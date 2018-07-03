public with sharing class AccountingEntryLinesService {
	public static ExceptionService exService = new ExceptionService();
    
    //Streamline AE/AEL Exceptions KNDY-10534
    public static void ValidateAELFields(List<Accounting_Entry_Line__c> lstAEL)
    {
    	for(Accounting_Entry_Line__c ael:lstAEL)
    	{ 
    		if(ael.Company__c==null)
    			exService.setException(ael, ExceptionUtil.AEL_MISSING_COMPANY);
    		//else
    		//	exService.clearException(ael, ExceptionUtil.AEL_MISSING_COMPANY);
    			
    		/*if(ael.GL_Account__c==null)
    			exService.setException(ael, ExceptionUtil.AEL_MISSING_GL_Account);*/
    		//else
    		//	exService.clearException(ael, ExceptionUtil.AEL_MISSING_GL_Account);
    			
    		if(ael.Currency__c==null)
    			exService.setException(ael, ExceptionUtil.AEL_MISSING_TRANSACTION_CURRENCY);
    		//else
    		//	exService.clearException(ael, ExceptionUtil.AEL_MISSING_TRANSACTION_CURRENCY);
    			
    		if(ael.Amount_CR__c==null && ael.source_id__c != null && !ael.source_id__c.contains('|RFX') && ael.Error_Message__c == 'Raise Exception')
    			exService.setException(ael, ExceptionUtil.AEL_MISSING_TRANSACTION_AMOUNT_CR);
    		//else
    		//	exService.clearException(ael, ExceptionUtil.AEL_MISSING_TRANSACTION_AMOUNT_CR);
    
    		if(ael.Amount_DR__c==null && ael.source_id__c != null && !ael.source_id__c.contains('|RFX') && ael.Error_Message__c == 'Raise Exception')
    			exService.setException(ael, ExceptionUtil.AEL_MISSING_TRANSACTION_AMOUNT_DR);
    		//else
    		//	exService.clearException(ael, ExceptionUtil.AEL_MISSING_TRANSACTION_AMOUNT_DR);
    		
    		if(ael.COMP_Transaction_Currency__c != ael.COMP_Functional_Currency__c && ael.COMP_Functional_Conversion_Rate__c == null ){
				exService.setException(ael, ExceptionUtil.AEL_MISSING_FUNCTIONAL_CONVERSION_RATE);
    		}
    		
     		if((ael.Accounting_rule__c == null && ael.source_id__c == null) || (ael.Accounting_rule__c == null && ael.source_id__c != null && !ael.source_id__c.contains('|RFX'))) {
     			exService.setException(ael, ExceptionUtil.AEL_MISSING_ACCOUNTING_RULE);
     		}
     		else
     		{
     			if(ael.SCOA_Valid__c == false)
    				exService.setException(ael, ExceptionUtil.SEGMENT_VALIDATION);
    			if(ael.GL_Account__c==null || (ael.source_id__c != null &&!ael.source_id__c.contains('|RFX') && ael.GL_Account__c==null))
    				exService.setException(ael, ExceptionUtil.AEL_MISSING_GL_Account);
     		} 
     		system.debug(logginglevel.info,'********Inside AEL trigger*******');
     		system.debug(logginglevel.info,'ael.item_cost_missing__c:'+ael.item_cost_missing__c+'=========ael.Error_Message__c:'+ael.Error_Message__c);
     		if(ael.item_cost_missing__c == true)
    			exService.setException(ael, ExceptionUtil.AEL_MISSING_ITEM_COST); 
     		if(ael.Error_Message__c != null && ael.Error_Message__c.equalsIgnoreCase('Exchangerate Service Error'))
    			exService.setException(ael, ExceptionUtil.AEL_EXCHANGE_SERVICE_ERROR); 
    	}
    }
    public static void validateLines(List<SegmentValidationService.SegmentValidationResponse> responses)
    {
	    SET<ID> accountingEntryLineIds=new set<Id>();	
	    Map<id,SegmentValidationService.SegmentValidationResponse> accountEntryLineObjectErrorMap	=new  Map<id,SegmentValidationService.SegmentValidationResponse>();
    	for(SegmentValidationService.SegmentValidationResponse resp : responses){
					if(!resp.isValid){
						accountEntryLineObjectErrorMap.put((Id)resp.recordId,resp);
					}
    	}
    	
    	for(Id lineId : accountEntryLineObjectErrorMap.Keyset()){
            SegmentValidationService.SegmentValidationResponse resp = accountEntryLineObjectErrorMap.get(lineId);
        	if(!resp.isValid){
					if(resp.compare!=null){
						string errorMessage = Label.One_or_more_segments_available_with_validation_exceptions +' ';
						errorMessage += (resp.compare.segment1==null?'('+Label.Segment+' '+Label.X1 +': ) - ':'('+Label.Segment +' '+Label.X1+': ' + (resp.compare.segment1==''?'*':resp.compare.segment1) + ') - ');
						errorMessage += (resp.compare.segment2==null?'('+Label.Segment+' '+Label.X2 +': ) - ':'('+Label.Segment +' '+Label.X2+': ' + (resp.compare.segment2==''?'*':resp.compare.segment2) + ') - ');
						errorMessage += (resp.compare.segment3==null?'('+Label.Segment+' '+Label.X3 +': ) - ':'('+Label.Segment +' '+Label.X3+': ' + (resp.compare.segment3==''?'*':resp.compare.segment3) + ') - ');
						errorMessage += (resp.compare.segment4==null?'('+Label.Segment+' '+Label.X4 +': ) - ':'('+Label.Segment +' '+Label.X4+': ' + (resp.compare.segment4==''?'*':resp.compare.segment4) + ') - ');
						errorMessage += (resp.compare.segment5==null?'('+Label.Segment+' '+Label.X5 +': ) - ':'('+Label.Segment +' '+Label.X5+': ' + (resp.compare.segment5==''?'*':resp.compare.segment5) + ') - ');
						errorMessage += (resp.compare.segment6==null?'('+Label.Segment+' '+Label.X6 +': ) - ':'('+Label.Segment +' '+Label.X6+': ' + (resp.compare.segment6==''?'*':resp.compare.segment6) + ') - ');
						errorMessage += (resp.compare.segment7==null?'('+Label.Segment+' '+Label.X7 +': ) - ':'('+Label.Segment +' '+Label.X7+': ' + (resp.compare.segment7==''?'*':resp.compare.segment7) + ') - ');
						errorMessage += (resp.compare.segment8==null?'('+Label.Segment+' '+Label.X8 +': ) - ':'('+Label.Segment +' '+Label.X8+': ' + (resp.compare.segment8==''?'*':resp.compare.segment8) + ') - ');
						errorMessage += (resp.compare.segment9==null?'('+Label.Segment+' '+Label.X9 +': ) - ':'('+Label.Segment +' '+Label.X9+': ' + (resp.compare.segment9==''?'*':resp.compare.segment9) + ') - ');
						errorMessage += (resp.compare.segment10==null?'('+Label.Segment+' '+Label.X10 +': ) - ':'('+Label.Segment +' '+Label.X10+': ' + (resp.compare.segment10==''?'*':resp.compare.segment10) + ') - ');
				
		        		ExceptionUtil.SEGMENT_VALIDATION.description = errorMessage;
		        		Accounting_Entry_Line__c aelObj=new Accounting_Entry_Line__c(Id = lineiD);
						exService.setException(aelObj, ExceptionUtil.SEGMENT_VALIDATION);
					}
				}
				else
				{
					Accounting_Entry_Line__c aelObj=new Accounting_Entry_Line__c(Id = lineiD);
					exService.clearException(aelObj, ExceptionUtil.SEGMENT_VALIDATION);
				
				
				}
        }
    }
    
    

	/*
	* FIN-795
	* adds errors if any fields are changed which aren't in the custom setting of fields which we are temporarily allowed to change
	*/    
	public static void checkNonChangeableFieldsClosedPeriod(Accounting_Entry_Line__c ael, Map<Id, sObject> oldMap, set<String> nonChangeableAELfieldsClosedPeriod) {
		List<String> errorFields = new List<String>();
		for (String f: nonChangeableAELfieldsClosedPeriod) {
			if (KSE.isFieldChanging(f, ael, oldMap)) {
				errorFields.add(f);
			}	
		}				
		if (!errorFields.isEmpty()) {
			ael.addError(Label.Cannot_create_AccountingEntries_for_closed_period + ' Fields: ' + String.join(errorFields, ', '));
		}
	}  

	/*
	* FIN-795
	* Returns a list of all the fields which can be changed if the custom setting is set to update AELs in closed periods
	* returns null if the custom setting doesn't exist, or exists with no value
	*/
	public static List<String> getAELallowedEditFields() {
		List<String> fieldList;
		//get the value from the custom setting
		Configuration__c c = Configuration__c.getValues('AELclosedPeriodEditFields');
		if (c == null) {
			return null;			
		} else {
			if (c.Value__c == null) {
				return null;	
			} else {
				String sFields = c.Value__c;
				if (sFields != null) {
					fieldList = sFields.toLowerCase().split(',');
					for (Integer i=0; i<fieldList.size(); i++) {
						fieldList[i] = fieldList[i].trim();
					}
				} 					
			}
		}

		return fieldList;
	}  


	/*
	* FIN-795
	* Returns a list of all the fields which cannot be changed in the context of adding the custom setting to
	* update AELs in closed periods
	*/
	public static set<String> getNonChangeableAELfieldsClosedPeriod(List<String> changeableAELfieldsClosedPeriod) {
		//get all the fields in the AEL
		set<String> allFieldsInAEL = Schemautil.getInstance().getAllCustomFieldsFromObject(null, 'Accounting_Entry_Line__c');	
		
		//remove the fields which we can change from the list of all fields, to get the ones we can't change
		if (changeableAELfieldsClosedPeriod != null) {
			allFieldsInAEL.removeAll(changeableAELfieldsClosedPeriod);
		}
		
		return allFieldsInAEL;
	}  
    
    
}