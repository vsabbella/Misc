trigger ReceivingDocument on Receiving_Document__c (before insert, before update, before delete) {

	if(DML.checkTriggerDispatch(Receiving_Document__c.getSobjectType())){return;}

static SchemaUtil util = SchemaUtil.getInstance();

//    VoidCancelService.validateHeader();
	
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		
		// set finalized hidden flag and validate user action of unfinalize
		KSE.setValidateFinalizedFlagonSD();
		
		// set finalized date on the receiving document
       	FinalizeService.setFinalizedDate(Trigger.new);
	}
	
	if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
     	FinalizeService.validateHeaderFinalize();
	}
}