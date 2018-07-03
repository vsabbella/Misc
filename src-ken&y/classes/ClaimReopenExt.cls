public with sharing class ClaimReopenExt {
	
	Apexpages.Standardcontroller con {get;set;}
	public boolean redirect {get;private set;}
	public boolean isValid {get; private set;}
	
	public ClaimReopenExt(Apexpages.Standardcontroller controller){
		this.con = controller;
	}
	
	public pageReference reopen(){
		try{
			if (con.getRecord().get('Settlement_Method__c') == ClaimService.SETTLEMENT_METHOD_REFUND){ //KNDY-15255
				throw ClaimService.getClaimReopenException_SettlementTypeRefund(new set<Id>{con.getId()});
			}else{
				ClaimService.reopen(new set<Id>{con.getId()});
			}
			redirect = true;
			return null;
		}catch(Exception ex){
			Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			redirect = false;
			return null;
		}
	}
	
}