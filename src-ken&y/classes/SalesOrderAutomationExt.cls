public class SalesOrderAutomationExt {
    
    Id salesOrderId;
    Id companyId;
    public Boolean hasErrors {get;set;}

    public SalesOrderAutomationExt(ApexPages.StandardController sc){
		Sales_Order__c so = (Sales_Order__c)sc.getRecord();
		this.salesOrderId = so.Id;
		this.companyId = so.Company__c;
		
		if (this.salesOrderId == null) {
        	ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Parameter: Sales order \'Id\' cannot be null.'));
        	return;
        }		
	}
	
	public void processSO(){
	    
	    try{
    	    SalesOrderPlanBatch batchInstance = new SalesOrderPlanBatch(new Set<Id>{ companyId }, salesOrderId);
            Id batchJobId = Database.executebatch(batchInstance, 1);
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, 'Sales Order is being processed. You will receive an email notification once processing is complete'));
	    }
	    catch(Exception e){
	        ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
	    }
	}
}