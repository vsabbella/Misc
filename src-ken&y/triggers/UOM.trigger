trigger UOM on UOM__c (before delete) {
	
	if(DML.checkTriggerDispatch(UOM__c.getSobjectType())){return;}
	
	if(trigger.isbefore &&  trigger.isDelete){
		KSE.ValidateUOM(); 
	}

}