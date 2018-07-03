//not with sharing class as this extension is used to pull transactions from yodlee and insert them in bank transaction object.
//Also, custom setting read/write is involved
public class YodleeTransactionSearchExt{
    ApexPages.StandardSetController setcon;
    public static string cobrandUserName;
    public static string cobrandPasswd;  
    private static string UserName;
    private static string UserPasswd; 
    private static string cobrandSessionToken;
    private static string UserSessionToken;
    public static boolean isUserCreated{get;set;}
    public static list<string> lstYodleeBankAccount{get;set;}
    public string bt{get;set;}
    public string nspace { get { return KSE.Namespace; }}
    public YodleeTransactionSearchExt(ApexPages.StandardController c) {
       
    }
    
    public YodleeTransactionSearchExt(Apexpages.standardsetcontroller c) {
        setcon = c;
        bt = JSON.serialize(new Bank_Transaction__c());
        boolean isValid = true;
        Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
        Service_Configuration__c serConfgUser = Service_Configuration__c.getValues('YodleeUserLogin');
        if(serConfg != null){
            if(string.isNotBlank(serConfg.username__c)){
                cobrandUserName = serConfg.username__c;
            }else{
                isValid = false;
            }
            if(string.isNotBlank(serConfg.password__c)){
                cobrandPasswd = serConfg.password__c;
            }else{
                isValid = false;
            }
        }else{
            isValid = false;
        }
        if(serConfgUser != null){
            if(string.isNotBlank(serConfgUser.username__c)){
                UserName = serConfgUser.username__c;
            }else{
                isValid = false;
                isUserCreated = false;
            }
            if(string.isNotBlank(serConfgUser.password__c)){
                UserPasswd = serConfgUser.password__c;
            }else{
                isValid = false;
                isUserCreated = false;
            }
        }else{
            isValid = false;
        }
        if(isValid){
            list<Bank_Account__c> lstBankAccount = setcon.getSelected();
            if(!lstBankAccount.isEmpty()){
                lstYodleeBankAccount = new list<string>();
                SOQLUtil soql;
        		soql = new SOQLUtil('Bank_Account__c', TRUE);
        		soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c'});
        		soql.setWhereClause('Id in :lstBankAccount');
                for(Bank_Account__c account :Database.Query(soql.getQuery())){
                    system.debug(logginglevel.debug,'Yodlee_Account_Number__c'+account.Yodlee_Account_Number__c);
                    if(string.isNotBlank(account.Yodlee_Account_Number__c)){
                    	lstYodleeBankAccount.add(account.Yodlee_Account_Number__c);
                    }
                }
            }else{
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Select_at_least_one_account));
            }
        }else{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Yodlee_Setup_Message));
        }
    }
    
    public PageReference goback() {
        Schema.DescribeSObjectResult result = Bank_Account__c.SObjectType.getDescribe();
        PageReference pageRef = new PageReference('/' + result.getKeyPrefix()+'?fcf='+setcon.getFilterId());
        system.debug(logginglevel.debug,'pageRef'+pageRef);
        pageRef.setRedirect(false);
        return pageRef;
    }
    
     @RemoteAction
    public static JsonResult cobrandAndUserlogin(){
        JsonResult jResult = new JsonResult();
        YodleeUserAPIParser apiResult;
        Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
        if(serConfg != null && string.isNotBlank(serConfg.username__c) && string.isNotBlank(serConfg.password__c)){
            apiResult = YodleeBankTransactionServices.cobrandlogin(serConfg.username__c, serConfg.password__c);            	        
            if(apiResult != null && apiResult.session != null && apiResult.session.cobSession != null){
            	system.debug('inside cobrand = '+apiResult.session.cobSession);
            	cobrandSessionToken = apiResult.session.cobSession;
                Service_Configuration__c serConfgUser = Service_Configuration__c.getValues('YodleeUserLogin');
                if(serConfgUser != null && string.isNotBlank(serConfgUser.username__c) && string.isNotBlank(serConfgUser.password__c)){
                    apiResult = YodleeBankTransactionServices.Userlogin(serConfgUser.username__c, serConfgUser.password__c, cobrandSessionToken);
                    system.debug('inside user apiResult='+apiResult);
                    if(apiResult != null && apiResult.user != null && apiResult.user.session != null)
                    	UserSessionToken = apiResult.user.session.userSession;
                    if(string.isNotBlank(UserSessionToken)){
                        jResult.total = 1;
                        jResult.success = true;
                        jResult.records = new list<string>{cobrandSessionToken,UserSessionToken};
                     }else if (apiResult != null && string.isNotBlank(apiResult.errorCode) ){
		                jResult.total = 0;
			            jResult.success = false;
			            //jResult.addMessage(apiResult.errorCode + '-' + apiResult.errorMessage, ApexPages.Severity.ERROR);
			             if (string.isNotBlank(apiResult.referenceCode))
		                	jResult.addMessage(Label.Yodlee_Generic_Error_Msg +(serConfgUser != null && string.isnotBlank(serConfgUser.URL__c) ? ' (' +serConfgUser.URL__c.replace('v1/','')  + '): ' : ': ')  + apiResult.errorCode + '-' + apiResult.errorMessage +' (' + apiResult.referenceCode + '). ' +Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
		                else
		                	jResult.addMessage(apiResult.errorCode +  ( apiResult.errorMessage != null ? '-' + apiResult.errorMessage : '' )  + '. ' + Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
                    }else{
                        jResult.total = 0;
                        jResult.success = false;
                        jResult.addMessage(Label.Yodlee_Setup_Message, ApexPages.Severity.ERROR);
                    }
                }else{
                    jResult.total = 0;
                    jResult.success = false;
                    jResult.addMessage(Label.Yodlee_Setup_Message , ApexPages.Severity.ERROR);
                }
            }else if (apiResult != null && string.isNotBlank(apiResult.errorCode) ){
                jResult.total = 0;
	            jResult.success = false;
	             if (string.isNotBlank(apiResult.referenceCode))
                	jResult.addMessage(Label.Yodlee_Generic_Error_Msg +(serConfg != null && string.isnotBlank(serConfg.URL__c) ? ' (' +serConfg.URL__c.replace('v1/','')  + '): ' : ': ')  + apiResult.errorCode + '-' + apiResult.errorMessage +' (' + apiResult.referenceCode + '). ' +Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
                else
                	jResult.addMessage(apiResult.errorCode + ( apiResult.errorMessage != null ? '-' + apiResult.errorMessage : '' )  + '. ' + Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
            }else{
                jResult.total = 0;
                jResult.success = false;
	            jResult.addMessage(Label.Invalid_CobrandName_Password_Msg, ApexPages.Severity.ERROR);
            }
        }else{
            jResult.total = 0;
            jResult.success = false;
            jResult.addMessage(Label.Yodlee_Setup_Message , ApexPages.Severity.ERROR);
        }
        return jResult;
    }
    
    @RemoteAction
    public static JsonResult searchBankTransactions(string cobrandSession,
                                           string userSession, string container,
                                           string baseType, string keyword, string accountId,
                                           string fromDate, string toDate, string categoryId,
                                           string highLevelCategoryId, string trantype, string categoryType,
                                           string skip, string top){
        JsonResult jResult = new JsonResult();
        if(string.isNotBlank(cobrandSession)){
            if(string.isNotBlank(userSession)){
            	Map<string,string> responseData;
                responseData = YodleeBankTransactionServices.searchBankTransactions(cobrandSession,
                                           userSession, container,
                                           baseType, keyword, accountId,
                                           fromDate, toDate, categoryId,
                                           highLevelCategoryId, trantype, categoryType,
                                           skip,top, 'true');
                if(responseData != null && responseData.containsKey('Body')){
                    jResult.success = true;
                    jResult.records = new list<string>{responseData.get('Body')};
                    jResult.addMessage(Label.Transaction_Retrieved_successfully, ApexPages.Severity.INFO);
                }else if(responseData != null && responseData.containsKey('Error')){
                    jResult.success = false;
                    jResult.records = new list<string>();
                    jResult.addMessage(responseData.get('Error'), ApexPages.Severity.ERROR);
                }   
            }
            else{
                jResult.success = false;
                jResult.addMessage(Label.User_Session_Token_is_invalid_Please_contact_your_system_administrator, ApexPages.Severity.ERROR);
            }
        }else{
            jResult.success = false;
            jResult.addMessage(Label.Cobrand_Session_Token_is_invalid_Please_contact_your_system_administrator, ApexPages.Severity.ERROR);
        }
        return jResult;
    }
        
    @RemoteAction
    public static JsonResult getTransactionsCount(string cobrandSession,
                                           string userSession, string accountId,
                                           string fromDate, string toDate){
        JsonResult jResult = new JsonResult();
        String transactionsCount;
        if(string.isNotBlank(cobrandSession)){
            if(string.isNotBlank(userSession)){
                YodleeTransactionCountParser transactionCountData;
                transactionCountData = YodleeBankTransactionServices.getTransactionsCount(cobrandSession,
                                           userSession, accountId,
                                           fromDate, toDate);
                                           
                System.debug(logginglevel.error,'transactionCountData---->'+transactionCountData);
                System.debug(logginglevel.error,'transactionCountData.transactionWrapper---->'+transactionCountData.transactionWrapper);
                System.debug(logginglevel.error,'transactionCountData.errorCode---->'+transactionCountData.errorCode);
                
                if(transactionCountData != null && transactionCountData.transactionWrapper != null && transactionCountData.transactionWrapper.total.countValue != null){
                    transactionsCount = transactionCountData.transactionWrapper.total.countValue;    
                    jResult.success = true;
                    jResult.records = new list<string>{transactionsCount};
                    jResult.addMessage(Label.Transaction_Count_Retrieved_successfully, ApexPages.Severity.INFO);  
                }else if(transactionCountData != null && transactionCountData.transactionWrapper == null && string.isNotBlank(transactionCountData.errorCode)){
                    jResult.success = false;
                    jResult.records = new list<string>();
                    //KNDY-18903  fixed error message 
                    if (transactionCountData.referenceCode != null)
                    	jResult.addMessage(transactionCountData.errorCode + (string.isNotBlank(transactionCountData.errorMessage) ? '-' + transactionCountData.errorMessage : '') + '. ' + Label.Contact_Sys_Admin_Or_Customer_Support, ApexPages.Severity.ERROR);
                    else
                    	jResult.addMessage(transactionCountData.errorCode + (string.isNotBlank(transactionCountData.errorMessage) ? '-' + transactionCountData.errorMessage : ''), ApexPages.Severity.ERROR);
                }
                else if(transactionCountData != null && transactionCountData.transactionWrapper == null ){
                    jResult.success = false;
                    jResult.records = new list<string>();
                    jResult.addMessage(Label.No_records_to_retrieve, ApexPages.Severity.INFO);
                }   
            }else{
                jResult.success = false;
                jResult.addMessage(Label.User_Session_Token_is_invalid_Please_contact_your_system_administrator, ApexPages.Severity.ERROR);
            }
        }else{
            jResult.success = false;
            jResult.addMessage(Label.Cobrand_Session_Token_is_invalid_Please_contact_your_system_administrator, ApexPages.Severity.ERROR);
        }
        return jResult;
    }
        
    @RemoteAction
    public static JsonResult saveBTs(list<Bank_Transaction__c> lstBT){
        JsonResult jResult = new JsonResult();
        system.debug('-------'+lstBT);
        if(!lstBT.isEmpty()){
            list<string> lstErrorMessage = YodleeBankTransactionServices.saveBTs(lstBT);
            if(lstErrorMessage.isEmpty()){
                jResult.success = true;
                jResult.records = lstBT;
                jResult.addMessage('Records Successfully Created!', ApexPages.Severity.INFO);
            }else{
                jResult.success = true;
                for(string msg: lstErrorMessage){
                    jResult.addMessage(msg, ApexPages.Severity.ERROR);
                }
            }
        }else{
            jResult.success = false;
            jResult.addMessage('Records not created. Please contact your system administrator', ApexPages.Severity.ERROR);  
        }
        return jResult;
    }
}