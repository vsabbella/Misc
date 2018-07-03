trigger BankAccount on Bank_Account__c (before update,before delete,before insert) {
	     
	 if(DML.checkTriggerDispatch(Bank_Account__c.getSobjectType())){return;}
	         //FIN-632
	   if(trigger.isDelete || trigger.isUpdate ){ 
	         for(Bank_Account__c bnkAcnt : trigger.old){
              if (trigger.isUpdate ) {
                if(KSE.isFieldChanging('Company__c', bnkAcnt, Trigger.newMap)){
                	//commented method call for kndy-10268 deprecating bank_file__c object // && CompanyService.checkBankFileAvailability(bnkAcnt)
	              if ( ! (CompanyService.checkSupplierPaymentsAvailability(bnkAcnt)) ) {
                         //KNDY-8329
                         Trigger.newMap.get(bnkAcnt.id).Company__c.addError(Label.Cannot_change_the_company_tagged_to_a_bank_account); 
	              } 
	           }   
	        }
              else if(trigger.isDelete){
              	//commented method call for kndy-10268 deprecating bank_file__c object // && CompanyService.checkBankFileAvailability(bnkAcnt)
                if ( ! (CompanyService.checkSupplierPaymentsAvailability(bnkAcnt) ) ) {
                        bnkAcnt.addError(Label.Cannot_delete_bank_account_tagged_to_supplier_payments); 
                  } 
              }
	      }
	   }

	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
		for(Bank_Account__c ba : trigger.new) {
			if(ba.Opening_Balance_Date__c != null && (trigger.isInsert || (trigger.isUpdate && KSE.isFieldChanging('Opening_Balance_Date__c', ba, trigger.oldmap ))) ) {
				DateTime openingDateTime = ba.Opening_Balance_Date__c;
				ba.Opening_Balance_Date__c = DateTime.newInstance(openingDateTime.year(), openingDateTime.month(), openingDateTime.day()+1, 0, 0, 0).addSeconds(-1);
			}
			ba.GL_Account_Unique__c = ba.GL_Account__c; //KNDY-17244
		}
	}
	      
	      if(trigger.isBefore &&  trigger.isInsert){
					set<Id> companyIdSet = new set<Id>();
					map<Id,Id> mCompanyDefaultCurr = new map<Id,Id>();
					list<Bank_Account__c> baUpdateList = new list<Bank_Account__c>();
					for(Bank_Account__c thisAcc: Trigger.new){
						if(thisAcc.currency__c == null && thisAcc.company__c != null){
							companyIdSet.add(thisAcc.company__c);
							baUpdateList.add(thisAcc);
						}
						
					}
					
					if(companyIdSet != null && companyIdSet.size()> 0){
						mCompanyDefaultCurr = CompanyService.setDefaultCurrency(companyIdSet);
					
					
						      
						for(Bank_Account__c thisAcc: baUpdateList){
							if((thisAcc.currency__c == null ) && mCompanyDefaultCurr != null && mCompanyDefaultCurr.containsKey(thisAcc.company__c)){
								thisAcc.currency__c = mCompanyDefaultCurr.get(thisAcc.company__c);
							}
							
						}
					}
	      }	      
}