trigger Task on Task (before insert, before update, after insert, after update, after delete) {
    
    if(DML.checkTriggerDispatch(Task.getSobjectType())){return;}
    
    //ExceptionService.validateExceptions();
    //ExceptionService.setPrimaryKey();
    if(trigger.isBefore) {
    	if(trigger.isInsert) {
			for(Task ex : trigger.new) {
				if(ex.Default_Owner__c != null) {
			    	ex.OwnerId = ex.Default_Owner__c;
			    }
			}
		}
    }
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate || trigger.isDelete){
    		ExceptionService.updateExceptionsCount();
        }
    }
}