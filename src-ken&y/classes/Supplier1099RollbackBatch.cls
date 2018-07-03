/*
* without sharing is intentional.  1099 batches need to be run in system mode.
*/
public without sharing class Supplier1099RollbackBatch implements Database.Batchable<sObject>, Schedulable{//, KNDY3.Process.Runnable{

   	public string query;
   	public Id companyId;
   	public String batchJobId;
   	
   	public void execute(SchedulableContext sc) {
   
   		Supplier1099RollbackBatch b = new Supplier1099RollbackBatch(); 
      	database.executebatch(b); 
   	}
   	
   	public void runBatch(Id comp){
   		companyId = comp;
   		Supplier1099RollbackBatch batch = new Supplier1099RollbackBatch(companyId);
   		Database.executebatch(batch);
   	}
   	
   	public Supplier1099RollbackBatch(Id companyId){
   		this.companyId = companyId;
   		updateQuery();
   		query += ' AND Company__c = :companyId';
   	}
   
   	public Supplier1099RollbackBatch(Id companyId, String batchJobId){ //KNDY-17918
   		this.companyId = companyId;
   		this.batchjobId = batchJobId;
   		updateQuery();
   		query += ' AND Company__c = :companyId';
   		if(!String.isBlank(batchJobId)){
   			query += ' and Batch_Job_ID__c = :batchJobId';
   		}
   	}
   	
   	public Supplier1099RollbackBatch(){
   		updateQuery();
   	} 

   	public Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator(query);
   	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope){ 
      
      	try{
    		DML.deleteAsSystem(scope);
      	}catch(exception ex){
      		Notify.Message msg = new Notify.Message('Supplier 1099 Rollback Error', 'There was a problem while deleting the requested 1099s: ' + ex.getMessage());
        	Notify.chatterOnMe(new Supplier1099Service(), new List<Notify.Message>{msg});
      	}
	}

   	public void finish(Database.BatchableContext BC){
   		Notify.Message msg = new Notify.Message('Supplier 1099 Rollback', 'Supplier 1099 Rollback batch completed.');
        Notify.chatterOnMe(new Supplier1099Service(), new List<Notify.Message>{msg});
   	}
   	
   	public void updateQuery(){
   		
		query = 'SELECT Id FROM Supplier_1099__c WHERE Filed__c = false';
		
   	}
   
}