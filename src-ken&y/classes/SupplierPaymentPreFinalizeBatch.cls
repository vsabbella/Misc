public with sharing class SupplierPaymentPreFinalizeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	
	private String batchJobId;
	private String likeText;
    private List<Notify.Message> messages = new List<Notify.Message>();
    private Type executeClass = null;
    private final String EXECUTE_NAME = null;
    private boolean totalCreditsExceedsDebits = false;
    private String query = 'Select Id from Supplier_Payment__c '+
					   ' where Finalized__c = false ' +
					   ' and Batch_Job_Id__C = :batchJobId and Source_Key__c LIKE :likeText';

	private Integer currentSequence;
	
	public SupplierPaymentPreFinalizeBatch(String batchId,boolean totalCreditsExceedsDebits, Type runClass, Integer sequence) {
		this.batchJobId = batchId;
		this.likeText = '%'+batchJobId+'%';
		this.totalCreditsExceedsDebits  = totalCreditsExceedsDebits;
		currentSequence = sequence;
		executeClass = runClass;
	}
	
	public Database.QueryLocator start(Database.BatchableContext info) {

		if(executeClass == null){
			likeText = info.getJobId();
		}
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext info, List<Supplier_Payment__c> scope) {
        system.debug (LoggingLevel.ERROR,'Pre Finalize SP Execute : ' + scope);
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
			bi = BatchInjector.getNextBatch(Schema.Supplier_Payment__c.getSObjectType().getDescribe().getName(), currentSequence);
		}

		Id batchId;
		if(bi != null && bi.executer != null){
			//run next batch
			system.debug('finish method of payment pre finalize batch, starting SupplierPaymentPreFinalizeBatch' + info.getJobId() + ' , nextBatch ='+bi);
        	batchId = Database.executeBatch(new SupplierPaymentPreFinalizeBatch(batchJobId,totalCreditsExceedsDebits, bi.executer, bi.sequence), bi.scope);
		}else{
			//NOW finalize  supplier invoices, and update amount paid field. 
			MasterControlProgram.finishedBatch( this );
            system.debug('finish method of payment pre finalize batch, starting SupplierPaymentFinalizeBatch' + info.getJobId() );
			batchId = Database.executeBatch(new SupplierPaymentFinalizeBatch(batchJobId,totalCreditsExceedsDebits),200);
		}
		
	}

}