trigger StockMovementRule on Stock_Movement_Rule__c (before insert,before update) {
    
 if(DML.checkTriggerDispatch(Stock_Movement_Rule__c.getSobjectType())){return;}
   
   if(trigger.isBefore && trigger.isInsert){
        //Fix for KNDY-4270
        for(Stock_Movement_Rule__c smrEntry: Trigger.new){
                smrEntry.Unique_Key__c = null;
        }       
   }
   
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
       for(Stock_Movement_Rule__c smrEntry: Trigger.new){
                list<Id> locList = new list<ID>();
                list<Id> uniquelocList =  new List<ID>();
                set<Id> locSet = new set<Id>();
                if (smrEntry.get('Location_List__c') != null) {
                	loclist = (list<Id>)JSON.deserialize(String.valueOf(smrEntry.get('Location_List__c')), list<Id>.Class);
                	if (loclist.size() > 0) { 
                    	for (Integer i=0; i < loclist.size() ; i++){
                        	if (!locSet.contains(loclist.get(i))){
                            	locSet.add(loclist.get(i));
                            	uniquelocList.add(loclist.get(i));
                        	}
                    	}   
                    
                	}
                	smrEntry.Location_List__c =  JSON.serialize( uniquelocList);
        		}    
       }
	}
}