trigger BankTransactionMatch on Bank_Transaction_Match__c (after delete, after insert, after update, before delete, before insert, before update) {
    
    if(DML.checkTriggerDispatch(Bank_Transaction_Match__c.getSobjectType())){return;}
    
    BankTransactionMatchService.updateBTMatchApproveFlag();
    BankTransactionMatchService.updateUniqueKey();
}