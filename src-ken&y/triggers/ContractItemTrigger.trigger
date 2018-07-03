trigger ContractItemTrigger on Contract_Line__c (after insert, after update, after delete, before insert, before update, before delete) {
	
	if(DML.checkTriggerDispatch(Contract_Line__c.getSobjectType())){return;}
	
    ContractService CC = new ContractService();
    
    CC.flipPAApprovalStatus_ContractLineChange(); //KNDY-11429
    
    if(Trigger.isAfter){
    
        if(Trigger.isUpdate){
            ContractService.checkForDuplicateLineExistanceTrigger(Trigger.new, Trigger.oldMap); //KNDY-10599
            CC.updatePOLines(Trigger.new, Trigger.oldMap);
            CC.updateAgreementtoExpired(Trigger.new);
        }
        if (Trigger.isInsert){
            ContractService.checkForDuplicateLineExistanceTrigger(Trigger.new, Trigger.oldMap); //KNDY-10599
        }
    
    }else if(Trigger.isBefore){
        if(trigger.isInsert){
            CC.checkifContractLinehasItem (Trigger.new);
            CC.checkifPALinehasUOMFromTrigger (Trigger.new);//KNDY-10599
        }
        if(Trigger.isUpdate){
            CC.checkifContractLinehasItem (Trigger.new);
            CC.checkifPALinehasUOMFromTrigger (Trigger.new);//KNDY-10599
            CC.checkifContractLinehasPOLine(trigger.new, trigger.old);
            CC.updatecLineStatus(Trigger.new, Trigger.old);
            //CC.reopenContractLines(Trigger.new,Trigger.old);
            
        }
        if(Trigger.isDelete ) {   
            CC.approvedContractLineValidation(trigger.old); 
		}
		if(Trigger.isInsert || Trigger.isUpdate){
			CC.defaultInvoiceMatchingFromSupplier(Trigger.new);
		}
        
    }
    

}