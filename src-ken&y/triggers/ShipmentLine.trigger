trigger ShipmentLine on Shipment_Line__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Shipment_Line__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Shipment_Line__c') == true) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true) ShipmentLineTriggerHandler.beforeInsert();
        else if (Trigger.isUpdate == true) ShipmentLineTriggerHandler.beforeUpdate();
        else ShipmentLineTriggerHandler.beforeDelete();
    } else {
        if (Trigger.isInsert == true) ShipmentLineTriggerHandler.afterInsert();
        else if (Trigger.isUpdate == true) ShipmentLineTriggerHandler.afterUpdate();
        else if (Trigger.isDelete == true) ShipmentLineTriggerHandler.afterDelete();
        else ShipmentLineTriggerHandler.afterUndelete();
    }
   	
    //OTC-189
    ShipmentLineService.calculateRollupFields();
            
    ShipmentLineService.rollupSalesOrderLineQuantities();        
    
    if(trigger.isAfter & (trigger.isInsert || trigger.isUpdate)){
		
		Set<Id> shipmentIds = new Set<Id>();
		
		for(Shipment_Line__c shipmentLine : (List<Shipment_Line__c>) trigger.new){
			if(trigger.isInsert || 
				(trigger.isUpdate && 
					(KSE.isFieldChanging('Location__c', shipmentLine, trigger.oldMap) ||
					 KSE.isFieldChanging('Shipment__c', shipmentLine, trigger.oldMap) 
					)
				)
			){	
				shipmentIds.add(shipmentLine.Shipment__c);
			}
		}
		
		if(shipmentIds.size() > 0){
			// Set the estimated shipment date
			ShipmentService.setShipmentDates(shipmentIds);
		}
	}
	
	// OTC-16:
	ShipmentLineService.validateSalesOrderLinePrices();
	
	// OTC-18: Manage demand skids
    ShipmentLineService.manageSkids();
    
    // OTC-18: Delete shipment header if all of its lines are deleted. 
    ShipmentService.deleteShipments();
    
    ShipmentLineService.validateShipDate();
    
    //Non-inventory fulfillment
    set<Id> shlIds = new set<Id>();
    if(trigger.isAfter){
    	if(trigger.isInsert || trigger.isUpdate){
    		for(Shipment_Line__c shl : trigger.new){
    			if((shl.Quantity_Shipped__c != 0 && shl.Quantity_Shipped__c != null && trigger.isInsert) 
    					|| (KSE.isFieldChanging('Quantity_Shipped__c', shl, trigger.oldMap) && trigger.isUpdate)){
    				 shlIds.add(shl.Id);
    			}
    		}
    	}
    	else if(trigger.isUndelete){
    		for(Shipment_Line__c shl : trigger.old){
    			if(shl.Quantity_Shipped__c != 0 && shl.Quantity_Shipped__c != null) shlIds.add(shl.Id);
    		}
    	}
    }
    
    if(trigger.isBefore){
    	if(trigger.isDelete){
    		for(Shipment_Line__c shl : trigger.old){
    			if(shl.Quantity_Shipped__c != 0 && shl.Quantity_Shipped__c != null) shlIds.add(shl.Id);
    		}
    	}
    }
    
    if(shlIds.size() > 0){
    	FulfillmentService.fulfillNonInventoryItems(shlIds);
    }
	
	///FIN-209 validate the line for finalized document
	if( ( trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete) )
			|| (trigger.isBefore && trigger.isDelete) )
	{
			FinalizeService.validateLineFinalize();

	}
	
	if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
		ShipmentLineService.exService.finishTasks();
	}
}