public with sharing class RecurringTemplateLineService {
	public void setOrClearInformation(List<Recurring_Template_Line__c> newRTLineList){
		if ( Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate) ) {
			Set <Id> RTIds = new Set<Id>();	
	    	if(RTIds!=null)
	    		RTIds.clear();
	
	        for(Recurring_Template_Line__c thisRT: newRTLineList){
	        	
	        	RTIds.add(thisRT.Recurring_Template__c);
	        }

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Recurring_Template__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Company__c','Company__r.Name'
			});
			soql.setWhereClause('id in :RTIds');

			Map <id, Recurring_Template__c> RTHdrMap = new map <id, Recurring_Template__c>((List<Recurring_Template__c>)Database.query(soql.getQuery()));
	        										
	       	for(Recurring_Template_Line__c rtl: newRTLineList){
	        	if(RTHdrMap.containsKey(rtl.Recurring_Template__c)){
	        		rtl.Company__c = RTHdrMap.get(rtl.Recurring_Template__c).Company__c ; // get header from map
	        	}if(rtl.Amount_DR__c == null){
	        		rtl.Amount_DR__c = 0;
	        	}if(rtl.Amount_CR__c == null){
	        		rtl.Amount_CR__c = 0;
	        	}
	       	}
		}
	}
}