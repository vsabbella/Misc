public with sharing class ContractLineNettingBatch implements Database.Batchable<sObject>, Process.Runnable2, Database.Stateful{
	public Id companyId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public string query;
    
    public ContractLineNettingBatch (Id comp){
        companyId = comp;
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
       //PTP-302 Netting should only run against Open, Closed or Expired PA Lines. Cancelled or Draft should never be picked up
    	query =  'Select Id, Name, Contract_End__c, Status__c From Contract_Line__c where (Status__c != \'Cancelled\' or Status__c != \'Draft\') and Company__c = :companyId'; 
    	return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contract_Line__c> scope){
    	Savepoint sp = Database.setSavepoint(); //KNDY-2336
    	
        try{
        	ContractLineService.recalculateNettingBuckets(scope);
        	ContractLineService.updateExpiredStatus(scope);
        }catch(Exception e) {
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(scope, e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public void finish(Database.BatchableContext info){
    	BatchToChatter.processBatchInformation(info.getJobId(), this, messages);

    	//KNDY-7362, any messages are failure messages.  pass in count of failures		
		Notify.sendEmailBatchFinish(messages.size(), null, messages, info);        

		MasterControlProgram.finishedBatch( this );
    }
 
 	/* implementation of Runnable 
 	 */
 	public ContractLineNettingBatch() {}
	public void runBatch( Process_Job__c job ) { 		// Process.Runnable implementation 
    	ContractLineNettingBatch batch = new ContractLineNettingBatch(job.Company__c);
    	integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 200 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
		system.debug(job);
		SYStem.debug(defaultbatchsize);
        Database.executebatch(batch, defaultBatchSize);
	}  
}