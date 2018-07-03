public with sharing class CustomerOutstandingBalanceBatch implements Database.batchable<sObject>,Database.Stateful, Process.Runnable2{
	SchemaUtil util = new Schemautil();
    public string query = 'Select Id,Name from Customer__c where RecordType.DeveloperName = \'Sold_To\'';
    public Id companyId;
	public List<Notify.Message> messages = new List<Notify.Message>();
	public BatchInjector nextBatch = null;
	
	private Integer currentSequence =0;
	private Type executeClass = null;
	private integer scopeCount = 1;
	
	//STATEFUL VARIABLE
	map<Id,CustomerService.RunningAverage> runningAverages = new map<Id, CustomerService.RunningAverage>();
	set<Id> manualCICustomers = new set<Id>(); 
	set<Id> manualCICorpCustomers = new set<Id>(); //KNDY-15808
	public CustomerOutstandingBalanceBatch(Type runClass, Integer sequence) {
		currentSequence = sequence;
		executeClass = runClass;
	}
	
	public CustomerOutstandingBalanceBatch() {}
	
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		CustomerOutstandingBalanceBatch obj=new CustomerOutstandingBalanceBatch();
		integer defaultBatchSize = 1;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 10 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){         
        return Database.getQueryLocator(query);
    }
    
     public void execute(Database.BatchableContext info, List<Customer__c> scope){
     	
     	
     	
     	//set static variables
     	Process.info = info;
     	CustomerService.runningAverages = runningAverages;
     	CustomerService.manualCICustomers = manualCICustomers;
     	CustomerService.manualCICorpCustomers = manualCICorpCustomers;//KNDY-15808
     	system.debug(' runningAverages '+runningAverages);
     	system.debug('manualCICustomers '+manualCICustomers);
     	system.debug('manualCICorpCustomers '+manualCICorpCustomers);
     	system.debug('scopeCount '+scopeCount);
     	scopeCount++;
     	if(executeClass == null) {
     		BatchInjector nextBatch = null;
        	if(nextBatch == null){
        		nextBatch = BatchInjector.getNextBatch(Schema.Customer__c.getSObjectType().getDescribe().getName(), 0);
	        }
	        if(nextBatch != null && nextBatch.executer != null){
	        	system.debug('nextBatch '+nextBatch);
	        	executeClass = nextBatch.executer;
	        	currentSequence = nextbatch.sequence;
	        }
        }
        
        if(executeClass != null) {
        	Savepoint sp = Database.setSavepoint();
        	try {
        		ICustomAction e = (ICustomAction)executeClass.newInstance();
   				e.executeAction(scope);
   				
   				 runningAverages = CustomerService.runningAverages;
     			 manualCICustomers = CustomerService.manualCICustomers;
     			 manualCICorpCustomers = CustomerService.manualCICorpCustomers;//KNDY-15808
     			 system.debug(' runningAverages '+runningAverages);
     			 system.debug('manualCICustomers '+manualCICustomers);
     			 system.debug('manualCICorpCustomers '+manualCICorpCustomers);
        	}catch(Exception ex) {
        		 system.debug(logginglevel.error, 'invoice batch exception '+ ex.getMessage() + ' ' +  ex.getStackTraceString());
			   	  Database.rollback(sp);
		    	  messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ex.getStackTraceString()));
        	}
        }else
        	system.abortJob(info.getJobID());
        	
     }
     
     public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		if(messages.size()>0){
			Notify.sendEmailBatchFinish(messages.size(),null,messages,info); 
		}else{
			Notify.sendEmailBatchFinish(null,messages,info);
		}   
		MasterControlProgram.finishedBatch( this ); 
		
		 BatchInjector nextBatch = null;
        
        if(nextBatch == null){
        	nextBatch = BatchInjector.getNextBatch(Schema.Customer__c.getSObjectType().getDescribe().getName(), currentSequence);
        }

        Id batchId;
        if(nextBatch != null && nextBatch.executer != null){
        	//run next batch
        	system.debug('nextBatch '+nextBatch);
        	batchId = Database.executeBatch(new CustomerOutstandingBalanceBatch(nextBatch.executer, nextBatch.sequence), nextBatch.scope);
        }else{
        	//call finish
        	MasterControlProgram.finishedBatch( this ); 
        	
        }
    }
}