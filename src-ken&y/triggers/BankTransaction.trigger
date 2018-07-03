trigger BankTransaction on Bank_Transaction__c (after delete, after insert, after update, before delete, before insert, before update) {
    if(DML.checkTriggerDispatch(Bank_Transaction__c.getSobjectType())){return;}
    if(ExceptionService.ignoreTrigger('Bank_Transaction__c')){return;}
    if(trigger.isAfter){
        if(trigger.isUpdate) {
        	FinalizeService.validateLineFinalize(); 
        }
    }
    if(trigger.isBefore){
        if(trigger.isUpdate){
        	// set finalized hidden flag and validate user action of unfinalize
	       	BankTransactionService.setValidateFinalizedFlagonBT();
        } 
        if(trigger.isDelete){
        	FinalizeService.validateLineFinalize();       	
        } 	 	   	        
    }
    BankTransactionService.validateAmountOnBankTransactionBeforeApproved();
    BankTransactionService.populateFinalizedFlag();
    BankTransactionService.createGroupOnCreationOfBankTransaction();
    BankTransactionService.restrictDeletionOfFinalizedTransaction();
    //BankTransactionService.populateFinalizedFlagOnBTG();
    BankTransactionService.syncBTChangesOnBTG();
    BankTransactionService.deleteBTM();	
}