trigger Component on Component__c (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    if (DML.checkTriggerDispatch(Component__c.getSobjectType()) || ExceptionService.ignoreTrigger('Component__c')) { return; }
    if (Trigger.isBefore && Trigger.isInsert) { ComponentTriggerHandler.beforeInsert(); }
    if (Trigger.isAfter && Trigger.isInsert) { ComponentTriggerHandler.afterInsert(); }
    if (Trigger.isBefore && Trigger.isUpdate) { ComponentTriggerHandler.beforeUpdate(); }
    if (Trigger.isAfter && Trigger.isUpdate) { ComponentTriggerHandler.afterUpdate(); }
    if (Trigger.isBefore && Trigger.isDelete) { ComponentTriggerHandler.beforeDelete(); }
    if (Trigger.isAfter && Trigger.isDelete) { ComponentTriggerHandler.afterDelete(); }
    if (Trigger.isAfter && Trigger.isUndelete) { ComponentTriggerHandler.afterUndelete(); }
}