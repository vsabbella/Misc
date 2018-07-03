public with sharing class ClaimWriteOffExt {
	
	public ClaimWriteOffExt(Apexpages.Standardcontroller controller){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This function is not available.'));
	}
	
	
	/*
	public Apexpages.Standardcontroller con {get;set;}
	public boolean disableAction {get;private set;}
	
	//This functionality is being abandoned, forcing write offs to be created as customer receipt lines at the time of cash application for the time being
	public ClaimWriteOffExt(Apexpages.Standardcontroller controller){
		this.con = controller;
		if(!test.isRunningTest()){
			//This is a hack, but prevents us from having to load this in the standardcontroller via the markup
			this.con.addFields(new List<string>{'status__c'});
		}
		validateRecord();
	}
	
	public void validateRecord(){
		Claim__c claim = (Claim__c)con.getRecord();
		if(claim.status__c == ClaimService.STATUS_CLOSED){
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'This claim is closed and cannot be written off.'));
		}else{
			disableAction = false;
		}
	}
	
	public void writeOff(){
		Savepoint sp = Database.setSavepoint();
		try{
			validateRecord();
			if(!disableAction){
				ClaimService.writeoffClaims(new set<Id>{con.getId()});
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'This claim was successfully written off.'));
			}
		}catch(Exception ex){
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There was an error while attempting to write off the claim: ' + ex.getMessage()));
		}finally{
			disableAction = true;
		}
	}
	*/
}