trigger PurchasingContract on Contract__c (before insert, before delete, before update, after update) {
	if(DML.checkTriggerDispatch(Contract__c.getSobjectType())){return;}
	ContractService CC = new ContractService();
//	VoidCancelService.validateHeader();   //PTP-392
	
	if ( Trigger.isBefore ) {
        if (Trigger.isInsert) {
        	CC.defaultPymtTermsFromSupplier(Trigger.new);
		        //Currency Defaulting Logic
		        Set<ID> companyIDs = new set<ID>();
		        List<Contract__c> recWithoutCurrency = new List<Contract__c>();
		        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
		            for(Contract__c rec : trigger.new){
		                 if(rec.Currency__c ==  NULL){
		                    companyIDs.add(rec.Company__c);
		                    recWithoutCurrency.add(rec);
		                 }   
		            }
		        
		            if(companyIDs.size() > 0 ){
		                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
		            }
		        
		            for(Contract__c rec : recWithoutCurrency){
		                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
		                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
		            }   
		        }        	
        }
	    if (Trigger.isDelete) { 
	    	for (Contract__c c : Trigger.old) {
		        if (c.PurchasedValue__c > 0) { //KNDY-7997 - Changed the Field reference from Purchased_Value__c to PurchasedValue__c
		            c.addError(Label.Agreement_with_related_releases_cannot_be_deleted);
		        } 
	        }
	    }
	    if (Trigger.isUpdate){
	    		CC.flipPAApprovalStatus_ContractChange (Trigger.new, Trigger.oldMap); 
	    		CC.updatePAStatusWhenApproved (Trigger.new, Trigger.old);
	    		CC.setContractLinestoApproved (Trigger.new, Trigger.old);
	    		//PTP-306
       			try
	            {
		            CC.runAVLValidationsOnClonedLines();
	            }catch(Exception ex)
	            {
	            	throw ex;
	            }
       			
       			
	    	}	
	    }
    if (trigger.isAfter && trigger.isUpdate){
    	//CC.checkifAgreementCanbeEdited (Trigger.new, Trigger.old);    Commented this as part of PTP-392 as this logic is covered in VoidCancelService.cls, ValidateHeader method
    	CC.updatelineStatusonHeaderChange (Trigger.new, Trigger.old);   	
    }
}