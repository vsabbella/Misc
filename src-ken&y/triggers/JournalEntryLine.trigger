trigger JournalEntryLine on Journal_Entry_Line__c (before insert, before update, before delete, after insert, after update, after undelete) {
	
	if(DML.checkTriggerDispatch(Journal_Entry_Line__c.getSobjectType())){return;}

if(ExceptionService.ignoreTrigger('Journal_Entry_Line__c')){return;}
	JournalEntryLineService JELS = new JournalEntryLineService();
	
if ( Trigger.isbefore && (Trigger.isInsert || Trigger.isUpdate) ) {
         JELS.ValidateJELine((List<Journal_Entry_Line__c> )Trigger.new, (List<Journal_Entry_Line__c>) Trigger.old, (Map<Id,Journal_Entry_Line__c>) Trigger.oldMap, Trigger.isUpdate, Trigger.isInsert);
 	}
 	
 	//FIN-209 validate the line for finalized document
	if( ( trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete) )
			|| ((trigger.isBefore && trigger.isDelete)) )
	{
			FinalizeService.validateLineFinalize();
	}
	//FIN-329
	if ( Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {
   
   	    JournalEntryLineService.validateJELineFields(trigger.new);
   	    //List<SegmentValidationService.SegmentValidationResponse> responses = SegmentValidationService.getInstance().afterValidateAEsOrJEs(trigger.new);
        //JournalEntryLineService.validateLines(responses);
     	JournalEntryLineService.exService.finishTasks();
	}	
}