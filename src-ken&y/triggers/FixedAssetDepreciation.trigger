trigger FixedAssetDepreciation on Fixed_Asset_Depreciation__c (before insert, before update, before delete) {
	if(DML.checkTriggerDispatch(Fixed_Asset_Depreciation__c.getSobjectType())){return;}
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
        KSE.setValidateFinalizedFlagonSD();
        // set finalized date on the customer invoice
       	FinalizeService.setFinalizedDate(Trigger.new);
    }
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
     	FinalizeService.validateHeaderFinalize();
	}
}