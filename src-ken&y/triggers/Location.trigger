trigger Location on Location__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Location__c.sObjectType) || ExceptionService.ignoreTrigger('Location__c')) return;
    if (Trigger.isBefore && Trigger.isInsert) { LocationTriggerHandler.beforeInsert(); }
    if (Trigger.isAfter && Trigger.isInsert) { LocationTriggerHandler.afterInsert(); }
    if (Trigger.isBefore && Trigger.isUpdate) { LocationTriggerHandler.beforeUpdate(); }
    if (Trigger.isAfter && Trigger.isUpdate) { LocationTriggerHandler.afterUpdate(); }
    if (Trigger.isBefore && Trigger.isDelete) { LocationTriggerHandler.beforeDelete(); }
    if (Trigger.isAfter && Trigger.isDelete) { LocationTriggerHandler.afterDelete(); }
    if (Trigger.isAfter && Trigger.isUndelete) { LocationTriggerHandler.afterUndelete(); }
}