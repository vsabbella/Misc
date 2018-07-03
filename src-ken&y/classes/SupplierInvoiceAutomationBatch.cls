public with sharing class SupplierInvoiceAutomationBatch implements Database.Batchable<sObject>, Process.Runnable2, Database.Stateful{
	public Id companyId;
	public Id facilityId;
	public Id supplierId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public string query;
    
    public SupplierInvoiceAutomationBatch() {}
    public void runBatch(Process_Job__c job) { 
    	integer defaultBatchSize = 20;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 200 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        SupplierInvoiceAutomationBatch batch = new SupplierInvoiceAutomationBatch(job.Company__c);
        ID jobId = Database.executeBatch(batch, defaultBatchSize); 
    }    
    
    public SupplierInvoiceAutomationBatch (Id comp){
        companyId = comp;      
    }
    
    public SupplierInvoiceAutomationBatch (Id comp, Id facility, Id supplier){
        //overloaded constructor.  So it can be called to filter on a facility and/or a supplier.  
        //Pass in null for facility or supplier if you only want one.
        companyId = comp;
        facilityId = facility;
        supplierId = supplier;        
    }    
    
    public Database.QueryLocator start(Database.BatchableContext BC){
		String additionalFilters = '';
		if (facilityId != null) {
			additionalFilters += 'Facility__c = : facilityId AND ';	
		}
		if (supplierId != null) {
			additionalFilters += 'Supplier__c = : supplierId AND ';	
		}		
		
		query = 'SELECT Id, Name FROM Receipt_Line__c WHERE '+
				'Company__c = :companyId AND '+
				additionalFilters +
				'Supplier__r.Create_Invoice_Automatically_on_Receipt__c=true AND '+
				'Supplier_Auto_Invoice__c = null AND '+
				'Uninvoiced_Quantity__c > 0';

    	return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Receipt_Line__c> scope){
    	Savepoint sp = Database.setSavepoint();
    	Set<Id> rlIdSet = (new Map<Id,Receipt_Line__c>(scope)).keySet();  //make a set of Ids from the list of SObjects	

        try{
        	 ReceivingDocumentService.generateInvoicesFromReceiptLines(rlIdSet);
        }catch(Exception e) {
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(scope, e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
    }
 
 
}