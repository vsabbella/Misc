public with sharing class Supplier1099BatchExt extends BaseController {
	
	private Apexpages.Standardcontroller companyController;
	public boolean disableBatch {get;private set;}
	public Id companyId{get; private set;}
	public decimal amountReportingThreshold {get;set;}
	private static final decimal DEFAULT_AMOUNT = 600;
	
	public Supplier1099BatchExt(Apexpages.Standardcontroller controller){
		companyController = controller;
		companyId = companyController.getId();
		if(companyController.getId() == null){
			disableBatch = true;	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, Label.Company_not_found));
		}else{
			disableBatch = false;
		}
		
		amountReportingThreshold = DEFAULT_AMOUNT;
		List<ConfigurationMDT__mdt> mdtRecords = [SELECT developerName, Value__c, namespacePrefix
                                        FROM ConfigurationMDT__mdt
                                        WHERE developerName = 'Supplier_1099_Amount_Reporting_Threshold'
                                        LIMIT 1];
        if (mdtRecords.size() > 0){
            amountReportingThreshold = Decimal.ValueOf(mdtRecords[0].Value__c);
        }
	}
	
	@RemoteAction
    public static JsonResult startOffBatch( String companyIdStr, String yearStr, String amountStr){
       JsonResult result = new JsonResult();
       Integer year = Integer.ValueOf(yearStr);
       Decimal amount = Decimal.ValueOf(amountStr);
       Id companyId = Id.ValueOf(companyIdStr);
       String pageMsg;
       
       Id batchJobId = btn_RunBatch(companyId,year, amount);
       if (batchJobId != null){
           result.success = true;
           pageMsg = Label.Your_batch_job_was_created + ' ' + Label.Batch_Job_ID + ': '+ batchJobId;
           result.addMessage(pageMsg,ApexPages.severity.CONFIRM);
       }else{
           result.success = false;
           pageMsg = Label.Batch_job_could_not_be_started;
           result.addMessage(pageMsg,ApexPages.severity.ERROR);
       }
       return result;
    }

	public static Id btn_RunBatch(Id companyId, Integer year, Decimal amount){
		Id batchJobId = null;
		try{
			Supplier1099Batch new1099BatchJob = new Supplier1099Batch(companyId, year, amount);
			batchJobId = database.executeBatch(new1099BatchJob);
		}catch(Exception ex){
			batchJobId = null;
		}
		return batchJobId;
	}
}