trigger RecurringTemplateLine on Recurring_Template_Line__c (before insert, before update) {
	
	if(DML.checkTriggerDispatch(Recurring_Template_Line__c.getSobjectType())){return;}
	
	RecurringTemplateLineService RTLS = new RecurringTemplateLineService();
	if ( Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {
		RTLS.setOrClearInformation(Trigger.new);
	}
}