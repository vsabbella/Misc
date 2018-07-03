trigger WorkingDay on Working_Day__c (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    if (DML.checkTriggerDispatch(Working_Day__c.getSobjectType()) || ExceptionService.ignoreTrigger('Working_Day__c')) { return; }
    if (Trigger.isBefore && Trigger.isInsert) { WorkingDayTriggerHandler.beforeInsert(); }
    if (Trigger.isAfter && Trigger.isInsert) { WorkingDayTriggerHandler.afterInsert(); }
    if (Trigger.isBefore && Trigger.isUpdate) { WorkingDayTriggerHandler.beforeUpdate(); }
    if (Trigger.isAfter && Trigger.isUpdate) { WorkingDayTriggerHandler.afterUpdate(); }
    if (Trigger.isBefore && Trigger.isDelete) { WorkingDayTriggerHandler.beforeDelete(); }
    if (Trigger.isAfter && Trigger.isDelete) { WorkingDayTriggerHandler.afterDelete(); }
    if (Trigger.isAfter && Trigger.isUndelete) { WorkingDayTriggerHandler.afterUndelete(); }
}