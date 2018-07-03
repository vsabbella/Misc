public with sharing class SalesOrderUndoReleaseExt {
    
    private Apexpages.Standardcontroller con;

    Id salesOrderId;
    
    public Boolean hasErrors {get;set;}

	
    public SalesOrderUndoReleaseExt(ApexPages.StandardController controller){
		con = controller;

		salesOrderId = controller.getId();		
		
		if (salesOrderId == null) {
        	ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid Parameter: Sales order \'Id\' cannot be null.'));
        	return;
        }		

	}
	
	
    public void undoRelease(){
        
        try{
            SalesOrderService sos = new SalesOrderService();
            sos.undoPlan(new Set<Id>{con.getId()});
            JSONResult jsonResult = new JSONResult();
	        jsonResult.success  = (ExceptionService.hasErrors == true ? false : true);
	        jsonResult.messages.addAll(ExceptionService.messages);
	        
	        hasErrors = ExceptionService.hasErrors;

			if(jsonResult.messages != null && jsonResult.messages.size() > 0){
				for (Map<String, String> msg : jsonResult.messages) {
				    ApexPages.addMessage(MessageUtil.toApexPageMessage(msg));
				}
			}
        }catch(Exception e){
            hasErrors = true;
			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.Error, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            
        }
    }
    
}