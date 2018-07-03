public with sharing class JournalEntryLineService {
	public static ExceptionService exService = new ExceptionService();
    
    public void ValidateJELine(List<Journal_Entry_Line__c> JournalEntryListNew, List<Journal_Entry_Line__c> JournalEntryListOld, Map<id, Journal_Entry_Line__c> oldMap,Boolean isUpdate,Boolean isInsert){
		if ( Trigger.isbefore && (Trigger.isInsert || Trigger.isUpdate) ) {
         	Set <Id> JEIds = new Set<Id>();
       
	        	//system.debug('Trigger.new: '+Trigger.new);
	        	for(Journal_Entry_Line__c jeLine: JournalEntryListNew){
	        		JEIds.add(jeLine.Journal_Entry__c);
	        }
        	
            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Journal_Entry__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','Company__c','Company__r.Name'
            });
            soql.setWhereClause('id in :JEIds');
            Map <id, Journal_Entry__c> JEHdrMap = new map <id, Journal_Entry__c>((List<Journal_Entry__c>)Database.query(soql.getQuery()));



			// Default the company from header
			for(Journal_Entry_Line__c jeLine: JournalEntryListNew){
				if(JEHdrMap.containsKey(jeLine.Journal_Entry__c)){
					// KNDY - 2362
					jeLine.Company__c = JEHdrMap.get(jeLine.journal_Entry__c).Company__c ; // get header from map
				}
				if(jeLine.Amount_CR__c == null){
					jeLine.Amount_CR__c = 0;
				}
				if(jeLine.Amount_DR__c == null){
					jeLine.Amount_DR__c = 0;
				}
				
				jeLine.Amount_CR__c = jeLine.Amount_CR__c.setScale(6,RoundingMode.FLOOR);// KNDY-6889 never store more than 6 decimal places
				jeLine.Amount_DR__c = jeLine.Amount_DR__c.setScale(6,RoundingMode.FLOOR);
            } 			
        }
    }
    
    public static void validateJELineFields(List<Journal_Entry_Line__c> JELineList)
    {
    	for(Journal_Entry_Line__c jeLine:JELineList)
    	{
    		if(jeLine.Company__c==null)
    			exService.setException(jeLine, ExceptionUtil.JEL_MISSING_COMPANY);
    		else
    			exService.clearException(jeLine, ExceptionUtil.JEL_MISSING_COMPANY);
    			
    		if(jeLine.Currency__c==null)
    			exService.setException(jeLine, ExceptionUtil.JEL_MISSING_TRANSACTION_CURRENCY);
    		else
    			exService.clearException(jeLine, ExceptionUtil.JEL_MISSING_TRANSACTION_CURRENCY);
    			
    		if(jeLine.Amount_CR__c==null)
    			exService.setException(jeLine, ExceptionUtil.JEL_MISSING_TRANSACTION_AMOUNT_CR);
    		else
    			exService.clearException(jeLine, ExceptionUtil.JEL_MISSING_TRANSACTION_AMOUNT_CR);
    
    		if(jeLine.Amount_DR__c==null)
    			exService.setException(jeLine, ExceptionUtil.JEL_MISSING_TRANSACTION_AMOUNT_DR);
    		else
    			exService.clearException(jeLine, ExceptionUtil.JEL_MISSING_TRANSACTION_AMOUNT_DR);
    		
    	}
    }
   
    public static void validateLines(List<SegmentValidationService.SegmentValidationResponse> responses){

	    SET<ID> journalEntryLineIds=new set<Id>();	
	    //system.debug(logginglevel.info,'responses:'+responses+'		journalEntryLineIds:'+journalEntryLineIds);
	    Map<id,SegmentValidationService.SegmentValidationResponse> journalEntryLineObjectErrorMap	=new  Map<id,SegmentValidationService.SegmentValidationResponse>();
    	for(SegmentValidationService.SegmentValidationResponse resp : responses){
					//if(!resp.isValid){
						journalEntryLineObjectErrorMap.put((Id)resp.recordId,resp);
					//}
					}
    	//system.debug(logginglevel.info,'journalEntryLineObjectErrorMap:'+journalEntryLineObjectErrorMap);
    	
    	for(Id lineId : journalEntryLineObjectErrorMap.Keyset()){
            SegmentValidationService.SegmentValidationResponse resp = journalEntryLineObjectErrorMap.get(lineId);
            //system.debug(logginglevel.info,'resp.isValid:'+resp.isValid);
        	if(!resp.isValid){
        			//system.debug(logginglevel.info,'resp.compare:'+resp.compare);
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
		        		Journal_Entry_Line__c jelObj=new Journal_Entry_Line__c(Id = lineiD);
						exService.setException(jelObj, ExceptionUtil.SEGMENT_VALIDATION);
					}else{
						Journal_Entry_Line__c jelObj=new Journal_Entry_Line__c(Id = lineiD);
						exService.setException(jelObj, ExceptionUtil.SEGMENT_VALIDATION);
					}
				}
				else
				{
					//system.debug(logginglevel.info,'Inside else loop for resp.isValid');
					Journal_Entry_Line__c jelObj=new Journal_Entry_Line__c(Id = lineiD);
					exService.clearException(jelObj, ExceptionUtil.SEGMENT_VALIDATION);
				
				
				}
        }
    }
 
}