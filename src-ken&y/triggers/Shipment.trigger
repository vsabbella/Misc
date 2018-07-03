trigger Shipment on Shipment__c (before insert, before update, after update, before delete) {
	
	if(DML.checkTriggerDispatch(Shipment__c.getSobjectType())){return;}
	
	// Ignore the exceptions count update.
   	if(ExceptionService.ignoreTrigger('Shipment__c')){return;}
   
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		// set finalized hidden flag and validate user action of unfinalize
		KSE.setValidateFinalizedFlagonSD();
		
		//set finalized date on shipment
		FinalizeService.setFinalizedDate(Trigger.new);
	}
	
	if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
		// FIN-209 validate the header for finalize
		FinalizeService.validateHeaderFinalize();
	}

	if (trigger.isBefore && trigger.isUpdate){
		//OTC-189
		ShipmentService.setDimensionalWeight();
		
		//OTC-800
		ShipmentService.onlyFinalizeIfConfirmed();
	}
	
	if(trigger.isAfter && trigger.isUpdate){
		ShipmentService.rollupSalesOrderLineQuantities();
		ShipmentService.setShipmentDates();
	
		ShipmentService.setEstimatedDeliveryDate();
	}
	
	//OTC-16
	ShipmentService.validateSalesOrderLinePrices();
	
	if(trigger.isAfter && trigger.isUpdate){
		// OTC-360
		//ShipmentService.validateShipmentWeight();
		ShipmentService.validateShipments();
		ShipmentService.validateShipDate();
	}	
	
	if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
		ShipmentService.updateSOPricingDate();
		ShipmentService.exService.finishTasks();
	}
	
	//Force cascade delete lines when header is deleted.
	if(trigger.isBefore && trigger.isDelete){
		ShipmentService.isShipmentDelete = true;
				
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Set<Id> shIds = trigger.oldMap.keySet();
		
		SOQLUtil soql = new SOQLUtil('Shipment_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('Shipment__c IN :shIds');
	
		DML.deleteAsUser(Database.query(soql.getQuery()));
	}

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Shipment__c> recWithoutCurrency = new List<Shipment__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Shipment__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Shipment__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }

}