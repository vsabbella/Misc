public class YodleeSiteAccountParser {
	//KNDY-15850 - new API
	public List<ProviderAccountsWrapper> providerAccount;
	public List<ProvidersWrapper> provider;
	public string errorCode;
    public string errorMessage;
    public string referenceCode;
	public class 	ProviderAccountsWrapper{
		public long id;
		public long providerId;
		public string lastUpdated;
		public boolean isManual;
		public string createdDate;
		public string aggregationSource;
		public RefreshInfoWrapper refreshInfo;
	}
	
	public class RefreshInfoWrapper{
		public integer statusCode;
		public  string statusMessage;
		public string status;
		public string additionalStatus;
		public string additionalInfo;
		public string nextRefreshScheduled;
		public string lastRefreshed;
		public string lastRefreshAttempt;
		public string message;
		
	}
	public class ProvidersWrapper{
		public long id;
		public string name;
		public string loginUrl;
		public string baseUrl;
		public string favicon;
		public string logo;
		public string status;
		public boolean isAutoRefreshEnabled;
		public containerAttributesWrapper containerAttributes;
		public string oAuthSite;
		public string lastModified;
		public string forgetPasswordUrl;
		public string languageISOCode;
		public string primaryLanguageISOCode;
		public list<string> containerNames;	
		public loginFormWrapper loginForm;	
		public list<additionalDataSetWrapper> additionalDataSet;
		public list<capabilityWrapper> capability;
		public string authType;
	}
	
	public class containerAttributesWrapper{
		public containerSubAttributesWrapper BILL;
		public containerSubAttributesWrapper INSURANCE;
		public containerSubAttributesWrapper LOAN;
		public containerSubAttributesWrapper CREDITCARD;
		public containerSubAttributesWrapper BANK;
		public containerSubAttributesWrapper INVESTMENT;
		public containerSubAttributesWrapper REWARD;
	}
	public class containerSubAttributesWrapper{
		public integer numberOfTransactionDays;
	}
	public class loginFormWrapper{
		public string id;
		public string forgetPasswordURL;
		public string formType;
		public list<rowWrapper> row;
	}
	public class rowWrapper{
		public string id;
		public string label;
		public string form;
		public string fieldRowChoice;
		public list<fieldWrapper> field;
	}
	public class fieldWrapper{
		public string id;
		public string name;
		public string type;
		public string valueField;
		public boolean isOptional;
		public boolean valueEditable;
	}
	public class additionalDataSetWrapper{
		public string name;
		public list<attributeWrapper> attribute;
		
	}
	public class attributeWrapper{
		public string name;
		public list<string> container;
	}
	public class capabilityWrapper{
		public string name;
		public list<string> container;	
	}
	//end KNDY-15850 
            
   public  YodleeSiteAccountParser(){
        
    }
   public class YodleeProviderAccountParser {
	//KNDY-15857 - new API
	public YodleeSiteAccountParser.ProviderAccountsWrapper providerAccount;
	public string errorCode;
    public string errorMessage;
    public string referenceCode;
    
    }
    
}