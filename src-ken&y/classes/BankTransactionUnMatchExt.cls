public with sharing class BankTransactionUnMatchExt {
	
	public Bank_Transaction_Match__c btm {get;set;}
	public boolean isDeleted {get;set;}
	public BankTransactionUnMatchExt(ApexPages.StandardController con) {
		
		btm = [Select Id, Bank_Transaction__r.Reconciled_As_Of_Date__c, Bank_Transaction__r.Match_Approved__c, Bank_Transaction__r.Name, Bank_Transaction__c 
			   from Bank_Transaction_Match__c where Id = :con.getRecord().Id limit 1];
		isDeleted = false;
			   
		
	}
	
	public PageReference validate() {
		PageReference page= null;
		if(btm.Bank_Transaction__r.Match_Approved__c) {
			if(btm.Bank_Transaction__r.Reconciled_As_Of_Date__c != null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.bank_transaction_has_been_reconciled));
			}else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.approved_matches_will_be_deleted));
			}
			
		}else
		{
			page = unMatch();
		}
		system.debug('page '+page);
		return page;
	}
	
	public PageReference UnMatch() {
		PageReference page= null;
		try {
			delete btm;
			page = new PageReference('/'+btm.Bank_Transaction__c);
			isDeleted = true;
		}catch(Exception ex) {
			system.debug(' unmatch btm error '+ex.getMessage() +' stack: '+ex.getStackTraceString());
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
		}
		system.debug('page '+page);
		return page;
	}
    
	public PageReference cancel() {
		PageReference page= null;
		Schema.DescribeSObjectResult dsr = Bank_Transaction_Match__c.SObjectType.getDescribe();
        page = isDeleted ? new PageReference('/' + dsr.getKeyPrefix()) : new PageReference('/' + btm.Id);   
        return page; 
	}
    
}