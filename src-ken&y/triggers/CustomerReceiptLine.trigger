trigger CustomerReceiptLine on Customer_Receipt_Line__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {

	if(DML.checkTriggerDispatch(Customer_Receipt_Line__c.getSobjectType())){return;}

    if(ExceptionService.ignoreTrigger('Customer_Receipt_Line__c')){return;}
    
	CustomerReceiptLineService.validateSalesOrder(); //validate that only non cancelled salesorder can be associated to CRL
	
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
	    
	    PaymentService.updateLineAmounts(trigger.new);
	    
		PaymentService.matchCreditMemo(trigger.new);
		PaymentService.matchInvoice(trigger.new);
	}
	
	if(trigger.isAfter && trigger.isInsert){
		//ClaimService.createClaims(trigger.new);
	}
	
	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
	    CustomerReceiptLineService.validateLines();
	    CustomerReceiptLineService.exService.finishTasks();
	}
	
	if(trigger.isBefore && trigger.isDelete){
		ClaimService.removeClaims(trigger.old);
	}
	
	//OTC-725
	/*if(trigger.isAfter && trigger.isDelete){
		CustomerReceiptLineService.updateInvoicePaymentAmounts(trigger.old);
	}
	if(trigger.isAfter  && (trigger.isInsert || trigger.isUpdate))
	{
		try
		{
			CustomerReceiptLineService.updateInvoicePaymentAmounts(trigger.new);
		}
		catch(Exception ex)
		{
			throw ex;
		}
	}*/
	
	//AR-52 this method is moved to the BankFile Line trigger
	/*// KNDY-5153
	if ( trigger.isbefore  && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete)) {
		
		list<Customer_Receipt_Line__c> crLines = new list<Customer_Receipt_Line__c>();
		for(Customer_Receipt_Line__c crL : trigger.new)
		{
			if(trigger.isUpdate){
				if(crL.Amount__c != trigger.oldmap.get(crL.ID).Amount__c)
					crLines.add(crL);
			}
			else
				crLines.add(crL);
		}
		
			list<RollUpSummaryUtility.fieldDefinition> fieldDefinitions = 
	            new list<RollUpSummaryUtility.fieldDefinition> {
	            new RollUpSummaryUtility.fieldDefinition('SUM', 'Amount__c', 'Amount_Received__c')
			};
			
			RollUpSummaryUtility.rollUpTrigger( 
				fieldDefinitions, 
				crLines, 
				'Bank_File_Line__c',
				'Customer_Receipt__c',
				'Customer_Receipt__c',
				''
			);
			
		
	}*/
	
	//FIN-209 validate the line for finalized document
	if( ( trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete) )
			|| ((trigger.isBefore && trigger.isDelete)) )
	{
			FinalizeService.validateLineFinalize();
	}
}