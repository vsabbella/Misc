/**
 * This class contains unit tests for validating the behavior of test methods in ShipmentService.cls
 */
@isTest
private class ShipmentServiceTest {
	static TestFuel globalTestData = new TestFuel();
	
    static testMethod void test_if_earliest_and_latest_shipment_dates_are_populated() {
    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
     
		Date estimatedShipDate;
		List<Shipment_Line__c> shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
				Shipment__r.Planned_Delivery_Date__c, Shipment__r.Earliest_Shipment_Date__c,
				Shipment__r.Latest_Shipment_Date__c, Need_Date__c
		from Shipment_Line__c
		where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
		
        for(Shipment_Line__c shipmentLine : shipmentLines){
			estimatedShipDate = estimatedShipDate == null || estimatedShipDate < shipmentLine.Need_Date__c ? shipmentLine.Need_Date__c : estimatedShipDate;
		}
	
		system.assertEquals(estimatedShipDate, shipmentLines[0].Shipment__r.Earliest_Shipment_Date__c);
		system.assertEquals(estimatedShipDate, shipmentLines[0].Shipment__r.Latest_Shipment_Date__c);
        
        Test.startTest();
    	
        // Test if the earliest and latest shipment dates are calculated based on 
        // the required date on the sales order.
        SalesOrderAllocateExt soAllocate = new SalesOrderAllocateExt(sc);
        soAllocate.undoRelease();
        
        Date requiredDate = system.today() + 30;
    	
    	globalTestData.customerShipTo.Earliest_Delivery_Window__c = 2;
    	globalTestData.customerShipTo.Latest_Delivery_Window__c = 2;
    	update globalTestData.customerShipTo;
    	
    	globalTestData.salesOrder.Required_Date__c = requiredDate;
    	globalTestData.salesOrder.Means_of_Transport__c = globalTestData.meansOfTransport.Id;
    	update globalTestData.salesOrder;
		
		for (Sales_Order_Line__c sol : globalTestData.salesOrderLines){
			sol.Required_Date__c = requiredDate;
		}
		update globalTestData.salesOrderLines;
    	
    	globalTestData.facility2.Lead_Time__c = 3;
    	update globalTestData.facility2;
    	
    	// Release the sales order to check if the dates are being populated.
    	soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
	
		shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
				Shipment__r.Planned_Delivery_Date__c, Shipment__r.Earliest_Shipment_Date__c,
				Shipment__r.Latest_Shipment_Date__c, Shipment__r.Customer__r.Business_Hours__c
		from Shipment_Line__c
		where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
		
        for(Shipment_Line__c shipmentLine : shipmentLines){
        	system.assertEquals(requiredDate, shipmentLine.Shipment__r.Planned_Delivery_Date__c);
        }
	
		Date earliest = KSE.previousBusinessDate(shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c, Integer.valueOf(globalTestData.customerShipTo.Earliest_Delivery_Window__c), globalTestData.facility2.Shipping_Calendar__c);
		Date latest = KSE.nextBusinessDate(shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c, Integer.valueOf(globalTestData.customerShipTo.Latest_Delivery_Window__c), shipmentLines[0].Shipment__r.Customer__r.Business_Hours__c);
	
		system.assertEquals( shipmentLines[0].Shipment__r.Earliest_Shipment_Date__c, earliest);
		system.assertEquals( shipmentLines[0].Shipment__r.Latest_Shipment_Date__c, latest);
        
        Test.stopTest();
    }
    
	static testMethod void test_if_planned_delivery_date_is_populated() {
    	
    	Test.startTest();
    	Date requiredDate = system.today() + 30;
    	
    	globalTestData.salesOrder.Required_Date__c = requiredDate;
    	globalTestData.salesOrder.Means_of_Transport__c = globalTestData.meansOfTransport.Id;
    	globalTestData.salesOrder.Delivery_Method__c = 'Delivery';
    	update globalTestData.salesOrder;
		
		for (Sales_Order_Line__c sol : globalTestData.salesOrderLines){
			sol.Required_Date__c = requiredDate;
		}
		update globalTestData.salesOrderLines;
    	
    	globalTestData.facility2.Lead_Time__c = null;
    	// KNDY-10333 globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
    	update globalTestData.facility2;
    	
        /* KNDY-10333  
    	globalTestData.transitRoute.Primary__c = true;
        update globalTestData.transitRoute;
    	*/

    	Sales_Order__c salesOrder = [select Id, Delivery_Method__c, Means_of_Transport__c, Required_Date__c from Sales_Order__c where Id =:globalTestData.salesOrder.Id];
    	  
    	system.assert(salesOrder.Delivery_Method__c != null, 'The delivery method on Sales Order is null');
    	  
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
        system.assertEquals( false, soReleaseExt.hasErrors , Apexpages.getMessages() );
        List<Shipment_Line__c> shipmentLineList = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
	                                                      Shipment__r.Planned_Delivery_Date__c, Shipment__r.Earliest_Shipment_Date__c,
	                                                      Shipment__r.Latest_Shipment_Date__c
	        									     from Shipment_Line__c 
	        									    where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
		system.assert(shipmentLineList.size() > 0, 'Expected shipment lines to be created.');
		        									  
        for(Shipment_Line__c shipmentLine : shipmentLineList){
        	system.assertEquals(requiredDate, shipmentLine.Shipment__r.Planned_Delivery_Date__c);
        }
        
        Test.stopTest();
    }
    
    static testMethod void test_if_shipment_dates_are_valid() {
    	//Test if the eartliest shipment date is after the next possible shipment date for the facility.
        
        Test.startTest();

        Date requiredDate = system.today() + 7;
    	
    	globalTestData.customerShipTo.Earliest_Delivery_Window__c = 2;
    	globalTestData.customerShipTo.Latest_Delivery_Window__c = 10;
    	update globalTestData.customerShipTo;
    	
    	globalTestData.salesOrder.Required_Date__c = requiredDate;
    	globalTestData.salesOrder.Means_of_Transport__c = globalTestData.meansOfTransport.Id;
    	update globalTestData.salesOrder;
    	
		for (Sales_Order_Line__c sol : globalTestData.salesOrderLines){
			sol.Required_Date__c = requiredDate;
		}
		update globalTestData.salesOrderLines;

    	globalTestData.facility2.Lead_Time__c = 2;
    	update globalTestData.facility2;
    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
        
        Date nextFacilityShipmentDate = KSE.calculateEndDate(system.today(), Integer.valueOf(globalTestData.facility2.Lead_Time__c), globalTestData.facility2.Shipping_Calendar__c);
	
		
		List<Shipment_Line__c> shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
				Shipment__r.Planned_Delivery_Date__c, Shipment__r.Earliest_Shipment_Date__c,
				Shipment__r.Latest_Shipment_Date__c, Need_Date__c
		from Shipment_Line__c
		where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
		
		for(Shipment_Line__c shipmentLine : shipmentLines){
        	// Assert that the earliest and latest shipment dates are after the next available date for the facility to ship 
        	system.assert(nextFacilityShipmentDate <= shipmentLine.Shipment__r.Earliest_Shipment_Date__c);
        	system.assert(nextFacilityShipmentDate <= shipmentLine.Shipment__r.Latest_Shipment_Date__c);

			Date earliestDeliveryDate = KSE.calculateStartDate(shipmentLine.Need_Date__c, Integer.valueOf(globalTestData.customerShipTo.Earliest_Delivery_Window__c), globalTestData.facility2.Shipping_Calendar__c);
			Date latestDeliveryDate = KSE.calculateEndDate(shipmentLine.Need_Date__c, Integer.valueOf(globalTestData.customerShipTo.Latest_Delivery_Window__c), globalTestData.facility2.Shipping_Calendar__c);

        	system.assert(earliestDeliveryDate <= shipmentLine.Shipment__r.Estimated_Delivery_Date__c
        	                && shipmentLine.Shipment__r.Estimated_Delivery_Date__c <= latestDeliveryDate);
			
        }
		
		// ba-todo check whether this is true or not. Required date specified so est ship date should be Need Date - lead time. Lead time is 2.
		system.assertEquals(shipmentLines[0].Shipment__r.Planned_Delivery_Date__c, (system.today() + 7));
//		Date shDateEstimated = shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c.addDays(Integer.valueOf(globalTestData.facility2.Lead_Time__c));
//		system.assertEquals(shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c, shDateEstimated);
        Test.stopTest();
    }
    
    static testMethod void test_if_estimated_shipment_and_delivery_dates_are_populated() {
    	
    	Test.startTest();
    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
	
		date estimatedShipDate;
		
		List<Shipment_Line__c> shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
		Location__r.Facility__r.Shipping_Calendar__c
		from Shipment_Line__c
		where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
		
	
		system.assertEquals(shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c, shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c);
		system.assertEquals(shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c, shipmentLines[0].Shipment__r.Estimated_Delivery_Date__c);
        
        Test.stopTest();
    }
    
    static testMethod void test_if_facility_lead_time_is_added() {
    	
    	Test.startTest();
        Carrier__c carr = new Carrier__c( name = 'SFDS');
        insert carr;

    	Shipping_Method__c shippingMethod = new Shipping_Method__c(
            Name = 'Super Fast Delivery Service',
            Service__c = '2 Day',
            Carrier__c = carr.id
        );
        insert shippingMethod;

    	globalTestData.facility2.Lead_Time__c = 2;
        update globalTestData.facility2;

        globalTestData.customerShipTo.Preferred_Shipping_Method__c = shippingMethod.id;
        update globalTestData.customerShipTo;
        
		List<Sales_Order_Line__c> solList = [select id, Required_Date__c, Sales_Order__r.Required_Date__c from Sales_Order_Line__c where Sales_Order__c = :globalTestData.salesOrder.Id];
		for (Sales_Order_Line__c sol : solList){
			sol.Required_Date__c = sol.Sales_Order__r.Required_Date__c;
		}
		update solList;

        // Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
        
        List<Shipment_Line__c> shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c, shipment__r.Shipping_Method__c,
                                                       Location__r.Facility__r.Shipping_Calendar__c, Need_Date__c, Shipment__r.Planned_Delivery_Date__c, Sales_Order_Line__r.Required_Date__c
	        									  from Shipment_Line__c 
	        									 where Sales_Order_Line__c IN :globalTestData.salesOrderLines];

		Date estDate = KSE.calculateEndDate(system.today(), 2, shipmentLines[0].Location__r.Facility__r.Shipping_Calendar__c);
		system.assertEquals(estDate, shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c);
		Date nextBDate = KSE.nextBusinessDate(shipmentLines[0].Shipment__r.Shipment_Date_Estimated__c, 0, shipmentLines[0].Location__r.Facility__r.Shipping_Calendar__c);
		system.assertEquals(nextBDate, shipmentLines[0].Shipment__r.Estimated_Delivery_Date__c);
        
        System.assert(shipmentLines[0].shipment__r.Shipping_Method__c == shippingMethod.id, 'Expecting shipping method from SO to get copied to Shipment');

        // Change facility on shipment lines to see if the estimated dates are re-calculated. 
        globalTestData.facility.Lead_Time__c = 1;
        update globalTestData.facility;
        
        Map<Id, Shipment__c> shipmentsMap = new Map<Id, Shipment__c>(); 
        for(Shipment_Line__c shipmentLine : shipmentLines){
        	shipmentLine.Location__c = globalTestData.location.Id;
        	shipmentLine.Shipment__r.Shipment_Date_Estimated__c = null;
        
        	shipmentsMap.put(shipmentLine.Shipment__c, shipmentLine.Shipment__r);
        }
        
        update shipmentsMap.values();
        update shipmentLines;
        
        shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
                                Location__r.Facility__r.Shipping_Calendar__c
						   from Shipment_Line__c 
						  where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
						  
        for(Shipment_Line__c shipmentLine : shipmentLines){
        	system.assertEquals(KSE.calculateEndDate(system.today(), 1, shipmentLine.Location__r.Facility__r.Shipping_Calendar__c), shipmentLine.Shipment__r.Shipment_Date_Estimated__c);
        	system.assertEquals(KSE.nextBusinessDate(shipmentLine.Shipment__r.Shipment_Date_Estimated__c, 0, shipmentLine.Location__r.Facility__r.Shipping_Calendar__c), shipmentLine.Shipment__r.Estimated_Delivery_Date__c);
        }
        
        Test.stopTest();
    }
    
    /* KNDY-10333
    static testMethod void test_if_transit_time_is_added() {
    	
    	Test.startTest();
    	
    	system.assert(globalTestData.meansOfTransport.Id != null);
    	system.assert(globalTestData.transitRoute.Id != null);
    	system.assert(globalTestData.transitRoute.Origin__c != null);
    	system.assert(globalTestData.transitRoute.Destination__c != null);
    	system.assert(globalTestData.transitRoute.Means_of_Transport__c != null);
    	
    	globalTestData.facility2.Lead_Time__c = 2;
    	globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
        update globalTestData.facility2;
        
    	globalTestData.salesOrder.Means_of_Transport__c = globalTestData.meansOfTransport.Id;
        update globalTestData.salesOrder;
        
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
        
        for(Shipment_Line__c shipmentLine : [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
                                                    Location__r.Facility__r.Shipping_Calendar__c, Shipment__r.Customer__r.Business_Hours__c
        									   from Shipment_Line__c 
        									  where Sales_Order_Line__c IN :globalTestData.salesOrderLines]){
        									  	
			// The facility lead time is 2 days        									  	
        	system.assertEquals(KSE.calculateEndDate(system.today(), 2, shipmentLine.Location__r.Facility__r.Shipping_Calendar__c), shipmentLine.Shipment__r.Shipment_Date_Estimated__c);
        	// The transit time is another 2 days
        	system.assertEquals(KSE.nextBusinessDate(shipmentLine.Shipment__r.Shipment_Date_Estimated__c, 2, shipmentLine.Shipment__r.Customer__r.Business_Hours__c), shipmentLine.Shipment__r.Estimated_Delivery_Date__c);
        }
    	
    	Test.stopTest();
    }
    */
    
    static testMethod void test_if_next_start_date_is_a_business_day(){
    	
    	List<BusinessHours> bussHours = [select Id, Name, 
    											SundayStartTime, SundayEndTime,
    											MondayStartTime, MondayEndTime,
    											TuesdayStartTime, TuesdayEndTime,
    											WednesdayStartTime, WednesdayEndTime,
    											ThursdayStartTime, ThursdayEndTime,
    											FridayStartTime, FridayEndTime,
    											SaturdayStartTime, SaturdayEndTime 
    									   from BusinessHours 
    									  where IsActive = true
    									  	and IsDefault = true 
    									  limit 1
    									 ];
    	
    	if(bussHours.size() > 0){
    		// Assert that the futureDate is not a holiday.
    		Integer leadTime = Integer.valueOf(Math.random());
    		Date futureDate = KSE.nextBusinessDate(system.today(), leadTime, bussHours[0].Id);
    		
    		DateTime nextStartDateTime;
    		nextStartDateTime = DateTime.newInstance(futureDate.year(), futureDate.month(), futureDate.day(), 0, 0, 0);
        	nextStartDateTime = BusinessHours.nextStartDate(bussHours[0].id, nextStartDateTime);
        	
    		Date nextStartDate = Date.newInstance(nextStartDateTime.year(), nextStartDateTime.month(), nextStartDateTime.day());
    		
    		system.assertEquals(nextStartDate, futureDate);
    		
    		//Assert that the future date falls on day with business hours
    		Integer dayOfTheWeek = KSE.dayOfTheWeek(futureDate);
    		
    		if(dayOfTheWeek == 0){
    			system.assert(bussHours[0].SundayStartTime != null);
    			system.assert(bussHours[0].SundayEndTime != null);
    		}
    		if(dayOfTheWeek == 1){
    			system.assert(bussHours[0].MondayStartTime != null);
    			system.assert(bussHours[0].MondayEndTime != null);
    		}
    		if(dayOfTheWeek == 2){
    			system.assert(bussHours[0].TuesdayStartTime != null);
    			system.assert(bussHours[0].TuesdayEndTime != null);
    		}
    		if(dayOfTheWeek == 3){
    			system.assert(bussHours[0].WednesdayStartTime != null);
    			system.assert(bussHours[0].WednesdayEndTime != null);
    		}
    		if(dayOfTheWeek == 4){
    			system.assert(bussHours[0].ThursdayStartTime != null);
    			system.assert(bussHours[0].ThursdayEndTime != null);
    		}
    		if(dayOfTheWeek == 5){
    			system.assert(bussHours[0].FridayStartTime != null);
    			system.assert(bussHours[0].FridayEndTime != null);
    		}
    		if(dayOfTheWeek == 6){
    			system.assert(bussHours[0].SaturdayStartTime != null);
    			system.assert(bussHours[0].SaturdayEndTime != null);
    		}
    		
    	}
    }
    
    /* KNDY-10333
    //KNDY 4494 Calcualting Estimated Delivery Date in case of Pickup as Delivery Method
     static testMethod void test_deliverymethodPickup() {    	
    	List<Period__c> periodList = globalTestData.periodList;
        system.assert(globalTestData.meansOfTransport.Id != null);
    	system.assert(globalTestData.transitRoute.Id != null);
    	system.assert(globalTestData.transitRoute.Origin__c != null);
    	system.assert(globalTestData.transitRoute.Destination__c != null);
    	system.assert(globalTestData.transitRoute.Means_of_Transport__c != null);
    	system.assert(globalTestData.transitRoute.Transit_Time__c >1);
    	
    	globalTestData.facility2.Lead_Time__c = 2;
    	globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
        update globalTestData.facility2;   
       
        globalTestData.transitRoute.Delivery_Method__c = 'Pickup';
        globalTestData.transitRoute.Transit_Time__c = 0;
        update globalTestData.transitRoute;
        
        Sales_Order__c salesOrder = globalTestData.salesOrder;        
        salesOrder = [Select Id, Pricing_Date__c, Price_Determination_Date__c from Sales_Order__c];
        
        List<SKID__c> skids = globalTestData.skids;
        List<Stock_Movement_Rule_Settings__c> smrsList = globalTestData.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = globalTestData.stockMovementRuleList;
        List<Shipment_Line__c> shiplines = new List<Shipment_Line__c>();
        Sales_Order_Line__c salesOrderLine = globalTestData.salesOrderLines[0];
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt planExt = new SOPlanExt(con);
        planExt.plan();
        Test.startTest();
        salesOrder = [Select Id, Pricing_Date__c, Price_Determination_Date__c, Delivery_Method__c from Sales_Order__c];
        system.assert(salesOrder.Delivery_Method__c == 'Pickup', 'The delivery method does not match from transit route');    
               
        
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            system.assert( sw.skidList.size() == 1, ApexPages.getMessages()+',:SOAEXTLOcations'+SOAExt.locationsByHeader );
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        
        SOAExt.allocate();
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();
        shiplines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c, Shipment__r.Date_Shipped__c,Shipment__r.Status__c,
                                                    Location__r.Facility__r.Shipping_Calendar__c, Shipment__r.Customer__r.Business_Hours__c
        									   from Shipment_Line__c 
        									  where Sales_Order_Line__c = :salesOrderLine.Id];
        system.assertEquals('Confirmed', shiplines[0].Shipment__r.Status__c, 'The shipment is not confirmed'+shiplines[0].Shipment__r.Status__c);
        system.assertEquals((shiplines[0].Shipment__r.Date_Shipped__c).date(), shiplines[0].Shipment__r.Estimated_Delivery_Date__c, 'Delivery Date does not match Date Shipped in case of Pickup' +shiplines[0].Shipment__r.Estimated_Delivery_Date__c + 'date shipped'+shiplines[0].Shipment__r.Date_Shipped__c);
  
        Test.stopTest();
    }
    */ 

    /* 
        Goes through the SO flow (release, allocate, confirm pick, confirm ship) and goes through the reverse flow 
        (undo ship confirm, undo confirm pick, un allocate, undo release) and asserts the skid type and count
    */
    // TODO: Below test method to be uncommented and refactored to avoid Too many SOQL errors - KNDY-9757
    /*static testMethod void test_SO_skid_flow(){

      List<Period__c> periodList = globalTestData.periodList;
      system.assert(globalTestData.meansOfTransport.Id != null);
      system.assert(globalTestData.transitRoute.Id != null);
      system.assert(globalTestData.transitRoute.Origin__c != null);
      system.assert(globalTestData.transitRoute.Destination__c != null);
      system.assert(globalTestData.transitRoute.Means_of_Transport__c != null);
      system.assert(globalTestData.transitRoute.Transit_Time__c >1);
        
      globalTestData.facility2.Lead_Time__c = 2;
      globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
        update globalTestData.facility2;
        
        Sales_Order__c salesOrder = globalTestData.salesOrder;    
        salesOrder = [Select Id, Pricing_Date__c, Price_Determination_Date__c from Sales_Order__c];
         Sales_order_line__c[] sols = [select id, Quantity_Ordered__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        
        List<SKID__c> skids = globalTestData.skids;
        List<Stock_Movement_Rule_Settings__c> smrsList = globalTestData.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = globalTestData.stockMovementRuleList;
        List<Shipment_Line__c> shiplines = new List<Shipment_Line__c>();
        Sales_Order_Line__c salesOrderLine = globalTestData.salesOrderLines[0];
        

        SalesOrderAPI.SalesOrderWrapper sow ;
        Map<Id,SalesOrderAPI.SalesOrderWrapper> sowMap ;
        sowMap = new Map<Id,SalesOrderAPI.SalesOrderWrapper>();
        sow =  new SalesOrderAPI.SalesOrderWrapper(salesOrder.Id);       
        for (Sales_Order_Line__c soLine : sols) {
            SalesOrderAPI.SalesOrderLineWrapper sol = new SalesOrderAPI.SalesOrderLineWrapper();
            SalesOrderAPI.PickedQuantity pq = new SalesOrderAPI.PickedQuantity();
            pq.qtyShipped = soLine.Quantity_Ordered__c;
            pq.lot = 'AAA';
            pq.expirationDate = System.today() + 365;
            sol.quantities.add(pq);
            sow.lines.put(soLine.Id,sol);
        }
        sowMap.put(salesOrder.Id,sow);
        SalesOrderAPI.SalesOrderAPIStatus release = SalesOrderAPI.release(sowMap).get(salesOrder.id);
		
		
        
        // SO released - 1 skid (so demand)
        if (release.ErrorMessage == null) release.ErrorMessage = '';
        system.assertEquals(true, release.success );
        Sales_order_line__c[] solsFlow = [select id, Quantity_Ordered__c, Quantity_Allocated__c, Quantity_shipped__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(1, sol.skids__r.size(), sol.skids__r.size());
            for (Skid__c skid : sol.skids__r){
                system.assertEquals('SO Demand', skid.Type__c, skid.Type__c);
            }
        }

        // SO allocated - 1 skid (allocated)
        SalesOrderAPI.SalesOrderAPIStatus allocate = SalesOrderAPI.allocate(sowMap).get(salesOrder.id);
        if (allocate.ErrorMessage == null) allocate.ErrorMessage = '';
        system.assertEquals(true, allocate.success, allocate.ErrorMessage);
        solsFlow = [select id, Quantity_Ordered__c, Quantity_Allocated__c, Quantity_shipped__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(1, sol.skids__r.size(), sol.skids__r.size());
            for (Skid__c skid : sol.skids__r){
                system.assertEquals('Allocated', skid.Type__c, skid.Type__c);
            }
        }

        // pick confirm - no skids
        SalesOrderAPI.SalesOrderAPIStatus pick = SalesOrderAPI.pick(sowMap).get(salesOrder.id);
        if (pick.ErrorMessage == null) pick.ErrorMessage = '';
        system.assertEquals(true, pick.success , pick.errorMessage);
        solsFlow = [select id, Quantity_Ordered__c, Quantity_Allocated__c, Quantity_shipped__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(0, sol.skids__r.size(), sol.skids__r.size());
            for (Skid__c skid : sol.skids__r){
                system.assertEquals(0, sol.skids__r.size(), sol.skids__r.size());
            }
        }
        
        Test.startTest();
        
        // pack ship - no skids
        SalesOrderAPI.SalesOrderAPIStatus confirmShip = SalesOrderAPI.confirmShip(sowMap).get(salesOrder.id);
        if (confirmShip.ErrorMessage == null) confirmShip.ErrorMessage = '';
        system.assertEquals(true, confirmShip.success , confirmShip.errorMessage);
        solsFlow = [select id, Quantity_Ordered__c, Quantity_Allocated__c, Quantity_shipped__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(0, sol.skids__r.size(), sol.skids__r.size());
            for (Skid__c skid : sol.skids__r){
                system.assertEquals(0, sol.skids__r.size(), sol.skids__r.size());
            }
        }
        system.assert([select id, status__c from Sales_Order__c where id =: salesorder.id].status__c == 'Closed');
        Shipment_line__c[] ship = [select id, Quantity_Planned__c, quantity_shipped__c, shipment__c,
                (select id from skids__r), 
                (select id from inventory_transactions__r) 
            from shipment_line__c];

        set<id> shipmentLine = new set <id>();
        for (shipment_line__c shipline : ship){
            shipmentLine.add(shipline.shipment__c );
        }

        system.debug(logginglevel.info, ship);
        system.debug(logginglevel.info, shipmentLine);


        // undo ship confirm. No skids. Only transaction records
        SalesOrderService sos = new SalesOrderService();
        sos.undoShipConfirm(shipmentLine);
        solsFlow = [select id, Quantity_Ordered__c, (select id, quantity__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(0, sol.skids__r.size(), sol.skids__r.size());
        }

        set<id> itsSet = new set<id>();
        Inventory_Transaction__c[] its = [select id from Inventory_Transaction__c];
        for (Inventory_Transaction__c it : its){
            itsSet.add(it.id);
        }

        // undo pick. 1 skid (Allocated)
        sos.undoConfirmPickNew(itsSet);
        Set<Id> allocatedIds = new set<Id>();
        solsFlow = [select id, Quantity_Ordered__c, Quantity_Allocated__c, Quantity_shipped__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(1, sol.skids__r.size(), sol.skids__r.size());
            for (Skid__c skid : sol.skids__r){
                allocatedIds.add(skid.id);
                system.assertEquals('Allocated', skid.Type__c, skid.Type__c);
            }
        }

        // un allocate. 1 skid (SO demand)
        sos.unallocateNew(allocatedIds);
        solsFlow = [select id, Quantity_Ordered__c, Quantity_Allocated__c, Quantity_shipped__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(1, sol.skids__r.size(), sol.skids__r.size());
            for (Skid__c skid : sol.skids__r){
                system.assertEquals('SO Demand', skid.Type__c, skid.Type__c + ' ' + sol.Quantity_Shipped__c );
            }
        }

        // undo release. no skids
        sos.undoPlan(new set<id>{salesorder.id});
        solsFlow = [select id, Quantity_Ordered__c, Quantity_Allocated__c, Quantity_shipped__c, (select id, quantity__c,Type__c from SKIDS__r) from Sales_Order_Line__c];
        for (Sales_order_line__c sol : solsFlow){
            system.assertEquals(0, sol.skids__r.size(), sol.skids__r.size());
        }

    }*/

    /* KNDY-10333
     //KNDY 4494 Calcualting Estimated Delivery Date in case of Delivery as Delivery Method
     static testMethod void test_deliverymethodDelivery() {    	
    	List<Period__c> periodList = globalTestData.periodList;
        system.assert(globalTestData.meansOfTransport.Id != null);
    	system.assert(globalTestData.transitRoute.Id != null);
    	system.assert(globalTestData.transitRoute.Origin__c != null);
    	system.assert(globalTestData.transitRoute.Destination__c != null);
    	system.assert(globalTestData.transitRoute.Means_of_Transport__c != null);
    	system.assert(globalTestData.transitRoute.Transit_Time__c >1);
        
    	globalTestData.facility2.Lead_Time__c = 2;
    	globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
        update globalTestData.facility2;
        
        Sales_Order__c salesOrder = globalTestData.salesOrder;    
        salesOrder = [Select Id, Pricing_Date__c, Price_Determination_Date__c from Sales_Order__c];
        
        List<SKID__c> skids = globalTestData.skids;
        List<Stock_Movement_Rule_Settings__c> smrsList = globalTestData.smrsList;
        List<Stock_Movement_Rule__c> stockMovementRuleList = globalTestData.stockMovementRuleList;
        List<Shipment_Line__c> shiplines = new List<Shipment_Line__c>();
        Sales_Order_Line__c salesOrderLine = globalTestData.salesOrderLines[0];
        
        ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
        SOPlanExt planExt = new SOPlanExt(con);
        planExt.plan();
        Test.startTest();
        salesOrder = [Select Id, Pricing_Date__c, Price_Determination_Date__c, Delivery_Method__c from Sales_Order__c];
        
        system.assert(salesOrder.Delivery_Method__c == 'Delivery', 'The delivery method does not match from transit route');
        system.assertEquals( false, planExt.hasErrors, 'Release Issue' +Apexpages.getMessages() );

        shiplines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c, Shipment__r.Date_Shipped__c,
                                                    Location__r.Facility__r.Shipping_Calendar__c, Shipment__r.Customer__r.Business_Hours__c
        									   from Shipment_Line__c 
        									  where Sales_Order_Line__c = :salesOrderLine.Id];
        									  
        system.assert(shiplines[0].Id != null, 'Error');									  
        system.assert(shiplines[0].Shipment__r.Estimated_Delivery_Date__c != shiplines[0].Shipment__r.Shipment_Date_Estimated__c, 'Delivery Date is not correct in case of DropOff');          
        
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);
        
        for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
            system.assert( sw.skidList.size() == 1, ApexPages.getMessages()+',:SOAEXTLOcations'+SOAExt.locationsByHeader );
            sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
        }
        
        SOAExt.allocate();
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderConfirmPickExt socpExt = new SalesOrderConfirmPickExt(con);
        socpExt.confirmPick();
        
        con = new ApexPages.Standardcontroller(salesOrder);
        SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension(con);
        socsExt.confirmShip();
        
        shiplines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c, Shipment__r.Date_Shipped__c,Shipment__r.Status__c,
                                                    Location__r.Facility__r.Shipping_Calendar__c, Shipment__r.Customer__r.Business_Hours__c
        									   from Shipment_Line__c 
        									  where Sales_Order_Line__c = :salesOrderLine.Id];
        system.assert(shiplines[0].Shipment__r.Status__c == 'Confirmed', 'The shipment is not confirmed'+shiplines[0].Shipment__r.Status__c);
        system.assert(shiplines[0].Shipment__r.Estimated_Delivery_Date__c != (shiplines[0].Shipment__r.Date_Shipped__c).date(), 'Delivery Date is not matching with Date Shipped in case of Delivery' +shiplines[0].Shipment__r.Estimated_Delivery_Date__c + 'date shipped'+shiplines[0].Shipment__r.Date_Shipped__c);
  
        Test.stopTest();
    }
    
    static testMethod void test_transitRouteCalendar_Delivery() {
    	
    	Test.startTest();
    	
    	globalTestData.facility2.Lead_Time__c = 2;
    	globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
        update globalTestData.facility2;
        
        //Populating Transit Route Calendar so that it can be picked over the Facility Calendar as per KNDY#4713
        globalTestData.transitRoute.Shipping_Calendar__c = [select Id from BusinessHours where isDefault = true limit 1].Id;        
        globalTestData.transitRoute.Delivery_Method__c = 'Delivery';       
        update globalTestData.transitRoute;       
             
        // Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
        
        List<Shipment_Line__c> shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
                                                       Location__r.Facility__r.Shipping_Calendar__c
	        									  from Shipment_Line__c 
	        									 where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
	        									 
        for(Shipment_Line__c shipmentLine : shipmentLines){
        	// The facility lead time is 2 days   
        	system.assertEquals(KSE.calculateEndDate(system.today(), 2, globalTestData.transitRoute.Shipping_Calendar__c), shipmentLine.Shipment__r.Shipment_Date_Estimated__c);
        	// The transit time is another 2 days
        	system.assertEquals(KSE.nextBusinessDate(shipmentLine.Shipment__r.Shipment_Date_Estimated__c, 2, globalTestData.transitRoute.Shipping_Calendar__c), shipmentLine.Shipment__r.Estimated_Delivery_Date__c);
        }       
        
        Test.stopTest();
    }
      static testMethod void test_transitRouteCalendar_Pickup() {
    	
    	Test.startTest();
    	
    	globalTestData.facility2.Lead_Time__c = 2;
    	globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
        update globalTestData.facility2;
        
        //Populating Transit Route Calendar so that it can be picked over the Facility Calendar as per KNDY#4713
        globalTestData.transitRoute.Shipping_Calendar__c = [select Id from BusinessHours where isDefault = true limit 1].Id;  
        globalTestData.transitRoute.Delivery_Method__c = 'Pickup';      
        update globalTestData.transitRoute;       
             
        // Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
        
        List<Shipment_Line__c> shipmentLines = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
                                                       Location__r.Facility__r.Shipping_Calendar__c
	        									  from Shipment_Line__c 
	        									 where Sales_Order_Line__c IN :globalTestData.salesOrderLines];
	        									 
        for(Shipment_Line__c shipmentLine : shipmentLines){
        	// The facility lead time is 2 days   
        	system.assertEquals(KSE.calculateEndDate(system.today(), 2, globalTestData.transitRoute.Shipping_Calendar__c), shipmentLine.Shipment__r.Shipment_Date_Estimated__c);
        	// The transit time is another 2 days
        	system.assertEquals(KSE.nextBusinessDate(shipmentLine.Shipment__r.Shipment_Date_Estimated__c, 2, globalTestData.transitRoute.Shipping_Calendar__c), shipmentLine.Shipment__r.Estimated_Delivery_Date__c);
        }       
        
        Test.stopTest();
    }
    static testMethod void testSetDeliveryMethod(){
    	    	
    	Test.startTest();
    	
    	// Create a new means of transport
    	Means_of_Transport__c newMot = globalTestData.newMeansOfTransport('AIR', 'Air');
		insert newMot;
		
		globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
		update globalTestData.facility2;
				
    	// Create a new secondary transit route.
    	Transit_Route__c secondaryTransitRoute = new Transit_Route__c();
    	secondaryTransitRoute.Destination__c = globalTestData.customerShipTo.Address__c;
		secondaryTransitRoute.Origin__c = globalTestData.facility2.Address__c;
		secondaryTransitRoute.Means_of_Transport__c = newMot.Id;
		secondaryTransitRoute.Transit_Time__c = 2;
		secondaryTransitRoute.Delivery_Method__c = 'Delivery';
		
		// Set the existing transit route as Primary
    	globalTestData.transitRoute.Primary__c = true;
    	
    	upsert new List<Transit_Route__c>{globalTestData.transitRoute, secondaryTransitRoute};
    	
    	Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
        salesOrderLine.Product__c = globalTestData.product.Id;
        salesOrderLine.Company__c = globalTestData.company.id;
        salesOrderLine.Sales_Order__c = globalTestData.salesOrder.Id;
        salesOrderLine.Quantity_Ordered__c = 5;
        salesOrderLine.Required_Date__c = System.today() + 5;
        salesOrderLine.Ship_From_Location__c = globalTestData.location.Id;
        insert salesOrderLine;
    	
    	Sales_Order__c salesOrder = [select Id, Means_of_Transport__c, Delivery_Method__c
    								   from Sales_Order__c 
    								  where Id = :globalTestData.salesOrder.Id];
    								  
		system.assertEquals(globalTestData.meansOfTransport.Id, salesOrder.Means_of_Transport__c);
		system.assertEquals(secondaryTransitRoute.Delivery_Method__c, salesOrder.Delivery_Method__c);   
				    							  
    	Test.stopTest();
    }
    
    static testMethod void test_if_transitroute_error(){    	
    	
    	Test.startTest();   
    	
    	globalTestData.facility2.Enable_Transit_Route_Optimization__c = true;
    	update globalTestData.facility2;
    	
		globalTestData.transitRoute.Primary__c = true;    	
    	update globalTestData.transitRoute;
    	
    	globalTestData.salesOrder.Delivery_Method__c = 'Pickup';
    	update globalTestData.salesOrder;
    	
    	Sales_Order__c salesOrder = [select Id, Delivery_Method__c, Means_of_Transport__c, Required_Date__c from Sales_Order__c where Id =:globalTestData.salesOrder.Id];
    	  
    	system.assert(salesOrder.Delivery_Method__c != null, 'The delivery method on Sales Order is null');    	
    	    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
         
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        String msg1;
        boolean hasmsg = false;
        
        for(Apexpages.Message msg : msgs){
          	msg1 = String.valueOf(msg);
          	
          	if (msg1.contains(ExceptionUtil.NO_MATCHING_TRANSIT_ROUTE_FOUND.label)){
                hasmsg = true;
        	}
    	}
    	
        system.assert(hasmsg, 'Plan should have failed as no matching Transit Routes are defined:' + hasmsg);
    	
    	Task overrideTask = new Task();
    	overrideTask.WhatId = salesOrder.Id;
    	overrideTask.Exception_Code__c = ExceptionUtil.NO_MATCHING_TRANSIT_ROUTE_FOUND.code;
	    overrideTask.Status = 'Overridden';
	    overrideTask.Subject = ExceptionUtil.NO_MATCHING_TRANSIT_ROUTE_FOUND.label;
	    overrideTask.Type = ExceptionUtil.NO_MATCHING_TRANSIT_ROUTE_FOUND.typeName;
	    overrideTask.Primary_Key__c = '' + overrideTask.WhatId + overrideTask.Exception_Code__c;
	    upsert overrideTask Primary_Key__c;
	    
	    ExceptionService.messages.clear();
	    
	    soReleaseExt.plan();
        
        system.assert(ExceptionService.hasErrors == false, 
        		'Plan should have passed as we have overridden no matching Transit Routes exception: ' 
        		+ ExceptionService.messages);
	    
    	Test.stopTest();
    }
    
    static testMethod void test_if_transitroutes_noerror() {
    	
    	Test.startTest();
    	
    	List <Transit_Route__c> transitroute = [select Id  from Transit_Route__c limit 2];
        system.assert(transitroute.size() == 0, 'Transit Routes are present'+transitroute.size());  
    	
    	globalTestData.facility2.Enable_Transit_Route_Optimization__c = false;
    	update globalTestData.facility2;
    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
        system.assertEquals( false, soReleaseExt.hasErrors , Apexpages.getMessages() );        
        
        Test.stopTest();
    }
    */
    static testMethod void testHoliday(){
    	Date holiday = Date.newInstance(2014, 10, 02);
        Date nextWorkingDay = Date.newInstance(2014, 10, 03);
        
        User user = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        
        system.runAs(user){    	
	    	Holiday hol = new Holiday();
			hol.Name='Test holiday';
			hol.activitydate = holiday;
			insert hol;
        }
    	
        BusinessHours defaultBH = [Select Id From BusinessHours Where IsDefault = True];
		
        while(KSE.isBusinessDay(defaultBH.Id, holiday) == false){
            holiday = holiday.addDays(1);
        }
        
        system.assertEquals(nextWorkingDay, holiday); 
    }
    
    //static testMethod void cannotFinalizedUnconfirmedShipment()
    //{
    //	//TestFuel fuel = new TestFuel();
    //    List<Period__c> periodList = globalTestData.periodList;
        
    //    Sales_Order__c salesOrder = globalTestData.salesOrder;
        
    //    List<SKID__c> skids = globalTestData.skids;    
    //    List<Stock_Movement_Rule_Settings__c> smrsList = globalTestData.smrsList;
    //    List<Stock_Movement_Rule__c> stockMovementRuleList = globalTestData.stockMovementRuleList;
            
        
        
    //    ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
    //    SOPlanExt soPlanExt = new SOPlanExt(con);
    //    soPlanExt.plan();
    //    System.assertEquals(false, soPlanExt.hasErrors);
        
    //    Shipment_Line__c shl = [select Id, Shipment__r.Estimated_Delivery_Date__c, Shipment__r.Shipment_Date_Estimated__c,
    //                                                   Location__r.Facility__r.Shipping_Calendar__c, Shipment__c, Shipment__r.Status__c
	   //     									  from Shipment_Line__c 
	   //     									 where Sales_Order_Line__c IN :globalTestData.salesOrderLines limit 1];
	   // system.assert(shl.Shipment__r.Status__c == 'Planned');    									 
	   // Shipment__c sh = new Shipment__c(Id = shl.Shipment__c, Status__c = shl.Shipment__r.Status__c );
	    
	   // sh.Finalized__c = true;
	   // try
	   // {
	   // 	update sh;
	   // }catch(Exception ex)
	   // {
	   // 	system.assert(ex.getMessage().contains(Label.CannotFinalizeUnconfirmedShipments));
	   // }
	    
	   // sh = [Select id, Status__c, Finalized__c from Shipment__c where id = :sh.Id limit 1];
	   // system.assert(sh.Finalized__c == false,'Finalized is: '+sh.Finalized__c);
	    
	        									 
    	
    //}
}