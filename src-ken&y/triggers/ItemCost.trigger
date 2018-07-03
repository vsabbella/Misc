trigger ItemCost on Item_Cost__c (before insert,before update,before delete) {
    
	  if(DML.checkTriggerDispatch(Item_Cost__c.getSobjectType())){return;}
    
      //PTM-582 & PTM-580
      if(trigger.isInsert || trigger.isUpdate || trigger.isDelete){
         //PTM-516
         if(trigger.isInsert || trigger.isUpdate){
             Scale.govern(trigger.new);
             for(Item_Cost__c ic : trigger.new){
                if(ic.start_date__c == null){
	         		ic.addError(Label.Start_Date_for_Item_Cost_is_required);   
                }
             }
         }
        ItemService.checkItemCostStatus(trigger.oldMap,trigger.new);
      }     
}