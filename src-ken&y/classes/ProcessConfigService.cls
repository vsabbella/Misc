public with sharing class ProcessConfigService {
	// Build a map for ProcessConfig?
	// During AddManageLines pass information to a function and see if it exists in the process config map.
	// IF the function returns true then render the segment on page else do not.
	
	
  	public static boolean configResult( String ObjName, string FieldValue, string lineValue, Boolean active) {
  		Map<String,Process_Configuration__c> configMap =	Process_Configuration__c.getAll();
  		Map<Process_Configuration__c,Process_Configuration__c> configMapNew = new Map<Process_Configuration__c,Process_Configuration__c>();
    	for(Process_Configuration__c pc: configMap.values()) {
    	if(pc.Active__c == true){
    	 		configMapNew.put(new Process_Configuration__c(Object_Name__c = pc.Object_Name__c, 
    	 												Field_Value__c = pc.Field_Value__c,
    	 												Line_Value__c = pc.Line_Value__c, 
    	 												Active__c = pc.Active__c 
    	 												),pc);
    	 	}
    	 }
	   	 if(configMapNew.containsKey(new Process_Configuration__c(Object_Name__c = ObjName, 
 																Field_Value__c = FieldValue,
 																Line_Value__c = lineValue,  
 																Active__c = true) )){
 																	
    	 		return true;
    	 }else{
    	 		return false;
    	 } 
    }
    
    public static boolean configResult( String ObjName, string FieldValue, Boolean active) {
  		return configResult(objName, fieldValue, null, active);
    }
	
}