trigger SKIDTrigger on SKID__c (before insert, before update) {
	
	if(DML.checkTriggerDispatch(SKID__c.getSobjectType())){return;}
	
    if( trigger.isBefore ) {
    	// PTM-566 make item not required at the DB to avoid locking, check that field is
    	// not null in the trigger so we cannot generate skids which are missing item. 
        for(SKID__c skid : trigger.new) {
            if(skid.Item__c == null) {
            	skid.Item__c.addError( Label.Invalid_Item + ' ' +skid.Item__c);
            }
            if ( (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED || skid.Type__c == SkidService3.SKID_TYPE_PLANNED ) && skid.Quantity__c < 0) {
                skid.Quantity__c.addError('Quantity cannot be less than zero for allocated or planned pick skids.');
            }
            if(skid.Stocking_UOM__c == null || skid.Packaging_UOM__c == null ){
                //this can be enabled only after all the flows are done , otherwise fails all test methods
                //skid.Stocking_UOM__c.addError('Stocking and Packaging UOM should be populated');
            }
            
            /*if(skid.Packaging_UOM__c == skid.Stocking_UOM__c){
                skid.Quantity_Stocking_UOM__c = skid.Quantity__c;
            }
            else{
                skid.Quantity_Stocking_UOM__c = skid.Quantity__c * KSE.getConversionFactor( skid.Item__c , skid.Packaging_UOM__c , skid.Stocking_UOM__c, null );
            }*/
        }
    }
}