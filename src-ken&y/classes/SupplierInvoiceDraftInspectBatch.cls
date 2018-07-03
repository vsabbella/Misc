public with sharing class SupplierInvoiceDraftInspectBatch implements Database.Batchable<sObject>, Process.Runnable2, Database.Stateful{
	public Id companyId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public string query;
    public Boolean hasTax = false;
    public SupplierInvoiceDraftInspectBatch (Id comp){
        companyId = comp;
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
       
        //PTP-420 CreatedDate < 1 hr or SystemModstamp < 1 hr or Last visited by date > maxTimeIntervalBetweenBatchRuns; use this Int/long in the query below.
        Integer maxTimeIntervalBetweenBatchRuns = 12; 
		Configuration__c c = Configuration__c.getValues('SIBatchMaxIntervalTime'); //Custom setting that dictates the max interval time elapsed before looking at the said invoice again
		if (c != null) {
			maxTimeIntervalBetweenBatchRuns = Integer.valueOf(c.Value__c);
		}

        DateTime maxIntervalHourDT=system.now().addHours(-maxTimeIntervalBetweenBatchRuns) ;
         
    	query =	'Select Id, Name, Invoice_Type__c, Company__c, Supplier__c, Date_Invoiced__c, Supplier_Invoice__c, Memo__c, Invoice_Amount__c, Total_Extended_Price__c, Status__c,'+ 
				' Purchase_Order__c, Purchase_Order__r.Supplier__c '+
				' From Supplier_Invoice__c where Status__c = \'Draft\' and Hold__c = false and Company__c = :companyId AND (Visited_Last_By_Batch__c = false OR Last_Visited_By_Batch__c < :maxIntervalHourDT)'; 
 	
    	return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Supplier_Invoice__c> scope){
        system.debug('scope for SupplierInvoiceDraftInspectBatch---> '+scope);
    	Savepoint sp = Database.setSavepoint(); //KNDY-2336
    	TaxService taxSvc = TaxService.getInstance();
    	Integer taxRecSize = 0; 
     
    	for(Supplier_Invoice__c eachSI: scope){ //KNDY-2869 capturing the record ids and including it in the failure msg
    		if(taxSvc.taxServiceConfigured(Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName(), eachSI)==true){
                 taxRecSize++;
            } 
    	}
    	hasTax = taxRecSize>0 ? true : false ;
    	 
        try{
        	SupplierInvoiceService.inspectDraftInvoices(scope, BC.getJobId());
        }catch(Exception e) {
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(scope, e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public void finish(Database.BatchableContext info){
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);    
		
        if(hasTax==true){
            MasterControlProgram.finishedBatch( this ); 
            Database.executeBatch(new SupplierInvoicePostInspectBatch(info.getJobId()),50);
        }else {  MasterControlProgram.finishedBatch( this );  }
        //Boolean hasTax = taxSvc.taxServiceConfigured(Supplier_Invoice__c.getSobjectType().getDescribe().getLocalName(), companyId);
        
        ///if(hasTax == true){
			//MasterControlProgram.finishedBatch( this ); 
            //Database.executeBatch(new SupplierInvoicePostInspectBatch(info.getJobId()),50);
        //}else{
          //  MasterControlProgram.finishedBatch( this ); 
      // }
    }
 
 	/* implementation of Runnable 
 	 */
 	public SupplierInvoiceDraftInspectBatch() {}
 	public void runBatch( Process_Job__c job ) {
		integer defaultBatchSize = 5;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
		
		SupplierInvoiceDraftInspectBatch batch = new SupplierInvoiceDraftInspectBatch(job.Company__c);
        ID jobId = Database.executeBatch(batch, defaultBatchSize); 
	}  
}