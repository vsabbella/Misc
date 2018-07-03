trigger ReceiptLine on Receipt_Line__c (after insert, after update, before update, before insert, before delete, after undelete) {
    
    if(DML.checkTriggerDispatch(Receipt_Line__c.getSobjectType())){return;}
    
    // Create a "PO Supply" skid when a new Receipt Invoice Line is generated.
static SchemaUtil util = SchemaUtil.getInstance();
    
    VoidCancelService.validateLines();

    if( trigger.isUpdate && trigger.isBefore )           
            SupplierInvoiceService.ReceiptInvoicedInFull( Trigger.new ); // KNDY-1277

    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore)  {
        ReceivingDocumentService.updateReceiptLineLineType(Trigger.new, Trigger.oldMap);    //KNDY-3155 
    }
    
    if((trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete))
            || (trigger.isBefore && trigger.isDelete)){
        
        FinalizeService.validateLineFinalize();
        
    }

}