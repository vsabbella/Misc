trigger InventoryTransaction on Inventory_Transaction__c (before insert,before update,after update,after insert,before delete,after delete,after undelete) {   
    if (DML.checkTriggerDispatch(Inventory_Transaction__c.getSobjectType())){ return; }    
    
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        List<Inventory_Transaction__c> costIts = new List<Inventory_Transaction__c>();
        List<Inventory_Transaction__c> invtranslist = new List<Inventory_Transaction__c>();
        Set<Id> itIds = new set<Id>();
        for (Inventory_Transaction__c it:Trigger.new) {
            if (KSE.isFieldChanging('Quantity__c',it,trigger.oldMap) || KSE.isFieldChanging('To_Location__c',it,Trigger.oldMap) || KSE.isFieldChanging('From_Location__c',it,Trigger.oldMap)) {
                costIts.add(it);
            }
            if(Trigger.isBefore && Trigger.isUpdate){
            	itIds.add(it.Id);
            	invtranslist.add(it);
            }
        }
        
        if (costIts.size() > 0) {
            InventoryTransactionService.populateCosts(costIts);
        }
        if(itIds.size() > 0){
        	InventoryTransactionService.populateExtendedPrice(itIds,invtranslist);
        }
    }
    
    
    if ((Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete)) || (Trigger.isBefore && Trigger.isDelete)) {
        Set<Id> fulfillIts = new set<Id>();
        
        List<Inventory_Transaction__c> itList = new List<Inventory_Transaction__c>();
        
        if (Trigger.new != null) {
            itList.addAll(Trigger.new);
        }
        if (Trigger.old != null) {
            itList.addAll(Trigger.old);
        }
        
        for (Inventory_Transaction__c it:itList) {
            String itType = it.Type__c == null ? '' : it.Type__c;
            if ((itType.equalsIgnoreCase('Sales Order Shipment') || itType.equalsIgnoreCase('Sales Order Undo Shipment') || itType.equalsIgnoreCase('RMA Repair Shipment') || itType.equalsIgnoreCase('RMA Repair Undo Shipment')
            || itType.equalsIgnoreCase('Work Order Repair Assembly Completion') || itType.equalsIgnoreCase('Work Order Repair Assembly Uncompletion')) && it.Sales_Order_Line__c!= null) {
                fulfillIts.add(it.Id);
            }
        }
        
        if (fulfillIts.size() > 0) {
            FulfillmentService.updateInventoryTransactionMappings(fulfillIts);
        }
        FinalizeService.validateLineFinalize();
        
    }
    
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isDelete || trigger.isUndelete)) {
        Set<Id> headerIds = new Set<Id>();
        List<Inventory_Transaction__c> itList = new List<Inventory_Transaction__c>();
        
        if (Trigger.new != null) {
            itList.addAll(Trigger.new);
        }
        if (Trigger.old != null) {
            itList.addAll(Trigger.old);
        }
        
        for (Inventory_Transaction__c it:itList) {
            if (it.Inventory_Change__c != null && KSE.isFieldChanging('Inventory_Change__c',it,Trigger.oldMap)) {
                headerIds.add(it.Inventory_Change__c);
            }
            
        }
        
        if (headerIds.size() > 0) {
            InventoryTransactionService.setLineCounts(headerIds);
        }
    }
}