trigger SupplierPayment on Supplier_Payment__c (before update, before delete, before insert) { 

	if(DML.checkTriggerDispatch(Supplier_Payment__c.getSobjectType())){return;}
	
static SchemaUtil util = SchemaUtil.getInstance();   

//VoidCancelService.validateHeader(); 

     if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate) ){
        SupplierPaymentService.setTransactionDate(Trigger.New);//KNDY-10280 KNDY-12343
        
     	// set finalized hidden flag and validate user action of unfinalize
     	KSE.setValidateFinalizedFlagonSD();
     	
     	// set finalized date on the shipment
       	FinalizeService.setFinalizedDate(Trigger.new);
     }
        
    if(trigger.isBefore && trigger.isDelete){
        for(Supplier_Payment__c SPayment: Trigger.old){
            if (((KSE.isFieldChanging('Status__c', SPayment, Trigger.oldMap)) == False) && SPayment.Void__c){
                    SPayment.addError(Label.Voided_SupplierPayment_cannot_be_Deleted);
            }
        }
    }
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
     	FinalizeService.validateHeaderFinalize();
	}

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Supplier_Payment__c> recWithoutCurrency = new List<Supplier_Payment__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Supplier_Payment__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Supplier_Payment__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }    
            
}