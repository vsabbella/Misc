@IsTest
private class ScannerServiceTest {
	private static TestFuelQuery fuelQuery = new TestFuelQuery();
	private static UOM__c eachUOM;
    private static UOM__c caseUOM;
    private static UOM__c palletUOM;
	private static Item__c palletItem;
	private static Item__c caseItem;
	private static Item__c testItem;

    @testSetup
    private static void setupData() {
        DML.systemTime = system.now().addHours(-2);
        List<Configuration__c> configList = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Inventory_Transaction__c.sObjectType,UOM__c.sObjectType,SKID__c.sObjectType,LPN__c.sObjectType,Item_Attribute__c.sObjectType,Inventory_Change__c.sObjectType,Receipt_Line__c.sObjectType,Company__c.sObjectType,Payment_Term__c.sObjectType,
            Pricebook__c.sObjectType,Pricebook_Line__c.sObjectType,Sales_Order__c.sObjectType,Purchase_Order__c.sObjectType,Purchase_Order_Line__c.sObjectType,Receiving_Document__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            configList.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert configList;
        TestFuel fuel = new TestFuel();
        System.assert(
	        fuel.bin != null && 
	        fuel.smrsList != null && 
	        fuel.stockMovementRuleList != null && 
	        fuel.workOrder != null && 
	        fuel.itemAttrObj2 != null &&
	        fuel.company != null &&
            fuel.itemList != null &&
            fuel.itemAttrObj != null &&
            fuel.location != null &&
            fuel.periodList != null &&
            fuel.packageSalesOrder != null
	    );
	    
	    User_Preference__c userDefaults = new User_Preference__c(
    		Default_Company__c = fuelQuery.company.Id,
    		Default_Facility__c = fuelQuery.facility2.Id,
    		User__c = UserInfo.getUserId()
    	); 
    	
    	insert userDefaults;
    	
    	List<Stock_Movement_Rule_Settings__c> smrsList = new List<Stock_Movement_Rule_Settings__c>();
        
        Stock_Movement_Rule_Settings__c smrs = new Stock_Movement_Rule_Settings__c();
        smrs.Name = 'Transfer - Company';
        smrs.Source_Document__c = 'Transfer';
		smrs.Stock_Movement_Rule_Field__c = 'Company__c';
        smrs.Source_Document_Path__c = 'Company__c';
        smrs.Source_Document_Path_Putaway__c ='Company__c';
        smrsList.add(smrs);
        
        Stock_Movement_Rule_Settings__c smrs2 = new Stock_Movement_Rule_Settings__c();
        smrs2.Name = 'Transfer - Facility';
        smrs2.Source_Document__c = 'Transfer';
		smrs2.Stock_Movement_Rule_Field__c = 'Facility__c';
        smrs2.Source_Document_Path__c = 'Facility__c';
        smrs2.Source_Document_Path_Putaway__c ='Facility__c';
        smrsList.add(smrs2);
        
        Stock_Movement_Rule_Settings__c smrs3 = new Stock_Movement_Rule_Settings__c();
        smrs3.Name = 'Transfer - Item';
        smrs3.Source_Document__c = 'Transfer';
		smrs3.Stock_Movement_Rule_Field__c = 'Item__c';
        smrs3.Source_Document_Path__c = 'Item__c';
        smrs3.Source_Document_Path_Putaway__c ='Item__c';
        smrsList.add(smrs3);
        
        Stock_Movement_Rule_Settings__c smrs4 = new Stock_Movement_Rule_Settings__c();
        smrs4.Name = 'Transfer - Location';
        smrs4.Source_Document__c = 'Transfer';
		smrs4.Stock_Movement_Rule_Field__c = 'Location__c';
        smrs4.Source_Document_Path__c = 'Location__c';
        smrs4.Source_Document_Path_Putaway__c ='Location__c';
        smrsList.add(smrs4);
        
        insert smrsList;
        
    	Stock_Movement_Rule__c stockMovement9 = new Stock_Movement_Rule__c();
        stockMovement9.Name = 'Transfer - Putaway';
        stockMovement9.Rule_Type__c = 'Putaway';
        stockMovement9.Company__c = fuelQuery.company.id;
        stockMovement9.Facility__c = fuelQuery.facility2.id;
        stockMovement9.Class__c = fuelQuery.clsObj.id;
        stockMovement9.Item__c = null;
        stockMovement9.Customer__c = null;
        stockMovement9.Source_Document__c = 'Transfer';
        stockMovement9.Source_Location__c = fuelQuery.location6.Id;
        stockMovement9.Priority__c = 1;
        stockMovement9.Location_List__c = JSON.serialize(new List<Id>{fuelQuery.location3.id});
        stockMovement9.Active__c = true;

        insert stockMovement9; 
        
        Package_Class__c eachClass = new Package_Class__c(Name = getUniqueName('Each'), Level__c = 1);
    	Package_Class__c caseClass = new Package_Class__c(Name = getUniqueName('Case'), Level__c = 2);
    	Package_Class__c palletClass = new Package_Class__c(Name = getUniqueName('Pallet'), Level__c = 3);
    	 
    	insert new List<Package_Class__c>{eachClass, caseClass, palletClass};
    	 
    	eachUOM = new UOM__c(Name = getUniqueName('Each'), Package_Class__c = eachClass.Id);
    	caseUOM = new UOM__c(Name = getUniqueName('Case'), Package_Class__c = caseClass.Id);
    	palletUOM = new UOM__c(Name = getUniqueName('Pallet'), Package_Class__c = palletClass.Id);
    	
    	insert new List<UOM__c>{eachUOM, caseUOM, palletUOM};
    	
    	String palletUOMShort = String.valueOf(palletUOM.Id).substring(3, 15);
    	String caseUOMShort = String.valueOf(caseUOM.Id).substring(3, 15);
    	String eachUOMShort = String.valueOf(eachUOM.Id).substring(3, 15);
    	
    	UOM_Conversion_Details__c palletToCases = new UOM_Conversion_Details__c(
	    	Name = palletUOMShort + caseUOMShort,
	        UOM_1__c = palletUOM.Id,
	        UOM_1_Quantity__c = 1,
	        UOM_2__c = caseUOM.Id,
	        UOM_2_Quantity__c = 8.0,
	        Key_1__c = string.valueof(palletUOM.Id) + string.valueof(caseUOM.Id), 
	        Key_2__c = string.valueof(caseUOM.Id) + string.valueof(palletUOM.Id)
		);
        
        UOM_Conversion_Details__c casesToEaches = new UOM_Conversion_Details__c(
	    	Name = caseUOMShort + eachUOMShort,
	        UOM_1__c = caseUOM.Id,
	        UOM_1_Quantity__c = 1,
	        UOM_2__c = eachUOM.Id,
	        UOM_2_Quantity__c = 8.0,
	        Key_1__c = string.valueof(caseUOM.Id) + string.valueof(eachUOM.Id), 
	        Key_2__c = string.valueof(eachUOM.Id) + string.valueof(caseUOM.Id)
		);
        
        UOM_Conversion_Details__c palletToEaches = new UOM_Conversion_Details__c(
	    	Name = palletUOMShort + eachUOMShort,
	        UOM_1__c = palletUOM.Id,
	        UOM_1_Quantity__c = 1,
	        UOM_2__c = eachUOM.Id,
	        UOM_2_Quantity__c = 64.0,
	        Key_1__c = string.valueof(palletUOM.Id) + string.valueof(eachUOM.Id), 
	        Key_2__c = string.valueof(eachUOM.Id) + string.valueof(palletUOM.Id)
		);
		
		insert new List<UOM_Conversion_Details__c>{palletToCases, casesToEaches, palletToEaches};
        
    	Item_Attribute__c lpnAttr = new Item_Attribute__c(Name = getUniqueName('LPN'), License_Plate_Number__c = true);
    	insert lpnAttr;
    	
    	palletItem = new Item__c(
						Name = getUniqueName('Pallet Item'),
						Description__c = 'Pallet Item',
						Source__c = 'Purchased',
						Company__c = fuelQuery.company.id,
						Active__c = true,
						
						Item_Attribute__c = lpnAttr.Id,
						Container__c = true, 
						Container_Package_Class__c = palletClass.Id,
						Packaging_UOM__c = '["' + eachUOM.Id +'"]',
						Stocking_UOM__c = eachUOM.Id
					 );
					 
		caseItem = new Item__c(
						Name = getUniqueName('Case Item'),
						Description__c = 'Case Item',
						Source__c = 'Purchased',
						Company__c = fuelQuery.company.id,
						Active__c = true,
						
						Container__c = true, 
						Container_Package_Class__c = caseClass.Id,
						Packaging_UOM__c = '["' + eachUOM.Id +'"]',
						Stocking_UOM__c = eachUOM.Id
					 );			
		
		testItem = new Item__c(
    							Name = getUniqueName('Test Item'),
    							Description__c = 'Test Item',
    							Source__c = 'Purchased',
    							Company__c = fuelQuery.company.id,
    							Active__c = true,
    							
    							Container__c = false, 
    							Packaging_UOM__c = JSON.serialize(new List<String>{eachUOM.Id, caseUOM.Id, palletUOM.Id}),
    							Stocking_UOM__c = eachUOM.Id
    						 );
    						 
		insert new List<Item__c>{testItem, caseItem, palletItem};		
		
		caseClass.Default_Container_Item__c = caseItem.Id;
        palletClass.Default_Container_Item__c = palletItem.Id;
        update new List<Package_Class__c>{caseClass, palletClass};	 	 
        
        Reason_Code__c rCode = new Reason_Code__c();
        rCode.Name = 'Cycle Count';
        rCode.Type__c = 'Cycle Count';
        insert rCode;
        
        delete configList;
    }
	
    // FIXME: test case fails because of Pakcaging uom setup issues
    /*static testMethod void testWorkOrderComplete() {
        fuelQuery.components[0].Type__c = 'Kit';
        Component__c byproduct = fuelQuery.components[0].clone(false,true);
        byproduct.Component_Item__c = fuelQuery.itemList[1].Id;
        byproduct.Type__c = 'By-product';
        byproduct.Component_Sequence__c = null;
        fuelQuery.components.add(byproduct);
        upsert fuelQuery.components;

        List<Lot__c> lots = new List<Lot__c>{
                new Lot__c(Item__c=fuelQuery.itemList[0].Id,Name='LOT-1234',Company__c=fuelQuery.company.Id),
                new Lot__c(Item__c=fuelQuery.itemList[2].Id,Name='LOT-123',Company__c=fuelQuery.company.Id)
        };
        insert lots;

        update new Item_Attribute__c(Id = fuelQuery.itemAttrObj.Id,Serial_Number__c = true);

        WorkOrderPlanningService.release(new Set<Id>{fuelQuery.workOrder.Id});

        Work_Order__c wo = WorkOrderService.getWorkOrders(new Set<Id>{fuelQuery.workOrder.Id},null,null,new Set<String>{ 'Operation_Trackings__r', 'Material_Trackings__r' })[0];

        Id kitMaterial;
        for (Material_Tracking__c mt:wo.Material_Trackings__r) {
            if (mt.Type__c == 'Kit') {
                kitMaterial = mt.Id;
                break;
            }
        }

        Id operationId = wo.Operation_Trackings__r[0].Id;

        List<SKID__c> skids = new List<SKID__c>{
                new SKID__c(Facility2__c=fuelQuery.facility2.Id,Location__c=fuelQuery.location3.Id,Company__c=fuelQuery.company.Id,Quantity__c=100,Item__c=fuelQuery.itemList[0].Id,Type__c='Location',Lot__c=lots[0].Id,Expiration_Date__c=System.today()+365, Packaging_UOM__c=fuelQuery.uomList[8].Id, Stocking_UOM__c=fuelQuery.uomList[8].Id),
                new SKID__c(Facility2__c=fuelQuery.facility2.Id,Location__c=fuelQuery.location7.Id,Company__c=fuelQuery.company.Id,Quantity__c = 100,Item__c=fuelQuery.itemList[2].Id,Type__c='WIP',Lot__c=lots[1].Id,Expiration_Date__c=System.today()+365,Material_Tracking__c=kitMaterial, Packaging_UOM__c=fuelQuery.uomList[8].Id, Stocking_UOM__c=fuelQuery.uomList[8].Id)
        };
        insert skids;

        List<Serial__c> bfSerials = new List<Serial__c>();
        List<Serial__c> wipSerials = new List<Serial__c>();
        for (Integer i=0;i<100;i++) {
            bfSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuelQuery.itemList[0].Id,Company__c=fuelQuery.company.Id,SKID__c=skids[0].Id,Unique_Key2__c=fuelQuery.company.Id+'-'+fuelQuery.itemList[0].Id+'-'+'SERIAL'+i));
            wipSerials.add(new Serial__c(Name='SERIAL'+i,Item__c=fuelQuery.itemList[2].Id,Company__c=fuelQuery.company.Id,SKID__c=skids[1].Id,Unique_Key2__c=fuelQuery.company.Id+'-'+fuelQuery.itemList[2].Id+'-'+'SERIAL'+i));
        }
        insert bfSerials;
        insert wipSerials;

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>();
        params.put('woName', wo.Name.substring(4));
        params.put('caseQuantity', '001');
        params.put('caseNumber', '008');
        
        String paramString = JSON.serialize(params);

        ScannerService scannerService = new ScannerService();
        ScannerService.getWorkOrderCompleteData getWorkOrderCompleteData = new ScannerService.getWorkOrderCompleteData();
        Action.Response resp = getWorkOrderCompleteData.execute(paramString);

        Work_Order__c woTest = WorkOrderService.getWorkOrders(new Set<Id>{fuelQuery.workOrder.Id},null,null,new Set<String>{ 'Operation_Trackings__r', 'Material_Trackings__r' })[0];
		Test.stopTest();
		//DOIT: Uncomment
		//system.assertEquals(true, resp.success, resp);
		//system.assertNotEquals(0, woTest.Quantity_Complete__c, woTest);
    }*/
    
    static String getUniqueName(String name){
    	return name + ' - ' + fuelQuery.company.Id;
    }
    
    static testMethod void testPalletize(){
    	
    	fuelQuery.facility2.Default_Work_Order_Complete_to_Location__c = fuelQuery.location6.Id;
    	update fuelQuery.facility2;
    						 
    	LPN__c newLPN = new LPN__c(Name='1234567890');
        //insert newLPN;
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(testItem.Packaging_UOM__c, List<Id>.class);
        
        SKID__c inventorySkid = new SKID__c(
            						Facility2__c = fuelQuery.facility2.Id,
            						Location__c = fuelQuery.location6.Id, // Finished Goods
            						Company__c = fuelQuery.company.Id,
            						Quantity__c = 100,
            						Quantity_Stocking_UOM__c = 100 * KSE.getConversionFactor (testItem.Id,fuelQuery.facility2.Facility_Identifier__c, caseUOM.Id, eachUOM.Id, lstPkgUom  ),
            						Item__c = testItem.Id, 
            						Item__r = testItem,
            						Container_Item__c = caseItem.Id,
            						Type__c = 'Location', 
            						Packaging_UOM__c = caseUOM.Id, 
            						Stocking_UOM__c = eachUOM.Id
        						);
        
        insert inventorySkid;
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('itemId', testItem.Id);
        params.put('lpnName', newLPN.Name);
        params.put('quantity', 8);
        params.put('contents', new List<String>{'1','2','3','4','5','6', '7', '8'});        
        
        Test.startTest();
        String response = ScannerService.palletize(params);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
        
        Test.stopTest();
        system.assert(Boolean.valueOf(responseMap.get('success')) == true, response);
        
        List<SKID__c> skidList = [select Id, Item__c, Quantity__c, Packaging_UOM__c, License_Plate_Number__r.Name 
        							from SKID__c 
        						   where Item__c = :testItem.Id];
        						   
        system.assertEquals(2, skidList.size(), skidList);
        
        for(SKID__c skid : skidList){
        	if(skid.Packaging_UOM__c == caseUOM.Id){
        		system.assertEquals(92, skid.Quantity__c, skidList);
        	}else{
    			system.assertEquals(1, skid.Quantity__c, skidList);
    			system.assertEquals('1234567890', skid.License_Plate_Number__r.Name, skidList);
        	}
        }
        
        list<Inventory_Change__c> inventoryChangeList = [select id, Computer_Quantity__c, Count_Quantity__c, Item__c from Inventory_Change__c];
        system.assertEquals(1, inventoryChangeList.size());
    }
    
    static testMethod void testPutawayLPN(){
    	
    	fuelQuery.facility2.Default_Work_Order_Complete_to_Location__c = fuelQuery.location6.Id;
    	update fuelQuery.facility2;
    						 
    	LPN__c newLPN = new LPN__c(Name='1234567890');
        insert newLPN;
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, PAckaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(testItem.Packaging_UOM__c, List<Id>.class);
        
        SKID__c inventorySkid = new SKID__c(
            						Facility2__c = fuelQuery.facility2.Id,
            						Location__c = fuelQuery.location6.Id, // Finished Goods
            						Company__c = fuelQuery.company.Id,
            						Quantity__c = 1,
            						Quantity_Stocking_UOM__c = 1 * KSE.getConversionFactor (testItem.Id,fuelQuery.facility2.Facility_Identifier__c, palletUOM.Id, eachUOM.Id, lstPkgUom  ),
            						Item__c = testItem.Id, 
            						Item__r = testItem,
            						Container_Item__c = palletItem.Id,
            						Type__c = 'Location', 
            						Packaging_UOM__c = palletUOM.Id, 
            						Stocking_UOM__c = eachUOM.Id,
            						License_Plate_Number__c = newLPN.Id
        						);
        
        insert inventorySkid;
        
        fuelQuery.location3.Bin_Tracked__c = true;
        update fuelQuery.location3; 
        
        Bin__c bin = new Bin__c(
						Name = getUniqueName('Putaway Bin'),
                    	Description__c = 'bin',
                    	Location__c = fuelQuery.location3.id
          			 );
              
        insert bin;  
                
        Map<String, Object> params = new Map<String, Object>();
        params.put('lpnName', newLPN.Name);
        params.put('toBin', bin.Name);
        
        Test.startTest();
        
        ScannerService.transferInventory transferInventory = new ScannerService.transferInventory();
        Action.Response response = transferInventory.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(response.success == true, response);	
        
        String responseString = ScannerService.getLPN(params);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseString);
        
        system.assert(Boolean.valueOf(responseMap.get('success')) == true, responseString);	
        Decimal quantity = (Decimal) responseMap.get('quantity');
        system.assert(quantity == 8, quantity);	
    }
    
    static testMethod void testPutawayEaches(){
    	
    	fuelQuery.facility2.Default_Work_Order_Complete_to_Location__c = fuelQuery.location6.Id;
    	update fuelQuery.facility2;
    						 
    	LPN__c newLPN = new LPN__c(Name='1234567890');
        insert newLPN;
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(testItem.Packaging_UOM__c, List<Id>.class);
        
        SKID__c inventorySkid = new SKID__c(
            						Facility2__c = fuelQuery.facility2.Id,
            						Location__c = fuelQuery.location6.Id, // Finished Goods
            						Company__c = fuelQuery.company.Id,
            						Quantity__c = 7,
            						Quantity_Stocking_UOM__c = 7,
            						Item__c = testItem.Id, 
            						Item__r = testItem,
            						Container_Item__c = testItem.Id,
            						Type__c = 'Location', 
            						Packaging_UOM__c = eachUOM.Id, 
            						Stocking_UOM__c = eachUOM.Id
        						);
        
        insert inventorySkid;
        
        fuelQuery.location3.Bin_Tracked__c = true;
        update fuelQuery.location3; 
        
        Bin__c bin = new Bin__c(
						Name = getUniqueName('Putaway Bin'),
                    	Description__c = 'bin',
                    	Location__c = fuelQuery.location3.id
          			 );
              
        insert bin;  
                
        Map<String, Object> params = new Map<String, Object>();
        params.put('itemId', testItem.Id);
        params.put('toBin', bin.Name);
        //params.put('quantity', '7');
        
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        lineItems.add(new Map<String,Object>{'quantity'=> 7});
        params.put('lines', lineItems);
        
        Test.startTest();
        
        ScannerService.transferInventory transferInventory = new ScannerService.transferInventory();
        Action.Response response = transferInventory.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(response.success == true, response);	
        
        list<SKID__c> skidList = [select Id, Item__c, Quantity__c, Location__c, Packaging_UOM__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(1, skidList.size(), skidList);
        
    	system.assertEquals(fuelQuery.location3.Id, skidList[0].Location__c, skidList);
    	system.assertEquals(eachUOM.Id, skidList[0].Packaging_UOM__c, skidList);
		system.assertEquals(7, skidList[0].Quantity__c, skidList);
	}
    
    static testMethod void testPutawayCases(){
    	
    	fuelQuery.facility2.Default_Work_Order_Complete_to_Location__c = fuelQuery.location6.Id;
    	update fuelQuery.facility2;
    						 
    	LPN__c newLPN = new LPN__c(Name='1234567890');
        insert newLPN;
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(testItem.Packaging_UOM__c, List<Id>.class);
        
        SKID__c inventorySkidCases = new SKID__c(
            						Facility2__c = fuelQuery.facility2.Id,
            						Location__c = fuelQuery.location6.Id, // Finished Goods
            						Company__c = fuelQuery.company.Id,
            						Quantity__c = 7,
            						Quantity_Stocking_UOM__c = 7 * KSE.getConversionFactor (testItem.Id,fuelQuery.facility2.Facility_Identifier__c, caseUOM.Id, eachUOM.Id, lstPkgUom  ),
            						Item__c = testItem.Id, 
            						Item__r = testItem,
            						Container_Item__c = caseItem.Id,
            						Type__c = 'Location', 
            						Packaging_UOM__c = caseUOM.Id, 
            						Stocking_UOM__c = eachUOM.Id
        						);
        SKID__c inventorySkidEaches = new SKID__c(
            						Facility2__c = fuelQuery.facility2.Id,
            						Location__c = fuelQuery.location6.Id, // Finished Goods
            						Company__c = fuelQuery.company.Id,
            						Quantity__c = 12,
            						Quantity_Stocking_UOM__c = 12 ,
            						Item__c = testItem.Id, 
            						Item__r = testItem,
            						Container_Item__c = testItem.Id,
            						Type__c = 'Location', 
            						Packaging_UOM__c = eachUOM.Id, 
            						Stocking_UOM__c = eachUOM.Id
        						);
        insert new List<Skid__c> {inventorySkidCases, inventorySkidEaches};
        
        fuelQuery.location3.Bin_Tracked__c = true;
        update fuelQuery.location3; 
        
        Bin__c bin = new Bin__c(
						Name = getUniqueName('Putaway Bin'),
                    	Description__c = 'bin',
                    	Location__c = fuelQuery.location3.id
          			 );
              
        insert bin;  
                
        Map<String, Object> params = new Map<String, Object>();
        params.put('itemId', testItem.Id);
        params.put('toBin', bin.Name);
        
        List<Map<String, Object>> lineItems = new List<Map<String, Object>>();
        lineItems.add(new Map<String,Object>{'quantity'=> 7});
        lineItems.add(new Map<String,Object>{'quantity'=> 1 * KSE.getConversionFactor (testItem.Id,fuelQuery.facility2.Facility_Identifier__c, caseUOM.Id, eachUOM.Id, lstPkgUom  )});
        lineItems.add(new Map<String,Object>{'quantity'=> 1 * KSE.getConversionFactor (testItem.Id,fuelQuery.facility2.Facility_Identifier__c, caseUOM.Id, eachUOM.Id, lstPkgUom  )});
        params.put('lines', lineItems);
        
        Test.startTest();
        
        ScannerService.transferInventory transferInventory = new ScannerService.transferInventory();
        Action.Response response = transferInventory.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(response.success == true, response);	
        
        list<SKID__c> skidList = [select Id, Item__c, Quantity__c, Location__c, Packaging_UOM__c from SKID__c where Item__c = :testItem.Id AND Location__c = :fuelQuery.location3.Id];
        system.assertEquals(2, skidList.size(), skidList);
        
        for ( SKID__c skid : skidList ) {
            if ( skid.Packaging_UOM__c == eachUOM.Id) {
                system.assertEquals(7, skid.Quantity__c, skid);
            } else if ( skid.Packaging_UOM__c == caseUOM.Id) {
                system.assertEquals(2, skid.Quantity__c, skid);
            } else {
                system.assert(false, 'Invalid Packaging UOM found!');
            }
        }
	}
    
    static testMethod void testGetRecords(){ 
		
        Company__c company = fuelQuery.company;
        Facility__c fac = fuelQuery.facility2;
        Location__c loc = fuelQuery.location3;
        
        Map<String, Object> childQueryParams = new Map<String, Object>();
        
        childQueryParams.put('relationshipName', 'Locations__r');
        childQueryParams.put('queryFields', new List<String>{'Id', 'Name'});
        childQueryParams.put('sortFields', new Map<String, String>{'Id' => 'ASC', 'Name' => 'DESC'});
        childQueryParams.put('whereClause', 'Facility__c = \'' + fac.Id + '\'');
        childQueryParams.put('limitRows', 1);
        
        Map<String, Object> queryParams = new Map<String, Object>();
        
        queryParams.put('sObjectName', 'Facility__c');
        queryParams.put('queryFields', new List<String>{'Company__c', 'Name'});
        queryParams.put('sortFields', new Map<String, String>{'Company__c' => 'DESC'});
        queryParams.put('whereClause', 'Id = \'' + fac.Id + '\'');
        queryParams.put('enforceFLS', false);
        queryParams.put('searchRecycle', false);
        queryParams.put('children', new List<Map<String, Object>>{childQueryParams});
        
        try{
        	ScannerService.GetRecords getRecordsInstance = new ScannerService.GetRecords();
        	
        	Action.Response response = getRecordsInstance.execute(JSON.serialize(queryParams));
        	
        	Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(response));
        	system.assert(Boolean.valueOf(responseMap.get('success')) == true, response);
	        
	        Map<String, Object> results = (Map<String, Object>) responseMap.get('results');
	        
			Object recordsObject = JSON.deserializeUntyped((String) results.get('records'));
	        List<Object> records = (List<Object>) recordsObject;
	        system.assert(records.size() == 1, 'No records found: ' + JSON.serialize(responseMap));
	        
	        Map<String, Object> facility = (Map<String, Object>) records[0];
	        system.assert(facility.get('Id') == fac.Id, 'Record not found: ' + JSON.serialize(facility));
	    	system.assert(facility.get('Company__r') != null, 'The parent object/relationship is missing');
	    	
	    	Map<String, Object> locations = (Map<String, Object>) facility.get('Locations__r');
            List<Object> locationRecords = (List<Object>) locations.get('records');
	    	system.assert(locationRecords.size() > 0, 'The subquery did not return any results');
	    	
        }catch(Exception ex){
        	system.debug(LoggingLevel.INFO, ex);
        	system.assert(false, 'Unexpected exception: ' + ex.getStackTraceString());
        }
	}
	
	static testMethod void testGetInventory(){
		fuelQuery.facility2.Default_Work_Order_Complete_to_Location__c = fuelQuery.location6.Id;
    	update fuelQuery.facility2;
    					 
    	LPN__c newLPN = new LPN__c(Name='1234567890');
        insert newLPN;
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(testItem.Packaging_UOM__c, List<Id>.class);
        SKID__c inventorySkid = new SKID__c(
            						Company__c = fuelQuery.company.Id,
            						Facility2__c = fuelQuery.facility2.Id,
            						Location__c = fuelQuery.location3.Id, // Finished Goods Stock
            						Bin__c = fuelQuery.bin.Id,
            						Quantity__c = 100,
            						Quantity_Stocking_UOM__c=100 * KSE.getConversionFactor(testItem.id,fuelQuery.facility2.Facility_Identifier__c, palletUOM.Id, eachUOM.Id, lstPkgUom),
            						Item__c = testItem.Id, 
            						Item__r = testItem, 
            						Container_Item__c = caseItem.Id,
            						Type__c = 'Location', 
            						License_Plate_Number__c = newLPN.Id,
            						Packaging_UOM__c = palletUOM.Id, 
            						Stocking_UOM__c = eachUOM.Id
        						);
        
        insert inventorySkid;
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('Company__c', fuelQuery.company.Id);
        params.put('Facility__c', fuelQuery.facility2.Id);
        params.put('Location__c', fuelQuery.location6.Id);
        params.put('Item__c', testItem.Id);
        params.put('Source_Document__c', 'Transfer');
        params.put('Type__c', 'Putaway');
        Test.startTest();
        ScannerService.getInventory getInventory = new ScannerService.getInventory();
        Action.Response response = getInventory.execute(JSON.serialize(params));
        Test.stopTest();
        system.assert(response.success, JSON.serialize(response));
	}
	
	public static testMethod void testCycleCount_increaseCases() {
    	
    	eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
    	palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        		 
    	Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();
        
        Map<String, Object> cases = new Map<String, Object>();
        Map<String, Object> eaches = new Map<String, Object>();
        
        params.put('binName', fuelQuery.bin.Name);
        
        cases.put('Count_Quantity__c', 3);
        cases.put('Item__c', testItem.Id);
        cases.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(cases);
        
        eaches.put('Count_Quantity__c', 10);
        eaches.put('Item__c', testItem.Id);
        eaches.put('Packaging_UOM__c', eachUOM.Id);
        inventory.add(eaches);
        
        params.put('inventory', inventory);
        
        Test.startTest();
        
        ScannerService.cycleCount cycleCount = new ScannerService.cycleCount();
        Action.Response response = cycleCount.execute(JSON.serialize(params));
        
        system.assert(response.success, JSON.serialize(response));
        
    	list<SKID__c> skidList = [select Id, Item__c, Quantity__c, Packaging_UOM__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(2, skidList.size(), skidList);
        
        for(SKID__c skid : skidList){
        	system.assertEquals(testItem.Id, skid.Item__c, skid);
        	
        	if(skid.Packaging_UOM__c == eachUOM.Id){
        		system.assertEquals(10, skid.Quantity__c, skid);
        	}
        	
        	if(skid.Packaging_UOM__c == caseUOM.Id){
        		system.assertEquals(3, skid.Quantity__c, skid);
        	}
        }
        
        inventory = new List<Map<String, Object>>();
        cases.put('Count_Quantity__c', 8);
        cases.put('Item__c', testItem.Id);
        cases.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(cases);
        
        eaches.put('Count_Quantity__c', 0);
        eaches.put('Item__c', testItem.Id);
        eaches.put('Packaging_UOM__c', eachUOM.Id);
        inventory.add(eaches);
        
        params.put('inventory', inventory);
        
        cycleCount = new ScannerService.cycleCount();
        response = cycleCount.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(response.success, JSON.serialize(response));
        
    	skidList = [select Id, Item__c, Quantity__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(1, skidList.size());
        system.assertEquals(8, skidList[0].Quantity__c, skidList);
        system.assertEquals(testItem.Id, skidList[0].Item__c, skidList);
        
        list<Inventory_Change__c> inventoryChangeList = [select id, Computer_Quantity__c, Count_Quantity__c, Item__c from Inventory_Change__c];
        system.assertEquals(3, inventoryChangeList.size());
    }
    
    public static testMethod void testCycleCount_decreaseCases() {
    	
    	eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
    	palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        		 
    	Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();
        
        Map<String, Object> cases = new Map<String, Object>();
     	Map<String, Object> eaches = new Map<String, Object>();
         
        params.put('binName', fuelQuery.bin.Name);
        
        cases.put('Count_Quantity__c', 3);
        cases.put('Item__c', testItem.Id);
        cases.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(cases);
        
        eaches.put('Count_Quantity__c', 10);
        eaches.put('Item__c', testItem.Id);
        eaches.put('Packaging_UOM__c', eachUOM.Id);
        inventory.add(eaches);
        
        params.put('inventory', inventory);
        
        Test.startTest();
        
        ScannerService.cycleCount cycleCount = new ScannerService.cycleCount();
        Action.Response response = cycleCount.execute(JSON.serialize(params));
        
        system.assert(response.success, JSON.serialize(response));
        
    	list<SKID__c> skidList = [select Id, Item__c, Quantity__c, Packaging_UOM__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(2, skidList.size(), skidList);
        
        for(SKID__c skid : skidList){
        	system.assertEquals(testItem.Id, skid.Item__c, skid);
        	
        	if(skid.Packaging_UOM__c == eachUOM.Id){
        		system.assertEquals(10, skid.Quantity__c, skid);
        	}
        	
        	if(skid.Packaging_UOM__c == caseUOM.Id){
        		system.assertEquals(3, skid.Quantity__c, skid);
        	}
        }
        
        inventory = new List<Map<String, Object>>();
        cases.put('Count_Quantity__c', 0);
        cases.put('Item__c', testItem.Id);
        cases.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(cases);
        
        eaches.put('Count_Quantity__c', 100);
        eaches.put('Item__c', testItem.Id);
        eaches.put('Packaging_UOM__c', eachUOM.Id);
        inventory.add(eaches);
        
        params.put('inventory', inventory);
        
        cycleCount = new ScannerService.cycleCount();
        response = cycleCount.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(response.success, JSON.serialize(response));
        
    	skidList = [select Id, Item__c, Quantity__c, Packaging_UOM__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(1, skidList.size(), skidList);
        system.assertEquals(testItem.Id, skidList[0].Item__c, skidList);
        system.assertEquals(100, skidList[0].Quantity__c, skidList);
        system.assertEquals(eachUOM.Id, skidList[0].Packaging_UOM__c, skidList);
        
        list<Inventory_Change__c> inventoryChangeList = [select id, Computer_Quantity__c, Count_Quantity__c, Item__c from Inventory_Change__c];
        system.assertEquals(3, inventoryChangeList.size());
    }
	
	public static testMethod void testCycleCount_increasePallet() {
    	
    	LPN__c newLPN = new LPN__c(Name='1234567890');
        insert newLPN;
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        
        Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();
        
        Map<String, Object> inventoryItem = new Map<String, Object>();
        
        params.put('binName', fuelQuery.bin.Name);
        
        inventoryItem.put('Count_Quantity__c', 3);
        inventoryItem.put('Item__c', testItem.Id);
        inventoryItem.put('License_Plate_Number__c', newLPN.Name);
        inventoryItem.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(inventoryItem);
        
        params.put('inventory', inventory);
        
        Test.startTest();
        
        ScannerService.cycleCount cycleCount = new ScannerService.cycleCount();
        Action.Response response = cycleCount.execute(JSON.serialize(params));
        
        system.assert(response.success, JSON.serialize(response));
        
    	list<SKID__c> skidList = [select Id, Item__c, Stocking_UOM__c, Quantity_Stocking_UOM__c, Quantity__c,
    									 License_Plate_Number__c
    								from SKID__c where Item__c = :testItem.Id];
        
        system.assertEquals(1, skidList.size(), skidList);
        system.assertEquals(3, skidList[0].Quantity__c, skidList);
        system.assertEquals(24, skidList[0].Quantity_Stocking_UOM__c, skidList);
        system.assertNotEquals(null, skidList[0].Stocking_UOM__c, skidList);
        system.assertNotEquals(null, skidList[0].License_Plate_Number__c, skidList);
        
        fuelQuery.bin = [SELECT Id, Name, Blocked__c, Location__c, Last_Cycle_Count__c FROM Bin__c WHERE Id = :fuelQuery.bin.Id];
        
        system.assertNotEquals(null, fuelQuery.bin.Last_Cycle_Count__c);
        
        //Change bin
        Bin__c stockBin2 = new Bin__c(
								Name = getUniqueName('Stock Bin 2'),
		                    	Description__c = 'stock bin 2',
		                    	Location__c = fuelQuery.bin.Location__c
		          			 );
		          			 
        insert stockBin2;
        
        params.put('binName', stockBin2.Name);
        
        inventory = new List<Map<String, Object>>();
        inventoryItem.put('Count_Quantity__c', 8);
        inventoryItem.put('Item__c', testItem.Id);
        inventoryItem.put('License_Plate_Number__c', newLPN.Name);
        inventoryItem.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(inventoryItem);
        
        params.put('inventory', inventory);
        
        cycleCount = new ScannerService.cycleCount();
        response = cycleCount.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(response.success, JSON.serialize(response));
        
    	skidList = [select Id, Item__c, Quantity__c, Bin__c from SKID__c where Item__c = :testItem.Id];
        
        system.assertEquals(stockBin2.Id, skidList[0].Bin__c, skidList);
        system.assertEquals(1, skidList.size());
        system.assertEquals(1, skidList[0].Quantity__c, skidList);
        
        fuelQuery.bin = [SELECT Id, Name, Blocked__c, Last_Cycle_Count__c FROM Bin__c WHERE Id = :fuelQuery.bin.Id];
        system.assertEquals(true, fuelQuery.bin.Blocked__c);
        
        
        list<Inventory_Transaction__c> inventoryTransactionList = [select id, Quantity__c from Inventory_Transaction__c];
        system.assertEquals(4, inventoryTransactionList.size());
        
        list<Inventory_Change__c> inventoryChangeList = [select id, Computer_Quantity__c, Count_Quantity__c, Item__c from Inventory_Change__c];
        system.assertEquals(3, inventoryChangeList.size());
    }
    
	public static testMethod void testCycleCount_DecreasePallet() {
    				 
    	LPN__c newLPN = new LPN__c(Name='1234567890');
        insert newLPN;
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        
        Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();
        
        Map<String, Object> pallets = new Map<String, Object>();
        Map<String, Object> cases = new Map<String, Object>();
        
        params.put('binName', fuelQuery.bin.Name);
        
        pallets.put('Count_Quantity__c', 8);
        pallets.put('Item__c', testItem.Id);
        pallets.put('License_Plate_Number__c', newLPN.Name);
        pallets.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(pallets);
        
        params.put('inventory', inventory);
        
        Test.startTest();
       	
       	ScannerService.cycleCount cycleCount = new ScannerService.cycleCount();
        Action.Response response = cycleCount.execute(JSON.serialize(params));
        
        system.assert(response.success, JSON.serialize(response));
        
        list<SKID__c> skidList = [select Id, Item__c, Quantity__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(1, skidList.size(), skidList);
        system.assertEquals(testItem.Id, skidList[0].Item__c, skidList);
        system.assertEquals(1, skidList[0].Quantity__c, skidList);
        
        inventory = new List<Map<String, Object>>();
        
        pallets.put('Count_Quantity__c', 0);
        pallets.put('Item__c', testItem.Id);
        pallets.put('License_Plate_Number__c', newLPN.Name);
        pallets.put('Packaging_UOM__c', palletUOM.Id);
        inventory.add(pallets);
        
        cases.put('Count_Quantity__c', 5);
        cases.put('Item__c', testItem.Id);
        cases.put('License_Plate_Number__c', newLPN.Name);
        cases.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(cases);
       
        params.put('inventory', inventory);
        
        cycleCount = new ScannerService.cycleCount();
        cycleCount.execute(JSON.serialize(params));
        
        system.assert(response.success, JSON.serialize(response));
        
    	skidList = [select Id, Item__c, Quantity__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(1, skidList.size());
        system.assertEquals(testItem.Id, skidList[0].Item__c, skidList);
        system.assertEquals(5, skidList[0].Quantity__c, skidList);
        
        inventory = new List<Map<String, Object>>();
        
        cases.put('Count_Quantity__c', 2);
        cases.put('Item__c', testItem.Id);
        cases.put('License_Plate_Number__c', newLPN.Name);
        cases.put('Packaging_UOM__c', caseUOM.Id);
        inventory.add(cases);
       
        params.put('inventory', inventory);
        
        cycleCount = new ScannerService.cycleCount();
        cycleCount.execute(JSON.serialize(params));
        
        system.assert(response.success, JSON.serialize(response));
        
    	skidList = [select Id, Item__c, Quantity__c from SKID__c where Item__c = :testItem.Id];
        system.assertEquals(1, skidList.size());
        system.assertEquals(testItem.Id, skidList[0].Item__c, skidList);
        system.assertEquals(2, skidList[0].Quantity__c, skidList);
        
        list<Inventory_Change__c> inventoryChangeList = [select id, Computer_Quantity__c, Count_Quantity__c, Item__c from Inventory_Change__c];
        system.assertEquals(4, inventoryChangeList.size());
        
        Test.stopTest();
        
    }

    public static testMethod void testCycleCount_noInventory() {

        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
        caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
        palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];

        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Test Item')];

        fuelQuery.bin.Blocked__c = true;
        update fuelQuery.bin;

        Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();

        params.put('binName', fuelQuery.bin.Name);
        params.put('inventory', inventory);

        Test.startTest();

        ScannerService.cycleCount cycleCount = new ScannerService.cycleCount();
        Action.Response response = cycleCount.execute(JSON.serialize(params));

        Test.stopTest();

        system.assert(response.success, JSON.serialize(response));

        Bin__c bin = [SELECT Id, Blocked__c FROM Bin__c WHERE Id = :fuelQuery.bin.Id];
        system.assertEquals(false, bin.Blocked__c);
    }
    
    public static testMethod void testDeletePicks() {
    	
    	fuelQuery.location2.Bin_Tracked__c = true;
		fuelQuery.location3.Bin_Tracked__c = true;
		
        update new List<Location__c>{fuelQuery.location2, fuelQuery.location3}; 
        
        Bin__c shippingBin = new Bin__c(
								Name = getUniqueName('Shipping Bin'),
		                    	Description__c = 'shipping bin',
		                    	Location__c = fuelQuery.location2.id
		          			 );
              
        insert shippingBin;
        
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        
        Test.startTest();
        
        new SalesOrderService().plan(fuelQuery.packageSalesOrder.Id);
    					 
    	fuelQuery.setupInventory(true, false, true);

        Sales_Order__c so = fuelQuery.packageSalesOrder;
		
		String lpnName = 'LPN' + fuelQuery.itemList[14].Name;
        
        List<SKID__c> palletSkids = [SELECT Id, Bin__c, Container_Item__c FROM SKID__c WHERE License_Plate_Number__c != null AND Location__c = :fuelQuery.location3.Id];
        
        for(SKID__c palletSkid : palletSkids){
        	palletSkid.Bin__c = fuelQuery.bin.Id;
        }
        
        update palletSkids;
    	
		SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        for (SkidService3.SerialWrapper sw : wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuelQuery.location3.Id && sw.skid.Bin__c == fuelQuery.bin.Id) { 
            	sw.skid.Input_Quantity__c = 6;
        	}
            else { 
            	sw.skid.Input_Quantity__c = 0;
        	}
        	
            sw.skid.Item__r = (Item__c) wrapper.line.getSObject('Item__r');
        }
        
        AllocationService.allocate(wrappers);
        
        Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();
        
        Map<String, Object> pallets = new Map<String, Object>();
        
        pallets.put('Packaging_UOM__c', fuelQuery.uomPallet.Name);
        pallets.put('quantity', 1.0);
        pallets.put('Shipment_Line__c', wrapper.line.Id);
        pallets.put('fromBin', fuelQuery.bin.Name);
        pallets.put('fromBinId', fuelQuery.bin.Id);
        
        inventory.add(pallets);
        
        params.put('inventory', inventory);
        
        ScannerService.generatePicks generatePicks = new ScannerService.generatePicks();
        Action.Response planResponse = generatePicks.execute(JSON.serialize(params));
        
		List<SKID__c> skids = [SELECT Id, Bin__c, Container_Item__c FROM SKID__c WHERE Type__c = 'Planned Pick'];
		system.assertEquals(1, skids.size(), skids);
		system.assertEquals(fuelQuery.bin.Id, skids[0].Bin__c, skids[0].Bin__c);
		
        fuelQuery.bin.Blocked__c = true;
              
        update fuelQuery.bin;
        
        pallets.put('quantity', -1.0);
        
		generatePicks = new ScannerService.generatePicks();
        planResponse = generatePicks.execute(JSON.serialize(params));
        
		skids = [SELECT Id, Container_Item__c FROM SKID__c WHERE Type__c = 'Planned Pick'];
		system.assertEquals(0, skids.size(), skids);
		
		Shipment_Line__c shl = [SELECT Id, Quantity_To_Pick__c FROM Shipment_Line__c WHERE Id = :wrapper.line.Id];
		system.assertEquals(0, shl.Quantity_To_Pick__c, shl);
    }
    
    public static testMethod void testGeneratePicks() {
    	
    	fuelQuery.location2.Bin_Tracked__c = true;
		fuelQuery.location3.Bin_Tracked__c = true;
		
        update new List<Location__c>{fuelQuery.location2, fuelQuery.location3}; 
        
        Bin__c shippingBin = new Bin__c(
								Name = getUniqueName('Shipping Bin'),
		                    	Description__c = 'shipping bin',
		                    	Location__c = fuelQuery.location2.id
		          			 );
              
        insert shippingBin;
        
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        
        Test.startTest();
        
        new SalesOrderService().plan(fuelQuery.packageSalesOrder.Id);
    					 
    	fuelQuery.setupInventory(true, false, true);

        Sales_Order__c so = fuelQuery.packageSalesOrder;
		
		String lpnName = 'LPN' + fuelQuery.itemList[14].Name;
        
        List<SKID__c> caseSkids = [SELECT Id, Bin__c, Item__c FROM SKID__c WHERE License_Plate_Number__c = null AND Location__c = :fuelQuery.location3.Id];
        
        for(SKID__c caseSkid : caseSkids){
        	caseSkid.Bin__c = fuelQuery.bin.Id;
        }
        
        update caseSkids;
    	
		SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        for (SkidService3.SerialWrapper sw : wrapper.serialWrappers) {
            if (sw.skid.Bin__c == fuelQuery.bin.Id) { 
            	sw.skid.Input_Quantity__c = 6;
        	}
            else { 
            	sw.skid.Input_Quantity__c = 0;
        	}
        	
            sw.skid.Item__r = (Item__c) wrapper.line.getSObject('Item__r');
        }
        
        AllocationService.allocate(wrappers);
        
        Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();
        
        Map<String, Object> case1 = new Map<String, Object>();
        
        case1.put('Packaging_UOM__c', fuelQuery.uomList[12].Name);
        case1.put('quantity', 1.0);
        case1.put('Shipment_Line__c', wrapper.line.Id);
        case1.put('Location__c', fuelQuery.location3.Id);
        case1.put('fromBin', fuelQuery.bin.Name);
        case1.put('fromBinId', fuelQuery.bin.Id);
        case1.put('toBin', shippingBin.Name);
        
        Map<String, Object> case2 = new Map<String, Object>();
        
        case2.put('Packaging_UOM__c', fuelQuery.uomList[12].Name);
        case2.put('quantity', 1.0);
        case2.put('Shipment_Line__c', wrapper.line.Id);
        case2.put('Location__c', fuelQuery.location3.Id);
        case2.put('fromBin', fuelQuery.bin.Name);
        case2.put('fromBinId', fuelQuery.bin.Id);
        case2.put('toBin', shippingBin.Name);
        
        Map<String, Object> case3 = new Map<String, Object>();
        
        case3.put('Packaging_UOM__c', fuelQuery.uomList[12].Name);
        case3.put('quantity', 1.0);
        case3.put('Shipment_Line__c', wrapper.line.Id);
        case3.put('Location__c', fuelQuery.location3.Id);
        case3.put('fromBin', fuelQuery.bin.Name);
        case3.put('fromBinId', fuelQuery.bin.Id);
        case3.put('toBin', shippingBin.Name);
        
        inventory.add(case1);
        inventory.add(case2);
        inventory.add(case3);
        
        params.put('Shipment__c', shipment.Id);
        params.put('inventory', inventory);
        
        ScannerService.generatePicks generatePicks = new ScannerService.generatePicks();
        Action.Response planResponse = generatePicks.execute(JSON.serialize(params));
        
		List<SKID__c> skids = [SELECT Id, Quantity__c, Packaging_UOM__c, Container_Item__c FROM SKID__c WHERE Type__c = 'Planned Pick'];
		system.assertEquals(1, skids.size(), skids);
		system.assertEquals(fuelQuery.uomList[12].Id, skids[0].Packaging_UOM__c, skids[0].Packaging_UOM__c);
		system.assertEquals(3, skids[0].Quantity__c, skids[0].Quantity__c);
		
		shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assertEquals(1, shipmentLines.size(), shipmentLines.values());
        
        ScannerService.pickInventory pickInventory = new ScannerService.pickInventory();
        Action.Response pickResponse = pickInventory.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(pickResponse.success, JSON.serialize(pickResponse));
        
        skids = [SELECT Id, Item__r.Name, Quantity__c, License_Plate_Number__r.Name FROM SKID__c WHERE Type__c = 'Location' AND Location__c = :fuelQuery.location2.Id];
        
        system.assertEquals(1, skids.size(), skids);
		system.assertEquals(3, skids[0].Quantity__c, skids);
		system.assertEquals(null, skids[0].License_Plate_Number__r.Name, skids);
    }
    
    public static testMethod void testPickInventory() {
    	
    	fuelQuery.location2.Bin_Tracked__c = true;
		fuelQuery.location3.Bin_Tracked__c = true;
		
        update new List<Location__c>{fuelQuery.location2, fuelQuery.location3}; 
        
        Bin__c shippingBin = new Bin__c(
								Name = getUniqueName('Shipping Bin'),
		                    	Description__c = 'shipping bin',
		                    	Location__c = fuelQuery.location2.id
		          			 );
              
        insert shippingBin;
        
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        
        Test.startTest();
        
        new SalesOrderService().plan(fuelQuery.packageSalesOrder.Id);
    					 
    	fuelQuery.setupInventory(true, false, true);

        Sales_Order__c so = fuelQuery.packageSalesOrder;
		
		String lpnName = 'LPN' + fuelQuery.itemList[14].Name;
        
        List<SKID__c> palletSkids = [SELECT Id, Bin__c, Container_Item__c FROM SKID__c WHERE License_Plate_Number__c != null AND Location__c = :fuelQuery.location3.Id];
        
        for(SKID__c palletSkid : palletSkids){
        	palletSkid.Bin__c = fuelQuery.bin.Id;
        }
        
        update palletSkids;
    	
		SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        for (SkidService3.SerialWrapper sw : wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuelQuery.location3.Id && sw.skid.Bin__c == fuelQuery.bin.Id) { 
            	sw.skid.Input_Quantity__c = 6;
        	}
            else { 
            	sw.skid.Input_Quantity__c = 0;
        	}
        	
            sw.skid.Item__r = (Item__c) wrapper.line.getSObject('Item__r');
        }
        
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());

        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper uomWrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:uomWrapper.serialWrappers) {
                if (sw.skid.Packaging_UOM__r.Package_Class__c != sw.skid.Container_Item__r.Container_Package_Class__c 
                		&& sw.skid.Container_Item__r.Container_Package_Class__c != null){ 
                	continue;
        		}

                if (uomWrapper.uom == 'PT') {
                    sw.skid.Quantity_to_Issue__c = 1; //1 PT
                    sw.skid.Input_Quantity__c = 6;  //6 EA
                } else if (uomWrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = 1; //1 CS
                    sw.skid.Input_Quantity__c = 2;  //2 EA
                } else if (uomWrapper.uom == 'EA2') {
                    sw.skid.Quantity_to_Issue__c = 2;   //2 EA
                    sw.skid.Input_Quantity__c = 2;  //2 EA
                }
                
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
		
		List<SKID__c> skids = [SELECT Id, Container_Item__c FROM SKID__c WHERE Type__c = 'Planned Pick'];
		system.assertEquals(1, skids.size(), skids);
		
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        Map<String, Object> params = new Map<String, Object>();
        List<Map<String, Object>> inventory = new List<Map<String, Object>>();
        
        Map<String, Object> pallets = new Map<String, Object>();
        
        pallets.put('plannedSkid', skids[0].Id);
        pallets.put('Shipment_Line__c', wrapper.line.Id);
        pallets.put('Packaging_UOM__c', fuelQuery.uomPallet.Name);
        pallets.put('Container_Item__c', palletSkids[0].Container_Item__c);
        pallets.put('Location__c', fuelQuery.location3.Id);
        pallets.put('fromBin', fuelQuery.bin.Name);
        pallets.put('toBin', shippingBin.Name);
        pallets.put('quantity', 1.0);
        pallets.put('fromLPN', lpnName);
        
        inventory.add(pallets);
        
        params.put('inventory', inventory);
        
        ScannerService.pickInventory pickInventory = new ScannerService.pickInventory();
        Action.Response response = pickInventory.execute(JSON.serialize(params));
        
        Test.stopTest();
        system.assert(response.success, JSON.serialize(response));
        
        skids = [SELECT Id, Item__r.Name, Quantity__c, License_Plate_Number__r.Name FROM SKID__c WHERE Type__c = 'Location' AND Location__c = :fuelQuery.location2.Id];
        
        system.assertEquals(1, skids.size(), skids);
		system.assertEquals(1, skids[0].Quantity__c, skids);
		system.assertEquals(lpnName, skids[0].License_Plate_Number__r.Name, skids);
    }
	
	public static testMethod void testPalletBreak() {
    	
    	fuelQuery.location2.Bin_Tracked__c = true;
    	fuelQuery.location2.Mixed_Bins_Allowed__c = true;
    	
		fuelQuery.location3.Bin_Tracked__c = true;
		fuelQuery.location3.Mixed_Bins_Allowed__c = true;
		
        update new List<Location__c>{fuelQuery.location2, fuelQuery.location3}; 
        
        Bin__c shippingBin = new Bin__c(
								Name = getUniqueName('Shipping Bin'),
		                    	Description__c = 'shipping bin',
		                    	Location__c = fuelQuery.location2.id
		          			 );
              
        insert shippingBin;
        
        fuelQuery.itemList[14].Item_Attribute__c = null;
        update fuelQuery.itemList[14];
        
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        
        Test.startTest();
        
        new SalesOrderService().plan(fuelQuery.packageSalesOrder.Id);
    					 
    	fuelQuery.setupInventory(true, false, true);

        Sales_Order__c so = fuelQuery.packageSalesOrder;
		
		String lpnName = 'LPN' + fuelQuery.itemList[14].Name;
        
        List<SKID__c> palletSkids = [SELECT Id, Bin__c FROM SKID__c WHERE License_Plate_Number__c != null AND Location__c = :fuelQuery.location3.Id];
        
        for(SKID__c palletSkid : palletSkids){
        	palletSkid.Bin__c = fuelQuery.bin.Id;
        }
        
        update palletSkids;
    	
		SOQLUtil shipmentQuery = new SOQLUtil('Shipment__c');
        shipmentQuery.addField('Id');
        Shipment__c shipment = Database.query(shipmentQuery.getQuery());
        
        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'allocate'));
        List<LineWrapper> wrappers = AllocationService.getInventory(shipmentLines.values());
        
        LineWrapper wrapper = wrappers[0];
        wrapper.line = shipmentLines.get(wrapper.line.Id);
        wrapper.header = wrapper.line.getSObject('Shipment__r');

        for (SkidService3.SerialWrapper sw : wrapper.serialWrappers) {
            if (sw.skid.Location__c == fuelQuery.location3.Id && sw.skid.Bin__c == fuelQuery.bin.Id) { 
            	sw.skid.Input_Quantity__c = 6;
        	}
            else { 
            	sw.skid.Input_Quantity__c = 0;
        	}
        	
            sw.skid.Item__r = (Item__c) wrapper.line.getSObject('Item__r');
        }
        
        AllocationService.allocate(wrappers);
        
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'planpick'));
        
        wrappers = ShipmentInventoryService.getInventoryForPlan(shipmentLines.values());

        LineWrapper shlWrapper = new LineWrapper(shipmentLines.values()[0].Shipment__r, shipmentLines.values()[0], new List<SkidService3.SerialWrapper>());
        for (LineWrapper uomWrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:uomWrapper.serialWrappers) {
                if (sw.skid.Packaging_UOM__r.Package_Class__c != sw.skid.Container_Item__r.Container_Package_Class__c 
                		&& sw.skid.Container_Item__r.Container_Package_Class__c != null){ 
                	continue;
        		}

                if (uomWrapper.uom == 'PT') {
                    sw.skid.Quantity_to_Issue__c = 1; //1 PT
                    sw.skid.Input_Quantity__c = 6;  //6 EA
                } else if (uomWrapper.uom == 'CS') {
                    sw.skid.Quantity_to_Issue__c = 1; //1 CS
                    sw.skid.Input_Quantity__c = 2;  //2 EA
                } else if (uomWrapper.uom == 'EA2') {
                    sw.skid.Quantity_to_Issue__c = 2;   //2 EA
                    sw.skid.Input_Quantity__c = 2;  //2 EA
                }
                
                sw.skid.Item__r = (Item__c)shlWrapper.line.getSObject('Item__r');
                shlWrapper.serialWrappers.add(sw);
            }
        }
        
        ShipmentInventoryService.plan(new List<LineWrapper>{ shlWrapper });
		
		List<SKID__c> skids = [SELECT Id, Container_Item__c FROM SKID__c WHERE Type__c = 'Planned Pick'];
		system.assertEquals(1, skids.size(), skids);
		
        shipmentLines = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Shipment__c' => shipment.Id }, 'pick'));
        System.assert(shipmentLines.size() == 1, shipmentLines.values());
        
        Id itemId = fuelQuery.itemList[14].Id;
        String binName = fuelQuery.bin.Name;
        
        List<SKID__c> inventory = [select Id, Packaging_UOM__r.Name, License_Plate_Number__r.Name, Quantity__c from Skid__c where Item__c = :itemId and Bin__r.Name = :binName];
        
        system.debug(JSON.serialize(inventory));   
        for(SKID__c skid : inventory){
        	if (skid.Packaging_UOM__r.Name == 'PT' && skid.License_Plate_Number__c != null) {
   				system.assertEquals(lpnName, skid.License_Plate_Number__r.Name);    
   				system.assertEquals(1, skid.Quantity__c);     
            } 
            else 
            if (skid.Packaging_UOM__r.Name == 'CS' && skid.License_Plate_Number__c == null) {
        		system.assertEquals(1, skid.Quantity__c);   
            } 
        }
        
        Map<String, Object> params = new Map<String, Object>();
        
        params.put('lpnName', lpnName);
        params.put('toBin', binName);
        params.put('itemId', itemId);
        params.put('attributesToCorrect', JSON.serialize(new List<String>{'Packaging_UOM__c'}));
        params.put('doBreakPallet', true);
        
        ScannerService.replenish replenish = new ScannerService.replenish();
        Action.Response response = replenish.execute(JSON.serialize(params));
        
        Test.stopTest();
        
        system.assert(response.success, JSON.serialize(response));
        
        inventory = [select Id, Packaging_UOM__r.Name, License_Plate_Number__r.Name, Quantity__c from Skid__c where Item__c = :itemId and Bin__r.Name = :binName];
           
        for(SKID__c skid : inventory){
        	if (skid.Packaging_UOM__r.Name == 'CS' && skid.License_Plate_Number__c == null) {
        		system.assertEquals(3, skid.Quantity__c, JSON.serialize(inventory));   
            } 
        }
    }
    
	public static testMethod void testPackShipment() {
							 
    	LPN__c fromLPN = new LPN__c(Name='12345678901', Contents__c = '');
    	
    	Set<String> contents = new Set<String>();
    	for(Integer i=0; i<7; i++){
    		contents.add(String.valueOf(i));
    	}
    	fromLPN.Contents__c = String.join(new List<String>(contents), ',');
    	
    	insert fromLPN;
        
        LPN__c toLPN = new LPN__c(Name='12345678902');
        //insert toLPN;
        
        fuelQuery.location2.Bin_Tracked__c = true;
        update fuelQuery.location2; 
        
        Bin__c bin = new Bin__c(
						Name = getUniqueName('Shipping Bin'),
                    	Description__c = 'bin',
                    	Location__c = fuelQuery.location2.id
          			 );
              
        insert bin;  
        
        eachUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Each')];
    	caseUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Case')];
    	palletUOM = [SELECT Id FROM UOM__c WHERE Name = :getUniqueName('Pallet')];
    	
        palletItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Pallet Item')];
        caseItem = [SELECT Id FROM Item__c WHERE Name = :getUniqueName('Case Item')];
        testItem = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Name = :getUniqueName('Test Item')];
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(testItem.Packaging_UOM__c, List<Id>.class);
        
        SKID__c inventorySkid = new SKID__c(
            						Facility2__c = fuelQuery.facility2.Id,
            						Location__c = fuelQuery.location2.Id, // Delivery/ Shipping 
            						Company__c = fuelQuery.company.Id,
            						Quantity__c = 8,
            						Quantity_Stocking_UOM__c = 8 * KSE.getConversionFactor (testItem.Id, fuelQuery.facility2.Facility_Identifier__c,caseUOM.Id, eachUOM.Id, lstPkgUom),
            						Item__c = testItem.Id, 
            						Container_Item__c = palletItem.Id,
            						Type__c = 'Location', 
            						Packaging_UOM__c = caseUOM.Id, 
            						Stocking_UOM__c = eachUOM.Id,
            						License_Plate_Number__c = fromLPN.Id,
            						Bin__c = bin.Id
        						);
        
        insert inventorySkid;
        
        Map<String, Object> params = new Map<String, Object>();
        params.put('fromLPN', fromLPN.Name);
        params.put('toLPN', toLPN.Name);
        
        List<Map<String, Object>> inventory = new List<Map<String, Object>>(); 
        
        for(Integer i=0; i<7; i++){
        	Map<String, Object> inventoryLine = new Map<String, Object>();
	        inventoryLine.put('itemId', testItem.Id);
	        inventoryLine.put('quantity', 8);
	        inventoryLine.put('caseNumber', String.valueOf(i));
	        
	        inventory.add(inventoryLine);
        }
        
        params.put('inventory', inventory);
        
        Test.startTest();
        
        ScannerService.packShipment pack = new ScannerService.packShipment();
        Action.Response response = pack.execute(JSON.serialize(params));
        system.assert(response.success, JSON.serialize(response));
        
        Test.stopTest();
        
        List<SKID__c> skidList = [select Id, Item__c, Quantity__c from SKID__c where License_Plate_Number__r.Name = :fromLPN.Name];
        system.assertEquals(1, skidList.size());
        system.assertEquals(1, skidList[0].Quantity__c, skidList);
        system.assertEquals(testItem.Id, skidList[0].Item__c, skidList);
        
        skidList = [select Id, Item__c, Quantity__c from SKID__c where License_Plate_Number__r.Name = :toLPN.Name];
        system.assertEquals(1, skidList.size(), skidList);
        system.assertEquals(7, skidList[0].Quantity__c, skidList);
        system.assertEquals(testItem.Id, skidList[0].Item__c, skidList);
        
        list<Inventory_Change__c> inventoryChangeList = [select id, Computer_Quantity__c, Count_Quantity__c, Item__c from Inventory_Change__c];
        system.assertEquals(1, inventoryChangeList.size());
	}

	// Remove shipment - part pallet
	public static testMethod void testScannerRemovePartPallet () {
	    
        DML.systemTime = system.now().addHours(-2);
        List<Configuration__c> c = new List<Configuration__c>();
        List<sObjectType> skipTriggers = new List<sObjectType>{Inventory_Transaction__c.sObjectType,
            UOM__c.sObjectType,
            SKID__c.sObjectType,
            LPN__c.sObjectType,
            Item_Attribute__c.sObjectType,
            Inventory_Change__c.sObjectType,
            Receipt_Line__c.sObjectType,
            Company__c.sObjectType,
            Sales_Order__c.sObjectType,
            Sales_Order_Line__c.sObjectType,
            Shipment__c.sObjectType};
        
        for (sObjectType s:skipTriggers) {
            c.add(new Configuration__c(Name = s.getDescribe().getLocalName() + '-' + s.getDescribe().getKeyPrefix(),Value__c = UserInfo.getUserId()));  
        }
        insert c;
		
        eachUOM = fuelQuery.uomList[11];
        caseUOM = fuelQuery.uomList[12];
        palletUOM = fuelQuery.uomList[13];

        palletItem = fuelQuery.itemList[13];
        caseItem = fuelQuery.itemList[12];

        fuelQuery.itemList[14].Item_Attribute__c = null;
        update fuelQuery.itemList[14];

        LPN__c newLPN = new LPN__c(Name='1234567890');
        newLPN.Contents__c = '001,002,003,004,005,006,007,008,009,010,011';
        //insert newLPN;

        LPN__c packLPN = new LPN__c(Name='1234567891');
        packLPN.Contents__c = '001,002,003,004,005,006,007,008,009,010,011';
        //insert packLPN;

        SKID__c locnSkid = new SKID__c();
        locnSkid.location__c = fuelQuery.location3.id;
        locnSkid.Bin__c = fuelQuery.bin.id;
        locnSkid.Facility2__c = fuelQuery.facility2.Id;
        locnSkid.Company__c= fuelQuery.company.id;
        locnSkid.Quantity__c = 1;
        locnSkid.Item__c= fuelQuery.itemList[14].Id;
        locnSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
        locnSkid.Quantity_Stocking_UOM__c = 2;
        locnSkid.License_Plate_Number__c = newLPN.Id;
        locnSkid.Stocking_UOM__c = eachUOM.Id;
        locnSkid.Packaging_UOM__c = caseUOM.Id;
        locnSkid.Packaging_UOM__r = caseUOM;
        locnSkid.Container_Item__c = palletItem.Id;

        // Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(new Set<String>{fuelQuery.company.Id});

        Inventory_Change__c inventoryChange = new Inventory_Change__c();
		inventoryChange.Company__c = fuelQuery.company.Id;
		inventoryChange.Company__r = fuelQuery.company;//mCompanies.get(fuelQuery.company.Id);
		inventoryChange.Transaction_Date__c = System.now();
		inventoryChange.Type__c = 'Transfer';
		//insert inventoryChange;

        insert new List<SObject>{ inventoryChange,locnSkid,newLPN,packLPN};
        
        Test.startTest();
        SalesOrderReleaseService.release(fuelQuery.packageSalesOrder.Id);
        
        list<SObject> groupedUpdate = new List<SObject>();


        List<Shipment__c> shipments = [SELECT Id, Name, Status__c, (SELECT Id, Name, Quantity_Allocated__c, Quantity_Picked__c, Quantity_Planned__c, Quantity_To_Pick__c FROM Shipment_Lines__r) FROM Shipment__c];
        List<Shipment_Line__c> shls = new List<Shipment_Line__c>();
		for(Shipment__c shipment: shipments) {
			shipment.Status__c = 'Staged';
			groupedUpdate.add(shipment);
            shls.addAll(shipment.Shipment_Lines__r);
		}

		for(Shipment_Line__c shl: shls) {
			shl.Quantity_Picked__c = 10;
			shl.Quantity_Shipped__c = 0;
			shl.Quantity_From_Stock__c = 10;

			groupedUpdate.add(shl);
		}

		SOQLUtil skidQuery = new SOQLUtil('Skid__c');
		skidQuery.addAllCustomFields();
		skidQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
		skidQuery.addAllCustomFields(Item__c.sObjectType,'Item__r.Container_Item__r');
		skidQuery.addAllCustomFields(Bin__c.sObjectType,'Bin__r');
		skidQuery.addAllCustomFields(Package_Class__c.sObjectType, 'Packaging_UOM__r.Package_Class__r');
		skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
		skidQuery.addFields(new Set<String>{ 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',
				'Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Item__r.Container_Item__r.Container_Package_Class__c', 'Item__r.Container_Item__r.Container_Package_Class__r.Level__c','Item__r.Container_Item__r.Container_Package_Class__r.Fractional_Quantities_Allowed__c',
				'Item__r.Container_Item__r.Item_Attribute__c', 'Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__c', 'Item__r.Container_Item__r.Packaging_UOM__c',
				'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Location__r.Bin_Tracked__c', 'Location__r.Track_Bin_Capacity__c',
				'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container__c', 'Shipment_Line__r.Shipment__c','Shipment_Line__c','Shipment_Line__r.Name',
				'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c', 'Location__r.Facility__c', 'Location__r.name', 'Item__r.Packaging_UOM__c', 'Facility2__r.Facility_Identifier__c'
		});
		Id shlId = shls[0].Id;
		skidQuery.setWhereClause('Shipment_Line__c = :shlId');
		List<Skid__c> skids = Database.query(skidQuery.getQuery());
		for ( Skid__c skid: skids ) {
			skid.Container_Item__c = palletItem.Id;
            skid.Container_Item__r = palletItem;
			skid.Type__c = 'Planned Pick';
            skid.Location__c = fuelQuery.location3.Id;
            skid.Bin__c = fuelQuery.bin.Id;
            skid.Quantity__c = 1;
            skid.Packaging_UOM__c = caseUOM.Id;
            skid.Stocking_UOM__c = eachUOM.Id;
            skid.Quantity_Stocking_UOM__c = 2;
//            groupedUpdate.add(skid);
            update skid;
            break;
		}
		update groupedUpdate;

		if ( !skids.isEmpty()){
			Skid__c skid = skids[0];

            Skid__c pickSkid = new Skid__c();
            pickSkid.Facility2__c = fuelQuery.facility2.Id;
            pickSkid.Company__c= fuelQuery.company.id;
            pickSkid.Item__c= fuelQuery.itemList[14].Id;
            pickSkid.Item__r= fuelQuery.itemList[14];
            pickSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            pickSkid.Stocking_UOM__c = eachUOM.Id;
            pickSkid.Packaging_UOM__c = caseUOM.Id;
            pickSkid.Packaging_UOM__r = caseUOM;
            pickSkid.License_Plate_Number__c = newLPN.Id;
            pickSkid.License_Plate_Number__r = newLPN;
            pickSkid.Container_Item__c = palletItem.Id;
            pickSkid.Container_Item__r = palletItem;
            pickSkid.Location__c = fuelQuery.location2.Id;
            pickSkid.Quantity__c = 1;
            pickSkid.Shipment_Line__c = shls[0].Id;
            pickSkid.Unique_Key__c = null;
            List<Id> lstPkgUom = (List<Id>) JSON.deserialize(pickSkid.Item__r.Packaging_UOM__c, List<Id>.class);
            pickSkid.Quantity_Stocking_UOM__c = pickSkid.Quantity__c * KSE.getConversionFactor (pickSkid.Item__c, fuelQuery.facility2.Facility_Identifier__c,pickSkid.Packaging_UOM__c, pickSkid.Stocking_UOM__c, lstPkgUom);
            //insert pickSkid;

            Skid__c transferSkid = new Skid__c();
            transferSkid.Facility2__c = fuelQuery.facility2.Id;
            transferSkid.Company__c= fuelQuery.company.id;
            transferSkid.Item__c= fuelQuery.itemList[14].Id;
            transferSkid.Item__r= fuelQuery.itemList[14];
            transferSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            transferSkid.Stocking_UOM__c = eachUOM.Id;
            transferSkid.Packaging_UOM__c = caseUOM.Id;
            transferSkid.Packaging_UOM__r = caseUOM;
            transferSkid.License_Plate_Number__c = packLPN.Id;
            transferSkid.License_Plate_Number__r = packLPN;
            transferSkid.Container_Item__c = palletItem.Id;
            transferSkid.Container_Item__r = palletItem;
            transferSkid.Location__c = fuelQuery.location2.Id;
            transferSkid.Quantity__c = 1;
            transferSkid.Unique_Key__c = null;
            transferSkid.Shipment_Line__c = shls[0].Id;
            transferSkid.Quantity_Stocking_UOM__c = transferSkid.Quantity__c * KSE.getConversionFactor (transferSkid.Item__c, fuelQuery.facility2.Facility_Identifier__c,transferSkid.Packaging_UOM__c, transferSkid.Stocking_UOM__c, lstPkgUom);
			transferSkid.Mixed_Palletized__c = true;

            insert new List<Skid__c>{pickSkid,transferSkid};

			Inventory_Transaction__c pickit = SkidService3.createInventoryTransaction(pickSkid.Item__r, inventoryChange, 'Sales Order Pick', locnSkid.Quantity__c, locnSkid, pickSkid, null);
            insert pickIt;
            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(pickSkid.Item__r, inventoryChange, 'Transfer', transferskid.Quantity__c, pickSkid, transferskid, null);
            insert it;

            system.assert(it.License_Plate_Number__c != null);
            system.assert (it.Mixed_Palletized__c == true);
            //insert new List<Inventory_Transaction__c>{it, pickIt};
			List<SObject> deleteSobjs = new List<SObject>();
            deleteSobjs.addAll((List<SObject>)skids);
            deleteSobjs.addAll(new List<SObject> { pickSkid, locnSkid});
            deleteSobjs.addAll((List<SObject>)c);
            delete deleteSobjs;
            //delete skids;


            //System.assert(new List<Skid__c>([SELECT id FROM Skid__c WHERE License_Plate_Number__c IN (:newLPN.Id, :packLPN.Id)]).size() == 1);
            //System.assert(new List<Skid__c>([SELECT id FROM Skid__c WHERE License_Plate_Number__c = :packLPN.Id]).size() == 1);

            Map<String, Object> params1 = new Map<String, Object>();
			params1.put('fromLPN', packLPN.Name);
			Action.Response response = BaseController.doAction('REMOVE_FROM_SHIPMENT', JSON.serialize(params1));
			system.assert(response.success, JSON.serialize(response));
		} else {
			system.assert(false);
		}

		Test.stopTest();
	}

    public static testMethod void testScannerRemoveLooseCases () {
        SalesOrderReleaseService.release(fuelQuery.packageSalesOrder.Id);
        Test.startTest();
        eachUOM = fuelQuery.uomList[11];
        caseUOM = fuelQuery.uomList[12];

        palletItem = fuelQuery.itemList[13];
        caseItem = fuelQuery.itemList[12];

        LPN__c packLPN = new LPN__c(Name='1234567891');
        packLPN.Contents__c = '001,002,003,004,005,006,007,008,009,010,011';
        insert packLPN;

        fuelQuery.itemList[14].Item_Attribute__c = null;
        update fuelQuery.itemList[14];

        SKID__c locnSkid = new SKID__c();
        locnSkid.location__c = fuelQuery.location3.id;
        locnSkid.Bin__c = fuelQuery.bin.id;
        locnSkid.Facility2__c = fuelQuery.facility2.Id;
        locnSkid.Company__c= fuelQuery.company.id;
        locnSkid.Quantity__c = 1;
        locnSkid.Item__c= fuelQuery.itemList[14].Id;
        locnSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
        locnSkid.Quantity_Stocking_UOM__c = 2;
        locnSkid.Stocking_UOM__c = eachUOM.Id;
        locnSkid.Packaging_UOM__c = caseUOM.Id;
        locnSkid.Packaging_UOM__r = caseUOM;
        locnSkid.Container_Item__c = caseItem.Id;
        insert locnSkid;

        list<SObject> groupedUpdate = new List<SObject>();


        List<Shipment__c> shipments = [SELECT Id, Name, Status__c FROM Shipment__c];
        for(Shipment__c shipment: shipments) {
            shipment.Status__c = 'Staged';
            groupedUpdate.add(shipment);
        }

        List<Shipment_Line__c> shls = [SELECT Id, Name, Quantity_Allocated__c, Quantity_Picked__c, Quantity_Planned__c, Quantity_To_Pick__c FROM Shipment_Line__c];
        for(Shipment_Line__c shl: shls) {
            shl.Quantity_Picked__c = 2;
            shl.Quantity_Shipped__c = 0;
            shl.Quantity_From_Stock__c = 2;

            groupedUpdate.add(shl);
        }
        update groupedUpdate;

        SOQLUtil skidQuery = new SOQLUtil('Skid__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        skidQuery.addAllCustomFields(Item__c.sObjectType,'Item__r.Container_Item__r');
        skidQuery.addAllCustomFields(Bin__c.sObjectType,'Bin__r');
        skidQuery.addAllCustomFields(Package_Class__c.sObjectType, 'Packaging_UOM__r.Package_Class__r');
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        skidQuery.addFields(new Set<String>{ 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',
                'Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Item__r.Container_Item__r.Container_Package_Class__c', 'Item__r.Container_Item__r.Container_Package_Class__r.Level__c','Item__r.Container_Item__r.Container_Package_Class__r.Fractional_Quantities_Allowed__c',
                'Item__r.Container_Item__r.Item_Attribute__c', 'Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__c', 'Item__r.Container_Item__r.Packaging_UOM__c',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Location__r.Bin_Tracked__c', 'Location__r.Track_Bin_Capacity__c',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container__c', 'Shipment_Line__r.Shipment__c','Shipment_Line__c','Shipment_Line__r.Name',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c', 'Location__r.Facility__c', 'Location__r.name', 'Item__r.Packaging_UOM__c', 'Facility2__r.Facility_Identifier__c'
        });
        Id shlId = shls[0].Id;
        skidQuery.setWhereClause('Shipment_Line__c = :shlId');
        List<Skid__c> skids = Database.query(skidQuery.getQuery());
        for ( Skid__c skid: skids ) {
            skid.Container_Item__c = caseItem.Id;
            skid.Container_Item__r = caseItem;
            skid.Type__c = 'Planned Pick';
            skid.Location__c = fuelQuery.location3.Id;
            skid.Bin__c = fuelQuery.bin.Id;
            skid.Quantity__c = 1;
            skid.Packaging_UOM__c = caseUOM.Id;
            skid.Stocking_UOM__c = eachUOM.Id;
            skid.Quantity_Stocking_UOM__c = 2;
            update skid;
            break;
        }

        Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(new Set<String>{fuelQuery.company.Id});

        Inventory_Change__c inventoryChange = new Inventory_Change__c();
        inventoryChange.Company__c = fuelQuery.company.Id;
        inventoryChange.Company__r = mCompanies.get(fuelQuery.company.Id);
        inventoryChange.Transaction_Date__c = System.now();
        inventoryChange.Type__c = 'Transfer';
        insert inventoryChange;

        if ( !skids.isEmpty()){
            Skid__c skid = skids[0];

            Skid__c pickSkid = new Skid__c();
            pickSkid.Facility2__c = fuelQuery.facility2.Id;
            pickSkid.Company__c= fuelQuery.company.id;
            pickSkid.Item__c= fuelQuery.itemList[14].Id;
            pickSkid.Item__r= fuelQuery.itemList[14];
            pickSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            pickSkid.Stocking_UOM__c = eachUOM.Id;
            pickSkid.Packaging_UOM__c = caseUOM.Id;
            pickSkid.Packaging_UOM__r = caseUOM;
            pickSkid.Container_Item__c = caseItem.Id;
            pickSkid.Container_Item__r = caseItem;
            pickSkid.Location__c = fuelQuery.location2.Id;
            pickSkid.Quantity__c = 1;
            pickSkid.Shipment_Line__c = shls[0].Id;
            pickSkid.Unique_Key__c = null;
            List<Id> lstPkgUom = (List<Id>) JSON.deserialize(pickSkid.Item__r.Packaging_UOM__c, List<Id>.class);
            pickSkid.Quantity_Stocking_UOM__c = pickSkid.Quantity__c * KSE.getConversionFactor (pickSkid.Item__c, fuelQuery.facility2.Facility_Identifier__c,pickSkid.Packaging_UOM__c, pickSkid.Stocking_UOM__c, lstPkgUom);
            insert pickSkid;

            Inventory_Transaction__c pickit = SkidService3.createInventoryTransaction(pickSkid.Item__r, inventoryChange, 'Sales Order Pick', locnSkid.Quantity__c, locnSkid, pickSkid, null);
            insert pickIt;

            Skid__c transferSkid = new Skid__c();
            transferSkid.Facility2__c = fuelQuery.facility2.Id;
            transferSkid.Company__c= fuelQuery.company.id;
            transferSkid.Item__c= fuelQuery.itemList[14].Id;
            transferSkid.Item__r= fuelQuery.itemList[14];
            transferSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            transferSkid.Stocking_UOM__c = eachUOM.Id;
            transferSkid.Packaging_UOM__c = caseUOM.Id;
            transferSkid.Packaging_UOM__r = caseUOM;
            transferSkid.License_Plate_Number__c = packLPN.Id;
            transferSkid.License_Plate_Number__r = packLPN;
            transferSkid.Container_Item__c = palletItem.Id;
            transferSkid.Container_Item__r = palletItem;
            transferSkid.Location__c = fuelQuery.location2.Id;
            transferSkid.Quantity__c = 1;
            transferSkid.Unique_Key__c = null;
            transferSkid.Shipment_Line__c = shls[0].Id;
            transferSkid.Quantity_Stocking_UOM__c = transferSkid.Quantity__c * KSE.getConversionFactor (transferSkid.Item__c, fuelQuery.facility2.Facility_Identifier__c,transferSkid.Packaging_UOM__c, transferSkid.Stocking_UOM__c, lstPkgUom);
            transferSkid.Mixed_Palletized__c = true;
            insert transferSkid;

            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(pickSkid.Item__r, inventoryChange, 'Transfer', transferskid.Quantity__c, pickSkid, transferskid, null);
            system.assert(it.License_Plate_Number__c != null);
            insert it;

            delete new List<Skid__c> { pickSkid, locnSkid};
            delete skids;


            System.assert(new List<Skid__c>([SELECT id FROM Skid__c WHERE License_Plate_Number__c = :packLPN.Id]).size() == 1);

            Map<String, Object> params1 = new Map<String, Object>();
            params1.put('fromLPN', packLPN.Name);
            Action.Response response = BaseController.doAction('REMOVE_FROM_SHIPMENT', JSON.serialize(params1));
            system.assert(response.success, JSON.serialize(response));
        } else {
            system.assert(false);
        }

        Test.stopTest();
    }

    public static testMethod void testScannerRemoveFullPallet () {
        SalesOrderReleaseService.release(fuelQuery.packageSalesOrder.Id);
        Test.startTest();
        eachUOM = fuelQuery.uomList[11];
        caseUOM = fuelQuery.uomList[12];
        palletUOM = fuelQuery.uomList[13];

        palletItem = fuelQuery.itemList[13];
        caseItem = fuelQuery.itemList[12];

        fuelQuery.itemList[14].Item_Attribute__c = null;
        update fuelQuery.itemList[14];

        LPN__c newLPN = new LPN__c(Name='1234567890');
        newLPN.Contents__c = '001,002,003,004,005,006,007,008,009,010,011';
        insert newLPN;

        LPN__c packLPN = new LPN__c(Name='1234567891');
        packLPN.Contents__c = '001,002,003,004,005,006,007,008,009,010,011';
        insert packLPN;

        List<Id> lstPkgUom = new List<Id> {eachUOM.Id, caseUOM.Id, palletUOM.Id};

        SKID__c locnSkid = new SKID__c();
        locnSkid.location__c = fuelQuery.location3.id;
        locnSkid.Bin__c = fuelQuery.bin.id;
        locnSkid.Facility2__c = fuelQuery.facility2.Id;
        locnSkid.Company__c= fuelQuery.company.id;
        locnSkid.Quantity__c = 1;
        locnSkid.Item__c= fuelQuery.itemList[14].Id;
        locnSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
        locnSkid.License_Plate_Number__c = newLPN.Id;
        locnSkid.Stocking_UOM__c = eachUOM.Id;
        locnSkid.Packaging_UOM__c = palletUom.Id;
        locnSkid.Packaging_UOM__r = palletUom;
        locnSkid.Container_Item__c = palletItem.Id;
        locnSkid.Quantity_Stocking_UOM__c = 1 * KSE.getConversionFactor (locnSkid.Item__c, fuelQuery.facility2.Facility_Identifier__c,locnSkid.Packaging_UOM__c, locnSkid.Stocking_UOM__c, lstPkgUom);
        insert locnSkid;

        list<SObject> groupedUpdate = new List<SObject>();


        List<Shipment__c> shipments = [SELECT Id, Name, Status__c FROM Shipment__c];
        for(Shipment__c shipment: shipments) {
            shipment.Status__c = 'Staged';
            groupedUpdate.add(shipment);
        }
        List<Shipment_Line__c> shls = [SELECT Id, Name, Quantity_Allocated__c, Quantity_Picked__c, Quantity_Planned__c, Quantity_To_Pick__c FROM Shipment_Line__c];
        for(Shipment_Line__c shl: shls) {
            shl.Quantity_Picked__c = locnSkid.Quantity_Stocking_UOM__c;
            shl.Quantity_Shipped__c = 0;
            shl.Quantity_From_Stock__c = locnSkid.Quantity_Stocking_UOM__c;

            groupedUpdate.add(shl);
        }
        update groupedUpdate;

        SOQLUtil skidQuery = new SOQLUtil('Skid__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        skidQuery.addAllCustomFields(Item__c.sObjectType,'Item__r.Container_Item__r');
        skidQuery.addAllCustomFields(Bin__c.sObjectType,'Bin__r');
        skidQuery.addAllCustomFields(Package_Class__c.sObjectType, 'Packaging_UOM__r.Package_Class__r');
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        skidQuery.addFields(new Set<String>{ 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',
                'Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Item__r.Container_Item__r.Container_Package_Class__c', 'Item__r.Container_Item__r.Container_Package_Class__r.Level__c','Item__r.Container_Item__r.Container_Package_Class__r.Fractional_Quantities_Allowed__c',
                'Item__r.Container_Item__r.Item_Attribute__c', 'Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__c', 'Item__r.Container_Item__r.Packaging_UOM__c',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Location__r.Bin_Tracked__c', 'Location__r.Track_Bin_Capacity__c',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container__c', 'Shipment_Line__r.Shipment__c','Shipment_Line__c','Shipment_Line__r.Name',
                'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c', 'Location__r.Facility__c', 'Location__r.name', 'Item__r.Packaging_UOM__c', 'Facility2__r.Facility_Identifier__c'
        });
        Id shlId = shls[0].Id;
        skidQuery.setWhereClause('Shipment_Line__c = :shlId');
        List<Skid__c> skids = Database.query(skidQuery.getQuery());
        for ( Skid__c skid: skids ) {
            skid.Container_Item__c = palletItem.Id;
            skid.Container_Item__r = palletItem;
            skid.Type__c = 'Planned Pick';
            skid.Location__c = fuelQuery.location3.Id;
            skid.Bin__c = fuelQuery.bin.Id;
            skid.Quantity__c = 1;
            skid.Packaging_UOM__c = palletUom.Id;
            skid.Stocking_UOM__c = eachUOM.Id;
            skid.Quantity_Stocking_UOM__c = locnSkid.Quantity_Stocking_UOM__c;
            update skid;
            break;
        }

        Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(new Set<String>{fuelQuery.company.Id});

        Inventory_Change__c inventoryChange = new Inventory_Change__c();
        inventoryChange.Company__c = fuelQuery.company.Id;
        inventoryChange.Company__r = mCompanies.get(fuelQuery.company.Id);
        inventoryChange.Transaction_Date__c = System.now();
        inventoryChange.Type__c = 'Transfer';
        insert inventoryChange;

        if ( !skids.isEmpty()){
            Skid__c skid = skids[0];

            Skid__c pickSkid = new Skid__c();
            pickSkid.Facility2__c = fuelQuery.facility2.Id;
            pickSkid.Company__c= fuelQuery.company.id;
            pickSkid.Item__c= fuelQuery.itemList[14].Id;
            pickSkid.Item__r= fuelQuery.itemList[14];
            pickSkid.Type__c = SKIDService.SKID_TYPE_LOCATION;
            pickSkid.Stocking_UOM__c = eachUOM.Id;
            pickSkid.Packaging_UOM__c = palletUOM.Id;
            pickSkid.Packaging_UOM__r = palletUOM;
            pickSkid.License_Plate_Number__c = newLPN.Id;
            pickSkid.License_Plate_Number__r = newLPN;
            pickSkid.Container_Item__c = palletItem.Id;
            pickSkid.Container_Item__r = palletItem;
            pickSkid.Location__c = fuelQuery.location2.Id;
            pickSkid.Quantity__c = 1;
            pickSkid.Shipment_Line__c = shls[0].Id;
            pickSkid.Unique_Key__c = null;
            pickSkid.Quantity_Stocking_UOM__c = pickSkid.Quantity__c * KSE.getConversionFactor (pickSkid.Item__c, fuelQuery.facility2.Facility_Identifier__c,pickSkid.Packaging_UOM__c, pickSkid.Stocking_UOM__c, lstPkgUom);
            insert pickSkid;

            Inventory_Transaction__c pickit = SkidService3.createInventoryTransaction(pickSkid.Item__r, inventoryChange, 'Sales Order Pick', locnSkid.Quantity__c, locnSkid, pickSkid, null);
            insert pickIt;

            delete new List<Skid__c> { locnSkid};
            delete skids;


            System.assert(new List<Skid__c>([SELECT id FROM Skid__c WHERE License_Plate_Number__c = :newLPN.Id]).size() == 1);

            Map<String, Object> params1 = new Map<String, Object>();
            params1.put('fromLPN', newLPN.Name);
            Action.Response response = BaseController.doAction('REMOVE_FROM_SHIPMENT', JSON.serialize(params1));
            system.assert(response.success, JSON.serialize(response));
        } else {
            system.assert(false);
        }

        Test.stopTest();
    }

    public static testMethod void testScannerConfirmShipSuccess() {
        LPN__c newLPN = new LPN__c(Name='1234567890');
        insert newLPN;
        Test.startTest(); 
        SalesOrderReleaseService.release(fuelQuery.packageSalesOrder.Id);

        Configuration__c c = new Configuration__c(Name = 'GTRGRDSPTCH', Value__c = 'DISABLE');
        insert c;

        SKID__c soSkid = [SELECT Id, Name, Company__c, License_Plate_Number__c, Sales_Order_Line__c, Shipment_Line__c, Scanned_For_Shipment__c, Quantity__c FROM SKID__c WHERE Sales_Order_Line__c = :fuelQuery.packageSalesOrder.Sales_Order_Lines__r[0].Id];
        soSkid.License_Plate_Number__c = newLPN.Id;
        soSkid.Quantity__c = -1;
        soSkid.Type__c = SkidService3.SKID_TYPE_LOCATION;
        update soSkid;
         
        list<SObject> groupedUpdate = new List<SObject>();
        List<Shipment__c> shipments = [SELECT Id, Name, Status__c FROM Shipment__c];
        for(Shipment__c shipment: shipments) {
            shipment.Date_Shipped__c = system.today();
            shipment.Status__c = 'Staged';
            groupedUpdate.add(shipment);
        }

        List<Shipment_Line__c> shls = [SELECT Id, Name, Quantity_Allocated__c, Quantity_Picked__c, Quantity_Planned__c, Quantity_To_Pick__c FROM Shipment_Line__c];
        for(Shipment_Line__c shl: shls) {
            shl.Quantity_Picked__c = 1;
            shl.Quantity_Shipped__c = 0;
            shl.Quantity_From_Stock__c = 1;

            groupedUpdate.add(shl);
        }

        update groupedUpdate;

        delete c;

        Map<String, Object> params = new Map<String, Object>();
        params.put('lpnName', string.valueOf(newLPN.Name));
	
    
        ScannerService.scanLPNForShipment scanLPNForShipment = new ScannerService.scanLPNForShipment();
        Action.Response response = scanLPNForShipment.execute(JSON.serialize(params));

        List<String> lpnIds = new List<String>();
        lpnIds.add(string.valueOf(newLPN.Id));

        Map<String, Object> confirmParams = new Map<String, Object>();
        confirmParams.put('lpnIds', lpnIds);
        ScannerService.confirmShip confirmShip = new ScannerService.confirmShip();
        Action.Response confirmResponse = confirmShip.execute(JSON.serialize(confirmParams));

        List<Shipment__c> requeryShipments = [SELECT Id, Name, Status__c FROM Shipment__c];
        
        Test.stopTest();
        system.debug(LoggingLevel.INFO ,confirmResponse);
        system.assertEquals(true, confirmResponse.success);
        system.assertEquals('Confirmed', requeryShipments[0].Status__c);

    }
}