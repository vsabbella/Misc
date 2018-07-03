public virtual with sharing class ServiceResponse {
    
    public Boolean isSuccess = false;
    public List<Object> records;
    
    public List<Message> messages = new List<Message>();
    public Map<Id, List<Message>> messageMap = new Map<Id, List<Message>>();
    
    public ServiceResponse(){
    	
    }
    
    public void addErrorMessage(String summary){
    	addMessage(Message.SEVERITY_ERROR, summary, '');
    }
    
    public void addErrorMessage(String summary, String detail){
    	addMessage(Message.SEVERITY_ERROR, summary, detail);
    }
    
    public void addWarningMessage(String summary){
    	addMessage(Message.SEVERITY_WARNING, summary, '');
    }
    
    public void addWarningMessage(String summary, String detail){
    	addMessage(Message.SEVERITY_WARNING, summary, detail);
    }
    
    public void addConfirmMessage(String summary){
    	addMessage(Message.SEVERITY_CONFIRM, summary, '');
    }
    
    public void addConfirmMessage(String summary, String detail){
    	addMessage(Message.SEVERITY_CONFIRM, summary, detail);
    }
    
    public void addFatalMessage(String summary){
    	addMessage(Message.SEVERITY_FATAL, summary, '');
    }
    
    public void addFatalMessage(String summary, String detail){
    	addMessage(Message.SEVERITY_FATAL, summary, detail);
    }
    
    public void addInfoMessage(String summary){
    	addMessage(Message.SEVERITY_INFO, summary, '');
    }
    
    public void addInfoMessage(String summary, String detail){
    	addMessage(Message.SEVERITY_INFO, summary, detail);
    }
    
    private void addMessage(String severity, String summary, String detail){
		Message message = new Message(severity, summary, detail);
		addMessage(message);    	
    }
    
    private void addMessage(Message message) {
    	messages.add(message);
    }
    
    public void addMessage(String recordId, Message message) {
    	if(messageMap.containsKey(recordId) == false){
    		messageMap.put(recordId, new List<Message>());	
    	}
    	messageMap.get(recordId).add(message);
    }
}