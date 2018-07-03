public with sharing class SupplierInvoicePostInspectBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,
															Database.Stateful {
	

	private Id batchJobId;
	private TaxService taxSvc = TaxService.getInstance();
	public List<Notify.Message> messages = new List<Notify.Message>();
	public Set<String> taxBlackListedInvoiceTypesForSI = new Set<String>{'Prepayment'}; 

	public SupplierInvoicePostInspectBatch(String batchId) {
			batchJobId = batchId;
	}

	public Database.QueryLocator start(Database.BatchableContext info) {

		//Boolean hasTax = taxSvc.taxServiceConfigured(Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName());
		//if(hasTax){
			String soql = 'SELECT ID, Name From Supplier_Invoice__c WHERE Batch_Job_Id__c = \'' 
			                + batchJobId +'\'' 
			                +' AND Invoice_type__c NOT  IN :taxBlackListedInvoiceTypesForSI';
			return Database.getQueryLocator(soql);
		//}else{
		//	return null;
		//}
	}

	public void execute(Database.BatchableContext info, List<Supplier_Invoice__c> scope) {
	     system.debug('scope for PostInspectBatch---> '+scope);
		List<Id> scopeIds = new List<Id>();
    	for(Supplier_Invoice__c si: scope){ //KNDY-2869 capturing the record ids and including it in the failure msg
    		if (si.id != null){
    			scopeIds.add(si.id);
    		}
    	}
    	 
		try{
			List<TaxService.TaxResult> results = taxSvc.getTax(scopeIds);

			for(TaxService.TaxResult tr : results){
				messages.add(new Notify.Message( 'Tax Service called', tr.message));
			}
		}catch(Exception e){
			messages.add(Notify.getErrorMessage(scope, e.getMessage(), e.getStackTraceString()));
		}
	}

	public void finish(Database.BatchableContext info) {
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
	}
}