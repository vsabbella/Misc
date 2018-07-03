public with sharing class GenerateAccountingBatchExt {
/* 
    ApexPages.StandardController con;
    Set<ID> CompanyIds = new Set<ID>();
    Set<ID> operatingCompSet = new Set<ID>();
    Map<Accounting_Rule__c,set<Id>> OperatingCompanyMap = new Map<Accounting_Rule__c,set<Id>>();
    Company__c Comp = new Company__c();
    public Boolean have_jobid {get; set;}

    public GenerateAccountingBatchExt(ApexPages.StandardController controller) {     
          
        con = controller;
        Comp = (Company__c)controller.getRecord();
        
        //Keeping the CompanyIds set because if we decide to move away invoking it from company to other location.
        CompanyIds.add(Comp.id);
        have_jobid = false;
    }

    public pagereference generateShipmentAccounting() {
        //CompanyIds = OperatingCompanyMap.get(new Accounting_Rule__c(Transaction__c = 'Shipment'));
        ShipmentAccountingBatch Obj=new ShipmentAccountingBatch(CompanyIds);
        Obj.operatingCompanyIds = CompanyIds;
        Id jobId=Database.executebatch(obj,10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled + jobId ));
        have_jobid = true;
        return null;
    }
    // Other way to invoke the invoice batch class is thru the finish method for shipment batch class
    public pagereference generateInvoiceAccounting() {
        //CompanyIds = OperatingCompanyMap.get(new Accounting_Rule__c(Transaction__c = 'Customer Invoice'));
        CustomerInvoiceAccountingBatch Obj=new CustomerInvoiceAccountingBatch(CompanyIds);
        Obj.operatingCompanyIds = CompanyIds;
        Id jobId=Database.executebatch(obj,10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled + jobId ));
        have_jobid = true;
        return null;
    }
    // Other way to invoke the receipt batch class is thru the finish method for invoice batch class
    public pagereference generateReceiptAccounting() {
        //CompanyIds = OperatingCompanyMap.get(new Accounting_Rule__c(Transaction__c = 'Customer Receipt'));
        CustomerReceiptAccountingBatch Obj=new CustomerReceiptAccountingBatch(CompanyIds);
        Obj.operatingCompanyIds = CompanyIds;
        Id jobId=Database.executebatch(obj,10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled + jobId ));
        have_jobid = true;
        return null;
    }
    
    public pagereference generatePOReceiptAccounting() {
        //CompanyIds = OperatingCompanyMap.get(new Accounting_Rule__c(Transaction__c = 'Purchase Receipt'));
        POReceiptAccountingBatch Obj=new POReceiptAccountingBatch(CompanyIds);
        Obj.operatingCompanyIds = CompanyIds;
        Id jobId=Database.executebatch(obj,10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled + jobId));
        have_jobid = true;
        return null;
    }
    
    public pagereference generateSupplierInvoiceAccounting() {
        //CompanyIds = OperatingCompanyMap.get(new Accounting_Rule__c(Transaction__c = 'Supplier Invoice'));
        SupplierInvoiceAccountingBatch Obj=new SupplierInvoiceAccountingBatch(CompanyIds);
        Obj.operatingCompanyIds = CompanyIds;
        Id jobId=Database.executebatch(obj,10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled + jobId ));
        have_jobid = true;
        return null;
    }
    
    public pagereference generateSupplierPaymentAccounting() {
        //CompanyIds = OperatingCompanyMap.get(new Accounting_Rule__c(Transaction__c = 'Supplier Payment'));
        SupplierPaymentAccountingBatch Obj=new SupplierPaymentAccountingBatch(CompanyIds);
        Obj.operatingCompanyIds = CompanyIds;
        Id jobId=Database.executebatch(obj,10);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Job_has_been_scheduled + jobId ));
        have_jobid = true;
        return null;
    }
    */
}