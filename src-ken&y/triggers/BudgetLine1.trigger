trigger BudgetLine1 on Budget_Line1__c (after insert, after update, before insert, before update) {
	
	if(DML.checkTriggerDispatch(Budget_Line1__c.getSobjectType())){return;}
	
	BudgetLineTriggerHandler.assignBudgetLineUniqueKeys();
}