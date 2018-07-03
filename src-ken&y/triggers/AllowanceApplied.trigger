trigger AllowanceApplied on Allowance_Applied__c (before insert, before update, before delete,
						after insert, after update, after delete) { 
	
	if(DML.checkTriggerDispatch(Allowance_Applied__c.getSobjectType())){return;}

	//if ( trigger.isBefore && (trigger.isInsert || trigger.isUpdate )) {
		//for (Allowance_Applied__c aa:trigger.new ) {
		//	if ( string.isBlank(aa.Unique_Key__c ) && (aa.Source__c!='Trade') ) {  // manual inserts may have this null, exempt trade per KNDY-6032
		//		aa.Unique_Key__c = AllowanceRuleService.genUniqueKey( null, aa );
		//	}
		//}
	//}
	if ( trigger.isBefore && trigger.isInsert){
		for (Allowance_Applied__c aa : (List<Allowance_Applied__c>) trigger.new) {
			if(aa.Allowance_Type__c == null){
				aa.addError('Allowance type cannot be empty');
			}
		}
	}
	// prevent updating for changing set lookup values. This could happen for One-time allowance because of unique key upserting
	if (trigger.isBefore && trigger.isUpdate){
		for (Allowance_Applied__c aa : (List<Allowance_Applied__c>) trigger.new) {
			if (KSE.isFieldChanging('Customer_Invoice2__c', aa, trigger.oldMap)) {
				aa.Customer_Invoice2__c = trigger.oldMap.get(aa.id).Customer_Invoice2__c;
			}
			if (KSE.isFieldChanging('Customer_Invoice_Line__c', aa, trigger.oldMap)) {
				aa.Customer_Invoice_Line__c = trigger.oldMap.get(aa.id).Customer_Invoice_Line__c;
			}
		}
	}
	
	// validation if AA's SO is fully invoiced
	if (trigger.isBefore){

		List<Allowance_Applied__c> soAAs = new List<Allowance_Applied__c>();
		Set<Id> aaSolIds = new Set<Id>();
        Set<Id> aaSoIds = new Set<Id>();

		if (trigger.isInsert || trigger.isUpdate){
			for (Allowance_Applied__c aa : (List<Allowance_Applied__c>) trigger.new) {
				if (aa.Sales_Order_Line__c != null || aa.Sales_Order__c != null){
					aaSolIds.add(aa.Sales_Order_Line__c);
					aaSoIds.add(aa.Sales_Order__c);
					soAAs.add(aa);
				}
			}
		}

		if (trigger.isDelete){
			for (Allowance_Applied__c aa : (List<Allowance_Applied__c>) trigger.old) {
				if (aa.Sales_Order_Line__c != null || aa.Sales_Order__c != null){
					aaSolIds.add(aa.Sales_Order_Line__c);
					aaSoIds.add(aa.Sales_Order__c);
					soAAs.add(aa);
				}
			}
		}

		aaSoIds.remove(null);
		aaSolIds.remove(null);

		if (!soAAs.isEmpty()){
			AllowanceService.validateInvoicedStatus(soAAs, aaSoIds, aaSolIds);
		}
	}

	if (trigger.isAfter){
	    
	    List<Allowance_Applied__c> aaList = new List<Allowance_Applied__c>();
	    
	    //KNDY-6032 filtering out source=trade from updateAllowanceAmmount
    	if(trigger.isDelete) {
    		for (Allowance_Applied__c aa: trigger.old) {
    			if (aa.Source__c!='Trade') {
    				aaList.add(aa);
    			}
    		}
    	}
    
        if (trigger.isInsert || trigger.isUpdate ) {
            
    		for (Allowance_Applied__c aa: trigger.new) {
    			if (aa.Source__c!='Trade' && ( trigger.isInsert || (trigger.isUpdate
					&& (KSE.isFieldChanging('Allowance_Amount__c', aa, trigger.oldMap)
						|| KSE.isFieldChanging('BillBack_Commitment__c', aa, trigger.oldMap) )))) {
    				aaList.add(aa);
    			}
    		}	    
        }
        
        if (!aaList.isEmpty()) {
    		AllowanceService.updateAllowanceAmmount(aaList);
        }
	}
}