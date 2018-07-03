trigger Facility on Facility__c (before insert, before update, after insert, before delete) {
	
	if(DML.checkTriggerDispatch(Facility__c.getSobjectType())){return;}
	
	if ( trigger.isBefore &&  (  trigger.isinsert || trigger.isupdate ) )  {
		// ensure that the facility can find a company if loaded using a data load	
		Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
											'Company__c' ,
											'Company__c', 
											'Company_Identifier__c',
											'Company_Identifier__c' );

        FacilityService.setFacilityIdentifier();
	}
	
	if(trigger.isBefore && trigger.isDelete){
		KSE.blockRecordDeletion();
	}
}