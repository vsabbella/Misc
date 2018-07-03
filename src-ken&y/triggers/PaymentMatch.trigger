trigger PaymentMatch on Payment_Match__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    if(DML.checkTriggerDispatch(Payment_Match__c.getSobjectType())){return;}
    
    if(trigger.isAfter){
    	if(trigger.isInsert || trigger.isUpdate){
    		PaymentService.updateLineMatchTotals(trigger.new);
    	}else if(trigger.isDelete){
    		PaymentService.updateLineMatchTotals(trigger.old);
    	}
    }
    
}