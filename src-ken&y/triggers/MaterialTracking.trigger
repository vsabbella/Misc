trigger MaterialTracking on Material_Tracking__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Material_Tracking__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Material_Tracking__c') == true) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true) MaterialTrackingTriggerHandler.beforeInsert();
        else if (Trigger.isUpdate == true) MaterialTrackingTriggerHandler.beforeUpdate();
        else MaterialTrackingTriggerHandler.beforeDelete();
    } else {
        if (Trigger.isInsert == true) MaterialTrackingTriggerHandler.afterInsert();
        else if (Trigger.isUpdate == true) MaterialTrackingTriggerHandler.afterUpdate();
        else if (Trigger.isDelete == true) MaterialTrackingTriggerHandler.afterDelete();
        else MaterialTrackingTriggerHandler.afterUndelete();
    }
}