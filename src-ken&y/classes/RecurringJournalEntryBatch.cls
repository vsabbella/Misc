public with sharing class RecurringJournalEntryBatch implements Database.Batchable<sObject>, Database.Stateful, Process.Runnable2, Schedulable{
    
    public string query;    
    public Id companyId;
    public set<Id> CompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    private List<Recurring_Template__c> recurringTemplates;
    private boolean sawException = false;
    RecurringJournalEntryService RJES = new RecurringJournalEntryService();
    @TestVisible
    Datetime currDate;
    
	public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		RecurringJournalEntryBatch obj=new RecurringJournalEntryBatch(new set<id>{ job.Company__c} );
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }
    public RecurringJournalEntryBatch() {}

    //public RecurringJournalEntryBatch(Id companyId){
    //    this.companyId = companyId;
    //}
    
    public RecurringJournalEntryBatch(set<Id> companyIds){
        this.CompanyIds = companyIds;
    }
    
    public void execute(SchedulableContext context){
        Database.executeBatch(new RecurringJournalEntryBatch());
    }
    // create a scope with all active RTs
    public Database.QueryLocator start(Database.BatchableContext BC){
   
        query = ' SELECT Id, name, Company__c '
                +' FROM Recurring_Template__c ' 
                +' WHERE status__c = \'Active\' AND Company__c in :CompanyIds ';
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        system.debug(logginglevel.info,'scope: ' + scope);
        if(currDate == null){
            currDate = system.now();
        }
  		Savepoint sp = Database.setSavepoint();
    	try{
        	// call the generate incremental JEs by passing the scope
        	RJES.createIncrementalJEs(scope, currDate);
    	}catch(Exception ex){
        	sawException = true;
        	Database.rollback(sp);
        	messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ex.getStackTraceString()));
    	}
        
    }
    
    public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
    }
}