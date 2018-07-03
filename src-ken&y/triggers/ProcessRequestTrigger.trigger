trigger ProcessRequestTrigger on Process_Request__c (after insert, after update) {
    
    if(DML.checkTriggerDispatch(Process_Request__c.getSobjectType())){return;}
    
    // Ignore the exceptions count update.
    if(ExceptionService.ignoreTrigger('Process_Request__c')){
        return;
    }
    
    if(trigger.isAfter){
    	if(trigger.isInsert || trigger.isUpdate){
    		List<Process_Request__c> readyProcessRequests = new List<Process_Request__c>();
    		
    		String processCall;
    		for(Process_Request__c pr : trigger.new){
    			if(pr.Status__c == 'Ready'){
	    			readyProcessRequests.add(pr);
	    			processCall = pr.Process_Call__c;
    			}
    		}
    		
	    	if(readyProcessRequests.size() > 0){
	    		ProcessRequestService prService = (ProcessRequestService) Type.forName('ProcessRequestServiceImpl').newInstance();
	    		ProcessResult result = prService.process(processCall, readyProcessRequests);
	    	}
    	}
    }
}