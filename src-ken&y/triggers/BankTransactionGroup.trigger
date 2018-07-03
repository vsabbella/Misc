trigger BankTransactionGroup on Bank_Transaction_Group__c (after delete, after insert, after update, before delete, before insert, before update) {
   if(DML.checkTriggerDispatch(Bank_Transaction_Group__c.getSobjectType())){return;}
   if(ExceptionService.ignoreTrigger('Bank_Transaction_Group__c')){return;}
   
    if(trigger.isBefore){
        if(trigger.isInsert || trigger.isUpdate){
        	// set finalized hidden flag and validate user action of unfinalize
	       	KSE.setValidateFinalizedFlagonSD();
       	
       		//Set Finalized date.
			FinalizeService.setFinalizedDate(Trigger.new);
        } 	
        if(trigger.isDelete || trigger.isUpdate){
        	FinalizeService.validateHeaderFinalize();
        	
        } 	        
    }
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
            BankTransactionGroupService.setExceptions(trigger.new);
            BankTransactionGroupService.exService.finishTasks();
        }

    }
    BankTransactionGroupService.uncheckFinalizedFlagOnBT();
   // BankTransactionGroupService.validateAmountOnBankTransactionBeforeFinalize(); 
}