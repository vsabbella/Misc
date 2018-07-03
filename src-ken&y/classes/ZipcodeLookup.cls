public with sharing class ZipcodeLookup {

    static string api_username;
   
    
    public static void getUsername(){
        
        if(service_configuration__c.getValues('usps')!= null){
            service_configuration__c sc = service_configuration__c.getValues('usps');
            api_username = sc.username__c;
        }
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please define the Custom Settings: Service Configuration for USPS API'));
        }
        
    }
    


    public static List<string> callApiWithRequest(String accountId,String addressKey, String streetAddress, String city, String state){
    
                                
        String httpCalloutApiString = 'http://production.shippingapis.com/ShippingAPI.dll?API=Verify &XML=';
        String httpCalloutApiStringXML;

        httpCalloutApiStringXML = '<AddressValidateRequest USERID="'+api_username+'" >'  
                                +'<Address ID="0">'
                                +'<Address1></Address1>'
                                +'<Address2>'+streetAddress+'</Address2>'
                                +'<City>'+city+'</City>'
                                +'<State>'+state+'</State>'
                                +'<Zip5></Zip5><Zip4></Zip4>'
                                +'</Address>'
                                +'</AddressValidateRequest>';                       
                                
        string encodedCalloutString = httpCalloutApiString + EncodingUtil.urlEncode(httpCalloutApiStringXML, 'UTF-8');
        
        // Instantiate a new http object
        Http h = new Http();
    
        // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
        HttpRequest request = new HttpRequest();
        request.setEndpoint(encodedCalloutString);
       
        request.setMethod('GET');
    
        // Send the request, and return a response
        HttpResponse response = h.send(request);
       
         return getZipcodeFromXML(response.getBody());
       
    }
    
    public static List<string> getZipcodeFromXML(String xmlString){
        
        
        List<String> AddressString = new List<String>();
        String primaryZipCode;
        String zipCodeExtension;
        System.debug('XMLSTRING'+ xmlString);
        XmlStreamReader xsr = new XmlStreamReader(xmlString);
        
        while(xsr.hasNext()) {
            
                if(xsr.getLocalName() == 'Address2'){ 
                    xsr.next();
                    if(xsr.getEventType() == XmlTag.CHARACTERS){
                        AddressString.add(xsr.getText());
                        System.debug('checkHere'+ xsr.getText());
                        
                    }
                }
                else if(xsr.getLocalName() == 'City'){
                    xsr.next();
                    if(xsr.getEventType() == XmlTag.CHARACTERS){
                        AddressString.add(xsr.getText());
                        System.debug('checkHere'+ xsr.getText());
                    }
                }
                else if(xsr.getLocalName() == 'State'){
                    xsr.next();
                    if(xsr.getEventType() == XmlTag.CHARACTERS){
                        AddressString.add(xsr.getText());
                        System.debug('checkHere'+ xsr.getText());
                    }
                }
                else if(xsr.getLocalName() == 'Zip5'){ 
                    xsr.next();
                    if(xsr.getEventType() == XmlTag.CHARACTERS){
                        primaryZipCode = xsr.getText();
                        System.debug('checkHere'+primaryZipCode);
                    }
                }
                else if(xsr.getLocalName() == 'Zip4'){
                    xsr.next();
                    if(xsr.getEventType() == XmlTag.CHARACTERS){
                        zipCodeExtension = xsr.getText();
                        System.debug('checkHere'+ xsr.getText());
                    }
                }
                else if(xsr.getLocalName() == 'Description'){ //Error Description if the callout does not return the expected response
                    xsr.next();
                    if(xsr.getEventType() == XmlTag.CHARACTERS)
                     
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.ValueOf(xsr.getText())));
                }
                else
                    xsr.next();
       
            
        }
        
        
        if(primaryZipCode != null)
        {
            if(zipCodeExtension == null) zipCodeExtension = '0000';
            
            AddressString.add(primaryZipCode+'-'+zipCodeExtension);
       
            return AddressString;
            
        }
        else 
            return null;
       
    }

}