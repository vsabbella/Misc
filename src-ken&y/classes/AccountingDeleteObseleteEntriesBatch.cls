public without sharing class AccountingDeleteObseleteEntriesBatch implements Database.batchable<sObject>, Process.Runnable2{
    public DateTime dateToDelete;
    private set<Id> deleteAEIds;
    private Id batchJobId;
    public Integer BatchErrorCount=0;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public map<string,set<id>> mErrMsgToRecId = new map<string,set<id>>();  
  
    public String query = 'SELECT Id, Status__c, Period__r.Delete_ObsoleteAEs__c  FROM Accounting_Entry__c' 
                        + ' WHERE Status__c = \'Obsolete\' AND Period__r.Delete_ObsoleteAEs__c = TRUE ';    

    /* runnable interface */
    
    public  void runBatch( Process_Job__c job ) {       // Process.Runnable2 implementation 
        
        system.debug('job: ' + job);
        AccountingDeleteObseleteEntriesBatch batch = new AccountingDeleteObseleteEntriesBatch(new Set<ID>{job.Company__c});
        
        integer defaultBatchSize = 1;
        if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 10 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
            defaultBatchSize = integer.valueOf(job.Batch_Size__c);
        }
        
        Id jobId=Database.executebatch(batch,defaultBatchSize);
     
    }     

    public AccountingDeleteObseleteEntriesBatch(set<Id> deleteAEIds){
        this.deleteAEIds = deleteAEIds;
    }

    public AccountingDeleteObseleteEntriesBatch() {} 
    



    public Database.QueryLocator start (Database.BatchableContext BC){
        //MasterControlProgram.checkAlreadyRunning( this, BC );
   
        return Database.getQueryLocator(query);


    
    }
    
    public void execute(Database.BatchableContext BC, list<Accounting_Entry__c> scope){
        list<Accounting_Entry__c> aeDeleteList =  new list<Accounting_Entry__c>();    
        list<Database.DeleteResult> deletedAEs = new list<Database.DeleteResult>(); 
            for(Accounting_Entry__c aeInContext : scope){
                aeDeleteList.add(aeInContext);
            }

           


        if(aeDeleteList.size() > 0){
			deletedAEs = DML.deleteAsSystem(aeDeleteList, false);
        }

    }

    

 

    public void finish(Database.BatchableContext BC){
         for(string s:mErrMsgToRecId.keyset()) {
          string errRecs = string.join(new list<id>(mErrMsgToRecId.get(s)), ',');
          messages.add(new Notify.Message('The  records '+ errRecs,'  have following errors '+s));
            
        }
        system.debug('messages'+messages);
        BatchToChatter.processBatchInformation(BC.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( BatchErrorCount,null, messages, BC);        
        MasterControlProgram.finishedBatch( this ); 
    
    }

     
    





}