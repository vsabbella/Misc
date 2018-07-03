public with sharing class ApplyPaymentsBatch implements Database.batchable<sObject>,Database.stateful, Process.Runnable {
    
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    
    public void runBatch( id CompanyId  ) {				// Process.Runnable implementation 
    		Database.executebatch( new ApplyPaymentsBatch( new set<id>{CompanyId} ),200);
    }
    
    public ApplyPaymentsBatch() {}  // no-arg constructor needed by Runnable

    public ApplyPaymentsBatch(set<id> OperatingCoIds){
        OperatingCompanyIDs = OperatingCoIds;
        // Select Invoices with changed equal true and pull related list of Payment Details to sum up
        query = 'select id, name, Amount_Paid__c, Write_off_Amount__c, Deduction_Amount__c, Amount_Applied__c '+
                //' (select id, name, Amount__c, Type__c from Payment_Lines__r)' + KNDY-2291
                'from Customer_Invoice__c where Changed_Flag__c=true ';        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        //system.debug('Start query:'+query);        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Customer_Invoice__c> scope){
        CustomerInvoiceService.sumInvoicePayments(scope);
    }
    
    public void finish(Database.BatchableContext info){
    		MasterControlProgram.finishedBatch( this ); 	// allows the MCP to chain batches if configured to do so
    }
    

}