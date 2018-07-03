public with sharing class RecurringTemplateLinesAddManageExt {
	
	public Apexpages.Standardcontroller con {get;set;}
	public boolean disableAction {get;private set;}
	public boolean isClosed {get; private set;}
	//public Claim__c refClaim {get;set;}
	public Recurring_Template__c thisRT {get; set;}
	
	public RecurringTemplateLinesAddManageExt(Apexpages.Standardcontroller controller){
		this.con = controller;
		//thisRT = (Recurring_Template__c)con.getRecord();
		if(!test.isRunningTest()){
			//This is a hack, but prevents us from having to load this in the standardcontroller via the markup
			//this.con.addFields(new List<string>{'status__c', 'resolution_code__c', 'Bill_to_Customer__c'});
		}
		validateRecord();
	}
	
	public void validateRecord(){
		Recurring_Template__c rt = (Recurring_Template__c)con.getRecord();
		thisRT = RecurringTemplateService.returnRTDetails(new set<Id>{rt.Id})[0]; 
		disableAction = null;
		if(thisRT.status__c == RecurringTemplateService.STATUS_CLOSED){
			isClosed = true;
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can not add lines to the closed template'));
		}else if(thisRT.status__c == RecurringTemplateService.STATUS_ACTIVE){
			isClosed = true;
			disableAction = true;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can not add lines to the active template'));
		}else{
			disableAction = false;
		}
	}

}