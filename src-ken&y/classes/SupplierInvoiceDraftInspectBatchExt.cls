public with sharing class SupplierInvoiceDraftInspectBatchExt {

	ApexPages.StandardController con;
    public ID CompanyID;
    public Boolean have_jobid {get; set;}


    public SupplierInvoiceDraftInspectBatchExt(ApexPages.StandardController controller) {     
          
        con = controller;
        Company__c cRec = (Company__c)controller.getRecord();
        CompanyID = cRec.ID;
        have_jobid = false;

    }
 
 	public PageReference supplierInvoiceInspectDraftInvoices(){
       
        SupplierInvoiceDraftInspectBatch jpBatch = new SupplierInvoiceDraftInspectBatch(CompanyId); 
        ID jobId = Database.executeBatch(jpBatch,200);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Job: ' +jobId +' has been scheduled'));
        have_jobid = true;
        return null;
        
    }   
}