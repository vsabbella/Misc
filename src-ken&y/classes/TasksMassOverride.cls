global with sharing class TasksMassOverride {
	
	private final ExceptionTasksExtNew ref;
	public TasksMassOverride(ExceptionTasksExtNew reference)
	{
		this.ref = reference;
	}
	
	public class TasksMassOverrideException extends Exception{}
	
	@RemoteAction
    global static JSONResult massOverrideTasks(list<Task> selectedTasks)
    {
    	JSONResult result = new JSONResult();
    	Boolean accExp    = false;
    	for(Task t: selectedTasks){
    		t.Status = 'Overridden';
    	    system.debug('Task---'+t.Exception_Code__c); 
    	  // Checking for Accounting related Exceptions-KNDY-12575
          if(t.Exception_Code__c.contains('AE') || t.Exception_Code__c.contains('AL') ){ 
              accExp = true;
          }	
    	}
    	
    	try
    	{
    		boolean anyErrors = false;
    		set<String> errors = new set<String>();
    		Database.SaveResult[] srList = DML.updateAsUser(selectedTasks, false);
    		
    		for (Database.SaveResult sr : srList) {
			    if (!sr.isSuccess()) {
			    	anyErrors = true;
			        // Operation failed, so get all errors                
			        for(Database.Error err : sr.getErrors()) {
			            System.debug('The following error has occurred.'+err.getMessage());                           
			            errors.add(err.getMessage());
			        }
			    }
			}
			
			if(anyErrors)
			{
				result.success = false;
				if(errors.size() == 1 && errors.contains('This Exception Task cannot be overridden.')){
					if(accExp){
 						result.addMessage('Accounting entry exceptions cannot be manually overridden',
                             				 ApexPages.Severity.Warning);
 					}else{
 						result.addMessage('These exceptions cannot be manually overridden.'+
 											'To resolve this exception, you must correct the condition that causes it.'+
 											'Please review the exception description for information on how it can be resolved.', 
 											 ApexPages.Severity.Warning);
 					}
				}
				else{
					throw new TasksMassOverrideException(String.join(new list<String>(errors),', '));
				}
			}
			else
			{
				result.success = true;
	    		result.records = selectedTasks;
		        result.total = selectedTasks.size();
		        result.addMessage('Selected Tasks have successfully been overridden', ApexPages.Severity.CONFIRM);
			}
    		
    		
    	}catch(Exception ex)
    	{
    		result.success = false;
    		result.addMessage(ex, ApexPages.Severity.ERROR);
    			
    		
    	}
    	
    	return result;
    }

}