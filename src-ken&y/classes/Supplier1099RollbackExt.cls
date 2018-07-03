public with sharing class Supplier1099RollbackExt {
	
	private Apexpages.Standardcontroller companyController;
	public boolean disableRollback {get;set;}
	public Id companyId{get; private set;}
	
	
	public Supplier1099RollbackExt(Apexpages.Standardcontroller controller){
		companyController = controller;
		companyId = companyController.getId();
		disableRollback = true;
	}

	@RemoteAction 
	public static JsonResult rollBack( String batchJobIdStr, String companyIdStr){//KNDY-17918
		JsonResult result = new JsonResult();
		system.debug(LoggingLevel.Error, '>>> batchJobIdStr: ' + batchJobIdStr);
		system.debug(LoggingLevel.Error, '>>> companyIdStr: ' + companyIdStr);
		try{
			Id batchJobId = database.executeBatch(new Supplier1099RollbackBatch((Id)companyIdStr, batchJobIdStr));
			result.success = true;
			String pageMsg = Label.Your_batch_job_was_created + ' ' + Label.Batch_Job_ID + ': '+ batchJobId;
			result.addMessage(pageMsg,ApexPages.severity.CONFIRM);
		}catch(Exception ex){
			result.success = false;
			String pageMsg = Label.Batch_job_could_not_be_started;
			result.addMessage(pageMsg,ApexPages.severity.ERROR);
		}
		return result;
	}
	
	@RemoteAction 
	public static JsonResult getSupplier1099s( String batchJobIdStr, String companyIdStr){//KNDY-17918
		JsonResult result = new JsonResult();
		system.debug(LoggingLevel.Error, '>>> batchJobIdStr: ' + batchJobIdStr);
		system.debug(LoggingLevel.Error, '>>> companyIdStr: ' + companyIdStr);
		String whereClause = 'Filed__c = false and Company__c  = :companyIdStr';
		if (!String.isBlank(batchJobIdStr)){
			whereClause += ' and Batch_Job_ID__c = :batchJobIdStr';
		}
		SOQLUtil soql = new SOQLUtil('Supplier_1099__c');
		soql.addFields(new Set<String>{'Id', 'Name'});
		soql.setWhereClause(whereClause);
		List<Supplier_1099__c> sup1099s = Database.query(soql.getQuery());
		if(sup1099s.size() == 0){
			result.success = false;
			String pageMsg = Label.No_supplier_1099_records;
			result.addMessage(pageMsg,ApexPages.severity.INFO);
		}else{
			result.success = true;
		}
		return result;
	}
}