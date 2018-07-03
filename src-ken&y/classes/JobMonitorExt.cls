public class JobMonitorExt {
    public class JobMonitorException extends Exception {}
    
    @RemoteAction
    public static String getBackgroundJobs () {
        String UserId = UserInfo.getUserId() ;
        String OrgId = UserInfo.getOrganizationId() ;
        
        Organization org = [ SELECT isSandbox, InstanceName FROM Organization ] ;
        
        String baseUrl ;
        
        if ( org.isSandbox ) {
            baseUrl = GatewayExt.BASE_URL_SBX ;
        }
        else {
            baseUrl = GatewayExt.BASE_URL_PRD ;
        }
        
        String endPoint = baseUrl + 'stats/jobs/'
                                  + OrgId
                                  + '/'
                                  + UserId ;
                                  
        
        // Signing the outbound request with a hmac key
        Blob pKey = Blob.valueOf( GatewayExt.PRIVATE_KEY ) ;
        Blob input = Blob.valueOf ( UserId + OrgId ) ;
        
        Blob hash = Crypto.generateMAc('hmacSHA256' , input , pKey ) ; 
        String hashStr = String.valueOf ( JSON.deserializeUntyped( JSON.serialize(hash) ) );
        
        Http http = new Http () ;
        HTTPRequest req = new HTTPRequest () ;
        req.setEndpoint( endPoint ) ;
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        
        req.setHeader ('kndy-authorization' , hashStr ) ;
        req.setMethod( 'POST' );
        
        try {
            HTTPResponse res = http.send ( req ) ;
            if ( res.getStatusCode() == 404 ) throw new JobMonitorException ( res.getBody() ) ;
            return String.valueOf ( res.getBody() );
        }
        catch ( Exception e ) {
            return JSON.serialize( new JobStatus (e.getMessage() , false ) ) ;
        }
    }
    
    class JobStatus {
        public Boolean isSuccessful {get;set;}
        public String message {get;set;}
        
        public JobStatus (String message , Boolean isSuccessful ) {
            this.isSuccessful = isSuccessful ;
            this.message = message ;
        }
    }
}