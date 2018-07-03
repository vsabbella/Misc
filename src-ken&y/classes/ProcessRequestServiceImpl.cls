public with sharing class ProcessRequestServiceImpl implements ProcessRequestService {
	
	private static final String INVALID_PROCESS_REQUEST_ID = String.format(Label.Invalid_data, new String[]{'Process Request Id'});
	private static final String INVALID_PROCESS_CALL = String.format(Label.Invalid_data, new String[]{'Process call'});
	private static final String INVALID_PARAMETER_NAME = String.format(Label.Invalid_data, new String[]{'Parameter Name'});
	private static final String INVALID_PARAMETER_VALUE = String.format(Label.Invalid_data, new String[]{'Parameter Value'});
	private static final String INVALID_TARGET_DOCUMENT_ID = String.format(Label.Invalid_data, new String[]{'Target Document Id'});
	
	public class ProcessRequestServiceException extends Exception {}
	
   /* public static ProcessResult getStatus(String processRequestId){
    	
    	List<String> processRequestIds = new List<String>();
    	 
    	if(! String.isBlank(processRequestId)){
    		processRequestIds.add(processRequestId);
    	}
    	
    	return getStatus(processRequestIds);
    }
    
    public static ProcessResult getStatus(List<String> processRequestIds){
    	ServiceResponse servResp = new ServiceResponse();
    	
    	if(processRequestIds.size() == 0){
    		servResp.isSuccess = false;
    		servResp.addMessage(null, new Message(Message.SEVERITY_ERROR, INVALID_PROCESS_REQUEST_ID, ''));
	    	return new ProcessResult(servResp);
    	}else{
	    	// Query Process Request with exceptions and populate the status map.
	    	for(Process_Request__c pr : getProcessRequests(processRequestIds)){
	    		for(Task exceptionTask : pr.Tasks){
	    			servResp.addMessage(pr.Id, new Message(Message.SEVERITY_ERROR, exceptionTask.Subject, exceptionTask.Description));
	    		}
	    	}
	    	
	    	return new ProcessResult(servResp);
    	}
    }
    
	private Process_Request__c getProcessRequest(String processRequestId){
		return getProcessRequests(new List<String>{processRequestId})[0];
	}
	
	private List<Process_Request__c> getProcessRequests(List<String> processRequestIds){
		SOQLUtil soql = new SOQLUtil('Process_Request__c');
		soql.addFields(new Set<String>{
			'Id', 'Status__c', 'Process_Call__c', 'Target_Document_Id__c', 'Has_Exceptions__c',
			'Parameter_Name__c', 'Parameter_Value__c', 'Parameter_Body__c'
		});
		soql.setWhereClause('Id IN :processRequestIds');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Tasks');
		childRel.addFields(new set<string>{
			'Id'
		});
		childRel.setWhereClause('Type = \'Exception\' AND Status = \'Open\'');
		
		soql.addChildRelationship(childRel);
		
		return Database.query(soql.getQuery());
	}
	
    public ProcessResult process(String processRequestId){
    	ServiceResponse servResp = new ServiceResponse();
    	
    	if(String.isBlank(processRequestId)){
    		servResp.isSuccess = false;
    		servResp.addMessage(null, new Message(Message.SEVERITY_ERROR, INVALID_PROCESS_REQUEST_ID, ''));
    		return new ProcessResult(servResp);
		}else{
			Process_Request__c processRequest = getProcessRequest(processRequestId);
			return process(processRequest);
    	}
    }
    
    public ProcessResult process(String processCall, List<String> processRequestIds){
    	ServiceResponse servResp = new ServiceResponse();
		
    	for(String processRequestId : processRequestIds){
    		if(String.isBlank(processRequestId)){
    			servResp.isSuccess = false;
	    		servResp.addMessage(processRequestId, new Message(Message.SEVERITY_ERROR, INVALID_PROCESS_REQUEST_ID, ''));
    		}
		}
		
		if(! servResp.isSuccess){
			return new ProcessResult(servResp);
		}else{
			List<Process_Request__c> processRequests = getProcessRequests(processRequestIds);
			return process(processCall, processRequests);
		}
    }
    
    public ProcessResult process(Process_Request__c processRequest){
    	String processCall = processRequest.Process_Call__c;
    	return process(processCall, new List<Process_Request__c>{processRequest});
	}*/
    
    public ProcessResult process(String processCall, List<Process_Request__c> processRequests){
    	List<ServiceRequest> servRequests = new List<ServiceRequest>();
    	List<Process_Request__c> completedRequests = new List<Process_Request__c>();
    	List<Process_Request__c> failedRequests = new List<Process_Request__c>();
    	
		ProcessResult processResult = new ProcessResult();
				
		if(String.isBlank(processCall)){
    		throw new ProcessRequestServiceException(INVALID_PROCESS_CALL);
    	}
    	/*
		String[] serviceNameParts = processCall.split(' ', 2);
    	String targetAction = serviceNameParts[0];
    	String targetObject = serviceNameParts[1];
    	
    	ServiceRequest servRequest = new ServiceRequest();
		servRequest.actionName = targetAction; //'Pick';
		
    	if(targetObject == 'Shipment Line'){
			servRequest.serviceName = 'ShipmentLineService';
    	}	
    	
		JSONGenerator jsonGen = JSON.createGenerator(false);
		jsonGen.writeStartArray();
		
		ServiceResponse servResp = new ServiceResponse();
										
		for(Process_Request__c pr : processRequests){
			try{
				if(!String.isBlank(pr.Parameter_Body__c)){
					jsonGen.writeString(pr.Parameter_Body__c);
				}
				else
				if(!String.isBlank(pr.Target_Document_Id__c)){
					if(String.isBlank(pr.Parameter_Name__c)){
						throw new ProcessRequestServiceException(INVALID_PARAMETER_NAME);
					}
					
					if(String.isBlank(pr.Parameter_Value__c)){
						throw new ProcessRequestServiceException(INVALID_PARAMETER_VALUE);
					}
					
					jsonGen.writeStartObject();
					jsonGen.writeStringField('targetId', pr.Target_Document_Id__c);
					jsonGen.writeStringField('requestId', pr.Id);
					
					if(!String.isBlank(pr.Parameter_Name__c)){
						jsonGen.writeStringField(pr.Parameter_Name__c, pr.Parameter_Value__c);
					}
					
					jsonGen.writeEndObject();
				}
				else{
					throw new ProcessRequestServiceException(INVALID_TARGET_DOCUMENT_ID);
				}
			}catch(Exception ex){
				system.debug(LoggingLevel.ERROR, ex);
				servResp.addMessage(pr.Id, new Message(Message.SEVERITY_ERROR, ex.getMessage(), ex.getStackTraceString()));
			}
		}
			
		jsonGen.writeEndArray();

		String paramString = jsonGen.getAsString();
		jsonGen.close();

    	if(!String.isBlank(paramString) && paramString != '[]'){
			servRequest.params = JSON.deserializeUntyped(paramString);
			servResp = ServiceRouter.route(servRequest); 
	    }
		*/

		ServiceRequest servRequest = new ServiceRequest();
		servRequest.actionName = processCall;
		
		list<string> paramList = new list<string>();
		for(Process_Request__c pr : processRequests){
			paramList.add(JSON.serialize(pr));
		}
		servRequest.params = paramList;

		ServiceResponse servResp = new ServiceResponse();
		servResp = ServiceRouter.route(servRequest);
	    
		if(! servResp.isSuccess && servResp.messages.size() > 0){
			throw new ProcessRequestServiceException(servResp.messages[0].summary);
		}
		
		ExceptionService exService = new ExceptionService();
		
    	for(Process_Request__c pr : processRequests){
			if(servResp.messageMap.containsKey(pr.Id)){

				failedRequests.add(new Process_Request__c(Id = pr.Id, Status__c = 'Failed'));
				
				processResult.isSuccess = false;
				processResult.messages.addAll(servResp.messageMap.get(pr.Id));
				
				TaskType PROCESS_REQUEST_EXCEPTION = new TaskType();
				PROCESS_REQUEST_EXCEPTION = new TaskType();
				PROCESS_REQUEST_EXCEPTION.code = 'PR-00001';
				PROCESS_REQUEST_EXCEPTION.typeName = 'Exception';
				PROCESS_REQUEST_EXCEPTION.label = servResp.messageMap.get(pr.Id)[0].summary;
				PROCESS_REQUEST_EXCEPTION.description = servResp.messageMap.get(pr.Id)[0].detail;
				
				exService.setException(pr, PROCESS_REQUEST_EXCEPTION);
				
			}else{
				completedRequests.add(new Process_Request__c(Id = pr.Id));
			}
		}
    	
		if(completedRequests.size() > 0){
			DML.deleteAsSystem( completedRequests );
		}
		
		if(failedRequests.size() > 0){
			DML.updateAsSystem( failedRequests );
		}
		
		exService.finishTasks();
		
		return processResult;
	}
	
}