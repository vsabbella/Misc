/**
 * 	@description : Trigger on sales order line object having the following fucntions
 */
 
trigger SalesOrderLineTrigger on Sales_Order_Line__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (DML.checkTriggerDispatch(Sales_Order_Line__c.getSObjectType()) == true || ExceptionService.ignoreTrigger('Sales_Order_Line__c') == true || (Trigger.isUpdate == true && SalesOrderLineService.IgnoreSalesOrderLineUpdate == true)) return;

    if (Trigger.isBefore == true) {
        if (Trigger.isInsert == true) SalesOrderLineTriggerHandler.beforeInsert();
        else if (Trigger.isUpdate == true) SalesOrderLineTriggerHandler.beforeUpdate();
        else SalesOrderLineTriggerHandler.beforeDelete();
    } else {
        if (Trigger.isInsert == true) SalesOrderLineTriggerHandler.afterInsert();
        else if (Trigger.isUpdate == true) SalesOrderLineTriggerHandler.afterUpdate();
        else if (Trigger.isDelete == true) SalesOrderLineTriggerHandler.afterDelete();
        else SalesOrderLineTriggerHandler.afterUndelete();
    }
    
    SalesOrderLineService.isExecuting = true;
    
    SalesOrderLineService.validateFulfillmentSource(); 

    // KNDY-631 : before update see if the product is changing on a closed (shipped) line, don't allow it
    SalesOrderLineService.validateChanges(); 
    
    // Populate defaults and link records through references.
    SalesOrderLineService.populateData(); 
    
    // Set line numbers (Make sure to set lines numbers before calling the pricing service)
	SalesOrderLineService.setLineNumbers(); 
    
    // OTC-948: Keep the Product Item Purchasing UOM the same as the SOL UOM
    SalesOrderLineService.validateItemUOM();
    
    // KNDY-7966: Populate standard cost 
    SalesOrderLineService.populateStandardCost();
    
    /********************* MANAGABLE ACTIONS *****************************/
    
    // Execute the process flows
    ProcessHandler.Dispatch(); 
    
    //Sales Order Line before delete validation
    SalesOrderLineService.beforeDeleteValidation();
    
    // Determine the best means of transport to ship goods from facility to the customer.
    //SalesOrderLineService.setMeansOfTransport(); KNDY-10333 (Needs rework)

    // Set Estimate Delivery Date
    SalesOrderLineService.setEstimatedShipDate();

    // KNDY-2122 : Substitutes the current product based on the valid entries in the substitution table.
    SubstitutionService.substituteProduct(); 
    
    // KNDY-2125 : Update Pricebook field on SO Line level 
    //SalesOrderLineService.populateMissingPricebooks(); 
    

     
    // KNDY-407 : If there is no active price for a product on a price book, users cannot order
    SalesOrderLineService.validateSalesOrderLinePrices(); 
    
    // Roll up Summary (Calculate SOL Total Weight) KNDY-614 and SO status KNDY-668
    SalesOrderLineService.calculateRollupFields();
    
    // validates AllocationRule if Estimate Delivery Date is changed
    SalesOrderLineService.validateAllocationRule();
    
    // KNDY-614 : Updates the weight of the product only if the product is changed
    SalesOrderLineService.setWeightAndUOM(); 
    
    // KNDY-2891 : Checks for minimum order qty exceptions
    SalesOrderLineService.validateSalesOrderLineQuantities();
    
    // KNDY-668 : Calculate the quantity for backordered (quantity ordered minus quantity shipped), 
    // 			  and update sales order line status if needed.  
    SalesOrderLineService.updateSalesOrderLineDetail();
    
    // Create, update or delete associated purchase order lines for the sales order lines.
    // OTC-361
    // SalesOrderLineService.managePOLines(); 
    
    // Create, update or delete associated 'SO Demand' skids for the sales order lines.
    // OTC-18 
    // SalesOrderLineService.manageSkids();
    
    /******************** FINAL ACTIONS **********************************/

    // update child Sales Order Lines when parent quanty is changed for Kitted Sales Order Lines
    SalesOrderLineService.updateKittedChildQuantities();

    // KNDY-9596: Close parent sales order line when children lines are closed
    SalesOrderLineService.closeBundleParentSalesOrderLine();
    
    // KNDY-1230: Close sales order after all the sales order lines are closed.
    SalesOrderLineService.updateSalesOrderStatus(); 
    
	//KNDY-4509
	
 //   if ((trigger.isBefore) && (trigger.isInsert || trigger.isUpdate)) {
	//	if (trigger.isInsert) {
	//		SalesOrderLineService.setListPrice(trigger.new); 	
	//	}
	//	if (trigger.isUpdate) {
	//		List<Sales_Order_Line__c> solUpdateListPrice = new List<Sales_Order_Line__c>();
	//		for (Sales_Order_Line__c sol: trigger.new) {
	//			if (KSE.isFieldChanging('Product__c', sol, trigger.oldMap)) {
	//				solUpdateListPrice.add(sol);	
	//			}
	//		}
	//		if (!solUpdateListPrice.isEmpty()) {
	//			SalesOrderLineService.setListPrice(solUpdateListPrice);	
	//		}
	//	}		
	//}  
	
	// KNDY-7965
	SalesOrderLineService.calculateDiscountFields();
	
	if ((trigger.isBefore) && (trigger.isInsert || trigger.isUpdate)) {

		set<Id> soIds = new Set<Id>();
		for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new) {
			soIds.add(sol.Sales_Order__c);
		}
		Map<Id,Sales_Order__c> soMap = new Map<Id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soIds));

		for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new) {
			sol.Sales_Order__r = soMap.get(sol.Sales_Order__c);
		}

        PricingService.salesOrderLinePricing(trigger.new);
	}

    if ((trigger.isAfter) && (trigger.isInsert || trigger.isUpdate)) {

        List<Id> soList = new List<Id>();
        Map<Id, Decimal> solToFulQty = new Map<Id, Decimal>();

        // BA-TODO: Separate this. Recalc Amounts vs. Revalidate. Low Priority.
        for (Sales_Order_Line__c sol : trigger.new){
            if (KSE.isFieldChanging('Product__c', sol, trigger.oldMap)
                || KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap)
                || KSE.isFieldChanging('Quantity_Fulfilled__c', sol, trigger.oldMap)
                || KSE.isFieldChanging('Quantity_Shipped__c', sol, trigger.oldMap)
                || KSE.isFieldChanging('Ordered_Date_Time__c', sol, trigger.oldMap)
                || (KSE.isFieldChanging('Unit_Price__c', sol, trigger.oldMap) && !AllowanceApplicator.skipSOLTrigger.contains(sol.Id))
                || KSE.isFieldChanging('Discount_Percent__c', sol, trigger.oldMap)
                || KSE.isFieldChanging('Off_Invoice_Rate__c', sol, trigger.oldMap)
            ) {

                if (trigger.isUpdate && KSE.isFieldChanging('Quantity_Fulfilled__c', sol, trigger.oldMap)){
                    Decimal qtyDiff = KSE.subtractDecimals( sol.Quantity_Fulfilled__c, (Decimal) trigger.oldMap.get(sol.id).get('Quantity_Fulfilled__c'));
                    solToFulQty.put(sol.id, qtyDiff);
                }
                soList.add(sol.Sales_Order__c);
            }
        }
        if (!soList.isEmpty()){
            SalesOrderService.validateAllowancesApplied(soList, solToFulQty);
        }
    }
    //end KNDY-4509

//	SalesOrderService.debugTriggerContext(new set<String>{
//			'allowances__c',
//			'extended_price__c',
//			'product_weight__c',
//			'quantity_ordered__c',
//			'unit_price__c',
//			'billback_commitment__c',
//			'New_Pricing_Rule__c',
//			'Status__c',
//			'Pricing_Date__c'
//		}
//	);

    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
	    SalesOrderLineService.exService.finishTasks();
		SubstitutionService.exService.finishTasks();
	}
}
