public with sharing class FinalizeCustomerInvoiceBatch implements Database.batchable<sObject>, Database.Stateful{

	
	public List<Notify.Message> messages = new List<Notify.Message>();
	public String batchJobId;
	public String likeText;
	public FinalizeCustomerInvoiceBatch(String batchJobId) {
		this.batchJobId = batchJobId;
		this.likeText = '%'+batchJobId+'%';
	}
	public Database.QueryLocator start(Database.BatchableContext BC){
		String query = 'Select Id, Name, Matches_To_Grouping_Rule__c, Source_Key__c from Customer_Invoice__c '+
					   ' where Finalized__c = false ' +
					   ' and Source_Key__c LIKE :likeText';
		
		return Database.getQueryLocator(query);
	}
	
	public void execute(Database.BatchableContext info, List<Customer_Invoice__c> scope) {
		
		//map<Id, Customer_Invoice__c> mCIs = new map<Id,Customer_Invoice__c>();
		for(Customer_Invoice__c ci : scope) {
			ci.Finalized__c = true;
		}
		
		
		Savepoint sp = Database.setSavepoint();
		try {
			DML.updateAsSystem(scope, false);//KNDY-15144
		}catch(Exception ex) {
			Database.rollback(sp);
    		messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ex.getStackTraceString()));
		}	
		
		
	}
	
	public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
	    Notify.sendEmailBatchFinish(messages.size(), null, messages, info);     
	    
	    //NOW finalize these invoices, and update the Next Billing Date for the Agreement Lines. 
		Id batchId = Database.executeBatch(new ApplyPrepaymentsBatch(batchJobId),50);
	}
	


}