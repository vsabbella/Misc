trigger AccountingCode on Accounting_Code__c (before insert, before update) {
	
	if(DML.checkTriggerDispatch(Accounting_Code__c.getSobjectType())){return;}
	
	AccountingCodeService ACS = new AccountingCodeService();
	
	
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		//AccountingCodeService.validateSystemFields();
		AccountingCodeService.generateSCOAKey(trigger.new);
	}
	
	if(trigger.isBefore && trigger.isInsert){
		AccountingCodeService.segmentValidation(trigger.new);
	}
	
	if(trigger.isBefore && trigger.isUpdate){
		AccountingCodeService.validateSystemFields();
	}
	
	

}