trigger TransitRoute on Transit_Route__c (before insert, before update) {
	
	if(DML.checkTriggerDispatch(Transit_Route__c.getSobjectType())){return;}
	
	TransitRouteService.setPrimaryKey();
	
	if (Trigger.isBefore && Trigger.isInsert) {
    	// KNDY-2525
	    TransitRouteService.setFuelAllowance(Trigger.new);
	}
	 
	if (Trigger.isBefore && Trigger.isUpdate) {
    	// KNDY-2525
	    TransitRouteService.setFuelAllowance(Trigger.new, Trigger.oldMap);
	}
}