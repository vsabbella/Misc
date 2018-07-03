/*Copyright Kenandy Inc
*@Author :MG
*@Description :This class is initiated from GenerateTempLevels class for next level items . It looks for the assemblies for the previous item components.
*/
public with sharing class CreateNextLevel implements Database.batchable<sObject>, Database.Stateful{
    public integer previousLevel; 
    public integer nextLevel;
    public string query;
    public Id companyId;
  
    public CreateNextLevel(integer prevLevel){
        previousLevel=prevLevel;
        query='select Id,Item__c from Item_Specification__c where Id in '+
                '(select Assembly_Item_Specification__c from Component__c where Component_Item__r.Level__c=:previousLevel) and '+
                'Company__c=:companyId';
    }
  
    public Database.QueryLocator start(Database.BatchableContext BC){
        if(previousLevel!=null){
            nextLevel=previousLevel;
            
        }  
        
        //Iterate over assembly items for the previous components items.     
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext info, List<Item_Specification__c> assemblyList){
      
        execute(assemblyList);
    }
    
    public void execute(List<Item_Specification__c> assemblyList){
      
      list<Item__c> updateList=new list<Item__c>();
      set<Id> itemSet=new set<Id>();
      for(Item_Specification__c itemObj:assemblyList){
        if(!itemSet.contains(itemObj.Item__c)){
            itemSet.add(itemObj.Item__c);
            Item__c obj=new Item__c(Id=itemObj.Item__c);
            nextLevel=previousLevel+1;      //update the assembly items to the next level
            obj.Level__c=nextLevel;
            updateList.add(obj);
        }
      }
      
      if(updateList.size()>0)
        DML.updateAsUser(updateList);
    }
    
    public void finish(Database.BatchableContext info){
          
        boolean loopError=false;
        if(previousLevel!=nextLevel){      //check if there was a next level i.e query locator returned assemblies
          if(nextLevel==21){        //if the next level is 21 then there is a loop
            loopError=true;  
          } 
        }else{
            nextLevel=21;
            
        }
        if(nextLevel!=21&&loopError==false){
            CreateNextLevel obj = new CreateNextLevel(nextLevel);
            obj.companyId=companyId; 
            Id jobId=Database.executebatch(obj,2000);
        }else{
            // PTM-705
            List<Notify.Message> messages = new List<Notify.Message>();
            if (loopError == true) {
                messages.add(new Notify.Message('Item Leveling Completed with Error', ''));
            }
            Notify.sendEmailBatchFinish( 'Item Leveling', messages, info);
        
            MasterControlProgram.finishedBatch( this );
        }
    }
}