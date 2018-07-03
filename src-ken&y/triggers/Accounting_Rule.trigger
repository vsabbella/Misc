trigger Accounting_Rule on Accounting_Rule__c (before insert, before update, before delete) {
	
	
	if(DML.checkTriggerDispatch(Accounting_Rule__c.getSobjectType())){return;}
	
	//if(trigger.isBefore) {
	//	AccountingRuleService.SetUniqueKeyField(trigger.new);
	//}
	
	if ( trigger.isBefore && ( trigger.isInsert || trigger.isUpdate ) ) {
		for(Accounting_Rule__c ar: Trigger.new){
			if(ar.company_ledger__c == false){
				ar.company_ledger__c = true;
			}
	    }
		Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
													'GL_Account__c' ,	
													'GL_Account__c', 
													'GL_Account_Identifier__c',
													'GL_Account_Unique__c'		);		
		
		Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
													'Company__c' ,	
													'Company__c', 
													'Company_Identifier__c',
													'Company_Identifier__c'		);	
		AccountingRuleService.getObjectAPIName(Trigger.New);
		//This method needs to be called AFTER any keys constituting the unique key are defaulted.
		AccountingRuleService.SetUniqueKeyField(trigger.new);		
	    AccountingRuleService.validateEffectiveDates(Trigger.new,Trigger.oldMap);	
	    //Any error in validateNARules supersedes validateEffectiveDates.
	    AccountingRuleService.validateNARules(Trigger.New);	

	}else if ( trigger.isBefore && ( trigger.isDelete ) ){
		//Validating the accounting rule reference in AELs before deleting.
		AccountingRuleService.checkAccountingRulesreference(trigger.oldMap);
	}

}