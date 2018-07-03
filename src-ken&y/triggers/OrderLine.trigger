trigger OrderLine on Order_Line__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Order_Line__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Order_Line__c') == true) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true) OrderLineTriggerHandler.beforeInsert();
        else if (Trigger.isUpdate == true) OrderLineTriggerHandler.beforeUpdate();
        else OrderLineTriggerHandler.beforeDelete();
    } else {
        if (Trigger.isInsert == true) OrderLineTriggerHandler.afterInsert();
        else if (Trigger.isUpdate == true) OrderLineTriggerHandler.afterUpdate();
        else if (Trigger.isDelete == true) OrderLineTriggerHandler.afterDelete();
        else OrderLineTriggerHandler.afterUndelete();
    }
    
    if( trigger.isBefore ){
        OrderService.orderLineTriggerBeforeActions();
    }
    
    if( trigger.isAfter ){
    
        OrderService.orderLineTriggerAfterActions();
    }
}