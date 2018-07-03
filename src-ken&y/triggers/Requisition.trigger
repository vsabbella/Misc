trigger Requisition on Requisition__c (before insert, before update) {

	if(DML.checkTriggerDispatch(Requisition__c.getSobjectType())){return;}
	
	RequisitionService.updateDeliveryAccount();
	RequisitionService.updateReqStatusonApproval(); 
	RequisitionService.updateRequisitionLinestoApproved(); 
	RequisitionService.flipReqApprovalStatus_headerchange();	
	if(trigger.isBefore && trigger.isUpdate){
		RequisitionService.validateDropShipReq();
   } 
}