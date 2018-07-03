trigger LPN on LPN__c (before insert, before update,before delete,after insert,after update) {
    if (DML.checkTriggerDispatch(LPN__c.getSobjectType()) == true || ExceptionService.ignoreTrigger('LPN__c') == true) return;
	
	if(trigger.isBefore && trigger.isDelete){
		skidservice3.allowLPNDelete();
	}
}