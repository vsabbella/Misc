global with sharing class AgreementGenerateInvoiceExt {
	
    public id recId{get;set;}
	public static string objectName{get;set;}
	public string nspace { get { return KSE.Namespace; }}
	private static SchemaUtil util = SchemaUtil.getInstance();
	global AgreementGenerateInvoiceExt(ApexPages.standardController controller) {
		if(controller == null) {
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'Controller not set'));
		}else { 
			recId = controller.getRecord().Id;
			objectName = util.getObjectNameFromId(recId);
		}
	}
	
    @remoteAction
    global static JsonResult validate(Id recordId, string objName) {
		JsonResult result = new JsonResult();
		result = GenerateInvoiceExt.validate(recordId, objName);
		return result;
    }
    
    @remoteAction
    global static JsonResult next(boolean useIGR, Id recordId, sObject rec){
        JsonResult result = new JsonResult();
        result = GenerateInvoiceExt.next(useIGR, recordId, rec);
        return result;
    }
	
	@remoteAction
	global static JSONResult createInvoice(string strTypeToFulfillments){
		JsonResult result = new JsonResult();
		result = GenerateInvoiceExt.createInvoice(strTypeToFulfillments);
		return result;
	}
	
	@remoteAction
	global static JSONResult prefinalizeActions(list<Customer_Invoice__c> lstCI){
		JsonResult result = new JsonResult();
		result = GenerateInvoiceExt.prefinalizeActions(lstCI);
		return result;
	}
	
	
	// This method is deprecated. Use below finalizeInvoices method instead.
	@remoteAction 
    global static JSONResult finalizeInvoices(Id recordId, list<Customer_Invoice__c> lstCI, string objName){
        JsonResult result = new JsonResult();
        return result;
    }
    
	@remoteAction
	global static JSONResult finalizeInvoices(Id recordId, boolean fromProcessFulFilment, list<Customer_Invoice__c> lstCI, string objName){
		JsonResult result = new JsonResult();
		result = GenerateInvoiceExt.finalizeInvoices(recordId, fromProcessFulFilment, lstCI, objName);
		return result;
	}
	
	@remoteAction
	global static JSONResult autoApplyPrepayments(list<Customer_Invoice__c> lstCI){
		JsonResult result = new JsonResult();
		result = GenerateInvoiceExt.autoApplyPrepayments(lstCI);
		return result;
	}
	
	@remoteAction
	global static JSONResult callUserDefinedMethod(Process__c pRecord, List<SObject> scope){
		JsonResult result = new JsonResult(); 
		result = GenerateInvoiceExt.callUserDefinedMethod(pRecord, scope);
		return result;
	}
	
	@remoteAction
	global static JSONResult getValues(){
		JsonResult result = new JsonResult(); 
		result = GenerateInvoiceExt.getValues();
		return result;
	}
}