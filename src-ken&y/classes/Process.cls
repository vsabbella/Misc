global with sharing class Process {
	
	/*
	 This field is used to store the batch context, used in conjunction with iCustomAction
	*/
	global static Database.BatchableContext info;
	/* Runnable 
	 *  allow a class that implements runBatch() to be run as a kenandy scheduled job
	 */
   	global interface  Runnable {		// used by the MasterControlProgram.cls to run individual batch classes
		void runBatch( Id companyId );
	}
    global interface Runnable2 {
        void runBatch( Process_Job__c jobRecord );
    }
	/* Automate 
	 * pass the configuration and records which matched
	 * processor should check the field mentioned in the config
	 * and may or may not perform queries or DML as specified in the config record
	 */		
    global interface  Automate { 
		void processRecords( Process_Automation__c config, 	List<sobject> records );
	}
	
 	public class NameException extends Exception{}     
          
	public static final Map<String,Process_Configuration__c> configMap =	Process_Configuration__c.getAll();
	 
	/** 
	 * read the Process_Configuration__c data, return true if the object field contains one of the values
	 */
    public static boolean configSwitch( sobject so , string config_switch_name ) {
		boolean ret = false; 
		try {  	 
		 	Process_Configuration__c conf  = configMap.get(config_switch_name);
		 	
		 	if ( conf != null && conf.active__c == true ) {
		    	// field value may contain a comma sep list, break this out now
		    	set <string> valueSet = new set<string>( conf.field_value__c.split(',') );
		    	
		    	for ( string  st : valueSet ) {
		    		st = st.trim();   // trim unwanted spaces before we compare
			    	if  ( st.equalsIgnoreCase( (string)so.get( conf.Field_name__c ) ) ) { 
						ret = true;  
			    	}
	    		}
		 	}
		}catch( exception  e) {
			System.debug(LoggingLevel.ERROR, e.getMessage());
		}     	 
 		return ret;  
    }
    
    
   	
   	global static void callAutomationMethod( Process_Automation__c config, 
   																						list<Sobject>records) {	
   		if (records.size() == 0 ) 
   			return; 
   		
   		try {
			System.Type typ = Inspect.forName(config.Method_name__c );  
			if ( typ == null ) {
				throw new NameException( config.name + 
										 ' could not construct class by name :'+
										 config.Method_Name__c);
			}
			
			Automate pp = (Automate)typ.newInstance(); 
			if( pp == null ) 
				throw new NameException( config.name + 
										 ' could not create instance of class by name :'+
										 config.Method_Name__c);
			// do the processing															
			pp.processRecords( config, records ); 
    			 
		} catch( Exception  e) {
			
			// log the issue to Chatter, by catching this we isolate other methods 
			// from the failure of one 
			//System.debug(LoggingLevel.INFO, e);
			Notify.chatterOnMe( config, new List<Notify.Message>{ 
													new Notify.Message( e.getTypeName(), e.getMessage() ) } ); 
		} 
		
   	}
   	
   	/* 
   	 * if called from a trigger we could do 
   	 * new Inspect( objectName ).execute ( trigger.new );
   	 */
   	
   	/* @description execute the automation framework to call standard and custom code 
   	 * for these records 
   	 */
   	global static void executeAutomation( list<Sobject>records ) {
   		if ( records.size() == 0 ) return;
   		
   		string objectName = String.valueof( records[0].getSObjectType() );
   		
   		/* 
   		 * filter only records that are ready, even if user passed in "unready" records
   		 * also add all the fields we can to help out the automation code
   		 */
   		string query = ' select ' +
   								SchemaUtil.getInstance().getFieldsforQuery (objectName) + 
   								' from ' + objectName + 
   								' where Ready__c = true AND id in :records ';   		
   		
   		SOQLUtil soql = new SOQLUtil(objectName);
	    
	    Map<String, sObjectField> fieldsMap = SchemaUtil.getInstance().getFieldsMap(objectName);
	    soql.addFields(fieldsMap.keySet());
	    soql.setWhereClause('Ready__c = true AND id in :records');
	    
   		/* 
   		 * run all automation steps that are 
   		 * configured for this object type with these records
   		 */
   		new Inspect(objectName).execute( Database.query(soql.getQuery()) );
					
   	}  	
   	
   	/* -------------------- */
   	/* Process Flow Objects */
   	/* -------------------- */
   	
   	public class ProcessFlow implements Comparable{
   		
   		public Process__c proc {get;set;}
   		
   		public List<Step> steps {get;set;}
   		public List<Criteria__c> criteria {get;set;}
   		
   		public integer compareTo(object compare){
   			ProcessFlow compareProcessFlow = (ProcessFlow)compare;
   			if(proc.sequence__c == compareProcessFlow.proc.sequence__c){
   				return 0;
   			}else if(proc.sequence__c > compareProcessFlow.proc.sequence__c){
   				return 1;
   			}else{
   				return -1;
   			}
   		}
   	}
   	
   	public class Step implements Comparable{
   		
   		public Step__c step {get;set;}
   		public List<Criteria__c> criteria {get;set;}
   		public List<Action__c> actions {get;set;}
   		
   		public integer compareTo(object compare){
   			Step compareStep = (Step)compare;
   			if(step.sequence__c == compareStep.step.sequence__c){
   				return 0;
   			}else if(step.sequence__c > compareStep.step.sequence__c){
   				return 1;
   			}else{
   				return -1;
   			}
   		}
   	}
   	
   	public class Action implements Comparable{
   		
   		public Action(Action__c inAction){
   			action = inAction;
   		}
   		
   		public Action__c action {get;set;}
   		
   		public integer compareTo(object compare){
   			Action compareAction = (Action)compare;
   			if(action.sequence__c == compareAction.action.sequence__c){
   				return 0;
   			}else if(action.sequence__c > compareAction.action.sequence__c){
   				return 1;
   			}else{
   				return -1;
   			}
   		}
   	}
   	
   	public class Criteria implements Comparable{
   		
   		public Criteria(Criteria__c inCriteria){
   			criteria = inCriteria;
   		}
   		
   		public Criteria__c criteria {get;set;}
   		
   		public integer compareTo(object compare){
   			Criteria compareCriteria = (Criteria)compare;
   			if(criteria.number__c == compareCriteria.criteria.number__c){
   				return 0;
   			}else if(criteria.number__c > compareCriteria.criteria.number__c){
   				return 1;
   			}else{
   				return -1;
   			}
   		}
   	}
   	
   	
   	private static map<string, List<ProcessFlow>> mObjectFlows = new Map<string, List<ProcessFlow>>();
   	/*
   	* Description: this method returns either a cached instance of an objects process flows
   	*	or builds the process flows based upon the information stored in the custom settings
   	*/				
   	public static List<ProcessFlow> returnObjectFlows(string sObjectName){
   		
   		if(mObjectFlows.containsKey(sObjectName)){
   			
   			//Return the cached instance of the Process Flows for the object
   			return mObjectFlows.get(sObjectName);
   		}else{
   			
   			//Build all of the flows from the custom settings and store for later reference by object
   			Map<Id, List<Criteria__c>> mProcessCriteria = new Map<Id, List<Criteria__c>>(); //Process Id to Criteria
   			Map<Id, List<Criteria__c>> mStepCriteria = new Map<Id, List<Criteria__c>>(); //Step Id to Criteria
   			Map<Id, List<Step>> mSteps = new Map<Id, List<Step>>(); //Process Id to Steps
   			Map<Id, List<Action>> mActions = new Map<Id, List<Action>>(); //Step Id to Actions
   			
   			//Loop through all of the criteria, placing in maps by process or step
   			for(Criteria__c c : Criteria__c.getAll().values()){
   				if(c.Step__c != null && c.Step__c != ''){
   					if(mStepCriteria.containsKey(c.Step__c)){
   						mStepCriteria.get(c.Step__c).add(c);
   					}else{
   						mStepCriteria.put(c.Step__c, new List<Criteria__c>{c});
   					}
   				}else if(c.Process__c != null && c.Process__c != ''){
   					if(mProcessCriteria.containsKey(c.Process__c)){
   						mProcessCriteria.get(c.Process__c).add(c);
   					}else{
   						mProcessCriteria.put(c.Process__c, new List<Criteria__c>{c});
   					}
   				} 
   			}
   			
   			//Loop through the actions and place in a map by step
   			for(Action__c a : Action__c.getAll().values()){
   				if(mActions.containsKey(a.step__c)){
   					mActions.get(a.step__c).add(new Action(a));	
   				}else{
   					mActions.put(a.step__c, new List<Action>{new Action(a)});
   				}
   			}

   			//Loop through the steps, and join the information to criteria and actions where possible
   			for(Step__c s : Step__c.getAll().values()){
   				Step iStep = new Step();
   				iStep.step = s;
   				if(mStepCriteria.containsKey(s.Id)){
   					iStep.criteria = mStepCriteria.get(s.Id);
   				}else{
   					iStep.criteria = new List<Criteria__c>();
   				}
   				
   				if(mActions.containsKey(s.Id)){
   					List<Action> iActions = mActions.get(s.Id);
   					//Sort the actions, unpack from the wrapper and load the actions in sequence
   					iActions.sort();
   					iStep.Actions = new List<Action__c>();
   					for(Action a : iActions){
   						iStep.Actions.add(a.action);
   					}
   				}else{
   					iStep.Actions = new List<Action__c>();
   				}
   				
   				if(mSteps.containsKey(s.process__c)){
   					mSteps.get(s.process__c).add(iStep);
   				}else{
   					mSteps.put(s.process__c, new List<Step>{iStep});
   				}
   			}

   			//Loop through the processes, creating the process flows and joining the information to criteria and steps where possible
   			for(Process__c p : Process__c.getAll().values()){
   				if(p.object__c == sObjectName){
	   				ProcessFlow iProcessFlow = new ProcessFlow();
	   				iProcessFlow.proc = p;
	   				
	   				if(mProcessCriteria.containsKey(p.Id)){
	   					iProcessFlow.Criteria = mProcessCriteria.get(p.Id);
	   				}else{
	   					iProcessFlow.Criteria = new List<Criteria__c>();
	   				}
	   				
	   				if(mSteps.containsKey(p.Id)){
	   					List<Step> iSteps = mSteps.get(p.Id);
	   					iSteps.sort();
	   					iProcessFlow.steps = iSteps;
	   				}else{
	   					iProcessFlow.steps = new List<Step>();
	   				}
	   				
	   				//Place the newly built process flow in a map by object
	   				if(mObjectFlows.containsKey(p.object__c)){
	   					mObjectFlows.get(p.object__c).add(iProcessFlow);
	   				}else{
	   					mObjectFlows.put(p.object__c, new List<ProcessFlow>{iProcessFlow});
	   				}	
   				}
   			}
   			
   			return mObjectFlows.containsKey(sObjectName) ? mObjectFlows.get(sObjectName) : new List<ProcessFlow>();
   		}
   	}
   	
   	
}