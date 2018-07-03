/*Copyright Kenandy Inc
*@Author: MG
*@Description: This class is initiated from the Item Level visualforce page button. The batch size should be set to 2000.
*It updates all items with level -1 as a first step
*/

public with sharing class ClearItemLevels implements Database.batchable<sObject>,Database.stateful{
  
    public string query;
    public Id companyId;
    
    public ClearItemLevels(){
        // PTM-705 
  	    query = 'select ID '+
  	            'from Item__c '+
  	            'where Company__c =: companyId and '+
  	            'Active__c = true and '+
  	            'ID not in (select Item__c from Item_Specification__c)';
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
	
    public void execute(Database.BatchableContext info, List<Item__c> itemList) {      
        execute(itemList);  
        }
    
    public void execute(List<Item__c> itemList) { 
    	
        // PTM-705 	
        for(Item__c itemObj : itemList) itemObj.Level__c = 0;
		
        DML.updateAsUser(itemList);  //KNDY-3586
    }
    
    public void finish(Database.BatchableContext info){
        //initiate the next batch for level 1
      GenerateTempLevels Obj=new GenerateTempLevels();
      obj.companyId=companyId;
      Id jobId=Database.executebatch(obj,2000);
    }
}