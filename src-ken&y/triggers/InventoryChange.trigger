trigger InventoryChange on Inventory_Change__c (before insert, before update, after update, before delete) {
	
	if(DML.checkTriggerDispatch(Inventory_Change__c.getSobjectType())){return;}
	
	if(trigger.isBefore && (trigger.isUpdate || trigger.isInsert)){
    	// set finalized hidden flag and validate user action of unfinalize
		KSE.setValidateFinalizedFlagonSD();
		
		// set finalized date on the shipment
       	FinalizeService.setFinalizedDate(Trigger.new);
    }
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
     	FinalizeService.validateHeaderFinalize();
	}

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Inventory_Change__c> recWithoutCurrency = new List<Inventory_Change__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Inventory_Change__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setCompanyCurrency(companyIDs);
            }
        
            for(Inventory_Change__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                	rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }  	
}