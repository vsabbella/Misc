/*Copyright Kenandy Inc
*@Author: MG
*@Description: This class is initiated from ClearItemLevels class. It updates the items to level 0 which don't exist as an assembly.
*/
public with sharing class GenerateTempLevels	implements Database.batchable<sObject>,Database.stateful {
  	//iterate through the items which doesn't exist as assembly 
  	public String query;
  	public Id companyId;
  
  	public GenerateTempLevels() {
  	    
        // PTM-705 
  	    query = 'select ID '+
  	            'from Item__c '+
  	            'where Company__c =: companyId and '+
  	            'Active__c = true and '+
  	            'ID in (select Item__c from Item_Specification__c)';
  	}
  
  	public Database.QueryLocator start(Database.BatchableContext BC) {              
        return Database.getQueryLocator(query);
  	}
    
	public void execute(Database.BatchableContext info, List<Item__c> itemList) {
	  	execute(itemList);
	}
    
    public void execute(List<Item__c> itemList){
        
        // PTM-705 	
        for(Item__c itemObj : itemList) itemObj.Level__c = 1;
      
        DML.updateAsUser(itemList);  //KNDY-3586
    }
    
    public void finish(Database.BatchableContext info){
        //initiate the next batch for next level
        // PTM-705 
        CreateNextLevel obj = new CreateNextLevel(1);
        obj.companyId=companyId; 
        Id jobId=Database.executebatch(obj,2000);
    }
}