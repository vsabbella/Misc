trigger GLType on GL_Type__c (after insert, after update, before delete, 
before insert, before update) {
	
	if(DML.checkTriggerDispatch(GL_Type__c.getSobjectType())){return;}

    GLTypeService GLtypeService = new GLTypeService();
	if ( trigger.isBefore && ( trigger.isInsert || trigger.isUpdate ) ) {
		GLtypeService.validateGLTypeWithGLTypeRange(trigger.new);
		
	} 
	if ( trigger.isBefore && trigger.isUpdate) {
		map<Id,GL_Type__c> triggernewMap = new map<Id,GL_Type__c>();
		for(GL_Type__c gltype : trigger.old){
			if(KSE.isFieldChanging('Account_Range_From__c', gltype, Trigger.newMap) || KSE.isFieldChanging('Account_Range_To__c', gltype, Trigger.newMap) ){
				triggernewmap.put(gltype.id,Trigger.newMap.get(gltype.id));
			}
		}
		GLtypeService.validateGLTypeWithGLAccount(triggernewmap);
	} 
	if ( trigger.isBefore && trigger.isDelete){
		GLtypeService.validateGLTypeDeleteWithGLAccount(trigger.old);
	
	}
}