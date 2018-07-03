public with sharing class ApplyPrepaymentsBatch implements Database.batchable<sObject>, Database.Stateful{
	
	public String batchJobId;
	public String likeText;
	public List<Notify.Message> messages = new List<Notify.Message>();
	public ApplyPrepaymentsBatch(String batchJobId) {
		this.batchJobId = batchJobId;
		this.likeText = '%'+batchJobId+'%';
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC){
		
		String query = 'Select Id, Name, Balance__c, Company__c, Currency__c, Bill_To_Customer__c from Customer_Invoice__c where Source_Key__c LIKE :likeText and Finalized__c = true order by Planned_Invoice_Date__c ASC';
		return Database.getQueryLocator(query);
	}
	
	public void execute(Database.BatchableContext info, List<Customer_Invoice__c> scope) {
		Savepoint sp = Database.setSavepoint();
		try {
			AutoApplyInvoiceService.autoApplyPrepayments(new map<Id, Customer_Invoice__c>(scope));
		}catch(Exception ex) {
			system.debug(logginglevel.info,'error on batch '+ex);
			Database.rollback(sp);
			messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ex.getStackTraceString()));
		}
		
	}
	
	public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
	    Notify.sendEmailBatchFinish(messages.size(), null, messages, info);     
	    MasterControlProgram.finishedBatch( this );    
	}

}