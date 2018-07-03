public with sharing class ProcessService {
	
	public class Response{
		public State state;
		//Not needed - can be deprecated
		public Step__c step;
	}
		
	public interface Action{
		//Response execute(Step__c step, State processState, List<sObject> records);
		Response execute(State processState, List<sObject> records);
		
	}
	
	public interface State{} //Empty interface to deliver contextual variables specific to the processor
	
	public void init(Process.ProcessFlow flow, List<sObject> records){
		
		List<Criteria__c> entryCriteria = flow.criteria;							
		
		List<Process.Step> steps = flow.steps; 
		
		//Exit if no steps exist
		if(steps == null || steps.size() == 0) return;
								
		Map<Id, Step__c> mSteps = new Map<Id, Step__c>();//steps
		
		List<Criteria__c> criteria = new List<Criteria__c>();
		if(entryCriteria != null){
			criteria.addAll(entryCriteria);
		}
		for(Process.Step s : flow.steps){
			if(s.criteria != null){
				criteria.addAll(s.criteria);
			}
		}						
		
		//Map<Id, sObject> mCriteriaRecs = returnCriteriaEvalRecs(flow.proc, criteria, records);
		//records = mCriteriaRecs.values(); // Why are the before insert/update values being replaced by old records ???
		//system.debug('mCriteriaRecs: ' + mCriteriaRecs);
		system.debug('records: ' + records);
		
		// grep the list of records as those resuming or qualified to enter
		Map<String, sObject> processRecords = new Map<String, sObject>(); //TODO:  Make this a map of index -> record
		//List<sObject> processRecords = new List<sObject>(); //TODO:  Make this a map of index -> record
		for(Integer i=0; i < records.size(); i++){
			//sObject rec = records[i].Id == null ? records[i].clone(true, true) : mCriteriaRecs.get(records[i].Id);
			sObject rec = records[i].clone(true, true);	
			Id iObjectStepId;
			if(rec.get(flow.proc.object_step__c) instanceOf Id){
				iObjectStepId = (Id)rec.get(flow.proc.object_step__c);
			}
			
			//Check entry criteria for records that are new to the process
			if(iObjectStepId == null){
				//if(!CriteriaService.evaluateCriteria(entryCriteria, mCriteriaRecs.get(rec.Id))){
				if(CriteriaService.evaluateCriteria(entryCriteria, rec)){
					processRecords.put(''+ ProcessHandler.currentDispatch.hashCode() + i, rec);
					//processRecords.add(rec);
					// Remove the record from trigger records if it is being processed.
					//ProcessHandler.processedRecordsMap.put(''+ ProcessHandler.currentDispatch.hashCode() + i, rec);
				}			
			}else if(mSteps.containsKey(iObjectStepId)){
				//add records that have already started on the process, regardless of their entry criteria
				processRecords.put(''+ ProcessHandler.currentDispatch.hashCode() + i, rec);// Q: How can a record enter this loop? is the process called twice? 
										 //    Multiple steps from different processes executes at the same time ?
				//processRecords.add(rec);
				
				// Remove the record from trigger records if it is being processed.
				//ProcessHandler.processedRecordsMap.put(''+ ProcessHandler.currentDispatch.hashCode() + i, rec);
				
			}
		}
		
		//Create a shared state context for this process
		ProcessService.State state = createState(flow.proc.State__c);
		
		//Check final sequence number - default to zero if no steps are found
		decimal termSeq = steps.size() > 0 ? steps[steps.size() -1].step.sequence__c : 0;
		
		for(Process.Step s : steps){
			system.debug('step: ' + s);
			List<sObject> actionRecs = new List<sObject>();
			for(String recordKey : processRecords.keySet()){
			//for(SObject rec : processRecords){	
				SObject rec = processRecords.get(recordKey);
				//system.debug(LoggingLevel.INFO, 'Criteria record: ' + rec);
				//Check resuming process - if process is open to be resumed by step sequence number
				boolean isOpen = true;
				Id iObjectStepId;
				if(rec.get(flow.proc.object_step__c) instanceOf Id){
					iObjectStepId = (Id)rec.get(flow.proc.object_step__c);
				}
				if(flow.proc.object_step__c != null && flow.proc.object_step__c != '' && mSteps.containsKey(iObjectStepId)){
					isOpen = CriteriaService.evaluateOpenProcess(mSteps.get(iObjectStepId), s.step);
				}
				//boolean isValid = CriteriaService.evaluateCriteria(s.Criteria__r, mCriteriaRecs.get(rec.Id));
				boolean isValid = CriteriaService.evaluateCriteria(s.criteria, rec);
				
				system.debug('isValid: ' + isValid);
				system.debug('isOpen: ' + isOpen);
				
				if(isValid && isOpen){
					actionRecs.add(rec);
					ProcessHandler.processedRecordsMap.put(recordKey, rec);
				}	
							
			}
			
			//Deliver records in bulk to relevant step
			if(actionRecs.size() > 0){
				boolean actionSuccess = true;
				for(Action__c a : s.actions){
					try{
						system.debug('Performing Action: ' + a.Id + ' - ' + a.action__c);
						system.debug('Action record scope: ' + actionRecs);
						Action action = createAction(a.action__c);
						Response resp = action.execute(state, actionRecs);
						//system.debug('state: ' + state);
						state = resp.state;
						//Let eval criteria drive which steps are relevant based on actions
						//When complete, the next step from the outer loop is considered for other resuming processes that fit the entry criteria
					}catch(Exception ex){
						actionSuccess = false;
						Notify.chatterOnMe(this, new List<Notify.Message>{new Notify.Message('Process Action Failure: ' + a.name, ex.getMessage())});
					}
				}
				
				for(sObject rec : actionRecs){
					if(flow.proc.object_step__c != null && flow.proc.object_step__c != '' 	
							 && s.step.Sequence__c < termSeq && actionSuccess){ //&& actionSuccess
						//Store this step as last successfully completed
						rec.put(flow.proc.object_step__c, s.step.Id);
					}else if(s.step.Sequence__c == termSeq && actionSuccess) { // && actionSuccess
						//End of process - clear the last step
						rec.put(flow.proc.object_step__c, null);
					}
				}
			}
			//system.debug('loop end records: ' + records);
			
		}						
		
		//KNDY#4590(Added Auto Update Flag on Process Custom Setting. Please mark it as true if you want to update the records.)
		if(flow.proc.bulk__c || 
				(flow.proc.Auto_Update__c && flow.proc.automated__c && flow.proc.after__c && (flow.proc.insert__c || flow.proc.update__c))){
			system.debug(LoggingLevel.INFO, 'update process end records for bulk and  after insert/update: ' + records);
			DML.updateAsSystem(processRecords.values());
		}
	}	
	
	
	/* Utility Functions */
	
	private Map<Id, sObject> returnCriteriaEvalRecs(Process__c p, List<Criteria__c> criteria, List<sObject> records){
		system.debug('criteria: ' + criteria);
		set<string> fieldPaths = new set<string>();
		if(p.object_step__c != null && p.object_step__c !=''){
			fieldPaths.add(p.object_step__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),''));
		}
		fieldPaths.addAll(CriteriaService.returnQueryFields(records[0]));
		for(Criteria__c c : criteria){
			if(c.field__c != null && c.field__c != ''){
				fieldPaths.add(c.field__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),''));
			}
			
			if(c.value_field__c == 'Field' && c.reference__c != null && c.reference__c != ''){
				fieldPaths.add(c.reference__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),''));
				//fieldPaths.add(c.field_reference__c.toLowerCase());
			}
		}
		
		/*string query = 'SELECT ';
		query += string.join(new List<string>(fieldPaths), ', ');
		query += ' FROM ' + p.object__c + ' WHERE Id IN :records';
		system.debug('query: ' + query);*/
		
		SOQLUtil soql = new SOQLUtil(p.Object__c);
	    soql.addFields(fieldPaths);
	    soql.setWhereClause('Id IN :records');
	    
		List<sObject> criteriaRecs = Database.query(soql.getQuery());
		Map<Id, sObject> mRecs = new Map<Id, sObject>(criteriaRecs);
		
		return mRecs;
	}
	
	private ProcessService.Action createAction(string stepActionName){
		Type t = Type.forName(stepActionName);
		//TODO: Namespace considerations
		ProcessService.Action retAction = (ProcessService.Action)t.newInstance();
		return retAction;
	}
	
	private ProcessService.State createState(string stateName){
		Type t= Type.forName(stateName);
		//TODO: Namespace considerations
		ProcessService.State retState = (ProcessService.State)t.newInstance();
		return retState;
	}
	
	/*
	set<string> returnQueryFields(sObject sObj){
		map<string,object> objmap = (map<string,object>) Json.deserializeuntyped(JSON.serialize(sObj));
		system.debug('objMap.keySet(): ' + objMap.keySet());
		//Cleanup
		objMap.remove('attributes');
		return objMap.keySet();
	}
	*/
}