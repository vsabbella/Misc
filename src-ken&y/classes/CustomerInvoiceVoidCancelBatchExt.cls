public with sharing class CustomerInvoiceVoidCancelBatchExt {
 /* public  String BatchID{get;set;}
  public String actionType{get;set;}
  public  CustomerInvoiceVoidCancelBatchExt(){
        
    }*/
   
    public Apexpages.StandardSetController con {get;set;}
   
   public  CustomerInvoiceVoidCancelBatchExt(ApexPAges.StandardSetController  scon){
       this.con = scon;
       Customer_Invoice__c ci = (Customer_Invoice__c)con.getRecord(); //Calling from UI
       ci.Void_Date__c = System.now();
       System.debug(logginglevel.error,ci.Void_Date__c);
    }
      

    @remoteAction
   public static JSONResult cancel1(String batchid, String voidDate){
         JSONResult js= new JSONResult();
       pattern IDPattern = pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}');
           matcher IDValidatorMatcher = IDPattern.matcher(batchid);
           if(!IDValidatorMatcher.matches()){
               Js.addmessage('Invalid Batch.',ApexPages.severity.Error);
               Js.success = false;
               return js;
            }
        database.executeBatch(new CustomerInvoiceVoidCancelBatch('Cancel',batchid,voidDate),10);
        Js.success = true;
        Js.addMessage('Your Cancel request for batch '+batchid+' has been successfully submitted. You will receive an email when the batch has completed processing.', ApexPages.Severity.CONFIRM);
   	   return js;   
    }
     @remoteAction
    public static JSONResult void(String batchid, String voidDate){
         JSONResult js= new JSONResult();
           pattern IDPattern = pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}');
           matcher IDValidatorMatcher = IDPattern.matcher(batchid);
           if(!IDValidatorMatcher.matches()){
               Js.addmessage('Invalid Batch.',ApexPages.severity.Error);
               Js.success = false;
               return js;
            }
      
	    System.debug(logginglevel.error,'before the batch execution void date--->'+voidDate); 
        database.executeBatch(new CustomerInvoiceVoidCancelBatch('void',batchid,voidDate ),1);
        Js.success = true;
        Js.addMessage('Your void request for batch '+batchid + ' has been successfully submitted. You will receive an email when the batch has completed processing.', ApexPages.Severity.CONFIRM);
   	    return js;   
    } 
}