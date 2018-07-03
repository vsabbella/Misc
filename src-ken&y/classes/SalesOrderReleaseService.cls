/**
 *	SalesOrderReleaseService class enables the release of a Sales Order
 *	@author Jerome Israel
 *	@date 04/11/2017
 *
 */
public with sharing class SalesOrderReleaseService {

	public static Boolean futureCall = false;

	public static void release(Set<Id> salesOrderIds) {
        
        List<Sales_Order_Line__c> soLines = SalesOrderReleaseService.getSalesOrderLines(salesOrderIds);

        SalesOrderReleaseService.releaseSalesOrders(SalesOrderReleaseService.getSoToSoLinesMap(soLines));
    }


    public static void release(Id salesOrderId) { // Return the created or modifed shipments?  
    	Integer startTime = Limits.getCpuTime();

        if(salesOrderId == null){
            ExceptionService.addMessage( MessageUtil.Severity.Error.name(), 'Sales order \'Id\' cannot be null.', '' );
            return;
        }

        List<Sales_Order_Line__c> soLines = SalesOrderReleaseService.getSalesOrderLines(new Set<Id>{ salesOrderId }); 

        if(soLines.size() > 0){

            //Truncate the company id from 18 chars to 15chars to match the config name
            String companyId = String.valueOf(soLines[0].Sales_Order__r.Company__c).substring(0, 15);

            String otcConfigName = 'CompanyId=' + companyId;

            OTC__c otc = OTC__c.getInstance(OTCConfigName);

            //If otc is null just return 200 as default value (This is needed for Unit test cases)
            Integer AsyncThreshold = (otc != null ? Integer.valueOf((KSE.addQuantityToField(otc.Max_Lines_for_Sync_order_release__c, 0))) : 200);

            //Check if total SO lines > AsyncThreshold
            if(soLines.size() <= AsyncThreshold){

                SalesOrderReleaseService.releaseSalesOrders(SalesOrderReleaseService.getSoToSoLinesMap(soLines));
            } else {
                SalesOrderReleaseService.futureCall = true;
                //Call future method
                futureRelease(salesOrderId);
            }
        }

        Integer endTime = Limits.getCpuTime();
    }

    @future
    public static void futureRelease(Id salesOrderId){
        SalesOrderReleaseService.futureCall = true;
        List<Sales_Order_Line__c> soLines = SalesOrderReleaseService.getSalesOrderLines(new Set<Id>{ salesOrderId });
        SalesOrderReleaseService.releaseSalesOrders(SalesOrderReleaseService.getSoToSoLinesMap(soLines));
    }

	/**
	 *	getSalesOrderLines method fetches the Sales Order Lines info by querying all Open and Draft Lines for
	 *  the given set of Sales Orders.
	 *	@param Set<Id> salesOrderIds
	 *	@return List<Sales_Order_Line__c>
	 *
	 */													    	
	private static List<Sales_Order_Line__c> getSalesOrderLines(Set<Id> salesOrderIds){

        List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>();

        Set<String> solFieldsToQuery = new Set<String>{ 'Id','Name', 'Product__r.Item__c', 'Company__c','Description__c','Discount_Percent__c','Pricebook__c','Quantity_From_Stock__c','Fulfillment_Source__c',
            'Purchase_From_Supplier__c','Currency__c','Has_Exceptions__c','Unit_Price__c','Estimated_Ship_Date__c','Item_Specification__c', 'Type__c', 'Line__c',
            'Weight__c','Weight_UOM__c','Status__c','Dimension_UOM__c','Weight_UOM_Name__c','Dimension_UOM_Name__c','Quantity_Backordered__c','Related_Sales_Order_Line__c',
            'Quantity_Ordered__c','Quantity_Shipped__c','Required_Date__c','Extended_Price__c','Product__c','Product_Weight__c','Non_Shippable__c', 'Product__r.Item__r.Packaging_UOM__c',
            'Item_Source__c','Parent_Sales_Order_Line__c','Ordered_Date_Time__c','Off_Invoice_Rate__c','Sales_Order__c','Selling_UOM__c','Ship_From_Location__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c',
            'Line_Type__c','Work_Order__c','Agreement_Line__c','Skid__c', 'Quantity_Fulfilled__c', 'Quantity_Planned__c','Company__r.Do_Not_Release_Partial_Sales_Orders__c' };

        Set<String> soFieldsToQuery = new Set<String>{ 'Sales_Order__r.Company__r.Use_Warranty_Repairs__c','Sales_Order__r.Pricebook__c','Sales_Order__r.Delivery_Method__c','Sales_Order__r.Company__c','Sales_Order__r.Bill_to__c','Sales_Order__r.Ship_To__c',
            'Sales_Order__r.Ship_to_Street__c','Sales_Order__r.Ship_to_State__c','Sales_Order__r.Ship_to_City__c','Sales_Order__r.Ship_to_Zip_Code__c',
            'Sales_Order__r.Ship_to_Country__c', 'Sales_Order__r.Status__c','Sales_Order__r.Hold__c','Sales_Order__r.Payment_Term__c', 'Sales_Order__r.Has_Exceptions__c',
            'Sales_Order__r.Type__c','Sales_Order__r.Customer__c','Sales_Order__r.Dimensional_Weight__c','Sales_Order__r.Required_Date__c',
            'Sales_Order__r.Means_of_Transport__c','Sales_Order__r.Exceeds_Max_Weight__c','Sales_Order__r.Total_Weight__c','Sales_Order__r.Total_Order_Volume__c',
            'Sales_Order__r.Subtotal__c','Sales_Order__r.Total_Quantity_Ordered__c','Sales_Order__r.Total_Product_Weight__c','Sales_Order__r.Order_Total__c',
            'Sales_Order__r.Weight_UOM__c','Sales_Order__r.Dimension_UOM__c','Sales_Order__r.Price_Determination_Date__c','Sales_Order__r.Pricing_Date__c',
            'Sales_Order__r.Date_Time_Ordered__c', 'Sales_Order__r.Credit_Hold__c', 'Sales_Order__r.Override_Credit_Hold__c', 'Sales_Order__r.Currency__c', 'Sales_Order__r.Currency__r.ISO_Code__c',
            'Sales_Order__r.Ship_From_Location__c', 'Sales_Order__r.Ship_From_Location__r.Facility__c', 'Sales_Order__r.Ship_From_Location__r.Facility__r.Shipping_Calendar__c',
            'Sales_Order__r.Ship_From_Location__r.Facility__r.Lead_Time__c' ,'Sales_Order__r.Company__r.Auto_Create_BTO_WOs__c' };

        Set<String> solAdditionalFields = new Set<String>{ 'Pricebook__r.Currency__c','Pricebook__r.Currency__r.ISO_Code__c','Dimension_UOM__r.Name','Weight_UOM__r.Name','Product__r.Item__r.Stocking_UOM__r.Name','Product__r.Item__r.Source__c',
            'Product__r.Weight_UOM__r.Name','Product__r.Dimension_UOM__r.Name','Product__r.Sales_Hierarchy__r.Path__c','Product__r.Sales_Hierarchy__r.Code__c',
            'Product__r.Product_Group__r.Hierarchy__c','Product__r.Product_Group__r.Hierarchy__r.Path__c','Product__r.Product_Group__r.Hierarchy__r.Code__c',
            'Parent_Sales_Order_Line__r.Item_Source__c','Sales_Order__r.Bill_To__r.Customer_Group__c','Sales_Order__r.Bill_To__r.Status__c', 'Sales_Order__r.Ship_From_Location__c',
            'Sales_Order__r.Customer__r.Top_Parent_Customer__c', 'Sales_Order__r.Customer__r.Top_Parent_Customer__r.Credit_Limit__c', 
            'Sales_Order__r.Customer__r.Top_Parent_Customer__r.Customer_Group__c','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Credit_Hold__c',
            'Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c','Sales_Order__r.Customer__r.Parent_Customer__r.Status__c','Sales_Order__r.Means_of_Transport__r.Name',
            'Sales_Order__r.Means_of_Transport__r.Minimum_Cube__c','Sales_Order__r.Means_of_Transport__r.Minimum_Weight__c','Sales_Order__r.Weight_UOM__r.Name',
            'Sales_Order__r.Dimension_UOM__r.Name','Selling_UOM__r.Name','Ship_From_Location__r.Facility__c','Item_Specification__r.Type__c', 'Product__r.Item_Specification__r.Active__c','Item_Specification__r.Active__c','Item_Specification__r.Default_Work_Order_Packaging_UOM__c'};

        SOQLUtil solQuery = new SOQLUtil('Sales_Order_Line__c');

        solQuery.addFields(solFieldsToQuery);
        solQuery.addFields(soFieldsToQuery);
        solQuery.addFields(solAdditionalFields);
        solQuery.addAllCustomFields(Work_Order__c.sObjectType,'Work_Order__r');
        solQuery.addAllCustomFields(Product__c.sObjectType,'Product__r');
        solQuery.addAllCustomFields(Item__c.sObjectType,'Product__r.Item__r');
        solQuery.addAllCustomFields(Customer__c.sObjectType,'Sales_Order__r.Customer__r');
        solQuery.addAllCustomFields(Customer__c.sObjectType,'Sales_Order__r.Ship_To__r');
        solQuery.addAllCustomFields(Facility__c.sObjectType,'Ship_From_Location__r.Facility__r');

        solQuery.setWhereClause('Sales_Order__c IN (\'' + String.join(new List<Id>(salesOrderIds),'\',\'') + '\') ' + 
            ' AND Status__c != \'' + SalesOrderService.SO_STATUS_CANCEL + '\' AND Status__c != \'' + SalesOrderService.SO_STATUS_CLOSED + '\' FOR UPDATE');

        SOQLUtil.ChildRelationship shlQuery = new SOQLUtil.ChildRelationship(solQuery,'Shipment_Lines__r');
        shlQuery.addFields(new Set<String>{ 'Id', 'Quantity_Planned__c', 'Shipment__c', 'Item__r.Packaging_UOM__c' });
        shlQuery.setWhereClause('Shipment__r.Status__c NOT IN (\'' + ShipmentService.SHIPMENT_STATUS_CONFIRMED + '\',\'' + ShipmentService.SHIPMENT_STATUS_DELIVERED + '\') ' + 
            ' AND Shipment__r.Customer__r.Aggregate_Shipments__c = false ');
        solQuery.addChildRelationship(shlQuery);

        SOQLUtil.ChildRelationship reqQuery = new SOQLUtil.ChildRelationship(solQuery,'Requisition_Lines__r');
        reqQuery.addFields(new Set<String>{ 'Id','Requisition__c','Sales_Order_Line__c','Requisition__r.Name', 'Requisition__r.Source__c', 'Requisition__r.Type__c','Requisition__r.Currency__c','Quantity_Ordered__c', 'Status__c' });
        solQuery.addChildRelationship(reqQuery);

        SOQLUtil.ChildRelationship excepQuery = new SOQLUtil.ChildRelationship(solQuery,'Tasks');
        excepQuery.addFields(new set<string>{
            'Id','Exception_Code__c','WhatId', 'Status', 'Subject', 'Type', 'Description'
        });
        excepQuery.setWhereClause('Status IN (\'' + TaskType.EXCEPTION_STATUS_OVERRIDDEN + '\', \'' + TaskType.EXCEPTION_STATUS_OPEN + '\')  AND Type = \'Exception\'');
        solQuery.addChildRelationship(excepQuery);

        soLines = Database.query(solQuery.getQuery());

        return soLines;

    }

    private static Map<Id, List<Task>> getSOExistingExceptions(Set<Id> soIds){

        Map<Id, List<Task>> soToExceptionsMap = new Map<Id, List<Task>>();

        SOQLUtil soql = new SOQLUtil('Task', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Exception_Code__c','WhatId', 'Status', 'Subject', 'Type', 'Description'
        });
        soql.setWhereClause('WhatId IN :soIds AND Status IN (\'' + TaskType.EXCEPTION_STATUS_OVERRIDDEN + '\', \'' + TaskType.EXCEPTION_STATUS_OPEN + '\') AND Type = \'Exception\'');

        List<Task> exceptions = Database.query(soql.getQuery());
        
        for(Task excep: exceptions) {
            if(!soToExceptionsMap.containsKey(excep.WhatId)){
                soToExceptionsMap.put(excep.WhatId, new List<Task> { excep });
            } else {
                soToExceptionsMap.get(excep.WhatId).add(excep);
            }
        }
        return soToExceptionsMap;
    }
    /**
     *	validateSORequiredDate method validates a Sales Order for any exceptions related to 
     *	required date.
     *	@param ExceptionService exService
     *	@param Sales_Order__c so
     *	@return ExceptionService
     */
	/*
    private static ExceptionService validateSORequiredDate(ExceptionService exService, Sales_Order__c salesOrder){
    	// The required date for this customer as entered on the sales order.
        Date requestedDeliveryDate = salesOrder.Required_Date__c;
    
        if(SalesOrderService.STANDARD_ORDER_TYPES.contains(salesOrder.Type__c) 
            &&  requestedDeliveryDate != null
        ){
          
            // Calculate the estimated shipment date based on the requested delivery date and transit time
            // (Estimated Shipment Date = requested Delivery Date (minus) Transit Time) 

            //Transit_Route__c route = routesMap.get(getTransitKey(sols[0]));
            Transit_Route__c route = null;      
            String facilityCalendarId = salesOrder.Ship_From_Location__r.Facility__r.Shipping_Calendar__c;
            String customerCalendarId = salesOrder.Ship_To__r.Business_Hours__c;
            String transitCalendarId;
            String shippingCalendarId;
            
            // Calculate the estimated shipment date such that the order reaches the customer 
            // on the requested delivery date as requested by the customer.
            Integer transitTimeRequired;
                  
            if(route != null && route.Shipping_Calendar__c != null){
                transitCalendarId = route.Shipping_Calendar__c; 
            }
            else{
                transitCalendarId = '';
            }
                    
            transitTimeRequired = route != null ? Integer.valueOf(route.Transit_Time__c) : 0;
	
			// Find the next business day that the facility can ship if an order is made today
			// i.e., today + facility lead time + customer lead time
			Integer facilityLeadTime = salesOrder.Ship_From_Location__r.Facility__r.Lead_Time__c != null ? salesOrder.Ship_From_Location__r.Facility__r.Lead_Time__c.intValue() : 0;
			
            Integer customerLeadTime = salesOrder.Ship_To__r.Lead_Time__c != null ? salesOrder.Ship_To__r.Lead_Time__c.intValue() : 0;
                
            Integer shippingLeadTime = customerLeadTime > facilityLeadTime ? customerLeadTime : facilityLeadTime;
                
            
            if(!String.isBlank(transitCalendarId)){               
              shippingCalendarId = transitCalendarId; 
            }
            else{
              shippingCalendarId = facilityCalendarId;              
            }
	
			Decimal val = null;
			
            Date nextFacilityShipmentDate = KSE.calculateEndDate(system.today(), shippingLeadTime, shippingCalendarId);             
                  
            // Find the latest delivery date that is accepted by the customer to receive the delivery
            // i.e., planned delivery date + latest delivery window.
            Integer latestDeliveryWindow = salesOrder.Ship_To__r.Latest_Delivery_Window__c != null ? 
                            Integer.valueOf(salesOrder.Ship_To__r.Latest_Delivery_Window__c) : 0;
                            
            Date latestDeliveryDate = KSE.nextBusinessDate(requestedDeliveryDate, latestDeliveryWindow, customerCalendarId);

            // Find the earliest delivery date that is accepted by the customer to receive the delivery
            // i.e., planned delivery date - earliest delivery window.
            Integer earliestDeliveryWindow = salesOrder.Ship_To__r.Earliest_Delivery_Window__c != null ? 
                            Integer.valueOf(salesOrder.Ship_To__r.Earliest_Delivery_Window__c) : 0;
                              
            Date earliestDeliveryDate = KSE.previousBusinessDate(requestedDeliveryDate, earliestDeliveryWindow, customerCalendarId);
                                    
            Date estimatedShipmentDate = KSE.previousBusinessDate(requestedDeliveryDate, transitTimeRequired, shippingCalendarId);
                    
            // If the estimated shipment date is on or after the next facility shipment date
            // then the estimated shipment date is valid.
			System.debug( logginglevel.error, '~*~ estimatedShipmentDate :' + estimatedShipmentDate );
			System.debug( logginglevel.error, '~*~ nextFacilityShipmentDate :' + nextFacilityShipmentDate );
            if(estimatedShipmentDate >= nextFacilityShipmentDate){
                exService.clearException(salesOrder, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
            }
            // If the estimated shipment date is before the next facility shipment date
            // then check if the next facility shipment date gives enough time to ship by the 
            // latest delivery date atleast.
            else{
                Date estimatedDeliveryDate = KSE.nextBusinessDate(nextFacilityShipmentDate, transitTimeRequired, customerCalendarId);

                // If the shipment can be delivered by the latest delivery date,
                // then the next facility shipment date is good for estimated shipment date.
                if(estimatedDeliveryDate <= latestDeliveryDate){
                    exService.clearException(salesOrder, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP); 
                }else{
                    // Else, if the shipment cannot be delivered within the window,
                    // reject the planned delivery date.
                    exService.setException(salesOrder, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
                    //continue;
                }
            }
        } else {
            exService.clearException(salesOrder, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
        }

        return exService;
    }
	*/
	
	private static ExceptionService validateSOLRequiredDate(ExceptionService exService, Sales_Order_Line__c soLine){
		// The required date for this customer as entered on the sales order.
		Date requestedDeliveryDate = soLine.Required_Date__c;
		
		if(SalesOrderService.STANDARD_ORDER_TYPES.contains(soLine.Sales_Order__r.Type__c) &&  requestedDeliveryDate != null ){
			
			// Calculate the estimated shipment date based on the requested delivery date and transit time
			// (Estimated Shipment Date = requested Delivery Date (minus) Transit Time)
			
			//Transit_Route__c route = routesMap.get(getTransitKey(sols[0]));
			Transit_Route__c route = null;
			String facilityCalendarId = soLine.Ship_From_Location__r.Facility__r.Shipping_Calendar__c;
			String customerCalendarId = soLine.Sales_Order__r.Ship_To__r.Business_Hours__c;
			String transitCalendarId;
			String shippingCalendarId;
			
			// Calculate the estimated shipment date such that the order reaches the customer
			// on the requested delivery date as requested by the customer.
			Integer transitTimeRequired;
			
			if(route != null && route.Shipping_Calendar__c != null){
				transitCalendarId = route.Shipping_Calendar__c;
			}
			else{
				transitCalendarId = '';
			}
			
			transitTimeRequired = route != null ? Integer.valueOf(route.Transit_Time__c) : 0;
			
			// Find the next business day that the facility can ship if an order is made today
			// i.e., today + facility lead time + customer lead time
			Integer facilityLeadTime = soLine.Ship_From_Location__r.Facility__r.Lead_Time__c != null ? soLine.Ship_From_Location__r.Facility__r.Lead_Time__c.intValue() : 0;
			
			Integer customerLeadTime = soLine.Sales_Order__r.Ship_To__r.Lead_Time__c != null ? soLine.Sales_Order__r.Ship_To__r.Lead_Time__c.intValue() : 0;
			
			Integer shippingLeadTime = customerLeadTime > facilityLeadTime ? customerLeadTime : facilityLeadTime;
			
			
			if(!String.isBlank(transitCalendarId)){
				shippingCalendarId = transitCalendarId;
			}
			else{
				shippingCalendarId = facilityCalendarId;
			}
			
			Decimal val = null;
			
			Date nextFacilityShipmentDate = KSE.calculateEndDate(system.today(), shippingLeadTime, shippingCalendarId);
			
			// Find the latest delivery date that is accepted by the customer to receive the delivery
			// i.e., planned delivery date + latest delivery window.
			Integer latestDeliveryWindow = soLine.Sales_Order__r.Ship_To__r.Latest_Delivery_Window__c != null ?
					Integer.valueOf(soLine.Sales_Order__r.Ship_To__r.Latest_Delivery_Window__c) : 0;
			
			Date latestDeliveryDate = KSE.nextBusinessDate(requestedDeliveryDate, latestDeliveryWindow, customerCalendarId);
			
			// Find the earliest delivery date that is accepted by the customer to receive the delivery
			// i.e., planned delivery date - earliest delivery window.
			Integer earliestDeliveryWindow = soLine.Sales_Order__r.Ship_To__r.Earliest_Delivery_Window__c != null ?
					Integer.valueOf(soLine.Sales_Order__r.Ship_To__r.Earliest_Delivery_Window__c) : 0;
			
			Date earliestDeliveryDate = KSE.previousBusinessDate(requestedDeliveryDate, earliestDeliveryWindow, customerCalendarId);
			
			Date estimatedShipmentDate = KSE.previousBusinessDate(requestedDeliveryDate, transitTimeRequired, shippingCalendarId);
			
			// If the estimated shipment date is on or after the next facility shipment date
			// then the estimated shipment date is valid.
			if(estimatedShipmentDate >= nextFacilityShipmentDate){
				exService.clearException(soLine, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
			}
			// If the estimated shipment date is before the next facility shipment date
			// then check if the next facility shipment date gives enough time to ship by the
			// latest delivery date atleast.
			else{
				Date estimatedDeliveryDate = KSE.nextBusinessDate(nextFacilityShipmentDate, transitTimeRequired, customerCalendarId);
				
				// If the shipment can be delivered by the latest delivery date,
				// then the next facility shipment date is good for estimated shipment date.
				if(estimatedDeliveryDate <= latestDeliveryDate){
					exService.clearException(soLine, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
				}else{
					// Else, if the shipment cannot be delivered within the window,
					// reject the planned delivery date.
					exService.setException(soLine, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
					//continue;
				}
			}
		} else {
			exService.clearException(soLine, ExceptionUtil.NOT_ENOUGH_LEAD_TIME_TO_SHIP);
		}
		
		return exService;
	}
    /**
     *	validateSalesOrder method validates a Sales Order for any exceptions and applies the exceptions
     *	appropriately.
     *	@param ExceptionService exService
     *	@param Sales_Order__c so
     *	@return ExceptionService
     */
    private static ExceptionService validateSalesOrder(ExceptionService exService, Sales_Order__c salesOrder){

        if(salesOrder == null){
            return exService;
        }       

        if(salesOrder.Customer__c == null){

            exService.setException(salesOrder, ExceptionUtil.SO_CUSTOMER_MISSING);
            
        } else {
            exService.clearException(salesOrder, ExceptionUtil.SO_CUSTOMER_MISSING);
        }

        if(salesOrder.Payment_Term__c == null){
            exService.setException(salesOrder, ExceptionUtil.SO_NO_PAYMENT_TERM_SELECTED);
        } else {
            exService.clearException(salesOrder, ExceptionUtil.SO_NO_PAYMENT_TERM_SELECTED);
        }

        if(salesOrder.Customer__r.Top_Parent_Customer__r.Status__c != 'Approved'){
            exService.setException(salesOrder, ExceptionUtil.SO_CUSTOMER_NOT_APPROVED);
        } else {
            exService.clearException(salesOrder, ExceptionUtil.SO_CUSTOMER_NOT_APPROVED);
        }
      
        if (salesOrder.Customer__r.Status__c != 'Approved') {   
            exService.setException(salesOrder, ExceptionUtil.SO_SOLD_TO_CUSTOMER_NOT_APPROVED);
        } else { 
            exService.clearException(salesOrder, ExceptionUtil.SO_SOLD_TO_CUSTOMER_NOT_APPROVED);
        }

        if (salesOrder.bill_to__r.Status__c != 'Approved') {
            exService.setException(salesOrder, ExceptionUtil.SO_BILL_TO_CUSTOMER_NOT_APPROVED);
        } else {
            exService.clearException(salesOrder, ExceptionUtil.SO_BILL_TO_CUSTOMER_NOT_APPROVED);
        }

        if (salesOrder.Ship_to__r.Status__c != 'Approved') {
            exService.setException(salesOrder, ExceptionUtil.SO_SHIP_TO_CUSTOMER_NOT_APPROVED);
        } else {
            exService.clearException(salesOrder, ExceptionUtil.SO_SHIP_TO_CUSTOMER_NOT_APPROVED);
        }


        if(salesorder != null && salesorder.Hold__c == true){
            exService.setException(salesOrder, ExceptionUtil.SO_ON_HOLD);
        }else{
            exService.clearException(salesOrder, ExceptionUtil.SO_ON_HOLD);
        }
          
        // Validate that sales order can be planned
        if( salesOrder.Status__c == SalesOrderService.SO_STATUS_CLOSED || 
            salesOrder.Status__c == SalesOrderService.SO_STATUS_CANCEL || 
            salesOrder.Status__c == SalesOrderService.SO_STATUS_HOLD ) 
        {
            exService.setException(salesOrder, ExceptionUtil.SO_PLAN_INVALID_STATUS);
        }else{
            exService.clearException(salesOrder, ExceptionUtil.SO_PLAN_INVALID_STATUS);
        }

        if (salesOrder.Exceeds_Max_Weight__c ) {
            exService.setException(salesOrder, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION);
        } else {
            exService.clearException(salesOrder, ExceptionUtil.SO_OVER_WEIGHT_EXCEPTION);
        }
        
//        exService = validateSORequiredDate(exService, salesOrder);

        if ((salesOrder.Customer__r.Top_Parent_Customer__r.Credit_Hold__c || 
            new CreditProfile().willOrderExceedCreditLimits(salesOrder))
            && !salesOrder.Override_Credit_Hold__c) {
            salesOrder.Credit_Hold__c = true;
            exService.setException(salesOrder, ExceptionUtil.SO_CREDIT_LIMIT_EXCEEDED);
        } else {
            salesOrder.Credit_Hold__c = false;
            exService.clearException(salesOrder, ExceptionUtil.SO_CREDIT_LIMIT_EXCEEDED);
        } 
        
        return exService;
    }

    /**
     *	validateSalesOrder method validates a Sales Order for any exceptions and applies the exceptions
     *	appropriately.
     *	@param ExceptionService exService
     *	@param Sales_Order_Line__c sol
     *	@return ExceptionService
     */
    private static ExceptionService validateSalesOrderLine(ExceptionService exService, Sales_Order_Line__c sol){

        if (sol == null){
            return exService;
        }

        if (!sol.Product__r.Item__r.Active__c){
            exService.setException(sol, ExceptionUtil.ITEM_NOT_ACTIVE);
        } else {
            exService.clearException(sol, ExceptionUtil.ITEM_NOT_ACTIVE);
        }

        if ((sol.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_KIT ||
            sol.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_MAKE_TO_ORDER ||
            sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER) 
            && sol.Item_Specification__c == null){
            exService.setException(sol, ExceptionUtil.SOL_MISSING_ITEM_SPECIFICATION);
        } else {
            exService.clearException(sol, ExceptionUtil.SOL_MISSING_ITEM_SPECIFICATION);
        }

        // KNDY-20068
        if ((sol.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_KIT ||
                sol.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_MAKE_TO_ORDER ||
                sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER)
                && sol.Item_Specification__c != null && sol.Item_Specification__r.Active__c == false){
            exService.setException(sol, ExceptionUtil.SOL_INACTIVE_ITEM_SPECIFICATION);
        } else {
            exService.clearException(sol, ExceptionUtil.SOL_INACTIVE_ITEM_SPECIFICATION);
        }
    
        if (sol.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_REPAIR && sol.Parent_Sales_Order_Line__c == null && sol.Item_Specification__c != null && sol.Item_Specification__r.Type__c != 'Repair') {
            exService.setException(sol,ExceptionUtil.SOL_ITEM_SPEC_NOT_REPAIR);
        } else {
            exService.clearException(sol,ExceptionUtil.SOL_ITEM_SPEC_NOT_REPAIR);
        }
        
        if(sol.Type__c != SalesOrderLineService.SO_LINE_TYPE_KIT_CHILD){ //Only check pricebook information if type is not a Kit

            if (sol.Unit_Price__c == null) {

                exService.setException(sol, ExceptionUtil.SOL_MISSING_PRICE);
            } else {
                exService.clearException(sol, ExceptionUtil.SOL_MISSING_PRICE);
            }

            if (sol.Pricebook__c != null && sol.Pricebook__r.Currency__r.ISO_Code__c != sol.Currency__c){

                exService.setException(sol, ExceptionUtil.SOL_MISMATCH_TRANSACTION_CURRENCY);
            } else {
                exService.clearException(sol, ExceptionUtil.SOL_MISMATCH_TRANSACTION_CURRENCY);
            }
        }

        if(sol.Ship_From_Location__c == null){

            if (SalesOrderService.SO_RMA_TYPES.contains(sol.Sales_Order__r.Type__c)  ) {
                
                exService.setException(sol,ExceptionUtil.SOL_MISSING_RECEIVING_LOCATION);//Need to add Shipping/Receiving Location
            } else {

                exService.setException(sol, ExceptionUtil.SOL_MISSING_SHIP_FROM_LOCATION);
            }
        } else {
            exService.clearException(sol,ExceptionUtil.SOL_MISSING_RECEIVING_LOCATION);
            exService.clearException(sol, ExceptionUtil.SOL_MISSING_SHIP_FROM_LOCATION);
        }

        if((sol.Quantity_Ordered__c <= 0 || sol.Quantity_Ordered__c == null) 
          && SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(sol.Sales_Order__r.Type__c) == false 
          && SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(sol.Sales_Order__r.Type__c) == false ){ 

            exService.setException(sol, ExceptionUtil.SOL_INVALID_ORDER_QUANTITY);
        } else {
            exService.clearException(sol, ExceptionUtil.SOL_INVALID_ORDER_QUANTITY);
        }

        if(sol.Product__c == null){

            exService.setException(sol, ExceptionUtil.SOL_MISSING_PRODUCT);
        } else {
            exService.clearException(sol, ExceptionUtil.SOL_MISSING_PRODUCT);
        }
        
        if(sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP 
           || sol.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_MAKE_TO_ORDER 
           || sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER 
           || sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK ){ //KNDY-13447

            if (sol.Required_Date__c == null) {

                if(sol.Product__r.Item__r.Lead_Time__c == null 
                   || sol.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_MAKE_TO_ORDER 
                   || sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER){

                    exService.setException(SOL, ExceptionUtil.SOL_REQUIRED_DATE_MISSING);
                } else { // Item Lead Time exists
                    exService.clearException(sol, ExceptionUtil.SOL_REQUIRED_DATE_MISSING);
                } 
            } else {
                exService.clearException(sol, ExceptionUtil.SOL_REQUIRED_DATE_MISSING);
            }
        }
	
		if (sol.Status__c == SalesOrderLineService.SO_LINE_STATUS_DRAFT) {
			exService = validateSOLRequiredDate(exService, sol);
		}

        return exService;
    }

    /**
     *  soLinesToMap converts a list of Sales Order Lines to Map of Sales Order Id to So Lines
     *  @param List<Sales_Order_Line__c> soLines
     *  @return Map<Id, List<Sales_Order_Line__c>> (SO id :-> List of SO Lines)
     **/
    private static Map<Id, List<Sales_Order_Line__c>> getSoToSoLinesMap(List<Sales_Order_Line__c> soLines){

        Map<Id, List<Sales_Order_Line__c>> soToSoLineMap = new Map<Id, List<Sales_Order_Line__c>>();

        for(Sales_Order_Line__c soLine: soLines) {
            if(soToSoLineMap.containsKey(soLine.Sales_Order__c)){
                soToSoLineMap.get(soLine.Sales_Order__c).add(soLine);
            } else{
                soToSoLineMap.put(soLine.Sales_Order__c, new List<Sales_Order_Line__c>{soLine});
            }
        }

        return soToSoLineMap;
    }

    /**
     * 	getExistingShipFromLocToShipmentMap method converts a list of SO Lines to a map of 
     * 	ship from location to shipment.
     *	@param List<Sales_Order_Line__c> soLines
     *	@return Map<Id, Shipment__c> Ship From Location to Shipment object
     */
    private static Map<Id, Shipment__c> getExistingShipFromLocToShipmentMap(List<Sales_Order_Line__c> soLines){

        Map<Id, Shipment__c> shLocToShipment = new Map<Id, Shipment__c>();

        for(Sales_Order_Line__c soLine: soLines) {
            
            if(soLine.Shipment_Lines__r.size() > 0){
                shLocToShipment.put(soLine.Ship_From_Location__c, soLine.Shipment_Lines__r[0].Shipment__r);
            }
        }

        return shLocToShipment;
    }

    /**
     * 	createShipment method initializes shipment to be created or updated.
     *	@param Sales_Order__c so
     *	@param Location__c shipFromLoc
     *	@param Shipment__c existingShipment
     *	@return Shipment__c Shipment object
     */
    private static Shipment__c createShipment(Sales_Order__c so,
											  Date needDate,
                                              Location__c shipFromLoc,
                                              Shipment__c existingShipment){

        Shipment__c shipment = new Shipment__c();

        if(existingShipment != null){

            shipment.Id = existingShipment.Id;

        } else {

            shipment.Shipping_Method__c = so.Ship_To__r.Preferred_Shipping_Method__c;
            shipment.Company__c = so.Company__c;
            shipment.Customer__c = so.Ship_To__c;
            shipment.Ship_to_Street__c = so.Ship_to_Street__c;
            shipment.Ship_to_City__c = so.Ship_to_City__c;
            shipment.Ship_to_State__c = so.Ship_to_State__c;
            shipment.Ship_to_Zip_Code__c = so.Ship_to_Zip_Code__c;
            shipment.Ship_to_Country__c = so.Ship_to_Country__c;
            shipment.Means_of_Transport__c = so.Means_of_Transport__c; // KNDY-1504   
            shipment.Weight_UOM__c = so.Weight_UOM__c;
            shipment.Planned_Delivery_Date__c = needDate;
            shipment.Ship_From_Facility__c = shipFromLoc.Facility__c;
            shipment.Ship_From_Location__c = shipFromLoc.Id;                       
            shipment.Status__c = ShipmentService.SHIPMENT_STATUS_PLANNED;
            shipment.Type__c = ShipmentService.SHIPMENT_TYPE_SALES_ORDER;
            shipment.Transaction_Type__c = ShipmentService.SHIPMENT_TRANSACTION_TYPE_SALES_ORDER_SHIPMENT;
            shipment.Currency__c = so.Currency__c;
        }
        return shipment;
    }

    /**
     *	createShipmentLine method initializes shipment line to be created or updated.
     *	@param Sales_Order_Line__c sol
     *	@param Shipment__c shipment
     *	@return Shipment_Line__c
     *
     */
    public static Shipment_Line__c createShipmentLine(Sales_Order_Line__c sol, Shipment__c shipment){
    
        Shipment_Line__c shLine = new Shipment_Line__c();

        if (sol.Parent_Sales_Order_Line__c != null ){
            shLine.Parent_Sales_Order_Line__c   = sol.Parent_Sales_Order_Line__c;
        }

        //OTC-18: Update existing line, if found.
        if(sol.Shipment_Lines__r.size() > 0){
            shLine = sol.Shipment_Lines__r[0];
        }

        shLine.Company__c = sol.Company__c;
        shLine.Description__c = sol.Description__c;
        shLine.Discount_Percent__c = sol.Discount_Percent__c;
        shLine.Work_Order__c = sol.Work_Order__c;
        shLine.Facility__c = sol.Ship_From_Location__r.Facility__c;
        shLine.Location__c = sol.Ship_From_Location__c;
        shLine.Product__c = sol.Product__c;
        shLine.Item__c = sol.Product__r.Item__c;
        shLine.Item__r = sol.Product__r.Item__r;
        shLine.Quantity_Planned__c = KSE.subtractDecimals(sol.Quantity_Ordered__c, sol.Quantity_Shipped__c);
        // Copy Total Weight from Sales Order Line : KNDY-2634
        shLine.Planned_Weight__c = sol.Weight__c;  //KNDY 3621 UOM Conversion.Changed the field from total_weight__c to weight__c.
        shLine.Quantity_Shipped__c = 0.0; //OTC-351
        shLine.Line_Type__c = sol.Line_Type__c; //OTC-688
        shLine.Quantity_From_Stock__c = 0.0;
        shLine.Sales_Order__c = sol.Sales_Order__c;
        shLine.Sales_Order_Line__c = sol.Id;
        shLine.Shipment__c  = shipment.Id;
        shLine.Unit_Price__c = sol.Unit_Price__c;
        shLine.Weight_UOM__c = sol.Weight_UOM__c;
        shLine.Extended_Cost__c = 0;
		shLine.Need_Date__c = sol.required_Date__c;
		
		Id facilityCal = sol.Ship_From_Location__r.Facility__r.Shipping_Calendar__c;
		System.debug( logginglevel.error, '*** shLine need date :' + shLine.Need_Date__c );
		if (shLine.Need_Date__c != null) {
			shLine.Estimated_ship_date__c = KSE.calculateStartDate(shLine.Need_Date__c, 0, facilityCal);
		}
		else{
			// No Need Date specified
			Decimal facilityLeadTime = sol.Ship_From_Location__r.Facility__r.Lead_time__c != null ? sol.Ship_From_Location__r.Facility__r.Lead_time__c: 0 ;
			Decimal customerLeadTime = sol.Sales_Order__r.Ship_To__r.Lead_time__c != null ? sol.Sales_Order__r.Ship_To__r.Lead_time__c : 0;
			Integer largerPrepTime = customerLeadTime > facilityLeadTime ? (Integer) customerLeadTime : (Integer) facilityLeadTime;
		
			// will retrieve today's date if facility and lead time is null. If calendar isn't null, it'll use the upcoming non-holiday date
			shLine.Estimated_ship_date__c = KSE.calculateEndDate(system.today(), largerPrepTime, facilityCal);
		}
	
		System.debug( logginglevel.error, '*** shl EST SHP Date :' + shLine.Estimated_Ship_Date__c );

        return shLine;
    }

    /**
     *	updateSOForRelease method updates Sales Order to be updated as part 
     *	of the release process
     *	@param Sales_Order__c so
     *	@return Sales_Order__c
     *
     */
    private static Sales_Order__c updateSOForRelease(Sales_Order__c so){

    	
        Sales_Order__c salesOrder = new Sales_Order__c();
        
    	//Update credit hold
    	if(ExceptionService.hasOpenTask(so.Id, ExceptionUtil.SO_CREDIT_LIMIT_EXCEEDED.code)){
    		salesOrder.Credit_Hold__c = true;
    	} else {
            if(so.Credit_Hold__c){
                salesOrder.Credit_Hold__c = false;
            }
    	}

        if(salesOrder != new Sales_Order__c()){
            salesOrder.Id = so.Id;
        }

    	return salesOrder;

    }
    /**
     *	updateSOLForRelease method updates the Sales Order lines to be updated as part 
     *	of the release process
     *	@param Sales_Order_Line__c sol
     *	@return Sales_Order_Line__c
     *
     */
    private static Sales_Order_Line__c updateSOLForRelease(Sales_Order_Line__c sol){

        if(sol.Status__c == SalesOrderService.SO_STATUS_DRAFT){    
            sol.Status__c = SalesOrderService.SO_STATUS_OPEN;
            sol.Original_Quantity_Ordered__c = sol.Quantity_Ordered__c; // OTC-18 : Change original quantity only when the order is released the first time.
        }
        if(sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP) {
            if(sol.Quantity_Planned__c != null ){
                if(sol.Quantity_Ordered__c > sol.Quantity_Planned__c){
                    sol.Quantity_Planned__c = sol.Quantity_Planned__c + (sol.Quantity_Ordered__c - sol.Quantity_Planned__c);
                }else sol.Quantity_Planned__c = sol.Quantity_Ordered__c;
                
            }else sol.Quantity_Planned__c = sol.Quantity_Ordered__c;
        }

        // If the validations are passed, then we have some work to do.
        // KNDY-3621: Calculating Weight & Volume using UOM Conversion factor.                   
        if(sol.Sales_Order__r.Weight_UOM__c != sol.Weight_UOM__c && sol.Sales_Order__r.Weight_UOM__c != null ){                                       
            sol.Weight_UOM__c = sol.Sales_Order__r.Weight_UOM__c; 
            sol.Weight_UOM__r = sol.Sales_Order__r.Weight_UOM__r; 
        }

        if(sol.Sales_Order__r.Dimension_UOM__c != sol.Dimension_UOM__c && sol.Sales_Order__r.Dimension_UOM__c != null){                     
            sol.Dimension_UOM__c = sol.Sales_Order__r.Dimension_UOM__c;
            sol.Dimension_UOM__r = sol.Sales_Order__r.Dimension_UOM__r; 
        }

        if(sol.Product__r.Weight__c != null && sol.Quantity_Ordered__c != null){
            sol.Weight__c = (sol.Product__r.Weight__c * sol.Quantity_Ordered__c * KSE.getSOConversionFactor(sol, 'weight')).setscale(6,System.RoundingMode.HALF_UP);
        }

        if(sol.Quantity_Ordered__c != null && sol.Product__r.Width__c !=null && sol.Product__r.Length__c !=null && sol.Product__r.Height__c !=null){
            sol.Volume__c = ((sol.Product__r.Width__c * sol.Product__r.Length__c * sol.Product__r.Height__c * sol.Quantity_Ordered__c) * (KSE.getSOConversionFactor(sol, 'dimension'))).setscale(6,System.RoundingMode.HALF_UP);
        }                             

        // update non shippable flag on SOL on release if it's been changed
        if ((sol.Sales_Order__r.Type__c != SalesOrderService.SO_TYPE_REPAIR || (sol.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_REPAIR && sol.Related_Sales_Order_Line__c==null)) && sol.Non_Shippable__c != sol.Product__r.Item__r.Non_Shippable__c ){
            sol.Non_Shippable__c = sol.Product__r.Item__r.Non_Shippable__c;
        }

        return sol;
    }
    public static Map<Id, Sales_Order_Line__c> createRequisitions(Map<id, List<Sales_Order_Line__c>> soToSOLines) {
        // Keeps the 1:1 relationship for updating the SOL Requisition with RQL Ids
        Map<Sales_Order_Line__c, Requisition_Line__c> solToRequisitionMap = new Map<Sales_Order_Line__c, Requisition_Line__c>();
        Map<Sales_Order_Line__c, List<Requisition_Line__c>> solToRqlsMap = new Map<Sales_Order_Line__c, List<Requisition_Line__c>>();
        Map<id, List<Requisition_Line__c>> solIdToRqlsMap = new Map<id, List<Requisition_Line__c>>();
        Map<String, Requisition__c> requisitionMap = new Map<String, Requisition__c>();
        Map<String,List<Requisition_Line__c>> rqlMap = new Map<String,List<Requisition_Line__c>>();
        List<Requisition_Line__c> requisitionLinesToUpsert = new List<Requisition_Line__c>();

        Map<Requisition__c, List<Requisition_Line__c>> reqToReqLineMap = new Map<Requisition__c, List<Requisition_Line__c>> ();

        Map<Id, Sales_Order_Line__c> solsToUpdate = new Map<Id, Sales_Order_Line__c>();

        for(Id soId : soToSOLines.keySet()) {

            List<Sales_Order_Line__c> salesOrderLines = soToSOLines.get(soId);

            for(Sales_Order_Line__c sol : salesOrderLines) {

              if( (sol.Fulfillment_Source__c == 'Drop Ship' && sol.Quantity_ordered__c != sol.Quantity_Planned__c ) || sol.Fulfillment_Source__c == 'Back to Back' ){
                   reqToReqLineMap = createReqLine(sol, reqToReqLineMap);
                }
                               
               	if(!reqToReqLineMap.isEmpty()){
                    solsToUpdate.put(sol.id, SalesOrderReleaseService.updateSOLForRelease(sol));
                }
            } 
        }      
           
        if (reqToReqLineMap.size() > 0){
            Savepoint sp = Database.setSavepoint();

            try{
                Map<Requisition__c, Requisition__c> rqMap = new Map<Requisition__c, Requisition__c>();
                for(Requisition__c rq : reqToReqLineMap.keyset()){
                    if(rq.id == null){
                        Requisition__c cloneRq = rq.clone(false, true);
                        rqMap.put(rq, cloneRq);    
                    }
                }

                DML.checkUpsertAsUser(rqMap.values() ); upsert rqMap.values();

                for(Requisition__c rq : reqToReqLineMap.keyset()){
                    for(Requisition_Line__c rql: reqToReqLineMap.get(rq)){
                        if(rql.Requisition__c == null){
                            rql.Requisition__c = rqMap.get(rq).Id;    
                        }
                        
                        requisitionLinesToUpsert.add(RQL);
                    } 
                }
                system.debug(logginglevel.info, 'requisitionLinesToUpsert ' + requisitionLinesToUpsert);
                DML.checkUpsertAsUser(requisitionLinesToUpsert); upsert requisitionLinesToUpsert;

            } catch(Exception e) {
                Database.rollback(sp);
                
                System.debug(loggingLevel.Error, '*** e.getMessage(): ' + e.getMessage()+e.getStackTraceString());
                throw e;
            } 
        }
        return solsToUpdate;
    }
    public static  Map<Requisition__c,List<Requisition_Line__c>> createReqLine (Sales_Order_Line__c sol, Map<Requisition__c, List<Requisition_Line__c>> reqToReqLineMap){   //
        Map<Sales_Order_Line__c, Requisition_Line__c> solToOpenRequisitionMap = new Map<Sales_Order_Line__c, Requisition_Line__c>();
        Map<Sales_Order_Line__c, List<Requisition_Line__c>> solToRqlsMap = new Map<Sales_Order_Line__c, List<Requisition_Line__c>>();
        
		 Decimal i = 0;
//RERELEASE SO
        if(sol.Requisition_Lines__r .size() >0) {
            reqToReqLineMap = createReqReqlineMap( sol, reqToReqLineMap);        

        }else{
            system.debug(logginglevel.info,'****create new req reqlines**');
            reqToReqLineMap = createNewReqReqLine( sol, reqToReqLineMap, i );
             
        }

        return reqToReqLineMap;
           
  
    }
    public static Map<Requisition__c, List<Requisition_Line__c>> createNewReqReqLine(Sales_Order_Line__c sol, Map<Requisition__c, List<Requisition_Line__c>> reqToReqLineMap, Decimal i ) {
    	Requisition__c RQ = new Requisition__c();
        Requisition_Line__c RQL = new Requisition_Line__c();
         
            RQ.Approval_Status__c = RequisitionService.RQ_APPROVAL_STATUS_APPROVED;
            RQ.Company__c = SOL.Company__c;
            RQ.Delivery_Facility__c = SOL.Ship_From_Location__r.Facility__c;
            RQ.Requester__c = UserInfo.getUserId();
            RQ.Sales_Order__c = SOL.Sales_Order__c;
            RQ.Ship_To_Customer__c = SOL.Sales_Order__r.Ship_To__c;
            if (SOL.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP){
            RQ.Source__c = RequisitionService.RQ_SOURCE_DROPSHIP;
            }else if (SOL.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK){
              RQ.Source__c = RequisitionService.RQ_SOURCE_BACKTOBACK;
            }
            RQ.Status__c = RequisitionService.RQ_STATUS_OPEN;
            RQ.Transaction_Date__c = System.today();
            RQ.Type__c = RequisitionService.RQ_TYPE_PURCHASE_REQUISITION; 
            RQ.Currency__c = SOL.Sales_Order__r.Currency__c;
            RQL.Approved__c = true;
            RQL.Item__c = SOL.Product__r.Item__c;
            RQL.Facility__c = SOL.Ship_From_Location__r.Facility__c;
            if(sol.Quantity_Ordered__c > i) {
                RQL.Quantity_Ordered__c = sol.Quantity_Ordered__c - i;           
            }else if (sol.Quantity_Ordered__c == i){
                RQL.Quantity_Ordered__c = sol.Quantity_Ordered__c;           
            }
            RQL.Supplier__c = SOL.Purchase_From_Supplier__c;
            RQL.Sales_Order_Line__c = SOL.Id;
            RQL.Status__c = RequisitionService.RQ_STATUS_OPEN;
            RQL.Delivery_Location__c = SOL.Ship_From_Location__c;
            RQL.Purchasing_UOM__c = SOL.Selling_UOM__c;
            RQL.Need_Date__c = SOL.Required_Date__c == null ? System.today() + (Integer) SOL.Product__r.Item__r.Lead_Time__c : SOL.Required_Date__c;
            
            if (!reqToReqLineMap.containsKey(RQ)){
                reqToReqLineMap.put(RQ, new List<Requisition_Line__c>());   
            }

            reqToReqLineMap.get(RQ).add(RQL);

            return reqToReqLineMap;
    }

    public static Map<Requisition__c,List<Requisition_Line__c>> createReqReqlineMap(Sales_Order_Line__c sol, Map<Requisition__c, List<Requisition_Line__c>> reqToReqLineMap){
    
        ExceptionService exService = new ExceptionService();
        boolean  openreqLine = false;
        Decimal i = 0;
        Integer totalCancelledReqLines = 0;
        Integer totalClosedReqLines = 0;
        for(Requisition_Line__c rl : sol.Requisition_Lines__r){
                if(rl.Status__c == 'Open'){
                    openReqLine = true;

                } else if(rl.Status__c == 'Closed'){
                    i = i+rl.Quantity_Ordered__c;
                    totalClosedReqLines += 1;
                }    
                else if(rl.Status__c == 'Cancelled'){
                    totalCancelledReqLines += 1;
                }
        }

            for(Requisition_Line__c rl : sol.Requisition_Lines__r) {
                if(!openReqLine){
                    if ( totalCancelledReqLines >= 1 &&  totalClosedReqLines == 0 ){
                        createNewReqReqLine(sol, reqToReqLineMap, i); 
                        break;
                    }
                    if ( totalClosedReqLines >= 1 && totalCancelledReqLines == 0 ){
                        if(sol.Quantity_Ordered__c > i ){
                            createNewReqReqLine(sol, reqToReqLineMap, i); 
                            break;    
                        }else if (sol.Quantity_Ordered__c == i){
                            break;
                        }else {
                            ExceptionService.addMessage( MessageUtil.Severity.Error.name(), 'Order Quantity on a Sales Order Line should be more than or equal to the Purchase Order Line Quantity or closed Requisition Line Quantity, adjust the SOL Quantity and Rerelease.', ''+ sol.name );
                            break;
                        }
                    }

                     if (totalCancelledReqLines >= 1 && totalClosedReqLines >= 1 ) {
                         if( sol.Quantity_Ordered__c == sol.Quantity_Planned__c ){  
                            break;
                         }
                         if(sol.Quantity_Ordered__c > sol.Quantity_planned__c ){
                            if(sol.Quantity_Ordered__c > i ){
                                createNewReqReqLine(sol, reqToReqLineMap, i);
                                break;    
                            }else if (sol.Quantity_Ordered__c == i){
                            	break;
                        	}else{
                                ExceptionService.addMessage( MessageUtil.Severity.Error.name(), 'Order Quantity on a Sales Order Line should be more than or equal to the Purchase Order Line Quantity or closed Requisition Line Quantity, adjust the SOL Quantity and Rerelease .', ''+sol.name );
                                break;
                            }
                         }
                     
                     }

                }
            }
        
            for(Requisition_Line__c rl : sol.Requisition_Lines__r){   
                 if(rl.Status__c == 'Open' && sol.Quantity_Ordered__c != rl.Quantity_Ordered__c ){
                     rl.Quantity_Ordered__c = sol.Quantity_Ordered__c - i ;
                   if(!reqToReqLineMap.containsKey(rl.Requisition__r)){
                        reqToReqLineMap.put(rl.Requisition__r, new List<Requisition_Line__c>{rl});    
                    }
                    
                    else {
                        reqToReqLineMap.get(rl.Requisition__r).add(rl);
                    } 
                }
                
            }
   
        return reqToReqLineMap;
    }


    /**
     *  getSOLinesGroupByShipFromLocMap method conversts a list of Sales order line to a map with Key of unique 
     *  ship from locations and the corresponding Sales Order Lines.
     *  @param List<Sales_Order_Line__c> soLines
     *  @return Map<Id, List<Sales_Order_Line__c>> ship from location Id to List of Sales order lines map
     *
     */
    private static Map<Id, List<Sales_Order_Line__c>> getSOLinesGroupByShipFromLocMap(List<Sales_Order_Line__c> soLines){
        
        Map<Id, List<Sales_Order_Line__c>> result = new Map<Id, List<Sales_Order_Line__c>>();

        for(Sales_Order_Line__c soLine: soLines) {
            if(result.containsKey(soLine.Ship_From_Location__c)){
                result.get(soLine.Ship_From_Location__c).add(soLine);
            } else{
                result.put(soLine.Ship_From_Location__c, new List<Sales_Order_Line__c>{ soLine });
            }
        }

        return result;
    }

    /**
     *	createShipments method creates/update shipment and shipment lines for Sales Order Lines
     *	that are of type Inventory and Back To back
     *	@param Map<Id, List<Sales_Order_Line__c>> soToSolShipmentMap
     *	@return Map<Id, Sales_Order_Line__c>
     *
     */
    public static Map<Id, Sales_Order_Line__c> createShipments(Map<Id, List<Sales_Order_Line__c>> soToSolShipmentMap){

        Map<Id, Sales_Order_Line__c> solsToUpdate = new Map<Id, Sales_Order_Line__c>();
        Map<Id, Sales_Order_Line__c> createWorkOrderSolsMap = new Map<Id, Sales_Order_Line__c>();
        Map<Id, Shipment_Line__c> solToShlMap = new Map<Id, Shipment_Line__c>();
        Boolean shipmentsSuccess = true;

        Map<String, Shipment__c> soToShipmentsToUpsert = new Map<String, Shipment__c>();
        List<Shipment_Line__c> shLinesToUpsert = new List<Shipment_Line__c>();

        Map<Id, Map<Id, Shipment__c>> soExitingShipments = new Map<Id, Map<Id, Shipment__c>>();
        Map<Id, Map<Id, List<Sales_Order_Line__c>>> soToSoLinesGroupByShipFromLocMap = new Map<Id, Map<Id, List<Sales_Order_Line__c>>>();


        for(Id soId: soToSolShipmentMap.keySet()) {
            List<Sales_Order_Line__c> soLines = soToSolShipmentMap.get(soId);
            Sales_Order__c so = soLines[0].Sales_Order__r;

            Map<Id, List<Sales_Order_Line__c>> soLinesGroupByShipFromLocMap = SalesOrderReleaseService.getSOLinesGroupByShipFromLocMap(soLines);
            Map<Id, Shipment__c> existingShipFromLocToShipmentMap = getExistingShipFromLocToShipmentMap(soLines);

            for(Id shipFromLocId: soLinesGroupByShipFromLocMap.keySet()) {

                Location__c shipFromLoc = soLinesGroupByShipFromLocMap.get(shipFromLocId)[0].Ship_From_Location__r;

				Date needDate;
				for (Sales_Order_Line__c sol : soLinesGroupByShipFromLocMap.get(shipFromLocId)){
					if (needDate == null || sol.Required_Date__c > needDate){
						needDate = sol.Required_Date__c;
					}
				}
				
                Shipment__c shipment = createShipment(so, needDate,
                                                      shipFromLoc, 
                                                      existingShipFromLocToShipmentMap.get(shipFromLocId));


                soToShipmentsToUpsert.put(so.Id + '-' + shipFromLocId, shipment);


            }
            soToSoLinesGroupByShipFromLocMap.put(so.Id, soLinesGroupByShipFromLocMap);
            soExitingShipments.put(so.Id, existingShipFromLocToShipmentMap);
        }
        try {

            DML.checkUpsertAsUser(soToShipmentsToUpsert.values()); upsert soToShipmentsToUpsert.values();

            for(Id soId: soToSolShipmentMap.keySet()) {
                List<Sales_Order_Line__c> soLines = soToSolShipmentMap.get(soId);

                for(Sales_Order_Line__c sol: soLines) {

                    solsToUpdate.put(sol.id, updateSOLForRelease(sol));

                    if ((sol.Sales_Order__r.Company__r.Auto_Create_BTO_WOs__c == true && (sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER || sol.Product__r.Item__r.Source__c == ItemService.ITEM_SOURCE_BUILD_TO_ORDER)) || sol.Type__c == 'Repair') {
                        createWorkOrderSolsMap.put(sol.Id, sol);
                        if (sol.Shipment_Lines__r.size() > 0) solToShlMap.put(sol.Id, sol.Shipment_Lines__r[0].clone(true, true));
                    }

                    if(sol.Sales_Order__r.Ship_To__r.Aggregate_Shipments__c == true
                      || sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP
                      || sol.Non_Shippable__c
                      || sol.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA 
                      || sol.Quantity_Ordered__c < 0
                      || SalesOrderService.NO_SHIP_ADJ_ORDER_TYPES.contains(sol.Sales_order__r.Type__c)) {

                        continue;
                    }

                    Shipment_Line__c shLine = createShipmentLine(sol, soToShipmentsToUpsert.get(soId + '-' + sol.Ship_From_Location__c));
                    shLinesToUpsert.add(shLine);
                    if (createWorkOrderSolsMap.containsKey(sol.Id) == true && solToShlMap.containsKey(sol.Id) == false) solToShlMap.put(sol.Id, shLine);
                }
            }
            
            DML.checkUpsertAsUser(shLinesToUpsert); upsert shLinesToUpsert;
            //Create Work Order
            if(!createWorkOrderSolsMap.isEmpty()){
                WorkOrderService.syncWorkOrdersWithSalesOrderLines(createWorkOrderSolsMap, createWorkOrderSolsMap, solToShlMap, WorkOrderService.SaveType.SAVE);
            }
          
            Set<id> solKeys = solsToUpdate.keySet();
            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', false); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Quantity_Planned__c','Quantity_Shipped__c'
            });
            soql.setWhereClause('Id IN :solKeys');
           
           for(Sales_Order_Line__c sol : Database.query(soql.getQuery())){
                if(solsToUpdate.containsKey(sol.id)){
                    solsToUpdate.get(sol.id).Quantity_Planned__c = sol.Quantity_Planned__c;
                }
           }
         
            return solsToUpdate;
        } catch(Exception e) {
            System.debug(loggingLevel.Error, '*** e.getMessage(): ' + e.getMessage());
            throw e;
        }
        
    } 

    private static Boolean isExistingExceptionsClosed(SObject sObj, List<Task> existingExceptions, ExceptionService exService){
        Boolean isClosed = true;

        if(existingExceptions == null || existingExceptions.size() == 0){
            return isClosed;
        }

        for(Task task: existingExceptions){
            if(task.Status == TaskType.EXCEPTION_STATUS_OVERRIDDEN){
                continue;
            } else if(!exService.isExceptionClosed((String)sObj.get('Id'), task.Exception_Code__c)){

                isClosed = false;
                ExceptionService.addMessage(task, (String)sObj.get('Name'), (String)sObj.get('Id'));
                return isClosed;
            }
        }

        return isClosed;
    }

    public static void releaseSalesOrders(Map<Id, List<Sales_Order_Line__c>> soToSoLines){

		Permissions.startAction('Sales_Order_Release');
        ExceptionService exService = new ExceptionService();

        Map<Id, List<Sales_Order_Line__c>> createShipmentSolsMap = new Map<Id, List<Sales_Order_Line__c>>();
        Map<Id, List<Sales_Order_Line__c>> createReqSolsMap = new Map<Id, List<Sales_Order_Line__c>>();
        Map<Id, List<Sales_Order_Line__c>> createKitChildSolsMap = new Map<Id, List<Sales_Order_Line__c>>();
        Map<Id, List<Sales_Order_Line__c>> updateNonStdSOLines = new Map<Id, List<Sales_Order_Line__c>>();

        //This for future to create Fulfillments at Line level but for now we need only the Key set to create Fulfillments for SO.
        Map<Id, List<Sales_Order_Line__c>> createFulFillmentSoMap = new Map<Id, List<Sales_Order_Line__c>>();

        Map<Id, Sales_Order__c> soToUpdateMap = new Map<Id, Sales_Order__c>();
        Map<Id, Sales_Order_Line__c> solsToUpdate = new Map<Id, Sales_Order_Line__c>();

        //Handle Kit SOLs
        if(soToSoLines == null || soToSoLines.isEmpty()){
            ExceptionService.addMessage( MessageUtil.Severity.Error.name(), 'Sales order has no Lines to be released.', '' );
            return;
        }

        Map<Id, List<Task>> soExistingExceptionsMap = getSOExistingExceptions(soToSoLines.keySet());

        for(Id soId: soToSoLines.keySet()) {
            Boolean preventSORelease = false;
            Boolean hasParentChildSoLines = false;

            //Validate Sales Order
            exService = SalesOrderReleaseService.validateSalesOrder(exService, soToSoLines.get(soId)[0].Sales_Order__r);
            

            List<Sales_Order_Line__c> soLines = soToSoLines.get(soId);
            Sales_Order__c soToUpdate = SalesOrderReleaseService.updateSOForRelease(soLines[0].Sales_Order__r);

            if(soToUpdate != new Sales_Order__c()){
                soToUpdateMap.put(soLines[0].Sales_Order__c, soToUpdate);
            }
            
            //If Sales Order has any exceptions then ignore processing So Lines
            if(exService.hasOpenException(soLines[0].Sales_Order__c, soExistingExceptionsMap.get(soId)) ||
               !SalesOrderReleaseService.isExistingExceptionsClosed(soLines[0].Sales_Order__r, soExistingExceptionsMap.get(soId), exService)){

                preventSORelease = true;
                continue;
            }

            

            for(Sales_Order_Line__c sol : soLines){

            	if(sol.Parent_Sales_Order_Line__c != null){
            		hasParentChildSoLines = true;
            	}

                exService = SalesOrderReleaseService.validateSalesOrderLine(exService, sol);
                Boolean solHasException = exService.hasOpenException(sol.id, sol.Tasks) || !isExistingExceptionsClosed(sol, sol.Tasks, exService);

                //Do Not release the SO if Do_Not_Release_Partial_Sales_Orders__c flag is set to true on the company
                if((solHasException) &&
                   sol.Company__r.Do_Not_Release_Partial_Sales_Orders__c){
                    
                    preventSORelease = true;

                } else if(!preventSORelease && !solHasException){

                    if((SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(sol.Sales_Order__r.Type__c)
                        && !SalesOrderService.SO_RMA_TYPES.contains(sol.Sales_Order__r.Type__c))
                          || SalesOrderService.NO_SHIP_ADJ_ORDER_TYPES.contains(sol.Sales_order__r.Type__c)
                        || SalesOrderService.SO_TYPE_RESALE.equals(sol.Sales_order__r.Type__c)){

                        if(createFulFillmentSoMap.containsKey(sol.Sales_Order__c)){

                            createFulFillmentSoMap.get(soId).add(sol);
                        } else {

                            createFulFillmentSoMap.put(soId, new List<Sales_Order_Line__c> { sol });
                        }

                    } else if(sol.Quantity_Ordered__c > 0
                              && !SalesOrderService.NO_SHIP_ADJ_ORDER_TYPES.contains(sol.Sales_order__r.Type__c) 
                              	&& ((!SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(sol.Sales_Order__r.Type__c) && !SalesOrderService.SO_RMA_TYPES.contains(sol.Sales_Order__r.Type__c)) || 
                              (SalesOrderService.SO_TYPE_RMA_REPAIR.contains(sol.Sales_Order__r.Type__c) &&
                         	   	sol.Sales_Order__r.Company__r.Use_Warranty_Repairs__c == false))){
                                 

                        //Update createShipmentSols
                        if (sol.Fulfillment_Source__c.equals(SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_INVENTORY) ||
                            sol.Fulfillment_Source__c.equals(SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK) ||
                            sol.Fulfillment_Source__c.equals(SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER)) {
                            
                            if(createShipmentSolsMap.containsKey(soId)){

                                createShipmentSolsMap.get(soId).add(sol);
                            } else {

                                createShipmentSolsMap.put(soId, new List<Sales_Order_Line__c>{sol});
                            }
                        }

                        //Create Req for Drop ship or Back to Back
                        if (sol.Quantity_Ordered__c >0 
                            && (sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP 
                                || sol.Fulfillment_Source__c == SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK)){
      
                            if(createReqSolsMap.containsKey(soId)){
                                createReqSolsMap.get(soId).add(sol);
                            } else {
                                createReqSolsMap.put(soId, new List<Sales_Order_Line__c>{sol});
                            }
                        }

                        //Update KIT sols Map to create Kit child lines
                        if(sol.Item_Source__c == 'Kit' 
                           && sol.Status__c.equals(SalesOrderLineService.SO_LINE_STATUS_DRAFT)
                           && !SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(sol.Sales_Order__r.Type__c)){

                            if(createKitChildSolsMap.containsKey(soId)){
                                createKitChildSolsMap.get(soId).add(sol);
                            } else {
                                createKitChildSolsMap.put(soId, new List<Sales_Order_Line__c>{sol});
                            }
                        }
                    } else {
                    	//Update All other SO Lines (Eg. RMA)
                    	if(updateNonStdSOLines.containsKey(soId)){
                    		updateNonStdSOLines.get(soId).add(SalesOrderReleaseService.updateSOLForRelease(sol));
                		} else {
                			updateNonStdSOLines.put(soId, new List<Sales_Order_Line__c> { SalesOrderReleaseService.updateSOLForRelease(sol) });
                		}
                    	

                    }
                }
            }

            if(preventSORelease) {
                createShipmentSolsMap.remove(soId);
                createReqSolsMap.remove(soId);
                createKitChildSolsMap.remove(soId);
                createFulFillmentSoMap.remove(soId);
                updateNonStdSOLines.remove(soId);
            } 

            //If SO has Parent Child Lines then check if the parent Lines have any exceptions and remove child lines if true
            if(hasParentChildSoLines){
            	if(!createShipmentSolsMap.isEmpty())
            		createShipmentSolsMap.put(soId, removeChildSOLWithParentSOLException(createShipmentSolsMap.get(soId), exService));
            	if(!createReqSolsMap.isEmpty())
            		createReqSolsMap.put(soId, removeChildSOLWithParentSOLException(createReqSolsMap.get(soId), exService));
            	if(!createFulFillmentSoMap.isEmpty())
            		createFulFillmentSoMap.put(soId, removeChildSOLWithParentSOLException(createFulFillmentSoMap.get(soId), exService));
            	if(!updateNonStdSOLines.isEmpty())
            		updateNonStdSOLines.put(soId, removeChildSOLWithParentSOLException(updateNonStdSOLines.get(soId), exService));
            } 
        }

        exService.finishTasks();

        Savepoint sp = Database.setSavepoint();
        //Shipments for Kit Child
        if(!createKitChildSolsMap.isEmpty()){
            //Create Kit-Child SO Lines
            List<Sales_Order_Line__c> kitChildSOLines = SalesOrderLineService.insertKittedSalesOrderLines(createKitChildSolsMap);

            for(Sales_Order_Line__c kcSoLine: kitChildSOLines) {
                if(createShipmentSolsMap.containsKey(kcSoLine.Sales_Order__c)){
                    createShipmentSolsMap.get(kcSoLine.Sales_Order__c).add(kcSoLine);
                } else {
                    createShipmentSolsMap.put(kcSoLine.Sales_Order__c, new List<Sales_Order_Line__c>{ kcSoLine });
                }
            }
        }

        try {
            
            if(!createShipmentSolsMap.isEmpty()){
                //Create Shipments
                Map<Id, Sales_Order_Line__c> shipmenSols = SalesOrderReleaseService.createShipments(createShipmentSolsMap);

                if(shipmenSols.size() > 0){
                    solsToUpdate.putAll(shipmenSols);
                }
            }
            
            //Create Requisitions
            if(!createReqSolsMap.isEmpty()){
                //Create Shipments
                Map<Id, Sales_Order_Line__c> reqSols = SalesOrderReleaseService.createRequisitions(createReqSolsMap);

                if(reqSols.size() > 0){
                    solsToUpdate.putAll(reqSols);
                }
            }


            if(!createFulFillmentSoMap.isEmpty()){

                FulfillmentService.fulfillSalesOrders(createFulFillmentSoMap.keySet());
            }

            
            
            //Update SO Lines
            if(!updateNonStdSOLines.isEmpty()){
            	solsToUpdate.putAll(SalesOrderReleaseService.getSOLinesMapFromSOToSOLineMap(updateNonStdSOLines));
            }

            DML.updateAsUser(solsToUpdate.values());

            if(!soToUpdateMap.isEmpty()){
                //Update SO
                DML.updateAsUser(soToUpdateMap.values());
            }
            
            //Send release completion email for Async SO release
            if(SalesOrderReleaseService.futureCall){
  
				Set<Id> SOSet = soToSoLines.keySet();
				List<Id> SOIds = new List<Id>(SOSet);
				SalesOrderReleaseService.sendReleaseCompletionEmail(SOIds[0]);
			}
        } catch(Exception e) {
            Database.rollback(sp);
            System.debug(loggingLevel.Error, '*** e.getMessage(): ' + e.getMessage());
            //Send release completion email for Async SO release
            if(SalesOrderReleaseService.futureCall){
  
				Set<Id> SOSet = soToSoLines.keySet();
				List<Id> SOIds = new List<Id>(SOSet);
				SalesOrderReleaseService.sendReleaseCompletionEmail(SOIds[0]);
			}

            throw e;
        }
        Permissions.endAction('Sales_Order_Release');
    }

    /**
     *	removeChildSOLWithParentSOLException removes the child Sales Order Lines from a list of SO Lines 
     *	if the Parent sales Order Lines have any exceptions
     *	@param List<Sales_Order_Line__c> soLines
     *	@param ExceptionService exService
     *	@return List<Sales_Order_Line__c>
     *
     */
    private static List<Sales_Order_Line__c> removeChildSOLWithParentSOLException(List<Sales_Order_Line__c> soLines,
    																			  ExceptionService exService){


    	Integer j = 0;

		while (j < soLines.size())
		{
			if(exService.hasOpenException(soLines.get(j).Parent_Sales_Order_Line__c, soLines.get(j).Tasks)){

				soLines.remove(j);
			}
			else {

				j++;
			}
		}

		return soLines;
    }

    /**
     *	getSOLinesFromSOToSOLineMap method converts a Map of So Id and Solines list to a Map of Sales Order Line Id to 
     *	Sales Order Line
     *	@param Map<Id, List<Sales_Order_Line__c>> soToSoLineMap
     *	@return Map<Id, Sales_Order_Line__c>
     *
     */
    private static Map<Id, Sales_Order_Line__c> getSOLinesMapFromSOToSOLineMap(Map<Id, List<Sales_Order_Line__c>> soToSoLineMap){
    	
    	Map<Id, Sales_Order_Line__c> soLinesMap = new Map<Id, Sales_Order_Line__c>();

    	for(Id soId: soToSoLineMap.keySet()) {
    		List<Sales_Order_Line__c> soLines = soToSoLineMap.get(soId);

    		for(Sales_Order_Line__c sol: soLines) {
    			soLinesMap.put(sol.Id, sol);
    		}
    	}

    	return soLinesMap;
    }

    /**
     * 	undoRelease method reverse a Sales Order that has been released
     *	@param Set<Id> salesOrderIds
     */
    public void undoRelease(Set<Id> salesOrderIds) {
        Map<Id, Sales_Order__c> mSalesOrders = new Map<Id, Sales_Order__c>();
        Set<Id> shipmentIds = new Set<Id>();
        List<Shipment__c> deleteShipments = new List<Shipment__c>();
    
        List<Sales_Order__c> sos = [SELECT Id, Name, Status__c, Type__c,
                                   (SELECT Id, Status__c FROM Requisitions__r),
                                   (SELECT Id, Name, Status__c, Quantity_ordered__c, Quantity_Backordered__c,
                                        Quantity_Allocated__c,Quantity_Shipped__c,Parent_Sales_Order_Line__r.Item_Source__c,Sales_Order__r.Type__c,
                                        Parent_Sales_Order_Line__r.Product__r.Item__r.Source__c, Item_Source__c, Quantity_Fulfilled__c
                                        FROM Sales_Order_Lines__r
                                        WHERE Quantity_Allocated__c = 0
                                            AND (Status__c = :SalesOrderService.SO_STATUS_OPEN OR (Status__c = :SalesOrderService.SO_STATUS_CLOSED and Sales_Order__r.Type__c IN :SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES and Sales_Order__r.Type__c NOT IN ('RMA-Credit', 'RMA-Replacement', 'RMA-Customer-Repair'))) order by Parent_Sales_Order_Line__c nulls first)
                                FROM Sales_Order__c
                                WHERE Id IN :salesOrderIds ];
                  
        List<Sales_Order_Line__c> sols = new List<Sales_Order_Line__c>();
        List<Sales_Order_Line__c> solsForDelete = new List<Sales_Order_Line__c>(); // child lines for kitting

        Set<Id> reqsIdsToDelete = new Set<Id>();
        Boolean isError = false;
        Set<id> draftParentSOL = new Set<id>();

        // create negitive fulfillments for adjustments
        Map<Id,Fulfillment__c> solFulfillMap = new Map<Id,Fulfillment__c>();
        for (Sales_order__c so : sos){
            if (SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(so.Type__c) && !SalesOrderService.SO_RMA_TYPES.contains(so.Type__c)) {
                for (Sales_Order_Line__c sol : so.Sales_Order_Lines__r){
                    Fulfillment__c ful = new Fulfillment__c();
                    ful.Type__c = 'Reversed ' + sol.Sales_Order__r.Type__c;
                    ful.Quantity__c = -sol.Quantity_Fulfilled__c;
                    solFulfillMap.put(sol.id, ful);
                }
            }
        }

        for(Sales_Order__c so : sos){
            integer counter = 0;

            for (Requisition__c RQ : so.Requisitions__r){
                if (ApexPages.currentPage() != null && RQ.Status__c != RequisitionService.RQ_STATUS_CANCELLED) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please cancel the Requisition before you Undo Release.'));
                    isError = true;
                    break;
                } else {
                    reqsIdsToDelete.add(RQ.Id);
                }
            }

            if(ApexPages.currentPage() != null && so.Sales_Order_Lines__r.size() == 0 ){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The Sales Order has no lines to be Undo Released.'));
                isError = true;
                break;
            }

            // sorted by Parent Sales Order lines with nulls first - this means we're looking at parents lines first
            for(Sales_Order_Line__c sol : so.Sales_Order_Lines__r){
              Decimal qtyFulfilledOrAllocated = KSE.addQuantityToField(sol.Quantity_Fulfilled__c, sol.Quantity_Allocated__c);
              Decimal remainingQty = KSE.subtractDecimals(sol.Quantity_Ordered__c, qtyFulfilledOrAllocated);

                // delete child lines if parent is changed to draft status
                if (draftParentSOL.contains(sol.Parent_Sales_Order_Line__c) && sol.Quantity_Fulfilled__c == 0){
                solsForDelete.add(sol);
                //continue;
              }

                if( (remainingQty == sol.quantity_backordered__c && sol.Status__c != SalesOrderService.SO_STATUS_CLOSED) || SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(sol.Sales_order__r.Type__c)) {


                    sol.status__c = SalesOrderService.SO_STATUS_DRAFT;

                    if (sol.Item_Source__c == 'Kit'){
                        draftParentSOL.add(sol.id);
                    }

                	sols.add(new Sales_Order_Line__c( Id=sol.id, Status__c=sol.Status__c));



	                counter++;
	                if(!mSalesOrders.containsKey(so.Id)){
	                    mSalesOrders.put(so.Id, so);
          	      	}
              	}
            }

            //Mark the Sales Order as a Draft if all lines are undergoing the undo release process
            if(counter == so.Sales_Order_Lines__r.size()){
                so.Status__c = SalesOrderService.SO_STATUS_DRAFT;
            }
        }
    
        if (!isError){
            List<Shipment_Line__c> shipLines = [SELECT id, name, shipment__c
                          FROM Shipment_Line__c
                          WHERE Sales_Order_Line__c IN :sols
                            AND Shipment__r.Status__c != 'Confirmed'
                            AND Shipment__r.Status__c != 'Delivered'];

            for(Shipment_Line__c sl : shipLines){
                shipmentIds.add(sl.shipment__c);
            }

            if(shipLines.size() > 0){
                //KNDY-1753
                DML.deleteAsUser(shipLines);

            }

            //KNDY-1753
            DML.deleteAsUser([SELECT Id FROM Requisition__c WHERE Id IN :reqsIdsToDelete]);
            DML.updateAsUser(mSalesOrders.values());

            if (!solFulfillMap.keySet().isEmpty()){
                FulfillmentService.fulfillSalesOrders(solFulfillMap.keySet(), solFulfillMap);
            }

            DML.updateAsUser(sols);

            if (!solsForDelete.isEmpty()){
              	DML.deleteAsUser(solsForDelete); // after update to bypass status validation
            }
            
            
	        ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, Label.SO_Undo_Released));
			
        }
    }

    public static Sales_Order__c getSODetails(Id salesOrderId){
      
		List<Sales_Order__c> SO = [select name,
		                Company__c
		               from Sales_Order__c
		                  WHERE id = :String.valueOf(salesOrderId)
		                   limit 1];
                           
    	return SO[0];
    }
    
    public static String getSOData(Id salesOrderId, String fieldName){
      
		Sales_Order__c SO;

		if(SO == Null){
			SO = new Sales_Order__c();
			SO = getSODetails(salesOrderId);

		}

		if(fieldName.equals('Company')){
			return String.valueOf(SO.Company__c);
		}                

		if(fieldName.equals('SOName')){

			return String.valueOf(SO.name);
		}

		return null;
                        
    }

    public static void sendReleaseCompletionEmail(Id SalesOrderId){
      
		String emailSubject = Label.SO_Release_Email_subject;
		String emailMessage = Label.SO_Release_Email_Body;
		String SOId = String.valueOf(SalesOrderId);

		String SOName = getSOData(SalesOrderId, 'SOName');

		String SOSubjectMatchingString = '{SOName}';
		String SOMessageMatchingString = '{SOLink}';

		if(emailSubject.contains(SOSubjectMatchingString)){

			emailSubject = emailSubject.replace(SOSubjectMatchingString, SOName);
		}

		if(emailMessage.contains(SOMessageMatchingString)){

			String SOLink = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + SOId.substring(0, SOId.length() - 3);

			emailMessage = emailMessage.replace(SOMessageMatchingString, SOLink);
		}

		KSE.sendEmailBatchCompletion(emailMessage, emailSubject);
      
      
    }
}