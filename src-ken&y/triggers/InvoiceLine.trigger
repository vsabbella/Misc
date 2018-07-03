trigger InvoiceLine on Invoice_Line__c (before delete, after insert, after update, after undelete ) {
   
   if(DML.checkTriggerDispatch(Invoice_Line__c.getSobjectType())){return;}
   
    if((trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete))
    	 	|| (trigger.isBefore && trigger.isDelete)){
   
        FinalizeService.validateLineFinalize();
    }
}