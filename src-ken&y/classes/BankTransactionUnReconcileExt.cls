public with sharing class BankTransactionUnReconcileExt extends GridRelatedListController{
	
	public Bank_Account__c bankAccount {get;set;}
	public BankTransactionUnReconcileExt(ApexPages.standardController controller){
		
	}
	
	@RemoteAction
	public static JSONResult getLatestReconciliationDate(Id bankAccountId) {
		JSONResult result = new JSONResult();
		DateTime recDate = BankReconciliationService.getLastReconciledDate(bankAccountId);
		system.debug(recDate);
		if(recDate == null) {
			result.success = false;
			result.records = null;
			result.addMessage('No reconciled records available.',ApexPages.Severity.Warning);
		}else {
            
			result.success = true;
			result.records = new list<DateTime>{recDate};
		}
		
		return result;
	}
	
	@RemoteAction
	public static JSONResult getRecordsToUnReconcile(Id bankAccountId, DateTime endDate) {
		JSONResult result = new JSONResult();
		DateTime startRange = dateTime.newInstance(endDate.date(), Time.newInstance(0,0,0,0));
   		DateTime endRange = startRange.addDays(1);
   		try{
	        SOQLUtil soql = new SOQLUtil('Bank_Transaction__c');
	        soql.addFields(new set<string>{'Id'});
	        soql.setWhereClause(
				'Finalized__c = true and Reconciled_As_Of_Date__c >= :startRange and Reconciled_As_Of_Date__c < :endRange and Bank_Account__c = :bankAccountId'       
	        );   			
   			soql.setLimit(50000);
   			
   			list<Bank_Transaction__c> lBTs = Database.query(soql.getQuery());
   			result.success = true;
   			result.records = lBTs;
   			return result;
   		}catch(Exception ex) {
   			result.success = false;
   			result.addMessage(ex,ApexPages.Severity.ERROR);
   			return result;
   		}
   		
		
   		
	}
	
	@RemoteAction
	public static JSONResult UnReconcileBankTransactions(list<Bank_Transaction__c> lBTs, Id bankAccountId, DateTime endDate) {
		JSONResult result = new JSONResult();
		try{
			BankReconciliationService.unReconcileBankTransactions(lBTs, endDate.date(), bankAccountId);
			result.success = true;
			result.addMessage('Transactions successfully unreconciled',ApexPages.Severity.CONFIRM);
		}catch(exception ex)
		{
			result.addMessage(ex,ApexPages.Severity.ERROR);
		}
		return result;
	}
    
}