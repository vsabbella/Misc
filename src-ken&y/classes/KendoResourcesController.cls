global with sharing class KendoResourcesController {
	global String timeZoneKey { get; set; }	
	global String localeKey { get; set; }
	global String languageLocaleKey { get; set; }
	global String namespacePrefix { get { return KSE.NamespaceUU; }} 
	global Integer defaultRemotingTimeout { get; set; }
	global String defaultKendoUIVersion { get; set; }

	global KendoResourcesController() {
		TimeZone tz = UserInfo.getTimeZone();
		
		// TimeZoneSidKey required for MomentJS to parse the date/datetime to user's locale
		timeZoneKey = tz.getID();
		
		// Kendo specific UI locale/language keys
        localeKey = UserInfo.getLocale().replace('_', '-');
        languageLocaleKey = UserInfo.getLanguage().replace('_', '-');
        
        // Set default visualforce remoting timeout in milliseconds
        defaultRemotingTimeout = 30000;

       
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('JavaScript_Remoting_Defaults__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Value__c','Name'
        });
        soql.setWhereClause('Name = \'Timeout\'');
        soql.setLimit(1);
        List<JavaScript_Remoting_Defaults__c> remotingDefaultList = Database.query(soql.getQuery());

        
        if (remotingDefaultList.size() > 0) {
	        JavaScript_Remoting_Defaults__c remotingDefaults = remotingDefaultList[0];

	        if (remotingDefaults != null) {
	        	try {
	        		defaultRemotingTimeout =  Integer.valueof(remotingDefaults.Value__c) * 1000; // Convert seconds into milliseconds
	        	}
	        	catch (Exception e) {
				  // ignore to set the default
				}
	        }
        }
    }
    
    global String getKendoUIVersion() {
		Set<String> supportedKendoUIVersions = new Set<String> { '2013.3.1119', '2015.2.902' ,'2016.1.412'};
		
		// Set default KendoUI version
        String kendoUIVersion = '2015.2.902';
        
        if (String.isNotBlank(defaultKendoUIVersion)) {
        	if (supportedKendoUIVersions.contains(defaultKendoUIVersion)) {
        		kendoUIVersion = defaultKendoUIVersion;
        	}
        }
        else {
	      
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Configuration__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Value__c','Name'
            });
            soql.setWhereClause('Name = \'KendoUIVersion\'');
            soql.setLimit(1);
            List<Configuration__c> appConfig = Database.query(soql.getQuery());
	        
	        if (appConfig.size() > 0) {
	        	Configuration__c configDefauts = appConfig[0];
	
		        if (configDefauts != null) {
		        	try {
		        		if (supportedKendoUIVersions.contains(configDefauts.Value__c)) {
		        			kendoUIVersion = configDefauts.Value__c;
		        		}
		        	}
		        	catch (Exception e) {
					  // ignore to set the default
					}
		        }
	        }
        }
        
        return kendoUIVersion;
    }
}