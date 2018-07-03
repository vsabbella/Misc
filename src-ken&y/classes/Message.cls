public with sharing class Message {
	
	// #JUSTDOIT Replace the strings with labels.
	public static final String SEVERITY_CONFIRM = 'CONFIRM';
	public static final String SEVERITY_ERROR = 'ERROR';
	public static final String SEVERITY_FATAL = 'FATAL';
	public static final String SEVERITY_INFO = 'INFO';
	public static final String SEVERITY_WARNING = 'FATAL';
    
    public String severity;
    public String summary;
    public String detail;
    
    public Message(String severity, String summary, String detail){
    	this.severity = severity;
    	this.summary = summary;
    	this.detail = detail;
    }
}