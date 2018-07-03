trigger AccountingDefault on Accounting_Default__c (before insert, before update, after insert, after update) {
	
	if(DML.checkTriggerDispatch(Accounting_Default__c.getSobjectType())){return;}
	
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		
		List<SegmentValidationService.SegmentValidationResponse> responses = SegmentValidationService.getInstance().beforeValidateAccountingDefaults(trigger.new);
		for(SegmentValidationService.SegmentValidationResponse resp : responses){
			if(!resp.isValid){
				integer i = integer.valueOf(resp.recordId);
				string errorMessage = 'There is one or more segments with validation exceptions. No segment validation exists for: ';
				if(resp.compare != null){
					errorMessage += (resp.compare.segment1==null?'':'(Segment 1: ' + (resp.compare.segment1==''?'*':resp.compare.segment1) + ') - ');
					errorMessage += (resp.compare.segment2==null?'':'(Segment 2: ' + (resp.compare.segment2==''?'*':resp.compare.segment2) + ') - ');
					errorMessage += (resp.compare.segment3==null?'':'(Segment 3: ' + (resp.compare.segment3==''?'*':resp.compare.segment3) + ') - ');
					errorMessage += (resp.compare.segment4==null?'':'(Segment 4: ' + (resp.compare.segment4==''?'*':resp.compare.segment4) + ') - ');
					errorMessage += (resp.compare.segment5==null?'':'(Segment 5: ' + (resp.compare.segment5==''?'*':resp.compare.segment5) + ') - ');
					errorMessage += (resp.compare.segment6==null?'':'(Segment 6: ' + (resp.compare.segment6==''?'*':resp.compare.segment6) + ') - ');
					errorMessage += (resp.compare.segment7==null?'':'(Segment 7: ' + (resp.compare.segment7==''?'*':resp.compare.segment7) + ') - ');
					errorMessage += (resp.compare.segment8==null?'':'(Segment 8: ' + (resp.compare.segment8==''?'*':resp.compare.segment8) + ') - ');
					errorMessage += (resp.compare.segment9==null?'':'(Segment 9: ' + (resp.compare.segment9==''?'*':resp.compare.segment9) + ') - ');
					errorMessage += (resp.compare.segment10==null?'':'(Segment 10: ' + (resp.compare.segment10==''?'*':resp.compare.segment10) + ') - ');
				}
				trigger.new[i].addError(errorMessage);
				
			} 
		}
		
	}
	/*
	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
		
		List<SegmentValidationService.SegmentValidationResponse> responses = SegmentValidationService.getInstance().validateAccountingDefaults(trigger.new);
		for(SegmentValidationService.SegmentValidationResponse resp : responses){
			if(!resp.isValid){
				throw new SegmentValidationService.SegmentValidationServiceException('There is one or more segments with validation exceptions.');
			}
		}
		
	}
	*/
}