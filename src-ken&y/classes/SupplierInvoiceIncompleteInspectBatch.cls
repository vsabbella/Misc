public with sharing class SupplierInvoiceIncompleteInspectBatch implements Database.Batchable<sObject>, Process.Runnable2, Database.Stateful {
    
    
    public string query;
    public Id companyId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public Schemautil util = Schemautil.getInstance();
    
    public SupplierInvoiceIncompleteInspectBatch (Id comp){
        companyId = comp;
    }

    public Database.QueryLocator start(Database.BatchableContext IC){ 
        
        set<String> fieldStrings = new set<string>{'Id','Name','CreatedById'};
    	fieldStrings.addAll(util.getAllCustomFieldsFromObject('','Supplier_Invoice__c'));
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.','Purchase_Order__c'));
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Purchase_Order__r.Purchase_Agreement__r.','Contract__c'));

       	query = util.generateQueryFromFieldSet('Supplier_Invoice__c', new set<string>() ,fieldStrings, 'Status__c = \'Incomplete\' and Hold__c = false and Company__c=' + '\''+companyId + '\'' );
        /*   	
        query =  'Select Id, Buyer__c, Name, Invoice_Type__c, Company__c, Supplier__c, Date_Invoiced__c, Supplier_Invoice__c, Memo__c, Invoice_Amount__c, Total_Extended_Price__c, Status__c,Payment_Term__c,'+ 
                    ' Purchase_Order__c, Purchase_Order__r.Supplier__c, Purchase_Order__r.Remit_To_Supplier__c, Credit_Memo_Amount__c, Apply_To_Invoice__c '+
                    ' From Supplier_Invoice__c where Status__c = \'Incomplete\' and Hold__c = false and Company__c =:companyId '; 
        */     
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Supplier_Invoice__c> scope){
        Savepoint sp = Database.setSavepoint(); //KNDY-2336
        
        try{
        	SupplierInvoiceService.inspectIncompleteInvoices( scope );
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
    
    public SupplierInvoiceIncompleteInspectBatch() {}
    public void runBatch( Process_Job__c job ) {
        integer defaultBatchSize = 5;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
        }
        SupplierInvoiceIncompleteInspectBatch batch = new SupplierInvoiceIncompleteInspectBatch(job.Company__c);
        ID jobId = Database.executeBatch(batch, defaultBatchSize); 
    }  
}