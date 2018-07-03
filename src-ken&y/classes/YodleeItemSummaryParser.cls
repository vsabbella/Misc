public class YodleeItemSummaryParser {
	public List<Accounts> account;
    public string errorCode;
    public string errorMessage;
    public string referenceCode;
    public class Accounts {
    	public string CONTAINER;
    	public long providerAccountId;
    	public boolean isManual;
    	public String accountName;
    	public string accountStatus;
    	public string url;
    	public String accountNumber;
    	public boolean isAsset;
    	public AvailableBalance balance;
    	public string id;
    	public string lastUpdated;
    	public boolean includeInNetworth;
    	public string providerId;
    	public string providerName;
    	public string accountType;
    	public AvailableBalance availableCash;
    	public AvailableBalance availableCredit;
    	public AvailableBalance totalCashLimit;
    	public AvailableBalance totalCreditLine;
    	public string  createdDate;
    	public YodleeSiteAccountParser.RefreshInfoWrapper refreshInfo;
     }
    
    public class AvailableBalance {
        public Double amount;
        public String currencyCode;
    
    
            }
    
    
}