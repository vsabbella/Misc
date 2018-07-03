trigger Bin on Bin__c (after insert, after update, after delete, before insert, before update, before delete) {
	if(DML.checkTriggerDispatch(Bin__c.getSobjectType())){return;}
	
    if(trigger.isBefore && trigger.isDelete){
		skidservice3.allowBinDelete();
	}
	if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        skidservice3.validateinsertUpdateBin( trigger.new);   
        if(trigger.isUpdate){
          skidservice3.validateUpdateBinCapacity( trigger.new); 
        }
	}
}