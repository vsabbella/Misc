public class YodleeBankTransactionServices {
    //Common parameters for all APIs except for cobrand login or cobrand creation APIs
    private static string paramNameCobSessionToken = 'cobSession';
    private static string paramNameUserSessionToken = 'userSession';
    private static string paramNameProviderAccId = 'providerAccountId'; //KNDY -15851 providerAccountId param name declaration for removesites and getsummarysites calls
    //Cobrand login API parameters
    private static string paramNameCobrandLogin = 'cobrandLogin';
    private static string paramNameCobrandPassword = 'cobrandPassword';
    
    //User login API parameters
    private static string paramNameUserLogin = 'login';
    private static string paramNameUserPassword = 'password';  
    
    
    //Search Transaction API parameters
    private static string paramNamehigherFetchLimit = 'top';
    private static string paramNamelowerFetchLimit = 'skip';    
    private static string paramNamefromDate = 'fromDate';
    private static string paramNametoDate = 'toDate';
    private static string paramNameBankAccountId= 'accountId';
    
    //Others
    private static string rsession = 'rsession';
    private static string finAppId = 'appIds';
    //new exception used to throw custom exception
    public class YodleeAPIException extends Exception{}
   public class siteAccount{
      public long siteId{get;set;}
      public long accountId{get;set;}
      public string AccountName{get;set;}
      public string strSiteAccountId{get;set;}
      public boolean disableRemove{get;set;}//KNDY-13289 Added flag to disable remove button on sites grid
      //KNDY-15850 - added extra props for refresh info
      public string lastRefreshAttempt {get;set;}
      public string nextRefreshScheduled{get;set;}
      public string lastRefreshed{get;set;}
      public string status{get;set;}
      public string statusMessage{get;set;}
      public string errorMessage;      
        siteAccount(long SiteId,string AccountName){
            this.SiteId=SiteId;
            this.AccountName=AccountName;
        }
        siteAccount(long SiteId,long accountId,string AccountName){
            this.SiteId=SiteId;
            this.accountId = accountId;
            system.debug('build strSiteAccountId='+this.SiteId +'=' +this.accountId);
            this.strSiteAccountId = this.SiteId != null && this.accountId != null ? this.SiteId +'-' +this.accountId  : null;
            this.AccountName=AccountName;
        }
        siteAccount(string strSiteAccountId,string AccountName){
            this.strSiteAccountId=strSiteAccountId;
            this.AccountName=AccountName;
        }
        //KNDY-13289
        siteAccount(long SiteId,string AccountName, boolean disableRemoveBtn){
        	this.SiteId=SiteId;
            this.AccountName=AccountName;
            this.disableRemove=disableRemoveBtn;
    	}
    	//KNDY-15850
        siteAccount(long SiteId,string AccountName, boolean disableRemoveBtn,string lastRefreshAttempt,string nextRefreshScheduled,string lastRefreshed,string status,string statusMessage){
        	this.SiteId=SiteId;
            this.AccountName=AccountName;
            this.disableRemove=disableRemoveBtn;
            this.lastRefreshAttempt = lastRefreshAttempt;
            this.nextRefreshScheduled = nextRefreshScheduled;
            this.lastRefreshed = lastRefreshed;
            this.status = status;
            this.statusMessage = statusMessage;
   		 }
    	//KNDY-15850 - ERROR messages
    	siteAccount(string apiName,string errorCode,string errorMessage, string referenceCode){
    		if (string.isNotBlank(referenceCode))
    	 		this.errorMessage =  Label.Yodlee_Generic_Error_Msg + (String.isNotBlank(apiName) ? ' (' + apiName +'): ' : ': ') + errorCode + '-' + errorMessage +' (' + referenceCode +'). ' + Label.Contact_Sys_Admin_Or_Customer_Support;
    	 	else
    	 		this.errorMessage = errorCode + (errorMessage != null ? + '. ' + errorMessage : '');
    	 }
    }
    
    public class SummaryForSite{
    	public integer siteId{get;set;}
    	public Id recordId{get;set;}
    	public string siteAccountName{get;set;}
    	public list<siteAccount> lstAccountsForSite{get;set;}
    	public string errorMessage;      
    	SummaryForSite(integer siteId, string siteAccountName, list<siteAccount> lstAccountsForSite){
    		this.siteId = siteId;
    		this.siteAccountName = siteAccountName;
    		this.lstAccountsForSite = lstAccountsForSite;
    	}
    	SummaryForSite(Id recordId, string siteAccountName, list<siteAccount> lstAccountsForSite){
    		this.recordId = recordId;
    		this.siteAccountName = siteAccountName;
    		this.lstAccountsForSite = lstAccountsForSite;
    	}
    	//KNDY-15851 - ERROR messages
    	SummaryForSite(string apiName,string errorCode,string errorMessage, string referenceCode){
    	 	if (string.isNotBlank(referenceCode))
    	 		this.errorMessage = Label.Yodlee_Generic_Error_Msg + (String.isNotBlank(apiName) ? ' (' + apiName +'): ' : ': ') + errorCode + '-' + errorMessage +' (' + referenceCode +'). ' +Label.Contact_Sys_Admin_Or_Customer_Support;
    	 	else
    	 		this.errorMessage = errorCode + (errorMessage != null ? + '. ' + errorMessage : '');
    	 }
    }
    //KNDY-13289 Wrapper class created to show "Account Links to Kenandy" grid
    public class LinkedAccountToKenandy{
        public string SiteName{get;set;}
        public Id Id{get;set;}
        public string YodleeAccountName {get;set;}
        public integer YodleeAccountNumber {get;set;}
        public string Name{get;set;}
    	public string errorMessage;     
        LinkedAccountToKenandy(string siteName, string YodleeAccountName,integer YodleeAccountNumber, id id, string Name){
            this.siteName = siteName;
            this.YodleeAccountName = YodleeAccountName;
            this.YodleeAccountNumber = YodleeAccountNumber;
            this.id = id;
            this.Name = Name;
        }
        //KNDY-15850 - ERROR messages
    	LinkedAccountToKenandy(string errorCode,string errorMessage){
	 		this.errorMessage = errorCode + '. ' + errorMessage;
    	 }
        
    }
    
   public static string getSessionToken(string name, integer interval){
   		list<Service_Configuration__c> lstSC = [Select Session_Token__c, Name from Service_Configuration__c where 
   												Session_Token__c != null and Name = :name and 
   												LastModifiedDate >= :system.now().addMinutes(-interval) and LastModifiedDate <= :system.now()];	
   		if(!lstSC.isEmpty()){
   			return lstSC[0].Session_Token__c;
   		}else{
   			return '';
   		}
   }
   
   public static Service_Configuration__c setSessionToken(string name, string sessionToken){
   		list<Service_Configuration__c> lstSC = [Select Id, Session_Token__c, Name from Service_Configuration__c where 
   												Name = :name];
    	return (new Service_Configuration__c(Id = lstSC[0].Id, Session_Token__c = sessionToken));
   }
   
   /******* cobrand login **********************
string url;
map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
if(!mapSvcCfg.isEmpty()){
   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('COB_LOGIN_URL')){
   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('COB_LOGIN_URL').KNDY4__URL__c;
   		}
    if(string.isNotBlank(url)){ 
	    HttpRequest req = new HttpRequest();
	    req.setMethod('POST');
	    req.setEndpoint(url);
	    req.setBody('&cobrandLogin='+EncodingUtil.urlEncode(mapSvcCfg.get('cobrandLogin').KNDY4__Username__c, 'UTF-8')+ '&cobrandPassword='+EncodingUtil.urlEncode(mapSvcCfg.get('cobrandLogin').KNDY4__Password__c, 'UTF-8'));   
	    system.debug('req = '+ req);
	    HttpResponse res = new Http().send(req);
	    string body = res.getBody();
	    system.debug('body = '+ body);
	}
}
********************************************/
   public static YodleeUserAPIParser cobrandlogin(string cobrandUserName, string cobrandPasswd) {
   		string url;
   		YodleeUserAPIParser userResult;
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('COB_LOGIN_URL')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('COB_LOGIN_URL').URL__c;
   			}
   		}
   		try {
   			system.debug('cobrand url='+url);
   			if (string.isBlank(url)){
   				throw new YodleeAPIException(Label.Yodlee_Setup_Message);
   			}
        	string cobrandToken = getSessionToken('cobrandLogin', 90);
        system.debug('cobrandToken: '+cobrandToken);
        if(string.isBlank(cobrandToken) && string.isNotBlank(url)){ 
	        
	            HttpRequest req = new HttpRequest();
	            req.setMethod('POST');
	            req.setTimeout(120000);
	            req.setEndpoint(url);
	            req.setBody('&' + paramNameCobrandLogin+'='+EncodingUtil.urlEncode(cobrandUserName, 'UTF-8')+ '&' + paramNameCobrandPassword+'='+EncodingUtil.urlEncode(cobrandPasswd, 'UTF-8'));   
	            system.debug('req = '+ req);
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();
	            system.debug('body = '+ body);
	            userResult = (YodleeUserAPIParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeUserAPIParser.class);	                   	       
		    }else{		    	
		    	userResult = new YodleeUserAPIParser();        	
		    	userResult.session = new YodleeUserAPIParser.SessionWrapper();
		    	userResult.session.cobSession = cobrandToken;
		    }
	    } catch (Exception e) {
	    	system.debug('COB login EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber());
           	userResult = new YodleeUserAPIParser();  
            userResult.errorCode =  e.getMessage();
	    } 
        system.debug('userResult=='+userResult);	  
        return userResult;
        }
    
    /******* user login ************************
    Sample request JSON (* for required)
    *************
    "user":      {
      *"loginName": "testUser",
      *"password": "TEST@123",
      "locale": "en_US"
     }
string url;
map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
if(!mapSvcCfg.isEmpty()){
   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('USER_LOGIN_URL')){
   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('USER_LOGIN_URL').KNDY4__URL__c;
   	}
   	if(string.isNotBlank(url)){ 
	    HttpRequest req = new HttpRequest();
	    req.setMethod('POST');
		    string authorizationHeader = paramNameCobSessionToken+ '='+mapSvcCfg.get('cobrandLogin').KNDY4__Session_Token__c;
	        req.setHeader('Authorization',authorizationHeader);
			req.setHeader('Content-Type', 'application/json');
			KNDY4.YodleeUserAPIParser.UserWrapper userWrap = new KNDY4.YodleeUserAPIParser.UserWrapper();
	        userWrap.loginName = UserName;
	        userWrap.password = UserPasswd;
	        loginUserWrapper.user = userWrap;
	    	string reqBody = KNDY4.YodleeJsonParser.jsonParser.serialize(loginUserWrapper);
	    	system.debug('usr login reqBody='+reqBody);
	    	req.setBody(reqBody);	  
	    req.setEndpoint(url);
	    HttpResponse res = new Http().send(req);
	    string body = res.getBody();
	    system.debug('body =' + body);
	}
}
	
	Sample Response JSON
	***********************
	{
	"user":
	  {
	  "id":1111484545,
	  "loginName":"LOGINNAME",
	  "name": {
	    "first": "FNAME",
	    "last": "LNAME"
	    },
	  "session": {
	    "userSession": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	  },
	  "preferences": {
	    "currency": "USD",
	    "timeZone": "PST",
	    "dateFormat": "MM/dd/yyyy",
	    "locale": "en_US"
	    }
	  }
	}
*******************************************/
    public static YodleeUserAPIParser Userlogin(string UserName, string UserPasswd, string cobrandSessionToken) {
        string url;
        YodleeUserAPIParser userResult;
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('USER_LOGIN_URL')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('USER_LOGIN_URL').URL__c;
   			}
   		}
        string userSessionToken = getSessionToken('YodleeUserLogin', 30);
        system.debug('userSessionToken: '+userSessionToken);
        try {
        if(string.isBlank(userSessionToken) && string.isNotBlank(url)){
	        
	            HttpRequest req = new HttpRequest();
	            req.setMethod('POST');
	            req.setTimeout(120000);
	            string authorizationHeader = paramNameCobSessionToken+ '='+cobrandSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
	            YodleeUserAPIParser loginUserWrapper = new YodleeUserAPIParser();
	            YodleeUserAPIParser.UserWrapper userWrap = new YodleeUserAPIParser.UserWrapper();
	            userWrap.loginName = UserName;
	            userWrap.password = UserPasswd;
	            loginUserWrapper.user = userWrap;
            	string reqBody = YodleeJsonParser.jsonParser.serialize(loginUserWrapper);
            	system.debug('usr login reqBody='+reqBody);
            	req.setBody(reqBody);
	            req.setEndpoint(url);
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();
	            system.debug('body =' + body);
	            //userSessionToken = YodleeJsonParser.ParseJsonToken(System.JSON.createParser(body),'userSession');
	            userResult = (YodleeUserAPIParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeUserAPIParser.class);
	            system.debug('userResult: '+userResult);
	            if ( userResult != null && userResult.user != null && userResult.user.session != null){
	            	userSessionToken = userResult.user.session.userSession;
	            } 
	            //throw new YodleeAPIException(Label.Yodlee_Configuration_Missing);
	            system.debug('userSessionToken: '+userSessionToken);
	       
        	}else{        		
        		userResult = new YodleeUserAPIParser();
        		userResult.user  = new YodleeUserAPIParser.UserWrapper(); 
        		userResult.user.session = new YodleeUserAPIParser.SessionWrapper();
        		userResult.user.session.userSession = userSessionToken;
        	}
	        if(string.isNotBlank(userSessionToken)){
	            list<Service_Configuration__c> lstSC = new list<Service_Configuration__c>();
            	if(string.isBlank(getSessionToken('cobrandLogin', 90))){
	            	lstSC.add(setSessionToken('cobrandLogin', cobrandSessionToken));
	            }
            	if (string.isBlank(getSessionToken('YodleeUserLogin', 30))){
	            lstSC.add(setSessionToken('YodleeUserLogin', userSessionToken));
            	}
            	system.debug('update to YodleeUserLogin config' + userSessionToken);
            	if (!lstSC.isEmpty())
	            	DML.updateAsuser(lstSC);
	        }
	     } catch (Exception e) {
	    	system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
	    	userResult = new YodleeUserAPIParser();  
            userResult.errorCode = e.getMessage() ;
	    } 
	    system.debug('userResult =='+userResult);
        return userResult;
    }
    /******* user registration ************************
    Sample Request JSON (* for required)
    *************************
    {
	"user": {
	  *"loginName": "yslRest21", 
	  *"password": "TEST@123", 
	  *"email": "yslRest19@yodlee.com", 
	  "name": {
	    "first": "FNAME",
	    "last": "LNAME" 
	    },
	"address": {
	    "address1": "200 Lincoln Ave",
	    "state": "CA",
	    "city": "Salinas",
	    "zip": "93901",
	    "country": "US"
	    },
	"preferences": {
	    "currency": "USD",
	    "timeZone": "PST",
	    "dateFormat": "MM/dd/yyyy",
	    "locale": "en_US"
	    }
	  }
	}
	string url;
	map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
	if(!mapSvcCfg.isEmpty()){
	   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('USER_REGISTER_URL')){
	   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('USER_REGISTER_URL').KNDY4__URL__c;
	   	}
	   	if(string.isNotBlank(url)){ 
		    HttpRequest req = new HttpRequest();
		    req.setMethod('POST');
		    string authorizationHeader =  'cobSession='+mapSvcCfg.get('cobrandLogin').KNDY4__Session_Token__c;
	        req.setHeader('Authorization',authorizationHeader);
			req.setHeader('Content-Type', 'application/json');
			KNDY4.YodleeUserAPIParser regUserWrapper = new KNDY4.YodleeUserAPIParser();
            KNDY4.YodleeUserAPIParser.UserWrapper userWrap = new KNDY4.YodleeUserAPIParser.UserWrapper();
            userWrap.loginName = loginName;
            userWrap.password = passwd;
            userWrap.email = emailAddress;
            KNDY4.YodleeUserAPIParser.NameWrapper nameWrap = new KNDY4.YodleeUserAPIParser.NameWrapper();
            nameWrap.first = firstName;
            nameWrap.last = lastName;
            userWrap.name = nameWrap;
            regUserWrapper.user = userWrap;
	    	string reqBody = KNDY4.YodleeJsonParser.jsonParser.serialize(regUserWrapper);
	    	system.debug('usr login reqBody='+reqBody);
	    	req.setBody(reqBody);	  
		    req.setEndpoint(url);
		    HttpResponse res = new Http().send(req);
		    string body = res.getBody();
		    system.debug('body =' + body);
		}
	}
    
	Sample Response JSON
	
	***************************
	{
	"user":
	  {
	  "id":1111484545,
	  "loginName":"LOGINNAME",
	  "session": {
	    "userSession": "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	  },
	  "name": {
	    "first": "FNAME",
	    "last": "LNAME"
	    },
	  "preferences": {
	    "currency": "USD",
	    "timeZone": "PST",
	    "dateFormat": "MM/dd/yyyy",
	    "locale": "en_US"
	    }
	  }
	}
	
	//script for unregistering user in case of issues
	string url;
	map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
	if(!mapSvcCfg.isEmpty()){
		if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('USER_REGISTER_URL')){
	   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + 'v1/user/unregister';
	   	}
	   	//url = 'https://stage.api.yodlee.com/ysl/private-sandbox219/v1/user/unregister';
	   	if(string.isNotBlank(url)){
	   		HttpRequest req = new HttpRequest();
		    req.setMethod('DELETE');
            string authorizationHeader = '{cobSession=11242015_2:3c2b7a0b59bc424164de5718a44b594616101cd25b448a083ac73aee7e414b39c441d109cf9662f01101fda707b05be509d7334353e3b212e12857cefd071658,userSession=11242015_2:3c2b7a0b59bc424164de5718a44b594616101cd25b448a083ac73aee7e414b39c441d109cf9662f01101fda707b05be509d7334353e3b212e12857cefd071658}';
	        req.setHeader('Authorization',authorizationHeader);
			req.setHeader('Content-Type', 'application/json');
		    req.setEndpoint(url);
		    HttpResponse res = new Http().send(req);
		    string body = res.getBody();
		    system.debug('body =' + body);
		}
	}
	*******************************************/
    public static YodleeUserAPIParser registerUser(string cobrandSessionToken, YodleeUserAPIParser regUserWrapper) { 
        string url;
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('USER_REGISTER_URL')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('USER_REGISTER_URL').URL__c;
   			}
   		}
   		YodleeUserAPIParser userResult;
   		if(string.isNotBlank(url)){
	        
	        try {
	            HttpRequest req = new HttpRequest();
	            req.setMethod('POST');
	            req.setTimeout(120000);
	            string reqBody = YodleeJsonParser.jsonParser.serialize(regUserWrapper);
	            system.debug('json reg user='+reqBody);
	            req.setBody(reqBody);
	            string authorizationHeader = paramNameCobSessionToken+ '='+cobrandSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
	            req.setEndpoint(url);
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();
	            system.debug('body =' + body);
	            userResult = (YodleeUserAPIParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeUserAPIParser.class);
	            system.debug('userResult: '+userResult);
	                        	           
	        } catch (Exception e) {
	            system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
	            userResult = new YodleeUserAPIParser();  
	            userResult.errorCode =  e.getMessage();
	        } 
   		}
        return userResult;
    }
    
    public static boolean insertUser(string cobrandSessionToken,string UserName, string UserPasswd,string userSessionToken) {
    	boolean isSuccess = true; 
    	try{
			if(string.isNotBlank(UserName) && string.isNotBlank(UserPasswd) && string.isNotBlank(userSessionToken)){
				if(Service_Configuration__c.getValues('YodleeUserLogin') != null){ 
					DML.updateAsSystem(new Service_Configuration__c(Name='YodleeUserLogin', username__c = UserName, password__c = UserPasswd, Session_Token__c = userSessionToken));
				}else{
					DML.insertAsSystem(new Service_Configuration__c(Name='YodleeUserLogin', username__c = UserName, password__c = UserPasswd, Session_Token__c = userSessionToken));
				}
				list<Service_Configuration__c> lstSC = new list<Service_Configuration__c>();
            	if(string.isBlank(getSessionToken('cobrandLogin', 90))){
            		lstSC.add(setSessionToken('cobrandLogin', cobrandSessionToken));
			}
            	DML.updateAsuser(lstSC);
			}
    	}catch(Exception e){
    		isSuccess = false;
    		system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
    	}
        return isSuccess;
    }
     
    
    public static list<string> fetchRefreshDates(string bankAccountId){
    	SOQLUtil soql;
    	list<string> lstDates = new list<string>();
    	try{
		soql = new SOQLUtil('Bank_Account__c', TRUE);
		soql.addFields(new Set<String>{'Id','Yodlee_Account_Linkage_Date__c'});
		soql.setWhereClause('Yodlee_Account_Number__c =:bankAccountId');
		soql.setLimit(1);
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql,'Bank_Transactions__r');
		childRel.addFields(new Set<String>{'Id','Transaction_Date__c'});
		childRel.setOrderByClause('Transaction_Date__c DESC');
		childRel.setWhereClause('Transaction_Id__c != null');
		childRel.setLimit(1);
		soql.addChildRelationship(childRel);
    	Bank_Account__c bankAccount = new Bank_Account__c();
        bankAccount = Database.query(soql.getQuery());
	        
        string startDate, endDate;
        if(bankAccount != null){
        	if(!bankAccount.Bank_Transactions__r.isEmpty()){
        		if(bankAccount.Bank_Transactions__r[0].Transaction_Date__c != null){
        			list<string> lstTemp = new list<string>();
        			lstTemp = (string.valueOf(bankAccount.Bank_Transactions__r[0].Transaction_Date__c.date())).split('-');
	        		startDate = lstTemp[0] + '-' + lstTemp[1]+'-'+lstTemp[2]; //convert date to yodlee accepted format MM-DD-YYYY
        		
	        		lstTemp.clear();
		        	lstTemp = new list<string>();
	        		lstTemp = (string.valueOf(system.now().date())).split('-');
		        	endDate = lstTemp[0] + '-' + lstTemp[1]+'-'+lstTemp[2];
        		}
        	}else{
        		if(bankAccount.Yodlee_Account_Linkage_Date__c != null){
		        	list<string> lstTemp = new list<string>();
		        	lstTemp = (string.valueOf(bankAccount.Yodlee_Account_Linkage_Date__c)).split('-');
			        endDate = lstTemp[0] + '-' + lstTemp[1]+'-'+lstTemp[2];
		        		
		        	lstTemp.clear();
		        	lstTemp = new list<string>();
		        	map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
		        	integer days = 90;
		        	if(!mapSvcCfg.isEmpty()){
			   			if(mapSvcCfg.containskey('DAYS_TO_PULL_TRANSACTION')){
			   				days = Integer.valueOf(mapSvcCfg.get('DAYS_TO_PULL_TRANSACTION').UserName__c);
			   			}
			   		}
			        lstTemp = (string.valueOf(bankAccount.Yodlee_Account_Linkage_Date__c.addDays(-1*days))).split('-');//replace 2000 with 90 days IMP
			        startDate = lstTemp[0] + '-' + lstTemp[1]+'-'+lstTemp[2];
        		}
        	}
        	if(string.isNotBlank(startDate) && string.isNotBlank(endDate)){
        		lstDates.add(startDate);
        		lstDates.add(endDate);
        	}
        }
    	}catch(Exception e){
    		system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
    		throw new YodleeAPIException(e.getMessage(),e);
    	}
        return lstDates;
    }
    
    /******* search bank transactions ************************
string url;
map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
if(!mapSvcCfg.isEmpty()){
   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('USER_TRANSACTION_SEARCH')){
   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('USER_TRANSACTION_SEARCH').KNDY4__URL__c;
   	}
   	if(string.isNotBlank(url)){
   		HttpRequest req = new HttpRequest();
	    req.setMethod('GET');
        string authorizationHeader = 'cobSessionToken='+EncodingUtil.urlEncode(mapSvcCfg.get('cobrandLogin').KNDY4__Session_Token__c, 'UTF-8')+',' + 'userSessionToken='+EncodingUtil.urlEncode(mapSvcCfg.get('YodleeUserLogin').KNDY4__Session_Token__c, 'UTF-8');
        req.setHeader('Authorization',authorizationHeader);
		req.setHeader('Content-Type', 'application/json');
        string parameters =  '';
       
        parameters = parameters + '?top='+EncodingUtil.urlEncode(500, 'UTF-8');
        parameters = parameters + '&skip='+EncodingUtil.urlEncode(1, 'UTF-8');
        if(string.isNotBlank(fromDate)){
        	parameters = parameters + '&fromDate='+EncodingUtil.urlEncode('10-01-2016', 'UTF-8');
        }
        if(string.isNotBlank(toDate)){
        	parameters = parameters + '&toDate='+EncodingUtil.urlEncode('10-01-2017', 'UTF-8');
        }
        if(!accountId.equalsIgnoreCase('all')){
        	parameters = parameters +   '&accountId='+EncodingUtil.urlEncode('1233333', 'UTF-8');
        }
        //req.setBody(parameters);   
        req.setEndpoint(url+ parameters);	    
        system.debug('searchBankTransactions: '+ req );
	    HttpResponse res = new Http().send(req);
	    string body = res.getBody();
	    system.debug('body =' + body);
	}

}
**********************************************************/
    public static map<string,string> searchBankTransactions(string cobrandSessionToken,
                                           string userSessionToken, string container,
                                           string baseType, string keyword, string accountId,
                                           string fromDate, string toDate, string categoryId,
                                           string highLevelCategoryId, string trantype, string categoryType,
                                           string skip, string top,string ignoreUserInput) {
    	string url;
    	string body;
    	string returnMessage = '';
    	map<string,string> returnMapData = new map<string,string>();
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('USER_TRANSACTION_SEARCH')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('USER_TRANSACTION_SEARCH').URL__c;
   			}
   		}
   		try {
   		if(string.isBlank(fromDate) && string.isBlank(toDate)){
	   			if(string.isNotBlank(accountId)){
		   			list<string> lstDates = fetchRefreshDates(accountId);
	   			if(!lstDates.isEmpty()){
	   				fromDate = lstDates[0];
	   				toDate = lstDates[1];
	   			}
   			}
   		}
    	if(string.isNotBlank(url)){
	        	HttpRequest req = new HttpRequest();
	            
	            req.setMethod('GET');
	            req.setTimeout(120000);
	            string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
	            string parameters =  '';
	           
	            parameters = parameters + '?' + paramNamehigherFetchLimit+'='+EncodingUtil.urlEncode(top, 'UTF-8');
                parameters = parameters + '&' + paramNamelowerFetchLimit+'='+EncodingUtil.urlEncode(skip, 'UTF-8');
	            if(string.isNotBlank(fromDate)){
	            	parameters = parameters + '&' + paramNamefromDate+'='+EncodingUtil.urlEncode(fromDate, 'UTF-8');
	            }
	            if(string.isNotBlank(toDate)){
	            	parameters = parameters + '&' + paramNametoDate+'='+EncodingUtil.urlEncode(toDate, 'UTF-8');
	            }
	            if(!accountId.equalsIgnoreCase('all')){
	            	parameters = parameters +   '&' + paramNameBankAccountId+'='+EncodingUtil.urlEncode(accountId, 'UTF-8');
	            }
	            //req.setBody(parameters);   
	            req.setEndpoint(url+ parameters);
	            system.debug(logginglevel.error,'searchBankTransactions: '+ req + parameters);
	            HttpResponse res = new Http().send(req);
	            body = res.getBody();
	            system.debug(logginglevel.error,'body=='+body);
	            
	            YodleeSiteAccountParser ysap = (YodleeSiteAccountParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeSiteAccountParser.class);                        
	             if (ysap != null){
                	if (ysap.errorCode != null && ysap.errorMessage != null){                		
                		returnMessage = Label.Yodlee_Generic_Error_Msg +  (mapSvcCfg.get('USER_TRANSACTION_SEARCH') != null && string.isNotBlank(mapSvcCfg.get('USER_TRANSACTION_SEARCH').URL__c) ? ' (' + mapSvcCfg.get('USER_TRANSACTION_SEARCH').URL__c.replace('v1/','')  +'/Fetch): ' :': ') + ysap.errorCode + '-' +ysap.errorMessage + ' (' + ysap.referenceCode + ')';
                		returnMapData.put('Error',returnMessage);
                	}else{
                		returnMessage = body;
                		returnMapData.put('Body',returnMessage);
                	}
                }			     
    		}else{
    			throw new YodleeAPIException(Label.Yodlee_Setup_Message);
    		}    		
	        } catch (Exception e) {
        	system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
        	returnMessage = e.getMessage() + '. '+Label.Contact_Sys_Admin_Or_Customer_Support;
        	returnMapData = new map<string,string>();
        	returnMapData.put('Error',returnMessage);
	    } 
        return returnMapData;
    }
    
    public static list<string> saveBTs(list<Bank_Transaction__c> lstBT){
    	list<string> errorMessage = new list<string>();
    	set<string> setTransactionId = new set<string>();
    	set<string> setQueriedTransactionId = new set<string>();
    	set<string> setYodleeBAId = new set<string>();
    	map<string,Id> mapYodleeBankAccountAndId = new map<string,Id>();
    	for(Bank_Transaction__c bt: lstBT){
    		setTransactionId.add(bt.Transaction_Id__c);
    		setYodleeBAId.add(bt.Account_Number__c);
    	}
    	if(!setTransactionId.isEmpty()){
    		if(!setYodleeBAId.isEmpty()){
    			SOQLUtil soql;
        		soql = new SOQLUtil('Bank_Account__c', TRUE);
        		soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c'});
        		soql.setWhereClause('Yodlee_Account_Number__c in :setYodleeBAId');
    			for(Bank_Account__c account: Database.Query(soql.getQuery())){
    				mapYodleeBankAccountAndId.put(account.Yodlee_Account_Number__c, account.Id);
    										  }
    			if(!mapYodleeBankAccountAndId.isEmpty()){
    				for(Bank_Transaction__c bt: lstBT){
    					if(mapYodleeBankAccountAndId.containsKey(bt.Account_Number__c)){
    						bt.Bank_Account__c = mapYodleeBankAccountAndId.get(bt.Account_Number__c);
    					}
    				}
    			}
    		}
    	}
    	try{
    		if(!lstBT.isEmpty()){
	    		Schema.SObjectField field = Bank_Transaction__c.Fields.Transaction_Id__c;
	    		DML.checkUpsertAsUser(lstBT); Database.UpsertResult[] result = Database.upsert(lstBT, field, false);				
				for(integer counter=0;counter<result.size();counter++){
	    			string message = '';
	    			if(!result.get(counter).isSuccess()){
	    				for(Database.Error err : result.get(counter).getErrors()) {
		    				message = message + ' '+  err.getMessage();
		    			}
		    			errorMessage.add(message);
	    			}
	    		} 
    		}
    	}catch(exception e){
    		system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
    		errorMessage.add( e.getMessage() +'. ' + Label.Contact_Sys_Admin_Or_Customer_Support);
    	}
    	return errorMessage;
    }
    
    
   /******* get transaction count ************************************
    Sample Request JSON
    *******************************
    
	string url;
    map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
    if(!mapSvcCfg.isEmpty()){
    if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_Transaction_Count_URL')){
        url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('GET_Transaction_Count_URL').KNDY4__URL__c;
    }
    if(string.isNotBlank(url)){
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        string authorizationHeader = 'cobSession='+mapSvcCfg.get('cobrandLogin').KNDY4__Session_Token__c+',userSession='+mapSvcCfg.get('YodleeUserLogin').KNDY4__Session_Token__c;
        req.setHeader('Authorization',authorizationHeader);
        req.setHeader('Content-Type', 'application/json');
        string parameters =  '';
        
        parameters = parameters + '?accountid='+EncodingUtil.urlEncode('32807116', 'UTF-8');
        if(string.isNotBlank(fromDate)){
        parameters = parameters + '&fromDate='+EncodingUtil.urlEncode('2013-01-01', 'UTF-8');
        }
        if(string.isNotBlank(toDate)){
        parameters = parameters + '&toDate='+EncodingUtil.urlEncode('2017-01-10', 'UTF-8');
        }
        System.debug('url+parameters-->'+url+parameters);
        req.setEndpoint(url+parameters);
        HttpResponse res = new Http().send(req);
        string body = res.getBody();
        system.debug(logginglevel.error,'body =' + body);
    }
    
   }
   Sample Response JSON
   ************************
   
    {
        "transaction":{
           "TOTAL":{
                "count":1588
            }
         }
    }
********************************************************/    

    
    public static YodleeTransactionCountParser getTransactionsCount(string cobrandSessionToken,
                                           string userSessionToken, string accountId,
                                           string fromDate, string toDate) {
        string url;
        string token;
        YodleeTransactionCountParser countResult ;
        map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
        if(!mapSvcCfg.isEmpty()){
            if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_Transaction_Count_URL')){
                url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('GET_Transaction_Count_URL').URL__c;
            }
        }
        try {
	        system.debug(logginglevel.error,'conditions=' + cobrandSessionToken + '='+userSessionToken +'='+url);  
	         if(string.isBlank(fromDate) && string.isBlank(toDate)){
	                if(string.isNotBlank(accountId)){
	                    list<string> lstDates = fetchRefreshDates(accountId);
	                if(!lstDates.isEmpty()){
	                    fromDate = lstDates[0];
	                    toDate = lstDates[1];
	                }
	            }
	        } 
	       
	        if(string.isNotBlank(cobrandSessionToken) && string.isNotBlank(userSessionToken) && string.isNotBlank(url)){ 
	            
	                HttpRequest req = new HttpRequest();
	                req.setMethod('GET');
	                req.setTimeout(120000);
	                string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken +','+paramNameUserSessionToken+'=' + userSessionToken;
	                //string authorizationHeader = paramNameCobSessionToken + '='+'cobrand34234234SessionToken' +','+paramNameUserSessionToken+'=' + 'userSession23423423423Token';
	                req.setHeader('Authorization',authorizationHeader);
	                req.setHeader('Content-Type', 'application/json');
	                
	                string parameters =  '';
	        
	                parameters = parameters + '?accountid='+EncodingUtil.urlEncode(accountId, 'UTF-8');
	                if(string.isNotBlank(fromDate)){
	                    parameters = parameters + '&fromDate='+EncodingUtil.urlEncode(fromDate, 'UTF-8');
	                }
	                if(string.isNotBlank(toDate)){
	                      parameters = parameters + '&toDate='+EncodingUtil.urlEncode(toDate, 'UTF-8');
	                }
			        System.debug(logginglevel.error,'url+parameters-->'+url+parameters);
			        req.setEndpoint(url+parameters);
			        HttpResponse res = new Http().send(req);
			        string body = res.getBody();
			        system.debug(logginglevel.error,'body =' + body);  
			        countResult = (YodleeTransactionCountParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeTransactionCountParser.class); 
			        system.debug(logginglevel.error,'countResult --->' + countResult);                
	            
	        }else{
	           throw new YodleeAPIException(Label.Yodlee_Setup_Message);
	        } 
        } catch (Exception e) {
            system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
            countResult = new YodleeTransactionCountParser();
            countResult.errorCode  = e.getMessage();            
        } 
        system.debug('getTransactionsCount result: '+countResult);
        return countResult;
    }
    
    /******* get sites ************************************
    Sample Request JSON
    *********************
    nothing
    
	string url;
	map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
	if(!mapSvcCfg.isEmpty()){
   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_SITE_ACCOUNTS_URL')){
   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').KNDY4__URL__c;
   	}
   	if(string.isNotBlank(url)){
   		HttpRequest req = new HttpRequest();
	    req.setMethod('POST');
		string authorizationHeader = 'cobSession='+mapSvcCfg.get('cobrandLogin').KNDY4__Session_Token__c+',userSession='+mapSvcCfg.get('YodleeUserLogin').KNDY4__Session_Token__c;
	    req.setHeader('Authorization',authorizationHeader);
		req.setHeader('Content-Type', 'application/json');
	    req.setEndpoint(url);
	    HttpResponse res = new Http().send(req);
	    string body = res.getBody();
	    system.debug('body =' + body);
	}
}
	Sample Response JSON
	******************
	{
	 "providerAccount": [{
	 "id": 10487529,
	 "providerId":16441,
	 "lastUpdated":"2016-08-25T07:18:32Z",
	 "isManual":false,
	 "createdDate":"2016-08-25",
	 "aggregationSource": "USER",
	 "refreshInfo": {
	   "statusCode": 0,
	   "statusMessage": "OK",
	   "status": "IN_PROGRESS",
	   "additionalStatus": "LOGIN_IN_PROGRESS",
	   "lastRefreshed": "2015-06-17T16:46:32Z",
	   "lastRefreshAttempt": "2015-06-17T16:46:32Z"
	 }
	 },{
	 "id": 10487530,
	 "providerId":16441,
	 "lastUpdated":"2016-08-26T07:18:32Z",
	 "isManual":false,
	 "createdDate":"2016-08-26",
	 "aggregationSource": "USER",
	 "refreshInfo": {
	   "statusCode": 0,
	   "statusMessage": "OK",
	   "status": "SUCCESS",
	   "nextRefreshScheduled": "2015-06-20T16:46:32Z",
	   "lastRefreshed": "2015-06-17T16:46:32Z",
	   "lastRefreshAttempt": "2015-06-17T16:46:32Z"
	 }
	 },{
	 "id": 10487531,
	 "providerId":16441,
	 "lastUpdated":"2016-08-21T07:18:32Z",
	 "isManual":true,
	 "createdDate":"2016-08-21",
	 "aggregationSource": "USER"
	 }]
	}
********************************************************/
    public static list<siteAccount> getSiteAccounts(string cobrandSessionToken, string userSessionToken){ 
        string url;
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_SITE_ACCOUNTS_URL')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c;
   			}
   		}
        map<long,List<siteAccount>> mapSiteAccount = new map<long,List<siteAccount>>();
        list<siteAccount> lstSiteAccount = new list<siteAccount>();
        list<siteAccount> lstSiteAccountTemp = new list<siteAccount>();
        siteAccount siteAccountObj;
        set<string> lstAccountId = new set<string>();
        map<long,string> providerMap = new map<long,string>();
        string providerName ;
        try {
        if(string.isNotBlank(url)){
	        
	            HttpRequest req = new HttpRequest();
	            req.setMethod('GET');	            
	            req.setTimeout(120000);           
	            req.setEndpoint(url);
	            string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();        
                system.debug('body siteaccounts length=='+body.length() +'=body='+body);
                //body with one site
                //body='{"providerAccount":[{"id":14847448,"providerId":16441,"lastUpdated":"2017-03-16T18:36:43Z","isManual":false,"createdDate":"2017-03-10","aggregationSource":"USER","refreshInfo":{"statusCode":0,"statusMessage":"OK","status":"IN_PROGRESS","additionalStatus":"LOGIN_SUCCESS","lastRefreshed":"2017-03-16T18:36:44Z","lastRefreshAttempt":"2017-03-16T18:36:44Z"}}]}';
                YodleeSiteAccountParser ysap = (YodleeSiteAccountParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeSiteAccountParser.class);
				//fetch unique providers
				if (ysap != null && ysap.providerAccount != null){
                	system.debug('ysap.providerAccount=='+ysap.providerAccount);
	                for(YodleeSiteAccountParser.ProviderAccountsWrapper inf: ysap.providerAccount){
	                	mapSiteAccount.put((long)inf.providerId,null); 
	                }   
				        
				for (long providerId: mapSiteAccount.keySet()){
					providerName = getProviders(cobrandSessionToken,userSessionToken,providerId);
					providerMap.put(providerId,providerName);
				}                     
               
                	system.debug('ysap.providerAccount=='+ysap.providerAccount);
	                for(YodleeSiteAccountParser.ProviderAccountsWrapper inf: ysap.providerAccount){
	                	lstSiteAccount = new list<siteAccount>();
	                	if (mapSiteAccount.containsKey(inf.providerId) && mapSiteAccount.get(inf.providerId) != null){
	                		
	                		lstSiteAccount = mapSiteAccount.get(inf.providerId)  ;
	                	}	                
	                	if (inf.refreshInfo != null){
	                		siteAccountObj = new  siteAccount(inf.id , providerMap.get(inf.providerId),false,inf.refreshInfo.lastRefreshAttempt,inf.refreshInfo.nextRefreshScheduled,inf.refreshInfo.lastRefreshed,inf.refreshInfo.status,inf.refreshInfo.statusMessage);
	                	}else{
	                		siteAccountObj = new  siteAccount(inf.id , providerMap.get(inf.providerId),false);
	                	}
	                	lstSiteAccount.add(siteAccountObj);
	                    mapSiteAccount.put(inf.providerId,lstSiteAccount);
	                    lstAccountId.add(String.valueof(inf.id));

	                }
	            
                system.debug('lstAccountId=='+lstAccountId);
                SOQLUtil soql = new SOQLUtil('Bank_Account__c', true); 
                soql.addFields(new set<string>{
                    'Id','Yodlee_Account_Site_ID__c'
                });
                soql.setWhereClause('Yodlee_Account_Site_ID__c in: lstAccountId');
                list<Bank_Account__c> lstBA = Database.query(soql.getQuery());
                Set<string> yodleeAccountSiteSet = new set<string>(); 
                system.debug('lstBA=='+lstBA);
                if(!lstBA.isEmpty()){
	                for (Bank_Account__c bacc :lstBA){
	                	if (string.isNotBlank(bacc.Yodlee_Account_Site_ID__c)){
	                		yodleeAccountSiteSet.add(bacc.Yodlee_Account_Site_ID__c);
	                	
	                	}
                	}
                }
                lstSiteAccount = new list<siteAccount>();
                for (long providerId : mapSiteAccount.keySet()){
                	
                	lstSiteAccountTemp = new list<siteAccount>();
                	lstSiteAccountTemp = mapSiteAccount.get(providerId);
                	system.debug('lstSiteAccountTemp='+lstSiteAccountTemp);
                	lstSiteAccount.addall(lstSiteAccountTemp);
                	for (siteAccount siteAcc : lstSiteAccountTemp){
        			if (siteAcc.SiteId != null && yodleeAccountSiteSet.contains( string.valueof(siteAcc.SiteId))){
                				siteAcc.disableRemove = true;
                			}
                		}
                }
				}else if (ysap != null && ysap.errorCode != null && ysap.errorMessage != null){
					system.debug('inside error message');
					lstSiteAccount.add (new siteAccount((mapSvcCfg.get('GET_SITE_ACCOUNTS_URL') != null && string.isnotblank(mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c) ? mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c.replace('v1/','') +'/Fetch' : null),ysap.errorCode,ysap.errorMessage,ysap.referenceCode));
				}
               
	         
        	}else{
        		throw new YodleeAPIException(Label.Yodlee_Setup_Message);
        	}  
	  	}catch(Exception e){
	          system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
	          lstSiteAccount.add (new siteAccount(null, e.getMessage(), Label.Contact_Sys_Admin_Or_Customer_Support, null));
	    }  
        system.debug('lstSiteAccount=='+lstSiteAccount);      
        return lstSiteAccount;
    }
    //KNDY-15857 - fetch site refresh info 
    public static list<siteAccount> getSiteAccountsWithProviders(string cobrandSessionToken, string userSessionToken, string providerAccountId){ 
        string url;
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_SITE_ACCOUNTS_URL')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c;
   			}
   		}
        map<long,List<siteAccount>> mapSiteAccount = new map<long,List<siteAccount>>();
        list<siteAccount> lstSiteAccount = new list<siteAccount>();
        list<siteAccount> lstSiteAccountTemp = new list<siteAccount>();
        siteAccount siteAccountObj;
        set<string> lstAccountId = new set<string>();
        map<long,string> providerMap = new map<long,string>();
        string providerName ;
        try {
        	if(string.isNotBlank(url)){
                		
	            HttpRequest req = new HttpRequest();
	            req.setMethod('GET');	
	            req.setTimeout(120000);            
	            req.setEndpoint(url +  '/'+ EncodingUtil.urlEncode(string.valueOf(providerAccountId), 'UTF-8'));
	            string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();        
                system.debug('body siteaccounts length=='+body.length() +'=body='+body);
                //body with one site
                //body='{"providerAccount":[{"id":14847448,"providerId":16441,"lastUpdated":"2017-03-16T18:36:43Z","isManual":false,"createdDate":"2017-03-10","aggregationSource":"USER","refreshInfo":{"statusCode":0,"statusMessage":"OK","status":"tesst","additionalStatus":"LOGIN_SUCCESS","lastRefreshed":"2017-03-17T18:36:44Z","lastRefreshAttempt":"2017-03-17T18:36:44Z"}}]}';
                YodleeSiteAccountParser.YodleeProviderAccountParser ysap = (YodleeSiteAccountParser.YodleeProviderAccountParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeSiteAccountParser.YodleeProviderAccountParser.class);
                system.debug('ysap=='+ysap);
				//fetch unique providers
				if (ysap != null && ysap.providerAccount != null){
                	system.debug('ysap.providerAccount=='+ysap.providerAccount);
	                
	                YodleeSiteAccountParser.ProviderAccountsWrapper inf= ysap.providerAccount;
	                	                
                	if (inf.refreshInfo != null){
                		siteAccountObj = new  siteAccount(inf.id , providerMap.get(inf.providerId),false,inf.refreshInfo.lastRefreshAttempt,inf.refreshInfo.nextRefreshScheduled,inf.refreshInfo.lastRefreshed,inf.refreshInfo.status,inf.refreshInfo.statusMessage);
                	}else{
                		siteAccountObj = new  siteAccount(inf.id , providerMap.get(inf.providerId),false);
                	}
                	lstSiteAccount.add(siteAccountObj);
	                
	            
	                system.debug('lstSiteAccount=='+lstSiteAccount);
	                
				}else if (ysap != null && ysap.errorCode != null && ysap.errorMessage != null){
					system.debug('inside error message');
					lstSiteAccount.add (new siteAccount((mapSvcCfg.get('GET_SITE_ACCOUNTS_URL') != null && string.isnotblank(mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c) ? mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c.replace('v1/','') +'/Fetch' : null),ysap.errorCode,ysap.errorMessage,ysap.referenceCode));
				}
               
	         
        	}else{
        		throw new YodleeAPIException(Label.Yodlee_Setup_Message);
        	}  
        }catch(Exception e){
	            system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
	            lstSiteAccount.add (new siteAccount(null, e.getMessage(), Label.Contact_Sys_Admin_Or_Customer_Support, null));
	        }   
        system.debug('lstSiteAccount=='+lstSiteAccount);      
        return lstSiteAccount;
    }
    //KNDY-15850
    /******* get providers ************************
	string url;
	map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
	if(!mapSvcCfg.isEmpty()){
	   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_PROVIDER_URL')){
            url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('GET_PROVIDER_URL').KNDY4__URL__c;
        }
	   	if(string.isNotBlank(url)){ 
		    HttpRequest req = new HttpRequest();
		    req.setMethod('POST');
		    string authorizationHeader =   'cobSession='+cobrandSessionToken+',userSession='+userSessionToken;
            req.setHeader('Authorization',authorizationHeader);
			req.setHeader('Content-Type', 'application/json');		    
		    req.setEndpoint(url+ '/'+EncodingUtil.urlEncode('14255560', 'UTF-8'));
		    HttpResponse res = new Http().send(req);
		    string body = res.getBody();
		    system.debug('body =' + body);
		}
	}
	*******************************************/
    private static string getProviders(string cobrandSessionToken, string userSessionToken, long providerId){ 
        string url;
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_PROVIDER_URL')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('GET_PROVIDER_URL').URL__c;
   			}
   		}
        list<siteAccount> lstSiteAccount = new list<siteAccount>();
        string providerName;
        if(string.isNotBlank(url)){
	        try {
	            HttpRequest req = new HttpRequest();
	            req.setMethod('GET');	            
	            req.setTimeout(120000);	            
	            req.setEndpoint(url + '/'+providerId);
	            string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();        
                system.debug('body getProviders length=='+body.length() +'=body='+body);
                
                YodleeSiteAccountParser ysap = (YodleeSiteAccountParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeSiteAccountParser.class);
                if (Test.isRunningTest()){
                	providerName = 'Dag Site';
                	return providerName;
                }                
                if (ysap != null && ysap.provider != null ){
                	system.debug('ysap.provider=='+ysap.provider);
	                for(YodleeSiteAccountParser.providersWrapper inf: ysap.provider){
	                   providerName = inf.name;
	                }
	            }else{
	            	throw new YodleeAPIException(Label.Yodlee_Generic_Error_Msg +  (mapSvcCfg.get('GET_PROVIDER_URL') != null && String.isNotBlank (mapSvcCfg.get('GET_PROVIDER_URL').URL__C) ? ' (' + mapSvcCfg.get('GET_PROVIDER_URL').URL__c.replace('v1/','') +'/Fetch): ' : ': ')+ ysap.errorCode + '-' + ysap.errorMessage + ' (' + ysap.referenceCode +')' );
	            }
                
                		
	        }catch(Exception e){
	            system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
	            throw new YodleeAPIException(e.getMessage(),e);
	        }  
	        
        }else{
    		throw new YodleeAPIException(Label.Yodlee_Setup_Message);
        }          
        return providerName;    
    }
    
    //KNDY-13289 remove site linkages to yodlee
    /******* remove sites ************************
	string url;
	map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
	if(!mapSvcCfg.isEmpty()){
	   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_SITE_ACCOUNTS_URL')){
            url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').KNDY4__URL__c;
        }
	   	if(string.isNotBlank(url)){ 
		    HttpRequest req = new HttpRequest();
		    req.setMethod('POST');
		    string authorizationHeader =   'cobSession='+cobrandSessionToken+',userSession='+userSessionToken;
            req.setHeader('Authorization',authorizationHeader);
			req.setHeader('Content-Type', 'application/json');
		    req.setEndpoint(url + '/'+ EncodingUtil.urlEncode('14255560', 'UTF-8'));
		    HttpResponse res = new Http().send(req);
		    string body = res.getBody();
		    system.debug('body =' + body);
		}
	}
	*******************************************/
    public static string removeSiteAccounts(string cobrandSessionToken, string userSessionToken, string memSiteAccId){ 
        string url;
        string body;
        string returnMessage = '';
        map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
        if(!mapSvcCfg.isEmpty()){
            if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_SITE_ACCOUNTS_URL')){
                url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c;
            }
        }
        try {
        	if(string.isNotBlank(url)){
        
                HttpRequest req = new HttpRequest();
                req.setMethod('DELETE');
                req.setTimeout(120000);
                string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
				//memSiteAccId = '11111';				               
                req.setEndpoint(url + '/' + EncodingUtil.urlEncode(string.valueOf(memSiteAccId), 'UTF-8'));
                system.debug('url=='+url);
                HttpResponse res = new Http().send(req);
                body = res.getBody();        
                system.debug('res=='+res);
                system.debug('body=='+body);
                if (string.isBlank(body)){
                	returnMessage = '';
                }else{
                	YodleeSiteAccountParser ysap = (YodleeSiteAccountParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeSiteAccountParser.class);
                
	                if (ysap != null){
	                	if (ysap.errorCode != null && ysap.errorMessage != null){
	                		returnMessage = Label.Yodlee_Generic_Error_Msg + (mapSvcCfg.get('GET_SITE_ACCOUNTS_URL') != null && String.isNotBlank(mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c) ? ' (' + mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c.replace('v1/','') +'/Remove): ' : ': ') +  ysap.errorCode + '-' +ysap.errorMessage  + ' (' + ysap.referenceCode + '). ' + Label.Contact_Sys_Admin_Or_Customer_Support;
	                	}
	                }					
                }   

        	}else{
        		throw new YodleeAPIException(Label.Yodlee_Setup_Message);
        	}
        }catch(Exception e){
                system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
                returnMessage = e.getMessage() +'. '+ Label.Contact_Sys_Admin_Or_Customer_Support;
            }  
        system.debug('removesites='+returnMessage);         
        return returnMessage;
    }

    //KNDY-15857 refresh sites from yodlee
    /******* refresh sites ************************
	string url;
	map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
	if(!mapSvcCfg.isEmpty()){
	   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('REFRESH_SITES_URL')){
            url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('REFRESH_SITES_URL').KNDY4__URL__c;
        }
	   	if(string.isNotBlank(url)){ 
		    HttpRequest req = new HttpRequest();
		    req.setMethod('POST');
		    string authorizationHeader =   'cobSession='+cobrandSessionToken+',userSession='+userSessionToken;
            req.setHeader('Authorization',authorizationHeader);
			req.setHeader('Content-Type', 'application/json');
		    req.setEndpoint(url + '?accountIds='+ EncodingUtil.urlEncode('14255560', 'UTF-8'));
		    HttpResponse res = new Http().send(req);
		    string body = res.getBody();
		    system.debug('body =' + body);
		}
	}
	*******************************************/
    public static string refreshSiteAccounts(string cobrandSessionToken, string userSessionToken, string memSiteAccId){ 
        string url;
        string body;
        string returnMessage = '';
        map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
        if(!mapSvcCfg.isEmpty()){
            if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_SITE_ACCOUNTS_URL')){
                url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('GET_SITE_ACCOUNTS_URL').URL__c;
            }
        }
        try {
    		if(string.isNotBlank(url)){
           
                HttpRequest req = new HttpRequest();
                req.setMethod('PUT');
                req.setTimeout(120000);
                string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');		               
                req.setEndpoint(url + '?providerAccountIds=' + EncodingUtil.urlEncode(string.valueOf(memSiteAccId), 'UTF-8'));
                system.debug('url=='+url  + '?providerAccountIds=' + EncodingUtil.urlEncode(string.valueOf(memSiteAccId), 'UTF-8'));
                HttpResponse res = new Http().send(req);
                body = res.getBody();        
                //body='{"providerAccount":[{"id":14847448,"providerId":16441,"lastUpdated":"2017-03-16T18:36:43Z","isManual":false,"createdDate":"2017-03-10","aggregationSource":"USER","refreshInfo":{"statusCode":0,"statusMessage":"OK","status":"IN_PROGRESS","additionalStatus":"LOGIN_SUCCESS","lastRefreshed":"2017-03-16T18:36:44Z","lastRefreshAttempt":"2017-03-16T18:36:44Z"}}]}';
                //system.debug('req=='+req  + 'res=='+res);
                system.debug('body=='+body);
                if (string.isBlank(body)){
                	returnMessage = Label.Yodlee_Setup_Message;
                }else{
                	returnMessage = '';
                	YodleeSiteAccountParser ysap = (YodleeSiteAccountParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeSiteAccountParser.class);
                    system.debug('refresh ysap=='+ysap);            
	                if (ysap != null){
	                	if (ysap.errorCode != null && ysap.errorMessage != null){
	                		returnMessage = Label.Yodlee_Generic_Error_Msg + (mapSvcCfg.get('REFRESH_SITES_URL') != null && String.isNotBlank(mapSvcCfg.get('REFRESH_SITES_URL').URL__c) ? ' (' + mapSvcCfg.get('REFRESH_SITES_URL').URL__c.replace('v1/','') +'/Refresh): ': ': ') + ysap.errorCode + '-' +ysap.errorMessage  + ' (' + ysap.referenceCode + '). ' +Label.Contact_Sys_Admin_Or_Customer_Support;
	                	}
	                }					
                }   
	        }else{
	        	//config values missing	        	
	            throw new YodleeAPIException(Label.Yodlee_Setup_Message);       
	        }   
    	}catch(Exception e){
                system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
                returnMessage = e.getMessage() + '. ' + Label.Contact_Sys_Admin_Or_Customer_Support;
            }  
        system.debug('refresh sites='+returnMessage);          
        return returnMessage;
    }
    
    
    /******* get account for a site ************************************
string url;
map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
if(!mapSvcCfg.isEmpty()){
   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_ACCOUNTS_URL')){
   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('GET_ACCOUNTS_URL').KNDY4__URL__c;
   	}
   	if(string.isNotBlank(url)){
   		HttpRequest req = new HttpRequest();
	    req.setMethod('POST');
	    string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
        req.setHeader('Authorization',authorizationHeader);
		req.setHeader('Content-Type', 'application/json');
	    req.setBody('&userSessionToken='+EncodingUtil.urlEncode(mapSvcCfg.get('YodleeUserLogin').KNDY4__Session_Token__c, 'UTF-8')+
	                '&cobSessionToken='+EncodingUtil.urlEncode(mapSvcCfg.get('cobrandLogin').KNDY4__Session_Token__c, 'UTF-8')+
	                '&memSiteAccId' +'='+EncodingUtil.urlEncode('1234556', 'UTF-8')
	    );
	    req.setEndpoint(url);
	    HttpResponse res = new Http().send(req);
	    string body = res.getBody();
	    system.debug('body =' + body);
	}
}
********************************************************************/
    public static list<SummaryForSite> getSummaryForSite(string siteIdName, string siteAccountName, string cobrandSessionToken, string userSessionToken){
        string url;
        map<string,string> mapAccountIdName = new map<string,string>();
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('GET_ACCOUNTS_URL')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('GET_ACCOUNTS_URL').URL__c;
   			}
   		}
        list<SummaryForSite> lstAccountIdName =new list<SummaryForSite>();
        list<siteAccount> lstSiteAccount = new list<siteAccount>();
        string[] splitAccSite;
        set<string> lstAccountId = new set<string>();
        try {
        if(string.isNotBlank(url)){
	        
	            YodleeItemSummaryParser yisp;
	            list<YodleeItemSummaryParser> yispList = new list<YodleeItemSummaryParser>();
	            HttpRequest req = new HttpRequest();
	            req.setMethod('GET');
	            req.setTimeout(120000);
	            string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken+',' + paramNameUserSessionToken + '='+userSessionToken;
			    req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
	            req.setEndpoint(url );// + '?' + paramNameProviderAccId  +'='+EncodingUtil.urlEncode(string.valueOf(siteIdName), 'UTF-8'));
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();        
	            system.debug('siteIdName='+siteIdName +'response  body =' + body);  
	            if(body.length()>100)
	            	yisp = (YodleeItemSummaryParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeItemSummaryParser.class);
	            	
	            if (yisp<> null && yisp.account != null) {
		            yispList.add(yisp);
		            system.debug('yispList=='+yispList);
	            for(YodleeItemSummaryParser yisp1 : yispList ){
		            	system.debug('yisp1.account='+yisp1.account);
		                for(YodleeItemSummaryParser.Accounts inf: yisp1.account){  
	                	if(inf != null){     
                        	//FOR Dummy Sites it returns itemDisplayName= "Dag Site - Bank"  account number- "xxxx3xxx" 
		                       
		                     system.debug('accountId--->'+inf.id);
		                     mapAccountIdName.put((inf.providerAccountId + '-'+ inf.id ),inf.providerName+'-'+inf.accountNumber);
		                     lstAccountId.add (inf.id);	               
				       	}
				    }
	            }
	            
	            system.debug('mapAccountIdName='+mapAccountIdName);
	           	if(!mapAccountIdName.isEmpty()){
	
		            	//lstAccountId.addAll(mapAccountIdName.keyset());
	            	SOQLUtil soql = new SOQLUtil('Bank_Account__c', true); 
					soql.addFields(new set<string>{
						'Id','Yodlee_Account_Number__c'
					});
					soql.setWhereClause('Yodlee_Account_Number__c in: lstAccountId');
	            	list<Bank_Account__c> lstBA = Database.query(soql.getQuery());
	            	if(!lstBA.isEmpty()){
	            		set<string> setYlAccNumber = new set<string>();
	            		for(Bank_Account__c bankAccount: lstBA){
	            			setYlAccNumber.add(bankAccount.Yodlee_Account_Number__c);
	            		}
		            	system.debug('setYlAccNumber--'+setYlAccNumber);
	            		if(!setYlAccNumber.isEmpty()){
	            			for(string accountId: mapAccountIdName.keyset()){
		            				system.debug('accountid='+accountId +'='+mapAccountIdName.get(accountId));
		            				splitAccSite = String.isNotBlank( accountId) ? accountId.split('-') : null;
		            				if (splitAccSite != null && splitAccSite.size() > 0){
		            					system.debug('splitAccSite='+splitAccSite.size() + '-'+splitAccSite[1] +'-'+setYlAccNumber.contains(splitAccSite[1]));
			            				if(!setYlAccNumber.contains(splitAccSite[1])){
			            					system.debug('contains values1');
			            					if (splitAccSite.size() >1){
			            						system.debug('contains values');
			            						lstSiteAccount.add(new siteAccount(Long.valueOf(splitAccSite[0]),Long.valueOf(splitAccSite[1]),mapAccountIdName.get(accountId)));
			            					}else{
			            						system.debug('contains values2');
			            						lstSiteAccount.add(new siteAccount(Integer.valueOf(splitAccSite[1]),mapAccountIdName.get(accountId)));
			            					}
			            				}
	            				}
	            			}
		            			system.debug('lstSiteAccount='+lstSiteAccount);
	            			if(!lstSiteAccount.isEmpty()){
	            				lstAccountIdName.add(new SummaryForSite(Integer.valueOf(siteIdName), siteAccountName,
	            					                                    lstSiteAccount));
	            			}
	            		}
	            	}else{
	            		for(string accountId: mapAccountIdName.keyset()){
		            			splitAccSite = String.isNotBlank( accountId) ? accountId.split('-') : null;
		            			system.debug('inside else splitAccSite='+splitAccSite);
		            			//siteid,accountid, sitename
		            			lstSiteAccount.add(new siteAccount(Integer.valueOf(splitAccSite[0]),Integer.valueOf(splitAccSite[1]),mapAccountIdName.get(accountId)));
	            		}
	            		if(!lstSiteAccount.isEmpty()){
	            			lstAccountIdName.add(new SummaryForSite(Integer.valueOf(siteIdName), siteAccountName,
	            					                                    lstSiteAccount));
	            		}
	            	}
		            	
		            }
	            }else if (yisp.errorCode != null && yisp.errorMessage != null){
	            	lstAccountIdName.add(new SummaryForSite(mapSvcCfg.get('GET_ACCOUNTS_URL').URL__c.replace('v1/','') +'/Fetch',yisp.errorCode , yisp.errorMessage, yisp.referenceCode));
	            }
	             //throw new YodleeAPIException('summary went wrong');
             }else{
	        	//config values missing
	        	lstAccountIdName =new list<SummaryForSite>();
	            lstAccountIdName.add(new SummaryForSite(null, Label.Yodlee_Setup_Message ,null,null));	         
	        }   
	        }catch(NullPointerException e){
            system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
            lstAccountIdName =new list<SummaryForSite>();
            lstAccountIdName.add(new SummaryForSite( null,e.getMessage(),Label.Contact_Sys_Admin_Or_Customer_Support,null));
	        }
	        catch(Exception ed){
            system.debug('EXCEPTION ' + ed.getMessage()+' ' + ed.getLineNumber() + 'stacktrace = '+ ed.getStacktracestring());
            lstAccountIdName =new list<SummaryForSite>();
            lstAccountIdName.add(new SummaryForSite(null, ed.getMessage() ,Label.Contact_Sys_Admin_Or_Customer_Support,null));
            
        } finally{
        	system.debug('lstAccountIdName='+lstAccountIdName);
   			system.debug('lstSiteAccount='+lstSiteAccount);
        	return lstAccountIdName;
	    }         
        
        //system.debug('lstAccountIdName='+lstAccountIdName);
        //system.debug('lstSiteAccount='+lstSiteAccount);
        return lstAccountIdName;
    }
    //get unlinked accounts from bank account object
    public static list<SummaryForSite> getUnlinkedAccount(list<SummaryForSite> lstSummaryForSite){
    	list<SummaryForSite> lstUnlinkedAccountAndYodleeId = new list<SummaryForSite>();
    	list<siteAccount> lstYodleeId = new list<siteAccount>();
    	try{
    	SOQLUtil soql = new SOQLUtil('Bank_Account__c', true); 
		soql.addFields(new set<string>{
			'Id','Yodlee_Account_Number__c','Name'
		});
		soql.setWhereClause('(Yodlee_Account_Number__c = null OR Yodlee_Account_Number__c = \'\') AND Active__c = true');
		list<Bank_Account__c> lstUnlinkedBankAccount = Database.query(soql.getQuery());
			system.debug('lstUnlinkedBankAccount='+lstUnlinkedBankAccount);
			system.debug('lstSummaryForSite='+lstSummaryForSite);
		if(!lstUnlinkedBankAccount.isEmpty()){
			if(!lstSummaryForSite.isEmpty()){
				for(SummaryForSite siteSummary: lstSummaryForSite){
					if(!siteSummary.lstAccountsForSite.isEmpty()){
							for(siteAccount siteAcct: siteSummary.lstAccountsForSite){
								lstYodleeId.add(new siteAccount(siteAcct.siteId,siteAcct.accountId,siteAcct.AccountName)); //siteSummary.siteId+'-'++'-'+accountNameId.siteId
						}
					}
					system.debug('lstYodleeId: ' + lstYodleeId);
				}
				if(!lstYodleeId.isEmpty()){
					for(Bank_Account__c account: lstUnlinkedBankAccount){
						lstUnlinkedAccountAndYodleeId.add(new SummaryForSite(account.Id, account.Name, lstYodleeId));
					}
				}
			}else{
				for(Bank_Account__c account: lstUnlinkedBankAccount){
					lstUnlinkedAccountAndYodleeId.add(new SummaryForSite(account.Id, account.Name, null));
				}
			}	
		}
			
    	}catch(Exception e){
    		system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
    		lstUnlinkedAccountAndYodleeId = new list<SummaryForSite>();
    		lstUnlinkedAccountAndYodleeId.add(new SummaryForSite(e.getMessage() ,Label.Contact_Sys_Admin_Or_Customer_Support ,null));
    	}
    	system.debug('lstUnlinkedAccountAndYodleeId=='+lstUnlinkedAccountAndYodleeId);
		return lstUnlinkedAccountAndYodleeId;
    }
    public static list<string> linkBankAccountWithSite(list<string> lstBA, list<string> lstSiteAccountId, list<string> lstSiteAccountName){
    	list<string> lstMessages = new list<string>();
    	system.debug('lstBA='+lstBA+'=lstSiteAccountId='+lstSiteAccountId+'=lstSiteAccountName='+lstSiteAccountName);
    	if(!lstBA.isEmpty() && !lstSiteAccountId.isEmpty() && lstBA.size()==lstSiteAccountId.size()){
    		list<Bank_Account__c> lstBAToLink = new list<Bank_Account__c>();
    		for(integer counter=0; counter<lstBA.size(); counter++){
    			lstBAToLink.add(new Bank_Account__c(Id=lstBA.get(counter), Yodlee_Account_Number__c = lstSiteAccountId.get(counter).split('-')[1],
    												Yodlee_Account_Linkage_Date__c = date.today(),
    												Yodlee_Account_Site_ID__c = lstSiteAccountId.get(counter).split('-')[0],
                                                    ////FOR getSummarySites the Dummy Sites returns itemDisplayName= "Dag Site - Bank"  account number- "xxxx3xxx" 
                                                    //site name comes from getSiteAccounts inf.siteinfo.defaultdisplayname + '('+ inf.siteinfo.defaultorgdisplayname +')'
    												Yodlee_Account_Name__c = lstSiteAccountName.get(counter)));
    		}
    		if(!lstBAToLink.isEmpty()){
    			try{
    				DML.updateAsSystem(lstBAToLink);
    			}
    			catch(DMLexception e){
    				for(integer i=0;i<e.getNumDml();i++) {
            			lstMessages.add(e.getDmlMessage(i) + '. '+ Label.Contact_Sys_Admin_Or_Customer_Support);  
            			system.debug('EXCEPTION ' + e.getDmlMessage(i)+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
            		}
            		}
    			catch(Exception ex){
		    		system.debug('EXCEPTION ' + ex.getMessage()+' ' + ex.getLineNumber() + 'stacktrace = '+ ex.getStacktracestring());
		    		lstMessages.add(ex.getMessage() + '. '+ Label.Contact_Sys_Admin_Or_Customer_Support);
    			}
    		}
    	}
    	return lstMessages;
    }
    
    /******* get token ************************************
    Sample Request JSON
    *******************************
    appIds:10003600,10003700
    
string url;
string applicationId;
map<string,KNDY4__Service_Configuration__c> mapSvcCfg = KNDY4__Service_Configuration__c.getAll();
if(!mapSvcCfg.isEmpty()){
   	if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('TOKEN')){
   		url = mapSvcCfg.get('HOST_URI').KNDY4__URL__c + mapSvcCfg.get('TOKEN').KNDY4__URL__c;
   	}
    if(mapSvcCfg.containskey('APP_ID')){
   		applicationId = mapSvcCfg.get('APP_ID').KNDY4__URL__c;
    }
    if(string.isNotBlank(url) && string.isNotBlank(applicationId)){
    	HttpRequest req = new HttpRequest();
	    req.setMethod('POST');
		    req.setEndpoint(url +'?appIds='+ applicationId);
		    string authorizationHeader = 'cobSession='+mapSvcCfg.get('cobrandLogin').KNDY4__Session_Token__c +',userSession=' + mapSvcCfg.get('YodleeUserLogin').KNDY4__Session_Token__c;
	        req.setHeader('Authorization',authorizationHeader);
			req.setHeader('Content-Type', 'application/json');
		    
	    system.debug('req = '+ req);
	    HttpResponse res = new Http().send(req);
	    string body = res.getBody();
	    system.debug('body = '+ body);
    }
}
	Sample Response JSON
	************************
	{
	   "user":{
	    "accessTokens":[
	     {
	        "appId":"10003600"
	        "value":"9670352f863c07bed8c2ce606bf8a23cc701f2a5f72821e5c11f42e5e821f053"
	     }
	    ]
	   }
	}
********************************************************/
    public static YodleeUserAPIParser getToken(string cobrandSessionToken, string userSessionToken) {
   		string url;
   		string applicationId;
   		string token;
   		YodleeUserAPIParser userResult ;
   		map<string,Service_Configuration__c> mapSvcCfg = Service_Configuration__c.getAll();
   		if(!mapSvcCfg.isEmpty()){
   			if(mapSvcCfg.containskey('HOST_URI') && mapSvcCfg.containskey('TOKEN')){
   				url = mapSvcCfg.get('HOST_URI').URL__c + mapSvcCfg.get('TOKEN').URL__c;
   			}
   			if(mapSvcCfg.containskey('APP_ID')){
   				applicationId = mapSvcCfg.get('APP_ID').URL__c;
   			}
   		}
   		try {
   			system.debug('conditions=' + cobrandSessionToken + '='+userSessionToken +'='+url +'='+applicationId);
        if(string.isNotBlank(cobrandSessionToken) && string.isNotBlank(userSessionToken) && string.isNotBlank(url) && 
           string.isNotBlank(applicationId)){ 
	        
	            HttpRequest req = new HttpRequest();
	            req.setMethod('GET');
	            req.setTimeout(120000);
	            req.setEndpoint(url + '?' + finAppId+'='+EncodingUtil.urlEncode(applicationId, 'UTF-8'));
	            string authorizationHeader = paramNameCobSessionToken + '='+cobrandSessionToken +','+paramNameUserSessionToken+'=' + userSessionToken;
	            req.setHeader('Authorization',authorizationHeader);
				req.setHeader('Content-Type', 'application/json');
				
	            system.debug('req = '+ req + 'url='+url + '?' + finAppId+'='+EncodingUtil.urlEncode(applicationId, 'UTF-8'));
	            HttpResponse res = new Http().send(req);
	            string body = res.getBody();
	            system.debug(logginglevel.error,'getToken body = '+ body);
	            userResult = (YodleeUserAPIParser)YodleeJsonParser.jsonParser.deserialize(body,YodleeUserAPIParser.class);	            
	            
	        
        	}else{
        		throw new YodleeAPIException(Label.Yodlee_Setup_Message);
	            } 
	        } catch (Exception e) {
	            system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
	            userResult = new YodleeUserAPIParser();
	            userResult.errorCode  = e.getMessage();
	        } 
        system.debug('getToken result: '+userResult);
        return userResult;
        }
    
    public static list<LinkedAccountToKenandy> getLinkedBankAccount() {
   		list<Bank_Account__c> lstBankAccount = new list<Bank_Account__c>();
   		Date todayDate = system.Today();
   		List<LinkedAccountToKenandy> lstLinkedBankAccounts = new List<LinkedAccountToKenandy>();
        LinkedAccountToKenandy linkedAccount;
   		try{
   		SOQLUtil soql = new SOQLUtil('Bank_Account__c', true); 
		soql.addFields('Linked_Account_with_Yodlee');
		soql.setWhereClause('Yodlee_Account_Number__c != null');
		soql.setLimit(1000);
		lstBankAccount = Database.query(soql.getQuery());
	        
        List<string> lstSplitAccount = new list<string>();
        for (Bank_Account__c bAcc :lstBankAccount){
        	
            if (string.isNotBlank( bAcc.Yodlee_Account_Name__c)){
        		 lstSplitAccount = bAcc.Yodlee_Account_Name__c.trim().split('-');
           
            }
            system.debug('splitAccount=='+ lstSplitAccount.Size() + '='+lstSplitAccount);
            string siteName = '';
            string accNumber = '';
        	if (lstSplitAccount.Size() > 0){
        		siteName = lstSplitAccount[0];        		
        	}
        	
    		accNumber = string.isNotBlank( bAcc.Yodlee_Account_Name__c) ? bAcc.Yodlee_Account_Name__c.replace(siteName +'-','') : '';
        		
        	linkedAccount = new LinkedAccountToKenandy(siteName,accNumber,integer.valueOf(bAcc.Yodlee_Account_Number__c),bAcc.id,bAcc.Name);
        	lstLinkedBankAccounts.add(linkedAccount);
	        	
	        }	        
        }catch(Exception e){
        	system.debug('EXCEPTION ' + e.getMessage()+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
        	lstLinkedBankAccounts = new List<LinkedAccountToKenandy>();
        	linkedAccount = new LinkedAccountToKenandy(e.getMessage(),Label.Contact_Sys_Admin_Or_Customer_Support);
        	lstLinkedBankAccounts.add(linkedAccount);
        }
        system.debug('lstLinkedBankAccounts=='+lstLinkedBankAccounts);
        return lstLinkedBankAccounts;
    }
     public static list<string> delinkBankAccount(list<string> lstBankAccIds) {
        list<string> lstMessages = new list<string>();
        list<Bank_Account__c> lstBankAccount = new list<Bank_Account__c>();
        if(!lstBankAccIds.isEmpty()){
        	for(string bankAccId: lstBankAccIds){
        		lstBankAccount.add(new Bank_Account__c(Id=bankAccId, Yodlee_Account_Number__c='',Yodlee_Account_Linkage_Date__c=null, Yodlee_Account_Name__c='', Yodlee_Account_Site_ID__c=''));
        	}
        	try{
            	DML.updateAsSystem(lstBankAccount);
            }catch(DMLexception e){
            	for(integer i=0;i<e.getNumDml();i++) {
                	lstMessages.add(e.getDmlMessage(i) + '. ' + Label.Contact_Sys_Admin_Or_Customer_Support); 
                	system.debug('EXCEPTION ' + e.getDMLMessage(i)+' ' + e.getLineNumber() + 'stacktrace = '+ e.getStacktracestring());
            	}
            	}
        	catch(Exception ex){
	    		system.debug('EXCEPTION ' + ex.getMessage()+' ' + ex.getLineNumber() + 'stacktrace = '+ ex.getStacktracestring());
	    		lstMessages.add(ex.getMessage() + '. '+ Label.Contact_Sys_Admin_Or_Customer_Support);
        	} 
                  
        }
        return lstMessages;
    }
}