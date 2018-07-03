trigger InvoiceGroupingRule on Invoice_Grouping_Rule__c (after delete, after insert, after undelete, 
														 after update, before delete, before insert, before update) {
	
	if(DML.checkTriggerDispatch(Invoice_Grouping_Rule__c.getSobjectType())){return;}													 	
														 	
														 	
	InvoiceGroupingRuleService.defaultGroupBySOType();													 	
	InvoiceGroupingRuleService.validateRuleForProductAndCategory();	
	if(!OnDemandInvoiceGenerateExt.bypassDuplicateCheck) //check to block only adhoc CI generation using Process Fulfillments
       InvoiceGroupingRuleService.checkDuplicates();                
	InvoiceGroupingRuleService.setRankKey();											 	
	InvoiceGroupingRuleService.restrictUpdationAndDeletionOfIGR();    //KNDY-15790
}