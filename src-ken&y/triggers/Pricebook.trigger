trigger Pricebook on Pricebook__c (before insert, before update, before delete) {
	if(DML.checkTriggerDispatch(Pricebook__c.getSobjectType())){return;}
	if ( Trigger.isBefore) { 
	 	if ( Trigger.isUpdate || Trigger.isInsert ) {
	 		Relate.setLookupUsingField(Trigger.new, Trigger.isBefore, 
		 		'Company__c', 
		 		'Company__c', 
		 		'Company_Identifier__c',
		 		'Company_Identifier__c');
	 	}
	}

	PricebookService.validateCompany();

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Pricebook__c> recWithoutCurrency = new List<Pricebook__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Pricebook__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Pricebook__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }	
    
    if(trigger.isBefore && trigger.isDelete){
		KSE.blockRecordDeletion();
	}

}