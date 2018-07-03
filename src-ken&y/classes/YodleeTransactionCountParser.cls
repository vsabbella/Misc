public with sharing class YodleeTransactionCountParser {
    
    public TransactionWrapper transactionWrapper;
    
    //end Cobrand response
    public string locale;
    public string errorCode;
    public string errorMessage;
    public string referenceCode;
    
    
    public class TransactionWrapper {
        public TotalWrapper total;
    } 
    
    public class TotalWrapper{
        public String countValue;
    }
    
}