public with sharing class ClaimChargebackExt {
	
	public Apexpages.Standardcontroller con {get;set;}
	public boolean redirect {get;private set;}
	public boolean disableAction {get;private set;}
	public boolean isClosed {get; private set;}
	public Claim__c refClaim {get;set;}
	
	public ClaimChargebackExt(Apexpages.Standardcontroller controller){
		this.con = controller;
		if(!test.isRunningTest()){
			//This is a hack, but prevents us from having to load this in the standardcontroller via the markup
			this.con.addFields(new List<string>{'status__c', 'resolution_code__c', 'Bill_to_Customer__c','manage__c','source__c'});
		}
		validateRecord();
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
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Cannot_Chargeback_Writeoff_Manual_Claim));
		}
		/*else if(claim.Manage__c == 'Credit')
		{
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,Label.Please_choose_CreditDebit_button ));
		}*/ //AR-83
		
		//OTC-244 - Remove validation on Claim to require a Bill To Customer
	/*	else if(claim.Bill_to_Customer__c == null){
    		disableAction = true;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Bill_to_Customer_required_before_creating_chargeback + ' ' + claim.Name ));
        }*/
		
		/*//Resolution Codes Not needed at this time
		else if(refClaim != null && refClaim.Claim_Lines__r.size() > 0){
			for(Claim_Line__c cl : refClaim.Claim_Lines__r){
				if(cl.Resolution_Code__c == null){
					disableAction = true;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please update all claim lines with a resolution code before performing a Chargeback.'));
					break;
				}
			}
			if(disableAction == null){
				disableAction = false;
			}
		}else if(claim.Resolution_Code__c == null){
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please update this claim with a resolution code before performing a Chargeback.'));
		}
		*/
		else{
			disableAction = false;
		}
	}
	
	public pageReference chargeback(){
		Savepoint sp = Database.setSavepoint();
		try{
			validateRecord();
			if(!disableAction){
				DML.updateAsUser(con.getRecord());
				ClaimService.chargeback(new set<Id>{con.getId()});
				redirect = TRUE;
				return null;
			}
		}catch(Exception ex){
			System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + ' ' + ex.getMessage());
			Database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
		}
		redirect = false;
		return null;
	}
	
}