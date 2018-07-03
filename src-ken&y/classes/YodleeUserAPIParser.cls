public class YodleeUserAPIParser {
    public UserWrapper user;
    //Cobrand Response
    public string cobrandId;
    public string applicationId;
    public sessionWrapper session;
    //end Cobrand response
    public string locale;
    public string errorCode;
    public string errorMessage;
    public string referenceCode;
    public class UserWrapper {
        public String loginName;    //yslRest21
        public String password; //TEST@123
        public String email;    //yslRest19@yodlee.com
        public NameWrapper name; 
        public AddressWrapper address; 
        public PreferencesWrapper preferences; 
        public sessionWrapper session;
        public List<accessTokensWrapper> accessTokens;
    }
    public class NameWrapper {
        public String first;    //FNAME
        public String last; //LNAME
    }
    public class AddressWrapper {
        public String address1; //200 Lincoln Ave
        public String state;    //CA
        public String city; //Salinas
        public String zip;  //93901
        public String country;  //US
    }
    public class PreferencesWrapper {
        public String currencyCode; //USD
        public String timeZone; //PST
        public String dateFormat;   //MM/dd/yyyy
        public String locale;   //en_US
    }
    public class sessionWrapper {
        public String userSession;
        public String cobSession;
    }    
    public class accessTokensWrapper{
        public string appid;
        public string valueField;
    }
}