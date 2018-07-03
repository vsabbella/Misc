public  class CustomerInvoiceVoidCancelBatch  implements 
Database.batchable<sObject>, 
Process.Runnable2,
Database.Stateful {
    public string BatchidtoCancel;   
    public string actionType ;
    public Set<id> FailedBatchIdSet;
    public String voidDate;
  
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    public  CustomerInvoiceVoidCancelBatch(String action, String batchId, String voidDateStr){
        BatchidtoCancel=batchId;
        actionType = action;
        voidDate = voidDateStr;
        FailedBatchIdSet= new Set<id>();
       
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){   
        String  query =  'select id, Name, Company__c, Finalized__c,Void__c, Void_Date__c, Status__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c  from customer_invoice__c where batch_job_id__c = :BatchidtoCancel and Status__c not in (\'Closed\', \'Cancelled\',\'Void\') order by name desc';
        return Database.getQueryLocator(query);
    } 
    
    public void execute(Database.BatchableContext info, List<Customer_invoice__C> scope){
        CustomerInvoiceVoidCancelService c=   new  CustomerInvoiceVoidCancelService(scope);
        Map<Id, VoidCancelService.VoidCancelDetail> vcd= c.getBusinessVoidCancelDetails(scope); 
        Map<Id, VoidCancelService.VoidCancelResponse> VoidCancelResponses = new Map<Id, VoidCancelService.VoidCancelResponse>() ;
        
        System.debug(logginglevel.error,'voidDate--->'+voidDate);
        Datetime dateTimeInFormat = null;
        if(!test.isRunningTest()){
	        dateTimeInFormat = (datetime)JSON.deserialize(voidDate, Datetime.class);
	        System.debug(logginglevel.error,'dateTimeInFormat--->'+dateTimeInFormat);
        }else{
            dateTimeInFormat = DateTime.valueof(voidDate);
        }
         
        List<Customer_invoice__C> validatedScope = new list<Customer_invoice__C>();
        set<Id> invalidCIIds = new set<Id>();
        
        for(Customer_invoice__c cis:scope){
            if(vcd.get(cis.id).cancelMessages.size()==0 && actionType.equalsIgnoreCase('cancel')){
                validatedScope.add(cis);
            }else if( vcd.get(cis.id).voidMessages.size()==0  && actionType.equalsIgnoreCase('void')){
                cis.void_date__c = dateTimeInFormat;
                 System.debug(logginglevel.error,'cis.void_date__c--->'+cis.void_date__c);
                 System.debug(logginglevel.error,'cis.Transaction_Date__c--->'+cis.Transaction_Date__c);
                if(cis.void_date__c < cis.Transaction_Date__c){
                   invalidCIIds.add(cis.Id);  // gather all the CI not eligible to be voided
                }else{
                validatedScope.add(cis);
            }
        }
        }
        System.debug(logginglevel.error, 'invalidCIIds-->'+invalidCIIds);
        System.debug(logginglevel.error, 'validatedScope-->'+validatedScope);
        
        
        if(actionType.equalsIgnoreCase('cancel') && validatedScope.size()>0){
            VoidCancelResponses = c.CancelSourceDocuments (validatedScope);
        }else if(actionType.equalsIgnoreCase('void')&& validatedScope.size()>0){
            VoidCancelResponses = c.VoidSourceDocuments (validatedScope);
        }
        
        for(Customer_invoice__C ciscope: scope){
            boolean firstTime=true;
            List<String> messagesforCI=new List<String>();
            if(actionType.equalsIgnoreCase('cancel') && vcd.containsKey(ciscope.id)){
                messagesforCI= vcd.get(ciscope.id).cancelMessages; 
            }else if(actionType.equalsIgnoreCase('void')&& vcd.containsKey(ciscope.id) ){
                messagesforCI=  vcd.get(ciscope.id).voidMessages ;
            }
            if(VoidCancelResponses.containsKey(ciscope.id)){
                messagesforCI.addAll(VoidCancelResponses.get(ciscope.id).messages);
            }
            boolean isSuccess=false;
                for(String m :   messagesforCI   ){
                    if(m.contains('Success')){
                        isSuccess=true;
                    }
                }
            if(!isSuccess) {
               FailedBatchIdSet.add(info.getjobid());
            
        
            for(String m :   messagesforCI   ){
                    if(firstTime){
                        firstTime=false;
                        messages.add(new Notify.Message( 'Cannot not '+ actionType  + ' Customer Invoice:  (' +ciscope.Name + ') ' +URL.getSalesforceBaseUrl().toExternalForm()  +'/'+ciscope.Id , ' Please click on the given link to visit the detail page and try '+actiontype + ' using the button on page.'));
                    }
                    messages.add(new Notify.Message( '',m));
            }
	            
	        for(Id ciId : invalidCIIds){
	                System.debug(logginglevel.error,'ciId--->'+ciId);
                    String errorMsg = 'Void date cannot be before Transaction Date';
                    if(firstTime){
                        firstTime=false;
                        messages.add(new Notify.Message( 'Cannot not '+ actionType  + ' Customer Invoice:  (' +ciscope.Name + ') ' +URL.getSalesforceBaseUrl().toExternalForm()  +'/'+ciscope.Id , ' Please click on the given link to visit the detail page and try '+actiontype + ' using the button on page.')); 
                    }
                    messages.add(new Notify.Message('',errorMsg));
            }
          }
        }
    }
    
    public void finish(Database.BatchableContext info){
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( FailedBatchIdSet.size(),actionType +' Request for Batch: '+BatchidtoCancel , messages, info);        
        MasterControlProgram.finishedBatch( this ); 
    }
    
    /* runnable interface */
    public CustomerInvoiceVoidCancelBatch() {}  // newInstance(); needs a no-arg consturctor  
    public void runBatch( Process_Job__c job) {
        CustomerInvoiceVoidCancelBatch Obj=new CustomerInvoiceVoidCancelBatch(actionType,BatchidtoCancel,voidDate);
        integer defaultBatchSize = 1;
        if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) < 10 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
            defaultBatchSize = integer.valueOf(job.Batch_Size__c);
        }
        Id jobId=Database.executebatch(obj, defaultBatchSize);
    }    
}