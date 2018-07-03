/**
 * This class contains unit tests for validating the behavior of ShipmentDatesBatch.cls
 */
@isTest
private class ShipmentDatesBatchTest {
	static TestFuel globalTestData = new TestFuel();
	
	static testMethod void testShipmentDatesBatchWithoutRequiredDate() {
        
        system.assert(globalTestData.salesOrder.Id != null);

        Test.startTest();
        
        globalTestData.salesOrder.Means_of_Transport__c = globalTestData.meansOfTransport.Id;
    	update globalTestData.salesOrder;
    	
    	globalTestData.facility2.Lead_Time__c = 2;
    	update globalTestData.facility2;
    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
    	
    	Map<Id, Shipment__c> plannedShipments = new Map<Id, Shipment__c>();
    	
    	// Get the planned shipment for the sales order.
    	for(Shipment_Line__c shipmentLine : [select Id, Shipment__c, Shipment__r.Shipment_Date_Estimated__c 
											   from Shipment_Line__c 
										      where Sales_Order_Line__c IN :globalTestData.salesOrderLines]){
	   		plannedShipments.put(shipmentLine.Shipment__c, shipmentLine.Shipment__r);
	   	}
	    
        system.assert(plannedShipments.size() > 0);
		
		// Expire the estimated shipment date
		for(Shipment__c shipment : plannedShipments.values()){
			shipment.Shipment_Date_Estimated__c = null;
		}
		
		update plannedShipments.values();
		
		ShipmentDatesBatch batchInstance = new ShipmentDatesBatch();
		batchInstance.runBatch(globalTestData.company.Id);
		
		// Finish executing the batch
		Test.stopTest();
		
		for(Shipment_Line__c shipmentLine : [select Id, Shipment__c, Shipment__r.Shipment_Date_Estimated__c 
											   from Shipment_Line__c 
										      where Sales_Order_Line__c IN :globalTestData.salesOrderLines]){
	   		system.assert(shipmentLine.Shipment__r.Shipment_Date_Estimated__c >= system.today());
	   	}
    }
    
    static testMethod void testShipmentDatesBatchWithRequiredDate() {
        
        system.assert(globalTestData.salesOrder.Id != null);

        Test.startTest();
        
        Date requiredDate = system.today() + 7;
    	
    	globalTestData.salesOrder.Required_Date__c = requiredDate;
    	globalTestData.salesOrder.Means_of_Transport__c = globalTestData.meansOfTransport.Id;
    	update globalTestData.salesOrder;
    	
    	globalTestData.facility2.Lead_Time__c = 2;
    	update globalTestData.facility2;
    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
    	
    	Map<Id, Shipment__c> plannedShipments = new Map<Id, Shipment__c>();
    	
    	// Get the planned shipment for the sales order.
    	for(Shipment_Line__c shipmentLine : [select Id, Shipment__c, Shipment__r.Shipment_Date_Estimated__c 
											   from Shipment_Line__c 
										      where Sales_Order_Line__c IN :globalTestData.salesOrderLines]){
	   		plannedShipments.put(shipmentLine.Shipment__c, shipmentLine.Shipment__r);
	   	}
	    
        system.assert(plannedShipments.size() > 0);
		
		// Expire the estimated shipment date
		for(Shipment__c shipment : plannedShipments.values()){
			shipment.Shipment_Date_Estimated__c = null;
		}
		
		update plannedShipments.values();
		
		ShipmentDatesBatch batchInstance = new ShipmentDatesBatch();
		batchInstance.runBatch(globalTestData.company.Id);
		
		// Finish executing the batch
		Test.stopTest();
		
		for(Shipment_Line__c shipmentLine : [select Id, Shipment__c, Shipment__r.Shipment_Date_Estimated__c 
											   from Shipment_Line__c 
										      where Sales_Order_Line__c IN :globalTestData.salesOrderLines]){
	   		system.assert(shipmentLine.Shipment__r.Shipment_Date_Estimated__c >= system.today());
	   	}
    }
    
    static testMethod void testShipmentDatesBatchWithShortRequiredDate() {
        
        system.assertNotEquals(null, globalTestData.salesOrder.Id, 'globalTestData.salesOrder: ' + globalTestData.salesOrder); //KNDY-4989

        Test.startTest();
        
        Date requiredDate = system.today() + 7;
    	
    	globalTestData.salesOrder.Required_Date__c = requiredDate;
    	globalTestData.salesOrder.Means_of_Transport__c = globalTestData.meansOfTransport.Id;
    	update globalTestData.salesOrder;
    	
    	globalTestData.facility2.Lead_Time__c = 2;
    	update globalTestData.facility2;
    	
    	// Release the sales order to check if the dates are being populated.
    	ApexPages.StandardController sc = new ApexPages.StandardController(globalTestData.salesOrder);
    	SOPlanExt soReleaseExt = new SOPlanExt(sc);
    	soReleaseExt.plan();
    	
    	globalTestData.salesOrder.Required_Date__c = system.today();
    	update globalTestData.salesOrder;
    	
    	Map<Id, Shipment__c> plannedShipments = new Map<Id, Shipment__c>();
    	
    	// Get the planned shipment for the sales order.
    	for(Shipment_Line__c shipmentLine : [select Id, Shipment__c, Shipment__r.Shipment_Date_Estimated__c 
											   from Shipment_Line__c 
										      where Sales_Order_Line__c IN :globalTestData.salesOrderLines]){
	   		plannedShipments.put(shipmentLine.Shipment__c, shipmentLine.Shipment__r);
	   	}
	    
	    //KNDY-4989
        system.assert(plannedShipments.size() > 0, 'exp: plannedShipments.size() > 0.  act: '+ plannedShipments.size() + ' *** gtd.sol.size: '+ globalTestData.salesOrderLines.size() + ' *** gtd.sol'+globalTestData.salesOrderLines);
		
		// Expire the estimated shipment date
		for(Shipment__c shipment : plannedShipments.values()){
			shipment.Shipment_Date_Estimated__c = null;
			shipment.Planned_Delivery_Date__c = system.today();
		}
		
		ExceptionService.ignoreSet.add('Shipment__c');
		update plannedShipments.values();
		ExceptionService.ignoreSet.remove('Shipment__c');
		
		ShipmentDatesBatch batchInstance = new ShipmentDatesBatch();
		batchInstance.runBatch(globalTestData.company.Id);
		
		// Finish executing the batch
		Test.stopTest();
		
		for(Shipment_Line__c shipmentLine : [select Id, Sales_Order_Line__r.Sales_Order__r.Has_Exceptions__c, Shipment__r.Shipment_Date_Estimated__c, Shipment__r.Planned_Delivery_Date__c,
													Shipment__r.Has_Exceptions__c 
											   from Shipment_Line__c 
										      where Sales_Order_Line__c IN :globalTestData.salesOrderLines]){
			
			//OTC-266
			system.assertEquals(system.today(), shipmentLine.Shipment__r.Shipment_Date_Estimated__c, 'shipmentLine: '+ shipmentLine);
	   	}
    }
}