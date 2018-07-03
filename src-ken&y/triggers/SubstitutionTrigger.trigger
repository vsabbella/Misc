trigger SubstitutionTrigger on Substitution__c (before insert, before update) {
	if(DML.checkTriggerDispatch(Substitution__c.getSobjectType())){return;}
	SubstitutionService.validateSubstitutionRules();
}