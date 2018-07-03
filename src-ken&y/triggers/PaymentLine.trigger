trigger PaymentLine on Payment_Line__c (before insert, before update,after update, after insert, before delete, after delete, after undelete) {
	
	if(DML.checkTriggerDispatch(Payment_Line__c.getSobjectType())){return;}
	
	if(ExceptionService.ignoreTrigger('Payment_Line__c')){return;}
    
    PaymentLineService.validations();
    
    if((trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete))
    	 	|| (trigger.isBefore && trigger.isDelete)){
        
        FinalizeService.validateLineFinalize();
    }
    
	PaymentLineService.calculateLineTotals();
	
	PaymentLineService.paymentLineCleanup();
	
	PaymentLineService.exService.finishTasks();
}