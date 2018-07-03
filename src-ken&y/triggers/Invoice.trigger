trigger Invoice on Invoice__c (before insert, before update, before delete) {
	if(DML.checkTriggerDispatch(Invoice__c.getSobjectType())){return;}
	if(trigger.isBefore && ( trigger.isInsert || trigger.isUpdate)){

		InvoiceService.invoiceChangedTrigger(Trigger.new, Trigger.oldMap);

		KSE.setValidateFinalizedFlagonSD();
		FinalizeService.setFinalizedDate_SD(Trigger.new);
	}
	
	if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
     	FinalizeService.validateHeaderFinalize();
	}

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Invoice__c> recWithoutCurrency = new List<Invoice__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Invoice__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.From_Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Invoice__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.From_Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.From_Company__c);
            }   
        } 
    }	

}