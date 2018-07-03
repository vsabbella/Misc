trigger Calendar on Calendar__c (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    if (DML.checkTriggerDispatch(Calendar__c.getSobjectType()) || ExceptionService.ignoreTrigger('Calendar__c')) { return; }
    if (Trigger.isBefore && Trigger.isInsert) { CalendarTriggerHandler.beforeInsert(); }
    if (Trigger.isAfter && Trigger.isInsert) { CalendarTriggerHandler.afterInsert(); }
    if (Trigger.isBefore && Trigger.isUpdate) { CalendarTriggerHandler.beforeUpdate(); }
    if (Trigger.isAfter && Trigger.isUpdate) { CalendarTriggerHandler.afterUpdate(); }
    if (Trigger.isBefore && Trigger.isDelete) { CalendarTriggerHandler.beforeDelete(); }
    if (Trigger.isAfter && Trigger.isDelete) { CalendarTriggerHandler.afterDelete(); }
    if (Trigger.isAfter && Trigger.isUndelete) { CalendarTriggerHandler.afterUndelete(); }
}