public with sharing class YodleeUserRegistrationAndAccountLinkExt extends GridRelatedListController {
    private static string cobrandSessionToken;
    private static string UserSessionToken;
    private static string UserName;
    private static string UserPasswd;
    public static string cobrandUserName;
    public static string cobrandPasswd;
    ApexPages.StandardSetController setcon;
    public boolean isUserCreated{get;set;}
    public GridRelatedListController.GridRelatedListConfig YodleeLinkedAccountGridConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig YodleeSiteLinkedGridConfig {get; set;} //KNDY-13289
    public string YodleeLinkedAccountFieldList;
    public string SiteLinksToYodleeFieldList;
    public boolean isError{get;set;}
    public string nspace { get { return KSE.Namespace; }}
    //KNDY- 13539 - Added user registration variables
    public string loginName {get;set;}
    public string loginPasswd {get;set;}
    public string loginEmail {get; set;}
    public string firstName {get; set;}
    public string lastName {get; set;}
    
	public YodleeUserRegistrationAndAccountLinkExt(ApexPages.StandardController c) {
    	
    }
    public YodleeUserRegistrationAndAccountLinkExt(Apexpages.standardsetcontroller c) {
        setcon = c;
        isUserCreated = false;
        isError = false;
        Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
        Service_Configuration__c serConfgUser = Service_Configuration__c.getValues('YodleeUserLogin');
        if(Service_Configuration__c.getAll().isEmpty()){
        	isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Yodlee_Setup_Message));
        }
        if(serConfg != null){
            if(string.isNotBlank(serConfg.username__c)){
                cobrandUserName = serConfg.username__c;
            }else{
            	if(!isError){
	            	isError = true;
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Yodlee_Setup_Message));
            	}
            }
            if(string.isNotBlank(serConfg.password__c)){
                cobrandPasswd = serConfg.password__c;
            }else{
                if(!isError){
	            	isError = true;
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Yodlee_Setup_Message));
            	}
            }
        }else{
            if(!isError){
	            isError = true;
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Yodlee_Setup_Message));
            }
        }
        if(serConfgUser != null){
            if(string.isNotBlank(serConfgUser.username__c) && string.isNotBlank(serConfgUser.password__c)){
                UserName = serConfgUser.username__c;
                UserPasswd = serConfgUser.password__c;
                isUserCreated = true;
            }
        }
        //KNDY-13539 - set default user variables for setting up yodleeuserlogin
        else{
        	
        	UserName = UserInfo.getOrganizationId();
        	loginName = UserName;
        	firstName = 'Treasury';
        	lastName = 'Manager';
        	UserPasswd = generatePwd(9);
        	if (string.isNotBlank(UserPasswd) && UserPasswd.substring(0,UserPasswd.length()-1).isAlpha()){
	        	while(true){
		        	if (UserPasswd.substring(0,UserPasswd.length()-1).isAlpha()){
						system.debug('again generate pwd');
						UserPasswd = generatePwd(9);					
					}else
						break;
	        	}
        	}
        	loginPasswd = UserPasswd;
        	loginEmail = Label.Yodlee_User_Registration_Email;
        }
        if(!isError){
	        YodleeLinkedAccountGridConfig = new GridRelatedListController.GridRelatedListConfig();
	        YodleeLinkedAccountGridConfig.uniqueId = 'yodleeLinkedAccountGrid';
	        YodleeLinkedAccountGridConfig.title = 'Linked Accounts';
	        YodleeLinkedAccountGridConfig.objectName = 'Bank_Account__c'; 
	        YodleeLinkedAccountGridConfig.fieldset = 'Linked_Account_with_Yodlee';
            YodleeLinkedAccountGridConfig.alwaysUseFullDateTimeFormat = false;
            YodleeLinkedAccountGridConfig.buttons = 'search';
            //Yodlee Site linked KNDY-13289
            YodleeSiteLinkedGridConfig = new GridRelatedListController.GridRelatedListConfig();
            YodleeSiteLinkedGridConfig.uniqueId = 'yodleeSiteLinkedAccountGrid';
            YodleeSiteLinkedGridConfig.title = 'Site Linked to Yodlee';
            YodleeSiteLinkedGridConfig.objectName = ''; 
            YodleeSiteLinkedGridConfig.fieldset = '';
            YodleeSiteLinkedGridConfig.alwaysUseFullDateTimeFormat = false;
            YodleeSiteLinkedGridConfig.buttons = 'search';
            
        }
    }
    
    //KNDY-13539- generate random  char password for given len
    private string generatePwd(integer len){
		/*Blob blobKey = crypto.generateAesKey(192);
		String key = EncodingUtil.convertToHex(blobKey);
		String pwd = key.substring(0,len);*/
		String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
	    String[] result = new String[len];
	    Integer idx = 0;
	
	    while(idx < len) {
	        Integer chr = Math.mod(Math.abs(Crypto.getRandomInteger()), 62);
	        result[idx++] = chars.substring(chr, chr+1);
	    }
		system.debug('*****'+String.join(result,''));
		string pwd = String.join(result,'');
		
		system.debug('pwd=='+ pwd);
		return pwd +'@';
				
    }
    public String getYodleeLinkedAccountFieldList() {
        if (String.isBlank(YodleeLinkedAccountFieldList) && YodleeLinkedAccountGridConfig != null) {                
            list<FieldInfo> lstfieldInfo = new list<FieldInfo>();
            FieldInfo fld = new FieldInfo();
            fld.title = Label.Financial_Institution;
            fld.field =  'SiteName';
            fld.editable = false;
            fld.sortable = true; 
            lstfieldInfo.add(fld); 
            list<FieldInfo> lstfieldSetInfo = FieldInfo.fetchJsonFieldInfos(YodleeLinkedAccountGridConfig.objectName, YodleeLinkedAccountGridConfig.fieldset);
            lstfieldInfo.addall(lstfieldSetInfo);
            Set<String> hiddenFields = new Set<String> {'Id','Yodlee_Account_Site_ID__c'};
            
            for(Integer counter = 1; counter < lstfieldInfo.size(); counter++){
                String fieldtitle = lstfieldInfo[counter].title;
                String fieldName = lstfieldInfo[counter].field;
                lstfieldInfo[counter].title = fieldtitle;
                lstfieldInfo[counter].field = fieldName;
                lstfieldInfo[counter].editable = false;
                lstfieldInfo[counter].hidden = hiddenFields.contains(fieldName);   
                //KNDY-13289 - setup different labels than actuals
                if(lstfieldInfo[counter].field =='Yodlee_Account_Site_ID__c'){
                    lstfieldInfo[counter].hidden = true;
                }
                if(lstfieldInfo[counter].field =='Yodlee_Account_Name__c'){
                 	lstfieldInfo[counter].title = Label.Financial_Account; 
                    lstfieldInfo[counter].field = 'YodleeAccountName';
                }
                if(lstfieldInfo[counter].field =='Yodlee_Account_Number__c'){
                    lstfieldInfo[counter].field = 'YodleeAccountNumber';
                }
                if(lstfieldInfo[counter].field =='Name'){
                  lstfieldInfo[counter].referenceTo = 'Id';
                  lstfieldInfo[counter].fieldtype ='Name';
                  lstfieldInfo[counter].title = Label.Bank_Account_Name;  
             	}
                lstfieldInfo[counter].sortable = true; 
            }           
            YodleeLinkedAccountFieldList = JSON.serialize(lstfieldInfo);
        }       
        return YodleeLinkedAccountFieldList;
    }
    //KNDY-13289 - Set site links to yodlee grid field set
    public String getSiteLinksToYodleeFieldList() {
        system.debug('SiteLinksToYodleeFieldList=='+SiteLinksToYodleeFieldList);
        if (String.isBlank(SiteLinksToYodleeFieldList) ) {                
            list<FieldInfo> lstfieldInfo = new list<FieldInfo>();//FieldInfo.fetchJsonFieldInfos(YodleeSiteLinkedGridConfig.objectName, YodleeSiteLinkedGridConfig.fieldset);
            Set<String> hiddenFields = new Set<String> {'Id'};
            system.debug('lstfieldInfo=='+ lstfieldInfo);
            FieldInfo fld = new FieldInfo();
                String fieldtitle = Label.Financial_Institution;
                String fieldName = 'AccountName';
                fld.title = fieldtitle;
                fld.field = fieldName;
                fld.editable = false;
                fld.sortable = true; 
                lstfieldInfo.add(fld);
                
                fld = new FieldInfo();
                fieldtitle = Label.Yodlee_Site_ID;
                fieldName = 'siteId';
                fld.title = fieldtitle;
                fld.field = fieldName;
                fld.editable = false;
                fld.sortable = true; 
                lstfieldInfo.add(fld);
                
                fld = new FieldInfo();
	            fld.title = Label.Refresh_Status;
	            fld.field =  'status';
	            fld.editable = true;
	            fld.sortable = true; 
	            lstfieldInfo.add(fld);        
            
                fld = new FieldInfo();
                fieldtitle = 'Disable Remove';
                fieldName = 'disableRemove';
                fld.title = fieldtitle;
                fld.field = fieldName;
                fld.editable = false;
                fld.hidden = true;
                lstfieldInfo.add(fld);
                
            system.debug('lstfieldInfo=='+ lstfieldInfo);
            SiteLinksToYodleeFieldList = JSON.serialize(lstfieldInfo);
        }       
        return SiteLinksToYodleeFieldList;
    }
    public string getLinkedAccountGridConfig() {
        string YodleeLinkedAccountConfigString = JSON.serialize(YodleeLinkedAccountGridConfig);
        return YodleeLinkedAccountConfigString;
    }
    //KNDY-13289 - setup sites grid config string
    public string getSiteLinksToYodleeGridConfig() {
        string SiteLinksToYodleeConfigString = JSON.serialize(YodleeSiteLinkedGridConfig);
        return SiteLinksToYodleeConfigString;
    }
    public string getURL() {
    	string url;
    	Service_Configuration__c serConfgUrl = Service_Configuration__c.getValues('FAST_LINK');
    	if(serConfgUrl != null){
    		url = serConfgUrl.URL__c;
    	}
    	return url;
    }
    
    public string getAppId() {
    	string appId;
    	Service_Configuration__c serConfgAppId = Service_Configuration__c.getValues('APP_ID');
    	if(serConfgAppId != null){
    		appId = serConfgAppID.URL__c;
    	}
    	return appId;
    }
    
    @RemoteAction
    public static JsonResult cobrandlogin(){
        JsonResult jResult = new JsonResult();
        Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
        if(serConfg != null && string.isNotBlank(serConfg.username__c) && string.isNotBlank(serConfg.password__c)){
            YodleeUserAPIParser cobrandResult = YodleeBankTransactionServices.cobrandlogin(serConfg.username__c, serConfg.password__c);
            system.debug('cobrandlogin jResult='+ cobrandResult + '-' + cobrandResult.errorCode);
             if(cobrandResult != null && cobrandResult.session != null && cobrandResult.session.cobSession != null){
                jResult.total = 1;
                jResult.success = true;
                jResult.records = new list<string>{cobrandResult.session.cobSession};
            }else if (cobrandResult != null && string.isNotBlank(cobrandResult.errorCode)){
            	jResult.total = 0;
                jResult.success = false;
                if (string.isNotBlank(cobrandResult.referenceCode))
                	jResult.addMessage(Label.Yodlee_Generic_Error_Msg +( serConfg != null && String.isNotBlank(serConfg.URL__C) ? ' (' +serConfg.URL__c.replace('v1/','')  + '): ' : ': ')+ cobrandResult.errorCode + '-' + cobrandResult.errorMessage  + ' (' + cobrandResult.referenceCode + '). ' + Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
                else
                	jResult.addMessage(cobrandResult.errorCode + ( string.isNotBlank(cobrandResult.errorMessage) ? '-' + cobrandResult.errorMessage : '' ) +'. ' + Label.Contact_Sys_Admin_Or_Customer_Support , ApexPages.Severity.ERROR);
             	system.debug('cobrandlogin jResult='+ jResult);
            }else{
                jResult.total = 0;
                jResult.success = false;
                jResult.addMessage(Label.Invalid_CobrandName_Password_Msg, ApexPages.Severity.ERROR);
            }
        }else{
            jResult.total = 0;
            jResult.success = false;
            jResult.addMessage(Label.Blank_CobrandName_Password_Msg, ApexPages.Severity.ERROR);
        }
        return jResult;
    }
    
	 
    @RemoteAction
    public static JsonResult registerUser(string loginName, string passwd,
                                          string emailAddress, string currencyUsed, string dateFormat,
                                          string firstName, string lastName, string middleInitial,
                                          string addr1, string addr2, string city, string country, string cobrandSession){
        JsonResult jResult = new JsonResult();
        YodleeUserAPIParser cobrandResult;
        if(string.isBlank(cobrandSession)){
            Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
            if(serConfg != null && string.isNotBlank(serConfg.username__c) && string.isNotBlank(serConfg.password__c)){
                cobrandResult = YodleeBankTransactionServices.cobrandlogin(serConfg.username__c, serConfg.password__c);
    }
	        if(cobrandResult != null && cobrandResult.session != null && cobrandResult.session.cobSession != null){
	            jResult.total = 1;
	            jResult.success = true;
	            jResult.records = new list<string>{cobrandResult.session.cobSession};
	        }else if (cobrandResult != null && string.isNotBlank(cobrandResult.errorCode) ){
	        	jResult.total = 0;
	            jResult.success = false;
	            if (string.isNotBlank(cobrandResult.referenceCode))
                	jResult.addMessage(Label.Yodlee_Generic_Error_Msg +( serConfg != null && String.isNotBlank(serConfg.URL__C) ? ' (' +serConfg.URL__c.replace('v1/','')  + '): ' : ': ')+ cobrandResult.errorCode + '-' + cobrandResult.errorMessage  + ' (' + cobrandResult.referenceCode + '). ' + Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
                else
                	jResult.addMessage(cobrandResult.errorCode + (string.isNotBlank(cobrandResult.errorMessage) ? '-' + cobrandResult.errorMessage : '') +'. ' +Label.Contact_Sys_Admin_Or_Customer_Support , ApexPages.Severity.ERROR);
	         }else{
                jResult.total = 0;
                jResult.success = false;
                jResult.addMessage(Label.Invalid_CobrandName_Password_Msg, ApexPages.Severity.ERROR);
            }
        }else{ 
            Service_Configuration__c serConfg = Service_Configuration__c.getValues('USER_REGISTER_URL');
            YodleeUserAPIParser regUserWrapper = new YodleeUserAPIParser();
            YodleeUserAPIParser.UserWrapper userWrap = new YodleeUserAPIParser.UserWrapper();
            userWrap.loginName = loginName;
            userWrap.password = passwd;
            userWrap.email = emailAddress;
            YodleeUserAPIParser.NameWrapper nameWrap = new YodleeUserAPIParser.NameWrapper();
            nameWrap.first = firstName;
            nameWrap.last = lastName;
            userWrap.name = nameWrap;
            regUserWrapper.user = userWrap;
    
            YodleeUserAPIParser userResult = YodleeBankTransactionServices.registerUser(cobrandSession, regUserWrapper);
            if(userResult != null && userResult.user != null && userResult.user.session != null){
                UserName = loginName;
                UserPasswd = passwd;
                jResult.total = 1;
                jResult.success = true;
                jResult.records = new list<string>{userResult.user.session.userSession};                
            }else if (userResult != null && string.isNotBlank(userResult.errorCode) ){
            	jResult.total = 0;
                jResult.success = false;
                if (string.isNotBlank(userResult.referenceCode))
                	jResult.addMessage(Label.Yodlee_Generic_Error_Msg +(serConfg != null && string.isnotBlank(serConfg.URL__c) ? ' (' +serConfg.URL__c.replace('v1/','')  + '): ' : ': ') + userResult.errorCode + '-' + userResult.errorMessage  + ' (' + userResult.referenceCode + '). ' +Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
                else
                	jResult.addMessage(userResult.errorCode +(string.isNotBlank(userResult.errorMessage) ? '-' + userResult.errorMessage : '')  +'. '+Label.Contact_Sys_Admin_Or_Customer_Support , ApexPages.Severity.ERROR);                
            }else{
                jResult.total = 0;
                jResult.success = false;
                jResult.addMessage(Label.Yodlee_User_Not_Created_Msg, ApexPages.Severity.ERROR);
            }
        }
        return jResult;
    }
    
    @RemoteAction
    public static JsonResult insertUser(string cobrandSession,string UName, string UPasswd,string userSession){
        JsonResult jResult = new JsonResult();
        if(string.isNotBlank(UName) && string.isNotBlank(UPasswd)){
            boolean isSuccess = YodleeBankTransactionServices.insertUser(cobrandSession,UName, UPasswd,userSession);
            if(isSuccess){
                jResult.success = true;
            }else{
                jResult.success = false;
                jResult.addMessage(Label.Yodlee_User_Registration_Failed_Msg, ApexPages.Severity.ERROR);
            }
        }
        return jResult;
    }
     @RemoteAction
    public static JsonResult getSiteAccounts(string cobrandSession, string userSession){
        JsonResult jResult = new JsonResult();
        list<YodleeBankTransactionServices.siteAccount> lstSiteAccount = YodleeBankTransactionServices.getSiteAccounts(cobrandSession, userSession);
        system.debug ('empty list=' +lstSiteAccount.isEmpty() + '-'+lstSiteAccount.size());        
        if(!lstSiteAccount.isEmpty() && lstSiteAccount.size() >=0 && string.isBlank(lstSiteAccount[0].errorMessage)){ 
            jResult.success = true;
            jResult.records = lstSiteAccount;
        }else if (lstSiteAccount.isEmpty()){
        	jResult.success = true;
            jResult.records = new list<YodleeBankTransactionServices.siteAccount>();
            system.debug('jResult.records='+jResult.records);
        }else if(!lstSiteAccount.isEmpty() && lstSiteAccount.size() >=0 && string.isNotBlank(lstSiteAccount[0].errorMessage)){ 
            jResult.success = false;
            jResult.records = new list<YodleeBankTransactionServices.siteAccount>();
            jResult.addMessage(lstSiteAccount[0].errorMessage, ApexPages.Severity.ERROR);
        }
        return jResult; 
        
    }
    //KNDY-15857 - fetch refresh status
    @RemoteAction
    public static JsonResult getSiteAccountsWithProviders(string cobrandSession, string userSession, string providerAccountId){
        JsonResult jResult = new JsonResult();
        list<YodleeBankTransactionServices.siteAccount> lstSiteAccount = YodleeBankTransactionServices.getSiteAccountsWithProviders(cobrandSession, userSession,providerAccountId);
        system.debug ('empty list=' +lstSiteAccount.isEmpty() + '-'+lstSiteAccount.size());        
        if(!lstSiteAccount.isEmpty() && lstSiteAccount.size() >=0 && string.isBlank(lstSiteAccount[0].errorMessage)){ 
            jResult.success = true;
            jResult.records = lstSiteAccount;
        }else if (lstSiteAccount.isEmpty()){
        	jResult.success = true;
            jResult.records = new list<YodleeBankTransactionServices.siteAccount>();
            system.debug('jResult.records='+jResult.records);
        }else if(!lstSiteAccount.isEmpty() && lstSiteAccount.size() >=0 && string.isNotBlank(lstSiteAccount[0].errorMessage)){ 
            jResult.success = false;
            jResult.records = new list<YodleeBankTransactionServices.siteAccount>();
            jResult.addMessage(lstSiteAccount[0].errorMessage, ApexPages.Severity.ERROR);
        }
        return jResult; 
        
    }
    
    //KNDY-13289 - remove site linkages to yodlee
     @RemoteAction
    public static JsonResult removeSiteAccounts(string cobrandSession, string userSession, string memSiteAccId){
        JsonResult jResult = new JsonResult();
        string body = YodleeBankTransactionServices.removeSiteAccounts(cobrandSession, userSession, memSiteAccId);
        system.debug('removesites==' +string.isBlank( body));
        if(string.isBlank( body) ){
            jResult.success = true;
        }else{
            jResult.success = false;
            jResult.addMessage(body,ApexPages.Severity.ERROR);
        }
        system.debug('jResult=='+jResult);
        return jResult; 
    
    } 
    //KNDY-15857 - refresh sites manually
     @RemoteAction
    public static JsonResult refreshSiteAccounts(string cobrandSession, string userSession, string memSiteAccId){
        JsonResult jResult = new JsonResult();
        string body = YodleeBankTransactionServices.refreshSiteAccounts(cobrandSession, userSession, memSiteAccId);
        system.debug('refreshSiteAccounts==' +string.isBlank( body));
        if(string.isBlank( body) ){
            jResult.success = true;
        }else{
            jResult.success = false;
            jResult.addMessage(body,ApexPages.Severity.ERROR);
        }
        system.debug('jResult=='+jResult);
        return jResult; 
    
    } 
    @RemoteAction
    public static JsonResult getSummaryForSite(string siteIdName, string siteAccountName, string cobrandSession, string userSession){
        JsonResult jResult = new JsonResult();
        list<YodleeBankTransactionServices.SummaryForSite> lstAccountIdName = YodleeBankTransactionServices.getSummaryForSite(siteIdName, siteAccountName, cobrandSession, userSession);
        system.debug ('empty list=' +lstAccountIdName.isEmpty() + '-'+lstAccountIdName.size() +'='+ lstAccountIdName);        
        if(!lstAccountIdName.isEmpty() && lstAccountIdName.size() >=0 && string.isBlank(lstAccountIdName[0].errorMessage) ){
            jResult.success = true;
            jResult.records = lstAccountIdName;
        }else if (lstAccountIdName.isEmpty()){
        	jResult.success = true;
            jResult.records = new list<YodleeBankTransactionServices.SummaryForSite>();
            jResult.addMessage(Label.Yodlee_Summary_Sites_Failed_Msg, ApexPages.Severity.ERROR);
            system.debug('jResult.records='+jResult.records);
        }else if(!lstAccountIdName.isEmpty() && lstAccountIdName.size() >=0 && string.isNotBlank(lstAccountIdName[0].errorMessage)){ 
            jResult.success = false;
            jResult.records = new list<YodleeBankTransactionServices.SummaryForSite>();
            jResult.addMessage(lstAccountIdName[0].errorMessage, ApexPages.Severity.ERROR); 
        }
        return jResult;
    }
    
    @RemoteAction
    public static JsonResult getUnlinkedAccount(list<YodleeBankTransactionServices.SummaryForSite> lstSummaryForSite){
        JsonResult jResult = new JsonResult();
        list<YodleeBankTransactionServices.SummaryForSite> lstUnlinkedAccountAndYodleeId = YodleeBankTransactionServices.getUnlinkedAccount(lstSummaryForSite);
        if(!lstUnlinkedAccountAndYodleeId.isEmpty() && lstUnlinkedAccountAndYodleeId.size() >=0 && string.isBlank(lstUnlinkedAccountAndYodleeId[0].errorMessage) ){
            jResult.success = true;
            jResult.records = lstUnlinkedAccountAndYodleeId;
        }else if(!lstUnlinkedAccountAndYodleeId.isEmpty() && lstUnlinkedAccountAndYodleeId.size() >=0 && string.isNotBlank(lstUnlinkedAccountAndYodleeId[0].errorMessage)){ 
            jResult.success = false;
            jResult.records = new list<YodleeBankTransactionServices.SummaryForSite>();
            jResult.addMessage(lstUnlinkedAccountAndYodleeId[0].errorMessage, ApexPages.Severity.ERROR); 
        }else if(lstUnlinkedAccountAndYodleeId.isEmpty()){
            jResult.success = false;
            jResult.records = new list<YodleeBankTransactionServices.SummaryForSite>();
        }
        return jResult;
    }
    
     @RemoteAction
    public static JsonResult linkBankAccountWithSite(list<string> lstBA, list<string> lstSiteAccountId, list<string> lstSiteAccountName){
        JsonResult jResult = new JsonResult();
        list<string> lstErrorMessage = YodleeBankTransactionServices.linkBankAccountWithSite(lstBA, lstSiteAccountId, lstSiteAccountName);
        if(lstErrorMessage.isEmpty()){
            jResult.success = true;
        }else if(!lstErrorMessage.isEmpty() && lstErrorMessage.size() >= 0){
            jResult.success = false;
            jResult.addMessage(lstErrorMessage[0], ApexPages.Severity.ERROR);
        }
        return jResult;
    }
    
    @RemoteAction
    public static JsonResult getLinkedBankAccount(){
        JsonResult jResult = new JsonResult();
        list<YodleeBankTransactionServices.LinkedAccountToKenandy> lstBankAccount = YodleeBankTransactionServices.getLinkedBankAccount();
        if(!lstBankAccount.isEmpty() && lstBankAccount.size()>= 0 && string.isBlank(lstBankAccount[0].errorMessage)){
            jResult.success = true;
            jResult.records = lstBankAccount;
        }else if(!lstBankAccount.isEmpty() && lstBankAccount.size()>= 0 && string.isNotBlank(lstBankAccount[0].errorMessage)){
            jResult.success = false;
            jResult.addMessage(lstBankAccount[0].errorMessage, ApexPages.Severity.ERROR);
            jResult.records = new list<Bank_Account__c>();
        }else if (lstBankAccount.isEmpty()){
            jResult.success = true;
            jResult.records = new list<Bank_Account__c>();
        }
        return jResult;
    }
    
    public string goback{
    	get{
	        Schema.DescribeSObjectResult result = Bank_Account__c.SObjectType.getDescribe();
	        PageReference pageRef = new PageReference('/' + result.getKeyPrefix());// + '?fcf=' +setcon.getFilterId());
	        string url = string.valueOf(pageRef);
	        if(url.contains('System.PageReference')){
	        	url = url.replaceAll('System.PageReference','');
	        }
	        if(url.contains(']') || url.contains('[')){
	        	url = url.replaceAll('[\\[\\]]','');
	        }
	        system.debug(logginglevel.debug,'pageRef'+pageRef);
	        system.debug(logginglevel.debug,'goback url=='+url);
	        return url;
    	}set;
    }
    
    @RemoteAction
    public static JsonResult getToken(string cobrandSession, string userSession){
        JsonResult jResult = new JsonResult();
        string token;
        if(string.isNotBlank(cobrandSession) && string.isNotBlank(userSession)){
            YodleeUserAPIParser userResult = YodleeBankTransactionServices.getToken(cobrandSession, userSession);
            Service_Configuration__c serConfg = Service_Configuration__c.getValues('TOKEN');
            if (userResult != null && userResult.user != null && userResult.user.accessTokens != null){
            	token = userResult.user.accessTokens[0].valueField;
                jResult.total = 1;
                jResult.success = true;
                jResult.records = new list<string>{userSession, token};
            }else if (userResult != null && userResult.user != null && string.isNotBlank(userResult.errorCode) ){
                jResult.total = 0;
                jResult.success = false;
                if (string.isNotBlank(userResult.referenceCode))
                	jResult.addMessage(Label.Yodlee_Generic_Error_Msg +(serConfg != null && string.isnotBlank(serConfg.URL__c) ? ' (' +serConfg.URL__c.replace('v1/','')  + '): ' : ': ')  + userResult.errorCode + '-' + userResult.errorMessage +' (' + userResult.referenceCode + '). ' +Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
                else
                	jResult.addMessage(userResult.errorCode + (string.isNotBlank(userResult.errorMessage) ? '-' + userResult.errorMessage : '') + '. ' + Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
            }
        }else{
            jResult.total = 0;
            jResult.success = false;
            jResult.addMessage(Label.Blank_CobrandName_Password_Msg, ApexPages.Severity.ERROR);
        }
        return jResult;
    }
    
    @RemoteAction
    public static JsonResult delinkBankAccount(list<string> lstBAId){
        JsonResult jResult = new JsonResult();
        list<string> lstMessages = YodleeBankTransactionServices.delinkBankAccount(lstBAId);
        if(lstMessages.isEmpty()){
            jResult.success = true;
        }else{
            jResult.success = false;
            for(string message: lstMessages){
            	jResult.addMessage(message, ApexPages.Severity.ERROR);
            }
        }
        return jResult;
    }
}