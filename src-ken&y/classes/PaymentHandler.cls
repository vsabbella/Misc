public with sharing class PaymentHandler {
    
    public class PaymentHandlerException extends Exception{}
    
    private boolean isTest;
    private final string apiLoginId;
    private final string transactionKey;
    private final string authNetNS = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
    private final string endpoint;
    private final string solutionID;
    private static final string KENANDY_SOLUTION_ID = 'AAA159859';
    public class PaymentProfileDetail{
        public Id customerId {get;set;}
        public string emailAddress {get;set;}
        public Id shipToCustomerId {get;set;}
        public CreditCardDetail creditCard {get;set;}
        public PaymentFormFields formFields {get;set;} //KNDY-12198
    }
    
    public class CreditCardDetail{
        
        public string cardNumber {get;set;}
        public string expirationDate {get;set;} //YYYY-MM
        public string CCV {get;set;}
        
        public string firstName {get;set;}
        public string lastName {get;set;}
        public string company {get;set;}
        public string address {get;set;}
        public string city {get;set;}
        public string state {get;set;}
        public string zip {get;set;}
        public string country {get;set;}
        public string phone {get;set;}
        public string fax {get;set;}
    }

    
    // authorize.net payment form fields that are not supported
    // recurringBillingTransaction, description,freight, duty,taxExempt,
    // poNumber.
    // Not supporting poNumber as in Authorize.Net it can only be 
    // upto 25 chars no symbols, and Customer_Purchase_Order field 
    // in Sales Order object can be upto 120 char in length.
    public class PaymentFormFields{
            // payment information
        // cardCode is in CreditCardDetail.CCV
        
            // order information
            public string invoiceNumber {get;set;} // SO.Name or CI.Name
        
            //Customer billing information on card holder 
            // first name and last name come from customer
            // everything else comes from payment method
            // These are sent to authorize.net when payment profile and payment method 
            //    are both created initially.
            // Subsequent create payment method only requests use the customerProfileId 
            //    and do not require the below values.
            public string billingFirstName {get;set;} 
            public string billingLastName {get;set;}
            public string billingCompany {get;set;}
            public string billingAddress {get;set;}
            public string billingCity {get;set;}
            public string billingState {get;set;}
            public string billingZipCode {get;set;}
            public string billingCountry {get;set;}
            public string billingPhone {get;set;}
            public string billingFax {get;set;}
            public string billingEmail {get;set;}
            public string billingCustomerId {get;set;}
        
        // shipping information required to create payment method in authorize.net
        
        //SO ->Ship To customer first and last name fields. 
        //CI -> Ship To customer's first and last name fields
            public string shippingFirstName {get;set;}
            public string shippingLastName {get;set;}
            
            //SO-> company, CI ->company
            public string shippingCompany {get;set;}
        
        //SO->Ship To address fields, CI -> Ship to address field
            public string shippingAddress {get;set;}
            public string shippingCity {get;set;}
            public string shippingState {get;set;}
            public string shippingZipCode {get;set;}
            public string shippingCountry {get;set;}
        
        // Additional information
        
        //on SO -> VAT_Amount__c + Sales_Tax__c. 
        //On CI-> Total_Sales_Tax__c  +  Total_Value_Added_Tax__c
            public string tax {get;set;}
    }
     
    public class TransactionDetail{
        
        public string transactionId;
        public string referenceId;
        public string transactionType;
        public string transactionStatus;
        public DateTime transactionDate;
        
    }
    
    public class PaymentResponse {
        
        public Id customerReceiptId;
        public boolean isSuccess;
        public String response;
    }
    
    
    
    //https://developer.authorize.net/api/reference/
    
    public PaymentHandler(){
        Service_Configuration__c sc = Service_Configuration__c.getAll().get('AuthorizeNetV1');
        if(sc == null){
            throw new PaymentHandlerException('No Service Configuration found for AuthorizeNetV1');
        }else{
            this.apiLoginId = sc.Username__c;
            this.transactionKey = sc.Password__c;
            this.isTest = (sc.Description__c == 'test');
            if(this.isTest){
                endpoint = 'https://apitest.authorize.net/xml/v1/request.api';
                solutionID = 'AAA100302';
            }else{
                endpoint = 'https://api.authorize.net/xml/v1/request.api';
                solutionID = KENANDY_SOLUTION_ID;
            }
        }
    }
    
    //Ultimately, this method will not be required for a production release
    public boolean testConnection(){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'text/xml');
        req.setMethod('POST');
        
        Dom.Document doc = new Dom.Document();
        Dom.XMLNode root = doc.createRootElement('authenticateTestRequest', null, null);
        root.setAttribute('xmlns', authNetNS);
        root.addChildElement('merchantAuthentication', null, null);
        Dom.XMLNode merchAuth = root.getChildElement('merchantAuthentication', null);
        
        merchAuth.addChildElement('name', null, null);
        Dom.XMLNode name = merchAuth.getChildElement('name', null);
        name.addTextNode(this.apiLoginId);
        
        merchAuth.addChildElement('transactionKey', null, null);
        Dom.XMLNode trxnKey = merchAuth.getChildElement('transactionKey', null);
        trxnKey.addTextNode(this.transactionKey);
        
        req.setBody(doc.toXmlString());
        
        system.debug(doc.toXmlString());
        
        Http http = new Http();
        
        HttpResponse resp = http.send(req);
        
        system.debug('resp: ' + resp.getBody());
        boolean isSuccess = false;
        
        try{
            
            Dom.Document respDoc = resp.getBodyDocument();
            Dom.XMLNode respRoot = respDoc.getRootElement();
            Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);
            if(resultCode.getText().equalsIgnoreCase('I00001')){
                isSuccess = true;
            }else{
                throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('text', authNetNS).getText());
            }
            
        }catch(Exception ex){
            system.debug('EXCEPTION: ' +ex.getMessage() + ' ' + ex.getStackTraceString());
            throw new PaymentHandlerException('Unable to complete request: ' + ex.getMessage());
        }
        
        return isSuccess;
        
    }
    
    // Assumption: ppd is not null
    // Payment Method Name is in format cardNumber/expDate as per KNDY-15863
    private void setCreditCardAndBillingInfo (Payment_Method__c pm,PaymentHandler.PaymentProfileDetail ppd){//KNDY-12198
        String[] ccInfo = pm.Name.split('/');
        system.debug( LoggingLevel.Error, '>>> pm.Name/ccInfo::: ' + pm.Name + '/'+ccInfo);
        if (ppd.creditCard == null){
            ppd.creditCard = new PaymentHandler.CreditCardDetail();
        }
        //KNDY-15863 - CCV won't be stored as a part of payment profile name to be compliant with PCI-SSC
        // KNDY-13366 do not set CCV as Payment Method Name is not in expected format
        /*if (ccInfo.size() == 3){
            String ccv = ccInfo[ccInfo.size()-1];
            ppd.creditCard.CCV = ccv;
        }*/
        setBillToFormFields(ppd);
    }
    
    // Also called by Payment Profile Manager Ext
    // copies over billing info in ppd.creditCard into ppd.formFields
    // Assumption: ppd is not null
    public void setBillToFormFields(PaymentHandler.PaymentProfileDetail ppd){//KNDY-12198
        if (ppd.formFields == null){
            ppd.formFields = new PaymentHandler.PaymentFormFields();
        }
        ppd.formFields.billingFirstName = ppd.creditCard.firstName;
        ppd.formFields.billingLastName = ppd.creditCard.lastName;
        ppd.formFields.billingCompany = ppd.creditCard.company;
        ppd.formFields.billingAddress = ppd.creditCard.address;
        ppd.formFields.billingCity = ppd.creditCard.city;
        ppd.formFields.billingState = ppd.creditCard.state;
        ppd.formFields.billingZipCode = ppd.creditCard.zip;
        ppd.formFields.billingCountry = ppd.creditCard.country;
        ppd.formFields.billingPhone = ppd.creditCard.phone;
        ppd.formFields.billingFax = ppd.creditCard.fax;
        ppd.formFields.billingEmail = ppd.emailAddress;
    }
    
    public string getCustomerProfile(Id customerId){
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <getCustomerProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
          <merchantAuthentication>
            <name>96bc46uTwG7P</name>
            <transactionKey>58d34Ramy8f45WJQ</transactionKey>
          </merchantAuthentication>
          <customerProfileId>10000</customerProfileId>
        </getCustomerProfileRequest>
        */
        
        

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Payment_Profile__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Payment_Profile_ID__c'
        });
        soql.setWhereClause('customer__c = :customerId AND Gateway__c = \'Authorize.net\'');
        List<Payment_Profile__c> profiles = Database.query(soql.getQuery());



        
        
        if(profiles.size() == 0)
            return null;
        
        Dom.Document reqDoc = new Dom.Document();
        reqDoc.createRootElement('getCustomerProfileRequest', null, null);
        Dom.XMLNode reqRoot = reqDoc.getRootElement();
        reqRoot.setAttribute('xmlns', authNetNS);
        
        addMerchantAuthentication(reqDoc);
        
        reqRoot.addChildElement('customerProfileId', null, null);
        Dom.XMLNode customerProfileId = reqRoot.getChildElement('customerProfileId', null);
        customerProfileId.addTextNode(profiles[0].Payment_Profile_ID__c);
        
        HttpResponse resp = sendRequest('POST', reqDoc.toXMLString());
        
        return parseGetCustomerProfile(customerId, resp.getBodyDocument());
        
    }
    
    private string parseGetCustomerProfile(Id customerId, Dom.Document respDoc){
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <getCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
          <messages>
            <resultCode>Ok</resultCode>
            <message>
              <code>I00001</code>
              <text>Successful.</text>
            </message>
          </messages>
          <profile>
            <merchantCustomerId>custId123</merchantCustomerId>
            <description>some description</description>
            <email>mark@example.com</email>
            <customerProfileId>10000</customerProfileId>
            <paymentProfiles>
              <billTo>
                <firstName>John</firstName>
                <lastName>Doe</lastName>
                <company></company>
                <address>123 Main St.</address>
                <city>Bellevue</city>
                <state>WA</state>
                <zip>98004</zip>
                <country>USA</country>
                <phoneNumber>000-000-0000</phoneNumber>
                <faxNumber></faxNumber>
              </billTo>
              <customerPaymentProfileId>20000</customerPaymentProfileId>
              <payment>
                <creditCard>
                  <cardNumber>XXXX1111</cardNumber>
                  <expirationDate>XXXX</expirationDate>
                </creditCard>
              </payment>
            </paymentProfiles>
            <paymentProfiles>
              <customerPaymentProfileId>20001</customerPaymentProfileId>
              <payment>
                <bankAccount>
                  <accountType>checking</accountType>
                  <routingNumber>XXXX0000</routingNumber>
                    <accountNumber>XXXX0000</accountNumber>
                  <nameOnAccount>John Doe</nameOnAccount>
                  <bankName>Bank of Washington</bankName>
                </bankAccount>
              </payment>
            </paymentProfiles>
            <shipToList>
              <firstName>John</firstName>
              <lastName>Doe</lastName>
              <company></company>
              <address>123 Main St.</address>
              <city>Bellevue</city>
              <state>WA</state>
              <zip>98004</zip>
              <country>USA</country>
              <phoneNumber>000-000-0000</phoneNumber>
              <faxNumber></faxNumber>
            </shipToList>
            <shipToList>
              <firstName>Jane</firstName>
              <lastName>Doe</lastName>
              <address>123 Main St.</address>
              <city>Bellevue</city>
              <state>WA</state>
              <zip>98004</zip>
              <country>USA</country>
              <phoneNumber>000-000-0000</phoneNumber>
            </shipToList>
          </profile>
        </getCustomerProfileResponse>
        */
        
        Dom.XMLNode respRoot = respDoc.getRootElement();
        Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);
        if(resultCode.getText().equalsIgnoreCase('I00001')){
            string customerProfileId =  respRoot.getChildElement('profile', authNetNS).getChildElement('merchantCustomerId', authNetNS).getText();
            return customerProfileId;
            //TODO: Parse alot more of this data and return some structured detail...
        }else{
            throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('text', authNetNS).getText());
        }
        
        
    }
    
   
    
    public Payment_Profile__c createPaymentProfile(PaymentProfileDetail profileDetail){
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <createCustomerProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">  
           <merchantAuthentication>
             <name>96bc46uTwG7P</name>
             <transactionKey>58d34Ramy8f45WJQ</transactionKey>
            </merchantAuthentication>
           <profile>
             <merchantCustomerId>Merchant_Customer_ID</merchantCustomerId>
             <description>Profile description here</description>
             <email>customer-profile-email@here.com</email>
             <paymentProfiles>
               <customerType>individual</customerType>
               <billTo>
                  <firstName> xxx </firstName>
                  <lastName> xxx </lastName>
                  <company> xxx </company>
                  <address> xxx </address>
                  <city> xxx </city>
                  <state> xxx </state>
                  <zip> xxx </zip>
                  <country> xxx </country>
                  <phoneNumber> (123)123-1234 </phoneNumber>
                  <faxNumber> (123)123-1234 </faxNumber>
              </billTo>
              <payment>
                     <creditCard>
                        <cardNumber>4111111111111111</cardNumber>
                        <expirationDate>2020-12</expirationDate>
                        <cardCode>ccvNumber</cardCode>
                      </creditCard>
                   </payment>
              </paymentProfiles>
            </profile>
            <validationMode>testMode</validationMode>
          </createCustomerProfileRequest>
        */
        
       


        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','name', 'Company__r.Default_transaction_Currency__c'
        });
        string cid = profileDetail.customerId;        
        soql.setWhereClause('Id = :cid');
        Customer__c cust = Database.query(soql.getQuery());



        
        Dom.Document reqDoc = new Dom.Document();
        reqDoc.createRootElement('createCustomerProfileRequest', null, null);
        Dom.XMLNode reqRoot = reqDoc.getRootElement();
        reqRoot.setAttribute('xmlns', authNetNS);
        
        addMerchantAuthentication(reqDoc);
        
        reqRoot.addChildElement('profile', null, null);
        reqRoot.addChildElement('validationMode', null, null);
        
        
        Dom.XMLNode profile = reqRoot.getChildElement('profile', null);
        profile.addChildElement('merchantCustomerId', null, null);
        profile.addChildElement('description', null, null);
        profile.addChildElement('email', null, null);
        profile.addChildElement('paymentProfiles', null, null);
        
        
        Dom.XMLNode merchantCustId = profile.getChildElement('merchantCustomerId', null);
        merchantCustId.addTextNode(cust.Id);
        
        Dom.XMLNode description = profile.getChildElement('description', null);
        description.addTextNode(cust.Name);
        
        Dom.XMLNode email = profile.getChildElement('email', null);
        email.addTextNode(profileDetail.emailAddress);
        
        Dom.XMLNode paymentProfiles = profile.getChildElement('paymentProfiles', null);
        paymentProfiles.addChildElement('customerType', null, null);
        paymentProfiles.addChildElement('billTo', null, null);
        paymentProfiles.addChildElement('payment', null, null);
        
        Dom.XMLNode customerType = paymentProfiles.getChildElement('customerType', null);
        customerType.addTextNode('business'); // or individual 
        
        addBillToInfoInCreatePaymentProfileRequest(reqDoc,profileDetail); //KNDY-12198
        
        Dom.XMLNode payment = paymentProfiles.getChildElement('payment', null);
        payment.addChildElement('creditCard', null, null);
        
        Dom.XMLNode creditCard = payment.getChildElement('creditCard', null);
        creditCard.addChildElement('cardNumber', null, null);
        creditCard.addChildElement('expirationDate', null, null);
        creditCard.addChildElement('cardCode', null, null);//KNDY-12730
        
        Dom.XMLNode cardNumber = creditCard.getChildElement('cardNumber', null);
        cardNumber.addTextNode(profileDetail.creditCard.cardNumber);
        
        Dom.XMLNode expirationDate = creditCard.getChildElement('expirationDate', null);
        expirationDate.addTextNode(profileDetail.creditCard.expirationDate);
        
        Dom.XMLNode cardCode = creditCard.getChildElement('cardCode', null); //KNDY-12730
        cardCode.addTextNode(profileDetail.creditCard.CCV);

        Dom.XMLNode validationMode = reqRoot.getChildElement('validationMode', null);
        validationMode.addTextNode('testMode'); //or ...

        system.debug('createPaymentProfile='+reqDoc.toXMLString());
        
        HttpResponse resp = sendRequest('POST', reqDoc.toXMLString());
        
        return parseCreateCustomerProfileResponse(profileDetail, resp.getBodyDocument());
        
        
    }

    private void addShipToInfoInChargePaymentMethodRequest(Dom.Document reqDoc,PaymentProfileDetail profileDetail){//KNDY-12198
        Dom.XMLNode root = reqDoc.getRootElement();
            Dom.XMLNode transactionRequest = root.getChildElement('transactionRequest', null);
            transactionRequest.addChildElement('shipTo', null, null);
            Dom.XMLNode shipTo = transactionRequest.getChildElement('shipTo', null);
        
        shipTo.addChildElement('firstName', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingFirstName)){
            Dom.XMLNode firstName = shipTo.getChildElement('firstName', null);
            firstName.addTextNode(profileDetail.formFields.shippingFirstName);
        }
        shipTo.addChildElement('lastName', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingLastName)){
            Dom.XMLNode lastName = shipTo.getChildElement('lastName', null);
            lastName.addTextNode(profileDetail.formFields.shippingLastName);
        }
        shipTo.addChildElement('company', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingCompany)){
            Dom.XMLNode company = shipTo.getChildElement('company', null);
            company.addTextNode(profileDetail.formFields.shippingCompany);
        }
        shipTo.addChildElement('address', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingAddress)){
            Dom.XMLNode address = shipTo.getChildElement('address', null);
            address.addTextNode(profileDetail.formFields.shippingAddress);
        }
        shipTo.addChildElement('city', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingCity)){
            Dom.XMLNode city = shipTo.getChildElement('city', null);
            city.addTextNode(profileDetail.formFields.shippingCity);
        }
        shipTo.addChildElement('state', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingState)){
            Dom.XMLNode state = shipTo.getChildElement('state', null);
            state.addTextNode(profileDetail.formFields.shippingState);
        }
        shipTo.addChildElement('zip', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingZipCode)){
            Dom.XMLNode zip = shipTo.getChildElement('zip', null);
            zip.addTextNode(profileDetail.formFields.shippingZipCode);
        }
        shipTo.addChildElement('country', null, null);
        if (!String.isBlank(profileDetail.formFields.shippingCountry)){
            Dom.XMLNode country = shipTo.getChildElement('country', null);
            country.addTextNode(profileDetail.formFields.shippingCountry);
        }
    }
    
    // Assumption billTo Node exists in reqDoc
    private void addBillToInfoInCreatePaymentProfileRequest(Dom.Document reqDoc,PaymentProfileDetail profileDetail){//KNDY-12198
        Dom.XMLNode root = reqDoc.getRootElement();
            Dom.XMLNode profile = root.getChildElement('profile', null);
        Dom.XMLNode paymentProfiles = profile.getChildElement('paymentProfiles', null);
        Dom.XMLNode billTo = paymentProfiles.getChildElement('billTo', null);
       
        if (!String.isBlank(profileDetail.formFields.billingFirstName)){
            billTo.addChildElement('firstName', null, null);
            Dom.XMLNode firstName = billTo.getChildElement('firstName', null);
            firstName.addTextNode(profileDetail.formFields.billingFirstName);
        }
        if (!String.isBlank(profileDetail.formFields.billingLastName)){
            billTo.addChildElement('lastName', null, null);
            Dom.XMLNode lastName = billTo.getChildElement('lastName', null);
            lastName.addTextNode(profileDetail.formFields.billingLastName);
        }
        if (!String.isBlank(profileDetail.formFields.billingCompany)){
            billTo.addChildElement('company', null, null);
            Dom.XMLNode company = billTo.getChildElement('company', null);
            company.addTextNode(profileDetail.formFields.billingCompany);
        }
        if (!String.isBlank(profileDetail.formFields.billingAddress)){
            billTo.addChildElement('address', null, null);
            Dom.XMLNode address = billTo.getChildElement('address', null);
            address.addTextNode(profileDetail.formFields.billingAddress);
        }
        if (!String.isBlank(profileDetail.formFields.billingCity)){
            billTo.addChildElement('city', null, null);
            Dom.XMLNode city = billTo.getChildElement('city', null);
            city.addTextNode(profileDetail.formFields.billingCity);
        }
        if (!String.isBlank(profileDetail.formFields.billingState)){
            billTo.addChildElement('state', null, null);
            Dom.XMLNode state = billTo.getChildElement('state', null);
            state.addTextNode(profileDetail.formFields.billingState);
        }
        if (!String.isBlank(profileDetail.formFields.billingZipCode)){
            billTo.addChildElement('zip', null, null);
            Dom.XMLNode zip = billTo.getChildElement('zip', null);
            zip.addTextNode(profileDetail.formFields.billingZipCode);
        }
        
        if (!String.isBlank(profileDetail.formFields.billingCountry)){
            billTo.addChildElement('country', null, null);
            Dom.XMLNode country = billTo.getChildElement('country', null);
            country.addTextNode(profileDetail.formFields.billingCountry);
        }
        if (!String.isBlank(profileDetail.formFields.billingPhone)){
            billTo.addChildElement('phoneNumber', null, null);
            Dom.XMLNode phoneNumber = billTo.getChildElement('phoneNumber', null);
            phoneNumber.addTextNode(profileDetail.formFields.billingPhone);
        }
        if (!String.isBlank(profileDetail.formFields.billingFax)){
            billTo.addChildElement('faxNumber', null, null);
            Dom.XMLNode faxNumber = billTo.getChildElement('faxNumber', null);
            faxNumber.addTextNode(profileDetail.formFields.billingFax);
        }
    }
    
    private Payment_Profile__c parseCreateCustomerProfileResponse(PaymentProfileDetail profileDetail, Dom.Document respDoc){
        
        /*
        <?xml version="1.0" encoding="UTF-8"?>
        <createCustomerProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
           <messages>
              <resultCode>Ok</resultCode>
              <message>
                 <code>I00001</code>
                 <text>Successful.</text>
              </message>
           </messages>
           <customerProfileId>38545475</customerProfileId>
           <customerPaymentProfileIdList>
              <numericString>35049701</numericString>
           </customerPaymentProfileIdList>
           <customerShippingAddressIdList />
           <validationDirectResponseList>
              <string>1,1,1,(TESTMODE) This transaction has been approved.,000000,P,0,none,Test transaction for ValidateCustomerPaymentProfile.,1.00,CC,auth_only,Cust_Id_1450292633,,,,,,,,,,,ryan.sieve@kenandy.com,,,,,,,,,0.00,0.00,0.00,FALSE,none,939D83D40EDEAB16DCEC897FE84C3C85,,,,,,,,,,,,,XXXX1111,Visa,,,,,,,,,,,,,,,,</string>
           </validationDirectResponseList>
        </createCustomerProfileResponse>
        */
        
        Dom.XMLNode respRoot = respDoc.getRootElement();
        Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);
        if(resultCode.getText().equalsIgnoreCase('I00001')){
            //Success!
            string profileId;
            List<string> paymentMethodIds = new List<string>();
            List<string> shippingAddressIds = new List<string>();
            
            Dom.XMLNode customerProfileId = respRoot.getChildElement('customerProfileId', authNetNS);
            profileId = customerProfileId.getText();
            
            Dom.XMLNode customerPaymentProfileIdList = respRoot.getChildElement('customerPaymentProfileIdList', authNetNS);
            for(Dom.XMLNode node : customerPaymentProfileIdList.getChildren()){
                if(node.getName() == 'numericString'){
                    paymentMethodIds.add(node.getText());
                }
            }
            
            Dom.XMLNode customerShippingAddressIdList = respRoot.getChildElement('customerShippingAddressIdList', authNetNS);
            for(Dom.XMLNode node : customerShippingAddressIdList.getChildren()){
                if(node.getName() == 'numericString'){
                    shippingAddressIds.add(node.getText());
                }
            }
            
            Dom.XMLNode validationDirectResponseList = respRoot.getChildElement('validationDirectResponseList', authNetNS);
            system.debug('validationDirectResponseList: ' + validationDirectResponseList);
            system.debug('string: ' + validationDirectResponseList.getChildElement('string', authNetNS));
            string value = validationDirectResponseList.getChildElement('string', authNetNS).getText();
            map<string, string> mValidationResponses = parseGatewayResponse(value);
            system.debug('mValidationResponses: ' + mValidationResponses);
            //TODO: Integrate shipping Address Ids to the Customer Ship-To?
            
            
            system.debug('profileId: ' + profileId);
            system.debug('paymentMethodIds: ' + paymentMethodIds);
            
            


            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','name'
            });
            string custId = profileDetail.customerId;
            soql.setWhereClause('Id = :custId');
            Customer__c cust = Database.query(soql.getQuery());
            
            
            Payment_Profile__c pp = new Payment_Profile__c();
            pp.Name = cust.Name + ' Authorize.net';
            pp.Customer__c = profileDetail.customerId;
            pp.Payment_Profile_ID__c = profileId;
            pp.Gateway__c = 'Authorize.net';
            pp.Email_Address__c = profileDetail.emailAddress;
            DML.insertAsUser(pp);
            
            List<Payment_Method__c> pms = new List<Payment_Method__c>();
            for(string paymentMethodId : paymentMethodIds){
                Payment_Method__c pm = new Payment_Method__c();
                String ccName = 'Card XXXX' + profileDetail.creditCard.cardNumber.right(4); 
                //KNDY-15863- FORMAT MM-YYYY
                string[] expDate = string.isNotBlank (profileDetail.creditCard.expirationDate) ? profileDetail.creditCard.expirationDate.split('-') : null;
                if (expDate != null  && !expDate.isEmpty() &&  expDate.size() > 1){
                	ccName += '/'+ expDate[1] + '-' + expDate[0];
                }
                //ccName += '/'+profileDetail.creditCard.expirationDate;
                //ccName += '/'+profileDetail.creditCard.CCV; //KNDY-15863 - Against PCI compliance to store CCV/CVV
                pm.Name = ccName;//KNDY-12730
                
                pm.Payment_Profile__c = pp.Id;
                pm.Type__c = 'Credit Card';
                pm.Payment_Method_ID__c = paymentMethodIds[0];  
                pms.add(pm);
            }
            
            DML.insertAsUser(pms);
            
            return pp;
            
        }else{
            throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('text', authNetNS).getText());
        }
    }
    
    
    public Payment_Method__c createPaymentMethod(Id paymentProfileId, CreditCardDetail creditCardInput){
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <createCustomerPaymentProfileRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
          <merchantAuthentication>
            <name>96bc46uTwG7P</name>
            <transactionKey>58d34Ramy8f45WJQ</transactionKey>
          </merchantAuthentication>
          <customerProfileId>10000</customerProfileId>
          <paymentProfile>
            <billTo>
              <firstName>John</firstName>
              <lastName>Doe</lastName>
              <company></company>
              <address>123 Main St.</address>
              <city>Bellevue</city>
              <state>WA</state>
              <zip>98004</zip>
              <country>USA</country>
              <phoneNumber>000-000-0000</phoneNumber>
              <faxNumber></faxNumber>
            </billTo>
            <payment>
              <creditCard>
                <cardNumber>4111111111111111</cardNumber>
                <expirationDate>2023-12</expirationDate>
              </creditCard>
            </payment>
          </paymentProfile>
          <validationMode>liveMode</validationMode>
        </createCustomerPaymentProfileRequest>
        */
        
        


        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Payment_Profile__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Payment_Profile_Id__c', 'Customer__r.Company__r.Default_transaction_Currency__c'
        });
        soql.setWhereClause('ID = :paymentProfileId');
        Payment_Profile__c pp = Database.query(soql.getQuery());



        
        Dom.Document reqDoc = new Dom.Document();
        reqDoc.createRootElement('createCustomerPaymentProfileRequest', null, null);
        Dom.XMLNode reqRoot = reqDoc.getRootElement();
        reqRoot.setAttribute('xmlns', authNetNS);
        
        addMerchantAuthentication(reqDoc);
        
        reqRoot.addChildElement('customerProfileId', null, null);
        Dom.XMLNode customerProfileId = reqRoot.getChildElement('customerProfileId', null);
        customerProfileId.addTextNode(pp.Payment_Profile_Id__c);
        
        reqRoot.addChildElement('paymentProfile', null, null);
        Dom.XMLNode paymentProfile = reqRoot.getChildElement('paymentProfile', null);
        
        paymentProfile.addChildElement('billTo', null, null);
        Dom.XMLNode billTo = paymentProfile.getChildElement('billTo', null);
        
        billTo.addChildElement('firstName', null, null);
        Dom.XMLNode firstName = billTo.getChildElement('firstName', null);
        firstName.addTextNode(creditCardInput.firstName == null ? '' : creditCardInput.firstName);
        
        billTo.addChildElement('lastName', null, null);
        Dom.XMLNode lastName = billTo.getChildElement('lastName', null);
        lastName.addTextNode(creditCardInput.lastName == null ? '' : creditCardInput.lastName);
        
        billTo.addChildElement('company', null, null);
        Dom.XMLNode company = billTo.getChildElement('company', null);
        company.addTextNode(creditCardInput.company == null ? '' : creditCardInput.company);
        
        billTo.addChildElement('address', null, null);
        Dom.XMLNode address = billTo.getChildElement('address', null);
        address.addTextNode(creditCardInput.address);
        
        billTo.addChildElement('city', null, null);
        Dom.XMLNode city = billTo.getChildElement('city', null);
        city.addTextNode(creditCardInput.city);
        
        billTo.addChildElement('state', null, null);
        Dom.XMLNode state = billTo.getChildElement('state', null);
        state.addTextNode(creditCardInput.state);
        
        billTo.addChildElement('zip', null, null);
        Dom.XMLNode zip = billTo.getChildElement('zip', null);
        zip.addTextNode(creditCardInput.zip);
        
        billTo.addChildElement('country', null, null);
        Dom.XMLNode country = billTo.getChildElement('country', null);
        country.addTextNode(creditCardInput.country == null ? '' : creditCardInput.country);
        
        billTo.addChildElement('phoneNumber', null, null);
        Dom.XMLNode phoneNumber = billTo.getChildElement('phoneNumber', null);
        phoneNumber.addTextNode(creditCardInput.phone == null ? '' : creditCardInput.phone);
        
        billTo.addChildElement('faxNumber', null, null);
        Dom.XMLNode faxNumber = billTo.getChildElement('faxNumber', null);
        faxNumber.addTextNode(creditCardInput.fax == null ? '' : creditCardInput.fax);
        
        paymentProfile.addChildElement('payment', null, null);
        Dom.XMLNode payment = paymentProfile.getChildElement('payment', null);
        payment.addChildElement('creditCard', null, null);
        
        Dom.XMLNode creditCard = payment.getChildElement('creditCard', null);
        creditCard.addChildElement('cardNumber', null, null);
        creditCard.addChildElement('expirationDate', null, null);
        creditCard.addChildElement('cardCode', null, null);
        
        Dom.XMLNode cardNumber = creditCard.getChildElement('cardNumber', null);
        cardNumber.addTextNode(creditCardInput.cardNumber);
        
        Dom.XMLNode expirationDate = creditCard.getChildElement('expirationDate', null);
        expirationDate.addTextNode(creditCardInput.expirationDate);
        
        Dom.XMLNode cardCode = creditCard.getChildElement('cardCode', null);
        cardCode.addTextNode(creditCardInput.CCV == null ? '' : creditCardInput.CCV);
        
        reqRoot.addChildElement('validationMode', null, null);
        Dom.XMLNode validationMode = reqRoot.getChildElement('validationMode', null);
        validationMode.addTextNode('testMode'); //or ... liveMode
        
        HttpResponse resp = sendRequest('POST', reqDoc.toXMLString());
        
        return parseCreatePaymentMethodResponse(paymentProfileId, creditCardInput, resp.getBodyDocument());
        
    }
    
    private Payment_Method__c parseCreatePaymentMethodResponse(Id paymentProfileId, CreditCardDetail creditCardInput, Dom.Document respDoc){
        
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <createCustomerPaymentProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
          <messages>
            <resultCode>Ok</resultCode>
            <message>
              <code>I00001</code>
              <text>Successful.</text>
            </message>
          </messages>
          <customerPaymentProfileId>20000</customerPaymentProfileId>
          <validationDirectResponse>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for 
        ValidateCustomerPaymentProfile.,0.01,CC,auth_only,custId123,
        John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,mark@example.com,,,,,,,,,0.00,0.00,0.00,,none,
        D18EB6B211FE0BBF556B271FDA6F92EE,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
          </validationDirectResponse>
        </createCustomerPaymentProfileResponse>
        */
        
        Dom.XMLNode respRoot = respDoc.getRootElement();
        Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);
        
        if(resultCode.getText().equalsIgnoreCase('I00001')){
            
            Dom.XMLNode customerPaymentProfileId = respRoot.getChildElement('customerPaymentProfileId', authNetNS);
            system.debug('customerPaymentProfileId: ' + customerPaymentProfileId);
            Payment_Method__c pm = new Payment_Method__c();
            
            String ccName = 'Card XXXX' + creditCardInput.cardNumber.right(4);
            //KNDY-15863- FORMAT MM-YYYY
            string[] expDate = string.isNotBlank (creditCardInput.expirationDate ) ? creditCardInput.expirationDate.split('-') : null;
            if (expDate != null  && !expDate.isEmpty() &&  expDate.size() > 1){
            	ccName += '/'+ expDate[1] + '-' + expDate[0];
            }
            //ccName += '/'+creditCardInput.expirationDate;
            //ccName += '/'+creditCardInput.CCV;//KNDY-15863 - Against PCI compliance to store CCV/CVV
            pm.Name = ccName;
            pm.Payment_Profile__c = paymentProfileId;
            pm.Type__c = 'Credit Card';
            pm.Payment_Method_Id__c = customerPaymentProfileId.getText();
            
            Dom.XMLNode validationDirectResponse = respRoot.getChildElement('validationDirectResponse', authNetNS);
            system.debug('validationDirectResponse: ' + validationDirectResponse);
            string value = validationDirectResponse.getText();
            map<string, string> mValidationResponses = parseGatewayResponse(value);
            system.debug('mValidationResponses: ' + mValidationResponses);
            //TODO: Parse and assign address fields on the Payment Method
            DML.checkUpsertAsUser(pm); upsert pm Payment_Method_Id__c;
            
            return pm;
            
        }else{
            throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('text', authNetNS).getText());
        }
        
    }
    
    public PaymentResponse chargePaymentMethod(Id paymentMethodId, string referenceId, PaymentHandler.PaymentProfileDetail ppd, decimal chargeAmount){
        /*
        <createTransactionRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
          <merchantAuthentication>
            <name>96bc46uTwG7P</name>
            <transactionKey>58d34Ramy8f45WJQ</transactionKey>
          </merchantAuthentication>
          <refId>123456</refId>
          <transactionRequest>
            <transactionType>authCaptureTransaction</transactionType>
            <amount>5</amount>
            <profile>
              <customerProfileId>27388924</customerProfileId>
              <paymentProfile>
                <paymentProfileId>25000332</paymentProfileId>
                <cardCode>123</cardCode>
              </paymentProfile>
            </profile>
            <solution>
            	<id></id>
            </solution>
            <order>
              <invoiceNumber>INV-12345</invoiceNumber>
              <description>Product Description</description>
            </order>
            <lineItems>
              <lineItem>
                <itemId>1</itemId>
                <name>vase</name>
                <description>Cannes logo </description>
                <quantity>18</quantity>
                <unitPrice>45.00</unitPrice>
              </lineItem>
            </lineItems>
                <tax>
                  <amount>4.26</amount>
                  <name>level2 tax name</name>
                  <description>level2 tax</description>
                </tax>
            <poNumber>456654</poNumber>
            <shipTo>
              <firstName>China</firstName>
              <lastName>Bayles</lastName>
              <company>Thyme for Tea</company>
              <address>12 Main Street</address>
              <city>Pecan Springs</city>
              <state>TX</state>
              <zip>44628</zip>
              <country>USA</country>
            </shipTo>
            <customerIP>192.168.1.1</customerIP>
          </transactionRequest>
        </createTransactionRequest>
        */
        
        


        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Payment_Method__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Payment_Method_ID__c','Payment_Profile__c','Payment_Profile__r.Payment_Profile_ID__c','Payment_Profile__r.Customer__c', 'Payment_Profile__r.Customer__r.Company__r.Default_transaction_Currency__c'
        });
        soql.setWhereClause('Id = :paymentMethodId');
        Payment_Method__c pm = Database.query(soql.getQuery());
        setCreditCardAndBillingInfo(pm, ppd);//KNDY-12198
        
        Dom.Document reqDoc = new Dom.Document();
        reqDoc.createRootElement('createTransactionRequest', null, null);
        Dom.XMLNode reqRoot = reqDoc.getRootElement();
        reqRoot.setAttribute('xmlns', authNetNS);
        
        addMerchantAuthentication(reqDoc);
        
        reqRoot.addChildElement('refId', null, null);
        Dom.XMLNode refId = reqRoot.getChildElement('refId', null);
        refId.addTextNode(referenceId == null ? '' : referenceId);
           
        reqRoot.addChildElement('transactionRequest', null, null);
        Dom.XMLNode transactionRequest = reqRoot.getChildElement('transactionRequest', null);
        
        transactionRequest.addChildElement('transactionType', null, null);
        Dom.XMLNode transactionType = transactionRequest.getChildElement('transactionType', null);
        transactionType.addTextNode('authCaptureTransaction'); //TODO: Pass auth, capture, or authCapture in future flows independently
        
        transactionRequest.addChildElement('amount', null, null);
        Dom.XMLNode amount = transactionRequest.getChildElement('amount', null);
        amount.addTextNode(string.valueOf(chargeAmount));
        
        transactionRequest.addChildElement('profile', null, null);
        Dom.XMLNode profile = transactionRequest.getChildElement('profile', null);
        
        profile.addChildElement('customerProfileId', null, null);
        Dom.XMLNode customerProfileId = profile.getChildElement('customerProfileId', null);
        customerProfileId.addTextNode(pm.Payment_Profile__r.Payment_Profile_ID__c);
        
        profile.addChildElement('paymentProfile', null, null);
        Dom.XMLNode paymentProfile = profile.getChildElement('paymentProfile', null);
        
        paymentProfile.addChildElement('paymentProfileId', null, null);
        Dom.XMLNode paymentProfileId = paymentProfile.getChildElement('paymentProfileId', null);
        paymentProfileId.addTextNode(pm.Payment_Method_ID__c);
        if (ppd != null && ppd.creditCard != null && !String.isBlank(ppd.creditCard.CCV)){
            paymentProfile.addChildElement('cardCode', null, null);//KNDY-12198
            Dom.XMLNode cardCode = paymentProfile.getChildElement('cardCode', null); 
            //system.debug(LoggingLevel.Error, '>>>ppd.creditCard.CCV:' + ppd);
            cardCode.addTextNode(ppd.creditCard.CCV);
        }

        //KNDY-13752 -- ADD SOLUTION TO AUTH TRANSACTIONS
        transactionRequest.addChildElement('solution', null, null);
        Dom.XMLNode solutionInfo = transactionRequest.getChildElement('solution', null);
        system.debug('solutionInfo '+solutionInfo);
		solutionInfo.addChildElement('id', null, null);
        Dom.XMLNode id = solutionInfo.getChildElement('id', null);
        system.debug('id '+id);
        id.addTextNode(solutionID);
        
        
        transactionRequest.addChildElement('order', null, null);
        Dom.XMLNode orderInfo = transactionRequest.getChildElement('order', null);
        
        system.debug('orderInfo '+orderInfo);
        orderInfo.addChildElement('invoiceNumber', null, null);
        Dom.XMLNode invoiceNumber = orderInfo.getChildElement('invoiceNumber', null);
        system.debug('invoiceNumber '+invoiceNumber);
        invoiceNumber.addTextNode(ppd.formFields.invoiceNumber);
        
        if (!String.isBlank(ppd.formFields.tax)){
           transactionRequest.addChildElement('tax', null, null);
           Dom.XMLNode taxNode = transactionRequest.getChildElement('tax', null);
           taxNode.addChildElement('amount', null, null);
           taxNode.addChildElement('name', null, null);
           taxNode.addChildElement('description', null, null);
           Dom.XMLNode taxAmountNode = taxNode.getChildElement('amount', null);
           taxAmountNode.addTextNode(ppd.formFields.tax);
           Dom.XMLNode taxNameNode = taxNode.getChildElement('name', null);
           taxNameNode.addTextNode('tax');
           Dom.XMLNode taxDescriptionNode = taxNode.getChildElement('description', null);
           taxDescriptionNode.addTextNode('tax');
        }
        addShipToInfoInChargePaymentMethodRequest(reqDoc,ppd);
        //transactionRequest.addChildElement('customer', null, null);
        //Dom.XMLNode customer = transactionRequest.getChildElement('customer', null);
        //customer.addTextNode(pm.Payment_Profile__r.Customer__c);
        
        //TODO: Do I need anything else? Seems like I just need the profiles and the amount...
        
        system.debug('charge payment='+reqDoc.toXMLString());
        HttpResponse resp = sendRequest('POST', reqDoc.toXMLString());
        
        
        return parseChargePaymentMethod(paymentMethodId, referenceId, chargeAmount, resp.getBodyDocument());
        
    }
    
    private PaymentResponse parseChargePaymentMethod(Id paymentMethodId, string referenceId, decimal chargeAmount, Dom.Document respDoc){
   
    /*
    <?xml version="1.0" encoding="utf-8"?>
            <createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
              <refId>123456</refId>
              <messages>
                <resultCode>Ok</resultCode>
                <message>
                  <code>I00001</code>
                  <text>Successful.</text>
                </message>
              </messages>
              <transactionResponse>
                <responseCode>1</responseCode>
                <authCode>UGELQC</authCode>
                <avsResultCode>E</avsResultCode>
                <cavvResultCode />
                <transId>2148061808</transId>
                <refTransID />
                <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash>
                <accountNumber>XXXX0015</accountNumber>
                <accountType>MasterCard</accountType>
                <message>
                  <code>1</code>
                  <description>This transaction has been approved.</description>
                </message>
                <userFields>
                  <userField>
                    <name>MerchantDefinedFieldName1</name>
                    <value>MerchantDefinedFieldValue1</value>
                  </userField>
                  <userField>
                    <name>favorite_color</name>
                    <value>lavender</value>
                  </userField>
                </userFields>
              </transactionResponse>
            </createTransactionResponse>
        */
        
        

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Payment_Method__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Payment_Method_ID__c','Payment_Profile__c','Payment_Profile__r.Customer__r.Top_Parent_Customer__c',
            'Payment_Profile__r.Payment_Profile_ID__c','Payment_Profile__r.Customer__c','Payment_Profile__r.Customer__r.Company__c','Payment_Profile__r.Customer__r.Company__r.Credit_Card_Bank_Account__c',  'Payment_Profile__r.Customer__r.Company__r.Default_transaction_Currency__c'// #JUSTDOIT Remove reference 
        });
        soql.setWhereClause('Id = :paymentMethodId');
        Payment_Method__c pm = Database.query(soql.getQuery());



        Customer__c paymentProfileCustomer;
        //not assuming a hierarchy: if customer on profile is a corp then it will evaluate the first part of or to true else if its bill to then the second part. 
        

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Default_Bill_To_Customer__c','RecordType.DeveloperName', 'Company__r.Default_transaction_Currency__c', 'Currency__c'
        });
        string pPCust = pm.Payment_Profile__r.Customer__c;
        string tPCust = pm.Payment_Profile__r.Customer__r.Top_Parent_Customer__c;
        soql.setWhereClause('Id = :pPCust  And (Top_Parent_Customer__c = null  OR (Top_Parent_Customer__c = :tPCust and RecordType.DeveloperName = \'Bill_To\'))');//KNDY-17864

        paymentProfileCustomer = Database.query(soql.getQuery());
		Sales_Order__c so;
        Customer_Invoice__c ci;
        if(referenceId instanceOf Id){
        	 Id refId = (Id)referenceId;
        	if(refId.getSObjectType() == Customer_Invoice__c.getSObjectType()){
        		soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		        soql.addFields(new set<string>{
		            'Currency__c','Company__c'
		        });
		        soql.setWhereClause('Id = :refId ');
		        soql.setLimit(1);
        		ci =  Database.query(soql.getQuery());
        		
        	}else {
        		soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		        soql.addFields(new set<string>{
		            'Currency__c','Company__c'
		        });
		        soql.setWhereClause('Id = :refId ');
		        soql.setLimit(1);
        		so =  Database.query(soql.getQuery());
        	}
        }


        system.debug('paymentProfileCustomer '+paymentProfileCustomer);
        Dom.XMLNode respRoot = respDoc.getRootElement();
        Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);
        for(Dom.XMLNode node : respRoot.getChildren()){
            system.debug(node.getName() + ' ' + node.getNamespace());
        }

        PaymentHandler.PaymentResponse pResponse = new PaymentHandler.PaymentResponse();

        if(resultCode.getText().equalsIgnoreCase('I00001')){
            
            //Dom.XMLNode refId = respRoot.getChildElement('refId', null);
            //string returnReferenceId = refId.getText();
            //TODO: Do something interesting with the referenceId - like identify if it came from a Quote or a Sales Order and make the association where relevant...
            Dom.XMLNode transactionResponse = respRoot.getChildElement('transactionResponse', authNetNS);
            
            Dom.XMLNode responseCode = transactionResponse.getChildElement('responseCode', authNetNS);
            string respCodeVal = responseCode.getText();
            
            system.debug('respCodeVal: ' + respCodeVal);
            
            map<string, string> mResponseCodes = new map<string, string>{'1'=>'Approved', '2'=>'Declined', '3'=>'Error', '4'=>'Held for Review'};
            
            string transId = transactionResponse.getChildElement('transId', authNetNS).getText();
            system.debug('transId: ' + transId);
            
            Customer_Receipt__c cr = new Customer_Receipt__c();
            cr.Company__c = so != null ? so.Company__c : ci.Company__c;
            cr.Customer__c = pm.Payment_Profile__r.Customer__c;
            cr.Transaction_Date__c = system.now();
            cr.Currency__c = so != null ? so.Currency__c : ci.Currency__c; //This is an egregious sin for right now... But the gateway doesn't have an obvious way to assign trxn currency. This will need to modify in time for multicurrency
            
            cr.Date_Received__c = cr.Transaction_Date__c;
            cr.Amount_Received__c = chargeAmount;
            cr.Type__c = 'Receipt'; //Prepayment??
            cr.Transaction_ID__c = transId;
            cr.Reference_Number__c = transId;//KNDY-10324
            cr.Payment_Method_3__c = pm.Id;
            cr.Bank_Account_2__c = pm.Payment_Profile__r.Customer__r.Company__r.Credit_Card_Bank_Account__c ;// KNDY-10324
            if(mResponseCodes.containsKey(respCodeVal)){
                cr.Status__c = mResponseCodes.get(respCodeVal);
            }else{
                cr.Status__c = 'Open';
            }
            
            DML.insertAsUser(cr);
            
            Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
            crl.Customer_Receipt__c = cr.Id;
            crl.Amount__c = chargeAmount;
            if(referenceId instanceOf Id){
                Id refId = (Id)referenceId;
                if(refId.getSObjectType() == Customer_Invoice__c.getSObjectType()){
                    crl.Type__c = 'Payment';
                    crl.Customer_Invoice__c = refId;
                }else{
                    crl.Customer__c = paymentProfileCustomer.RecordType.DeveloperName == 'Bill_To' ? paymentProfileCustomer.Id : paymentProfileCustomer.Default_Bill_To_Customer__c;
                    crl.Type__c = 'Prepayment';
                    if(refId.getSObjectType() == Sales_Order__c.getSObjectType()){
                        crl.Sales_Order__c = refId;
                    }
                }
            }else{
                crl.Customer__c = paymentProfileCustomer.RecordType.DeveloperName == 'Bill_To' ? paymentProfileCustomer.Id : paymentProfileCustomer.Default_Bill_To_Customer__c;
                crl.Type__c = 'Prepayment';
            }
            
            system.debug('payment handler crl '+crl);       
            DML.insertAsUser(crl);
            
            if(respCodeVal == '1'){ //Approved
                cr.Finalized__c = true;
                DML.updateAsUser(cr);
                pResponse.customerReceiptId = cr.Id;
                pResponse.isSuccess = true;
                pResponse.response = response(respRoot);
                
                
            }else if(respCodeVal == '2' || respCodeVal == '3') {
                cr.Status__c = 'Cancelled';
                DML.updateAsUser(cr);
                
                pResponse.customerReceiptId = cr.Id;
                pResponse.isSuccess = false;
                pResponse.response = respRoot.getChildElement('transactionResponse', authNetNS).getChildElement('errors', authNetNS).getChildElement('error', authNetNS).getChildElement('errorText', authNetNS).getText();
                
            }else {
                pResponse.customerReceiptId = cr.Id;
                pResponse.isSuccess = true;
                pResponse.response = response(respRoot);
            }
            
            return pResponse;
            
        }else{
            DOM.XMLNode transactionResponse = respRoot.getChildElement('transactionResponse', authNetNS);
            //system.assert(1 != 1, '>>>> transactionResponse: '+ transactionResponse);

            if (transactionResponse != null){
                DOM.XMLNode transactionErrorsNode =  transactionResponse.getChildElement('errors', authNetNS);
                if (transactionErrorsNode != null){
                    //system.debug(LoggingLevel.Error, '>>>> transactionErrorsNode: '+ transactionErrorsNode);
                    Dom.XmlNode[] errorNodes = transactionErrorsNode.getChildren();
                    for (Dom.XmlNode errorNode : errorNodes){
                        system.debug(LoggingLevel.Error, '>>>> errorNode: '+ errorNode);
                        Dom.XmlNode errorText = errorNode.getChildElement('errorText', authNetNS);
                        system.debug(LoggingLevel.Error, '>>>> errorText: '+ errorText);
                        if (errorText != null){
                            Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, errorText.getText())); //KNDY-8389
                        }
                    }
                }
            }
            throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('text', authNetNS).getText());
        }
    }
    
    // Is this used anywhere?
    public PaymentResponse refundTransaction(Id paymentMethodId, string referenceTransactionId, string referenceId, string memoText){
        //Refund the whole amount

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Amount_Received__c',  'Company__r.Default_transaction_Currency__c'
        });
        soql.setWhereClause('Transaction_ID__c = :referenceTransactionId AND Payment_Method_3__c = :paymentMethodId');
        List<Customer_Receipt__c> refCRs = Database.query(soql.getQuery());
                                            
        Customer_Receipt__c refCR;
        if(refCRs.size() == 1){
            refCR = refCRs[0];
        }else{
            system.debug('found more than 1 CR for pmId ' + paymentMethodId + ' trxnId ' + referenceTransactionId);
            throw new PaymentHandlerException('Unable to complete refund, more than 1 Transaction Id was found for ' + referenceTransactionId);
        }       
        
        return refundTransaction(paymentMethodId, referenceTransactionId, referenceId, refCR.Amount_Received__c, memoText);
    }
    
    public PaymentResponse refundTransaction(Id paymentMethodId, string referenceTransactionId, string referenceId, decimal refundAmount, string memoText){
    
    /*
    <createTransactionRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
          <merchantAuthentication>
            <name>API_LOGIN_ID</name>
            <transactionKey>API_TRANSACTION_KEY</transactionKey>
          </merchantAuthentication>
          <refId>123456</refId>
          <transactionRequest>
            <transactionType>refundTransaction</transactionType>
            <amount>5</amount>
            <profile>
              <customerProfileId>27388924</customerProfileId>
              <paymentProfile>
                <paymentProfileId>25000332</paymentProfileId>
              </paymentProfile>
            </profile>
            <refTransId>1122334455</refTransId>
          </transactionRequest>
        </createTransactionRequest>
        */
    
    
    // For Prepayment CRs, Customer_Invoices__r is not null
    // For Payment CRs created by a charge via Authorize.Net, Customer_Invoices__r is  null
    // For Payment CRs not created through Authorize.Net, Transaction_Id__c is null

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Amount_Received__c'
        });
        soql.setWhereClause('Transaction_ID__c = :referenceTransactionId AND Payment_Method_3__c = :paymentMethodId');
        
        String cInvWhereClause = ' (Status__c = \'Open\' or Status__c = \'Closed\') and Invoice_Type__c = \'Prepayment\'';
        SOQLUtil.ChildRelationship cInvSubQuery = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoices__r');
        cInvSubQuery.addFields(new Set<String>{'Id', 'Name', 'Balance__c'});
        cInvSubQuery.setWhereClause(cInvWhereClause);
        soql.addChildRelationship(cInvSubQuery);
        
        String cReceiptLineWhereClause = ' (Type__c = \'Payment\' or Type__c = \'Prepayment\') and Customer_Receipt__r.Status__c = \'Closed\' and Finalized__c = true order by CreatedDate desc';
        SOQLUtil.ChildRelationship customerReceiptLineSubQuery = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipt_Lines__r');
        customerReceiptLineSubQuery.addFields(new Set<String>{'Id', 'Amount__c', 'Customer_Invoice__c', 'Customer_Receipt__c', 'Type__c',
                                            'Customer_Invoice__r.Id', 'Customer_Invoice__r.Balance__c', 'Customer_Invoice__r.Amount_Paid__c',
                                        'Customer_Invoice__r.Id', 'Customer_Invoice__r.Name', 'Customer_Invoice__r.Total_Sales_Tax__c', 
                                        'Customer_Invoice__r.Total_Value_Added_Tax__c',
                                        'Sales_Order__c','Sales_Order__r.Id','Sales_Order__r.Name',
                                        'Sales_Order__r.VAT_Amount__c','Sales_Order__r.Sales_Tax__c'});
        customerReceiptLineSubQuery.setWhereClause(cReceiptLineWhereClause);
        soql.addChildRelationship(customerReceiptLineSubQuery);
        
        String cRelatedReceiptWhereClause = ' Type__c =\'Refund\' and Status__c = \'Closed\' and Finalized__c = true';
        SOQLUtil.ChildRelationship cRelatedReceiptSubQuery = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipts__r');
        cRelatedReceiptSubQuery.addFields(new Set<String>{'Id'});
        cRelatedReceiptSubQuery.setWhereClause(cRelatedReceiptWhereClause);
        soql.addChildRelationship(cRelatedReceiptSubQuery);
        List<Customer_Receipt__c> refCRs = Database.query(soql.getQuery());


        Customer_Receipt__c refCR;
        if(refCRs.size() == 1){
            refCR = refCRs[0];
        }else{
            system.debug('found more than 1 CR for pmId ' + paymentMethodId + ' trxnId ' + referenceTransactionId);
            throw new PaymentHandlerException('Unable to complete refund, more than 1 Transaction Id was found for ' + referenceTransactionId);
        }                           

        //KNDY-12198
        PaymentHandler.PaymentProfileDetail ppd = new PaymentHandler.PaymentProfileDetail();
        ppd.formFields = new PaymentHandler.PaymentFormFields();
        // system.assert(1 != 1, '>>>> cr.Customer_Receipt_Lines__r: ' + cr.Customer_Receipt_Lines__r);
                
        for (Customer_Receipt_Line__c crl: refCR.Customer_Receipt_Lines__r){
            if (crl.Type__c == 'Payment' && crl.Customer_Invoice__c != null){
                 Customer_Invoice__c ci = crl.Customer_Invoice__r;
                 ppd.formFields.invoiceNumber = ci.Name;
                 Decimal tax = KSE.addQuantityToField(ci.Total_Value_Added_Tax__c,0) + 
                 KSE.addQuantityToField(ci.Total_Sales_Tax__c,0);
                 ppd.formFields.tax = String.ValueOf(tax);
             }
             else if (crl.Type__c == 'Prepayment' && crl.Sales_Order__c != null){
                 Sales_Order__c so = crl.Sales_Order__r;
                 ppd.formFields.invoiceNumber = so.Name;
                 Decimal tax =  KSE.addQuantityToField(so.VAT_Amount__c,0) + 
                 KSE.addQuantityToField(so.Sales_Tax__c,0);
                 ppd.formFields.tax = String.ValueOf(tax);
             }
        }
        
        soql = new SOQLUtil('Payment_Method__c');
        soql.addFields(new set<string>{
            'Id','Name','Payment_Method_ID__c','Payment_Profile__c', 
            'Payment_Profile__r.Payment_Profile_ID__c',
            'Payment_Profile__r.Customer__c',  'Payment_Profile__r.Customer__r.Company__r.Default_transaction_Currency__c'       
        });
        soql.setWhereClause('Id = :paymentMethodId');
        Payment_Method__c pm = Database.query(soql.getQuery());
        
        Dom.Document reqDoc = new Dom.Document();
        reqDoc.createRootElement('createTransactionRequest', null, null);
        Dom.XMLNode reqRoot = reqDoc.getRootElement();
        reqRoot.setAttribute('xmlns', authNetNS);
        
        addMerchantAuthentication(reqDoc);
        
        reqRoot.addChildElement('refId', null, null);
        Dom.XMLNode refId = reqRoot.getChildElement('refId', null);
        refId.addTextNode(referenceId == null ? '' : referenceId);
        
        reqRoot.addChildElement('transactionRequest', null, null);
        Dom.XMLNode transactionRequest = reqRoot.getChildElement('transactionRequest', null);
        
        transactionRequest.addChildElement('transactionType', null, null);
        Dom.XMLNode transactionType = transactionRequest.getChildElement('transactionType', null);
        transactionType.addTextNode('refundTransaction'); 
        
        transactionRequest.addChildElement('amount', null, null);
        Dom.XMLNode amount = transactionRequest.getChildElement('amount', null);
        if(refundAmount <= refCR.Amount_Received__c){
            amount.addTextNode(string.valueOf(refundAmount));
        }else{
            amount.addTextNode(string.valueOf(refCR.Amount_Received__c));
        }
        
        transactionRequest.addChildElement('profile', null, null);
        Dom.XMLNode profile = transactionRequest.getChildElement('profile', null);
        
        profile.addChildElement('customerProfileId', null, null);
        Dom.XMLNode customerProfileId = profile.getChildElement('customerProfileId', null);
        customerProfileId.addTextNode(pm.Payment_Profile__r.Payment_Profile_ID__c);
        
        profile.addChildElement('paymentProfile', null, null);
        Dom.XMLNode paymentProfile = profile.getChildElement('paymentProfile', null);
        
        paymentProfile.addChildElement('paymentProfileId', null, null);
        Dom.XMLNode paymentProfileId = paymentProfile.getChildElement('paymentProfileId', null);
        paymentProfileId.addTextNode(pm.Payment_Method_ID__c);

        transactionRequest.addChildElement('refTransId', null, null);
        Dom.XMLNode refTransId = transactionRequest.getChildElement('refTransId', null);
        refTransId.addTextNode(referenceTransactionId);
                
        transactionRequest.addChildElement('order', null, null); //KNDY-12198
        Dom.XMLNode orderInfo = transactionRequest.getChildElement('order', null);
        orderInfo.addChildElement('invoiceNumber', null, null);
        Dom.XMLNode invoiceNumber = orderInfo.getChildElement('invoiceNumber', null);
        invoiceNumber.addTextNode(ppd.formFields.invoiceNumber);

        transactionRequest.addChildElement('tax', null, null);
        Dom.XMLNode taxNode = transactionRequest.getChildElement('tax', null);
        taxNode.addChildElement('amount', null, null);
        taxNode.addChildElement('name', null, null);
        taxNode.addChildElement('description', null, null);
        Dom.XMLNode taxAmountNode = taxNode.getChildElement('amount', null);
        taxAmountNode.addTextNode(ppd.formFields.tax);
        Dom.XMLNode taxNameNode = taxNode.getChildElement('name', null);
        taxNameNode.addTextNode('tax');
        Dom.XMLNode taxDescriptionNode = taxNode.getChildElement('description', null);
        taxDescriptionNode.addTextNode('tax');
        HttpResponse resp = sendRequest('POST', reqDoc.toXMLString());
   
        return parseRefundTransaction(paymentMethodId, referenceId, refundAmount, resp.getBodyDocument(), refCR, memoText);
    
    }
    
    private PaymentResponse parseRefundTransaction(Id paymentMethodId, string referenceId, decimal refundAmount, Dom.Document respDoc, Customer_Receipt__c relatedCR, string memoText){
        
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <createTransactionResponse>
          <refId>123456</refId>
          <messages>
            <resultCode>Ok</resultCode>
            <message>
              <code>I00001</code>
              <text>Successful.</text>
            </message>
          </messages>
          <transactionResponse>
            <responseCode>1</responseCode>
            <authCode>UGELQC</authCode>
            <avsResultCode>E</avsResultCode>
            <cavvResultCode />
            <transId>2148061808</transId>
            <refTransID />
            <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash>
            <testRequest>0</testRequest>
            <accountNumber>XXXX0015</accountNumber>
            <accountType>MasterCard</accountType>
            <message>
              <code>1</code>
              <description>This transaction has been approved.</description>
            </message>
            <userFields>
              <userField>
                <name>MerchantDefinedFieldName1</name>
                <value>MerchantDefinedFieldValue1</value>
              </userField>
              <userField>
                <name>favorite_color</name>
                <value>lavender</value>
              </userField>
            </userFields>
          </transactionResponse>
        </createTransactionResponse>
        
        <!--RESPONSE WITH ERROR -->
        <?xml version="1.0" encoding="utf-8"?>
        <createTransactionResponse>
            <refId>a0r36000000HL1tAAG</refId>
            <messages>
                <resultCode>Error</resultCode>
                <message>
                    <code>E00027</code>
                    <text>The transaction was unsuccessful.</text>
                </message>
            </messages>
            <transactionResponse>
                <responseCode>3</responseCode>
                <authCode />
                <avsResultCode>P</avsResultCode>
                <cvvResultCode /><cavvResultCode />
                <transId>0</transId>
                <refTransID>2248899643</refTransID>
                <transHash>3E3E1869711546220BB7619647BF04EA</transHash>
                <testRequest>0</testRequest>
                <accountNumber>XXXX8888</accountNumber>
                <accountType>Visa</accountType>
                <errors>
                    <error>
                        <errorCode>55</errorCode>
                        <errorText>The sum of credits against the referenced transaction would exceed original debit amount.</errorText>
                    </error>
                </errors>
            </transactionResponse>
        </createTransactionResponse>
        */
        
        

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Payment_Method__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Payment_Method_ID__c','Payment_Profile__c','Payment_Profile__r.Payment_Profile_ID__c','Payment_Profile__r.Customer__c',
            'Payment_Profile__r.Customer__r.Company__c','Payment_Profile__r.Customer__r.Company__r.Credit_Card_Bank_Account__c',  'Payment_Profile__r.Customer__r.Company__r.Default_transaction_Currency__c' // #JUSTDOIT Remove company reference
        });
        soql.setWhereClause('Id = :paymentMethodId');
        Payment_Method__c pm = Database.query(soql.getQuery());
		
        Customer_Receipt__c crOriginal;
        if(referenceId instanceOf Id){
        	 Id refId = (Id)referenceId;
            system.debug('refId.getSObjectType() == Customer_Receipt__c.getSObjectType() '+(refId.getSObjectType() == Customer_Receipt__c.getSObjectType()));
        	if(refId.getSObjectType() == Customer_Receipt__c.getSObjectType()){
        		soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
		        soql.addFields(new set<string>{
		            'Currency__c','Company__c'
		        });
		        soql.setWhereClause('Id = :refId ');
		        soql.setLimit(1);
        		crOriginal =  Database.query(soql.getQuery());
        		
        	}
        }


        
        Dom.XMLNode respRoot = respDoc.getRootElement();
        Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);
        for(Dom.XMLNode node : respRoot.getChildren()){
            system.debug(node.getName() + ' ' + node.getNamespace());
        }
        PaymentHandler.PaymentResponse pResponse = new PaymentHandler.PaymentResponse(); 
        if(resultCode.getText().equalsIgnoreCase('I00001')){
            
            Dom.XMLNode transactionResponse = respRoot.getChildElement('transactionResponse', authNetNS);
            
            Dom.XMLNode responseCode = transactionResponse.getChildElement('responseCode', authNetNS);
            string respCodeVal = responseCode.getText();
            
            system.debug('respCodeVal: ' + respCodeVal);
            
            map<string, string> mResponseCodes = new map<string, string>{'1'=>'Approved', '2'=>'Declined', '3'=>'Error', '4'=>'Held for Review'};
            
            string transId = transactionResponse.getChildElement('transId', authNetNS).getText();
            system.debug('transId: ' + transId);
            
            Customer_Receipt__c cr = new Customer_Receipt__c();
            cr.Company__c = crOriginal.Company__c;
            cr.Customer__c = pm.Payment_Profile__r.Customer__c;
            cr.Transaction_Date__c = system.now();
            cr.Currency__c = crOriginal.Currency__c; //This is an egregious sin for right now... But the gateway doesn't have an obvious way to assign trxn currency. This will need to modify in time for multicurrency
            
            cr.Date_Received__c = cr.Transaction_Date__c;
            cr.Amount_Received__c = (-1) * refundAmount;//KNDY-10324
            cr.Type__c = 'Refund';
            cr.Transaction_ID__c = transId;
            cr.Reference_Number__c = transId;
            cr.Payment_Method_3__c = pm.Id;
            cr.Bank_Account_2__c = pm.Payment_Profile__r.Customer__r.Company__r.Credit_Card_Bank_Account__c ;
            cr.Related_Customer_Receipt__c = relatedCR.Id;
            //TODO: Related Customer Receipt???
            if(mResponseCodes.containsKey(respCodeVal)){
                cr.Status__c = mResponseCodes.get(respCodeVal);
            }else{
                cr.Status__c = 'Open';
            }
            
            DML.insertAsUser(cr);
            
            list<Customer_Invoice__c> lPrepayments = relatedCR.Customer_Invoices__r;
            list<Customer_Receipt_Line__c> lCRLs  = new list<Customer_Receipt_Line__c>();
            //system.debug('lPrepayments '+lPrepayments);
            //system.assert(1 != 1, '>>> lPrepayments: ' + lPrepayments);
            
            if(lPrepayments != null && lPrepayments.size() > 1) {
                throw new PaymentHandlerException(' more than one prepayment linked to this customer receipt.');
            }
            else if(lPrepayments != null && lPrepayments.size() == 1){
                
                Decimal creditOnAccount = (-1) * lPrepayments[0].Balance__c;
                system.debug('creditOnAccount '+creditOnAccount);
                system.debug('refundAmount '+refundAmount);
                if(refundAmount > creditOnAccount ) {
                    if(creditOnAccount != 0){
                    	//KNDY-13995
                        lCRLs.add(new Customer_Receipt_Line__c(Customer_Receipt__c = cr.Id, Amount__c = (-1) * creditOnAccount, Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, Customer_Invoice__c = lPrepayments[0].Id, Memo__c = memoText));
                    }
                    //KNDY-12536
                    Decimal remainingRefundAmount = (refundAmount - creditOnAccount);
                    //system.assert(1 != 1, '>>> remainingRefundAmount: ' + remainingRefundAmount);
                    if (remainingRefundAmount > 0){
                        createRefundforPrepaymentsApplied(lPrepayments[0], cr, remainingRefundAmount, lCRLs, relatedCR, memoText);
                    }
                }else {
                	//KNDY-13995
                    lCRLs.add(new Customer_Receipt_Line__c(Customer_Receipt__c = cr.Id, Amount__c = (-1) * (refundAmount), Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, Customer_Invoice__c = lPrepayments[0].Id, Memo__c = memoText));
                }
                
            }
            // Payment CR
            else if (lPrepayments == null || lPrepayments.size() ==0 ){ //KNDY-12536
                list<Customer_Receipt_Line__c> paymentCRLs = new list<Customer_Receipt_Line__c>();
                for (Customer_Receipt_Line__c crl : relatedCR.Customer_Receipt_Lines__r){
                    if (crl.Type__c == 'Payment'){
                        paymentCRLs.add(crl);
                    }
                }
                //list<Customer_Receipt_Line__c> paymentCRLs = relatedCR.Customer_Receipt_Lines__r;
                createRefundforPaymentsApplied(paymentCRLs, cr, lCRLs, refundAmount, relatedCR, memoText);
            }

            system.debug('lCRLs '+lCRLs);
            DML.insertAsUser(lCRls);
            
            if(respCodeVal == '1'){ //Approved
                cr.Finalized__c = true;
                DML.updateAsUser(cr);
                pResponse.customerReceiptId = cr.Id;
                pResponse.isSuccess = true;
                pResponse.response = response(respRoot);
                
                
            }else if(respCodeVal == '2' || respCodeVal == '3') {
                cr.Status__c = 'Cancelled';
                DML.updateAsUser(cr);
                
                pResponse.customerReceiptId = cr.Id;
                pResponse.isSuccess = false;
                pResponse.response = respRoot.getChildElement('transactionResponse', authNetNS).getChildElement('errors', authNetNS).getChildElement('error', authNetNS).getChildElement('errorText', authNetNS).getText();
                
            }else {
                pResponse.customerReceiptId = cr.Id;
                pResponse.isSuccess = true;
                pResponse.response = response(respRoot);
            }
             
            return pResponse; 
                       
        }else{
            system.debug(logginglevel.error,'Errors --->'+respRoot.getChildElement('transactionResponse', authNetNS).getChildElement('errors', authNetNS).getChildElement('error', authNetNS).getChildElement('errorText', authNetNS).getText());
            throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('transactionResponse', authNetNS).getChildElement('errors', authNetNS).getChildElement('error', authNetNS).getChildElement('errorText', authNetNS).getText());
        }
        
    }

    // KNDY-12536 KNDY-12895 Create Receipt Lines indicating Payments applied were refunded
    public void createRefundforPaymentsApplied(list<Customer_Receipt_Line__c> paymentCRLs, Customer_Receipt__c newCR, list<Customer_Receipt_Line__c> lCRLs, decimal refundAmount, Customer_Receipt__c relatedCR, String memoText){
            if (paymentCRLs == null || paymentCRLs.size() == 0 ){
                throw new PaymentHandlerException('no payments are linked to this customer receipt.');
            }
            else if (paymentCRLs.size() > 1){
                throw new PaymentHandlerException('more than one payment is linked to this customer receipt.');
            }
            else if (paymentCRLs != null && paymentCRLs[0].Customer_Invoice__c == null){
                throw new PaymentHandlerException('Invalid payment CRL as it was not applied toward a CI');
            }
            else { // paymentCRLs.size() == 1
                Decimal invoiceAmountPaid = paymentCRLs[0].Amount__c;
                ID invoiceId = paymentCRLs[0].Customer_Invoice__c;
                ID relatedCRId = relatedCR.Id;
                system.debug('invoiceAmountPaid original payment '+invoiceAmountPaid);
                
                String crlwhereClause = ' type__c = \'Refund applied payment\'';
                crlwhereClause  += ' and Customer_Receipt__r.Related_Customer_Receipt__c = :relatedCRId';
                crlwhereClause  += ' and Customer_Receipt__r.Type__c = \'Refund\'';
                crlwhereClause  += ' and Customer_Receipt__r.Status__c = \'Closed\' and Finalized__c  = true';
                crlwhereClause  += ' and Customer_Invoice__c = :invoiceId';
                SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id','Amount__c'
                });
                
                soql.setWhereClause(crlwhereClause);
                List<Customer_Receipt_Line__c> refundAppliedPaymentCRLs = (List<Customer_Receipt_Line__c>) Database.query(soql.getQuery());

                    for(Customer_Receipt_Line__c crl :    refundAppliedPaymentCRLs){    
                            invoiceAmountPaid += crl.Amount__c;
                    }
                 system.debug('invoiceAmountPaid after refunds applied '+invoiceAmountPaid);
                Customer_Invoice__c ci = paymentCRLs[0].Customer_Invoice__r;
                system.debug(LoggingLevel.Error, '>>>refundAmount '+refundAmount);
                
                // create new CRL showing refunded amount was put back on CI
                if(refundAmount <= ci.Amount_Paid__c ) { 
                    lCRLs.add(new Customer_Receipt_Line__c(Customer_Receipt__c = newCR.Id, 
                                Amount__c = (-1) * refundAmount,  
                                Type__c = PaymentService.TYPE_REFUND_APPLIED_PAYMENT, 
                                Customer_Invoice__c = ci.Id, Memo__c = memoText));
                }
            }
      }

    
    // KNDY-12536 KNDY-12895 Create Receipt Lines indicating prepayments applied were refunded
    public void createRefundforPrepaymentsApplied(Customer_Invoice__c prepaymentCI, Customer_Receipt__c cr, Decimal amountToRefund, list<Customer_Receipt_Line__c> lCRLs, Customer_receipt__c relatedCR, String memoText ){
        Id prepaymentCIId;
        ID relatedCRId = relatedCR.Id;
        
        Map<Id, Customer_Receipt_Line__c> crIdPrepaymentAppliedCRL = new Map<Id, Customer_Receipt_Line__c>();
        Map<Id, Customer_Receipt_Line__c> crIdPaymentCRL = new Map<Id, Customer_Receipt_Line__c>();
        List<Customer_Invoice__c> cInvs = new List<Customer_Invoice__c>();
        
        prepaymentCIId = prepaymentCI.Id;
        system.assert(prepaymentCIId != null, '>>> prepaymentCI: ' + prepaymentCI);
       // Get all CRLs where prepayments were applied using prepaymentCIId
       // assumption only 1 prepayment applied CRLine exists on a CR for a Customer_Invoice__c
       
        SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
                'Id','Amount__c','Customer_Receipt__c'
        });
        Id recordId = cr.Id;
        //KNDY-13995
        soql.setWhereClause('Customer_Receipt__c != :recordId and Customer_Invoice__c = :prepaymentCIId and Type__c = \'Prepayment Applied\' and Customer_Receipt__r.Status__c = \'Closed\' and Finalized__c = true');
        List<Customer_Receipt_Line__c> prepaymentAppliedCRLs = (List<Customer_Receipt_Line__c>) Database.query(soql.getQuery());

       for (Customer_Receipt_Line__c crl: prepaymentAppliedCRLs){
           crIdPrepaymentAppliedCRL.put(crl.Customer_Receipt__c, crl);
       }
       // system.assert(1 != 1, '>>> crIdPrepaymentAppliedCRL: ' + crIdPrepaymentAppliedCRL);
       
        // Get CRLines of type Payment for the above CRs
        Map<Id, List<Customer_Receipt_Line__c>> crIdpaymentCRLs = new Map<Id, List<Customer_Receipt_Line__c>>();
        set<Id> paymentCIs = new set<ID>();
        map<Id, Decimal> paymentCIAmounts = new map<Id,Decimal>();
        
        Set<Id> crIds = crIdPrepaymentAppliedCRL.keyset();
            SOQLUtil soql1 = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
        soql1.addFields(new set<string>{
                'Id','Amount__c','Customer_Receipt__c', 'Customer_Invoice__c', 
                 'Customer_Invoice__r.Amount_Paid__c', 'Customer_Invoice__r.Balance__c'
        });
        
        soql1.setWhereClause('Customer_Receipt__c in :crIds and Type__c = \'Payment\' and Customer_Receipt__r.Status__c = \'Closed\' and Finalized__c = true order by CreatedDate desc');
        List<Customer_Receipt_Line__c> paymentCRLs = (List<Customer_Receipt_Line__c>)Database.query(soql1.getQuery());

       for (Customer_Receipt_Line__c crl: paymentCRLs){
           if(!paymentCIAmounts.containsKey(crl.Customer_Invoice__c)){
               paymentCIAmounts.put(crl.Customer_Invoice__c, crl.Amount__c);
           }
           else {
               paymentCIAmounts.put(crl.Customer_Invoice__c,paymentCIAmounts.get(crl.Customer_Invoice__c) + crl.Amount__c);
           }
       }
       system.debug('paymentCIAmounts after collecting payment  '+paymentCIAmounts);
       if(!paymentCIAmounts.isEmpty()) {
           Set<Id> ciIds = paymentCIAmounts.keySet();
           String crlwhereClause = ' type__c = \'Refund applied prepayment\'';
           crlwhereClause  += ' and Customer_Receipt__r.Related_Customer_Receipt__c = :relatedCRId';
           crlwhereClause  += ' and Customer_Receipt__r.Type__c = \'Refund\'';
           crlwhereClause  += ' and Customer_Receipt__r.Status__c = \'Closed\' and Finalized__c  = true';
           crlwhereClause  += ' and Customer_Invoice__c = :ciIds';
           soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
           soql.addFields(new set<string>{
                    'Id','Amount__c','Customer_Invoice__c'
           });
           
           soql.setWhereClause(crlwhereClause);
           List<Customer_Receipt_Line__c> refundAppliedPrepaymentCRLs = (List<Customer_Receipt_Line__c>)Database.query(soql.getQuery());
       
               for(Customer_Receipt_Line__c crl : refundAppliedPrepaymentCRLs) {
                   system.debug('crl '+crl);
                   Decimal amt = paymentCIAmounts.get(crl.Customer_Invoice__c);
                   system.debug('amt before '+amt);
                   amt += crl.Amount__c;
                   system.debug('amt after '+amt);
                   paymentCIAmounts.put(crl.Customer_Invoice__c,amt);                                    
               }
       }
       
       system.debug('paymentCIAmounts after collecting refund applied prepayment '+paymentCIAmounts);
       // This amount needs to be put back on the CIs associated with Payment CRLs
       Decimal remainingAmountToRefund = amountToRefund;

       for (Id invoiceId : paymentCIAmounts.keySet()){
          Decimal ciAmountToPutBack;
          decimal invoiceAmountAvailable = paymentCIAmounts.get(invoiceId);
          if(invoiceAmountAvailable == 0) {//its already beeen fully rest
              continue;
          }
          // payment on CRL >= refund amount
          if (invoiceAmountAvailable >= remainingAmountToRefund){
              ciAmountToPutBack = remainingAmountToRefund;
              remainingAmountToRefund = 0;
          }
          // payment on CRL< refund amount
          if (invoiceAmountAvailable < remainingAmountToRefund){
              ciAmountToPutBack = invoiceAmountAvailable;
              remainingAmountToRefund = remainingAmountToRefund - invoiceAmountAvailable;
          }
                
          // create new CRL showing how much was put back on CI
          lCRLs.add(new Customer_Receipt_Line__c(Customer_Receipt__c = cr.Id, Amount__c = (-1) * ciAmountToPutBack,  Type__c = PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT, Customer_Invoice__c = invoiceId, Memo__c = memoText));
          if(remainingAmountToRefund == 0){
                break;//if within the inner loop it goes to zero we should break!
          }
       }
       system.debug('lCRLs '+lCRLs);
    }
    
    public boolean voidTransaction(string referenceId, string referenceTransactionId){
        /*
        <createTransactionRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
          <merchantAuthentication>
            <name>API_LOGIN_ID</name>
            <transactionKey>API_TRANSACTION_KEY</transactionKey>
          </merchantAuthentication>
          <refId>123456</refId>
          <transactionRequest>
            <transactionType>voidTransaction</transactionType>
            <refTransId>22434566</refTransId>
           </transactionRequest>
        </createTransactionRequest>
        */
        
        Dom.Document reqDoc = new Dom.Document();
        reqDoc.createRootElement('createTransactionRequest', null, null);
        Dom.XMLNode reqRoot = reqDoc.getRootElement();
        reqRoot.setAttribute('xmlns', authNetNS);
        
        addMerchantAuthentication(reqDoc);
        
        reqRoot.addChildElement('refId', null, null);
        Dom.XMLNode refId = reqRoot.getChildElement('refId', null);
        refId.addTextNode(referenceId == null ? '' : referenceId);
        
        reqRoot.addChildElement('transactionRequest', null, null);
        Dom.XMLNode transactionRequest = reqRoot.getChildElement('transactionRequest', null);
        
        transactionRequest.addChildElement('transactionType', null, null);
        Dom.XMLNode transactionType = transactionRequest.getChildElement('transactionType', null);
        transactionType.addTextNode('voidTransaction'); 
        
        transactionRequest.addChildElement('refTransId', null, null);
        Dom.XMLNode refTransId = transactionRequest.getChildElement('refTransId', null);
        refTransId.addTextNode(referenceTransactionId); 
        
        HttpResponse resp = sendRequest('POST', reqDoc.toXMLString());
        
        return parseVoidTransaction(referenceId, referenceTransactionId, resp.getBodyDocument());
    }
    
    private boolean parseVoidTransaction(string referenceId, string referenceTransactionId, Dom.Document respDoc){
        
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <createTransactionResponse>
          <refId>123456</refId>
          <messages>
            <resultCode>Ok</resultCode>
            <message>
              <code>I00001</code>
              <text>Successful.</text>
            </message>
          </messages>
          <transactionResponse>
            <responseCode>1</responseCode>
            <authCode>UGELQC</authCode>
            <avsResultCode>E</avsResultCode>
            <cavvResultCode />
            <transId>2148061808</transId>
            <refTransID />
            <transHash>0B428D8A928AAC61121AF2F6EAC5FF3F</transHash>
            <testRequest>0</testRequest>
            <accountNumber>XXXX0015</accountNumber>
            <accountType>MasterCard</accountType>
            <message>
              <code>1</code>
              <description>This transaction has been approved.</description>
            </message>
            <userFields>
              <userField>
                <name>MerchantDefinedFieldName1</name>
                <value>MerchantDefinedFieldValue1</value>
              </userField>
              <userField>
                <name>favorite_color</name>
                <value>lavender</value>
              </userField>
            </userFields>
          </transactionResponse>
        </createTransactionResponse>
        */
        
        
        Dom.XMLNode respRoot = respDoc.getRootElement();
        Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);
        for(Dom.XMLNode node : respRoot.getChildren()){
            system.debug(node.getName() + ' ' + node.getNamespace());
        }
        if(resultCode.getText().equalsIgnoreCase('I00001')){
            
            Dom.XMLNode transactionResponse = respRoot.getChildElement('transactionResponse', authNetNS);
            
            Dom.XMLNode responseCode = transactionResponse.getChildElement('responseCode', authNetNS);
            string respCodeVal = responseCode.getText();
            
            system.debug('respCodeVal: ' + respCodeVal);
            
            map<string, string> mResponseCodes = new map<string, string>{'1'=>'Approved', '2'=>'Declined', '3'=>'Error', '4'=>'Held for Review'};
            
            
            


            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Amount_Received__c','Transaction_Date__c','Finalized_Date__c','Posting_Date__c','Finalized__c','Finalized_Hidden__c',
                'Void__c','Void_Date__c','Status__c','Historical__c',  'Company__r.Default_transaction_Currency__c'
            });
            soql.setWhereClause('Transaction_ID__c = :referenceTransactionId');
            List<Customer_Receipt__c> refCRs = Database.query(soql.getQuery());



                                        
            Customer_Receipt__c refCR;
            if(refCRs.size() == 1){
                refCR = refCRs[0];
            }else{
                system.debug('found more than 1 CR for trxnId ' + referenceTransactionId);
                throw new PaymentHandlerException('Unable to complete refund, more than 1 Transaction Id was found for ' + referenceTransactionId);
            }   
            
            boolean isSuccess = false;                      
            if(respCodeVal == '1'){ //Approved
                isSuccess = true;
                }
            
            return isSuccess;
            
        }else{
            throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('text', authNetNS).getText());
        }
        
        
    }
   
    public boolean isTransactionRefundable(string transactionId) {
        
        PaymentHandler.TransactionDetail td = getTransaction(transactionId);
        if(td.transactionStatus == 'capturedPendingSettlement')
            return false;
        else if(td.transactionStatus == 'settledSuccessfully')
           return true;
        else 
            return false;
    }
   
    
    public TransactionDetail getTransaction(string transactionId){
        /*
        <getTransactionDetailsRequest xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
              <merchantAuthentication>
                <name>96bc46uTwG7P</name>
                <transactionKey>58d34Ramy8f45WJQ</transactionKey>
              </merchantAuthentication>
              <transId>12345</transId>
        </getTransactionDetailsRequest>
        */
        
        Dom.Document reqDoc = new Dom.Document();
        reqDoc.createRootElement('getTransactionDetailsRequest', null, null);
        Dom.XMLNode reqRoot = reqDoc.getRootElement();
        reqRoot.setAttribute('xmlns', authNetNS);
        
        addMerchantAuthentication(reqDoc);
        
        reqRoot.addChildElement('transId', null, null);
        Dom.XMLNode transId = reqRoot.getChildElement('transId', null);
        transId.addTextNode(transactionId);
        
        HttpResponse resp = sendRequest('POST', reqDoc.toXMLString());
        
        return parseGetTransaction(transactionId, resp.getBodyDocument());
        
    }
    
    
    private TransactionDetail parseGetTransaction(string transactionId, Dom.Document respDoc){
        /*
        <?xml version="1.0" encoding="utf-8"?>
        <getTransactionDetailsResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd">
        <messages>
            <resultCode>Ok</resultCode>
            <message>
              <code>I00001</code>
              <text>Successful.</text>
            </message>
          </messages>
        <transaction>
            <transId>12345</transId>
            <refTransId>12345</refTransId> 
            <splitTenderId>12345</splitTenderId>
            <submitTimeUTC>2010-08-30T17:49:20.757Z</submitTimeUTC>
            <submitTimeLocal>2010-08-30T13:49:20.757</submitTimeLocal>
            <transactionType>authOnlyTransaction</transactionType> 
            <transactionStatus>settledSuccessfully</transactionStatus> 
            <responseCode>1</responseCode>
            <responseReasonCode>1</responseReasonCode>
            <responseReasonDescription> Approval</responseReasonDescription>
            <authCode>000000</authCode> 
            <AVSResponse>X</AVSResponse>
            <cardCodeResponse>M</cardCodeResponse>
            <CAVVResponse>2</CAVVResponse> 
          <FDSFilterAction>authAndHold</FDSFilterAction> 
            <FDSFilters>
              <FDSFilter>
                <name>Hourly Velocity Filter</name>
                <action>authAndHold</action>
              </FDSFilter>
              <FDSFilter>
                <name>Amount Filter</name>
                <action>report</action>
              </FDSFilter>
            </FDSFilters>
            <batch> 
              <batchId>12345</batchId>
              <settlementTimeUTC>2010-08-30T17:49:20.757Z</settlementTimeUTC>
              <settlementTimeLocal>2010-08-30T13:49:20.757</settlementTimeLocal>
              <settlementState>settledSuccessfully</settlementState>
            </batch>
            <order>
              <invoiceNumber>INV00001</invoiceNumber>
              <description>some description</description>
              <purchaseOrderNumber>PO000001</purchaseOrderNumber>
            </order>
            <requestedAmount>5.00</requestedAmount> 
            <authAmount>2.00</authAmount>
            <settleAmount>2.00</settleAmount>
            <tax>
              <amount>1.00</amount>
              <name>WA state sales tax</name>
              <description>Washington state sales tax</description>
            </tax>
            <shipping>
              <amount>2.00</amount>
              <name>ground based shipping</name>
              <description>Ground based 5 to 10 day shipping</description>
            </shipping>
            <duty>
              <amount>1.00</amount>
            </duty>
          <lineItems>
              <lineItem>
                <itemId>ITEM00001</itemId>
               <name>name of item sold</name>
                <description>Description of item sold</description>
                <quantity>1</quantity>
                <unitPrice>6.95</unitPrice>
                <taxable>true</taxable>
              </lineItem>
              <lineItem>
                <itemId>ITEM00001</itemId>
                <name>name of item sold</name>
                <description>Description of item sold</description>
                <quantity>1</quantity>
                <unitPrice>6.95</unitPrice>
                <taxable>true</taxable>
              </lineItem>
            </lineItems>
            <prepaidBalanceRemaining>30.00</prepaidBalanceRemaining>
            <taxExempt>false</taxExempt>
            <payment>
              <!-- either creditCard or bankAccount will be here -->
              <creditCard>
                <cardNumber>XXXX1111</cardNumber>
                <expirationDate>XXXX</expirationDate>
                <accountType>Visa</accountType>
              </creditCard>
              <!--<bankAccount>
                <routingNumber>XXXX0000</routingNumber>
                <accountNumber>XXXX0000</accountNumber>
                <nameOnAccount>John Doe</nameOnAccount>
                <echeckType>WEB</echeckType>
              </bankAccount>-->
            </payment>
            <customer>
              <type>individual</type> 
              <id>ABC00001</id>
              <email>mark@example.com</email>
            </customer>
            <billTo>
              <firstName>John</firstName>
              <lastName>Doe</lastName>
              <company></company>
              <address>123 Main St.</address>
              <city>Bellevue</city>
              <state>WA</state>
              <zip>98004</zip>
              <country>USA</country>
              <phoneNumber>000-000-0000</phoneNumber>
              <faxNumber></faxNumber>
            </billTo>
            <shipTo>
              <firstName>John</firstName>
              <lastName>Doe</lastName>
              <company></company>
              <address>123 Main St.</address>
              <city>Bellevue</city>
              <state>WA</state>
              <zip>98004</zip>
              <country>USA</country>
            </shipTo>
            <recurringBilling>false</recurringBilling>
            <customerIP>0.0.0.0</customerIP>
            <subscription>
              <id>145521</id>
              <payNum>1</paynum>
          <marketType>eCommerce</marketType>
          <product>Card Not Present</product>
          <returnedItems>
            <returnedItem>
              <id>2148878904</id>
              <dateUTC>2014-05-12T21:22:44Z</dateUTC>
              <dateLocal>2014-05-12T14:22:44</dateLocal>
              <code>R02</code>
              <description>Account Closed</description>
            </returnedItem>
          </returnedItems>
          <solution>
            <id>A1000004</id>
            <name>Shopping Cart</name>
          </solution>
          <mobileDeviceiD>2354578983274523978</mobileDeviceId>
            </subscription>
           </transaction>
        </getTransactionDetailsResponse>
        */
        //There is a lot here to glean, but I only want a little bit of this for now...
        //As needed, add more attributes to the TransactionDetail wrapper
        Dom.XMLNode respRoot = respDoc.getRootElement();
        Dom.XMLNode resultCode = respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('code', authNetNS);

        if(resultCode.getText().equalsIgnoreCase('I00001')){
            system.debug('successful trxn details');
            TransactionDetail td = new TransactionDetail();
            Dom.XMLNode trxn = respRoot.getChildElement('transaction', authNetNS);
            td.transactionId = trxn.getChildElement('transId', authNetNS).getText();
            if(trxn.getChildElement('refTransId', authNetNS) != null){
                td.referenceId = trxn.getChildElement('refTransId', authNetNS).getText();
            }
            td.transactionType = trxn.getChildElement('transactionType', authNetNS).getText();
            td.transactionStatus = trxn.getChildElement('transactionStatus', authNetNS).getText();
            td.transactionDate = getLocalDateTime(parseUTCString(trxn.getChildElement('submitTimeUTC', authNetNS).getText()));
            system.debug('td: ' + td);
            return td;
        }else{
            throw new PaymentHandlerException('Unable to complete request: ' + respRoot.getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('text', authNetNS).getText());
        }
        
    }
    
    /*
     *  Utility Methods
     */
     
    //This method is a necessary evil...
    private DateTime parseUTCString(string UTCDateTime){
        //2010-05-30T09:00:00
        integer yyyy = integer.valueOf(UTCDateTime.left(4));
        integer MM = integer.valueOf(UTCDateTime.mid(5,2));
        integer dd = integer.valueOf(UTCDateTime.mid(8,2));
        integer hh = integer.valueOf(UTCDateTime.mid(11,2));
        integer min = integer.valueOf(UTCDateTime.mid(14,2));
        integer ss = integer.valueOf(UTCDateTime.mid(17,2));
        DateTime dt = DateTime.newInstanceGMT(yyyy, MM, dd, hh, min, ss);
        system.debug('UTCDateTime: ' + UTCDateTime + ' - ' + dt);
        return dt;
    }
    
    private Datetime getLocalDateTime(Datetime gmtDt){
        TimeZone tz = UserInfo.getTimeZone();
        integer seconds = tz.getOffset(gmtDt)/1000;
        return gmtDt.addSeconds(seconds);
    }
    
    private HttpResponse sendRequest(string method, string body){
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'text/xml');
        req.setMethod(method);
        req.setBody(body);
        
        system.debug('endpoint: ' + req.getEndpoint());
        system.debug('body: ' + req.getBody());
        
        Http http = new Http();
        
        HttpResponse resp = http.send(req);
        system.debug('resp code: ' + resp.getStatusCode());
        system.debug('resp: ' + resp.getBody());
        
        return resp;
        
    }
    
    //Sign the request with the auth id and transaction key
    private void addMerchantAuthentication(Dom.Document doc){
        /*
        <merchantAuthentication>
            <name>API_LOGIN_ID</name>
            <transactionKey>API_TRANSACTION_KEY</transactionKey>
        </merchantAuthentication>
        */
        Dom.XMLNode root = doc.getRootElement();
        root.addChildElement('merchantAuthentication', null, null);
        Dom.XMLNode merchAuth = root.getChildElement('merchantAuthentication', null);
        
        merchAuth.addChildElement('name', null, null);
        Dom.XMLNode name = merchAuth.getChildElement('name', null);
        name.addTextNode(this.apiLoginId);
        
        merchAuth.addChildElement('transactionKey', null, null);
        Dom.XMLNode trxnKey = merchAuth.getChildElement('transactionKey', null);
        trxnKey.addTextNode(this.transactionKey);
        
    }
    
    /* Test CC Numbers */
    /*
    
    - American Express Test Card: 370000000000002
    - Discover Test Card: 6011000000000012
    - Visa Test Card: 4007000000027
    - Second Visa Test Card: 4012888818888
    - JCB: 3088000000000017
    - Diners Club/ Carte Blanche: 38000000000006
    
    */
    
    private map<string, string> parseGatewayResponse(string validationDirectResponse){
        map<string, string> mResponseVals = new map<string, string>();
        List<string> vals = validationDirectResponse.split(',');
        for(integer i=0; i<vals.size(); i++){
            integer respCode = i+1;
            mResponseVals.put(mGatewayResponse.get(respCode), vals[i]);
        }
        return mResponseVals;
    }
    
    private String response (Dom.XMLNode respRoot) {
        String response = '';
        boolean hasMessageTag = (respRoot.getChildElement('transactionResponse', authNetNS).getChildElement('message', authNetNS)) != null ? true : false;
        if(hasMessageTag)
            response = respRoot.getChildElement('transactionResponse', authNetNS).getChildElement('message', authNetNS).getChildElement('description', authNetNS).getText();
        else
            response = respRoot.getChildElement('transactionResponse', authNetNS).getChildElement('messages', authNetNS).getChildElement('message', authNetNS).getChildElement('description', authNetNS).getText();
        return response;
    }
    
    //This is the ordinal values of the comma delimited values in the validationDirectResponse tag
    //Used with the parseGatewayResponse method above to map out the keys and values
    private map<integer, string> mGatewayResponse = new map<integer, string>{
        1 => 'Response Code', 
        2 => 'Response Subcode', 
        3 => 'Response Reason Code', 
        4 => 'Response Reason Text', 
        5 => 'Authorization Code', 
        6 => 'AVS Response', 
        7 => 'Transaction ID', 
        8 => 'Invoice Number', 
        9 => 'Description', 
        10 => 'Amount', 
        11 => 'Method', 
        12 => 'Transaction Type', 
        13 => 'Customer ID', 
        14 => 'First Name', 
        15 => 'Last Name', 
        16 => 'Company', 
        17 => 'Address', 
        18 => 'City', 
        19 => 'State', 
        20 => 'ZIP Code', 
        21 => 'Country', 
        22 => 'Phone', 
        23 => 'Fax', 
        24 => 'Email Address', 
        25 => 'Ship To First Name', 
        26 => 'Ship To Last Name', 
        27 => 'Ship To Company', 
        28 => 'Ship To Address', 
        29 => 'Ship To City', 
        30 => 'Ship To State', 
        31 => 'Ship To ZIP Code', 
        32 => 'Ship To Country', 
        33 => 'Tax', 
        34 => 'Duty', 
        35 => 'Freight', 
        36 => 'Tax Exempt', 
        37 => 'Purchase Order Number', 
        38 => 'MD5 Hash', 
        39 => 'Card Code Response', 
        40 => 'Cardholder Authentication Verification Response', 
        51 => 'Account Number', 
        52 => 'Card Type', 
        53 => 'Split Tender ID', 
        54 => 'Requested Amount', 
        55 => 'Balance On Card'
    };
    
}