trigger Payment on Payment__c (before insert, before update, after update, before delete) {
    
    if(DML.checkTriggerDispatch(Payment__c.getSobjectType())){return;}
    
    if(ExceptionService.ignoreTrigger('Payment__c')){return;}
    
    if(trigger.isBefore && ( trigger.isInsert || trigger.isUpdate)){
        KSE.setValidateFinalizedFlagonSD();
        FinalizeService.setFinalizedDate_SD(Trigger.new);
    }
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
        FinalizeService.validateHeaderFinalize();
    }
    
    PaymentService.onFinalizeChange();
    
    PaymentService.paymentCleanup();
    PaymentService.onUnfinalize(); //KNDY-10986
    PaymentService.pmtExService.finishTasks();

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Payment__c> recWithoutCurrency = new List<Payment__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Payment__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.From_Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Payment__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.From_Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.From_Company__c);
            }   
        } 
    }    
    
    
}