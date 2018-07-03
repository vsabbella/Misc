public with sharing class ShipmentService {
    static Map<Id, Shipment__c> shipmentsMap = new Map<Id, Shipment__c>();
    static Map<String, Transit_Route__c> routesMap = new Map<String, Transit_Route__c>();
    
    public static ExceptionService exService = new ExceptionService();
    public static Boolean isShipmentDelete = false;
    
    public static final String SHIPMENT_LOAD_NUMBER_PREFIX = 'K-';
    public static final String SHIPMENT_STATUS_PLANNED = 'Planned';
    public static final String SHIPMENT_STATUS_RELEASED = 'Released';
    public static final String SHIPMENT_STATUS_STAGED = 'Staged';
    public static final String SHIPMENT_STATUS_CONFIRMED = 'Confirmed';
    public static final String SHIPMENT_STATUS_DELIVERED = 'Delivered';
    
    public static final String SHIPMENT_TYPE_TRANSFER_ORDER = 'Transfer Order Shipment';
    public static final String SHIPMENT_TYPE_SALES_ORDER = 'Sales Order Shipment';
    public static final String SHIPMENT_TRANSACTION_TYPE_LOGICAL = 'Logical Sales Order Shipment';
    public static final String SHIPMENT_TRANSACTION_TYPE_SALES_ORDER_SHIPMENT = 'Sales Order Shipment';
    
    public class ShipmentServiceException extends Exception {}
    
    // OTC-360
	public class FulfillmentLineWrapper {
		public String salesOrderLineId;
		public String shipmentId;
		public Date estimatedShipmentDate;
		public Decimal quantityPlanned;
		
		public FulfillmentLineWrapper(){
  
		}
	}
    
	// Called from ShipmentPlanExt.cls
    public static void plan(List<FulfillmentLineWrapper> fulfillmentLines) {
    	// Sales Order Line Id => Sales Order Line
        Map<Id, Sales_Order_Line__c> mSalesOrderLines = new Map<Id, Sales_Order_Line__c>();
        
        Set<Id> solIdSet = new Set<Id>();
        
        for(FulfillmentLineWrapper fulfillmentLine : fulfillmentLines){
        	solIdSet.add(fulfillmentLine.salesOrderLineId);
        }
        
        for(Sales_Order_Line__c sol : [SELECT Id, Name, Company__c, Description__c, Discount_Percent__c, pricebook__c,
                                              Has_Exceptions__c, Unit_Price__c, Estimated_Ship_Date__c,
                                              Weight__c, Weight_UOM__c, Status__c, Dimension_UOM__c, Weight_UOM_Name__c,
                                              Dimension_UOM_Name__c, Dimension_UOM__r.Name, Weight_UOM__r.Name,
                                              Quantity_Backordered__c, Quantity_Ordered__c, Quantity_Planned__c, Quantity_Shipped__c, Required_Date__c, Extended_Price__c,
                                              Product__c, Product__r.Item__r.Stocking_UOM__c, Product_Weight__c,Product__r.Item__r.Packaging_UOM__c,
                                              Product__r.Item__r.Stocking_UOM__r.Name, Product__r.Weight__c, Product__r.Product_Group__c,
                                              Product__r.Weight_UOM__r.Name, Product__r.Dimension_UOM__r.Name,
                                              Product__r.Item__r.Non_Inventory__c, Product__r.Width__c, Product__r.Height__c, Product__r.Length__c,
                                              Product__r.Sales_hierarchy__c, Product__r.Sales_hierarchy__r.Path__c, Product__r.Sales_hierarchy__r.Code__c,
                                              Product__r.Product_group__r.Hierarchy__c, Product__r.Product_group__r.Hierarchy__r.Path__c, 
                                              Product__r.Product_group__r.Hierarchy__r.Code__c,
                                              Product__r.Pricebook_Line_Required__c, Off_Invoice_Rate__c ,
                                              Sales_Order__c, Sales_Order__r.Delivery_Method__c, Sales_Order__r.Company__c, 
                                              Sales_Order__r.Bill_to__c, Sales_order__r.Bill_to__r.Customer_Group__c,
                                              Sales_Order__r.Ship_To__c, Sales_Order__r.Ship_To__r.Name, Sales_Order__r.Ship_To__r.Address__c, Sales_Order__r.Ship_To__r.Business_Hours__c,
                                              Sales_Order__r.Ship_To__r.Lead_Time__c, Sales_Order__r.Ship_To__r.Earliest_Delivery_Window__c, Sales_Order__r.Ship_To__r.Latest_Delivery_Window__c, 
                                              Sales_Order__r.Currency__c, Sales_Order__r.Status__c, Sales_Order__r.Hold__c, 
                                              Sales_Order__r.Type__c, Sales_Order__r.Customer__c, Sales_Order__r.Customer__r.Top_Parent_Customer__c,
                                              Sales_Order__r.Customer__r.Customer_Group__c, Sales_Order__r.Ship_To__r.Customer_Group__c, Sales_Order__r.Customer__r.Top_Parent_Customer__r.Customer_Group__c,
                                              Sales_Order__r.Customer__r.Top_Parent_Customer__r.Credit_Hold__c, Sales_Order__r.Dimensional_Weight__c, 
                                              Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c, Sales_Order__r.Customer__r.Status__c, Sales_Order__r.Customer__r.Parent_Customer__r.Status__c, Sales_Order__r.Ship_To__r.Status__c,
                                              Sales_Order__r.Means_of_Transport__c, Sales_Order__r.Means_of_Transport__r.Name, Sales_Order__r.Exceeds_Max_Weight__c, 
                                              Sales_Order__r.Total_Weight__c, Sales_Order__r.Total_Order_Volume__c, Sales_Order__r.subtotal__c,
                                              Sales_Order__r.Total_Quantity_Ordered__c, Sales_Order__r.Total_Product_Weight__c,
                                              Sales_Order__r.Means_of_Transport__r.Minimum_Cube__c, Sales_Order__r.Means_of_Transport__r.Minimum_Weight__c,
                                              Sales_Order__r.Weight_UOM__c, Sales_Order__r.Dimension_UOM__c, Sales_Order__r.Weight_UOM__r.Name, Sales_Order__r.Dimension_UOM__r.Name,
                                              Sales_Order__r.Price_Determination_Date__c, Sales_Order__r.Pricing_Date__c, Sales_Order__r.Date_Time_Ordered__c,
                                              Selling_UOM__c, Selling_UOM__r.Name, Ship_From_Location__c, Ship_From_Location__r.Facility__r.Address__c, 
                                              Ship_From_Location__r.Facility__c, Ship_From_Location__r.Facility__r.Name, Ship_From_Location__r.Facility__r.Lead_Time__c, Sales_Order__r.Override_Credit_Hold__c,
                                              Ship_From_Location__r.Facility__r.Enable_Transit_Route_Optimization__c, Ship_From_Location__r.Facility__r.Shipping_Calendar__c, Line_Type__c,
                                              Ship_From_Location__r.Facility__r.Facility_Identifier__c
                                         FROM Sales_Order_Line__c
                                        WHERE Id IN :solIdSet
                                        FOR UPDATE] 
		){
            Decimal unplannedQuantity = sol.Quantity_Ordered__c - KSE.addQuantityToField(sol.Quantity_Planned__c, sol.Quantity_Shipped__c);
			
	        if (unplannedQuantity > 0 && sol.Status__c == SalesOrderService.SO_STATUS_OPEN){
		    	mSalesOrderLines.put(sol.Id, sol);
		    }
	    }
        
	    if(mSalesOrderLines.size() > 0){
		    
		    Savepoint sp = Database.setSavepoint();
		    
		    try{
		        // Create / Update shipment lines.
		        createUpdateShipmentLines(mSalesOrderLines, fulfillmentLines);
		        
			}catch(Exception e){
	            Database.rollback(sp);
	            ExceptionService.addMessage( MessageUtil.Severity.Error.name(), e.getMessage(), '');
              	System.debug(LoggingLevel.ERROR, '(from SalesOrderService.cls) ' + e.getStackTraceString());
	        }
	    }
	    
	    exService.finishTasks();
	    
        return;
    }
    
    public static void createUpdateShipmentLines(Map<Id, Sales_Order_Line__c> mSalesOrderLines, List<FulfillmentLineWrapper> fulfillmentLines){
    	system.debug(LoggingLevel.INFO, 'Entering createUpdateShipmentLines Method ........');
    	
        List<Shipment_Line__c> shlsToUpsert = new List<Shipment_Line__c>();
        
        // Planning Key => New Shipment
        Map<String, Shipment__c> mShipmentsToUpsert = new Map<String, Shipment__c>();
        
        // Sales Order Line Id => Shipment Line
        Map<String, Shipment_Line__c> solToShlMap = new Map<String, Shipment_Line__c>();
        
        Set<Id> selectedShipmentIds = new Set<Id>();
        
        // Create a new shipment for the shipment lines we are about to create.
        for(FulfillmentLineWrapper fulfillmentLine : fulfillmentLines){
	        
	        if(mSalesOrderLines.containsKey(fulfillmentLine.salesOrderLineId) == false){
	        	continue;
	        }
	        
	       	selectedShipmentIds.add(fulfillmentLine.shipmentId);
        
            Sales_Order_Line__c sol = mSalesOrderLines.get(fulfillmentLine.salesOrderLineId);
		    
	        if(fulfillmentLine.quantityPlanned == null || fulfillmentLine.quantityPlanned == 0){
            	fulfillmentLine.quantityPlanned = sol.Quantity_Ordered__c - (KSE.addQuantityToField(sol.Quantity_Planned__c, sol.Quantity_Shipped__c));
            }
            
	        if(String.isBlank(fulfillmentLine.shipmentId) && fulfillmentLine.quantityPlanned > 0){
	        	
		    	String planningKey = '' + sol.Ship_From_Location__c 
	        							+ sol.Sales_Order__r.Ship_To__c;
	        	
	        	Shipment__c shipment = new Shipment__c();
	        	
	        	if(mShipmentsToUpsert.containsKey(planningKey) == false){
	        		shipment.Company__c = sol.Sales_Order__r.Company__c;
	                shipment.Customer__c = sol.Sales_Order__r.Ship_To__c;
	                shipment.Means_of_Transport__c = sol.Sales_Order__r.Means_of_Transport__c;
	                
					// ba-todo From the ShipmentPlanExt, the page populates the estimatedShipDate value on the VF page in the wrapper. Test This scenario.
	                if(fulfillmentLine.estimatedShipmentDate != null){
	                	shipment.Shipment_Date_Estimated__c = fulfillmentLine.estimatedShipmentDate;
	                }
	                else{
	                	shipment.Planned_Delivery_Date__c = sol.Required_Date__c;
	                }
	                 
	                shipment.Ship_From_Facility__c = sol.Ship_From_Location__r.Facility__c;
	                shipment.Ship_From_Location__c = sol.Ship_From_Location__c;		                    
	                shipment.Status__c = 'Planned';
	                shipment.Type__c = ShipmentService.SHIPMENT_TYPE_SALES_ORDER;
	                shipment.Transaction_Type__c = ShipmentService.SHIPMENT_TRANSACTION_TYPE_SALES_ORDER_SHIPMENT;
	                shipment.Currency__c = sol.Sales_Order__r.Currency__c;
	                
	                mShipmentsToUpsert.put(planningKey, shipment);
	            }
				else {
					// the shipment's Need Date should be the largest of all the lines.
					if (mShipmentsToUpsert.get(planningKey).Planned_Delivery_Date__c != null
							&& sol.Required_Date__c > mShipmentsToUpsert.get(planningKey).Planned_Delivery_Date__c)
					{
						mShipmentsToUpsert.get(planningKey).Planned_Delivery_Date__c = sol.Required_Date__c;
					}
				}
		    }
        }
	    
	    if(mShipmentsToUpsert.size() > 0){    
        	DML.checkUpsertAsUser(mShipmentsToUpsert.values()); upsert mShipmentsToUpsert.values();
	    }
        
        // Get existing shipment lines. 
        if(selectedShipmentIds != null && selectedShipmentIds.size() > 0){
     		for(Shipment_Line__c shl : [SELECT Id, Sales_Order_Line__c, Sales_Order_Line__r.Name, Shipment__c 
     									  FROM Shipment_Line__c 
     									 WHERE Shipment__c IN :selectedShipmentIds
 									 	   AND Sales_Order_Line__c IN :mSalesOrderLines.keySet()]){
     			
	    		String shlKey = '' + shl.Sales_Order_Line__c + shl.Shipment__c;
	    		
	    		if(solToShlMap.containsKey(shlKey)){
	    			throw new ShipmentServiceException(shl.Sales_Order_Line__r.Name + ':' + 'There is more than one shipment line for this sales order line on the selected shipment - ' + shl.Shipment__r.Name);
	    		}else{
	    			solToShlMap.put(shlKey, shl);
	    		}
	 		}
     	}
	    
	    Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        
	    for(Sales_Order_Line__c sol : mSalesOrderLines.values()) {
        	itemIds.add(sol.Product__r.Item__c);
    		facilityIds.add(sol.Ship_From_Location__r.Facility__c);
    	}
            
        for(FulfillmentLineWrapper fulfillmentLine : fulfillmentLines){  
            	
        	Sales_Order_Line__c sol = mSalesOrderLines.get(fulfillmentLine.salesOrderLineId);
        	
        	String planningKey = '' + sol.Ship_From_Location__c 
            						+ sol.Sales_Order__r.Ship_To__c;
            						
        	Id shipmentId = null; 
            
            if(String.isBlank(fulfillmentLine.shipmentId)){
            	if(mShipmentsToUpsert.containsKey(planningKey)){
            		shipmentId = mShipmentsToUpsert.get(planningKey).Id;
            	}else{
            		// This should never be invoked since we always create a new shipment.
            		throw new ShipmentServiceException(sol.Name + ':' + 'No matching shipment found.');
            	}
            }else{
            	shipmentId = fulfillmentLine.shipmentId;
            }
            
			// OTC-18: Update existing line, if found.
            String shlKey = '' + sol.Id + shipmentId;
            
            Shipment_Line__c shlObj = new Shipment_Line__c(); 
            
            if(solToShlMap.containsKey(shlKey)){
            	shlObj = solToShlMap.get(shlKey);
            }
            else{
            	solToShlMap.put(shlKey, shlObj);
            }
                
            if(fulfillmentLine.quantityPlanned != 0){
            	shlObj.Quantity_Planned__c = KSE.addQuantityToField(fulfillmentLine.quantityPlanned, 0);
        		shlObj.Quantity_Shipped__c = 0.0;
            	shlObj.Quantity_From_Stock__c = KSE.addQuantityToField(fulfillmentLine.quantityPlanned, 0) * KSE.getConversionFactor(sol);
        		
        		Decimal activeStandardCost = ItemService.getActiveStandardCostDecimal(itemIds, facilityIds, sol.Company__c, sol.Ship_From_Location__r.Facility__c, System.Today(), sol.Product__r.Item__c);
           
	            if (sol.Product__r.Item__r.Non_Inventory__c && activeStandardCost != null) {    
	                
	                shlObj.Extended_Cost__c = activeStandardCost 
	                                            * KSE.addQuantityToField(fulfillmentLine.quantityPlanned, 0) 
	                                            * KSE.getConversionFactor(sol);
	            }
	            else {
	                shlObj.Extended_Cost__c = 0;
	            }
	            
            	if(String.isBlank(shlObj.Id)){ // If existing shipment line
            	
            	    shlObj.Company__c = sol.Company__c;
		            shlObj.Description__c = sol.Description__c;
		            shlObj.Discount_Percent__c = sol.Discount_Percent__c;
		            shlObj.Facility__c = sol.Ship_From_Location__r.Facility__c;
		            shlObj.Line_Type__c = sol.Line_Type__c; // OTC-688
		            shlObj.Location__c = sol.Ship_From_Location__c;
		            shlObj.Product__c = sol.Product__c;
		            shlObj.Item__c = sol.Product__r.Item__c;
		            shlObj.Planned_Weight__c = sol.Weight__c;  
		            shlObj.Sales_Order__c = sol.Sales_Order__r.Id;
		            shlObj.Sales_Order_Line__c = sol.Id;
		            shlObj.Shipment__c  = shipmentId;
		            shlObj.Unit_Price__c = sol.Unit_Price__c;
		            shlObj.Weight_UOM__c = sol.Weight_UOM__c;
					shlObj.Need_Date__c = sol.Required_Date__c;
					shlObj.Estimated_Ship_Date__c = null; // ba-todo add calculation here? or do in trigger.
		        }
		        
		        shlsToUpsert.add(shlObj);
            }
            
        }
           
        if(shlsToUpsert.size() > 0){
        	DML.checkUpsertAsUser(shlsToUpsert); upsert shlsToUpsert;
        }
        
        system.debug(LoggingLevel.INFO, 'Exiting createUpdateShipmentLines Method ........');
    } 
    
    //OTC-800 should block user from setting Finalized to true, if Shipment Status != Confirmed
    public static void onlyFinalizeIfConfirmed() 
    { 
    //  //KNDY-7904
    //	if(trigger.isBefore && trigger.isUpdate)
    //	{
    //		for(Shipment__c sh : (list<Shipment__c>)trigger.new)
    //		{
    //			if(sh.Finalized__c)
    //				sh.addError(sh.Name+' - User cannot manually finalize a shipment.');
    //		}
    //	}
    }
    
    /*  
    *   @description : Checks if any of the fields that might affect the estimated shipment date are changing and
    *                  recalculates the estimated shipment date based on the new data.          
    */
    public static void setShipmentDates(){
        // Not checking for trigger.isInsert as we dont have the facility information yet.
        // Instead, the estimated delivery date will be calculated when the shipment lines are created.
        if(trigger.isAfter && trigger.isUpdate){
    
            Set<Id> shipmentIds = new Set<Id>();
    
            for(Shipment__c shipment : (List<Shipment__c>) trigger.new){
				if(trigger.isUpdate 
					&& (KSE.isFieldChanging('Planned_Delivery_Date__c', shipment, trigger.oldMap) || 
						(KSE.isFieldChanging('Movement_Number__c', shipment, trigger.oldMap) && shipment.Movement_Number__c == null))
					&& shipment.Customer__c != null ){	
					shipmentIds.add(shipment.Id); 
				}
			}

            if(shipmentIds.size() > 0){
                setShipmentDates(shipmentIds);
            }
        }
    }
    
    /* 
    *   @description : KNDY-1504 - Populate the estimated shipment date. 
    */
    public static void setShipmentDates(Set<Id> shipmentIds){
        if(shipmentIds.size() > 0){
            
            // Requery shipment lines to get all the information to get the extra data needed.
            requeryShipments(shipmentIds);
            
            // Calculate the estimated shipment date for the shipments

            Set<Id> shipmentsToPlan = new Set<Id>();
            Set<String> transitRouteKeys = new Set<String>();
            Map<Id, Shipment__c> updatedShipmentsMap = new Map<Id, Shipment__c>();
                        
            shipmentIds = shipmentsMap.keySet();
                    
            for(Id shipmentId : shipmentIds){
                Shipment__c latestShipment = shipmentsMap.get(shipmentId);
                String transitKey = getTransitKey(latestShipment);
                transitRouteKeys.add(transitKey);
            }
            
            ShipmentService.getTransitRoutesMap(transitRouteKeys);
            
            try{
            	for(Id shipmentId : shipmentIds){
    
                    Shipment__c latestShipment = shipmentsMap.get(shipmentId);
                    Shipment__c updatedShipment = new Shipment__c(Id = latestShipment.Id);
                    
                    if(latestShipment != null){
                        Transit_Route__c route = routesMap.get(getTransitKey(latestShipment));
						Boolean routesEnabled = latestShipment.Shipment_Lines__r[0].Location__r.Facility__r.Enable_Transit_Route_Optimization__c;
                        // OTC-328
                        /*if(route == null && routesEnabled == true){     
							String errorDetails = 'Facility = ' + latestShipment.Shipment_Lines__r[0].Location__r.Facility__r.Name + ', ';       			
                            errorDetails += 'Customer = ' + latestShipment.Customer__r.Name + ', ';
                            errorDetails += 'Means of Transport = ' + latestShipment.Means_Of_Transport__r.Name + ', ';
                            errorDetails += 'Delivery Method = ' + latestShipment.Shipment_Lines__r[0].Sales_Order__r.Delivery_Method__c;
                            ExceptionUtil.NO_MATCHING_TRANSIT_ROUTE_FOUND.description = errorDetails;
                            
                            exService.setException(latestShipment, ExceptionUtil.NO_MATCHING_TRANSIT_ROUTE_FOUND);
                        }else{
                            exService.clearException(latestShipment, ExceptionUtil.NO_MATCHING_TRANSIT_ROUTE_FOUND);
                        }*/
                        
                        String facilityCalendarId = latestShipment.Shipment_Lines__r.size() > 0 ? 
														latestShipment.Shipment_Lines__r[0].Location__r.Facility__r.Shipping_Calendar__c : '';
                    	
                        if(latestShipment.Planned_Delivery_Date__c == null){
                            //exService.clearException(latestShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                            
                            // If the customer did not specify a required date on the sales order ("Planned delivery date" on the shipment), 
                            // then ship the goods as soon as the facility can (i.e., Ordered date + facility lead time + customer lead time).
							Decimal facilityLeadTime = latestShipment.Shipment_Lines__r[0].Location__r.Facility__r.Lead_Time__c;
                            Decimal customerLeadTime = latestShipment.Customer__r.Lead_Time__c;
                            String transitCalendarId;
                            String shippingCalendarId;
                            
                            Integer transitTimeRequired = 0;
                            
                            if(route != null && route.Shipping_Calendar__c != null){
                                transitCalendarId = route.Shipping_Calendar__c;
                            }
                            else{
                                transitCalendarId = '';
                            }                           
                            
                            transitTimeRequired = route != null ? Integer.valueOf(route.Transit_Time__c) : 0;                           
                            
                            // pxp added 06/26/2014
                            // KNDY-4741
                            // adding to incorporate customer lead time concept as order processing time needed - use the greater of the facility lead time vs. customer lead time
                            Integer shippingLeadTime = (Integer) facilityLeadTime;
                            if(customerLeadTime > facilityLeadTime){
                                shippingLeadTime = (Integer) customerLeadTime;
                            }
                            
                            if(!String.isBlank(transitCalendarId)){                     
                                shippingCalendarId = transitCalendarId;                         
                            }
                            else{
                                shippingCalendarId = facilityCalendarId;                        
                            }
                              
                            if(latestShipment.Shipment_Date_Estimated__c == null){
                            	updatedShipment.Shipment_Date_Estimated__c = KSE.calculateEndDate(system.today(), shippingLeadTime, shippingCalendarId);
                            	
                            	//Populating the field to avoid requerying in setEstimatedDate method.
                            	latestShipment.Shipment_Date_Estimated__c = updatedShipment.Shipment_Date_Estimated__c;
                            }
                            
                            // Set the earliest shipment date and latest shipment date to the estimated shipment date
                            // so that they can still be aggregated with other orders that are shipping on the same day.
                            updatedShipment.Earliest_Shipment_Date__c = latestShipment.Shipment_Date_Estimated__c;
                            updatedShipment.Latest_Shipment_Date__c = latestShipment.Shipment_Date_Estimated__c;
                            
                            updatedShipmentsMap.put(updatedShipment.Id, updatedShipment);
                        }
                        else
                        if(latestShipment.Planned_Delivery_Date__c != null){
                            
                            // Else, if the customer did specify a required date on the sales order, calculate when to ship 
                            // so that the order is delivered around the requested delivery date but within the 
                            // allowed delivery window for the customer.
                            shipmentsToPlan.add(latestShipment.Id);
                        }   
                    }
                }
                
                //  Populate planned shipment date for the shipments that have a customer 
                //  specified required date on the corresponding sales order.
                
                if(shipmentsToPlan.size() > 0){
                    
                    // Calculate the estimated shipment date based on the planned delivery date and transit time
                    // (Estimated Shipment Date = Planned Delivery Date (minus) Transit Time) 
    
                    for(Id shipmentId : shipmentsToPlan){
                        Shipment__c latestShipment = shipmentsMap.get(shipmentId);
                        Shipment__c updatedShipment = new Shipment__c(Id = latestShipment.Id);
                        
                        if(latestShipment != null){
                            Transit_Route__c route = routesMap.get(getTransitKey(latestShipment));
                            
                            // The calender name matches with the facility name (might change in the future)
					    	String facilityCalendarId = latestShipment.Shipment_Lines__r.size() > 0 ? latestShipment.Shipment_Lines__r[0].Location__r.Facility__r.Shipping_Calendar__c : '';
                            String customerCalendarId = latestShipment.Customer__r.Business_Hours__c;
                            String transitCalendarId;
                            String shippingCalendarId;
                            
                            // Find the next business day that the facility can ship if an order is made today
                            // i.e., today + facility lead time + customer lead time
							Decimal facilityLeadTime = latestShipment.Shipment_Lines__r[0].Location__r.Facility__r.Lead_Time__c;
                            
                            // Calculate the estimated shipment date such that the order reaches the customer 
                            // on the planned delivery date as requested by the customer.
                            Integer transitTimeRequired;
                            
                            if(route != null && route.Shipping_Calendar__c != null){
                                transitCalendarId = route.Shipping_Calendar__c; 
                            }
                            else{
                                transitCalendarId = '';
                            }
                                                        
                            transitTimeRequired = route != null ? Integer.valueOf(route.Transit_Time__c) : 0;                                                   
                                                            
                            Decimal customerLeadTime = latestShipment.Customer__r.Lead_Time__c;
                            
                            //pxp added 06/26/2014
                            // KNDY-4741
                            // adding to incorporate customer lead time concept as order processing time needed - use the greater of the facility lead time vs. customer lead time
                            Integer shippingLeadTime = (Integer) facilityLeadTime;
                            
                            if(customerLeadTime > facilityLeadTime){
                                shippingLeadTime = (Integer) customerLeadTime;
                            }
                            
                            if(!String.isBlank(transitCalendarId)){                     
                                shippingCalendarId = transitCalendarId; 
                            }
                            else{
                                shippingCalendarId = facilityCalendarId;                    
                            }
                            
                            Date nextFacilityShipmentDate = KSE.calculateEndDate(system.today(), shippingLeadTime, shippingCalendarId);                     
                            
                            // The required date for the customer as entered on the sales order.
                            Date plannedDeliveryDate = latestShipment.Planned_Delivery_Date__c;
                            
                            if(plannedDeliveryDate != null){
                                
                                // Find the latest delivery date that is accepted by the customer to receive the delivery
                                // i.e., planned delivery date + latest delivery window.
                                Integer latestDeliveryWindow = latestShipment.Customer__r.Latest_Delivery_Window__c != null ? 
                                                                    Integer.valueOf(latestShipment.Customer__r.Latest_Delivery_Window__c) : 0;
                                                                    
                                Date latestDeliveryDate = KSE.nextBusinessDate(plannedDeliveryDate, latestDeliveryWindow, customerCalendarId);
                                
                                // Find the earliest delivery date that is accepted by the customer to receive the delivery
                                // i.e., planned delivery date - earliest delivery window.
                                Integer earliestDeliveryWindow = latestShipment.Customer__r.Earliest_Delivery_Window__c != null ? 
                                                                    Integer.valueOf(latestShipment.Customer__r.Earliest_Delivery_Window__c) : 0;
                                                                        
                                Date earliestDeliveryDate = KSE.previousBusinessDate(plannedDeliveryDate, earliestDeliveryWindow, customerCalendarId);
                                                                    
                                Date estimatedShipmentDate = KSE.previousBusinessDate(plannedDeliveryDate, transitTimeRequired, shippingCalendarId);
                                
                                // If the estimated shipment date is on or after the next facility shipment date
                                // then the estimated shipment date is valid.
                                if(estimatedShipmentDate >= nextFacilityShipmentDate){
                                    updatedShipment.Shipment_Date_Estimated__c = estimatedShipmentDate;  
                                    
                                    //exService.clearException(latestShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                                }
                                // If the estimated shipment date is before the next facility shipment date
                                // then check if the next facility shipment date gives enough time to ship by the 
                                // latest delivery date atleast.
                                else{
                                    Date estimatedDeliveryDate = KSE.nextBusinessDate(nextFacilityShipmentDate, transitTimeRequired, customerCalendarId);
                                    
                                    // If the shipment can be delivered by the latest delivery date,
                                    // then the next facility shipment date is good for estimated shipment date.
                                    if(estimatedDeliveryDate <= latestDeliveryDate){
                                        updatedShipment.Shipment_Date_Estimated__c = nextFacilityShipmentDate;  
                                             
                                        //exService.clearException(latestShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP); // Not enough transit time??
                                    }else{
                                        // Else, if the shipment cannot be delivered within the window,
                                        // reject the planned delivery date.
                                        //exService.setException(latestShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                                        //continue;
                                        
                                        //OTC-266
                                        if(estimatedShipmentDate < system.today()){
                                        	estimatedShipmentDate = KSE.calculateEndDate(system.today(), 0, shippingCalendarId);
                                        }
                                        updatedShipment.Shipment_Date_Estimated__c = estimatedShipmentDate; 
                                        
                                    }
                                }
								
								//Populating the field to avoid requerying in setEstimatedDate method.
                            	latestShipment.Shipment_Date_Estimated__c = updatedShipment.Shipment_Date_Estimated__c; 
                                
                                // Calculate the earliest shipment date such that the order reaches the customer on the earliest date
                                // accepted by the customer for delivery.
                                Date earliestShipmentDate = KSE.previousBusinessDate(earliestDeliveryDate, transitTimeRequired, shippingCalendarId);                            
                                
                                // If the earliest shipment date is on or after the next facility shipment date
                                // then the earliest shipment date is valid.
                                if(earliestShipmentDate >= nextFacilityShipmentDate){
                                    updatedShipment.Earliest_Shipment_Date__c = earliestShipmentDate;    
                                    //exService.clearException(latestShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                                }
                                // If the earliest shipment date is before the next facility shipment date
                                // then check if the next facility shipment date gives enough time to ship by the 
                                // latest delivery date atleast.
                                else{
                                    Date estimatedDeliveryDate = KSE.nextBusinessDate(nextFacilityShipmentDate, transitTimeRequired, customerCalendarId);
                                    
                                    // If the shipment can be delivered by the latest delivery date,
                                    // then the next facility shipment date is good for earliest shipment date.
                                    if(estimatedDeliveryDate <= latestDeliveryDate){
                                        updatedShipment.Earliest_Shipment_Date__c = nextFacilityShipmentDate;
                                        //exService.clearException(updatedShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);       
                                    }else{
                                        // Else, if the shipment cannot be delivered within the window,
                                        // reject the planned delivery date.
                                        //exService.setException(updatedShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP); // Not enough facility lead time??
                                        //continue;
                                        
                                        //OTC-266
                                        if(earliestShipmentDate < system.today()){
                                        	earliestShipmentDate = KSE.calculateEndDate(system.today(), 0, shippingCalendarId);
                                        }
                                        updatedShipment.Earliest_Shipment_Date__c = earliestShipmentDate; 
                                    }
                                }
                                
                                // Calculate the latest shipment date such that the order reaches the customer on the latest date
                                // accepted by the customer for delivery.
                                Date latestShipmentDate = KSE.previousBusinessDate(latestDeliveryDate, transitTimeRequired, shippingCalendarId);
                                
                                // If the latest shipment date is on or after the next facility shipment date
                                // then the latest shipment date is valid.
                                if(latestShipmentDate >= nextFacilityShipmentDate){
                                    updatedShipment.Latest_Shipment_Date__c = latestShipmentDate;    
                                    //exService.clearException(updatedShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                                }
                                // If the latest shipment date is before the next facility shipment date
                                // then check if the next facility shipment date gives enough time to ship by the 
                                // latest delivery date atleast.
                                else{
                                    Date estimatedDeliveryDate = KSE.nextBusinessDate(nextFacilityShipmentDate, transitTimeRequired, customerCalendarId);
                                    
                                    // If the shipment can be delivered by the latest delivery date,
                                    // then the next facility shipment date is good for latest shipment date.
                                    if(estimatedDeliveryDate <= latestDeliveryDate){
                                        updatedShipment.Latest_Shipment_Date__c = nextFacilityShipmentDate;      
                                        //exService.clearException(updatedShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                                    }else{
                                        // Else, if the shipment cannot be delivered within the window,
                                        // reject the planned delivery date.
                                        //exService.setException(updatedShipment, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                                        //continue;
                                        
                                        //OTC-266
                                        if(latestShipmentDate < system.today()){
                                        	latestShipmentDate = KSE.calculateEndDate(system.today(), 0, shippingCalendarId);
                                        }
                                        updatedShipment.Latest_Shipment_Date__c = latestShipmentDate; 
                                    }
                                }
                                
                                // If the execution reached this point, something has been updated on shipment.
                                updatedShipmentsMap.put(updatedShipment.Id, updatedShipment);
                                
                            }
                        }
                    }
                }
                
                if(updatedShipmentsMap.size() > 0){
                	DML.updateAsUser(updatedShipmentsMap.values());
                }
                
            }catch(Exception ex){           
                ExceptionService.addMessage( MessageUtil.Severity.Error.name(), ex.getMessage(), ex.getStackTraceString());
                return;
            }
            
            // Upsert the exceptions
            exService.finishTasks();
            
            // Calculate the estimated delivery date for the new estimated shipment date.
            ShipmentService.setEstimatedDeliveryDate(updatedShipmentsMap.keySet());
        }
    }
    
    public static void updateSOPricingDate(){
        if (trigger.isAfter && (trigger.isUpdate || trigger.isInsert)){
            Set<Id> shipmentIds = new Set<Id>();
            for(Shipment__c shipment : (List<Shipment__c>) trigger.new){
                if (KSE.isFieldChanging('Movement_Number__c', shipment, trigger.oldMap) || 
                    (KSE.isFieldChanging('Shipment_Date_Estimated__c', shipment, trigger.oldMap) && Shipment.Status__c != 'Delivered') 
                    || (KSE.isFieldChanging('Date_Shipped__c', shipment, trigger.oldMap)) )  {
                    shipmentIds.add(shipment.Id);
                }
            }
            if(shipmentIds.size() > 0){
                ShipmentService.updateSOPricingDate(shipmentIds);
            }
        }
    }

    public static void updateSOPricingDate(Set<Id> shipmentIds){
        //Sales_Order__c[] soList = [Select id, pricing_date__c, (select id, shipment__c from Shipment_Lines__r) from Sales_Order__c]; // where Shipment_Lines__r.Shipment__c In: shipmentIds
        Shipment_Line__c[] shpLnList = [select Id, Sales_Order__c, Shipment__c,
                                                Shipment__r.Shipment_Date_Estimated__c, Shipment__r.Date_Shipped__c,
                                                Sales_Order_Line__r.Sales_Order__r.Pricing_date__c,
                                                Sales_Order_Line__r.Sales_Order__r.Price_determination_date__c
                                        from Shipment_Line__c 
                                        where Shipment__c in: shipmentIds and sales_order_line__r.Sales_Order__r.Price_determination_date__c = 'Shipment Date'];

        if (!shpLnList.isEmpty()){
            Map<Id, Sales_Order__c> soForUpdateMap = new Map<Id, Sales_Order__c>();
            for (Shipment_Line__c shpLn : shpLnList){
                
                Sales_Order__c salesOrder = shpLn.Sales_Order_Line__r.Sales_Order__r;

                if (salesOrder.Price_determination_date__c == 'Shipment Date'){

                    if (salesOrder.Pricing_date__c != shpLn.Shipment__r.Date_Shipped__c 
                        && shpLn.Shipment__r.Date_Shipped__c != null){
                        
                        salesOrder.Pricing_date__c = shpLn.Shipment__r.Date_Shipped__c.date();
                        soForUpdateMap.put(salesOrder.Id, salesOrder);

                    } else if (salesOrder.Pricing_date__c != shpLn.Shipment__r.Shipment_Date_estimated__c
                        && shpLn.Shipment__r.Shipment_Date_estimated__c != null){
                        
                        salesOrder.Pricing_date__c = shpLn.Shipment__r.Shipment_Date_estimated__c;
                        soForUpdateMap.put(salesOrder.Id, salesOrder);
                    }
                }
            }
            if (!soForUpdateMap.isEmpty()){
                DML.updateAsUser(soForUpdateMap.values());
            }
        }
    }

    /*  
    *   @description : Checks if any of the fields that might affect the delivery date are changing and
    *                  recalculate the estimated delivery date based on the new data.
    */
    public static void setEstimatedDeliveryDate(){
        
        // Not checking for trigger.isInsert as we dont have the facility information yet.
        // Instead, the estimated delivery date will be calculated when the shipment lines are created.
        if(trigger.isAfter && trigger.isUpdate){
            Set<Id> shipmentIds = new Set<Id>();
            for(Shipment__c shipment : (List<Shipment__c>) trigger.new){
                if(trigger.isUpdate && 
                    (KSE.isFieldChanging('Customer__c', shipment, trigger.oldMap) ||
                     KSE.isFieldChanging('Date_Shipped__c', shipment, trigger.oldMap) ||
                     KSE.isFieldChanging('Means_of_Transport__c', shipment, trigger.oldMap) ||
                     KSE.isFieldChanging('Shipment_Date_Estimated__c', shipment, trigger.oldMap) ||
                     KSE.isFieldChanging('Status__c', shipment, trigger.oldMap) 
                    )
                ){  
                    if( shipment.Customer__c != null )
                    	shipmentIds.add(shipment.Id);
                }
            }
            
            if(shipmentIds.size() > 0){
                ShipmentService.setEstimatedDeliveryDate(shipmentIds);
            }
        }
    }
    
    /* 
    *   @description : KNDY-1504 - Populate the estimated delivery date. 
    */
    public static void setEstimatedDeliveryDate(Set<Id> shipmentIds){
        
        if(shipmentIds.size() > 0){
        	
            // Requery shipment lines to get the extra data needed.
            //shipmentsMap.clear();
            requeryShipments(shipmentIds);
            
            // Query for the required transit times
            Set<String> transitRouteKeys = new Set<String>();
            for(Id shipmentId : shipmentIds){
                Shipment__c latestShipment = shipmentsMap.get(shipmentId);
                String transitKey = getTransitKey(latestShipment);
                transitRouteKeys.add(transitKey);                                      
            }
            
            // Query for transit routes
            ShipmentService.getTransitRoutesMap(transitRouteKeys);
            
            // Calculate the estimated delivery date based on the estimated shipment date and transit time
            // (Estimated Delivery Date = Estimated Shipment Date (plus) Transit Time) 
                
            Map<Id, Shipment__c> updatedShipmentsMap = new Map<Id, Shipment__c>();
            
            for(Id shipmentId : shipmentIds){
                Date dateShipped;
                Shipment__c latestShipment = shipmentsMap.get(shipmentId);
                Shipment__c updatedShipment = new Shipment__c(Id = latestShipment.Id);
                
                if(latestShipment != null){
                    String transitKey = getTransitKey(latestShipment);
                    Id facilityCalendarId = latestShipment.Shipment_Lines__r.size() > 0 ? 
													latestShipment.Shipment_Lines__r[0].Location__r.Facility__r.Shipping_Calendar__c : '';
                    Id customerCalendarId = latestShipment.Customer__r.Business_Hours__c;
                    
                    if((latestShipment.Status__c == 'Confirmed' || latestShipment.Status__c == 'Delivered') && 
                        latestShipment.Date_Shipped__c != null){
                        dateShipped = latestShipment.Date_Shipped__c.date();
                    }else{
                        dateShipped = latestShipment.Shipment_Date_Estimated__c;
                    }
                    
                    Integer transitTimeRequired = 0;
                    
                    if(dateShipped != null) {
                        if (routesMap.get(getTransitKey(latestShipment)) != null){
                            transitTimeRequired = routesMap.containsKey(getTransitKey(latestShipment)) ? 
                                                    Integer.valueOf(routesMap.get(getTransitKey(latestShipment)).Transit_Time__c) : 0;
                        }
                        
                        updatedShipment.Estimated_Delivery_Date__c = KSE.nextBusinessDate(dateShipped, transitTimeRequired, customerCalendarId); 
                    }
                    else{
                        updatedShipment.Estimated_Delivery_Date__c = null;
                    }
                    updatedShipmentsMap.put(updatedShipment.Id, updatedShipment);
                }
            }
            
            if(updatedShipmentsMap.size() > 0){
        		DML.updateAsUser(updatedShipmentsMap.values());
            }
        }
        
        // Clear the map so that the next trigger invocation 
        // can requery the latest shipments.
        shipmentsMap.clear();
    }
    
    // Delete the shipment header if all of its lines are deleted.
    public static void deleteShipments(){
        if(trigger.isAfter && trigger.isDelete){
        	if(ShipmentService.isShipmentDelete == false){
	            Set<Id> shipmentIds = new Set<Id>();
	            
	            for(Shipment_Line__c shl : (List<Shipment_Line__c>) trigger.old){
	                shipmentIds.add(shl.Shipment__c);
	            }
	            
	            if(shipmentIds.size() > 0){
	                List<Shipment__c> shipmentsToDelete = new List<Shipment__c>();
	                for(Shipment__c shipment : [SELECT Id, (SELECT Id FROM Shipment_Lines__r) FROM Shipment__c WHERE Id IN :shipmentIds]){
	                    if(shipment.Shipment_Lines__r == null || shipment.Shipment_Lines__r.size() == 0){
	                        shipmentsToDelete.add(shipment);
	                    }
	                }
	                
	                if(shipmentsToDelete.size() > 0){
	                    DML.deleteAsUser(shipmentsToDelete);
	                }
	            }
        	}
        }
    }
    
    public static void rollupSalesOrderLineQuantities(){
    	if(trigger.isAfter && trigger.isUpdate){
    		Set<Id> shIds = new Set<Id>();
    		for(Shipment__c sh : (List<Shipment__c>) trigger.new){
        	    if(sh.Type__c == 'Sales Order Shipment' && KSE.isFieldChanging('Status__c', sh, trigger.oldMap)){
             		if(sh.Status__c == 'Confirmed' || sh.Status__c == 'Delivered'){
             			shIds.add(sh.Id);
             		}        
                }
    		}
    		
    		if(shIds.size() > 0){
    			Set<Id> solIds = new Set<Id>();
    			
    			for(Shipment_Line__c shl : [SELECT Id, Sales_Order_Line__c 
    				   						  FROM Shipment_Line__c 
    				  						 WHERE Shipment__c IN :shIds]){
    				if(shl.Sales_Order_Line__c != null){  						 	
    					solIds.add(shl.Sales_Order_Line__c);
    				}
    			}
    			
    			if(solIds.size() > 0){
	            	ShipmentLineService.rollupSalesOrderLineQuantities(solIds);
	            }
    		}
    	}
    }
    
    /*  
    *   @description : Check if the shipments are already in the map
    *                  If not, collect the ids that are not in the map and requery for them.
    *                  and return the latest map.
    *
    *   @return : Map<Id, Shipment__c> map of shipments with 'Id' as key.
    */
    static Map<Id, Shipment__c> requeryShipments(Set<Id> shipmentIds){
        
        Set<Id> shipmentsToQuery = new Set<Id>();
        
        for(Id shipmentId : shipmentIds){
            if(shipmentsMap.containsKey(shipmentId) == false){
                shipmentsToQuery.add(shipmentId);
            }
        }
        
        if(shipmentsToQuery.size() > 0){
            for(Shipment__c shipment : [SELECT Id, Customer__r.Name, Customer__r.Address__c, Customer__r.Earliest_Delivery_Window__c,
                                               Customer__r.Latest_Delivery_Window__c, Customer__r.Lead_Time__c, 
                                               Customer__r.Business_Hours__c, Customer__r.Business_Hours__r.Name,
											   Date_Shipped__c, Shipment_Date_Estimated__c,
                                               Status__c, Means_of_Transport__c, Means_of_Transport__r.Name, Planned_Delivery_Date__c,
											   (SELECT Id, Location__r.Facility__r.Address__c, Location__r.Facility__r.Enable_Transit_Route_Optimization__c,
												       Location__r.Facility__r.Lead_Time__c, Location__r.Facility__r.Name,
												       Location__r.Facility__r.Shipping_Calendar__c, Sales_Order__c, Sales_Order__r.Delivery_Method__c
												  FROM Shipment_Lines__r limit 1) 
                                          FROM Shipment__c
									     WHERE Id IN :shipmentsToQuery and Customer__c != null ]){
                                             
                shipmentsMap.put(shipment.Id, shipment);
            }
        }
        
        return shipmentsMap;
    }
    
    /*  
    *   @description : Check if the transit route keys are already in the map
    *                   If not, collect the keys that are not in the map and requery for them.
    *                   and return the latest map.
    *
    *   @return : Map<String, Transit_Route__c> map of transit routes with 'Transit_Route_Unique__c' as key.
    */
    static Map<String, Transit_Route__c> getTransitRoutesMap(Set<String> transitRouteKeys){
        
        Set<String> transitRouteKeysToQuery = new Set<String>();
        
        for(String transitRouteKey : transitRouteKeys){
            if(routesMap.containsKey(transitRouteKey) == false){
                transitRouteKeysToQuery.add(transitRouteKey);
                routesMap.put(transitRouteKey, null); // cache the transit key even if there are no reoutes for this key to reduce queries
            }
        }
        
        if(transitRouteKeysToQuery.size() > 0){
            for(Transit_Route__c route : [SELECT Id, Transit_Time__c , Means_of_Transport__c,
                                                 Origin__c, Destination__c, Transit_Route_Unique__c, Shipping_Calendar__c, Delivery_Method__c
                                            FROM Transit_Route__c 
                                           WHERE Transit_Route_Unique__c IN :transitRouteKeysToQuery
                                         ]){
                routesMap.put(route.Transit_Route_Unique__c, route);
            }
        }
        
        return routesMap;
    }
    
    /*  
    *   @description    Return the transit key that matches this shipment
    */
    static String getTransitKey(Shipment__c shipment){
        String transitKey = ''; // KNDY-10333 + shipment.Means_of_Transport__c + shipment.Shipment_Lines__r[0].Location__r.Facility__r.Address__c+ shipment.Customer__r.Address__c+ shipment.Shipment_Lines__r[0].Sales_Order__r.Delivery_Method__c;       
        return transitKey;                             
    }


    /* 
    *   @description : OTC-189 - Because the Dimensional Weight is already in use, update the value through a trigger. 
    */

    public static void setDimensionalWeight(){

        if (Trigger.isBefore && Trigger.isUpdate){
            List<Shipment__c> shipments = new List<Shipment__c>();
            Set<Id> motIds = new Set<Id>();
            Set<Id> locationIds = new Set<Id>();

            for (Shipment__c shipment : (List<Shipment__c>) trigger.new){
                if ((trigger.isInsert || 
                     Trigger.isUpdate && 
                        (KSE.isFieldChanging('Maximum_Dimensional_Percent__c', shipment, trigger.oldMap) ||
                         KSE.isFieldChanging('Total_Weight_Planned__c', shipment, trigger.oldMap))
                     )){
                    shipments.add(shipment);
                    locationIds.add(shipment.Ship_From_Location__c);
                    motIds.add(shipment.Means_of_Transport__c);
                }
            }

            if(shipments.size() > 0){
                Map<Id, Means_of_Transport__c> motMap = new Map<Id, Means_of_Transport__c>(
                                                                [SELECT Id, Maximum_Weight__c, Minimum_Weight__c 
                                                                   FROM Means_of_Transport__c 
                                                                  WHERE Id IN :motIds]
                                                        );
                
                Map<Id, Location__c> locationMap = new Map<Id, Location__c>(SalesOrderFlowCache.cachedLocationsForIds(locationIds));
                                                                        
                for (Shipment__c sh : shipments){
                    if (motMap.containsKey(sh.Means_of_Transport__c)){
                        Means_of_Transport__c mot = motMap.get(sh.Means_of_Transport__c);
                        sh.Dimensional_Weight__c = KSE.addQuantityToField(mot.Maximum_Weight__c, 0) * KSE.addQuantityToField(sh.Maximum_Dimensional_Percent__c, 0) / 100;
                        
                        // OTC-8: Aggregate full truck load sales orders automatically. 
                        if( sh.Dimensional_Weight__c > 0 && 
                            sh.Dimensional_Weight__c <= mot.Maximum_Weight__c && 
                            sh.Dimensional_Weight__c >= mot.Minimum_Weight__c && 
                        	(sh.Ship_From_Location__c != null && 
                        		locationMap.get(sh.Ship_From_Location__c).Facility__r.Sales_Order_Aggregation_Required__c == true)){
                        			
                            sh.Movement_Number__c = SHIPMENT_LOAD_NUMBER_PREFIX + sh.Autonumber__c;
                        }
                    }
                }
            }
        }
    }
    
    // OTC-16: Reprice sales order lines after aggregation and disaggregation.
    public static void validateSalesOrderLinePrices() {
    	List<Shipment__c> shipments = new List<Shipment__c>();
    	Boolean isAggregation = false;
    	
    	if(trigger.isBefore && (trigger.isDelete || trigger.isUpdate)){
    		for(Shipment__c shipment : (List<Shipment__c>) trigger.old){
    			if(trigger.isDelete || 
    				(trigger.isUpdate &&  
    				KSE.isFieldChanging('Movement_Number__c', shipment, trigger.newMap))){
	    			
	    			if( ! String.isBlank(shipment.Movement_Number__c)){
	    				shipments.add(shipment);
	    				isAggregation = false;
	    			}
    			}
    		}
    	}
    	 	
    	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete)){
    		for(Shipment__c shipment : (List<Shipment__c>) trigger.new){
    			if( KSE.isFieldChanging('Movement_Number__c', shipment, trigger.oldMap) ||
    				KSE.isFieldChanging('Total_Product_Weight__c', shipment, trigger.oldMap)){
					
					if( ! String.isBlank(shipment.Movement_Number__c)){
    					shipments.add(shipment);
    					isAggregation = true;
					}
    			}
    		}
    	}
    	
    	if(shipments.size() > 0){
    		validateSalesOrderLinePrices(shipments, isAggregation);
    	}
    }
    
    public static void validateSalesOrderLinePrices(List<Shipment__c> shipments, Boolean isAggregation) {
        Set<String> movementNumbers = new Set<String>();
    	
    	for(Shipment__c shipment : shipments){
    		if( ! String.isBlank(shipment.Movement_Number__c)){
				movementNumbers.add(shipment.Movement_Number__c);	
			}
    	}
    	
    	if(movementNumbers.isEmpty()){
    		return;
    	}
    	
        Set<Id> companyIds = new Set<Id>();
        Map<Id, Sales_Order__c> updatedSalesOrders = new Map<Id, Sales_Order__c>();
        
        Map<Id, Shipment__c> shMap = new Map<Id, Shipment__c>(
										 [SELECT Id, Company__c, Total_Product_Weight__c, Movement_Number__c,
	        							    	 (SELECT Id, Sales_Order_Line__r.Sales_Order__c, Sales_Order_Line__r.Sales_Order__r.Bracket_Price_Field_In_Use__c,
	        							    	         Sales_Order_Line__r.Sales_Order__r.Total_Product_Weight__c, Sales_Order_Line__r.Sales_Order__r.Pricing_Bracket__c 
                                                    FROM Shipment_Lines__r)
	        							    FROM Shipment__c
	        							   WHERE Movement_Number__c IN :movementNumbers]
    							     );	        							   
	    
	    // Calculate weights for movement numbers.
	    Map<String, Decimal> aggregatedWeights = new Map<String, Decimal>();
	         							   
        // Get shipment lines for all the shipments that are part of an aggregation/disaggregation.
        for(Shipment__c shipment : shMap.values()){
    		Decimal aggregatedWeight = KSE.addQuantityToField(aggregatedWeights.get(shipment.Movement_Number__c), shipment.Total_Product_Weight__c); 
        	aggregatedWeights.put(shipment.Movement_Number__c, aggregatedWeight);
        	
        	companyIds.add(shipment.Company__c);
        }
        
        if(isAggregation == false){
	        for(Shipment__c shipment : shipments){
	        	shipment = shMap.get(shipment.Id);
	        	
	        	if(shipment == null){
	        		continue;
	        	}
	        	
	        	Decimal aggregatedWeight = KSE.subtractDecimals(aggregatedWeights.get(shipment.Movement_Number__c), shipment.Total_Product_Weight__c); 
        		aggregatedWeights.put(shipment.Movement_Number__c, aggregatedWeight);
	        }
        }
        
        Map<Id, BracketPricingService.BracketPriceRange[]> bracketPricesByCompanyId = SalesOrderFlowCache.cachedBracketPriceRanges(companyIds);
        
        for(Shipment__c shipment : shMap.values()){
        	
        	if(shipment.Shipment_Lines__r == null || shipment.Shipment_Lines__r.size() == 0){
        		continue;
        	}
        	
        	for(Shipment_Line__c shl : shipment.Shipment_Lines__r){
	            
	        	if (bracketPricesByCompanyId == null || 
	            	bracketPricesByCompanyId.isEmpty() || 
	            	bracketPricesByCompanyId.containsKey(shipment.Company__c) == false)  {
	                
	                if(shl.Sales_Order_Line__r!=null){
                        shl.Sales_Order_Line__r.Sales_Order__r.Bracket_Price_Field_In_Use__c = null;
	                    updatedSalesOrders.put(shl.Sales_Order_Line__r.Sales_Order__c, shl.Sales_Order_Line__r.Sales_Order__r);
	                }
                }
                else{
            		for (BracketPricingService.BracketPriceRange bp : bracketPricesByCompanyId.get(shipment.Company__c)) {
		                // If has movement number, then check for aggregated weight.
	                	if(	aggregatedWeights.get(shipment.Movement_Number__c) >= bp.volumeRangeBottom && 
	                		aggregatedWeights.get(shipment.Movement_Number__c) <= bp.volumeRangeHigh
	                	){
                    	    if (shl.Sales_Order_Line__r != null && String.isBlank(shl.Sales_Order_Line__r.Sales_Order__r.Pricing_Bracket__c)){
    	                            shl.Sales_Order_Line__r.Sales_Order__r.Bracket_Price_Field_In_Use__c = bp.pricebookLineField;
    		                        updatedSalesOrders.put(shl.Sales_Order_Line__r.Sales_Order__c, shl.Sales_Order_Line__r.Sales_Order__r);
    		                        break;
                                }
	                	    }
		                }        
                	}
	            }
            } 
        
        if(isAggregation == false){
	        for(Shipment__c shipment : shipments){
	        	shipment = shMap.get(shipment.Id);
	        	
	        	if(shipment == null || shipment.Shipment_Lines__r == null || shipment.Shipment_Lines__r.size() == 0){
	        		continue;
	        	}
	        	
	        	for(Shipment_Line__c shl : shipment.Shipment_Lines__r){
		         	if(shl.Sales_Order_Line__r!=null){ 
		        		if (bracketPricesByCompanyId == null || 
		            		bracketPricesByCompanyId.isEmpty() || 
		            		bracketPricesByCompanyId.containsKey(shipment.Company__c) == false)  {
		                
	                    	shl.Sales_Order_Line__r.Sales_Order__r.Bracket_Price_Field_In_Use__c = null;
		                	updatedSalesOrders.put(shl.Sales_Order_Line__r.Sales_Order__c, shl.Sales_Order_Line__r.Sales_Order__r);
	                	}
	                	else{
	            			for (BracketPricingService.BracketPriceRange bp : bracketPricesByCompanyId.get(shipment.Company__c)) {
			                	if(	shl.Sales_Order_Line__r.Sales_Order__r.Total_Product_Weight__c >= bp.volumeRangeBottom && 
		                			shl.Sales_Order_Line__r.Sales_Order__r.Total_Product_Weight__c <= bp.volumeRangeHigh
		                		){
		                        	shl.Sales_Order_Line__r.Sales_Order__r.Bracket_Price_Field_In_Use__c = bp.pricebookLineField;
			                    	updatedSalesOrders.put(shl.Sales_Order_Line__r.Sales_Order__c, shl.Sales_Order_Line__r.Sales_Order__r);
			                    	break;
		                		}
			            	}
		            	}
		            }
	            } 
	        }
        }
        
        
        if(updatedSalesOrders.size() > 0){
        	DML.updateAsUser(updatedSalesOrders.values());
        }
    }
    
    public static void validateShipments(){
    	if(trigger.isAfter && trigger.isUpdate){
    		for(Shipment__c shipment : (List<Shipment__c>) trigger.new){
    			if(shipment.Type__c == ShipmentService.SHIPMENT_TYPE_SALES_ORDER && KSE.isFieldChanging('Weight_Out_Of_Range__c', shipment, trigger.oldMap)){
    				if (shipment.Weight_Out_Of_Range__c) {
					    exService.setException(shipment, ExceptionUtil.SHIPMENT_OVER_WEIGHT_EXCEPTION);
					} else {
					    exService.clearException(shipment, ExceptionUtil.SHIPMENT_OVER_WEIGHT_EXCEPTION);
					}
    			}
    		}
    	}
    }
    
    public static void validateShipDate(){
    	if(trigger.isAfter && trigger.isUpdate){
    		Set<Id> shipmentIds = new Set<Id>();
    		
    		for(Shipment__c shipment : (List<Shipment__c>) trigger.new){
    			if(shipment.Type__c == ShipmentService.SHIPMENT_TYPE_SALES_ORDER){
		    		if( KSE.isFieldChanging('Shipment_Date_Estimated__c', shipment, trigger.oldMap)
	    			){
	    				shipmentIds.add(shipment.Id); 
	    			}
    			}
    		}
    		
    		if(! shipmentIds.isEmpty() ){
    			ShipmentLineService.validateShipDate(shipmentIds);
       		}
    	}
    }
    
    public static Map<Id,Boolean> checkFinalized(Set<Id> shipmentIds) {
    	Map<Id,Boolean> result = new Map<Id,Boolean>();
    	for (Id shipmentId:shipmentIds)
    		result.put(shipmentId,false);
    	for (Inventory_Transaction__c it:[SELECT Id,Shipment_Line__r.Shipment__c FROM Inventory_Transaction__c WHERE Shipment_Line__r.Shipment__c IN :shipmentIds AND Inventory_Change__c = null])
    		result.put(it.Shipment_Line__r.Shipment__c,true);
    	return result;
    }
}