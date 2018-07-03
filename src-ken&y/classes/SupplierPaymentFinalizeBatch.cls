public with sharing class SupplierPaymentFinalizeBatch implements Database.batchable<sObject>, Database.Stateful{

	
	public List<Notify.Message> messages = new List<Notify.Message>();
	public String batchJobId;
	public String likeText;
	public boolean totalCreditsExceedsDebits;
	public SupplierPaymentFinalizeBatch(String batchJobId,boolean totalCreditsExceedsDebits) {
		this.batchJobId = batchJobId;
		this.likeText = '%'+batchJobId+'%';
		this.totalCreditsExceedsDebits =  totalCreditsExceedsDebits;
	}
	public Database.QueryLocator start(Database.BatchableContext BC){
		//KNDY-17923 - deperecated 'Check_Number__c' ,payment_number__c
		//create another query to fetch payment lines because of error "Aggregate query has too many rows for direct assignment, use FOR loop = External entry point "
		String query = 'Select Id,Name, Source_Key__c,Payment_Amount__c,Status__c,Status_Reason__c,Total_Number_of_Lines__c,Bank_Account__c,Payment_Method_G__c,Reference__c,Batch_Job_Id__c ' +
					   //' (select id,Supplier_Invoice__c,Amount__c,Type__c from Supplier_Payment_Lines__r)  '+
					   ' from Supplier_Payment__c where Finalized__c = false And Status__c =\'Applied\'' +
					   ' and Batch_Job_Id__C = :batchJobId  and Source_Key__c LIKE :likeText';
		
		return Database.getQueryLocator(query);
	}
	
	public void execute(Database.BatchableContext info, List<Supplier_Payment__c> scope) {
		SupplierPaymentService spService = new SupplierPaymentService();
		set<Id> SPIdSet = new set<Id>();
		
		for (Supplier_Payment__C sp :scope){
			SPIdSet.add(sp.id);
		}
		//create another query to fetch payment lines because of error "Aggregate query has too many rows for direct assignment, use FOR loop = External entry point "
		SOQLUtil supplierPaymentSOQL = new SOQLUtil ( 'Supplier_Payment_Line__c',true) ;//enforceFLS=true, running in user mode		      
        supplierPaymentSOQL.addFields('Payment_Lines_Preview');
        supplierPaymentSOQL.addFields(new set<string> {'Name','Supplier_Payment__c','Amount__c','Type__c','Supplier_Invoice__c'});
        supplierPaymentSOQL.setWhereClause ( ' Supplier_Payment__c IN :SPIdSet' ) ;
        system.debug(LoggingLevel.Info,'SP Line Query : '+supplierPaymentSOQL.getQuery ());
	    List<Supplier_Payment_Line__c> spLinesList = Database.query( supplierPaymentSOQL.getQuery () ) ;    
	    system.debug(LoggingLevel.Debug,'Finalize Batch find lines fetched : ' + spLinesList.Size());
	    Map<Id,List<Supplier_Payment_Line__c>> SPLineToFinalizeMap = new Map<Id,List<Supplier_Payment_Line__c>>();
	    List<Supplier_Payment_Line__C> spLineAppend = new List<Supplier_Payment_Line__C>(); 
        for (Supplier_Payment_Line__C spLine :spLinesList){     
        	spLineAppend = new List<Supplier_Payment_Line__C>(); 
        	spLineAppend.add(spLine);
        	if (SPLineToFinalizeMap.containsKey(spLine.Supplier_Payment__c))  {
        		spLineAppend.addAll(SPLineToFinalizeMap.get(spLine.Supplier_Payment__c));        		
        	}
    		SPLineToFinalizeMap.put(spLine.Supplier_Payment__c,spLineAppend);        
        }
        system.debug(LoggingLevel.Debug,'Finalize Batch find lines fetched : ' + SPLineToFinalizeMap);
        messages = spService.FinalStepToFinalize(totalCreditsExceedsDebits,scope,SPLineToFinalizeMap);
		if (messages == null)  messages = new List<Notify.Message>();
	}
	
	public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		integer msgCount = messages.size();
		//KNDY-17206 -check if zero payment msg only displayed mark batch is successfull
		system.debug(LoggingLevel.Error,'msgCount='+msgCount + 'messages =' +messages);
		if (messages.size() > 0 && messages.size() ==1){
			if (messages[0].title.contains(Label.Payment_amount_was_zero_Create_Zero_Amount_Payments_checkbox_unselected))
				msgCount = 0;
		}
	    Notify.sendEmailBatchFinish(msgCount, null, messages, info);     
	}
	


}