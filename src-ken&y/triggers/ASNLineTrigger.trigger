trigger ASNLineTrigger on ASN_Line__c (before update, before insert) {
	
	if(DML.checkTriggerDispatch(ASN_Line__c.getSobjectType())){return;}
	
	ASNService.checkIfASNConfirmed(); 
	
	if(trigger.isBefore && trigger.isUpdate)				
		ASNService.checkASNLinesReceivedQty();		
	
}