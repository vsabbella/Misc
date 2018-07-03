trigger AllocationProfile on Allocation_Profile__c (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
    if (DML.checkTriggerDispatch(Allocation_Profile__c.getSobjectType()) || ExceptionService.ignoreTrigger('Allocation_Profile__c')) { return; }
    if (Trigger.isBefore && Trigger.isInsert) { AllocationProfileTriggerHandler.beforeInsert(); }
    if (Trigger.isAfter && Trigger.isInsert) { AllocationProfileTriggerHandler.afterInsert(); }
    if (Trigger.isBefore && Trigger.isUpdate) { AllocationProfileTriggerHandler.beforeUpdate(); }
    if (Trigger.isAfter && Trigger.isUpdate) { AllocationProfileTriggerHandler.afterUpdate(); }
    if (Trigger.isBefore && Trigger.isDelete) { AllocationProfileTriggerHandler.beforeDelete(); }
    if (Trigger.isAfter && Trigger.isDelete) { AllocationProfileTriggerHandler.afterDelete(); }
    if (Trigger.isAfter && Trigger.isUndelete) { AllocationProfileTriggerHandler.afterUndelete(); }
}