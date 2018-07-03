public with sharing class ClaimResolveExt {
	
	public Apexpages.Standardcontroller con {get;set;}
	public boolean redirect {get;private set;}
	public boolean disableAction {get;private set;}
	public boolean renderNonmatchingcodes {get;private set;}
	public boolean isClosed {get; private set;}
	public Claim__c refClaim {get;set;}
	
	public ClaimResolveExt(Apexpages.Standardcontroller controller){ 
		this.con = controller;
		if(!test.isRunningTest()){
			//This is a hack, but prevents us from having to load this in the standardcontroller via the markup
			this.con.addFields(new List<string>{'status__c', 'resolution_code__c','manage__c','source__c'});
		}
		renderNonmatchingcodes=false;
	}
	
	
	
	public void validateRecord(){
		Claim__c claim = (Claim__c)con.getRecord();
		refClaim = ClaimService.returnClaimDetails(new set<Id>{claim.Id})[0]; 
		disableAction = null;
		if(claim.status__c == ClaimService.STATUS_CLOSED || claim.status__c == ClaimService.STATUS_CANCELLED){
			isClosed = true;
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Claim_is_closed));
		}
		//KNDY-15529
		else if (claim.Source__c == ClaimService.SOURCE_MANUAL){
			disableAction = true;
			isClosed = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cannot_Chargeback_Writeoff_Manual_Claim));
		}
		/*else if(claim.Manage__c == 'Credit')
		{
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,Label.Please_choose_CreditDebit_button));
		}*/ //AR-83
		else if (claim.Amount__c ==null || claim.Amount__c ==0) //OTC-661
		{
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Claim_amount_cannot_be_empty_or_zero + claim.Name));
		}
		
		else if(refClaim != null && refClaim.Claim_Lines__r.size() > 0){
			set<String> resCodes = new set<String>();
			for(Claim_Line__c cl : refClaim.Claim_Lines__r){
				resCodes.add(cl.Resolution_Code__c);
				if(cl.Resolution_Code__c == null){
					disableAction = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Update_all_claim_lines_with_a_resolution_code));
					break;
				}
				else if( refClaim.Resolution_code__c != null && cl.Resolution_code__c !=refClaim.Resolution_code__c)
				{
					disableAction = true;
					renderNonmatchingcodes =true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.ResolutionCodesAtLineAndHeaderDontMatch));
					break;
				}
				else if(resCodes.size()>1)
				{
					disableAction = true;
					renderNonmatchingcodes =true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.ResCodesAtLinesDontMatch));
					break;
				}
			}
			if(disableAction == null){
				disableAction = false;
			}
			
			
		}else if(claim.Resolution_Code__c == null){
			disableAction = true;
		}else{
			disableAction = false;
		}
	}
	
	public pageReference manageLines(){
		PageReference manageLines = Page.ClaimLinesManage;
		manageLines.getParameters().put('Id',con.getId());
		return manageLines;
	}
	public PageReference ResolveProcess()
	{
		Savepoint sp = Database.setSavepoint();
		try
		{

			//Flip the flag in the service class to reflect a manual action
			DML.updateAsUser(con.getRecord());
			ClaimService.isManual = true;
			ClaimService.resolve(new set<Id>{con.getId()});
			//ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'This claim was successfully resolved.'));
			return null;
				
		}catch(Exception ex){
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' ' + MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
		}
		return null;
	}
	
	public pageReference resolve(){
		
		pageReference ref;
		validateRecord();
		if(!disableAction ){
			//Flip the flag in the service class to reflect a manual action
			ref = ResolveProcess();
			redirect = true;
			return ref;
		}
		else {
			redirect = false;
			return null;
		}

	}
	
}