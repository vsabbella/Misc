trigger WorkOrderTrigger on Work_Order__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) { 
    if (DML.checkTriggerDispatch(Work_Order__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Work_Order__c') == true) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true) WorkOrderTriggerHandler.beforeInsert();
        else if (Trigger.isUpdate == true) WorkOrderTriggerHandler.beforeUpdate();
        else WorkOrderTriggerHandler.beforeDelete();
    } else {
        if (Trigger.isInsert == true) WorkOrderTriggerHandler.afterInsert();
        else if (Trigger.isUpdate == true) WorkOrderTriggerHandler.afterUpdate();
        else if (Trigger.isDelete == true) WorkOrderTriggerHandler.afterDelete();
        else WorkOrderTriggerHandler.afterUndelete();
    }

    
    if (Trigger.isBefore) {
        if (Trigger.isUpdate || Trigger.isInsert) {
            List<Work_Order__c> workOrders = new List<Work_Order__c>();
            for (Work_Order__c wo:Trigger.new) {
                wo.Has_Contents__c = String.isBlank(wo.Contents__c) == false;
                if (Trigger.isUpdate && KSE.isFieldChanging('Order_Quantity__c', wo, Trigger.oldMap)) workOrders.add(wo);
            }

            if (workOrders.size() > 0) WorkOrderPlanningService.validateQuantityChange(workOrders, Trigger.oldMap);
        } else {
            for (Work_Order__c wo:Trigger.old) {
                if (wo.Type__c == WorkOrderService.WO_TYPE_SUBCONTRACT) {
                    wo.addError(Label.SubContract_Work_Order_cannot_be_deleted);
                } else if (wo.status__c != WorkOrderService.WO_STATUS_DRAFT) {
                    wo.addError(Label.Work_Order_cannot_be_deleted);
                }
            }
            SKIDService.deleteSkids(Trigger.oldMap, 'WO Supply');
        }
    } else if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        Set<Id> itemSpecIds = new Set<Id>();
        
        for (Work_Order__c wo:Trigger.new) {
        	
        	if(KSE.isFieldChanging('Assembly_Item_Specification__c', wo, Trigger.oldMap)||
                        KSE.isFieldChanging('Quantity_to_Complete__c', wo, Trigger.oldMap)||
                        KSE.isFieldChanging('Complete_to_Location__c', wo, Trigger.oldMap)||
                        KSE.isFieldChanging('Need_date2__c', wo, Trigger.oldMap) || 
                        KSE.isFieldChanging('Start_date2__c', wo, Trigger.oldMap) ||
                        KSE.isFieldChanging('Packaging_UOM__c', wo, Trigger.oldMap)
            ){
            	itemSpecIds.add(wo.Assembly_Item_Specification__c);
            }
        }
        Map<Id,Id> assemblyItemMap = ItemService.getAssembyItemIds(itemSpecIds);
            
        if (Trigger.isInsert) {
            SKIDService.insertSkids(Trigger.newMap,'WO Supply',assemblyItemMap);
        } else if (Trigger.isUpdate) {
        	if(assemblyItemMap.values().size()>0)
            	SKIDService.updateSkids(Trigger.oldMap,Trigger.newMap,'WO Supply',assemblyItemMap);
        }
    }
    
    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Work_Order__c> recWithoutCurrency = new List<Work_Order__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Work_Order__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Work_Order__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }
}