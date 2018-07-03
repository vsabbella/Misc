trigger OperationTransaction on Operation_Transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Operation_Transaction__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Operation_Transaction__c') == true) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true) OperationTransactionTriggerHandler.beforeInsert();
        else if (Trigger.isUpdate == true) OperationTransactionTriggerHandler.beforeUpdate();
        else OperationTransactionTriggerHandler.beforeDelete();
    } else {
        if (Trigger.isInsert == true) OperationTransactionTriggerHandler.afterInsert();
        else if (Trigger.isUpdate == true) OperationTransactionTriggerHandler.afterUpdate();
        else if (Trigger.isDelete == true) OperationTransactionTriggerHandler.afterDelete();
        else OperationTransactionTriggerHandler.afterUndelete();
    }
}