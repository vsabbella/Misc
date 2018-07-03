/**
 * This class contains unit tests for validating the behavior of methods in SOPlanExt.cls
 * and triggers.
 */
@isTest
private class ShipmentPlanExtTest {
	
	static testMethod void testShipmentPlanExt() {
		
		TestData globalTestData = new TestData();
        ApexPages.StandardController con;
        ShipmentPlanExt planExt;
        
        Test.startTest();
        
        con = new ApexPages.StandardController(globalTestData.facility);
        planExt = new ShipmentPlanExt(con);
        
        system.assert( planExt.salesOrderLinesGridConfig != null );
        system.assert( planExt.fulfillmentLinesGridConfig != null );
        
        system.assert( planExt.getSalesOrderLineFieldList().length() > 0 );
        system.assert( planExt.getFulfillmentLinesFieldList().length() > 0 );
        
        system.assert( planExt.getSalesOrderLinesGridConfigJson() != null );
        system.assert( planExt.getFulfillmentLinesGridConfigJson() != null );
        
        Test.stopTest();
        
    }
    
    static testMethod void testPlan() {
    	TestData globalTestData = new TestData();
        
        globalTestData.customerShipTo.Aggregate_Shipments__c = true; 
        update globalTestData.customerShipTo;
        
        globalTestData.salesOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_SHIPMENT;
        update globalTestData.salesOrder;
        
        ApexPages.StandardController con = new ApexPages.StandardController(globalTestData.salesOrder);
        SOPlanExt planExt = new SOPlanExt(con);            
        planExt.plan();
        
        System.assertEquals(false, planExt.hasErrors);
        
        List<Shipment_Line__c> shlLines = [select Id 
        									 from Shipment_Line__c 
        									where Sales_Order_Line__r.Sales_Order__c = :globalTestData.salesOrder.Id ];
        									
        system.assertEquals(0, shlLines.size(), 'No shipment lines should have been created.');
        
        Test.startTest();
        
        JsonResult result = ShipmentPlanExt.getSalesOrderLines(new List<String>());
        System.assertEquals(true, result.success);
        System.assertEquals(1, result.total, 'Expected to return one group of sales order lines.');
        
        List<ShipmentPlanExt.PlanWrapper> planWrapperList = (List<ShipmentPlanExt.PlanWrapper>) result.records;
        
        System.assertEquals(2, planWrapperList[0].linesToPlan.size(), 'Expected to return two open sales order lines.');
        
        // Select only one sales order line
        planWrapperList[0].linesToPlan.remove(1);
        
        // (Estimated ship date based on sales order required date)
        planWrapperList[0].selectedPlan.Shipment_Date_Estimated__c = system.today().addDays(2); 
        
        JsonResult planResult = ShipmentPlanExt.plan(planWrapperList);
        System.assertEquals(true, planResult.success);
        
        shlLines = [select Id, Shipment__c
					  from Shipment_Line__c 
					 where Sales_Order_Line__r.Sales_Order__c = :globalTestData.salesOrder.Id ];
        									
        system.assertEquals(1, shlLines.size(), 'One shipment line should have been created.');
     	
     	result = ShipmentPlanExt.getSalesOrderLines(new List<String>());
        System.assertEquals(true, result.success);
        System.assertEquals(1, result.total, 'Expected to return one sales order lines.'); 
        
        planWrapperList = (List<ShipmentPlanExt.PlanWrapper>) result.records;
        
        System.assertEquals(1, planWrapperList[0].linesToPlan.size(), 'Expected to return one open sales order lines.');
        
        planWrapperList[0].selectedPlan = new Shipment__c(Id = shlLines[0].Shipment__c);
        
        planResult = ShipmentPlanExt.plan(planWrapperList);
        System.assertEquals(true, planResult.success);  
        
        shlLines = [select Id, Shipment__c
					  from Shipment_Line__c 
					 where Shipment__c = :shlLines[0].Shipment__c ];
        									
        system.assertEquals(2, shlLines.size(), 'Two shipment lines should have been created.');
        
        result = ShipmentPlanExt.getSalesOrderLines(new List<String>());
        System.assertEquals(true, result.success);
        System.assertEquals(0, result.total, 'Expected to return no sales order lines.'); 
    }
    
}