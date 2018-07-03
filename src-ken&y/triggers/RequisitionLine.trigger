trigger RequisitionLine on Requisition_Line__c (after delete, after insert, after update, 
before delete, before insert, before update) {
	
	if(DML.checkTriggerDispatch(Requisition_Line__c.getSobjectType())){return;}
	
	RequisitionService.flipReqApprovalStatus_linechange();
	if(Trigger.isDelete && Trigger.isBefore) {
		for(Requisition_Line__c rl : Trigger.old) {
			if(rl.Approved__c) {
				rl.addError('Approved requisition lines cannot be deleted.');
			}
		}
	}
	if(Trigger.isBefore && Trigger.isUpdate){
		RequisitionService.validateDropShipReqLine();   //KNDY-9504
	} 
	if(Trigger.isAfter && Trigger.isUpdate){
		RequisitionService.updateRequisitionStatus();   //KNDY-10515
	}
}