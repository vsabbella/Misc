public with sharing class ClaimMassResolveExt {
	public Apexpages.Standardsetcontroller ssCon {get;set;}
	public List<Claim__c> availableClaims {get;set;}
	public boolean disabled {get; private set;}
	
	public ClaimMassResolveExt(Apexpages.Standardsetcontroller ssController){
		ssCon = ssController;
		disabled = false;
		filterRecords();
		compareSelected();
	}
	
	public void filterRecords(){
		list<sObject> recs = ssCon.getSelected();
		string statusClosed = ClaimService.STATUS_CLOSED;
		string sourceManual = ClaimService.SOURCE_MANUAL;//KNDY-15529
		set<String> queryFields = new set<string>(); //new set<String>{'id', 'name', 'status__c', 'resolution_code__c'};
		for(string s : SchemaUtil.getInstance().getFieldsFromFieldSetString(recs.getSObjectType(), 'Resolve')){
			queryFields.add(s.toLowerCase());
		}
		string whereClause = 'Id IN :recs';
		whereClause += ' AND Status__c != :statusClosed';
		whereClause += ' AND Resolution_Code__c != null';
		whereClause += ' AND Source__c != :sourceManual';//KNDY-15529
		
		SOQLUtil soql = new SOQLUtil('Claim__c', TRUE);
		soql.addFields(queryFields);
		soql.setWhereClause(whereClause);
		availableClaims = Database.query(soql.getQuery());
		
	}
	
	public void compareSelected(){
		if(availableClaims.size() < ssCon.getSelected().size() && availableClaims.size() > 0){
			ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.WARNING, Label.Some_records_missing_resolution_code_or_are_closed));
		}else if(availableClaims.size() == 0 && ssCon.getSelected().size() > 0){
			ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, Label.Selected_claims_are_closed_or_missing_resolution_code));
			disabled = true;
		}else if(ssCon.getSelected().size() == 0){
			ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.WARNING, Label.No_records_selected));
			disabled = true;
		}
	}
	
	public pageReference resolve(){
		filterRecords();
		boolean isSuccess = true;
		if(availableClaims.size() > 0){
			Map<Id, Claim__c> mClaims = new Map<Id, Claim__c>(availableClaims);
			try{
				ClaimService.isManual = true;
				ClaimService.resolve(mClaims.keySet());
				disabled = true;
				ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.CONFIRM, Label.Selected_claims_have_been_resolved));
			}catch(Exception ex){
				isSuccess = false;
				ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
				System.debug(LoggingLevel.ERROR, ex.getStackTraceString() + ' ' + ex.getMessage());
			}
		}else if(availableClaims.size() == 0){
			isSuccess = false;
			ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, Label.Selected_claims_have_been_closed));
			disabled = true;
		}
		if(isSuccess){
			pageReference newPage;
			string retURL = Apexpages.currentPage().getParameters().get('retURL');
			if(retURL != null){
				newPage = new pageReference(retURL);
			}else{
				string objPrefix = SchemaUtil.getInstance().getObjectPrefix(new Claim__c());
				newPage = new pageReference('/'+objPrefix + '/o');
			}
			return newPage;
		}else{
			return null;
		}
	}
}