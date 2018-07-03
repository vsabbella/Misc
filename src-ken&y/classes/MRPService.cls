public class MRPService {
    public class MRPException extends Exception {}
    
    public static final String STATUS_RUNNING    = 'Running' ;
    public static final String STATUS_FAILED     = 'Failed' ;
    public static final String STATUS_COMPLETE   = 'Complete' ;
    
    static final String APPLICATION_ERP   = 'erp' ;
    static final String OPERATION_GENERATEMRP = 'generateMrp' ;
    
    public static final Integer HTTP_STATUS_OK   = 200 ;
    
    static final String METHOD_POST = 'POST' ;
    
    public static void startMRPGenerate ( Id mrpRunId ) {
        String endpoint ; 
        if ( GatewayExt.org.isSandbox ) {
            endpoint = GatewayExt.BASE_URL_SBX + APPLICATION_ERP + '/' + OPERATION_GENERATEMRP ;
        }
        else {
            endpoint = GatewayExt.BASE_URL_PRD  + APPLICATION_ERP + '/' + OPERATION_GENERATEMRP ;
        }
        
        // for authenticating the incoming request - mandatory parameter required by the web service 
        //endpoint += '?access_token='+ EncodingUtil.urlEncode( session , 'UTF-8') ;
        
        // Defining the payload for the mrp run requests
        RequestBody payload = new RequestBody () ;
        payload.Application = APPLICATION_ERP ;
        payload.Operation = OPERATION_GENERATEMRP ;
        payload.mrpRunId = mrpRunId ;
        payload.UserId = UserInfo.getUserId() ;
        payload.OrgId = UserInfo.getOrganizationId() ;
        payload.Instance = GatewayExt.org.InstanceName ;
        
        Blob pKey = Blob.valueOf( GatewayExt.PRIVATE_KEY ) ;                   // Random PKEY string 
        Blob input = Blob.valueOf ( payload.UserId+payload.OrgId ) ;
        
        Blob hash = Crypto.generateMAc('hmacSHA256' , input , pKey ) ; 
        String hashStr = String.valueOf ( JSON.deserializeUntyped( JSON.serialize(hash) ) ) ;
        
        HTTPRequest req = new HTTPRequest () ;
        req.setMethod( METHOD_POST ) ;
        req.setBody( JSON.serialize( payload ) ) ;
        req.setEndpoint( endpoint ) ;
        req.setHeader('Content-Type', 'application/json') ;
        req.setHeader ('kndy-authorization' , hashStr ) ;           // Kenandy API specific auth header
		
        Http http = new Http();
        
        try {
            HTTPResponse response = http.send( req );
            system.debug ( response.getBody() ) ;
            if ( response.getStatusCode() != HTTP_STATUS_OK ) {
                throw new MRPException  (response.getStatus() ) ;
            }
        }
        catch ( Exception e ) {
            MRP_Run__c mrpRun = new MRP_Run__c(id=payload.mrpRunId );
            mrpRun.Completion_Status__c = STATUS_FAILED ;
            mrpRun.Failure_Message__c = e.getMessage () ;
            update mrpRun ;
        }
    }
    
    
    @future ( callout = true )
    public static void startMRPGenerateFuture ( Id mrpRunId ) {
        startMRPGenerate ( mrpRunId );
    }
    
    public static void sendEmailAfterJobCompletion ( Map<ID,Mrp_Run__c> mapMRPRuns ) {
        // Escaping the  limit errors
        if ( Limits.getEmailInvocations() >= Limits.getLimitEmailInvocations() || (Limits.getEmailInvocations() + mapMRPRuns.size() ) >= Limits.getLimitEmailInvocations() ) return;
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>() ;
        
        MRPSettingsService settings = new MRPSettingsService () ;
        
        for ( Id mrpRunId : mapMRPRuns.keySet() ) {
            Mrp_Run__c mrpRun = mapMRPRuns.get( mrpRunId ) ;
            String validStatuses = 'Complete|Failure|Failed' ;
            if ( validStatuses.contains(mrpRun.Completion_Status__c) == false ) {
            	continue ;
            }
            String recId = mrpRun.Company__c ;
            if ( mrpRun.Facility__c != null ) recId += '-' + mrpRun.Facility__c ;
            settings.mrp_complete ( recId ) ;
            String subject = mrpRun.Completion_Status__c.equals ( STATUS_COMPLETE ) ? 'SUCCESS - MRP Job Completed' : 'FAILURE - MRP Job encountered errors' ;
            
            String body  = 'MRP Run: ' +  mrpRun.Name  + '<br />';
            body += 'Start Time: ' + mrpRun.CreatedDate  + '<br />';
            body += 'End Time: ' + mrpRun.LastModifiedDate + '<br />' ;
            body += 'Completion Status: ' + mrpRun.Completion_Status__c   + '<br />';
            body += 'Failure Message: ' + (mrpRun.Failure_Message__c==null?'':mrpRun.Failure_Message__c)   + '<br />';
            
            Messaging.SingleEmailMessage singleRequest = new Messaging.SingleEmailMessage();
            singleRequest.setTargetObjectId( mrpRun.CreatedById );
            singleRequest.setSaveAsActivity(false);
            singleRequest.setSubject(subject);
            singleRequest.setHtmlBody( body ); 
            emailMessages.add ( singleRequest ) ;
        }
        
        if ( emailMessages.size() > 0 )
            Messaging.sendEmail( emailMessages );
    }
    
    public class RequestBody {
        public String Application {get;set;}
        public String Operation {get;set;}
        public String mrpRunId {get;set;}
        public String OrgId {get;set;}
        public String UserId { get;set;}
        public String Instance {get;set;}
    }
}