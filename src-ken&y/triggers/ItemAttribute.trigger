trigger ItemAttribute on Item_Attribute__c (before Update, before Delete) {
    
    if(DML.checkTriggerDispatch(Item_Attribute__c.getSobjectType())){return;}
    
    if( trigger.isBefore && ( trigger.isUpdate || trigger.isDelete) ){
        
        ItemService.allowChangeInItemAttribute(trigger.newMap, trigger.oldMap);   
    }
    
}