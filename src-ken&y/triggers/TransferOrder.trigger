trigger TransferOrder on Order__c (before delete, before insert, before update) {
	
	if(DML.checkTriggerDispatch(Order__c.getSobjectType())){return;}
	if(trigger.isbefore &&  trigger.isDelete)
		OrderService.orderTriggerBeforeActions(); 

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Order__c> recWithoutCurrency = new List<Order__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Order__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Receiving_Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Order__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Receiving_Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Receiving_Company__c);
            }   
        } 
    }

    if(trigger.isBefore && trigger.isUPdate){
        for(Order__c order: Trigger.new){
            if(order.status__c!='Draft' && trigger.oldMap.get(order.Id).Deliver_to_Facility__c!= trigger.newMap.get(order.Id).Deliver_to_Facility__c){
                order.addError('Cannot Update Order\'s deliver to facility after release' );
            }
        }
    }

}