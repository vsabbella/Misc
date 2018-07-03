public with sharing class CustomerCreditBucketExt {

    ApexPages.StandardController con;
    ID CompanyID;
    public Boolean have_jobid {get; set;}


    public CustomerCreditBucketExt(ApexPages.StandardController controller) {     
          
        con = controller;
        Company__c cRec = (Company__c)controller.getRecord();
        CompanyID = cRec.ID;
        have_jobid = false;

    }
    
    public pagereference calculate() {
    
        CustomerOutstandingBalanceBatch Obj=new CustomerOutstandingBalanceBatch();
        Obj.companyId = CompanyID;
        Id jobId=Database.executebatch(obj,1);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled  + jobId ));
        have_jobid = true;
        return null;
    }

}