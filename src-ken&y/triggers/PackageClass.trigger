trigger PackageClass on Package_Class__c (before insert, before update,before delete,after insert,after update) {
if(DML.checkTriggerDispatch(Package_Class__c.getSobjectType())){return;}
	
	if(trigger.isBefore  && trigger.isInsert){
		for (Package_Class__c cl: trigger.new) {
        	if(cl.Level__c == null){
				cl.Level__c =1;//Class created without Parent Pkg will be at level 1.
		    }
		}
	}
	
	if((trigger.isAfter  && (trigger.isInsert || trigger.isUpdate))){
		
    	PackageClassService.validateandupdatePkgClass();
    }
	
	if(trigger.isBefore && trigger.isDelete){
        		
		PackageClassService.allowPkgClassDelete(trigger.oldmap);
	}
	
	
}