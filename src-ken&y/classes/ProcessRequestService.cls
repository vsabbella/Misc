public interface ProcessRequestService {
    /*ProcessResult getStatus(String processRequestId);
    ProcessResult getStatus(List<String> processRequestIds);
    
    ProcessResult process(String processRequestId);
    ProcessResult process(String processCall, List<String> processRequestIds);
    
    ProcessResult process(Process_Request__c processRequest);*/
    ProcessResult process(String processCall, List<Process_Request__c> processRequests);
}