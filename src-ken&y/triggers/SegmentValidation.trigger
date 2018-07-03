trigger SegmentValidation on Segment_Validation__c (before delete) {
	
	if(DML.checkTriggerDispatch(Segment_Validation__c.getSobjectType())){return;}
	
	if(trigger.isBefore && trigger.isDelete){
		for(Segment_Validation__c thisSV: Trigger.old){
			thisSV.addError('Segment Validations can not be deleted');
		}
	}
}