public with sharing class CustomerInvoicePreFinalizeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,
															Database.Stateful {
	
	private String batchJobId;
	private String likeText;
    private List<Notify.Message> messages = new List<Notify.Message>();
    private Type executeClass = null;
    private final String EXECUTE_NAME = null;
    private String query = 'Select Id from Customer_Invoice__c '+
					   ' where Finalized__c = false ' +
					   ' and Source_Key__c LIKE :likeText';

	private Integer currentSequence;

	
	public CustomerInvoicePreFinalizeBatch(String batchId, Type runClass, Integer sequence) {
		this.batchJobId = batchId;
		this.likeText = '%'+batchJobId+'%';

		currentSequence = sequence;
		executeClass = runClass;
	}
	
	public Database.QueryLocator start(Database.BatchableContext info) {

		if(executeClass == null){
			likeText = info.getJobId();
		}
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext info, List<Customer_Invoice__c> scope) {
   		if(executeClass != null){
   			ICustomAction e = (ICustomAction)executeClass.newInstance();
   			List<Notify.Message> m = (List<Notify.Message>)e.executeAction(scope);

   			if(m != null && m.size() > 0){
   				messages.addAll(m);
   			}
   		}
	}
	
	public void finish(Database.BatchableContext info) {
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		

		BatchInjector bi = null;
		if(executeClass != null){
			bi = BatchInjector.getNextBatch(Schema.Customer_Invoice__c.getSObjectType().getDescribe().getName(), currentSequence);
		}

		Id batchId;
		if(bi != null && bi.executer != null){
			//run next batch
        	batchId = Database.executeBatch(new CustomerInvoicePreFinalizeBatch(batchJobId, bi.executer, bi.sequence), bi.scope);
		}else{
			//NOW finalize these invoices, and update the Next Billing Date for the Agreement Lines. 
			MasterControlProgram.finishedBatch( this );
			batchId = Database.executeBatch(new FinalizeCustomerInvoiceBatch(batchJobId),200);
		}
		
	}

}