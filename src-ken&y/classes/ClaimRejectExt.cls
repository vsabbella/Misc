public with sharing class ClaimRejectExt {
	
	public Apexpages.Standardcontroller con {get;set;}
	public boolean redirect {get;private set;}
	public boolean disableAction {get;private set;}
	public boolean canReject {get; private set;}
	public Claim__c refClaim {get;set;}
	
	public ClaimRejectExt(Apexpages.Standardcontroller controller){ 
		canReject = true;
		this.con = controller;
		if(!test.isRunningTest()){
			//This is a hack, but prevents us from having to load this in the standardcontroller via the markup
			this.con.addFields(new List<string>{'status__c', 'resolution_code__c','source__c', 'Enter_Claims_Notes__c'});
		}
	}
	
	public void validateRecord(){
		Claim__c claim = (Claim__c)con.getRecord(); // has user entered values in UI
		refClaim = ClaimService.returnClaimDetails(new set<Id>{claim.Id})[0]; // queried from database
		disableAction = false;
		if (claim.Source__c != ClaimService.SOURCE_MANUAL){
			canReject = false;
			disableAction = true;
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,Label.You_can_reject_only_a_claim_with_a_manual_source));
		}
		else if(claim.status__c == ClaimService.STATUS_CLOSED || claim.status__c == ClaimService.STATUS_CANCELLED){
			canReject = false;
			disableAction = true;
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,Label.Claim_is_closed));
		}
		else if(refClaim != null && refClaim.Claim_Lines__r.size() > 0){
			canReject = false;
			disableAction = true;
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,Label.You_can_t_reject_this_manual_claim_because_it_has_at_least_one_line));
		}
		else if(claim.Resolution_Code__c == null){
			disableAction = true;
		}
	}
	

	public PageReference RejectProcess()
	{
		Savepoint sp = Database.setSavepoint();
		try
		{
			//Flip the flag in the service class to reflect a manual action
			ClaimService.isManual = true;
			Claim__c claim = (Claim__c)con.getRecord();
			//Set user entered values in queried claim
			refClaim.Enter_Claims_Notes__c = claim.Enter_Claims_Notes__c;
			refClaim.Resolution_Code__c = claim.Resolution_Code__c;
			ClaimService.reject(new List<Claim__c>{refClaim});
			return null;
				
		}catch(Exception ex){
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
		}
		return null;
	}
	
	public pageReference reject(){
		pageReference ref;
		validateRecord();
		if(!disableAction ){
			//Flip the flag in the service class to reflect a manual action
			ref = RejectProcess();
			redirect = true;
			return null;
		}
		else {
			redirect = false;
			return null;
		}

		
	
	}
}