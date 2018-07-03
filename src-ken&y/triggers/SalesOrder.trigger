trigger SalesOrder on Sales_Order__c (before insert, before update, after update) {


    if(DML.checkTriggerDispatch(Sales_Order__c.getSobjectType())){return;}
    
    // Ignore the exceptions count update.
    if(ExceptionService.ignoreTrigger('Sales_Order__c')){
        return;
    }
   
    // OTC-927 Don't allow changing customers if SO not draft
    SalesOrderService.validateCustomer();
    
    SalesOrderService.validateTypeChange();
    
    //OTC-715 deactivate Closed check validation rule and replace with trigger
    SalesOrderService.changeStatus();
    // Populate defaults and link records through references.
    SalesOrderService.populateData(); 
    //OTC-681
    SalesOrderService.preventChangeOnPaymentTerms();

    SalesOrderService.updatePricingDate();

    // OTC-362 : changing delivery method from pickup should remove freight allowances
    SalesOrderService.validateChangingDeliveryMethod();

    // KNDY-2125 : Update Price field if total weight changes on a sales order
    SalesOrderService.findAndUpdateBracketPriceField();
    
    // Update the line prices with any changes in bracket calculations.
    SalesOrderService.validateSalesOrderPrices();
    
    // When a new sales order is created, copy the ship to address from the Customer into the Sales order
    SalesOrderService.copyCustomerAddress();
    
    // KNDY-1149 : Set the Payment Term on the sales order from the Customer record if possible
    //             this is like setLookupUsingField, but not quite
    SalesOrderService.setPaymentTerms();
    
    // Try to find a pricebook from the customer
    SalesOrderService.setPricebook();
    
    // KNDY-1114 : Always create sales order in 'Draft' status
    SalesOrderService.setStatus();  
    
    // Set means of transport // Commenting on KNDY-10333 (Needs rework)
    //SalesOrderService.setMeansOfTransport();(Needs rework)

    // Set Estimated Ship Date
    SalesOrderService.setEstimatedShipDate();
    
    // KNDY-3220 : Refire SO Quantity validations when customer changes
    SalesOrderService.updateSalesOrderLineForQuantityFactorValidations();
    
    // OTC-346 : Allocations
    SalesOrderService.updateAllocationRule();
    
    //KNDY # 4343 Calculating Total Product Weight using Pallet weight.	
	SalesOrderService.calculateTotalWeight();    
	

    
    // KNDY-7935 : Update Weight UOM
    SalesOrderService.updateWeightUOM();
    
    SalesOrderService.validateAllowancesApplied();

    // KNDY-1489: Close / Cancel all the sales order lines if the sales order is closed / cancelled
    SalesOrderService.closeSalesOrderLines();
    
    // Dispatch automation steps.
    ProcessHandler.Dispatch();
    
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){  
        SalesOrderLineService.exService.finishTasks();
    }

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Sales_Order__c> recWithoutCurrency = new List<Sales_Order__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Sales_Order__c rec : trigger.new){
                 if(rec.Currency__c ==  NULL){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }   
            }
        
            if(companyIDs.size() > 0 && recWithoutCurrency.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
        
            for(Sales_Order__c rec : recWithoutCurrency){
                if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
                rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
            }   
        } 
    }

//	SalesOrderService.debugTriggerContext(new set<String>{
//			'total_weight__c',
//			'total_quantity_ordered__c',
//			'Status__c',
//			'Pricing_Date__c'
//	});
        
}