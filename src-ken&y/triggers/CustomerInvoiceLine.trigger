trigger CustomerInvoiceLine on Customer_Invoice_Line__c (before insert, before update, before delete, after insert, after update, after undelete) {


	if(DML.checkTriggerDispatch(Customer_Invoice_Line__c.getSobjectType())){return;}

	CustomerInvoiceLineService.roundSalesTax();
	//FIN-209 validate the line for finalized document
	if( ( trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete) )
			|| ((trigger.isBefore && trigger.isDelete)) )
	{
			FinalizeService.validateLineFinalize();
	}
	
	CustomerInvoiceLineService.customerInvoiceLinePricing();
	CustomerInvoiceLineService.setProRateFactor();
	if(trigger.isBefore && trigger.isInsert)
		CustomerInvoiceLineService.setLineNumbers(trigger.new);


//	SalesOrderService.debugTriggerContext(new Set<String>{'Unit_Price__c'});
}