public with sharing class CustomerInvoicesBatchExt {

    ApexPages.StandardController con;
    public Set<ID> operatingCompanies = new Set<ID>();
    public ID CompanyID;
    public Boolean have_jobid {get; set;}

    public CustomerInvoicesBatchExt(ApexPages.StandardController controller) {     
          
        con = controller;
        Company__c compRec = (Company__c)controller.getRecord();
        CompanyID = compRec.ID;
        operatingCompanies.add(CompanyID);
        have_jobid = false;
    }
    
    public pagereference generateInvoices() {
        CustomerInvoiceBatch Obj=new CustomerInvoiceBatch(operatingCompanies);
        Obj.operatingCompanyIds = operatingCompanies;
        Id jobId=Database.executebatch(obj,10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled +jobId ));
        have_jobid = true;
        return null;
    }

}