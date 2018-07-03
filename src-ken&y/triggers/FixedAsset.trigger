trigger FixedAsset on Fixed_Asset__c (before insert, before update, after insert, before delete) {
	
	if(DML.checkTriggerDispatch(Fixed_Asset__c.getSobjectType())){return;}
	
	if(trigger.isInsert){
		if(trigger.isBefore){
			FixedAssetService.beforeActions(trigger.new);
			FixedAssetService.checkInactiveGLs(trigger.new);				
		}
		if(trigger.isAfter){
			FixedAssetService.createTaxBooks(trigger.newMap.keySet());
		}
	}
	
	if(trigger.isUpdate){
	    FixedAssetService.validateSystemFields();
		if(trigger.isBefore){
			FixedAssetService.beforeActions(trigger.new);
			FixedAssetService.checkInactiveGLs(trigger.new);				
		}
	}
	
	
	
	//Delete child tax book assets
	if(trigger.isDelete){
		if(trigger.isBefore){
			system.debug('keyset: ' + trigger.oldMap.keySet());
			FixedAssetService.deleteFixedAssetTaxBooks(trigger.oldMap.keySet());
		}
	}
}