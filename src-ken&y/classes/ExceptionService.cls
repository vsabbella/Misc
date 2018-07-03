public with sharing class ExceptionService {
	
	public static SchemaUtil sUtil = SchemaUtil.getInstance();
	private static string namespaceUU { get {  return  String.isNotBlank(sUtil.namespace)  ? sUtil.namespace+'__' : '' ; } }
	
	
	
	public static Set<String> ignoreSet = new Set<String>();
	public static Set<Map<String, String>> messages { 
		get{
			if(messages== null){
				messages = new Set<Map<String, String>>();	
			}
			return messages;
		}
		set; 
	}
    
    public static Boolean hasErrors {
        get{
        	return (hasMessages(MessageUtil.Severity.ERROR.name()) || hasMessages(MessageUtil.Severity.FATAL.name()));
        }
    }
    
    public static Boolean hasMessages(String severityName) {
        for (Map<String, String> msg : messages) {
            if (msg.get('severity') == severityName) {
               return true;
            }
        }
        return false;
    }
    
    public static Integer maxSeverityLevel {
    	get{
    		Map<String, Integer> levelMap = new Map<String, Integer>();
    		for(MessageUtil.Severity sev : MessageUtil.Severity.values()){
    			levelMap.put(sev.name(), sev.ordinal());
    		} 
    		
    		Integer maxLevel = 0;
    		for (Map<String, String> msg : messages) {
    			String severityName = msg.get('severity');
	            if ( maxLevel < levelMap.get(severityName)) {
	               maxLevel = levelMap.get(severityName);
	            }
	        }
	        return maxLevel;
    	}
    }
        
	// Exceptions will be added to this list to get processed and upserted into the system.
	private List<ExceptionWrapper> exceptionWrappers = new List<ExceptionWrapper>();
	
	private class ExceptionWrapper {
		SObject record;
		Task exceptionTask = new Task();
		
		ExceptionWrapper(SObject record, Task exceptionTask){
			this.record = record;
			this.exceptionTask = exceptionTask;
		}
		
	}
    public static string ExceptionSeverity{
         	
     get{
    	Map<integer,string> mapMessageSeverityString=new Map<integer,string>{0 => 'CONFIRM', 1 => 'INFO', 2 => 'WARNING', 3 => 'ERROR', 4 => 'FATAL'};
    	
		return mapMessageSeverityString.get(maxSeverityLevel);
	   
      }
      
    }

	public static Boolean ignoreTrigger (String sobjectName) {
		return ignoreSet.contains(sobjectName);
	}

	public Boolean hasOpenException(Id documentId, List<Task> existingTasks){

		for(ExceptionWrapper exWrapper: exceptionWrappers) {
			
			if(exWrapper.record != null && 
			   exWrapper.record.Id == documentId && 
			   exWrapper.exceptionTask.Status.equals(TaskType.EXCEPTION_STATUS_OPEN) &&
			   !isExceptionOverriden(existingTasks, exWrapper.exceptionTask.Exception_Code__c)){

				return true;
			}
		}

		return false;
	}

	private Boolean isExceptionOverriden(List<Task> existingTasks, String exceptionCode){

		if(existingTasks != null && existingTasks.size()> 0){

			for(Task task: existingTasks) {

				if(exceptionCode.equals(task.Exception_Code__c) && task.Status.equals(TaskType.EXCEPTION_STATUS_OVERRIDDEN)){
					return true;
				}
			}
		}

		return false;
	}

    public Boolean isExceptionClosed(Id documentId, String code){
        for(ExceptionWrapper exWrapper: exceptionWrappers) {

            if(exWrapper.record != null &&
               exWrapper.record.Id == documentId &&
               exWrapper.exceptionTask.Exception_Code__c == code &&
               exWrapper.exceptionTask.Status.equals(TaskType.EXCEPTION_STATUS_CLOSED)){

                return true;
            }
        }

        return false;

    }

	/**
		Returns TRUE, if an OPEN task exists for given source document and exception code
	*/	
	public static Boolean hasOpenTask(Id documentId, String code) {
		Task[] tasks = fetchTasks(new Set<Id>{documentId}, code, TaskType.EXCEPTION_STATUS_OPEN);
		
		return tasks != null && tasks.size() > 0;
	}

	/**
		Returns a Mapping of ExceptionIds clubbed by Document Ids i.e.
		K: WhatId
		V: Set<Task> Exception Tasks
		
	*/
	public static Map<Id, Set<Task>> fetchExceptionTasks(Set<Id> documentIds) {
	    Map<Id, Set<Task>> exceptionsByWhatId = new Map<Id, Set<Task>>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Task', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Subject','Status','Exception_Code__c','Description','WhatId'
		});
		String sStatus = TaskType.EXCEPTION_STATUS_OPEN;
		soql.setWhereClause('WhatId IN :documentIds AND Status =:sStatus AND WhatId != null AND Type = \'Exception\'');
		for(Task t : Database.query(soql.getQuery())) {
		    Set<Task> tsks = exceptionsByWhatId.get(t.WhatId);
		    if (tsks == null) {
		        tsks = new Set<Task>();
		        exceptionsByWhatId.put(t.WhatId, tsks);
		    }
	        tsks.add(t);
		}
		return exceptionsByWhatId;
	}
	
	/**
		Fetchs tasks for given source documents with matching status and exception codes
	*/
	public static Task[] fetchTasks(Set<Id> documentIds, String code, String status) {
	    return fetchTasks(documentIds, new Set<String>{ code }, status);
	}
	
	/**
		Fetchs tasks for given source documents with matching status and exception codes
	*/
	public static Task[] fetchTasks(Set<Id> documentIds, Set<String> codes, String status) {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Task', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Exception_Code__c','WhatId'
		});
		soql.setWhereClause('WhatId IN :documentIds AND Status = :status AND Exception_Code__c IN :codes');
		return Database.query(soql.getQuery());
	}
	
	public static Task[] fetchTasks(Set<Id> documentIds, Set<String> codes, Set<String> statuses) {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Task', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Exception_Code__c','WhatId'
		});
		soql.setWhereClause('WhatId IN :documentIds AND Status IN :statuses AND Exception_Code__c IN :codes');
		return Database.query(soql.getQuery());
	}

	/**
	*   Creates a new task with "Open" status.
	*/
	public void setException(SObject record, TaskType exType){
	    addException(record, exType, TaskType.EXCEPTION_STATUS_OPEN);
	}
	
	
	/**
	*   Updates an existing task with "Closed" status.
	*/
	public void clearException(SObject record, TaskType exType){
		addException(record, exType, TaskType.EXCEPTION_STATUS_CLOSED);
	}
	
	
	/**
	*	Creates a value holder for task that needs to be upserted and adds it to the list of tasks to be processed.
	*/
	private void addException(SObject record, TaskType exType, String status) {
		Task newTask = new Task();
	    newTask.Count_Field_API_Name__c = exType.countFieldAPIName;
	    newTask.Description = exType.description;
	    newTask.Exception_Code__c = exType.code;
		
		//KNDY-7410, KNDY-7498
		//boolean hasHistorical = record.getSobjectType().getDescribe().fields.getMap().containsKey('historical__c');
		boolean hasHistorical = record.getSobjectType().getDescribe().fields.getMap().containsKey(namespaceUU.toLowerCase()+'historical__c');
		
		
		//FIN-385/511
		//boolean hasHistorical = fieldsMap.containsKey('historical__c');
	    
	    if(hasHistorical){
	    	try{
		    	if((boolean)record.get('historical__c')){
		    		return;
		    	}
	    	}catch(exception ex){ /*do nothing*/ }
	    }
	    
	    if(Assignment__c.getInstance(exType.code) != null) {
	    	String userField = Assignment__c.getInstance(exType.code).Assigned_To_Field__c;
	    	if(!String.isBlank(userField)) {
	    		if(!String.isBlank(AccountingRuleService.getValue(userField, record))) {
	    			newTask.Default_Owner__c = (Id) AccountingRuleService.getValue(userField, record);
	    		}
	    	}
	    }
	    
	    if(exType.assignedTo != null){
	    	newTask.OwnerId =  exType.assignedTo;
	    }
	    
	    newTask.Status = status;
	    newTask.Subject = exType.label;
	    newTask.Type = exType.typeName;
	    newTask.Prohibit_Override__c = exType.ProhibitOverride;
	    
	    DescribeSObjectResult recordDescribe = record.getSObjectType().getDescribe();
	    if(TaskType.childToParentMap.containsKey(recordDescribe.getLocalName())) {
	   	    String headerField = TaskType.childToParentMap.get(recordDescribe.getLocalName());

			//KNDY-7410, KNDY-7498
			//boolean hasHeaderField = recordDescribe.fields.getMap().containsKey(headerField);
		    boolean hasHeaderField = recordDescribe.fields.getMap().containsKey(namespaceUU.toLowerCase()+headerField);
		    
		    
		    if(hasHeaderField) {
		    	if(record.get(headerField) != null) {
		    		newTask.Source_Document_Id__c = (String) record.get(headerField);
		    		newTask.Source_Document_Name__c = (String) record.getSObject(headerField.replace('__c','__r')).get('Name');
		    	}
		    }
	    }
	    
	    
	    
	    // Do not upsert the task here, add it to the list.
	    exceptionWrappers.add(new ExceptionWrapper(record, newTask));
	    
	    // Convert task to message and add it to the list of messages.
	    if(status == TaskType.EXCEPTION_STATUS_OPEN){
	    	String recordName;
	    	String recordId;
	    	try{
	    		// Try to get the name of the sobject record
	    		recordName = String.valueOf(record.get('Name'));
	    	}catch(System.SObjectException ex){
	    		recordName = '';
	    	}
	    	
	    	try{
	    		// Try to get the name of the sobject record
	    		recordId = String.valueOf(record.get('Id'));
	    	}catch(System.SObjectException ex){
	    		recordId = '';
	    	}
	    	
			addMessage(newTask, recordName, recordId);
		}
	}
	
	public static void addMessage(Task tsk, String recordName, String recordId){
		String summary = String.isBlank(recordName) ? tsk.Subject : recordName + ': ' + tsk.Subject;
		
		if (tsk.Type == 'Exception') {
	        addMessage(MessageUtil.Severity.ERROR.name(), summary, tsk.Description, recordName, recordId);
	    }else{
	    	addMessage(MessageUtil.Severity.WARNING.name(), summary, tsk.Description, recordName, recordId);
	    }
	}
	
	public static void addMessage(String severityLevel, String summary, String details, String recordName, String recordId){
		messages.add(
			new Map<String, String>{                    
			    'message' => summary,
			    'severity' => severityLevel,
			    'details' => details,
			    'recordName' => recordName,  //OTC-677
			    'recordId' => recordId                 
			}
        );
	}
	public static void addMessage(String severityLevel, String summary, String details){
		messages.add(
			new Map<String, String>{                    
			    'message' => summary,
			    'severity' => severityLevel,
			    'details' => details,
			    'recordName' => '',
			     'recordId' => ''               
			}
        );
	}
	
	public static void removeMessage(Task tsk){
		if (! String.isBlank(tsk.Subject)) {
	        removeMessage(tsk.Subject, String.valueOf(tsk.whatId));
	    }
	}
	
	public static void removeMessage(String summary, String recordId){
		
		for(Map<String, String> msg : ExceptionService.messages){
			if(msg.get('recordId') != null && msg.get('recordId').equals(recordId))  
			{
				String message =  String.isBlank(msg.get('recordName')) ? summary : msg.get('recordName')+': '+summary; //OTC-677
				system.debug('Message --> '+message);
				if(message.equals(msg.get('message'))){
					ExceptionService.messages.remove(msg);
					system.debug('after removing --> '+ExceptionService.messages);
				}
			}
			
		}
	}
	
	public Set<String> newExceptionCodes {
		get {
			Set<String> codes = new Set<String>();
			for(ExceptionWrapper ew : exceptionWrappers) {
				codes.add(ew.exceptionTask.Exception_Code__c);
			}
			
			return codes;
		}
		set;
	}
	
	public Set<String> newOpenExceptionCodes {
		get {
			Set<String> codes = new Set<String>();
			for(ExceptionWrapper ew : exceptionWrappers) {
				if(ew.exceptionTask.Status == TaskType.EXCEPTION_STATUS_OPEN) {
					codes.add(ew.exceptionTask.Exception_Code__c);
				}
			}
			
			return codes;
		}
		set;
	}
	
	public Set<String> exceptionsAlreadyOverridden;
	public Set<String> newExceptionsAlreadyOverridden (Set<Id> documentIds, Set<String> statuses) {
		exceptionsAlreadyOverridden = new Set<String>();
		Task[] tasks = fetchTasks(documentIds, newExceptionCodes, statuses);
		
		for(Task t : Tasks) {
			exceptionsAlreadyOverridden.add(''+t.WhatId+t.Exception_Code__c);
		}

		return exceptionsAlreadyOverridden;
		
	}
	
	
	public Integer newOpenExceptionCount(Set<Id> documentIds) {
		integer i = 0;
		for(ExceptionWrapper ew : exceptionWrappers) {
			if(documentIds.contains(ew.record.Id) && ew.exceptionTask.Status == TaskType.EXCEPTION_STATUS_OPEN && !exceptionsAlreadyOverridden.contains(''+ew.record.Id+ew.exceptionTask.Exception_Code__c)) {
				i++;
			}
		}
		return i;
		
	}
	
	public Map<Id,Set<String>> newOpenExceptionCodesPerRecord;
	
	public Map<Id,Integer> taskExceptionsPerRecord {
		get {
			Map<Id,Integer> taskExceptionsCount = new Map<Id,Integer>();
			newOpenExceptionCodesPerRecord = new Map<Id,Set<String>>();
			//PTP-98 Supplier Invoice Exception handling
			//Map of Exception code to Exception wrapper list is created 
			Map<String, List<ExceptionWrapper>> ExceptionWrapperMap = new Map<String, List<ExceptionWrapper>>();
			
			for(ExceptionWrapper ew : exceptionWrappers) {
				if(ew.exceptionTask.Type == 'Exception'){
					List<ExceptionWrapper> exceptionWrapperList = new List<ExceptionWrapper>();
					if (!ExceptionWrapperMap.containsKey(ew.exceptionTask.Exception_Code__c)){
						exceptionWrapperList.add(ew);
						ExceptionWrapperMap.put(ew.exceptionTask.Exception_Code__c, exceptionWrapperList.clone());
					}
					else{
						exceptionWrapperList = ExceptionWrapperMap.get(ew.exceptionTask.Exception_Code__c);
						exceptionWrapperList.add(ew);
						ExceptionWrapperMap.put(ew.exceptionTask.Exception_Code__c, exceptionWrapperList.clone());
					}	
				}
			}
			
			//Logic has been modified to loop through all the exceptions per exception code based on the map created above
			for (String exceptionCode : ExceptionWrapperMap.keyset()){
				string exceptionKey = '';
				for(ExceptionWrapper ew : ExceptionWrapperMap.get(exceptionCode)) {
					if(!taskExceptionsCount.containsKey(ew.record.Id)) {
						taskExceptionsCount.put(ew.record.Id,0);
					}

					if(ew.exceptionTask.Status == TaskType.EXCEPTION_STATUS_OPEN && !exceptionsAlreadyOverridden.contains(''+ew.record.Id+ew.exceptionTask.Exception_Code__c)) {
							exceptionKey = ew.record.Id + exceptionCode;
						if(!taskExceptionsCount.containsKey(ew.record.Id)) {
							taskExceptionsCount.put(ew.record.Id,1);
						}
						else {
							taskExceptionsCount.put(ew.record.Id,taskExceptionsCount.get(ew.record.Id)+1);
						}
						
						if(!newOpenExceptionCodesPerRecord.containsKey(ew.record.Id)) {
							newOpenExceptionCodesPerRecord.put(ew.record.Id,new Set<String>{exceptionCode});
						}
						else {
							newOpenExceptionCodesPerRecord.get(ew.record.Id).add(exceptionCode);
						}
					} //Reset the exeption if the task is closed for the same record
					else if(ew.exceptionTask.Status == TaskType.EXCEPTION_STATUS_CLOSED){
						if ((taskExceptionsCount.get(ew.record.Id) > 0) && (ew.record.ID + exceptionCode == exceptionKey)){
							taskExceptionsCount.put(ew.record.Id,taskExceptionsCount.get(ew.record.Id)-1);
						}
					}
					
				}
			}
			return taskExceptionsCount;
		}
	}
	
	/**
	*	Runs the upsert DML statement for exceptions generated.
	*/
	public list<Database.UpsertResult> finishTasks(){
		return finishTasks(true);
	}
	
	/**
	*	Loop through the wrapper and find the record id to associate the task with.
	*	This is needed to associate the records that have not yet been inserted into the database but have exceptions.
	*/
	public list<Database.UpsertResult> finishTasks(Boolean doUpsert){
		list<Database.UpsertResult> results = new List<Database.UpsertResult>();
		list<Database.UpsertResult> resultsToReturn = new List<Database.UpsertResult>();
		Map<String, Task> upsertTasksMap = new Map<String, Task>();
		
		// Set "Related To" and "Primary Key" fields on the tasks.
		for(ExceptionWrapper exWrapper : exceptionWrappers){
			exWrapper.exceptionTask.WhatId = exWrapper.record.Id;
			exWrapper.exceptionTask.Primary_Key__c = '' + exWrapper.exceptionTask.WhatId + exWrapper.exceptionTask.Exception_Code__c;
			upsertTasksMap.put(exWrapper.exceptionTask.Status + exWrapper.exceptionTask.Primary_Key__c, exWrapper.exceptionTask);
		}

		
		// Upsert using the "Primary_Key__c" external id.
		if(doUpsert && upsertTasksMap.values().size() > 0){
			List<Task> upsertList = new List<Task>();
			
			// KNDY-5129
			for(Task tsk : upsertTasksMap.values()){
				upsertList.add(tsk);
				if(upsertList.size() == Limits.getLimitDMLRows()){
					DML.upsertAsSystem(); results.addAll(Database.upsert(upsertList, Schema.Task.Primary_Key__c, false));
					upsertList.clear();
					break;
			    }  
			}
			
			if(upsertList.isEmpty() == false){
				DML.upsertAsSystem(); results.addAll(Database.upsert(upsertList, Schema.Task.Primary_Key__c, false)); 
			}
			
			// Check if the exceptions are upserted succesfully.
			// If the record failed to upsert, remove the error message from the messsages set.
			for(Task tempTsk : upsertTasksMap.values()){
				// Task Id will not be populated if the upsert failed.
				if(tempTsk.Status == TaskType.EXCEPTION_STATUS_OPEN && String.isBlank(tempTsk.Id)){
					System.debug(LoggingLevel.DEBUG, 'Removed task:'+tempTsk);
					removeMessage(tempTsk);
				}
			}
		}
		
		if(!results.isEmpty()){
			set<string> setValidationRule = new set<string>{'This Exception Task cannot be overridden.','Only exception tasks can be overridden.',
			                                                'You must enter an exception code.','Invalid status. Exception is not open.'};
			for(Database.UpsertResult result: results){
				if(!result.isSuccess() && !(result.getErrors()).isEmpty()){
					for(Database.Error error: result.getErrors()){
						if(error.getMessage() != null && error.getMessage() != ''){
							string errMsg = error.getMessage();
							if(!setValidationRule.contains(errMsg)){
								resultsToReturn.add(result);
							}
						}
					}
				}
			}
		}
		
		// Reset the isRunning flag to allow other code to set exceptions
		exceptionWrappers.clear();
		return resultsToReturn;
	}

	/**
	*	Legacy Method - KNDY-19955
	*/
	public List<Task> finish(){
		return finish(true);
	}

	/**
	*	Legacy Method - KNDY-19955
	*/
	public List<Task> finish(Boolean doUpsert){

		Map<String, Task> upsertTasksMap = new Map<String, Task>();

		// Set "Related To" and "Primary Key" fields on the tasks.
		for(ExceptionWrapper exWrapper : exceptionWrappers){
			exWrapper.exceptionTask.WhatId = exWrapper.record.Id;
			exWrapper.exceptionTask.Primary_Key__c = '' + exWrapper.exceptionTask.WhatId + exWrapper.exceptionTask.Exception_Code__c;
			upsertTasksMap.put(exWrapper.exceptionTask.Status + exWrapper.exceptionTask.Primary_Key__c, exWrapper.exceptionTask);
		}


		// Upsert using the "Primary_Key__c" external id.
		if(doUpsert && upsertTasksMap.values().size() > 0){
			List<Task> upsertList = new List<Task>();
			List<Database.UpsertResult> results = new List<Database.UpsertResult>();

			// KNDY-5129
			for(Task tsk : upsertTasksMap.values()){
				upsertList.add(tsk);
				if(upsertList.size() == Limits.getLimitDMLRows()){
					DML.upsertAsSystem(); results.addAll(Database.upsert(upsertList, Schema.Task.Primary_Key__c, false));
					upsertList.clear();
				}
			}

			if(upsertList.isEmpty() == false){
				DML.upsertAsSystem(); results.addAll(Database.upsert(upsertList, Schema.Task.Primary_Key__c, false));
			}

			// Check if the exceptions are upserted succesfully.
			// If the record failed to upsert, remove the error message from the messsages set.
			for(Task tempTsk : upsertTasksMap.values()){
				// Task Id will not be populated if the upsert failed.
				if(tempTsk.Status == TaskType.EXCEPTION_STATUS_OPEN && String.isBlank(tempTsk.Id)){
					System.debug(LoggingLevel.DEBUG, 'Removed task:'+tempTsk);
					removeMessage(tempTsk);
				}
			}
		}

		// Reset the isRunning flag to allow other code to set exceptions
		exceptionWrappers.clear();

		return upsertTasksMap.values();
	}
	
	// Called from Task.trigger to update the "Exception" Count field on the "Related To" records
	public static void updateExceptionsCount(){
		List<sObject> objectsToUpdate = new List<sObject>();
	    Map<Id, Map<String, Decimal>> taskCountMap = new Map<Id, Map<String, Decimal>>();
	    Set<Id> whatIdSet = new Set<Id>();
	    
	    if(trigger.isAfter){
	        if(trigger.isInsert || trigger.isUpdate || trigger.isDelete){
	            
	        	List<Task> tasksToProcess = new List<Task>();
	        	if(trigger.new != null) {
	        		tasksToProcess = (List<Task>) trigger.new;
	        	}
	        	else if(trigger.old != null) {
	        		tasksToProcess = (List<Task>) trigger.old;
	        	}
	           
	            for(Task taskToCount : tasksToProcess){
	            	// OTC-460: Count only exceptions and warnings.
	            	if(taskToCount.Type == 'Exception' || taskToCount.Type == 'Warning'){
		            	if(String.isBlank(taskToCount.Exception_Code__c) == false
		            		&& String.isBlank(taskToCount.WhatId) == false
		            	){
		            		Id recordId = taskToCount.WhatId;
		            		Schema.SObjectType objType = recordId.getSObjectType();
			                Schema.DescribeSObjectResult describeResult = objType.getDescribe();
			                String objName = describeResult.getName();
			                String namespace = objName.split('__').size() == 3 ? objName.split('__')[0]+'__' : '';
		            		
		            		String countFieldName = taskToCount.Count_Field_API_Name__c;                 	
						    
						    if(String.isBlank(countFieldName)){
						    	countFieldName = namespace + 'Exceptions_Count__c';
						    }
						    
		            	    whatIdSet.add(recordId);
		           		    
		           		    // By default, the count is zero.
		           		    if(taskCountMap.containsKey(recordId) == false){
		           		    	taskCountMap.put(recordId, new Map<String, Decimal>());
		           		    }
		           		    
		           		    if(taskCountMap.get(recordId).containsKey(countFieldName) == false){
		           		    	taskCountMap.get(recordId).put(countFieldName, 0);
		           		    }
		            	}
	           		}
	            }
	        }
	        
	        if(whatIdSet.size() > 0){

	            // Construct a map from record Ids to the number of open exceptions/tasks
				// KNDY-6563 Add limit to select	            
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Task', true, true); //enforceFLS=true, running in user mode.  aggregate query = true
				soql.addFields(new set<string>{
					'COUNT(Id)','WhatId','Count_Field_API_Name__c'
				});
				soql.setWhereClause('WhatId IN :whatIdSet AND Type IN (\'Exception\', \'Warning\') AND Status = \'Open\' GROUP BY WhatId, Count_Field_API_Name__c');
				soql.setLimit(5000);
				for (AggregateResult ar : Database.query(soql.getQuery())) {
				    Id recordId = (Id) ar.get('WhatId');
            		Schema.SObjectType objType = recordId.getSObjectType();
	                Schema.DescribeSObjectResult describeResult = objType.getDescribe();
	                String objName = describeResult.getName();
	                String namespace = objName.split('__').size() == 3 ? objName.split('__')[0]+'__' : '';
	                
				    String countFieldName = (String) ar.get(KSE.NamespaceUU + 'Count_Field_API_Name__c');                 	
				    
				    if(String.isBlank(countFieldName)){
				    	countFieldName = namespace + 'Exceptions_Count__c';
				    }
				    Task existingTask = new Task(
				    						WhatId = recordId, 
				    						Count_Field_API_Name__c = countFieldName
				    					);
				    
				    if(taskCountMap.containsKey(recordId) == false){
           		    	taskCountMap.put(recordId, new Map<String, Decimal>());
           		    }
           		    
           		    if(taskCountMap.get(recordId).containsKey(countFieldName) == false){
           		    	taskCountMap.get(recordId).put(countFieldName, 0);
           		    }
           		    
           		    taskCountMap.get(recordId).put(countFieldName, Integer.valueOf(ar.get('expr0')));					
	            }
	            
	            // Populates exception count with the number of tasks associated with the record
	            for (Id recordId : taskCountMap.keySet()) {
	            	
	                Schema.SObjectType objType = recordId.getSObjectType();
	                Schema.DescribeSObjectResult describeResult = objType.getDescribe();
	                
	                SObject obj = objType.newSObject(recordId);
	                
                    for(String countFieldName : taskCountMap.get(recordId).keySet()){
                    	obj.put(countFieldName, taskCountMap.get(recordId).get(countFieldName));
	                }
                    objectsToUpdate.add(obj);
	                
	                // Add the object to the ignoreSet
	                ignoreSet.add(describeResult.getLocalName());
	            }
	            
	            if (objectsToUpdate.size() > 0){
                    DML.updateSobjectList( objectsToUpdate );
	                ignoreSet.clear();
	            }
	        }
	    }
	}
	
	
	/*
	*	Validate exceptions
	
	public static void validateExceptions(){
		if(trigger.isBefore){
	        if(trigger.isInsert || trigger.isUpdate){
	        	for(Task exceptionTask : (List<Task>) trigger.new){
	            	if(exceptionTask.Type == 'Exception'){
	            		if( (trigger.isInsert 
	            				&& exceptionTask.Status != ExceptionService.EXCEPTION_STATUS_OPEN
	            			) 
	            			|| 
	            			(trigger.isUpdate 
	            				&& ((Task)trigger.oldMap.get(exceptionTask.Id)).Status != ExceptionService.EXCEPTION_STATUS_OPEN 
	            				&& KSE.isFieldChanging('Status', exceptionTask, trigger.oldMap) 
	            			)
	            		){
	            			//exceptionTask.Status.addError('Invalid status. Exception is not open.');
	            		}
	            	}
	            }
	        }
		}
	}*/
	
	//Clears the primary key on closed tasks. 
	
	public static void setPrimaryKey(){
		if(trigger.isAfter){
			if(trigger.isInsert || trigger.isUpdate){
				List<Task> updatedTasks = new List<Task>();
				for(Task exceptionTask : (List<Task>) trigger.new){
	            	if(exceptionTask.Type == 'Exception'){
	            		if(exceptionTask.Status != TaskType.EXCEPTION_STATUS_OPEN && 
	            		   exceptionTask.Status != TaskType.EXCEPTION_STATUS_OVERRIDDEN &&
	            		   exceptionTask.Primary_Key__c != null){
	            			
	            			Task updateTask = new Task();
	            			updateTask.Id = exceptionTask.Id;
	            			updateTask.Primary_Key__c = null;
	            			updatedTasks.add(updateTask);
	            		}
	            	}
	            }
	            
	            if(updatedTasks.size() > 0){
	            	DML.updateAsSystem(updatedTasks);
	            }
			}
		}
	}
	
	//PTP-422
	public static Map<String,String> parentChildRelationships = new Map<String,String>{
		'Supplier_Invoice__c' => 'Supplier_Invoice_Line__c',
		'Receiving_Document__c' => 'Receipt_Line__c',
		'Purchase_Order__c' => 'Purchase_Order_Line__c',
		'Customer_Invoice__c' => 'Customer_Invoice_Line__c',
		'Supplier_Payment__c' => 'Supplier_Payment_Line__c',
		'Journal_Entry__c' => 'Journal_Entry_Line__c'};
	
	//Used to get a map of ALL child relationships for a given sObject
	public static Map<String,String> childObjectMap(sObject parentRecord) {

		Map<String,String> childMap = new Map<String,String>();

		if(parentRecord != null) {
			Schema.DescribeSObjectResult dsr = parentRecord.getSObjectType().getDescribe();
			List<Schema.ChildRelationship> childObjects = dsr.getChildRelationships(); 
			
			for(Schema.ChildRelationship child : childObjects) {
				Schema.DescribeFieldResult childDFR = child.getField().getDescribe();
				if(childDFR.isCustom()) {
					childMap.put(child.getChildSObject().getDescribe().getLocalName(),childDFR.getLocalName());
				}
			}
		}
		return childMap;
	}
	
	public static Set<Id> taskWhatIds (sObject parentRecord) {
		Set<Id>whatIds = new Set<Id>();
		Id parentId = (parentRecord != null && String.isNotBlank(parentRecord.Id)) ? parentRecord.Id : '';
        whatIds.add(parentRecord.Id);
        
        //Map<String,String> childMap = childObjectMap(parentRecord); //This uses all child objects for a give sObject
        String parentType = parentRecord.getSObjectType().getDescribe().getLocalName() ;
		
		if(parentChildRelationships.containsKey(parentType)) {
			//String query = 'SELECT Id, Name FROM ' + parentChildRelationships.get(parentType) + ' WHERE ' + parentType + ' = \'' + parentId + '\''; 
            
            String whereClause = parentType + ' = \'' + parentId + '\'';//KNDY-8796
            SOQLUtil soql = new SOQLUtil(parentChildRelationships.get(parentType),true);
            soql.addFields(new Set<String>{'Id', 'Name'});
            soql.setWhereClause(whereClause);
            
			//for(sObject obj : database.query(query)) {
            for(sObject obj : database.query(soql.getQuery())) {
				whatIds.add(obj.Id);
			}
		}
		

		return whatIds;
	}

    public static List<sObject> getTaskRelatedList(sObject parentRecord) {
        Set<Id> whatIds = taskWhatIds(parentRecord);

        string whereClause = 'WhatId IN :whatIds AND isClosed = false and Type = \'Exception\'';
        whereClause += ' ORDER BY CreatedDate DESC,Source_Document_Id__c DESC NULLS LAST,WhatId DESC ';
        
        //String queryString = sUtil.generateQueryFromFieldSet('Task', new Set<string>(), new set<string>(), whereClause);
        
        //KNDY-8796
        SOQLUtil soql = new SOQLUtil('Task');
        soql.addFields(new Set<String>{'Id'});
        soql.setWhereClause(whereClause);
        List<sObject> result = new List<sObject>();
        //result = database.query(queryString);   
        result = database.query(soql.getQuery());   
        return result;
    }
	
}