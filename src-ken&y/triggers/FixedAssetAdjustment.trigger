trigger FixedAssetAdjustment on Fixed_Asset_Adjustment__c (before delete, before insert, before update) {
	if(DML.checkTriggerDispatch(Fixed_Asset_Adjustment__c.getSobjectType())){return;}
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        KSE.setValidateFinalizedFlagonSD();
        // set finalized date on the customer invoice
       	FinalizeService.setFinalizedDate(Trigger.new);
    }
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
     	FinalizeService.validateHeaderFinalize();
	}

}