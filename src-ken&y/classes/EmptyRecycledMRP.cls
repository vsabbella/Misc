public with sharing class EmptyRecycledMRP implements Database.batchable<sObject>,Database.Stateful, Process.Runnable2 {
    
    public ID CompanyID;
    public string query;
    public String errMsg;
    
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
    
        EmptyRecycledMRP obj = new EmptyRecycledMRP();
        
        integer defaultBatchSize = 200;
        if ( job.Batch_Size__c != null && integer.valueOf(job.Batch_Size__c) <= 2000 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
            defaultBatchSize = integer.valueOf(job.Batch_Size__c);
        }
        
        Database.executebatch(obj, defaultBatchSize);
    }
    
    public EmptyRecycledMRP() {
        
        query ='select ID '+
               'from MRP__c '+
               'where IsDeleted = true All Rows';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<MRP__c> tempList){
        
        execute( tempList );
    }
   
    public void execute( List<MRP__c> tempList) {
        
        errMsg = null;
      
        try {
            Database.emptyRecycleBin(tempList);
        }
        catch (Exception e) {
            errMsg = errMsg +e.getMessage()+','+e.getStackTraceString();
            throw e;
        }
    }
    
    public void finish(Database.BatchableContext info) {
        
        String msg;
        
        if (errMsg != null) {
            msg = 'EmptyRecycledMRP for run Failed with error: ' +errMsg;
            Notify.sendEmailBatchFinish( null, msg, info);        
        }
        else {
            msg = 'EmptyRecycledMRP Completed';
            Notify.sendEmailBatchFinish( null, msg, info);        
        }
    }
}