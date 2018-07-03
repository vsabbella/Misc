/**
 * @author Sunil Murali
 * @description Authorize the Kenandy Gateway Oauth application
 *              As part of the design strategy, we will now have a single oauth application in Kenandy Core (ERP)
 *              Supplementary package to leech on this Kenandy Gateway for corresponding external apps
 * 
 * @Note Admin would need to add the instance url for hte remote site settings - this is only for the revokeToken method [** COMMENTED OUT ** ]
 */ 
global with sharing class GatewayExt {
    
    final String PARAM_IMMEDIATE                    =           '&immediate=false' ;
    final String PARAM_DISPLAY                      =           '&display=popup' ;
    
    final String TAG_REDIRECT_URI                   =           '&redirect_uri=' ;
    final String TAG_STATE                          =           '&state=' ;
    final String TAG_CLIENT_ID                      =           '&client_id=' ;
    
    public static final String PRIVATE_KEY          =           'RjsNra23ZzKY1xNwJ8fFoA==' ;            // AES128 private key | This is also set in the heroku instance as environment variable
    
    public static String BASE_URL_PRD               =           'https://kndy-api.herokuapp.com/v1/' ; 
    static String REDIRECT_URL_PRD                  =           'https://kndy-api.herokuapp.com/v1/oauth2/callback' ; 
    
    public static String BASE_URL_SBX               =           'https://kndy-api-snd.herokuapp.com/v1/' ; 
    static String REDIRECT_URL_SBX                  =           'https://kndy-api-snd.herokuapp.com/v1/oauth2/callback' ; 
    
    static String CLIENT_KEY_SBX                    =           '3MVG99OxTyEMCQ3jEuK9zvaFdf8vLuehpP3yqtMaNcRcoIZ1OOZmJhz1bZfyNVCz4OtMQxLpZT6szI6WhDQkB' ;   
    static String CLIENT_SECRET_SBX                 =           '3845195352991404699' ;
    
    static String CLIENT_KEY_PRD                    =           '3MVG99OxTyEMCQ3jEuK9zvaFdf_2YjCsyNiRBTH5grXagc1cYeySTENMXpoQ_o5DOb2c5K8sxwsUMmA8e_iAS' ;
    static String CLIENT_SECRET_PRD                 =           '8176035361969825726' ; 
    
    static final String SBX_URL                     =           'https://test.salesforce.com/services/oauth2/authorize?response_type=code' ;
    static final String PRD_URL                     =           'https://login.salesforce.com/services/oauth2/authorize?response_type=code' ;
    
    static final String APP_NAME_SBX                =           'Kenandy Sandbox' ;
    static final String APP_NAME_PRD                =           'Kenandy' ;
    
    ApexPages.StandardController  con ;
    public Boolean isButtonDisabled { get ; set ; }
    List<OAuthToken> oauths ;
    
    public String CLIENT_REQUEST_URL { get; set; }
    public static Organization org { get {
        if ( org == null ) {
            org = [SELECT Id, InstanceName, IsSandbox  FROM Organization LIMIT 1] ;            
        }
        return org  ;
    }set;}
    
    public GatewayExt ( ApexPages.StandardController  con ) {
        this.con = con ;
        oauths = getOAuthToken ( org.isSandbox ) ;
        isButtonDisabled = false ;
        
        String url = System.URL.getSalesforceBaseUrl().toExternalForm() + ApexPages.currentPage().getURL() ;
        // KNDY-13765
        url = url + ((url.indexOf('?') > -1 ) ? '&sbcheck=' + org.IsSandbox : '?sbcheck=' + org.IsSandbox ); 
        
        String encodedUrl = EncodingUtil.urlEncode(url, 'UTF-8') ;
        
        if ( org.isSandbox ) {
            CLIENT_REQUEST_URL = SBX_URL 
                                 + TAG_CLIENT_ID + CLIENT_KEY_SBX
                                 + TAG_REDIRECT_URI + REDIRECT_URL_SBX 
                                 + TAG_STATE + encodedUrl
                                 + PARAM_IMMEDIATE 
                                 + PARAM_DISPLAY;
                                                    
        }
        else {
            CLIENT_REQUEST_URL = PRD_URL 
                                 + TAG_CLIENT_ID + CLIENT_KEY_PRD
                                 + TAG_REDIRECT_URI + REDIRECT_URL_PRD 
                                 + TAG_STATE + encodedUrl
                                 + PARAM_IMMEDIATE 
                                 + PARAM_DISPLAY;
        }
        
        checkOAuth() ;
    }
    
    /**
     * Helper method which can be called from supplementary packages to check the authorization
     */ 
    global static Boolean isUserAuthorized () {
        if ( Test.isRunningTest() ) return true;
        List<OAuthToken> tokens = getOAuthToken ( org.isSandbox ) ;
        return (tokens != null && tokens.size() > 0 ) ; 
    }
    
    /** 
     * Redirecting the page to the auth url to start the oauth flow
     */ 
    public PageReference startDance1 () {
        return new PageReference ( CLIENT_REQUEST_URL ) ;
    }
    
    /**
     * This will revoke the tokens for the current user
     * Problem with adding revoke is admin/configurer will have to manually add Remote Site Settings -> with instance url as post install setup
     * Doesn't warrent the need for this atm as admin can go to Conencted App OAuth Usage to revoke access 
     * 
     * Refer to : https://help.salesforce.com/HTViewHelpDoc?id=remoteaccess_revoke_token.htm
     * Refer to : https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_oauthtoken.htm
     */ 
    /*public PageReference revokeToken () {
        Http http = new Http () ;
        HttpResponse res = new HttpResponse();
        HttpRequest req = new HttpRequest () ;
 
        // This endpoint needs to be added to the Remote Site Settings
        String endpoint = 'https://'+org.InstanceName.toLowerCase()+'.salesforce.com/services/oauth2/revoke' ;
        endpoint += '?token=' +EncodingUtil.urlEncode( oauths.get(0).DeleteToken ,'UTF-8') ;
        
        req.setEndpoint( endpoint ) ;
        req.setMethod('GET') ;
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded'); 
        try {
            res = http.send ( req ) ;
            if ( res.getStatusCode() == 200 ) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'Successfully revoked Kenandy Gateway access!'  ) ) ;    
                PageReference pr = new PageReference (ApexPages.currentPage().getUrl())  ;
                pr.setRedirect(true) ;
                return pr ;
            }
            else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, 'Error revoking access for Kenandy Gateway!'  + res.getBody()) ) ;
                return null ;
            }
        }
        catch (Exception e ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL , e.getMessage()  ) ) ;
            return null ;
        }
    }*/
    
    public void checkOAuth(){ 
        String error = ApexPages.currentPage().getParameters().get('error') ;
        if ( error !=null && error!='') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL,error + ':' +ApexPages.currentPage().getParameters().get('error_description')  ) ) ;
            return;
        }
        
        if ( oauths!=null && oauths.size() > 0 ) {
            isButtonDisabled = true ;
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'You are authorized for Kenandy Gateway!'  ) ) ;
            return ;
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'You are not authorized for Kenandy Gateway !'  ) ) ;   
            return ;
        }
    }
    
    /** 
     * Getting OAuth token info for the current user - lastuseddate first. Delete Token will be used to revoke the app for User 
     */ 
    static List<OAuthToken> getOAuthToken ( Boolean isSandbox ) {
        String userId = UserInfo.getUserId().substring(0,15);
        if ( isSandbox ) {
            return [SELECT id, Appname, AccessToken, DeleteToken, REquestToken, UserId FROM OAuthToken WHERE AppName = :APP_NAME_SBX AND UserId = :userId ORDER BY LastUsedDate DESC LIMIT 1] ;
        }
        else {
            return [SELECT id, Appname, AccessToken, DeleteToken, REquestToken, UserId FROM OAuthToken WHERE AppName = :APP_NAME_PRD AND UserId = :userId ORDER BY LastUsedDate DESC LIMIT 1] ;
        }
    }
}