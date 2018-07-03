trigger RecurringTemplate on Recurring_Template__c (before insert, before update, before delete,after insert, after update) {
	if(DML.checkTriggerDispatch(Recurring_Template__c.getSobjectType())){return;}
	
	if(ExceptionService.ignoreTrigger('Recurring_Template__c')){return;}
	RecurringTemplateService RTS = new RecurringTemplateService();
	
	if(trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
		RTS.setOrClearInformation(Trigger.new);
	}
	
	if(trigger.isBefore && (Trigger.isUpdate)){
		RTS.validateRecurringTemplate(Trigger.new, Trigger.oldMap);
	}
	if(trigger.isBefore && (Trigger.isDelete)){
		for(Recurring_Template__c thisRT: trigger.old){
			if(thisRT.isJECreated__c == true){
				thisRT.addError('Template can not be deleted once the journal entries are created');
			}
		}
	}
	if(trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){

        RecurringJournalEntryService.ValidateRJEFields(trigger.new);
        RecurringJournalEntryService.exService.finishTasks();
        
    }

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Recurring_Template__c> recWithoutCurrency = new List<Recurring_Template__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Recurring_Template__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Recurring_Template__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }
	
	
}