trigger Operation on Operation_Tracking__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Operation_Tracking__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Operation_Tracking__c') == true) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true) OperationTriggerHandler.beforeInsert();
        else if (Trigger.isUpdate == true) OperationTriggerHandler.beforeUpdate();
        else OperationTriggerHandler.beforeDelete();
    } else {
        if (Trigger.isInsert == true) OperationTriggerHandler.afterInsert();
        else if (Trigger.isUpdate == true) OperationTriggerHandler.afterUpdate();
        else if (Trigger.isDelete == true) OperationTriggerHandler.afterDelete();
        else OperationTriggerHandler.afterUndelete();
    }
}