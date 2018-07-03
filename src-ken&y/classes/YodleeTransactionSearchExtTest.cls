@isTest
public class YodleeTransactionSearchExtTest {
    @testSetup static void createTestDate() {
		system.assert(bankAccount != null);
		system.assert(periodList != null);
	}
	//KNDY-16435
	public class MockHttpResponseGenerator implements HttpCalloutMock{
		protected String bodyAsString;
		public MockHttpResponseGenerator(string body){
			bodyAsString = body;
		}
		
		public HTTPResponse respond(HttpRequest req) {
			// Create a fake response 
	    	system.debug('bodyAsString='+bodyAsString);
	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');       
	        res.setBody(bodyAsString);
	        res.setStatusCode(200);
	        System.assert(res.getBody()!=null);
	        return res;
		}
		
		
	}
	public class MultiRequestMock implements HttpCalloutMock {
		Map<String, HttpCalloutMock> requests;
		
		public MultiRequestMock(Map<String, HttpCalloutMock> requests) {
		    this.requests = requests;
		}
		public HTTPResponse respond(HTTPRequest req) {
		
		    boolean contains = requests.containsKey(req.getEndpoint());
		    if (contains == true) {
		        HttpCalloutMock mock = requests.get(req.getEndpoint());
		        return mock.respond(req);
		    } else {
		        List<HttpCalloutMock> mocks = requests.values();
		        if(mocks.size() > 0){
		            return mocks[0].respond(req);
		        }
		        else {
		            return null;
		        }
		    }
		}
	}
    static void createServiceConfiguraionData(boolean isCreateCobrand, boolean isCreateUser){
    	list<Service_Configuration__c> lstSC = new list<Service_Configuration__c>();
    	if(isCreateCobrand){
	    	lstSC.add(new Service_Configuration__c(Name='cobrandLogin', Password__c='TG@1tfer2w', 
	    										   UserName__c='sandbox', Description__c='cobrand login and password'));
    	}
    	if(isCreateUser){
	    	lstSC.add(new Service_Configuration__c(Name='YodleeUserLogin', Password__c='kenandy', 
	    										   UserName__c='kenandy', Description__c='User Name and Password'));
    	}
    	lstSC.add(new Service_Configuration__c(Name='DAYS_TO_PULL_TRANSACTION', 
    										   Username__c = '90'));
    	lstSC.add(new Service_Configuration__c(Name='COB_LOGIN_URL', 
    										   URL__c = 'v1/cobrand/login'));
    	lstSC.add(new Service_Configuration__c(Name='FAST_LINK', 
    										   URL__c = 'https://yieapnodestage.yodlee.com/authenticate/private-sandbox219/?channelAppName=yisandbox'));
    	lstSC.add(new Service_Configuration__c(Name='TOKEN', 
    										   URL__c = 'v1/user/accessTokens'));
	    lstSC.add(new Service_Configuration__c(Name='GET_ACCOUNTS_URL', 
    										   URL__c = 'v1/accounts'));
    	lstSC.add(new Service_Configuration__c(Name='GET_PROVIDER_URL', 
    										   URL__c = 'v1/providers'));
    	lstSC.add(new Service_Configuration__c(Name='GET_SITE_ACCOUNTS_URL', 
    										   URL__c = 'v1/providerAccounts'));
    	lstSC.add(new Service_Configuration__c(Name='APP_ID', 
    										   URL__c = '10003600'));
    	lstSC.add(new Service_Configuration__c(Name='HOST_URI', 
    										   URL__c = 'https://stage.api.yodlee.com/ysl/private-sandbox219/'));
    	lstSC.add(new Service_Configuration__c(Name='USER_LOGIN_URL', 
    										   URL__c = 'v1/user/login'));
    	lstSC.add(new Service_Configuration__c(Name='USER_REGISTER_URL', 
    										   URL__c = 'v1/user/register'));
    	lstSC.add(new Service_Configuration__c(Name='USER_TRANSACTION_SEARCH', 
    										   URL__c = 'v1/transactions'));								   
    	lstSC.add(new Service_Configuration__c(Name='GET_Transaction_Count_URL', 
                                               URL__c = 'v1/transactions/count'));								   
    	if(!lstSC.isEmpty()){
    		DML.insertAsSystem(lstSC);
    	}
    	
    }
    
    public static Account account {
        get {
            if (account == null) {
               	account = new Account();
                //account.name = 'KenandyTestFuel'+ '-' + String.ValueOf(Math.round(Math.random(), 2));
                account.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
                account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
                account.billingcity = 'Redwood City';
                account.billingstate = 'CA';
                account.billingpostalcode = '94065';
                account.billingcountry = 'USA';
                account.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
                account.shippingcity = 'Redwood City';
                account.shippingstate = 'CA';
                account.shippingpostalcode = '94065';
                account.shippingcountry = 'USA';
                account.phone = '650-468-2000'+ String.ValueOf((Integer) (Math.random () * 999));
                account.fax = '650-468-2010';
                account.website = 'kenandy.com' + String.ValueOf((Integer) (Math.random () * 999));
                insert account;
            }
            return account;
        }
        set;
    }
    
    public static Currency__c currencyUSD{
        get {
            if(currencyUSD== null){
                currencyUSD = new Currency__c();
                currencyUSD.name = 'USD TestFuel';
                //currencyUSD.Active__c = TRUE;
                currencyUSD.ISO_Code__c = 'USD';
                currencyUSD.Currency__c = 'USD Currency';
                insert currencyUSD;
            }
            return currencyUSD;
        }
        
        set;
    }
  
    public static Currency__c currencyGBP {
        get {
            if(currencyGBP == null){
                currencyGBP = new Currency__c();
                currencyGBP.name = 'GBP TestFuel';
                //currencyUSD.Active__c = TRUE; 
                currencyGBP.ISO_Code__c = 'GBP';
                currencyGBP.Currency__c = 'British Pound';
                insert currencyGBP;
            }
            return currencyGBP;
        }
        
        set;
    } 

    public static Currency__c currencyEUR {
        get {
            if(currencyEUR == null){
                currencyEUR = new Currency__c();
                currencyEUR.name = 'EUR TestFuel';
                //currencyUSD.Active__c = TRUE;
                currencyEUR.ISO_Code__c = 'EUR';
                currencyEUR.Currency__c = 'EURO Currency';
                insert currencyEUR;
            }
            return currencyEUR;
        }
        
        set;
    }

    public static Currency__c currencySGD {
        get {
            if(currencySGD == null){
                currencySGD = new Currency__c();
                currencySGD.name = 'SGD TestFuel';
                //currencyUSD.Active__c = TRUE;
                currencySGD.ISO_Code__c = 'SGD';
                currencySGD.Currency__c = 'SGD Currency';
                insert currencySGD;
            }
            return currencySGD;
        }
        
        set;
    }
    
    public static Company__c company {
        get {
            if (company == null) {
                company = new Company__c();
                    company.name = 'KenandyTestFuel'+ '-' + String.ValueOf((Integer) (Math.random () * 999));
                    company.Address__c = account.Id;
                    company.A_Days__c = 30;
                    company.B_Days__c = 60;
                    company.C_Days__c = 180;
                    company.Company_Identifier__c = 'KEN' + '-' + String.ValueOf((Integer) (Math.random () * 999));
                    company.Comp_Currency__c = currencySGD.id;
                    company.Consol_Currency__c = currencyEUR.id;
                    company.Stat_Currency__c = currencyGBP.id;
                    company.Subs_Currency__c = currencyUSD.id;
                    company.Default_Transaction_Currency__c = currencyUSD.id;
					system.assert(AutoBackdatingConfigVal != null);//Make the setting to default No as all existing tests are written based on that flow.
                    insert company;
            }
            return company;
        }
        set;
    }
    
    public static Configuration__c AutoBackdatingConfigVal {
        get {
            if(AutoBackdatingConfigVal==null){
                // Create Configuration
                AutoBackdatingConfigVal = new Configuration__c();
                AutoBackdatingConfigVal.name = 'AutoBackdateToOpenSubledgers';
                AutoBackdatingConfigVal.Value__c = 'No';
                insert AutoBackdatingConfigVal;                
            }
            return AutoBackdatingConfigVal;
        }
        set;
    }
    
      public static List<Period__c> periodList {
        get {
            if (periodList == null) {
            	integer year = system.now().year();
       			periodList = new List<Period__c>();
       			
       			//insert current year
       			for(integer i=1; i<=12; i++){
				    Period__c iPeriod = new Period__c();
				    //iPeriod.Name = string.valueOf(i) + '-' + string.valueOf(year);
				    //iPeriod.Name = string.valueOf(i) + '-' + String.ValueOf(Math.random());
				    iPeriod.Name = string.valueOf(i)+ '-' + String.ValueOf((Integer) (Math.random () * 999) + system.now().getTime());
				    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
				    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
				    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
				    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
				    iPeriod.Period_Number__c = i;
				    if(i>=1 && i <= 3){
				        iPeriod.Quarter_Number__c = 1;
				    }else if(i>=4 && i <= 6){
				        iPeriod.Quarter_Number__c = 2;
				    }else if(i>=7 && i <= 9){
				        iPeriod.Quarter_Number__c = 3;
				    }else if(i>=10 && i <= 12){
				        iPeriod.Quarter_Number__c = 4;
				    }	
				    
				    iPeriod.Fiscal_Year__c = String.valueOf(year);
				    iPeriod.Company__c = company.Id;
				    iPeriod.Adjustment_Period__c = false;
				    iPeriod.Closed__c = false;
				    iPeriod.Open__c = i >= system.now().month();
				    iPeriod.Fiscal__c = true;
				    iPeriod.Corporate__c = false;
				    iPeriod.Tax__c = false;
				    iPeriod.Permanently_Closed__c = false;
				    iPeriod.Adjustment_Period__c = false;
				    
				    iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.JE_Cutoff__c = iPeriod.Period_End__c;
				    
				    periodList.add(iPeriod);
				}
				
				
				//insert next year
				year++;
				for(integer i=1; i<=12; i++){
				    Period__c iPeriod = new Period__c();
				    //iPeriod.Name = string.valueOf(i) + '-' + string.valueOf(year);
				    //iPeriod.Name = string.valueOf(i) + '-' + String.ValueOf(Math.random());
				    iPeriod.Name = string.valueOf(i)+ '-' + String.ValueOf((Integer) (Math.random () * 999) + system.now().getTime());
				    iPeriod.Year_Start_Date__c = date.newInstance(year, 1, 1);
				    iPeriod.Year_End_Date__c = date.newInstance(year + 1, 1, 1);
				    iPeriod.Period_Start__c = datetime.newInstance(year, i, 1, 0, 0, 0);
				    iPeriod.Period_End__c = datetime.newInstance((i == 12 ? year + 1 : year), (i == 12 ? 1 : i + 1), 1, 0, 0, 0);
				    iPeriod.Period_Number__c = i;
				    if(i>=1 && i <= 3){
				        iPeriod.Quarter_Number__c = 1;
				    }else if(i>=4 && i <= 6){
				        iPeriod.Quarter_Number__c = 2;
				    }else if(i>=7 && i <= 9){
				        iPeriod.Quarter_Number__c = 3;
				    }else if(i>=10 && i <= 12){
				        iPeriod.Quarter_Number__c = 4;
				    }	
				    
				    iPeriod.Fiscal_Year__c = String.valueOf(year);
				    iPeriod.Company__c = company.Id;
				    iPeriod.Adjustment_Period__c = false;
				    iPeriod.Closed__c = false;
				    iPeriod.Open__c = i >= system.now().month();
				    iPeriod.Fiscal__c = true;
				    iPeriod.Corporate__c = false;
				    iPeriod.Tax__c = false;
				    iPeriod.Permanently_Closed__c = false;
				    iPeriod.Adjustment_Period__c = false;
				    
				    iPeriod.AP_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.AR_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.Shipment_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.Receiving_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.FA_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.Inventory_Subledger_Cutoff__c = iPeriod.Period_End__c;
				    iPeriod.JE_Cutoff__c = iPeriod.Period_End__c;
				    
				    periodList.add(iPeriod);
				}
				
				Fiscal_Year__c fy = new Fiscal_Year__c();
				fy.company__c = company.Id;
				fy.fiscal_year_start_date__c = periodList[0].period_start__c;
				fy.fiscal_year_end_date__c = periodList[periodList.size()-1].period_end__c.addMonths(3);
				
				insert fy;
				for(Period__c p : periodList){
					p.fiscalyear__c = fy.Id;
				}
				
        		insert periodList;
            }
            update periodList;
            
            return periodList;
        } 
        set;
    }    
    
    public static List<GL_Type__c> GLTypeTestData{
    	get{
    		if(GLTypeTestData == null){
    			string glTypeBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLType' LIMIT 1].body.toString();
    			GLTypeTestData = (List<GL_Type__c>)CSVParser.parseRecords(GL_Type__c.sObjectType, glTypeBody);
    			system.debug('GLTypeTestData:'+GLTypeTestData);
    			insert GLTypeTestData;
    		}
    		return GLTypeTestData;
    	}
    	set ;
    	 
    }
    
    public static List<GL_Account__c> GLAccountTestData{
    	get{
    			system.assert(GLTypeTestData.size() != 0);
	    		if(GLAccountTestData == null){
	    			//List<sObject> recs = Test.loadData(GL_Account__c.sObjectType, 'TestData_GLAccount');
	    			//GLAccountTestData = (List<GL_Account__c>)recs;
	    			string glAccountBody = [SELECT id, Body FROM StaticResource WHERE Name = 'TestData_GLAccount' LIMIT 1].body.toString();
	    			GLAccountTestData = (List<GL_Account__c>)CSVParser.parseRecords(GL_Account__c.sObjectType, glAccountBody);
	    			system.debug(logginglevel.info,'GLAccountTestData:'+GLAccountTestData);
	    			insert GLAccountTestData;
	    		}
    	
    		return GLAccountTestData;
    	}
    	set ;
    	 
    }
    
    public static Map<String,GL_Account__c> mGLAccounts {
    	get{
    		if(mGLAccounts == null){
    			mGLAccounts = new Map<String,GL_Account__c>();
    			for(GL_Account__c gla: GLAccountTestData){
    				String s = String.valueof(gla.get('GL_Account_Number__c'));
    				mGLAccounts.put(s, gla);
    			}
    		}
    		return mGLAccounts;
    	}
    	set;
    }
    
    public static GL_Account__c cashGL { 
		get {
			if ( cashGL == null && mGLAccounts.containsKey('12000')) {
				cashGL = mGLAccounts.get('12000');
			}
			return cashGL; 
		}
		set; 
	}
	
    public static Bank_Account__c bankAccount {
		get {
			if (bankAccount == null) {
    			bankAccount = new Bank_Account__c(
    				Name = 'Test BOFA',
    				account_type__c = 'Checking',
    				GL_Account__c = cashGL.id,
    				Company__c = company.Id,
    				Active__c = true,
    				Yodlee_Account_Number__c = '28862580',
    				Yodlee_Account_Linkage_Date__c = system.now().date()
				);
				insert bankAccount; 
			}
			return bankAccount;
		}
		set; 
    } 
    
     public static list<Bank_Transaction__c> lstBankTransactions{
    	get{
    		if(lstBankTransactions == null){
    			lstBankTransactions = new list<Bank_Transaction__c>();
    			SOQLUtil newsoql;
                newsoql = new SOQLUtil('Company__c', TRUE);
                newsoql.addFields(new Set<String>{'Id'});
                newsoql.setLimit(1);
                Company__c c = Database.Query(newsoql.getQuery()); 
                
                SOQLUtil newsoql1;
                newsoql1 = new SOQLUtil('Bank_Account__c', TRUE);
                newsoql1.addFields(new Set<String>{'Id'});
                newsoql1.setLimit(1);
                Bank_Account__c BA = Database.Query(newsoql1.getQuery()); 
                
                SOQLUtil soql1;
		        soql1 = new SOQLUtil('Currency__c', TRUE);
		        soql1.addFields(new Set<String>{'Id'});
		        soql1.setWhereClause('ISO_Code__c =\'USD\'');
				soql1.setLimit(1);
    			Currency__c usd = Database.Query(soql1.getQuery());
    	
                Bank_Transaction__c bankTransaction = new Bank_Transaction__c();
                bankTransaction.Amount__c = 5000.00;
                bankTransaction.Bank_Account__c = BA.id;
                bankTransaction.Currency__c = usd.Id;
                bankTransaction.Company__c = c.Id;
                bankTransaction.Transaction_Type__c = 'Credit';
                bankTransaction.Reference_Number__c = '123s44567mnJ';
                bankTransaction.Source__c = 'Yodlee';
                bankTransaction.Transacted_With__c = 'KPMG';
               bankTransaction.Transaction_Id__c = '123456';
                bankTransaction.Transaction_Date__c = System.now();
                bankTransaction.Payment_Method__c = 'Wire';
                //bankTransaction.SubTransaction_Type__c = 'Credit';
                bankTransaction.Account_Number__c = '28862580';
                lstBankTransactions.add(bankTransaction);
                
                bankTransaction = new Bank_Transaction__c();
                bankTransaction.Amount__c = -3000.00;
                bankTransaction.Currency__c = usd.Id;
                bankTransaction.Bank_Account__c = BA.id;
                bankTransaction.Company__c = c.Id;
                bankTransaction.Transaction_Type__c = 'Debit';
                bankTransaction.Reference_Number__c = '123s44567mnK';
                bankTransaction.Source__c = 'Yodlee';
                bankTransaction.Transacted_With__c = 'KPMG';
                bankTransaction.Transaction_Id__c = '123457';
                bankTransaction.Transaction_Date__c = System.now();
                bankTransaction.Payment_Method__c = 'Check';
                //bankTransaction.SubTransaction_Type__c = 'Debit'; 
                bankTransaction.Account_Number__c = '28862580';              
                lstBankTransactions.add(bankTransaction);
                
                bankTransaction = new Bank_Transaction__c();
                bankTransaction.Amount__c = 3000.00;
                bankTransaction.Currency__c = usd.Id;
                bankTransaction.Bank_Account__c = BA.id;
                bankTransaction.Company__c = c.Id;
                bankTransaction.Transaction_Type__c = 'Credit';
                bankTransaction.Reference_Number__c = '123s44567mnL';
                bankTransaction.Source__c = 'Yodlee';
                bankTransaction.Transacted_With__c = 'KPMG';
                bankTransaction.Transaction_Id__c = '123458';
                bankTransaction.Transaction_Date__c = System.now();
                bankTransaction.Payment_Method__c = 'Cash';
                //bankTransaction.SubTransaction_Type__c = 'Credit'; 
                bankTransaction.Account_Number__c = '28862580';               
                lstBankTransactions.add(bankTransaction);
            }
            return lstBankTransactions;
    	}
    	set;
    }
    
    @isTest
    static void testcobrandAndUserlogin(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);

    	Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        HttpCalloutMock multiCalloutMock1 = new MockHttpResponseGenerator(requestResponseBodies.get('cobrandLogin'));
	    HttpCalloutMock multiCalloutMock2 = new MockHttpResponseGenerator(requestResponseBodies.get('userLogin'));
	    endpoint2TestResp.put('https://stage.api.yodlee.com/ysl/private-sandbox219/v1/cobrand/login',multiCalloutMock1);
        endpoint2TestResp.put('https://stage.api.yodlee.com/ysl/private-sandbox219/v1/user/login',multiCalloutMock2);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(endpoint2TestResp);
        
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
    	
    	Test.startTest();
    	JsonResult jResult = YodleeTransactionSearchExt.cobrandAndUserlogin();
    	System.assertNotEquals(null, jResult.records[0],jResult);
    	System.assertNotEquals(null, jResult.records[1]);
    	Test.stopTest();	
    }
    
     @isTest
    static void testcobrandAndUserlogin_setController(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery()); 
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	system.debug('lstBA--'+lstBA);
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(standardsObjectController);
    	Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        HttpCalloutMock multiCalloutMock1 = new MockHttpResponseGenerator(requestResponseBodies.get('cobrandLogin'));
	    HttpCalloutMock multiCalloutMock2 = new MockHttpResponseGenerator(requestResponseBodies.get('userLogin'));
	    endpoint2TestResp.put('https://stage.api.yodlee.com/ysl/private-sandbox219/v1/cobrand/login',multiCalloutMock1);
        endpoint2TestResp.put('https://stage.api.yodlee.com/ysl/private-sandbox219/v1/user/login',multiCalloutMock2);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(endpoint2TestResp);
        
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
    	Test.startTest();
    	JsonResult jResult = YodleeTransactionSearchExt.cobrandAndUserlogin();
    	System.assertNotEquals(null, jResult.records[0]);
    	System.assertNotEquals(null, jResult.records[1]);
    	Test.stopTest();	
    }
    
    @isTest
    static void testsearchBankTransactions(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);

        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('transactionCount')));
    	Test.startTest();
        JsonResult jResult1 = YodleeTransactionSearchExt.getTransactionsCount('cobrandSession','userSession',
                                                                               '28790524','2013-01-01','2014-01-01');   
        System.debug(logginglevel.error, 'jResult1--->'+jResult1.records[0]);
        System.assertEquals(YodleeTransactionSearchExtTest.transactionCount, Integer.valueOf(jResult1.records[0]),'Transaction Count is not correct');
        
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('searchTransaction')));
    	JsonResult jResult = YodleeTransactionSearchExt.searchBankTransactions('cobrandSession','userSession','',
    																		   '','','28790524','2013-01-01','2014-01-01','',
    																		   '','','','1','500');
    	System.assertNotEquals(null, jResult.records,jResult);
    	Test.stopTest();	
    }
    
    @isTest
    static void testGetTransactionsCount(){
        //create custom setting record 
        createServiceConfiguraionData(true,true);
        SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
        soql.setLimit(1);
        Bank_Account__c bA = Database.Query(soql.getQuery());
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
        YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('transactionCount')));
        Test.startTest();
        JsonResult jResult = YodleeTransactionSearchExt.getTransactionsCount('cobrandSession','userSession',
                                                                               '28790524','2013-01-01','2014-01-01');                                                                      
        System.debug(logginglevel.error, 'jResult--->'+jResult.records);
        System.assertNotEquals(null, jResult.records,jResult);
        System.assertEquals(YodleeTransactionSearchExtTest.transactionCount, Integer.valueOf(jResult.records[0]), 'Transaction Count is not correct' );
        Test.stopTest();    
    }
    
    @isTest
    static void testGetTransactionsCountFailure(){
        //create custom setting record 
        createServiceConfiguraionData(true,true);
        SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
        soql.setLimit(1);
        Bank_Account__c bA = Database.Query(soql.getQuery());
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
        YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('errorResponse')));
        Test.startTest();
        JsonResult jResult = YodleeTransactionSearchExt.getTransactionsCount('cobrandSession','userSession',
                                                                               '28790524','2016-01-01','2017-01-01');                                                                      
        system.debug(logginglevel.error,'jResult==>'+jResult);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jResult.messages)
            if(msg.containsKey('message')){
                if(msg.get('message').contains('Y008-Invalid token in authorization header')){
                    ErrorExists = true;
                    break;
                }
            }
        System.assertEquals(true, ErrorExists,jResult);
        system.debug(logginglevel.error,'jResult.records==>'+jResult.records);
        Test.stopTest();      
    }
    
    @isTest
    static void testsearchBankTransactionsWithoutDate(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
		
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	
    	insert lstBankTransactions;
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('searchTransaction')));
    	Test.startTest();
    	
    	JsonResult jResult = YodleeTransactionSearchExt.searchBankTransactions('cobrandSession','userSession','',
    																		   '','','28862580',null,null,'',
    																		   '','','','1','500');
    	System.assertNotEquals(null, jResult.records,jResult);
    
    	Test.stopTest();	
    }
    @isTest
    static void testsearchBankTransactionsWithoutDateandTrans(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
		
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('searchTransaction')));
    	Test.startTest();
    	
    	JsonResult jResult = YodleeTransactionSearchExt.searchBankTransactions('cobrandSession','userSession','',
    																		   '','','28862580',null,null,'',
    																		   '','','','1','500');
    	System.assertNotEquals(null, jResult.records,jResult);

    	Test.stopTest();	
    }
    @isTest
    static void testregisterUser(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	SOQLUtil soql;
    	soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('registerUser')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.registerUser('Arch1376475200981', 'password#',
                                          'johndoe@abc.com', 'PREFERRED_CURRENCY~USD', 'PREFERRED_DATE_FORMAT~MM/dd/yyyy',
                                          'John', 'Doe', 'M',
                                          '3600 Bridge Parkway', 'Suite 200', 'Redwood City', 'USA','cobrandSession');
    	System.assertNotEquals(null, jResult.records);
    	Test.stopTest();	
    }
    
    @isTest
    static void testregisterUserBlankCobrand(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	SOQLUtil soql;
    	soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('cobrandLogin')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.registerUser('Arch1376475200981', 'password#',
                                          'johndoe@abc.com', 'PREFERRED_CURRENCY~USD', 'PREFERRED_DATE_FORMAT~MM/dd/yyyy',
                                          'John', 'Doe', 'M',
                                          '3600 Bridge Parkway', 'Suite 200', 'Redwood City', 'USA',null);
    	System.assertNotEquals(null, jResult.records,jResult);
    	Test.stopTest();	
    }
    @isTest
    static void testregisterUserErrorCobrand(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	SOQLUtil soql;
    	soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('registerUser')));
    	Test.startTest();
    	//null response
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.registerUser('Arch1376475200981', 'password#',
                                          'johndoe@abc.com', 'PREFERRED_CURRENCY~USD', 'PREFERRED_DATE_FORMAT~MM/dd/yyyy',
                                          'John', 'Doe', 'M',
                                          '3600 Bridge Parkway', 'Suite 200', 'Redwood City', 'USA',null);
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Invalid CobrandName/Password.')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        System.assertEquals(true, ErrorExists,jResult);
        //invalid cobrand
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('invalidCobrandCredential')));
        jResult = YodleeUserRegistrationAndAccountLinkExt.registerUser('Arch1376475200981', 'password#',
                                          'johndoe@abc.com', 'PREFERRED_CURRENCY~USD', 'PREFERRED_DATE_FORMAT~MM/dd/yyyy',
                                          'John', 'Doe', 'M',
                                          '3600 Bridge Parkway', 'Suite 200', 'Redwood City', 'USA',null);
    	ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Invalid cobrand credentials')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        System.assertEquals(true, ErrorExists,jResult);
        //error response from user registration       
		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('invalidUserCredential')));
        jResult = YodleeUserRegistrationAndAccountLinkExt.registerUser('Arch1376475200981', 'password#',
                                          'johndoe@abc.com', 'PREFERRED_CURRENCY~USD', 'PREFERRED_DATE_FORMAT~MM/dd/yyyy',
                                          'John', 'Doe', 'M',
                                          '3600 Bridge Parkway', 'Suite 200', 'Redwood City', 'USA','cobrandSession');
    	ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Invalid value for password')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        System.assertEquals(true, ErrorExists,jResult);
    	Test.stopTest();	
    }
    @isTest
    static void testsaveBTs(){
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name', 'Company__c'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	Test.startTest();
    	JsonResult jResult = YodleeTransactionSearchExt.saveBTs(lstBankTransactions);
    	System.assertNotEquals(null, jResult.records,jResult + '= ' + lstBankTransactions);
    	
    	//testing subtransaction type field
    	SOQLUtil soql1;
        soql1 = new SOQLUtil('Bank_Transaction__c', TRUE);
        soql1.addFields(new Set<String>{'Id','SubTransaction_Type__c', 'Transaction_Type__c'});
    	list<Bank_Transaction__c> lstBT = Database.Query(soql1.getQuery());
    	for(Bank_Transaction__c bt:lstBT){
    		if(bt.Transaction_Type__c == 'Credit'){
    			system.assertEquals(true,bt.SubTransaction_Type__c == 'Debit');
    		}else if(bt.Transaction_Type__c == 'Debit'){
    			system.assertEquals(true,bt.SubTransaction_Type__c == 'Credit');
    		}
    	}
    	Test.stopTest();	
    }
    
     @isTest
    static void testinsertUser(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.insertUser('cobrandSession','Arch1376475200981', 'password#','userSession');
    	System.assertEquals(true,jResult.success,jResult);
    	Test.stopTest();	
    }
    
    @isTest
    static void testcoBrandUserNamePasswordNotExist_setController(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
    	serConfg.username__c = '';
    	serConfg.password__c = '';
    	DML.updateAsSystem(serConfg);
    	
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.startTest();
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(new ApexPages.StandardSetController(lstBA));
    	boolean ErrorExists = false;
        for(ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains(Label.Yodlee_Setup_Message)){
        		ErrorExists = true;
        		break;
        	}
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }
    
     @isTest
    static void testUserNamePasswordNotExist_setController(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	Service_Configuration__c serConfg = Service_Configuration__c.getValues('YodleeUserLogin');
    	serConfg.username__c = '';
    	serConfg.password__c = '';
    	DML.updateAsSystem(serConfg);
    	
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	
    	Test.startTest();
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(new ApexPages.StandardSetController(lstBA));
    	boolean ErrorExists = false;
        for(ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains(Label.Yodlee_Setup_Message)){
        		ErrorExists = true;
        		break;
        	}
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }
    
    @isTest
    static void testcoBrandAndUserNotExist_setController(){
    	//create custom setting record 
    	createServiceConfiguraionData(false,false);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(standardsObjectController);
    	boolean ErrorExists = false;
        for(ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains(Label.Yodlee_Setup_Message)){
        		ErrorExists = true;
        		break;
        	}
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }
    
    @isTest
    static void testUserNotExist_setController(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(standardsObjectController);
    	boolean ErrorExists = false;
        for(ApexPages.Message msg :ApexPages.GetMessages()){
        	if(msg.getDetail().contains(Label.Yodlee_Setup_Message)){
        		ErrorExists = true;
        		break;
        	}
        }
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();
    }
    @isTest
    static void testThrowErrorCobrandlogin(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	Service_Configuration__c serConfg = Service_Configuration__c.getValues('COB_LOGIN_URL');
    	delete (serConfg);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('cobrandLogin')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.cobrandlogin();
    	System.assertEquals(null, jResult.records,jResult);
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Yodlee_Setup_Message)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
        System.assertEquals(true, ErrorExists,jResult);
       
    	Test.stopTest();	
    }
    
    @isTest
    static void testThrowErrorCobrandlogin_Userpwdnotexists(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);    
		SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);
    	
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('invalidCobrandCredential')));
    
    	Test.startTest();
    	Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
    	serConfg.username__c = '';
    	serConfg.password__c = '';
    	DML.updateAsSystem(serConfg);
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.cobrandlogin();
    	System.assertEquals(null, jResult.records,jResult);
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Blank CobrandName/Password')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
        System.assertEquals(true, ErrorExists,jResult);
       
    	Test.stopTest();	
    }
    @isTest
    static void testinvalidcobrandlogin(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('invalidCobrandCredential')));
    	Test.startTest();
    	JsonResult jResult = YodleeTransactionSearchExt.cobrandAndUserlogin();
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Invalid cobrand credentials')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
        System.assertEquals(true, ErrorExists,jResult);
    	Test.stopTest();	
    }
    
    @isTest
    static void testinvalidUserlogin(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(sc);
    	Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        HttpCalloutMock multiCalloutMock1 = new MockHttpResponseGenerator(requestResponseBodies.get('cobrandLogin'));
	    HttpCalloutMock multiCalloutMock2 = new MockHttpResponseGenerator(requestResponseBodies.get('invalidUserCredential'));
	    endpoint2TestResp.put('https://stage.api.yodlee.com/ysl/private-sandbox219/v1/cobrand/login',multiCalloutMock1);
        endpoint2TestResp.put('https://stage.api.yodlee.com/ysl/private-sandbox219/v1/user/login',multiCalloutMock2);
        HttpCalloutMock multiCalloutMock = new MultiRequestMock(endpoint2TestResp);
        
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
    	Test.startTest();
    	JsonResult jResult = YodleeTransactionSearchExt.cobrandAndUserlogin();
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Invalid value for password')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
        System.assertEquals(true, ErrorExists,jResult);
    	Test.stopTest();	
    }
    
     @isTest
    static void testgoBack(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeTransactionSearchExt yodleeTransSearchExtObj = new YodleeTransactionSearchExt(standardsObjectController);
        System.assertNotEquals(null,yodleeTransSearchExtObj.nspace);
        System.assertNotEquals(null, yodleeTransSearchExtObj.goback());
    	Test.stopTest();	
    }
    
    @isTest
    static void testcobrandAndUserlogin_registerAndFLcontroller(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('cobrandLogin')));
    
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.cobrandlogin();
    	System.assertNotEquals(null, jResult.records[0]);
    	Test.stopTest();	
    }
    
     @isTest
    static void testcoBrandUserNamePasswordNotExist_registerAndFLcontroller(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,false);
    	Service_Configuration__c serConfg = Service_Configuration__c.getValues('cobrandLogin');
    	serConfg.username__c = '';
    	serConfg.password__c = '';
    	DML.updateAsSystem(serConfg);
    	
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	boolean ErrorExists = false;
        for(ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains(Label.Yodlee_Setup_Message)){
        		ErrorExists = true;
        		break;
        	}
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }
    
     @isTest
    static void testcoBrandAndUserNotExist_registerAndFLcontroller(){
    	//create custom setting record 
    	createServiceConfiguraionData(false,false);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	boolean ErrorExists = false;
        for(ApexPages.Message msg :ApexPages.GetMessages())
        	if(msg.getDetail().contains(Label.Yodlee_Setup_Message)){
        		ErrorExists = true;
        		break;
        	}
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }
    
     @isTest
    static void testemptyServiceConfiguration_registerAndFLcontroller(){
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	boolean ErrorExists = false;
        for(ApexPages.Message msg :ApexPages.GetMessages()){
        	system.debug('---'+msg);
        	if(msg.getDetail().contains(Label.Yodlee_Setup_Message)){
        		ErrorExists = true;
        		break;
        	}
        }
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }
    
     @isTest
    static void testURLandAppId_registerAndFLcontroller(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	System.assertNotEquals(null,yodleeUserRegistrationExtObj.getAppId());
    	System.assertNotEquals(null,yodleeUserRegistrationExtObj.getURL());
    	System.assertNotEquals(null,yodleeUserRegistrationExtObj.getYodleeLinkedAccountFieldList());
        System.assertNotEquals(null,yodleeUserRegistrationExtObj.getLinkedAccountGridConfig());
        //KNDY-13289
        System.assertNotEquals(null,yodleeUserRegistrationExtObj.getSiteLinksToYodleeFieldList());
        System.assertNotEquals(null,yodleeUserRegistrationExtObj.getSiteLinksToYodleeGridConfig());
    	Test.stopTest();	
    }
    
     @isTest
    static void testgetSiteAccounts(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('SiteAccounts')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSiteAccounts('cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records,jResult);
    	system.debug('jResult.records=='+jResult.records);
    	Test.stopTest();	
    }
     @isTest
    static void testgetSiteAccountsError(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	StaticResourceCalloutMock singlemock = new StaticResourceCalloutMock();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('errorResponse')));
        
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSiteAccounts('cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records,jResult);
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Invalid token in authorization header')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}
        System.assertEquals(true, ErrorExists,jResult);
    	Test.stopTest();	
    }
    //KNDY-13289
     @isTest
    static void testgetRemoveSiteAccounts(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('removeSiteAccounts')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.removeSiteAccounts('cobrandSession','userSession','26439744');
    	System.assertEquals(null, jResult.records);
    	Test.stopTest();	
    }
    
    @isTest
    static void testgetRemoveSiteAccountsFailure(){   
    	//create custom setting record 
        createServiceConfiguraionData(true,true);    
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('errorResponse')));
        Test.startTest();
        JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.removeSiteAccounts('cobrandSession','userSession','26439744');
        System.assertEquals(false, jResult.Success,jResult);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jResult.messages)
            if(msg.containsKey('message')){
                if(msg.get('message').contains('Y008-Invalid token in authorization header')){
                    ErrorExists = true;
                    break;
                }
            }
        System.assertEquals(true, ErrorExists,jResult);
        system.debug('jResult.records=='+jResult.records);
        Test.stopTest();    
    }
    @isTest
    static void testgetSummaryForSiteAccounts(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('SummaryForSite')));
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSummaryForSite('26439744', 'siteAccountName', 'cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records);
    	Test.stopTest();	
    }
    
    @isTest
    static void testgetSummaryForSiteAccountsError(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('invalidToken')));
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSummaryForSite('26439744', 'siteAccountName', 'cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Y008-Invalid token in authorization header (b1489454706013O4T27h).')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}       
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }   
    @isTest
    static void testgetSummaryForSiteAccountsURLMissing(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
        Service_Configuration__c serConfg = Service_Configuration__c.getValues('GET_ACCOUNTS_URL');
    	delete serConfg;
        serConfg = Service_Configuration__c.getValues('HOST_URI');
    	delete serConfg;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('invalidToken')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSummaryForSite('26439744', 'siteAccountName', 'cobrandSession','userSession');
    	System.assertEquals(false, jResult.success,jResult);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jResult.messages){
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Yodlee_Setup_Message)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
    	}       
    	System.assertEquals(true, ErrorExists);
    	Test.stopTest();	
    }
    @isTest
    static void testgetToken(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('Token')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getToken('cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records);
    	Test.stopTest();	
    }
    
     @isTest
    static void testgetToken_invalid(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('invalidToken')));
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getToken('cobrandSession','userSession');
    	System.assertEquals(null, jResult.records);
    	//null session tokens
    	jResult = YodleeUserRegistrationAndAccountLinkExt.getToken(null,null);
    	System.assertEquals(null, jResult.records);
    	Test.stopTest();	
    }
    
     @isTest
    static void testgetToken_blankCobrandUserSession(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getToken('','');
    	System.assertEquals(null, jResult.records);
    	Test.stopTest();	
    }
    
     @isTest
    static void testgoBack_UserRegistrationAndAccountLinkExt(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
        System.assertNotEquals(null, yodleeUserRegistrationExtObj.goback);
    	Test.stopTest();	
    }
    
    @isTest
    static void testgetUnlinkedAccount_NoAccount(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('SummaryForSite')));
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSummaryForSite('26439744', 'siteAccountName', 'cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records);
    	
    	JsonResult jResult1 = YodleeUserRegistrationAndAccountLinkExt.getUnlinkedAccount((list<YodleeBankTransactionServices.SummaryForSite>)jResult.records);

        System.assertEquals(0, jResult1.records.size());
    	Test.stopTest();	
    }
    
     @isTest
    static void testgetUnlinkedAccount(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	bA.Yodlee_Account_Number__c = '';
    	DML.updateAsSystem(bA);
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('SummaryForSite')));
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSummaryForSite('26439744', 'siteAccountName', 'cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records);
    	
    	JsonResult jResult1 = YodleeUserRegistrationAndAccountLinkExt.getUnlinkedAccount((list<YodleeBankTransactionServices.SummaryForSite>)jResult.records);
    	System.assertNotEquals(null, jResult1.records);
    	Test.stopTest();	
    }
    
    @isTest
    static void testlinkBankAccountWithSite_and_getLinkedBankAccount(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	bA.Yodlee_Account_Number__c = '';
    	DML.updateAsSystem(bA);
    	list<Bank_Account__c> lstBA = new list<Bank_Account__c>();
    	lstBA.add(bA);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('SummaryForSite')));
    	Test.startTest();
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSummaryForSite('14782604', 'siteAccountName', 'cobrandSession','userSession');
    	System.assertNotEquals(null, jResult.records,jResult);
    	
    	JsonResult jResult1 = YodleeUserRegistrationAndAccountLinkExt.getUnlinkedAccount((list<YodleeBankTransactionServices.SummaryForSite>)jResult.records);
    	system.assertNotEquals(null, jResult1.records,jResult1);
    	
    	list<YodleeBankTransactionServices.SummaryForSite> lstSummaryForSite = (list<YodleeBankTransactionServices.SummaryForSite>)jResult1.records;
    	list<string> lstBankAccount = new list<string>();
    	list<string> lstSiteAccountId = new list<string>(); 
    	list<string> lstSiteAccountName = new list<string>();
		for(YodleeBankTransactionServices.SummaryForSite summaryforSite: lstSummaryForSite){
			lstBankAccount.add(summaryforSite.recordId);
			system.assertNotEquals(null, summaryforSite.lstAccountsForSite,summaryforSite); 
			lstSiteAccountId.add(summaryforSite.lstAccountsForSite[1].strSiteAccountId);
			lstSiteAccountName.add(summaryforSite.lstAccountsForSite[1].AccountName);
		}
		
		JsonResult jResult2 = YodleeUserRegistrationAndAccountLinkExt.linkBankAccountWithSite(lstBankAccount, lstSiteAccountId, lstSiteAccountName);
    	system.assertEquals(true, jResult2.success);
    	
    	JsonResult jResult3 = YodleeUserRegistrationAndAccountLinkExt.getLinkedBankAccount();
    	system.assertEquals(true, jResult3.success);
    	system.assertNotEquals(null, jResult3.records);
    	Test.stopTest();	
    }
    
     @isTest
    static void testDummyController(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(bA); 
    	YodleeBankTransactionDummyExt yodleeBankTransactionDummyExtObj = new YodleeBankTransactionDummyExt(sc);
    	Test.startTest();
    	System.assertNotEquals(null, yodleeBankTransactionDummyExtObj.nspace);
    	Test.stopTest();	
    }
    
    @isTest
    static void test_delinkBankAccount(){
    	SOQLUtil soql;
        soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name','Yodlee_Account_Linkage_Date__c','Yodlee_Account_Name__c',
        								'Yodlee_Account_Site_ID__c'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
    	Bank_Account__c bA = Database.Query(soql.getQuery());
    	bA.Yodlee_Account_Number__c = '123456';
    	bA.Yodlee_Account_Linkage_Date__c = Date.today();
    	bA.Yodlee_Account_Name__c = 'JPMC';
    	bA.Yodlee_Account_Site_ID__c = '654321';
    	DML.updateAsSystem(bA);
    	list<Bank_Account__c> lstBA  = new list<Bank_Account__c>{bA};
    	ApexPages.StandardSetController standardsObjectController = new ApexPages.StandardSetController(lstBA);
    	standardsObjectController.setSelected(lstBA);
    	YodleeUserRegistrationAndAccountLinkExt yodleeUserRegistrationExtObj = new YodleeUserRegistrationAndAccountLinkExt(standardsObjectController);
    	list<string> lstBAId = new list<string>{bA.Id};
    	Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.delinkBankAccount(lstBAId);
    	system.assertEquals(true, jResult.success);
    	
    	soql = new SOQLUtil('Bank_Account__c', TRUE);
        soql.addFields(new Set<String>{'Id','Yodlee_Account_Number__c', 'Name','Yodlee_Account_Linkage_Date__c','Yodlee_Account_Name__c',
        								'Yodlee_Account_Site_ID__c'});
        soql.setWhereClause('Name =\'Test BOFA\'');
		soql.setLimit(1);
        bA = Database.Query(soql.getQuery());
    	system.assertEquals(null, bA.Yodlee_Account_Number__c);
    	system.assertEquals(null, bA.Yodlee_Account_Linkage_Date__c);
    	system.assertEquals(null, bA.Yodlee_Account_Name__c);
    	system.assertEquals(null, bA.Yodlee_Account_Site_ID__c);
    	Test.stopTest();	
    }
     @isTest
    static void test_refreshSitesSuccess(){
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('refreshSitesResponse')));
        Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.refreshSiteAccounts('cobrandSession','userSession','26439744');
    	
        System.assertEquals(true, jResult.Success,jResult);
    	system.debug('jResult.records=='+jResult.records);
    	Test.stopTest();	
    }
    @isTest
    static void test_refreshSitesNoURL(){    	
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('refreshSitesResponse')));
        Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.refreshSiteAccounts('cobrandSession','userSession','26439744');
    	System.assertEquals(false, jResult.Success,jResult);
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains(Label.Yodlee_Setup_Message)){
	        		ErrorExists = true;
	        		break;
        		}
        	}
        System.assertEquals(true, ErrorExists,jResult);
    	system.debug('jResult.records=='+jResult.records);
    	Test.stopTest();	
    }
    @isTest
    static void test_refreshSitesError(){    	
    	//create custom setting record 
    	createServiceConfiguraionData(true,true);
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('errorResponse')));
        Test.startTest();
    	JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.refreshSiteAccounts('cobrandSession','userSession','26439744');
    	System.assertEquals(false, jResult.Success,jResult);
    	boolean ErrorExists = false;
    	for(Map<String, String> msg :jResult.messages)
        	if(msg.containsKey('message')){
        		if(msg.get('message').contains('Y008-Invalid token in authorization header')){
	        		ErrorExists = true;
	        		break;
        		}
        	}
        System.assertEquals(true, ErrorExists,jResult);
    	system.debug('jResult.records=='+jResult.records);
    	Test.stopTest();	
    }
     @isTest
    static void test_refreshSitesGridNoURL(){       
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('refreshSiteAccounts')));
        Test.startTest();
        JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSiteAccountsWithProviders('cobrandSession','userSession','15053696');
        System.assertEquals(false, jResult.Success,jResult);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jResult.messages)
            if(msg.containsKey('message')){
                if(msg.get('message').contains(Label.Yodlee_Setup_Message)){
                    ErrorExists = true;
                    break;
                }
            }
        System.assertEquals(true, ErrorExists,jResult);
        system.debug('jResult.records=='+jResult.records);
        Test.stopTest();    
    }
    @isTest
    static void test_refreshSitesGridSuccess(){   
    	//create custom setting record 
        createServiceConfiguraionData(true,true);    
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('refreshSiteAccounts')));
        Test.startTest();
        JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSiteAccountsWithProviders('cobrandSession','userSession','15053696');
        System.assertEquals(true, jResult.Success,jResult);        
        Test.stopTest();    
    }
    @isTest
    static void test_refreshSitesGridFailure(){   
    	//create custom setting record 
        createServiceConfiguraionData(true,true);    
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(requestResponseBodies.get('errorResponse')));
        Test.startTest();
        JsonResult jResult = YodleeUserRegistrationAndAccountLinkExt.getSiteAccountsWithProviders('cobrandSession','userSession','15053696');
        System.assertEquals(false, jResult.Success,jResult);
        boolean ErrorExists = false;
        for(Map<String, String> msg :jResult.messages)
            if(msg.containsKey('message')){
                if(msg.get('message').contains('Y008-Invalid token in authorization header')){
                    ErrorExists = true;
                    break;
                }
            }
        System.assertEquals(true, ErrorExists,jResult);
        system.debug('jResult.records=='+jResult.records);
        Test.stopTest();    
    }
     @testVisible
    private static map<string, string> requestResponseBodies = new map<string, string>{
    	'refreshSitesResponse' 	=> 	'{"providerAccount":[{"id":14847448,"providerId":16441,"lastUpdated":"2017-03-15T20:57:48Z","isManual":false,"createdDate":"2017-03-10","aggregationSource":"USER","refreshInfo":{"status":"NON_UPDATABLE","additionalInfo":"UPDATED_RECENTLY","message":"INVOKE_UPDATE_PROVIDER_ACCOUNT_WITH_CREDENTIALS_PARAM","lastRefreshStatusCode":0}}]}',
    	'errorResponse'			=> '{"errorCode":"Y008","errorMessage":"Invalid token in authorization header","referenceCode":"i1489621307345t4D26Q"}',
    	'cobrandLogin'			=> '{"cobrandId":10000004,"applicationId":"17CBE222A42161A3FF450E47CF4C1A00","session":{"cobSession":"06142010_1:43982e81341b415b3823a804b273e1715f50011bb8ff1722e21003d3a42773584a3563c07f69d57b5c379d82c919a2063b5f7af7c1c95a8fea66d660ee709f15"},"locale":"en_US"}',
    	'userLogin'				=> '{"user":{"id":10483860,"loginName":"sptest1","name":{"first":"FNAME","last":"LNAME"},"session":{"userSession":"06142010_1:b8d011fefbab8bf1753391b074ffedf9578612d676ed2b7f073b5785b5076ebd513fd2ea6f163bd1938dc92f8b9ae5d5539d70867ee2624711b5c372a7e031b7"},"preferences":{"currency":"USD","timeZone":"PST","dateFormat":"MM/dd/yyyy","locale":"en_US"}}}',
    	'searchTransaction'  	=> '{"transaction":[{"CONTAINER":"bank","id":469440664,"amount":{"amount":3465,"currency":"USD"},"baseType":"CREDIT","categoryType":"INCOME","categoryId":32,"category":"Other Income","categorySource":"SYSTEM","description":{"original":"DESC"},"type":"OTHER_DEPOSITS","subType":"CREDIT","isManual":false,"date":"2013-01-16","transactionDate":"2013-01-16","postDate":"2013-01-16","status":"POSTED","accountId":28862580,"runningBalance":{"amount":59,"currency":"USD"},"checkNumber":"DAG-133","highLevelCategoryId":10000012},{"CONTAINER":"bank","id":469440672,"amount":{"amount":3103,"currency":"USD"},"baseType":"DEBIT","categoryType":"EXPENSE","categoryId":19,"category":"Other Expenses","categorySource":"SYSTEM","description":{"original":"DESC"},"type":"OTHER_WITHDRAWALS","subType":"DEBIT","isManual":false,"date":"2013-01-14","transactionDate":"2013-01-12","postDate":"2013-01-14","status":"POSTED","accountId":28862580,"runningBalance":{"amount":59,"currency":"USD"},"checkNumber":"DAG-333","highLevelCategoryId":10000009},{"CONTAINER":"bank","id":469440668,"amount":{"amount":5646,"currency":"USD"},"baseType":"CREDIT","categoryType":"INCOME","categoryId":32,"category":"Other Income","categorySource":"SYSTEM","description":{"original":"DESC"},"type":"OTHER_DEPOSITS","subType":"CREDIT","isManual":false,"date":"2013-01-10","transactionDate":"2013-01-11","postDate":"2013-01-10","status":"POSTED","accountId":28862580,"runningBalance":{"amount":59,"currency":"USD"},"checkNumber":"DAG-233","highLevelCategoryId":10000012},{"CONTAINER":"bank","id":469440676,"amount":{"amount":9846,"currency":"USD"},"baseType":"CREDIT","categoryType":"INCOME","categoryId":32,"category":"Other Income","categorySource":"SYSTEM","description":{"original":"DESC"},"type":"OTHER_DEPOSITS","subType":"CREDIT","isManual":false,"date":"2013-01-02","transactionDate":"2013-01-16","postDate":"2013-01-02","status":"POSTED","accountId":28862580,"runningBalance":{"amount":59,"currency":"USD"},"checkNumber":"DAG-333","highLevelCategoryId":10000012}]}',
    	'registerUser'			=> '{"user":{"id":10499359,"loginName":"Arch1376475200981","session":{"userSession":"06142010_0:479415bf75ed206b94fe5430dcdc5ca639d95f40e99c3ff2102458b09966bace89cd5ce3272ae42aadf9727fe189223649d025f0d6441bffab5cb42c0005ecc8"},"name":{"first":"FNAME","last":"LNAME"},"preferences":{"currency":"USD","timeZone":"PST","dateFormat":"MM/dd/yyyy","locale":"en_US"}}}',
    	'removeSiteAccounts'	=> '{ }',
    	'invalidCobrandCredential' => '{"errorCode":"Y007","errorMessage":"Invalid cobrand credentials","referenceCode":"z1489175371322k4n26O"}',
    	'invalidUserCredential'	=> '{"errorCode":"Y801","errorMessage":"Invalid value for password","referenceCode":"z1489175371322k4n26O"}',
    	'SiteAccounts'			=> '{"providerAccount":[{"id":14847448,"providerId":16441,"lastUpdated":"2017-03-14T02:11:04Z","isManual":false,"createdDate":"2017-03-10","aggregationSource":"USER","refreshInfo":{"statusCode":0,"statusMessage":"OK","status":"SUCCESS","nextRefreshScheduled":"2017-03-15T03:57:18Z","lastRefreshed":"2017-03-14T02:11:04Z","lastRefreshAttempt":"2017-03-14T02:11:04Z"}}]}',
    	'SummaryForSite'		=> '{"account":[{"CONTAINER":"bank","providerAccountId":14782604,"accountName":"TESTDATA1","accountStatus":"ACTIVE","accountNumber":"xxxx3xxx","isAsset":true,"balance":{"amount":9044.78,"currency":"USD"},"id":28862580,"lastUpdated":"2017-03-06T01:32:26Z","includeInNetWorth":true,"providerId":"16441","providerName":"Dag Site","availableBalance":{"amount":65454.78,"currency":"USD"},"currentBalance":{"amount":9044.78,"currency":"USD"},"accountType":"SAVINGS","isManual":false,"createdDate":"2017-02-28T20:05:49Z","refreshinfo":{"statusCode":0,"statusMessage":"OK","lastRefreshed":"2017-03-06T01:32:25Z","lastRefreshAttempt":"2017-03-06T01:32:25Z","nextRefreshScheduled":"2017-03-07T04:03:05Z"},"holderProfile":[{"name":{"displayed":"accountHolder"}}]},{"CONTAINER":"bank","providerAccountId":14782604,"accountName":"TESTDATA","accountStatus":"ACTIVE","accountNumber":"xxxx3xxx","isAsset":true,"balance":{"amount":44.78,"currency":"USD"},"id":28862576,"lastUpdated":"2017-03-06T01:32:26Z","includeInNetWorth":true,"providerId":"16441","providerName":"Dag Site","availableBalance":{"amount":54.78,"currency":"USD"},"currentBalance":{"amount":44.78,"currency":"USD"},"accountType":"CHECKING","isManual":false,"createdDate":"2017-02-28T20:05:49Z","refreshinfo":{"statusCode":0,"statusMessage":"OK","lastRefreshed":"2017-03-06T01:32:25Z","lastRefreshAttempt":"2017-03-06T01:32:25Z","nextRefreshScheduled":"2017-03-07T04:03:05Z"},"holderProfile":[{"name":{"displayed":"accountHolder"}}]},{"CONTAINER":"loan","providerAccountId":14752308,"accountName":"Super CD Plus","accountStatus":"ACTIVE","url":"http://abc.com","accountNumber":"xxxx2334","isAsset":false,"balance":{"amount":2000,"currency":"USD"},"id":28790524,"lastUpdated":"2017-03-04T12:26:25Z","includeInNetWorth":true,"providerId":"16441","providerName":"Dag Site","accountType":"OTHER","amountDue":{"amount":14000,"currency":"USD"},"dueDate":"2012-01-25","minimumAmountDue":{"amount":200,"currency":"USD"},"availableCredit":{"amount":200,"currency":"USD"},"maturityDate":"2013-01-25","interestRate":7,"originalLoanAmount":{"amount":3000,"currency":"USD"},"isManual":false,"originationDate":"2013-01-22","createdDate":"2017-02-22T22:49:39Z","refreshinfo":{"statusCode":0,"statusMessage":"OK","lastRefreshed":"2017-03-04T12:26:25Z","lastRefreshAttempt":"2017-03-04T12:26:25Z","nextRefreshScheduled":"2017-03-07T05:57:36Z"},"holderProfile":[{"name":{"displayed":"Bill Gates"}}]}]}',
    	'Token'					=>	'{"user":{"accessTokens":[{"appId":"10003600","value":"b64e45f4804e6b3f3ca4350753306b7988f033f19498fe99ddda070e5f968c11"}]}}'	,
        'invalidToken'          => '{"errorCode":"Y008","errorMessage":"Invalid token in authorization header","referenceCode":"b1489454706013O4T27h"}' ,
        'refreshSiteAccounts'	=> '{"providerAccount":{"id":15053696,"providerId":16441,"lastUpdated":"2017-03-21T16:40:27Z","isManual":false,"createdDate":"2017-03-20","aggregationSource":"USER","refreshInfo":{"statusCode":0,"statusMessage":"OK","status":"SUCCESS","nextRefreshScheduled":"2017-03-29T00:30:29Z","lastRefreshed":"2017-03-21T16:40:47Z","lastRefreshAttempt":"2017-03-21T16:40:47Z"}}}',
        'transactionCount' => '{"transaction":{"TOTAL":{"count":4}}}'    
    };
    
    public static Integer transactionCount = 4;
}