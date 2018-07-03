trigger CustomerTrigger on Customer__c (before insert, before update, after update, before delete) {

	if(DML.checkTriggerDispatch(Customer__c.getSobjectType())){return;}
	// Ignore the exceptions count update.
   	if(ExceptionService.ignoreTrigger('Customer__c')){return;}
    
    CustomerService.setOutstandingBalance();
	
	if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
 		
 		CompanyService.setDefaultCompany(Trigger.new, Trigger.isBefore );
 		
		// set the record type if the record type name field is filled in 		
		Relate.setRecordTypeUsingDeveloperName( Trigger.New, Trigger.isBefore,
			'Record_Type_Name__c'  
		);
		
		// set the parent customer lookup if the parent customer identifier is set in the new / updated record
		Relate.setLookupUsingField( Trigger.new, Trigger.isBefore, 
			'Customer__c',  
			'Parent_Customer__c', 
			'Parent_Customer_Identifier__c', 
			'Customer_Identifier__c' 
		);
		
		// set the payment term  lookup if the term identifier is set in the new / updated record
		Relate.setLookupUsingField( Trigger.new, Trigger.isBefore, 
			'Payment_Term__c',  
			'Payment_Term__c', 
			'Payment_Term_Identifier__c', 
			'Payment_Term_Unique__c' // actually the name of the payment term record 
		);
		
	}

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Customer__c> recWithoutCurrency = new List<Customer__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Customer__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Customer__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    } 	

	
	// set Top Parent if possible, makes the hierarchy work
	/*  KNDY-307 */
	if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
		CustomerTopParent.setupTopParent(Trigger.New);
	}
	
	if (Trigger.isUpdate && Trigger.isAfter) {
	     //KNDY-3220 : Refire SO Quantity validations when customer changes
	    Set<Id> validateQtyInLinesForCustomerIds = new Set<Id>();
	    for (Customer__c newCust : Trigger.new) {
	        if (KSE.isFieldChanging('Order_Quantity_Factor_At__c', newCust, Trigger.oldMap)
	            // KNDY-3229 See if rounding changed
	            || KSE.isFieldChanging('Make_Order_Quantity_Even_With_Factor__c', newCust, Trigger.oldMap)) {
	            validateQtyInLinesForCustomerIds.add(newCust.Id);
	        } 
	    }
	    if (!validateQtyInLinesForCustomerIds.isEmpty()) {
	        SalesOrderLineService.updateSalesOrderLineForQuantityFactorValidationsForCustomerIds(validateQtyInLinesForCustomerIds);
	    }
	    
	    // KNDY-2525 Freight Allowance :Update Transit route in case Fuel Preference is changed
	    TransitRouteService.updateTransitRouteForCustomerUpdate(Trigger.new, Trigger.oldMap); 
	   
	}
	
	if(trigger.isBefore && trigger.isDelete){
		KSE.blockRecordDeletion();
	}
	
	// Validate 'Use Fixed Pricing' changes on Customer Record
	CustomerService.validateUseFixedPricing(); 

	SalesOrderLineService.exService.finishTasks();

}