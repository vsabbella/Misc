public with sharing class ProcessResult extends ServiceResponse {
    
    public Boolean isSuccess = false;
    public List<Message> messages = new List<Message>();
    public Map<Id, List<Message>> messageMap = new Map<Id, List<Message>>();
    public List<SObject> records = new List<SObject>();
    
    public ProcessResult(){
    	
    }
    
    /*public ProcessResult(ServiceResponse response){
    	this.isSuccess = response.isSuccess;
    	this.messages = response.messages;
    	this.messageMap = response.messageMap;
    	this.records = (List<SObject>) response.records;
    }*/
    
}