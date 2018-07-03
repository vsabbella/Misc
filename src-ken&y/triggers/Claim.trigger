trigger Claim on Claim__c (after insert, after update, before update, before insert) {
	public class ClaimException extends Exception{}
	 if(DML.checkTriggerDispatch(Claim__c.getSobjectType())){return;}
	if(ExceptionService.ignoreTrigger(KSE.NameSpaceUU + 'Claim__c')){return;}
	ProcessHandler.Dispatch();
	ClaimService.autoCreate(); //AR-106
	ClaimService.populateCorrespondent();
	if(trigger.isBefore){	
        if(trigger.isUpdate){
        	SchemaUtil util = SchemaUtil.getInstance();
    		Set<String> claimFields = new Set<String>();
			claimFields.addAll(util.getFieldsFromFieldSetString(Claim__c.sObjectType , 'ClaimFieldSet'));
			for(Claim__c claim: Trigger.new){
				Claim__c iClaimBeforeUpdate = System.Trigger.oldMap.get(claim.Id);
				String claimStatus = claim.Status__c;
				String iClaimBeforeUpdateStatus = iClaimBeforeUpdate.Status__c;
				for(String localString : claimFields){
					if(claim.get(localString) != iClaimBeforeUpdate.get(localString)){
						if(localString == KSE.NameSpaceUU +'Status__c'){
							if(iClaimBeforeUpdate.get(localString) == 'Closed' && !claim.Currently_Reopened_Flag__c && claim.Status__c != ClaimService.STATUS_CANCELLED){
								claim.addError(Label.Open_the_Claim_using_the_Reopen_button);
							}
							if(claim.get(localString) == 'Closed'){
								claim.Currently_Reopened_Flag__c = false;
							}
						}
						if(!(localString == KSE.NameSpaceUU +'Status__c')){
							if(claim.Status__c == 'Closed' && (string)trigger.oldMap.get(claim.Id).get(KSE.NameSpaceUU +'Status__c') == 'Closed'){
								if(claim.Currently_Reopened_Flag__c == false){
									system.debug('inside the kse part' + localString);
									Boolean isFieldChangingFlag =  KSE.isFieldChanging(localString , claim, Trigger.oldMap);
						    		if(isFieldChangingFlag){
							            claim.addError(Label.Cannot_edit_a_closed_claim_without_reopening);
							        }
								}
							}
						}
					}
		    	}
			}
        }
    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Claim__c> recWithoutCurrency = new List<Claim__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Claim__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Claim__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }        
        /**
		if((trigger.isUpdate || trigger.isInsert)){
			set<Id> companyIdSet = new set<Id>();
			map<Id,Id> mCompanyDefaultCurr = new map<Id,Id>();
			for(Claim__c claim: Trigger.new){
				if((claim.currency__c == null || claim.currency__c == '') && claim.company__c != null){
					companyIdSet.add(claim.company__c);
				}
				
			}
			
			if(companyIdSet != null && companyIdSet.size()> 0){
				mCompanyDefaultCurr = CompanyService.setDefaultCurrency(companyIdSet);
			
			}
				      
			for(Claim__c claim: Trigger.new){
				if((claim.currency__c == null || claim.currency__c == '' ) && mCompanyDefaultCurr != null && mCompanyDefaultCurr.containsKey(claim.company__c)){
					claim.currency__c = mCompanyDefaultCurr.get(claim.company__c);
				}
				
			}
	      }
	      **/
		}			
}