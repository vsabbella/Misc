global with sharing class ExceptionServiceAPI {
	
	private ExceptionService exService;
	
	// OTC-725
	global static boolean isCashAppRunning = false;
	
	global ExceptionServiceAPI(){
		 exService = new ExceptionService();
	}
	
	global static Boolean ignoreTrigger (String sobjectName) {
		return ExceptionService.ignoreTrigger(sobjectName);
	}
	
	/**
	*   Creates a new task with "Open" status.
	*/
	global void setException(SObject record, TaskType exType){
	    exService.setException(record, exType);
	}
	
	/**
	*   Updates an existing task with "Closed" status.
	*/
	global void clearException(SObject record, TaskType exType){
		exService.clearException(record, exType);
	}
	
	/*
	*	Runs the upsert DML statement for exceptions generated.
	*/
	global list<Database.UpsertResult> finishTasks(){
		return exService.finishTasks();
	}
	global list<Task> finish(){
		return exService.finish();
	}
	/**
	*	Loop through the wrapper and find the record id to associate the task with.
	*	This is needed to associate the records that have not yet been inserted into the database but have exceptions.
	*/
	global list<Database.UpsertResult> finishTasks(Boolean doUpsert){
		return exService.finishTasks(doUpsert);
	}

	global list<Task> finish(Boolean doUpsert){
		return exService.finish(doUpsert);
	}
}