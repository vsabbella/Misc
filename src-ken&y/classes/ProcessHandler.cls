public with sharing class ProcessHandler {
	
	public class ProcessHandlerException extends Exception{}
	public class ProcessToken{
		
		public final string sObjectName;
		public final boolean isBefore;
		public final boolean isAfter;
		public final boolean isInsert;
		public final boolean isUpdate;
		public final boolean isDelete;
		public final boolean isUndelete;
		
		public ProcessToken(string inSObjectName, boolean inIsBefore, boolean inIsAfter, boolean inIsInsert, boolean inIsUpdate, boolean inIsDelete, boolean inIsUndelete){
			sObjectName = inSObjectName;
			isBefore = inIsBefore;
			isAfter = inIsAfter;
			isInsert = inIsInsert;
			isUpdate = inIsUpdate;
			isDelete = inIsDelete;
			isUndelete = inIsUndelete;
			//system.debug('ProcessToken: ' + this);
		}
		
		//Defines uniqueness when comparing an apex class as key in sets or maps
		//http://www.salesforce.com/us/developer/docs/apexcode/Content/langCon_apex_collections_maps_keys_userdefined.htm
		public boolean equals(Object obj){
			ProcessToken compare = (ProcessToken)obj;
			if(sObjectName == compare.sObjectName
					&& isBefore == compare.isBefore
					&& isAfter == compare.isAfter
					&& isInsert == compare.isInsert
					&& isUpdate == compare.isUpdate
					&& isDelete == compare.isDelete
					&& isUndelete == compare.isUndelete){
				return true;
			}else{
				return false;
			}
		}
		
		public integer hashCode(){
			return HashCodeGenerator.getHashCode(this);  
		}
		
	}
	
	@TestVisible
	private static set<ProcessToken> dispatches = new set<ProcessToken>();
	//private static Map<string, List<Process__c>> mProcesses = new Map<string, List<Process__c>>();
	//private static Map<Id, List<Step__c>> mSteps = new Map<Id, List<Step__c>>();
	
	public static ProcessToken currentDispatch;
	
	public static Map<String, SObject> processedRecordsMap = new Map<String, SObject>();
	
	public static void Dispatch(){
		
		string sObjectName;
		if(trigger.isDelete || trigger.isUndelete){
			sObjectName = trigger.old.getSObjectType().getDescribe().getName();
		}else{
			sObjectName = trigger.new.getSObjectType().getDescribe().getName();
		}
		
		//system.debug(LoggingLevel.INFO, 'sObjectName: ' + sObjectName);
		if(sObjectName == '' || sObjectName == null){
			//Exit Dispatcher
			return;
		}
		
		ProcessToken procToken = new ProcessToken(sObjectName, trigger.isBefore, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete);
		//system.debug('dispatches: '+dispatches);
		//system.debug('procToken: ' + procToken);
		//system.debug('dispatches contains: ' + dispatches.contains(procToken));
		if(!dispatches.contains(procToken)){
			//TODO: Provide hook to all re-dispatching the same event
			dispatches.add(procToken);
			List<Process.ProcessFlow> processes = Process.returnObjectFlows(sObjectName);
			ProcessService procSvc = new ProcessService();
			for(Process.ProcessFlow p : processes){
				if(qualifyDispatch(procToken, p.proc)){
					currentDispatch = procToken;
					if(trigger.isDelete || trigger.isUndelete){
						procSvc.init(p, trigger.old);
					}else{
						procSvc.init(p, trigger.new);
					}
				}
			}
		}
		
	}
	
	
	private static boolean qualifyDispatch(ProcessToken procToken, Process__c proc){
		
		if(proc.Active__c && proc.Automated__c
				&&
				proc.object__c == procToken.sObjectName
				&&
				((procToken.isBefore && proc.Before__c) || (procToken.isafter && proc.After__c))
				&& 
				((procToken.isInsert && proc.Insert__c)
				|| (procToken.isUpdate && proc.Update__c)
				|| (procToken.isDelete && proc.Delete__c)
				|| (procToken.isUndelete && proc.Undelete__c))){
					
						
			//system.debug('qualified process ' + proc.Id + ' - ' + proc.name);
			return true;	
					
		}else{
			//system.debug('unqualified process ' + proc.Id + ' - ' + proc.name);
			return false;
		}
		
	}
	
	public static List<SObject> getUnprocessedRecords(List<Sobject> allRecords){
		List<sObject> unProcessedRecords = new List<sObject>();
		String sObjectName = allRecords.getSObjectType().getDescribe().getName();
		ProcessHandler.ProcessToken procToken = new ProcessHandler.ProcessToken(sObjectName, trigger.isBefore, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUndelete);
	    	
		for(Integer i=0; i < allRecords.size(); i++){
			sObject rec = allRecords[i];
			if(ProcessHandler.processedRecordsMap.containsKey('' + procToken.hashCode() + i) == false){
				unProcessedRecords.add(rec);
			}
		}
		
		return unProcessedRecords;
	}
	
	//TODO: Re-entrant code management
	
}