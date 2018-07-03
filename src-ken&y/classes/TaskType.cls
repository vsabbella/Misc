global with sharing class TaskType {
		
	global static final String EXCEPTION_STATUS_OPEN = 'Open';
	global static final String EXCEPTION_STATUS_CLOSED = 'Closed';
	global static final String EXCEPTION_STATUS_OVERRIDDEN = 'Overridden';
	
	global static final Map<String,String> childToParentMap = new Map<String,String>{'Supplier_Invoice_Line__c'=>'Supplier_Invoice__c'};
	
	global String code {get; public set;}
	global String label {get; public set;}
	global String description {get; public set;}
	global String typeName {get; public set;}
	global String countFieldAPIName {get; public set;}
	global Id assignedTo {get; public set;}
	global Boolean ProhibitOverride {get; public set;}{prohibitOverride=false;}
	
	public TaskType(){ 
		
	}
	
	global TaskType(String code, String label, String description, String typeName, Id assignedTo){
		this(code, label, description, typeName, assignedTo, false);
	}
	
	global TaskType(String code, String label, String description, String typeName, Id assignedTo, Boolean ProhibitOverride){
		this(code, label, description, typeName, '', assignedTo, false);
	}
	
	global TaskType(String code, String label, String description, String typeName, String countFieldAPIName, Id assignedTo, Boolean ProhibitOverride){
		this.code = code;
		this.label = label;
		this.description = description;
		this.typeName = typeName;
		this.countFieldAPIName = countFieldAPIName;
		this.assignedTo = assignedTo;
		this.ProhibitOverride = ProhibitOverride;
	}
	
	
}