public with sharing class ClaimUndoSplitExt {
	
	public Apexpages.Standardcontroller con {get;set;}
	public boolean disableAction {get;private set;}
	public List<Claim__c> relatedClaims {get; private set;}
	
	public ClaimUndoSplitExt(Apexpages.Standardcontroller controller){
		con = controller;
		if(!test.isRunningTest()){
			//prevents us from having to load this in the standardcontroller via the markup
			con.addFields(new List<string>{'status__c'});
		}
		updateRelatedClaims();
		validateSplit();
	}
	
	public void updateRelatedClaims(){ 
		Id claimId = con.getId();
		SOQLUtil soql = new SOQLUtil('Claim__c', TRUE);
		soql.addFields('Split');
		soql.setWhereClause('related_claim__c = :claimId');
		//system.debug('query: ' + soql.getQuery());
		relatedClaims = database.query(soql.getQuery());
	}
	
	public void validateSplit(){
		//OTC-103
		Claim__c c = (Claim__c)con.getRecord();

		if(relatedClaims.size() == 0 && c.Settlement_Method__c != ClaimService.SETTLE_SPLIT){
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Claim_doesnot_have_related_claims_to_remove));
		}else{
			disableAction = false;
		}
	}
	
	public void undoSplit(){
		Savepoint sp = Database.setSavepoint();
		try{
			ClaimService.undoSplit(new set<Id>{con.getId()});
			updateRelatedClaims();
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.Related_claims_were_removed));
		}catch(Exception ex){
			database.rollback(sp);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
		}
		disableAction = true;
	}
}