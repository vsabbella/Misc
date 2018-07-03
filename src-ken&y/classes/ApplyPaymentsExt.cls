public with sharing class ApplyPaymentsExt {

    ApexPages.StandardController con;
    public Set<ID> operatingCompanies = new Set<ID>();
    public ID CompanyID;
    public Boolean have_jobid {get; set;}

    public ApplyPaymentsExt(ApexPages.StandardController controller) {     
          
        con = controller;
        Company__c compRec = (Company__c)controller.getRecord();
        CompanyID = compRec.ID;
        operatingCompanies.add(CompanyID);
        have_jobid = false;
    }
      
    public pagereference applyCash() {
        ApplyPaymentsBatch Obj=new ApplyPaymentsBatch(operatingCompanies);   
        Obj.operatingCompanyIds = operatingCompanies;
        Id jobId=Database.executebatch(obj,200);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled + jobId ));
        have_jobid = true;
        return null;
    }

}