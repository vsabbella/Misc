trigger Fulfillment on Fulfillment__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
	
	if(DML.checkTriggerDispatch(Fulfillment__c.getSobjectType())){return;}
	if(trigger.isBefore){
		
		FulfillmentService.holdManagement();//KNDY-8369
		if(trigger.isInsert || trigger.isUpdate){
			FulfillmentService.setAgreementAcceptanceDate();
			FulfillmentService.setFulfillmentDetails(trigger.new);
			if(trigger.isUpdate)
			FulfillmentService.setFulfillmentFullyInvoiced(trigger.new);
		}
	}
    FulfillmentService.setAgreementQuantities();
   
    if(trigger.isAfter){
    	
        if(trigger.isInsert || trigger.isUpdate){
        	FulfillmentService.updateOrderFulfillmentDetails(trigger.new);
        }
    	
        if(trigger.isUpdate){
        	FulfillmentService.generateInstallBaseSKIDs(trigger.new);
        }
        
        if(trigger.isDelete){
			FulfillmentService.updateOrderFulfillmentDetails(trigger.old);
        }
        
    }
}