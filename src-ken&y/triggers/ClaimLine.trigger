trigger ClaimLine on Claim_Line__c (before insert, before update) {
	if(DML.checkTriggerDispatch(Claim_Line__c.getSobjectType())){return;}
	if(ExceptionService.ignoreTrigger('Claim_Line__c')){return;}
	
}