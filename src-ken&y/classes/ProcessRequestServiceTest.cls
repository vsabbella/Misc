@isTest
public class ProcessRequestServiceTest {
    static TestFuel fuel = new TestFuel();
    
    class TestData{
    	
    	public TestData(){
	    	
	    	List<Stock_Movement_Rule_Settings__c> smrsList = fuel.smrsList;
	        List<Stock_Movement_Rule__c> stockMovementRuleList = fuel.stockMovementRuleList;
	
	        fuel.company.Serial_Control__c = 'At receipt and all processes';
	        update fuel.company;
	
	        Sales_Order__c so = fuel.salesOrder;
	
	        for (Sales_Order_Line__c sol:fuel.salesOrderLines) {
	            sol.Quantity_Ordered__c = 5;
	        }
	        update fuel.salesOrderLines;
	
	        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
	        for (Item__c item:fuel.itemList) {
	            item.Item_Attribute__c = fuel.itemAttrObj2.Id;
	            lots.put(item.Id,new Lot__c(
	                Name = item.Name,
	                Company__c = fuel.company.Id,
	                Item__c = item.Id
	            	)
	            );
	        }
	        update fuel.itemList;
	        insert lots.values();
	
	        List<Serial__c> serials = new List<Serial__c>();
	        for (SKID__c skid : fuel.skids) {
	            skid.Quantity__c = 5;
	            skid.Lot__c = lots.get(skid.Item__c).Id;
	
	            for (Integer i=0;i<5;i++) {
	                serials.add(new Serial__c(
	                    Name = '' + skid.Item__c + skid.Location__c + i,
	                    Company__c = fuel.company.Id,
	                    Item__c = skid.Item__c,
	                    SKID__c = skid.Id,
	                    Unique_Key2__c = fuel.company.Id + '-' + skid.Item__c + '-' + skid.Item__c + skid.Location__c + i
	                ));
	            }
	        }
	        update fuel.skids;
	        insert serials;
	
	        new SalesOrderService().plan(so.id);
	
	        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
	        shlQuery.addAllCustomFields();
	        shlQuery.addAllCustomFields(Shipment__c.sObjectType,'Shipment__r');
	        shlQuery.setWhereClause('Sales_Order__c = \'' + so.Id + '\'');
	
	        List<Shipment_Line__c> shipmentLines = Database.query(shlQuery.getQuery());
	        Shipment__c shipment = shipmentLines[0].Shipment__r;
	        System.assert(shipmentLines.size() == 2,shipmentLines);

            Map<Id, Shipment_Line__c> shlMap = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
            List<LineWrapper> wrappers = AllocationService.getInventory(shlMap.values());
            for (LineWrapper wrapper:wrappers) {
                wrapper.line = shlMap.get(wrapper.line.Id);
                wrapper.header = wrapper.line.getSObject('Shipment__r');
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    if (sw.skid.Location__c == fuel.location3.Id) {
                        sw.skid.Input_Quantity__c = 5;
                    } else {
                        sw.skid.Input_Quantity__c = 0;
                    }
                    sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
                }
            }
            AllocationService.allocate(wrappers);

            shlMap = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
            wrappers = ShipmentInventoryService.getInventoryForPlan(shlMap.values());
            for (LineWrapper wrapper:wrappers) {
                wrapper.line = shlMap.get(wrapper.line.Id);
                wrapper.header = wrapper.line.getSObject('Shipment__r');
                for (SkidService3.SerialWrapper sw:wrapper.serialWrappers) {
                    sw.skid.Input_Quantity__c = 5;
                    sw.skid.Item__r = (Item__c)wrapper.line.getSObject('Item__r');
                }
            }
            
            Test.startTest();
            
            ShipmentInventoryService.plan(wrappers);
    	}
    }

    public static testMethod void testCycleCount() {
    	
    	system.assert(      
            fuel.company != null &&
            fuel.stockMovementRuleList != null &&
            fuel.smrsList != null &&
            fuel.itemList != null &&
            fuel.itemAttrObj != null &&
            fuel.itemAttrObj2 != null &&
            fuel.bin != null &&
            fuel.location != null
        );
        
        fuel.company.Serial_Control__c = 'At receipt and all processes';
        update fuel.company;
	         
        TestFuelQuery fuelQuery = new TestFuelQuery();
        test.StartTest();
        User_Preference__c up = new User_Preference__c( ownerId = UserInfo.getUserId(), name = 'my preference', default_company__c = fuelQuery.company.Id, default_facility__c = fuelQuery.facility2.Id );
        insert up; 
         
        Lot__c lot = new Lot__c(Name = '1234');
        lot.Company__c = fuelQuery.company.Id;
        lot.Item__c = fuelQuery.itemList[0].Id;
        lot.Expiration_Date__c = system.today() + 10;
        insert lot;
         
        SKID__c skid = new SKID__c(
            Facility2__c = fuelQuery.facility2.Id,
            Location__c = fuelQuery.location3.Id,
            Quantity__c = 200.0,
            Quantity_Stocking_UOM__c = 200.0,
            Stocking_UOM__c= fuelQuery.itemList[0].Stocking_UOM__c,
            Packaging_UOM__c = fuelQuery.itemList[0].Stocking_UOM__c,
            Container_Item__c = fuelQuery.itemList[0].Id,
            Item__c = fuelQuery.itemList[0].Id,
            Type__c = 'Location',
            Company__c = fuelQuery.company.Id,
            //Date_Received__c = system.today(),
            Expiration_Date__c = system.today() + 10,
            Bin__c = fuelQuery.bin.Id,
            Lot__c = lot.Id
        );
        insert skid;   
       
        Reason_Code__c rCode = new Reason_Code__c();
        rCode.Name = 'Cycle Count';
        rCode.Type__c = 'Cycle Count';
        insert rCode;
        
        DateTime transactionDate = datetime.now();
        
        Process_Request__c pr = new Process_Request__c(); 
        pr.Process_Call__c = 'Cycle Count';
        pr.Status__c = 'Ready';
        
        pr.Reason_Code__c = rCode.Id;
        pr.Transaction_Date__c = transactionDate;
        
        pr.Company__c = fuelQuery.company.Id;
        pr.Facility__c = fuelQuery.facility2.Id;
        pr.Location__c = fuelQuery.location3.Id;
        pr.Item__c = fuelQuery.itemList[0].Id;
        pr.Count_Quantity__c = 201;
        pr.Date_Received__c = system.today();
        pr.Expiration_Date__c = system.today() + 10;
        pr.Lot_Number__c = '1234';
        pr.Packaging_UOM__c = fuelQuery.itemList[0].Stocking_UOM__c;
        pr.Bin__c = fuelQuery.bin.Id;
    	pr.Status__c = 'Ready';
    	
		insert pr;
        
        List<Process_Request__c> processRequests = [SELECT Id, Has_Exceptions__c, 
						    						 	  (SELECT Id, Subject, Description 
						    						 	  	 FROM Tasks 
						    						 	  	WHERE Type = 'Exception')
						    						 FROM Process_Request__c];
    						 
    	for(Process_Request__c prqst : processRequests){					 
    		system.debug(LoggingLevel.INFO, prqst.Tasks);
    	}
    	
    	system.assertEquals(1, processRequests.size(), 'The process requests should have failed.');
    	system.debug(LoggingLevel.INFO, fuelQuery.bin.Id);
    	
    	pr.Date_Received__c = null;
    	pr.Status__c = 'Ready';
        update pr;
        
        processRequests = [SELECT Id, Has_Exceptions__c, Bin__c,
						    						 	  (SELECT Id, Subject, Description 
						    						 	  	 FROM Tasks 
						    						 	  	WHERE Type = 'Exception')
						    						 FROM Process_Request__c];
    						 
    	for(Process_Request__c prqst : processRequests){					 
    		system.debug(LoggingLevel.INFO, prqst.Bin__c);
    		system.debug(LoggingLevel.INFO, prqst.Tasks);
    	}
    	
    	system.assertEquals(0, processRequests.size(), 'The process requests should have been deleted.');
    	
        list<SKID__c> skidList = [select Id, Item__c, Quantity__c from SKID__c where Id = :skid.Id];
        system.assertEquals(1, skidList.size());
        system.assertEquals(201, skidList[0].Quantity__c, skidList);
        system.assertEquals(fuelQuery.ItemList[0].Id, skidList[0].Item__c, skidList);
        
        list<Inventory_Transaction__c> inventoryTransactionList = [select id, Quantity__c from Inventory_Transaction__c];
        system.assertEquals(1, inventoryTransactionList.size());
        system.assertEquals(1, inventoryTransactionList[0].Quantity__c, inventoryTransactionList);
        
        list<Inventory_Change__c> inventoryChangeList = [select id, Computer_Quantity__c, Count_Quantity__c, Item__c, Type__c, Transaction_Date__c from Inventory_Change__c];
        system.assertEquals(1, inventoryChangeList.size());
        system.assertEquals('Cycle Count', inventoryChangeList[0].Type__c);
        system.assertEquals(transactionDate, inventoryChangeList[0].Transaction_Date__c);    
        test.StopTest();    
    }
}