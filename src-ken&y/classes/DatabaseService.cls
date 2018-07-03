public with sharing class DatabaseService {
	
	private static DatabaseService instance = null;
	//Singleton
	private DatabaseService(){
		
	}
	
	public static DatabaseService getInstance(){
		if(instance == null){
			instance = new DatabaseService();
		}
		return instance;
	}
	
	/*
	//CONSIDERATIONS:
	//Use text file attachment to store serialized JSON sObject record or sObject Record array and/or corresponding Database.SaveResult(s) data (if bundled, use class wrapper JSON)
	//This could be used to reinflate failed records for user interaction and modification - or retry from declarative changes (turn off validation, etc)
	
	public void processSaveResults(List<Database.Saveresult> saveResults, List<sObject> records, string processMsg){
		system.debug('saveResults: ' + saveResults);
		system.debug('records: ' + records);
		system.debug('processMsg: ' + processMsg);
		for(integer i=0; i<saveResults.size(); i++){
			if(!saveResults[i].isSuccess()){
				//TODO - RS Generate Error Queue record for failed saveresults based on error responses
				for(Database.Error err : saveResults[i].getErrors()){
					
				}
			}
		}
	}
	
	public void processUpsertResults(List<Database.UpsertResult> upsertResults, List<sObject> records, string processMsg){
		system.debug('saveResults: ' + upsertResults);
		system.debug('records: ' + records);
		system.debug('processMsg: ' + processMsg);
		for(integer i=0; i<upsertResults.size(); i++){
			if(!upsertResults[i].isSuccess()){
				//TODO - RS Generate Error Queue record for failed saveresults based on error responses
				if(upsertResults[i].isCreated()){
					//TODO - RS manage error tagging with ur.getId() for the failed update
				}
				for(Database.Error err : upsertResults[i].getErrors()){
					
				}
			}
		}
	}
	*/
	//TODO - RS Delete and undelete processors
	
	
}