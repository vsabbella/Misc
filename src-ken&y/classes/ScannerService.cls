public with sharing class ScannerService {
	
	public static ExceptionService exService = new ExceptionService();
	
	class ScannerServiceException extends Exception {
    	
    }
    
    private static User_Preference__c userDefaults {
    	get{
    		userDefaults = UserPreference.getInstance().preference;
    		
	    	if(String.isBlank(userDefaults.Id)){
	    		throw new ScannerServiceException('User defaults has not been setup.');
	    	}
	    	
    		return userDefaults;
    	}
    }
    
    public static String palletize(Map<String, Object> params){
	    try{
	    	String companyId = userDefaults.Default_Company__c;
			String facilityId = userDefaults.Default_Facility__c;
			String locationId = userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c;
			
			String itemId = (String) params.get('itemId');
			String lpnName = (String) params.get('lpnName');
			Decimal quantity = (Decimal) params.get('quantity');
			
			List<Object> contents = (List<Object>) params.get('contents');
			
	        Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 
	        								'Item__c' => new Set<Id>{ itemId }, 
	        								'Facility2__c' => new Set<Id>{ facilityId }, 
	        								'Location__c' => new Set<Id>{ locationId } 
	        							  };
		
			List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());
	
	    	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
	
	        for (SkidService3.SerialWrapper sw : InventoryChangeService.getSkids(filters, null, ' AND Consigned_Owner__c = null ',false)) {
	
	            SKID__c toSkid = new SKID__c(Company__c = sw.skid.Company__c, Item__c = sw.skid.Item__c, Item__r = sw.skid.Item__r);
				toSkid.Facility2__c = userDefaults.Default_Facility__c;
				toSkid.Facility2__r = userDefaults.Default_Facility__r;
	            toSkid.Location__c = sw.skid.Location__c;
	            toSkid.Location__r = sw.skid.Location__r;
	            toSkid.Bin__c = sw.skid.Bin__c;
	            toSkid.Bin__r = sw.skid.Bin__r;
	
	            sw.skid.Input_Quantity__c = 0;
	                
	            List<String> skidKey = SkidService3.generateKey(sw.skid, attributeList);
	
	    		serialWrapperMap.put(skidKey, new SkidService3.SerialWrapper(sw.skid, null, sw.serialList, toSkid));
	
	        }
	
	    	Set<String> itemIds = new Set<String>();
	    	Set<String> companyIds = new Set<String>();
	    	Set<String> locationIds = new Set<String>();
	    	Set<String> lpns = new Set<String>();
				
			//Assign container item.
	        map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
		    	
			if(!String.isBlank(companyId)){
	    		companyIds.add(companyId);
	    	}
	
	    	if(!String.isBlank(locationId)){
	    		locationIds.add(locationId);
	    	}
	
			if(!String.isBlank(itemId)){
	    		itemIds.add(itemId);
	    	}
	
	    	if(!String.isBlank(lpnName)){
	    		lpns.add(lpnName);
	    	}
	
	    	Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(companyIds);
	                
	        Map<Id, Item__c> mItems = InventoryChangeService.getItems(itemIds);
	        Item__c item = mItems.get(itemId);
			
			List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
			String caseUOMId = packagingUOMs[1];
			String palletUOMId = packagingUOMs[2];	
			
			Map<Id, Location__c> mLocations = InventoryChangeService.getLocations(locationIds);
	        Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));
	        Map<String, LPN__c> lpnMap = getLPNsByName(lpns);
	
	        Map<String, Inventory_Change__c> icMap = new Map<String, Inventory_Change__c>();
	    	Map<String, Map<List<String>, SkidService3.SerialWrapper>> positiveSerialWrapperMap = new Map<String, Map<List<String>, SkidService3.SerialWrapper>>();
	
	    	DateTime transactionDate = system.now();
			
			if(!itemsWithPackagingUOM.containskey(item)){
				itemsWithPackagingUOM.put(item, new Set<UOM__c>());
			}
	        	
	    	itemsWithPackagingUOM.get(item).add(uomsMap.get(caseUOMId));
			    	
			map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
	        if(itemsWithPackagingUOM.values().size()>0){
		        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
	        }
	
	    	SKID__c fromSkid = new SKID__c();
	    	fromSkid.Company__c = companyId;
	    	fromSkid.Facility2__c = facilityId;
			fromSkid.Facility2__r = userDefaults.Default_Facility__r;
	    	fromSkid.Location__c = locationId;
	    	fromSkid.Item__c = item.Id;
	    	fromSkid.Packaging_UOM__c = caseUOMId;
	    	
	    	Item__c containerItem = containersByItem.get(itemId).get(caseUOMId);
	
	    	if(containerItem !=null){
	        	fromSkid.Container_Item__c = containerItem.Id;
	        }
	
	    	List<String> skidKey = SkidService3.generateKey(fromSkid, attributeList);
	
	    	SkidService3.SerialWrapper serialWrapper;
			if(serialWrapperMap.containsKey(skidKey)){
	    		serialWrapper = serialWrapperMap.get(skidKey);
	    	}else{
	    		// No matching quantity found in the system
	    		throw new ScannerServiceException('Quantity not available');
	    	}
	
	    	SKID__c skid = serialWrapper.skid;
	
	    	Boolean hasError = false;
	
	    	Inventory_Change__c inventoryChange = new Inventory_Change__c();
	    	inventoryChange.Company__c = companyId;
	    	inventoryChange.Company__r = mCompanies.get(companyId);
	    	inventoryChange.Transaction_Date__c = transactionDate;
			inventoryChange.Type__c = 'Transfer';
			    	
	    	String icKey = '' + inventoryChange.Company__c + inventoryChange.Transaction_Date__c;
	
	        if(icMap.containsKey(icKey) == false){
	    	    icMap.put(icKey, inventoryChange);
		    }else{
		    	inventoryChange = icMap.get(icKey);
		    }
	
	    	List<Serial__c> serialList = new List<Serial__c>();
	
    		serialWrapper.toSkid.Packaging_UOM__c = palletUOMId;
	    	serialWrapper.toSkid.Location__r = mLocations.get(skid.Location__c);
			
	    	if(!String.isBlank(lpnName)){
	    		if(lpnMap.containsKey(lpnName)){
	    			serialWrapper.toSkid.License_Plate_Number__c = lpnMap.get(lpnName).Id;
	    		}else{
	    			serialWrapper.toSkid.Temporary_LPN_Holder__c = lpnName;
	    		}

				serialWrapper.toSkid.Container_Item__r = mItems.get(itemId).Container_Item__r;
	    	}
	
			serialWrapper.skid.Input_Quantity__c += quantity;
	
	        Map<List<String>, SkidService3.SerialWrapper> icSerialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
			icSerialWrapperMap.put(skidKey, serialWrapper);
		
	        List<SkidService3.SerialWrapper> inventoryAdded = new List<SkidService3.SerialWrapper>();
			inventoryAdded.addAll(icSerialWrapperMap.values());
	    	
	    	List<InventoryChangeWrapper> icWrapperList = new List<InventoryChangeWrapper>();
	    		
	    	if(inventoryAdded.size() > 0){
	    		InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(icMap.get(icKey), inventoryAdded);
		    	icWrapperList.add(icWrapper);
	    	}
	    	
	    	
	        Savepoint sp = Database.setSavepoint();
	
	        try{
	
	        	if(icWrapperList.size() > 0){
        			DML.insertAsSystem(icMap.values());
	        		InventoryChangeService.inventoryTransfer(icWrapperList, new List<String>{ 'Packaging_UOM__c' });

	        		addPalletContents(lpnName, contents);
	        	}
				
	            return '{"success": true}';
	        }catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	Database.rollback(sp);
	        	throw ex;
	        }
        }catch(Exception ex){
        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
        	return '{"success": false, "error": {"message": "'+ex.getMessage()+'"}}';
        }
    }
    
    public static String dePalletize(Map<String, Object> params){
	    try{
			
			String itemId = (String) params.get('itemId');
			String lpnName = (String) params.get('lpnName');
			String caseNumber = (String) params.get('caseNumber');
			String locationId = params.get('locationId') != null ? (String) params.get('locationId') : '';
			Boolean isPacked = params.get('isPacked') != null ? (Boolean) params.get('isPacked') : false;
			
	    	String companyId = userDefaults.Default_Company__c;
			String facilityId = userDefaults.Default_Facility__c;
			
			if(String.isBlank(locationId)){
				locationId = userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c;
			} 
			
			SOQLUtil soql = new SOQLUtil('LPN__c');
	    	soql.addFields(new Set<String>{'Id', 'Name', 'Contents__c'});
	    	soql.setWhereClause('Name = :lpnName');
	    	
	    	SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
	        skids.addAllCustomFields();
	        skids.setWhereClause('Type__c = \'Location\'');
	        soql.addChildRelationship(skids);
	        
	        List<LPN__c> lpnList = (List<LPN__c>)Database.query(soql.getQuery());
	        
			List<String> contents = new List<String>{caseNumber};
			
	        Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 
	        								'Item__c' => new Set<Id>{ itemId }, 
	        								'Facility2__c' => new Set<Id>{ facilityId }, 
	        								'Location__c' => new Set<Id>{ locationId } 
	        							  };
		
			List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());
	
	    	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
	
	        for (SkidService3.SerialWrapper sw : InventoryChangeService.getSkids(filters, null, ' AND Consigned_Owner__c = null ', isPacked)) {
	
	            SKID__c toSkid = new SKID__c(Company__c = sw.skid.Company__c, Item__c = sw.skid.Item__c, Item__r = sw.skid.Item__r);
	            toSkid.Location__c = sw.skid.Location__c;
	            toSkid.Location__r = sw.skid.Location__r;
	            toSkid.Bin__c = sw.skid.Bin__c;
	            toSkid.Bin__r = sw.skid.Bin__r;
	
	            sw.skid.Input_Quantity__c = 0;
	                
	            List<String> skidKey = SkidService3.generateKey(sw.skid, attributeList);
	
	    		serialWrapperMap.put(skidKey, new SkidService3.SerialWrapper(sw.skid, null, sw.serialList, toSkid));
	
	        }
	
	    	Set<String> itemIds = new Set<String>();
	    	Set<String> companyIds = new Set<String>();
	    	Set<String> locationIds = new Set<String>();
	    	Set<String> packagingUOMs = new Set<String>();
	    	Set<String> lpns = new Set<String>();
				
			if(!String.isBlank(companyId)){
	    		companyIds.add(companyId);
	    	}
	
	    	if(!String.isBlank(locationId)){
	    		locationIds.add(locationId);
	    	}
	
			if(!String.isBlank(itemId)){
	    		itemIds.add(itemId);
	    	}
	
	    	if(!String.isBlank(lpnName)){
	    		lpns.add(lpnName);
	    	}

			Map<Id, Item__c> mItems = InventoryChangeService.getItems(itemIds);
	        Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(companyIds);
	        Map<Id, Location__c> mLocations = InventoryChangeService.getLocations(locationIds);
	        Map<String, LPN__c> lpnMap = getLPNsByName(lpns);
	
	        Item__c item = mItems.get(itemId);

			List<String> itemUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
			
			String eachUOMId = itemUOMs[0];
			String caseUOMId = itemUOMs[1];
			String palletUOMId = itemUOMs[2];
			
			Decimal caseCapacity = KSE.getConversionFactor(item.Id, userDefaults.Default_Facility__r.Facility_Identifier__c, caseUOMId, eachUOMId, itemUOMs);
			
	    	packagingUOMs.add(palletUOMId);
			packagingUOMs.add(caseUOMId);

	        Map<String, UOM__c> uomsMap = getUOMs(packagingUOMs);

	        Map<String, Inventory_Change__c> icMap = new Map<String, Inventory_Change__c>();
	    	Map<String, Map<List<String>, SkidService3.SerialWrapper>> positiveSerialWrapperMap = new Map<String, Map<List<String>, SkidService3.SerialWrapper>>();
	
	    	DateTime transactionDate = system.now();

			SKID__c fromSkid = lpnList[0].SKIDs__r.size() > 0 ? lpnList[0].SKIDs__r[0] : new SKID__c();
	    	
	    	List<String> skidKey = SkidService3.generateKey(fromSkid, attributeList);
	
	    	SkidService3.SerialWrapper serialWrapper;
			if(serialWrapperMap.containsKey(skidKey)){
	    		serialWrapper = serialWrapperMap.get(skidKey);
	    	}else{
	    		// No matching quantity found in the system
	    		system.debug(LoggingLevel.DEBUG, JSON.serialize(attributeList));
	        	system.debug(LoggingLevel.DEBUG, JSON.serialize(skidKey));
	        	system.debug(LoggingLevel.DEBUG, JSON.serialize(serialWrapperMap.keySet()));
	    		throw new ScannerServiceException('No inventory found');
	    	}
	
	    	SKID__c skid = serialWrapper.skid;
	
	    	Boolean hasError = false;
	
	    	Inventory_Change__c inventoryChange = new Inventory_Change__c();
	    	inventoryChange.Company__c = companyId;
	    	inventoryChange.Company__r = mCompanies.get(companyId);
	    	inventoryChange.Transaction_Date__c = transactionDate;
			inventoryChange.Type__c = 'Transfer';
			    	
	    	String icKey = '' + inventoryChange.Company__c + inventoryChange.Transaction_Date__c;
	
	        if(icMap.containsKey(icKey) == false){
	    	    icMap.put(icKey, inventoryChange);
		    }else{
		    	inventoryChange = icMap.get(icKey);
		    }
	
	    	List<Serial__c> serialList = new List<Serial__c>();
			
    		serialWrapper.toSkid.Location__r = mLocations.get(skid.Location__c);
	    	serialWrapper.toSkid.License_Plate_Number__c = null;
	    	// DOIT: Find the case container item: serialWrapper.toSkid.Container_Item__r = mItems.get(itemId).Container_Item__r;
	    
			//Defaults to case capacity for backwards compatibility.
			Decimal quantity = params.get('quantity') != null ? Decimal.valueOf((String) params.get('quantity')) : caseCapacity;
			
			if(quantity == caseCapacity){
				serialWrapper.toSkid.Packaging_UOM__c = caseUOMId;
				serialWrapper.skid.Input_Quantity__c += 1;	
			}else{
				serialWrapper.toSkid.Packaging_UOM__c = eachUOMId;
				serialWrapper.skid.Input_Quantity__c += quantity;
			}
			
			Map<List<String>, SkidService3.SerialWrapper> icSerialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
			icSerialWrapperMap.put(skidKey, serialWrapper);
		
	        List<SkidService3.SerialWrapper> inventoryAdded = new List<SkidService3.SerialWrapper>();
			inventoryAdded.addAll(icSerialWrapperMap.values());
	    	
	    	List<InventoryChangeWrapper> icWrapperList = new List<InventoryChangeWrapper>();
	    		
	    	if(inventoryAdded.size() > 0){
	    		InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(icMap.get(icKey), inventoryAdded);
		    	icWrapperList.add(icWrapper);
	    	}
	    	
	        Savepoint sp = Database.setSavepoint();
	
	        try{
	
	        	if(icWrapperList.size() > 0){
        			DML.insertAsSystem(icMap.values());
        			InventoryChangeService.inventoryTransfer(icWrapperList, new List<String>{ 'Packaging_UOM__c' });
	        		
	        		removePalletContents(lpnName, contents);
	        	}
				
	            return '{"success": true}';
	        }catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	Database.rollback(sp);
	        	throw ex;
	        }
        }catch(Exception ex){
        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
        	return '{"success": false, "error": {"message": "'+ex.getMessage()+'"}}';
        }
    }
    
    public static String putaway(Map<String, Object> params){
	    try{
	    	String lpnName = (String) params.get('lpnName');
	    	String binName = (String) params.get('toBin');
	    	String itemId = (String) params.get('itemId');
	    	
			// Q: How to get pass these in ?
			String companyId;
			String facilityId;
			String locationId; //Mainly this.
			
	    	List<Object> lineItems = (List<Object>) params.get('lines'); 
	    	
	    	Map<String, SKID__c> mapPutawaySkid = new Map<String, SKID__c> ();

	    	List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());
	    	
	    	if(!String.isBlank(lpnName)){
		    	Map<String, LPN__c> lpnMap = getLPNsByName(new Set<String>{lpnName});

		        if(lpnMap.size() > 0 && lpnMap.containsKey(lpnName)){
			        if(lpnMap.get(lpnName).SKIDs__r.size() > 0){
			    		SKID__c putawaySkid = lpnMap.get(lpnName).SKIDs__r[0];
			    		companyId = putawaySkid.Company__c;
			    		facilityId = putawaySkid.Facility2__c;
			    		locationId = putawaySkid.Location__c;
			    		mapPutawaySkid.put('PALLET', putawaySkid);
			    		itemId = putawaySkid.Item__c;
			    	}else{
			    		throw new ScannerServiceException('Pallet is empty: ' + lpnName);
			    	}
		        }else{
		        	throw new ScannerServiceException('Pallet not found: ' + lpnName);
		        }
	    	}
	    	else
	    	if(!String.isBlank(itemId)){
	    		companyId = userDefaults.Default_Company__c;
	    		facilityId = userDefaults.Default_Facility__c;
	    		locationId = userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c;
	    		
	    		Map<Id, Item__c> itemsMap = InventoryChangeService.getItems(new Set<String>{itemId});
	    		
	    		Item__c item = itemsMap.get(itemId);
			    List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
						
				String eachUOMId = packagingUOMs[0];
				String caseUOMId = packagingUOMs[1];
				String palletUOMId = packagingUOMs[2];
				
				Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));
        		map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
		        
		        if(!itemsWithPackagingUOM.containskey(item)){
					itemsWithPackagingUOM.put(item, new Set<UOM__c>());
				}

			    itemsWithPackagingUOM.get(item).add(uomsMap.get(caseUOMId));
			    itemsWithPackagingUOM.get(item).add(uomsMap.get(eachUOMId));
				
				map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
		        if(itemsWithPackagingUOM.values().size()>0){
			        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
		        }
					        
				Decimal caseCapacity = KSE.getConversionFactor(item.Id,userDefaults.Default_Facility__r.Facility_Identifier__c, caseUOMId, eachUOMId, packagingUOMs);
				
	    		for ( Object line: lineItems ) {
		    		if(itemsMap.size() > 0){
                        Map<String, Object> lineItem = (Map<String, Object>) line;
						Decimal quantity = Decimal.valueOf(String.valueOf(lineItem.get('quantity')));
						String putawaySkidType, packagingUOMId;
                        
                        if ( quantity == caseCapacity ) {
                            putawaySkidType = 'CASE';
                            packagingUOMId = caseUOMId;
                            quantity = 1;
                        } else {
                        	putawaySkidType = 'EACH';
                            packagingUOMId = eachUOMId;
                        }
                        
						if ( !mapPutawaySkid.containsKey(putawaySkidType) ) {
							SKID__c putawaySkid;
							putawaySkid = new SKID__c(
				    						Company__c = companyId,
				    						Facility2__c = facilityId,
											Facility2__r = userDefaults.Default_Facility__r,
				    						Location__c = locationId,
				    						Item__c = item.Id,
				    						Item__r = item
			    						  );
			    			
							putawaySkid.Packaging_UOM__c = packagingUOMId;
		
			        		Item__c containerItem = containersByItem.get(item.Id).get(packagingUOMId);
		
					    	if(containerItem !=null){
					        	putawaySkid.Container_Item__c = containerItem.Id;
					        }
					        mapPutawaySkid.put(putawaySkidType, putawaySkid);
						}
                        
                        mapPutawaySkid.get(putawaySkidType).Quantity__c = KSE.addQuantityToField(mapPutawaySkid.get(putawaySkidType).Quantity__c, quantity);
                        
		        	}else{
		        		throw new ScannerServiceException('Item not found');
		        	}
	    		}
	    	}else{
	    		throw new ScannerServiceException('Item or pallet is required');
	    	}
			
            // get the company info
            Set<String> companyIds = new Set<String>();
	        if(!String.isBlank(companyId)){
	    		companyIds.add(companyId);
	    	}
	    	Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(companyIds);
            
            // Get the bin info
			Map<String, Bin__c> binMap = getBinsByName(new Set<String>{binName});
			Bin__c toBin;
	    	if(binMap.containsKey(binName)){
	    		toBin = binMap.get(binName);
	    	}else{
	    		throw new ScannerServiceException('Bin not found: ' + binName);
	    	}
	    	
            // Get the location skids 
	        Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 
	        								'Item__c' => new Set<Id>{ itemId }, 
	        								'Facility2__c' => new Set<Id>{ facilityId }, 
	        								'Location__c' => new Set<Id>{ locationId } 
	        							  };
			
	    	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
	        for (SkidService3.SerialWrapper sw : InventoryChangeService.getSkids(filters, null, ' AND Consigned_Owner__c = null ',false)) {
				
	            SKID__c toSkid = sw.skid.clone(false, true);
	            toSkid.Location__c = toBin.Location__c;
	            toSkid.Location__r = toBin.Location__r;
	            toSkid.Bin__c = toBin.Id;
	            toSkid.Bin__r = toBin;
				
				toSkid.Packaging_UOM__c = null;
				toSkid.Packaging_UOM__r = null;
				
	        	sw.skid.Input_Quantity__c = 0;
	            
	            List<String> skidKey = SkidService3.generateKey(sw.skid, attributeList);
	    		serialWrapperMap.put(skidKey, new SkidService3.SerialWrapper(sw.skid, null, null, toSkid));
	        }
	        
	        DateTime transactionDate = system.now();
	        Inventory_Change__c inventoryChange = new Inventory_Change__c();
	    	inventoryChange.Company__c = companyId;
	    	inventoryChange.Company__r = mCompanies.get(inventoryChange.Company__c);
	    	inventoryChange.Transaction_Date__c = transactionDate;
			inventoryChange.Type__c = 'Transfer';
            
			Map<List<String>, SkidService3.SerialWrapper> icSerialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
				
	        for ( SKID__c putawaySkid : mapPutawaySkid.values() ) {
		        List<String> skidKey = SkidService3.generateKey(putawaySkid, attributeList);
		
		    	SkidService3.SerialWrapper serialWrapper;
		    	if(serialWrapperMap.containsKey(skidKey)){
		    		serialWrapper = serialWrapperMap.get(skidKey);
		    	}else{
                    throw new ScannerServiceException('Not enough quantity for: ' + putawaySkid.Item__r.Name);
		    	}
		
		    	SKID__c fromSkid = serialWrapper.skid;
		    	SKID__c toSkid = serialWrapper.toSkid;
		    	
		    	Decimal inputQuantity = putawaySkid.Quantity__c; // Using count quantity for now.
		
				fromSkid.Input_Quantity__c = KSE.addQuantityToField(fromSkid.Input_Quantity__c, inputQuantity);
		
				icSerialWrapperMap.put(skidKey, serialWrapper);
	        }
		
	        List<SkidService3.SerialWrapper> inventoryAdded = new List<SkidService3.SerialWrapper>();
			inventoryAdded.addAll(icSerialWrapperMap.values());
	    	
	    	List<InventoryChangeWrapper> icWrapperList = new List<InventoryChangeWrapper>();
	    		
	    	if(inventoryAdded.size() > 0){
	    		InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(inventoryChange, inventoryAdded);
		    	icWrapperList.add(icWrapper);
	    	}
	    
	        Savepoint sp = Database.setSavepoint();
	
	        try{
	
	        	if(icWrapperList.size() > 0){
	        		DML.insertAsSystem(inventoryChange);
	        		InventoryChangeService.inventoryTransfer( icWrapperList, null);
	        	}
	        	
	        	Map<String, Object> responseMap = new Map<String, Object>();
	        	responseMap.put('success', true);
	        	responseMap.put('bin', toBin);
	        	responseMap.put('location', toBin.Location__r);
	        	
				return JSON.serialize(responseMap);
				
	        }catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	Database.rollback(sp);
	        	return '{"success": false, "error": {"message": "'+ex.getMessage()+'"}}';
	        }
	    }
        catch(Exception ex){
        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
        	return '{"success": false, "error": {"message": "'+ex.getMessage()+'"}}';
        }	
    }
    
    //DOIT: Use SkidService3 method.
    public static String getToLocation(Map<String, Object> params){

    	String sourceDocument = (String) params.get('Source_Document__c');
    	String ruleType = (String) params.get('Type__c');

    	String fromlocationId = userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c;

    	SchemaUtil util = SchemaUtil.getInstance();

        Map<Id, List<Location__c>> locationMap = new Map<Id, List<Location__c>>();
        Map<Id, List<Id>> locationIdMap = new Map<Id, List<Id>>();
        Set<Id> locationIdSet = new Set<Id>();
        Map<Id, Stock_Movement_Rule__c> matchedRules = new Map<Id, Stock_Movement_Rule__c>();

        Set<String> smrFields = new Set<string>{
        								'id', 'name', 'rule_type__c', 'source_document__c', 'priority__c',
										'location__c', 'location__r.name', 'company__c', 'class__c',
                                        'item__c', 'facility__c', 'location__r.facility__c',
                                        'location__r.bin_tracked__c', 'customer__c', 'Location_List__c'
                                    };

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Stock_Movement_Rule_Settings__c', false);
		soql.addFields(new Set<string>{
			'Source_Document_Path__c','Source_Document_Path_Putaway__c','Stock_Movement_Rule_Field__c'
		});
		soql.setWhereClause('Source_Document__c = :sourceDocument');

		List<Stock_Movement_Rule_Settings__c> smrSettings = Database.query(soql.getQuery());

        for( Stock_Movement_Rule_Settings__c smrSetting : smrSettings ){
            smrFields.add( (smrSetting.Stock_Movement_Rule_Field__c).toLowerCase() );
        }

        String whereClause = 'Rule_Type__c=:ruleType and Source_Document__c=:sourceDocument and Active__c = true Order By Priority__c ASC';

	    soql = new SOQLUtil('Stock_Movement_Rule__c');
	    soql.addFields(smrFields);
	    soql.setWhereClause(whereClause);

        List<Stock_Movement_Rule__c> smrList = (List<Stock_Movement_Rule__c>) Database.query(soql.getQuery());

        String sourceField;
        if( ruleType.toLowerCase() == 'putaway' ){
            sourceField = 'Source_Document_Path_Putaway__c';
        }
        else{
            sourceField = 'Source_Document_Path__c';
        }

        String key='';

        for( Stock_Movement_Rule_Settings__c smrSetting : smrSettings ){
            String fieldName = (String) smrSetting.get(sourceField);
            key += (String) params.get(fieldName);
        }

    	for( Stock_Movement_Rule__c smr : smrList ){
            if( smr.Location_List__c != null ){

	            String smrKey = '';
	            Stock_Movement_Rule__c smrClone = smr.clone(true, true);

                for( Stock_Movement_Rule_Settings__c smrSetting : smrSettings ){

                     String smrKeyField = smrSetting.Stock_Movement_Rule_Field__c;

                     if( smrClone.get(smrKeyField) == null ){
                        smrClone.put( smrKeyField, params.get((String)smrSetting.get(sourceField)));
                     }

                     smrKey+= smrClone.get(smrKeyField);
                }

                if( smrKey == key ){
                	List<Id> locationList = new List<Id>();
                    try{
                        locationList = (list<Id>)JSON.deserialize(String.valueOf(smr.get('Location_List__c')), List<Id>.Class);
                    }
                    catch(Exception e){
                        throw new ScannerServiceException('Invalid location specified on stock movement rule :' + smr.get('name'));
                    }

                    locationIdMap.put(smr.id, locationList);
                    locationIdSet.addAll(locationList);

                    matchedRules.put( smr.id, smr );
                    break;
                }
            }
        }

       	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

		soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new Set<string>{
			'id','Name','Bin_Tracked__c','Facility__c','Facility__r.Company__c'
		});
		soql.setWhereClause('Id IN :locationIdSet');

		Map<Id, Location__c> locations = new Map<Id, Location__c>((List<Location__c>)Database.query(soql.getQuery()));

        for(Id headerId : locationIdMap.keySet()) {
            for(Id locationId : locationIdMap.get(headerId) ){
                if(!locationMap.containsKey(headerId)){
                    locationMap.put(headerId, new list<Location__c>());
                }

                if(locations.containsKey(locationId)){
                    locationMap.get(headerId).add(locations.get(locationId));
                }
            }
        }

        Map<String, Object> responseMap = new Map<String, Object>();

    	if(locationMap.size() > 0){
	    	responseMap.put('records', locationMap);
			responseMap.put('success', true);
		}else{
    		responseMap.put('success', false);
    		responseMap.put('error', new Map<String, String>{'message' => 'No locations found.'});
    	}

		return JSON.serialize(responseMap);
    }
    

    
    public static String getPutawayBin(Map<String, Object> params){
    	
    	SKID__c putawaySkid;
    	Item__c item;
		
    	try{
    		if(params.get('lpnName') != null){
		    	String lpnName = (String) params.get('lpnName');

		    	LPN__c lpn = getLPNsByName(new Set<String>{lpnName}).get(lpnName);

		    	if(lpn.SKIDs__r.size() > 0){
		    		putawaySkid = lpn.SKIDs__r[0];
		    		item = putawaySkid.Item__r;
		    	}else{
		    		throw new ScannerServiceException('Pallet is empty');
		    	}
	    	}
	    	else
	    	if(params.get('itemCode') != null){
	    		String itemCode = (String) params.get('itemCode');
	    		Decimal quantity = Decimal.valueOf((String)params.get('quantity'));
	    		
	    		Map<String,Item__c> itemsMap = getItemsByCode(new Set<String>{itemCode});

	        	if(itemsMap.size() > 0){

	        		item = itemsMap.get(itemCode);
		        	
		        	putawaySkid = new SKID__c(
		    						Company__c = userDefaults.Default_Company__c,
		    						Facility2__c = userDefaults.Default_Facility__c,
									Facility2__r = userDefaults.Default_Facility__r,
		    						Location__c = userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c,
		    						Item__c = item.Id,
		    						Item__r = item,
		    						Quantity__c = quantity
	    						  );
	
	    			List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
					
		        	String eachUOMId = packagingUOMs[0];
					String caseUOMId = packagingUOMs[1];
					String palletUOMId = packagingUOMs[2];
					
					Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));
	        		map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();

					if(!itemsWithPackagingUOM.containskey(item)){
						itemsWithPackagingUOM.put(item, new Set<UOM__c>());
					}

			    	itemsWithPackagingUOM.get(item).add(uomsMap.get(caseUOMId));
			    	itemsWithPackagingUOM.get(item).add(uomsMap.get(eachUOMId));

					map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
			        if(itemsWithPackagingUOM.values().size()>0){
				        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
			        }
			        
					Decimal caseCapacity = KSE.getConversionFactor(item.Id,userDefaults.Default_Facility__r.Facility_Identifier__c, caseUOMId, eachUOMId, packagingUOMs);
					
					String packagingUOMId = '';
					
					if(quantity == caseCapacity){
				        packagingUOMId = caseUOMId;
					}else{
						packagingUOMId = eachUOMId;
					}
					
					putawaySkid.Packaging_UOM__c = packagingUOMId;
					Item__c containerItem = containersByItem.get(item.Id).get(packagingUOMId);

			    	if(containerItem !=null){
			        	putawaySkid.Container_Item__c = containerItem.Id;
			        	putawaySkid.Container_Item__r = containerItem;
			        }

	        	}else{
	        		throw new ScannerServiceException('Item not found: ' + itemCode);
	        	}
	    	}else{
	    		throw new ScannerServiceException('Item or pallet is required');
	    	}

	    	Stock_Movement_Rule__c stockMovementRule = new Stock_Movement_Rule__c();
	    	stockMovementRule.Source_Document__c = 'Directed Putaway';
	    	stockMovementRule.Item__r = item;
	    	
			for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
    
	            if( smrs.Source_Document__c == stockMovementRule.Source_Document__c ){
	                
	                if( smrs.Source_Document_Path__c == null || smrs.Source_Document_Path_Putaway__c == null ){
	                    throw new ScannerServiceException(Label.Source_Document_Path_Fields_Not_Populated);
	                }
	                
	                string smrKeyField = smrs.Stock_Movement_Rule_Field__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),'');
	                string sDocPathPutaway = smrs.Source_Document_Path_Putaway__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),'');
	                system.debug(LoggingLevel.DEBUG, smrKeyField);
	                system.debug(LoggingLevel.DEBUG, sDocPathPutaway);
	                
	                if(smrKeyField.contains('facility__c')){
	                	sDocPathPutaway = 'facility2__c';
	                }
	                
	                if(smrKeyField.contains('source_location__c')){
	                	smrKeyField = 'location__c';
	                }
	                
	                if(smrKeyField.contains('container_package_class__c')){
	                	system.debug(LoggingLevel.DEBUG, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid.Container_Item__r));
	                	stockMovementRule.put(smrKeyField, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid.Container_Item__r));
	                }else{
	                	system.debug(LoggingLevel.DEBUG, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid));
	                	stockMovementRule.put(smrKeyField, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid));
	                }
	            }
	        }
    
	    	/*stockMovementRule.Company__c =  putawaySkid.Company__c;
	    	stockMovementRule.Facility__c = putawaySkid.Facility2__c;
	    	stockMovementRule.Location__c = putawaySkid.Location__c;
	    	stockMovementRule.Item__c = putawaySkid.Item__c;
	    	stockMovementRule.Packaging_UOM__c = putawaySkid.Packaging_UOM__c;
	    	stockMovementRule.Source_Document__c = 'Transfer';
	    	
	    	if(putawaySkid.Container_Item__r != null){
	    		stockMovementRule.Container_Package_Class__c = putawaySkid.Container_Item__r.Container_Package_Class__c;
	    	}*/
	    	
	    	system.debug(LoggingLevel.DEBUG, stockMovementRule);
	    	SkidService3.directPutawayWrapper putawayWrapper = new SkidService3.directPutawayWrapper(stockMovementRule, putawaySkid);

	    	map<Integer, Bin__c> binMap = SkidService3.availableBinForDirectPutaway(new List<SkidService3.directPutawayWrapper>{putawayWrapper});

	    	Map<String, Object> responseMap = new Map<String, Object>();
    		responseMap.put('item', item);
    		responseMap.put('binMap', binMap);
    		responseMap.put('success', true);

    		return JSON.serialize(responseMap);
    	}catch(Exception ex){
    		system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
    		return '{"success": false, "error": {"message": "'+ex.getMessage()+'"}}';
    	}
    }
    
    public static String getPalletCapacity(Map<String, Object> params){
     	String itemId = (String) params.get('itemId');
     	   	
    	return String.valueOf(getPalletCapacity(itemId));
    }
    
    public static Decimal getPalletCapacity(String itemId){
     	// DOIT: Remove the need for requerying the item.
    	Item__c item = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Id = :itemId];
    	
    	List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
    	
    	return KSE.getConversionFactor( item.Id,userDefaults.Default_Facility__r.Facility_Identifier__c, packagingUOMs[2], packagingUOMs[1], packagingUOMs );
    	
    }

    public static void removePalletContents(String lpnName, List<String> caseNumbers){
    	
    	//Lock the LPNs while modifying the contents.
    	LPN__c lpn = [SELECT Id, Name, Contents__c
				 		FROM LPN__c 
			 		   WHERE Name = :lpnName FOR UPDATE][0];
		
		Set<String> contents = new Set<String>();
		 
		if(!String.isBlank(lpn.Contents__c)){
			contents = new Set<String>(lpn.Contents__c.split(','));
		}
		
		for(Object caseNumber : caseNumbers){
			String caseString = String.valueOf(caseNumber);
			
			if(! contents.contains(caseString)){
				throw new ScannerServiceException('Barcode not found on pallet: ' + caseString);
			}else{
				contents.remove(caseString);
			}
		}	
		
		lpn.Contents__c = String.join(new List<String>(contents), ',');
	
		update lpn;
		
    }
    
    public static void addPalletContents(String lpnName, List<Object> caseNumbers){
    	
    	//Lock the LPNs while modifying the contents.
    	LPN__c lpn = [SELECT Id, Name, Contents__c
				 		FROM LPN__c 
			 		   WHERE Name = :lpnName FOR UPDATE][0];
		
		Set<String> contents = new Set<String>();
		 
		if(!String.isBlank(lpn.Contents__c)){
			contents = new Set<String>(lpn.Contents__c.split(','));
		}
		
		for(Object caseNumber : caseNumbers){
			String caseString = String.valueOf(caseNumber);
			
			if(contents.contains(caseString)){
				throw new ScannerServiceException('Duplicate case found: ' + caseString);
			}else{
				contents.add(caseString);
			}
		}	
		
		lpn.Contents__c = String.join(new List<String>(contents), ',');
	
		update lpn;
		
    }
    
    public static String getLPN(Map<String, Object> params) {
		String lpnName = (String) params.get('lpnName');
		Map<String, Object> responseMap = new Map<String, Object>();
		
		Map<String, LPN__c> lpnMap = getLPNsByName(new Set<String>{lpnName});
		
		if (lpnMap.size() > 0) {
			Decimal palletCapacity = 0;
			Decimal palletQuantity = 0;

			Item__c item = new Item__c();
			LPN__c lpn = lpnMap.get(lpnName);
			List<String> contents = new List<String>();

			if (!String.isBlank(lpn.Contents__c)) {
				contents = lpn.Contents__c.split(',');
			}

			if (lpn.SKIDs__r.size() > 0) {
				palletCapacity = getPalletCapacity(lpn.SKIDs__r[0].Item__c);
				item = lpn.SKIDs__r[0].Item__r;

				List<Id> packagingUOMS = (List<Id>) JSON.deserialize(item.Packaging_UOM__c, List<Id>.class);

				Id skidPackagingUOM = lpn.SKIDs__r[0].Packaging_UOM__c;
				Id casePackagingUOM = packagingUOMS[1];

				if(skidPackagingUOM == casePackagingUOM){
					palletQuantity = lpn.SKIDs__r[0].Quantity__c;
				} else {//Pallet
					palletQuantity = lpn.SKIDs__r[0].Quantity__c * palletCapacity;
				}
			}

			responseMap.put('records', lpnMap.values());
			responseMap.put('capacity', palletCapacity);
			responseMap.put('item', item);
			responseMap.put('quantity', palletQuantity);
			responseMap.put('contents', contents);
			responseMap.put('success', true);

			return JSON.serialize(responseMap);

		} else {
			return '{"success": false, "error": {"message": "LPN not found"}}';
		}
    }

	public static void removeWorkOrderContents(String woId, List<Object> caseNumbers){

		Work_Order__c workOrder = [SELECT Id, Name, Contents__c
									 FROM Work_Order__c
									WHERE Id = :woId FOR UPDATE][0];

		Set<String> contents = new Set<String>();

		if(!String.isBlank(workOrder.Contents__c)){
			contents = new Set<String>(workOrder.Contents__c.split(','));
		}

		for(Object caseNumber : caseNumbers){
			String caseString = String.valueOf(caseNumber);

			if(! contents.contains(caseString)){
				throw new ScannerServiceException('Case not found: ' + caseString);
			}else{
				contents.remove(caseString);
			}
		}

		workOrder.Contents__c = String.join(new List<String>(contents), ',');

		update workOrder;

	}

	public class addWorkOrderContents implements Action.Target{
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();

	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
	        	String woId = String.valueOf(params.get('woId'));
	        	Object caseNumber = params.get('caseNumber');
	        	addWorkOrderContents(woId, new List<Object>{caseNumber});
	        	resp.success = true;
	        }
	        catch(Exception ex){
	        	resp.success = false;
	        	resp.error.put('message', ex.getMessage());
	        }

	        return resp;
        }
    }
    
	public static void addWorkOrderContents(String woId, List<Object> caseNumbers){

		Work_Order__c workOrder = [SELECT Id, Name, Contents__c
									 FROM Work_Order__c
									WHERE Id = :woId FOR UPDATE][0];

		 Set<String> contents = new Set<String>();


		if(!String.isBlank(workOrder.Contents__c)){
			contents = new Set<String>(workOrder.Contents__c.split(','));
		}
		
		for(Object caseNumber : caseNumbers){
			String caseString = String.valueOf(caseNumber);

			if(contents.contains(caseString)){
				throw new ScannerServiceException('Case Already Complete: ' + caseString);
			}else{
				contents.add(caseString);
			}
		}
		
		workOrder.Contents__c = String.join(new List<String>(contents), ',');

		update workOrder;

	}

    public class getScannerSettings implements Action.Target {
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();
			Set<String> enabledApps = new Set<String>();
			
            try{
            	Set<Id> assignedPermSets = new Map<Id, PermissionSet>([
											        SELECT Id 
											          FROM PermissionSet
											         WHERE Id 
											         	IN (
												            SELECT PermissionSetId
												              FROM PermissionSetAssignment
												             WHERE AssigneeId = :UserInfo.getUserId()
													       )
											    ]).keySet();
			    
			    for(CustomPermission customPerm :  [
			    									SELECT DeveloperName 
			    									  FROM CustomPermission
												     WHERE Id 
												        IN (
												            SELECT SetupEntityId
												              FROM SetupEntityAccess
												             WHERE SetupEntityType = 'CustomPermission'
												               AND ParentId 
												                IN :assignedPermSets
											       		   )
												   ]){
												   	
					enabledApps.add(customPerm.DeveloperName);
			    }
			    
			    resp.success = true;
				resp.results.put('enabledApps', enabledApps) ;
				resp.results.put('userDefaults', userDefaults) ;
				
				Map<String, Configuration__c> allConfigs = Configuration__c.getAll();
				Map<String, Configuration__c> scannerConfigs = new Map<String, Configuration__c>();
				
				for(String configName : allConfigs.keySet()){
					if(configName.startsWith('SCANNER')){
						scannerConfigs.put(configName, allConfigs.get(configName));
					}
				}
				
				resp.results.put('configs', scannerConfigs) ;
				
            }catch(Exception ex){
                system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
				resp.success = false;
				resp.error.put('message', ex.getMessage());
			}
            return resp;
        }
    }
    
    // This will fetch the conversion factor for the users default facility
    public class getConversionFactor implements Action.Target {
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();

            try{
            	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(string.valueOf(obj));

            	String itemId = (String) params.get('itemId');
		    	String uom1 = (String) params.get('uom1');
		    	String uom2 = (String) params.get('uom2');
		    	
    			Item__c item = [SELECT Id, Packaging_UOM__c FROM Item__c WHERE Id = :itemId];

    	        List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
    	        Map<String, UOM__c> uomMap = getUOMs(new Set<String>(packagingUOMs));
    	        
	    		resp.success = true;
    			resp.results.put('conversionFactor', KSE.getConversionFactor( itemId,userDefaults.Default_Facility__r.Facility_Identifier__c, uom1, uom2, packagingUOMs )) ;
    			resp.results.put('uomMap', uomMap);
    			
            }catch(Exception ex){
                system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
				resp.success = false;
				resp.error.put('message', ex.getMessage());
			}
            return resp;
        }
    }
    
    public class getRecords implements Action.Target {
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();
            try{
            	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(string.valueOf(obj));

            	String sObjectName = (String) params.get('sObjectName');
				Boolean enforceFLS = params.get('enforceFLS') != null ? (Boolean) params.get('enforceFLS') : false; //Disable by default.
				Boolean isAggregateQuery = params.get('isAggregateQuery') != null ? (Boolean) params.get('isAggregateQuery') : false;

				//String orderByClause = (String) params.get('orderByClause'); // Not namespace safe
				//Boolean setNullsLast = (Boolean) params.get('setNullsLast'); //DOIT: Why doesn't SOQLUtil does not support this ?

				SOQLUtil soql = new SOQLUtil(sObjectName, enforceFLS, isAggregateQuery);

				if(params.get('queryFields') != null){
					for(Object fieldName : (List<Object>) params.get('queryFields')){
						soql.addField(String.valueOf(fieldName));
					}
				}

				if(params.get('sortFields') != null){

					Map<String, Object> sortFields = (Map<String, Object>) params.get('sortFields');

					Map<String, SOQLUtil.sortOrder> mInputFieldNameToOrder = new Map<String, SOQLUtil.sortOrder>();

					for(String fieldName : sortFields.keySet()){

						String sortOrderVal = (String) sortFields.get(fieldName);

						if(sortOrderVal == 'ASC') {
					 		mInputFieldNameToOrder.put(fieldName.trim(), SOQLUtil.sortOrder.sortASC);
					 	}
					 	else if(sortOrderVal == 'DESC') {
					 		mInputFieldNameToOrder.put(fieldName.trim(), SOQLUtil.sortOrder.sortDESC);
					 	}
					 	else {
					 		throw new ScannerServiceException('Invalid sort order specified for ' + fieldName);
					 	}

					}
					
					if(params.get('nullsLast') != null){
						soql.setOrderBy(mInputFieldNameToOrder, (Boolean) params.get('nullsLast'));
					}else{
						soql.setOrderBy(mInputFieldNameToOrder);
					}
				}

				if(params.get('whereClause') != null){
					soql.setWhereClause((String) params.get('whereClause'));
				}

				if(params.get('limitRows') != null){
					soql.setLimit((Integer) params.get('limitRows'));
				}

				if(params.get('offset') != null){
					soql.setLimit((Integer) params.get('offset'));
				}

				if(params.get('searchRecycle') != null){
					soql.setSearchRecycle((Boolean) params.get('searchRecycle'));
				}

				//Child relationship query
				if(params.get('children') != null){
					List<Object> children = (List<Object>) params.get('children');

					for(Object child : children){

						Map<String, Object> childParams = (Map<String, Object>) child;

						String relationshipName = (String) childParams.get('relationshipName');

						SOQLUtil.ChildRelationship childRelationship = new SOQLUtil.ChildRelationship(soql, relationshipName);

						if(childParams.get('queryFields') != null){
							for(Object fieldName : (List<Object>) childParams.get('queryFields')){
								childRelationship.addField(String.valueOf(fieldName));
							}
						}

						if(childParams.get('sortFields') != null){
							Map<String, Object> sortFields = (Map<String, Object>) childParams.get('sortFields');

							Map<String, SOQLUtil.sortOrder> mInputFieldNameToOrder = new Map<String, SOQLUtil.sortOrder>();

							for(String fieldName : sortFields.keySet()){

								String sortOrderVal = (String) sortFields.get(fieldName);

								if(sortOrderVal == 'ASC') {
							 		mInputFieldNameToOrder.put(fieldName.trim(), SOQLUtil.sortOrder.sortASC);
							 	}
							 	else if(sortOrderVal == 'DESC') {
							 		mInputFieldNameToOrder.put(fieldName.trim(), SOQLUtil.sortOrder.sortDESC);
							 	}
							 	else {
							 		throw new ScannerServiceException('Invalid sort order specified for ' + fieldName);
							 	}

							}

							childRelationship.setOrderBy(mInputFieldNameToOrder);
						}

						if(childParams.get('whereClause') != null){
							childRelationship.setWhereClause((String) childParams.get('whereClause'));
						}

						if(childParams.get('limitRows') != null){
							childRelationship.setLimit(Integer.valueOf(childParams.get('limitRows')));
						}

						soql.addChildRelationship(childRelationship);
					}
				}

				List<SObject> records = Database.query(soql.getQuery());

				if(records.size()>0){

					String recordsJSON = JSON.serialize(records);
					Boolean namespace = params.get('namespace') != null ? (Boolean) params.get('namespace') : false; //Remove namespace by default.

					if(!namespace){
						recordsJSON = recordsJSON.replace(KSE.NamespaceUU, '');
					}

					resp.success = true;
    				resp.results.put('records', recordsJSON) ;

				}else{
					resp.success = false;
    				resp.error.put('message', 'No records found') ;
				}

            }catch(Exception ex){
                system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
				resp.success = false;
				resp.error.put('message', ex.getMessage()) ;
            }
            return resp;
        }
    }
    
    public class scanLPNForShipment implements Action.Target{
		public Action.Response execute(Object obj){
			Action.Response resp = new Action.Response();

			Savepoint sp = Database.setSavepoint();

			try{
				Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(string.valueOf(obj));
				String lpnName = string.valueOf(params.get('lpnName'));

				SchemaUtil schema = SchemaUtil.getInstance();
				Set<String> skidsFields = schema.getAllCustomFieldsFromObject(null, 'SKID__c');
				skidsFields.add('Id');

				SOQLUtil soql = new SOQLUtil('LPN__c');
				SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
				soql.addFields(new Set<String>{'Id', 'Name'});
				skids.addFields(skidsFields);
				soql.addChildRelationship(skids);
				soql.setWhereClause('Name = :lpnName');

				List<LPN__c> lpnList = Database.query(soql.getQuery());

				List<SKID__c> skidList = new List<SKID__c>();

				for(LPN__c lpn : lpnList) {
					for(SKID__c skid : lpn.SKIDs__r) {
						skid.Scanned_For_Shipment__c = TRUE;
						skidList.add(skid);
					}
				}

				//Update as system when dealing with SKIDS
				List<Database.SaveResult> saveResult = DML.updateAsSystem(skidList);
				resp.result = new Action.Result();
				resp.result.resultObject = lpnList;
				resp.success = true;
			}catch(Exception ex){
				system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
				Database.rollback(sp);
				resp.result = new Action.Result();
				resp.result.resultObject = '{"error": {"message": "'+ex.getMessage()+'"}}';
				resp.success = false;
			}
			return resp;
		}
	}

	public class confirmShip implements Action.Target{
		public Action.Response execute(Object obj){
			Action.Response resp = new Action.Response();

			Savepoint sp = Database.setSavepoint();

			try{
				Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(string.valueOf(obj));
				List<Object> rawLpnObjects = (List<Object>)params.get('lpnIds');
				Set<String> lpnIds = new Set<String>();
				for(Object r : rawLpnObjects) {
					lpnIds.add(string.valueOf(r));
				}

				SchemaUtil schema = SchemaUtil.getInstance();
				Set<String> skidsFields = schema.getAllCustomFieldsFromObject(null, 'SKID__c');
				skidsFields.addAll(new Set<String>{'Id', 'Item__r.Packaging_UOM__c', 
					'Item__r.Container__c', 'Packaging_UOM__r.Name', 'Shipment_Line__r.Shipment__c', 'Item__r.Item_Attribute__c','Item__r.Item_Attribute__r.Serial_Number__c',
					'Location__r.Track_Bin_Capacity__c', 'Location__r.Mixed_Bins_Allowed__c',
					'Bin__r.Blocked__c', 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c',
		            'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
		            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
		            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
		            'Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Item__r.Packaging_UOM__c',
					'Facility2__r.Facility_Identifier__c', 'Item__r.Stocking_UOM__c'
		        });

				SOQLUtil lpnQuery = new SOQLUtil('LPN__c');
				lpnQuery.addFields(new Set<String>{'Id', 'Name'});
				SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(lpnQuery, 'SKIDs__r');
				skids.addFields(skidsFields);
				skids.addFields(new Set<String>(SkidService3.attributesForUniqueKey));
				lpnQuery.setWhereClause('Id IN :lpnIds');
				skids.setWhereClause('Scanned_For_Shipment__c = TRUE');
				lpnQuery.addChildRelationship(skids);

				List<LPN__c> lpnList = Database.query(lpnQuery.getQuery());

				Map<Id, List<SkidService3.SerialWrapper>> mSerialWrappersByShipmentLine = new Map<Id, List<SkidService3.SerialWrapper>>();
				Set<Id> shipmentLineIds = new Set<Id>();
				Set<Id> shipmentIds = new Set<Id>();
				Map<Id, String> mUOMNamesByShipmentLines = new Map<Id, String>();
				
				for(LPN__c lpn : lpnList) {
					for(SKID__c skid : lpn.SKIDs__r) {
						shipmentLineIds.add(skid.Shipment_Line__c);
						shipmentIds.add(skid.Shipment_Line__r.Shipment__c);
					}
				}

				Set<String> shipmentLineFields = schema.getAllCustomFieldsFromObject(null, 'Shipment_Line__c');
				shipmentLineFields.addAll(new Set<String>{
						'Item__r.Non_Inventory__c',
						'Item__r.Packaging_UOM__c',
						'Item__r.Item_Attribute__c',
						'Item__r.Stocking_UOM__c',
						'Item__r.Track_Install_Base__c',
						'Item__r.Item_Attribute__r.Expiration_Date__c',
						'Item__r.Company__c',
						
						'Sales_Order_Line__r.Selling_UOM__c',
						'Sales_Order_Line__r.Quantity_Allocated__c',
						'Sales_Order_Line__r.Quantity_Shipped__c',
						'Sales_Order_Line__r.Parent_Sales_Order_Line__c',
						'Sales_Order_Line__r.Customer_Site__c',
						'Sales_Order__r.Ship_To__c',
						'Sales_Order__r.Company__c',
						'Sales_Order__r.Ship_To__r.Track_Install_Base__c',
						
						'Order_Line__r.Deliver_To_Facility__c',
                        'Order_Line__r.Ship_From_Facility__r.Facility_Identifier__c',
                        'Order_Line__r.Deliver_To_Facility__r.Facility_Identifier__c',
						'Order_Line__r.Deliver_To_Location__c', 
						'Order_Line__r.Quantity_Allocated__c', 
						'Order_Line__r.Quantity_Shipped__c',
            			'Order_Line__r.Receiving_Company__c', 
            			'Order_Line__r.Receiving_Item__c',  
            			'Order_Line__r.Packaging_UOM__c',  
            			'Order_Line__r.Receiving_Item__r.Packaging_UOM__c',  
            			'Order_Line__r.Receiving_Item__r.Stocking_UOM__c',
            			
						'Shipment__r.Company__c',
						'Shipment__r.Company__r.Serial_Control__c',
						'Shipment__r.Date_Shipped__c',
						
						'Facility__r.Facility_Identifier__c'
				});
				
				SOQLUtil shipmentLineQuery = new SOQLUtil('Shipment_Line__c');
				shipmentLineQuery.addFields(shipmentLineFields);
				shipmentLineQuery.setWhereClause('Id IN :shipmentLineIds OR (Shipment__c IN :shipmentIds AND Item__r.Non_Inventory__c = TRUE)');

				Map<Id, Shipment_Line__c> mShipmentLinesByIDs = new Map<Id, Shipment_Line__c>((List<Shipment_Line__c>)Database.Query(shipmentLineQuery.getQuery()));

				for(LPN__c lpn : lpnList) {
					for(SKID__c skid : lpn.SKIDs__r) {

						mUOMNamesByShipmentLines.put(skid.Shipment_Line__c, skid.Packaging_UOM__r.Name);

						if(mSerialWrappersByShipmentLine.containsKey(skid.Shipment_Line__c)) {
							List<SkidService3.SerialWrapper> swList = mSerialWrappersByShipmentLine.get(skid.Shipment_Line__c);
							swList.add(new SkidService3.SerialWrapper(skid, new List<Serial__c>()));
							mSerialWrappersByShipmentLine.put(skid.Shipment_Line__c, swList);
						} else {
							mSerialWrappersByShipmentLine.put(skid.Shipment_Line__c,
									new List<SkidService3.SerialWrapper>{new SkidService3.SerialWrapper(skid, new List<Serial__c>())});
						}
					}
				}

				//Generate Shipment Line Wrappers

				List<LineWrapper> wrappers = new List<LineWrapper>();

				Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>> ();
				for(Id shlId : mShipmentLinesByIDs.keySet()) {
					Shipment_Line__c shipmentLine = mShipmentLinesByIDs.get(shlId);
					
					if(mUOMNamesByShipmentLines.containsKey(shlId) && mSerialWrappersByShipmentLine.containsKey(shlId)) {
						String uom = mUOMNamesByShipmentLines.get(shlId);
						List<SkidService3.SerialWrapper> serialWrappers = mSerialWrappersByShipmentLine.get(shlId);
					
						if ( !itemPackagingUomCache.containsKey(shipmentLine.Item__c) ) {
							List<Id> lstPkgUom = (List<Id>) JSON.deserialize(shipmentLine.Item__r.Packaging_UOM__c, List<Id>.class);
							itemPackagingUomCache.put(shipmentLine.Item__c, lstPkgUom);
						}
						
						Decimal convFactor = 1;
						
						if(shipmentLine.Sales_Order_Line__c != null){
							convFactor = KSE.getConversionFactor(
											shipmentLine.Item__c,
											shipmentLine.Facility__r.Facility_Identifier__c,
											shipmentLine.Sales_Order_Line__r.Selling_UOM__c,
											shipmentLine.Item__r.Stocking_UOM__c,
											itemPackagingUomCache.get(shipmentLine.Item__c)); 
						}
						
						if(shipmentLine.Order_Line__c != null){
							convFactor = KSE.getConversionFactor(
											shipmentLine.Item__c,
											shipmentLine.Facility__r.Facility_Identifier__c,
											shipmentLine.Order_Line__r.Packaging_UOM__c,
											shipmentLine.Order_Line__r.Receiving_Item__r.Stocking_UOM__c,
											itemPackagingUomCache.get(shipmentLine.Item__c)); 
						}
						
						LineWrapper wrapper = new LineWrapper(
								new Shipment__c(
										Id = shipmentLine.Shipment__c,
										Company__c = shipmentLine.Shipment__r.Company__c,
										Company__r = shipmentLine.Shipment__r.Company__r,
										Date_Shipped__c = system.now()
								),
								shipmentLine,
								serialWrappers
						);
						wrapper.convFactor = convFactor;
						wrapper.uom = uom;

						wrappers.add(wrapper);
					}
					else
					if (shipmentLine.Item__r.Non_Inventory__c == true) {
			            LineWrapper shlWrapper = new LineWrapper(
			            							new Shipment__c(
															Id = shipmentLine.Shipment__c,
															Company__c = shipmentLine.Shipment__r.Company__c,
															Company__r = shipmentLine.Shipment__r.Company__r,
															Date_Shipped__c = system.now() 
													), 
			            							shipmentLine, 
			            							new List<SkidService3.SerialWrapper>()
			            						 );
						    
		                //Quantity Stocking UOM = 0 will ignore non inventory items when calculating quantity picked vs picked skid quantity
		                shlWrapper.serialWrappers.add(
		                	new SkidService3.SerialWrapper(
		                		new SKID__c(
		                			Quantity__c = shipmentLine.Quantity_Planned__c, 
		                			Quantity_Stocking_UOM__c = 0
		                		), 
		                		new List<Serial__c>()
		                	)
		                );
		                
		                wrappers.add(shlWrapper);
			        }
				}

				ShipmentInventoryService.confirmShip(wrappers);
				rerelease(shipmentIds);

				resp.success = true;
			}catch(Exception ex){
				system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
				Database.rollback(sp);
				resp.error.put('message', ex.getMessage());
				resp.error.put('stackTrace', ex.getStackTraceString());
				resp.success = false;
			}
			return resp;
		}
	}
	
	@future
	private static void rerelease(Set<Id> shipmentIds) {
		ShipmentRereleaseService.rerelease(shipmentIds);
	}
	
    public class getWorkOrderCompleteData implements Action.Target {
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();
            
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
                
            String woId = String.valueOf(params.get('woId'));
            String caseNumber = String.valueOf(params.get('caseNumber'));
			Decimal caseQuantity = Decimal.valueOf(String.valueOf(params.get('caseQuantity')));
            Boolean isUndo = params.containsKey('isUndo') ? Boolean.valueOf(params.get('isUndo')) : false;
			try {
				SOQLUtil util = new SOQLUtil('Work_Order__c');
				util.addFields(new Set<String>{'Id','Facility__c'});
				util.setWhereClause('Id = : woId');
				Work_Order__c workOrder = Database.query(util.getQuery());

				if ( woID == null || caseNumber == null || caseQuantity == null ) throw new ScannerServiceException ('Invalid parameters specified for the Complete.');
                
                Process_Request__c pr = new Process_Request__c ();
                if ( isUndo ) {
	                pr.Process_Call__c='Work Order Uncomplete';
                } else {
                    pr.Process_Call__c='Work Order Complete';
                }
                pr.Work_Order__c = woId;
                pr.Target_Document_Id__c = woId;
                pr.Parameter_Value__c = caseNumber;
                pr.Quantity__c = caseQuantity;
                pr.Status__c = 'Draft';
                pr.Facility__c = workOrder.Facility__c;
                insert pr;
                
                ScannerService.enqueueJob (pr);
                
                resp.success = true;
            } catch (Exception ex ) {
                resp.error.put('message', ex.getMessage());
                resp.error.put('stackTrace', ex.getStackTraceString());
                resp.success = false;
                
                ExceptionUtil.WO_COMPLETE_EXCEPTION.description += '\n' + ex.getMessage();
                exService.setException( new Work_Order__c(Id=woId), ExceptionUtil.WO_COMPLETE_EXCEPTION);
            }
            
            return resp;
            
        }
    }
    
    public static void enqueueJob ( Process_Request__c pr ) {
        // Check custom settings
        Configuration__c bulkifyProcessRequest = Configuration__c.getValues('BULKIFY_WORK_ORDER_QUEUE');
        Boolean isBulkifyRequests = bulkifyProcessRequest !=null && bulkifyProcessRequest.Value__c.toUpperCase() == 'TRUE' ? true : false;
        Integer MAX_QUEUE_JOBS = 10;
		Integer DEFAULT_QUEUE_JOB_SIZE = 1;

        if ( isBulkifyRequests ) {
			// Bulkifies the request by the facility
			Id currentUser = UserInfo.getUserId();
			Set<Id> userIds = new Set<Id> {currentUser};
			Boolean bEnqueueJob = false;
			Map<Id, Id> faciltyByUser = new Map<Id, Id>();

			SOQLUtil soql = new SOQLUtil('AsyncApexJob', false); //enforceFLS=false, running in system mode
			soql.addFields(new set<string>{
					'id', 'status', 'ApexClass.Name', 'CreatedById'
			});

			soql.setWhereClause('status IN(\'Holding\',\'Queued\',\'Preparing\',\'Processing\') AND ApexClass.Name = \'WorkOrderQueue\'  ');// dont confuse myself with other jobs which share my class name
			soql.setOrderByClause('CreatedDate desc');
			List<AsyncApexJob> runningJobs = Database.query(soql.getQuery());

			for ( AsyncApexJob job : runningJobs) {
				userIds.add(job.CreatedById);
			}

			List<User_Preference__c> prefs =getVerifyUserPreferences(userIds, pr);
			User_Preference__c currentUserPref;
			for( User_Preference__c pref : prefs) {
				faciltyByUser.put(pref.User__c, pref.Default_Facility__c);

				if ( pref.User__c == currentUser) {
					currentUserPref = pref;
				}
			}

			try {
				Configuration__c facilityQueueMax = Configuration__c.getValues('WO_QUEUE_MAX-' + currentUserPref.Default_Facility__c);

				if (facilityQueueMax != null && facilityQueueMax.Value__c != null) {
					Integer jobSize = Integer.valueOf(facilityQueueMax.Value__c);
					if ( jobSize < MAX_QUEUE_JOBS ) {
						DEFAULT_QUEUE_JOB_SIZE = jobSize;
					} else {
						DEFAULT_QUEUE_JOB_SIZE = MAX_QUEUE_JOBS;
					}
				}
			} catch (Exception e) {
				// do nothing
			}

			if ( DEFAULT_QUEUE_JOB_SIZE > 0 ) {
				if (runningJobs.isEmpty()) {
					bEnqueueJob = true;
				} else {
					List<AsyncApexJob> jobForCurrentFacility = new List<AsyncApexJob>();

					for (AsyncApexJob job : runningJobs) {
						if (faciltyByUser.get(job.CreatedById) == currentUserPref.Default_Facility__c)
							jobForCurrentFacility.add(job);
					}

					if (DEFAULT_QUEUE_JOB_SIZE > jobForCurrentFacility.size()) {
						bEnqueueJob = true;
					}
				}


				if (bEnqueueJob) {
					System.enqueueJob(new WorkOrderQueue(new List<Process_Request__c>{
							pr
					}));
				}
			}
        } else {
            System.enqueueJob(new WorkOrderQueue(new List<Process_Request__c>{pr}));
        }
    }

	private static List<User_Preference__c> getVerifyUserPreferences (Set<Id> userIDs, Process_Request__c pr) {
		Id currentUser = UserInfo.getUserId();

		SOQLUtil soql = new SOQLUtil ('User_Preference__c', false);
		soql.addAllCustomFields();
		soql.setWhereClause('User__c =:userIds');
		List<User_Preference__c> prefs = Database.query(soql.getQuery());
		User_Preference__c currentUserPref;
		for( User_Preference__c pref : prefs) {
			if ( pref.User__c == currentUser) {
				currentUserPref = pref;
			}
		}

		// user preference is not setup or Default Facility not provided
		if ( currentUserPref == null || currentUserPref.Default_Facility__c == null ) {
			throw new ScannerServiceException ('Please verify the User Preference.');
		}

		if ( currentUserPref.Default_Facility__c != pr.Facility__c ) {
			throw new ScannerServiceException ('Cannot complete work order for a different facility.');
		}

		return prefs;
	}
    
    public class runWorkOrderUncompleteJob implements Action.Target {
        public Action.Response execute (Object obj ) {
            Savepoint sp = Database.setSavepoint();
            Action.Response resp = new Action.Response();
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
                
            String woId = String.valueOf(params.get('woId'));
            String caseNumber = String.valueOf(params.get('caseNumber'));
			Decimal caseQuantity = Decimal.valueOf(String.valueOf(params.get('caseQuantity')));
			Boolean bFullCase = params.containsKey( 'isFullCase') ? Boolean.valueOf( params.get('isFullCase')) : false;
            
            Work_Order__c workOrder = new Work_Order__c(Id = woId);
            
            try {
                workOrder = WorkOrderService.getWorkOrders(
								new Set<Id>{woId},
								null,
								new Set<String>{'Company__c','Company__r.Serial_Control__c','Shipment_Line__r.Shipment__c'},
								new Set<String>{'Operation_Trackings__r'}
							)[0];
							
				Operation_Tracking__c op = new Operation_Tracking__c();
				
				for(Operation_Tracking__c opTracking : workOrder.Operation_Trackings__r){
                    if(String.isBlank(op.Id) || (opTracking.Sequence__c > op.Sequence__c)){
                        op = opTracking;
                    }
                }
				
                // fetch conversions
                Map<String, UOM__c> uomsMap = getUOMs(new Set<String>{workOrder.Packaging_UOM__c, workOrder.Item__r.Stocking_UOM__c});
				
				map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>> ();
	            
                if ( itemsWithPackagingUOM.containsKey( workOrder.Item__r) == false ) {
                    itemsWithPackagingUOM.put( workOrder.Item__r, new Set<UOM__c>());
                }
                
                itemsWithPackagingUOM.get( workOrder.Item__r ).add( workOrder.Packaging_UOM__r );
	            itemsWithPackagingUOM.get( workOrder.Item__r ).add( uomsMap.get(workOrder.Item__r.Stocking_UOM__c) );
	            
	            map<Id, map<Id, Item__c>> mapContainerItems = SkidService3.getContainerforItems(itemsWithPackagingUOM);
            	
                // assembly data for uncompletion
                JSONResult assemblyResult = WorkOrderUncompleteExtV2.getHeaderAssemblyData (woId, op.Id, true);
                
                List<SkidService3.SerialWrapper> assemblyInfo = new List<SkidService3.SerialWrapper>();
                for(Object assemblyRecord : assemblyResult.records) {
                    if(assemblyRecord instanceof List<SkidService3.SerialWrapper>) {
                        List<SkidService3.SerialWrapper> serialWrapper = (List<SkidService3.SerialWrapper>)assemblyRecord;
                        assemblyInfo.addAll(serialWrapper);
                    } else if(assemblyRecord instanceof WorkOrderService.CompleteWrapper) {
                        WorkOrderService.CompleteWrapper completeWrapper = (WorkOrderService.CompleteWrapper)assemblyRecord;
                        if(completeWrapper.assemblyInfo != null) {
                            assemblyInfo.add(completeWrapper.assemblyInfo);
                        }
                    }
                }
                
                Id fromUOMId;
				Id itemId;
				Decimal quantityReturned;
                
				Map<Id, List<Id>> packageUOMsByItems = new Map<Id, List<Id>>();
				Decimal hoursToUnconsume = 0;
				SkidService3.SerialWrapper assemblySW;
                
                List<WorkOrderService.UncompleteWrapper> wrappers = new List<WorkOrderService.UncompleteWrapper>();
                
                // multiple assembly cases will pick the appropriate assembly 
                // based on the uncompletion 
                for(SkidService3.SerialWrapper assembly : assemblyInfo) {
					List<Id> packagingUOMs;
                    Boolean fullCase = false;
                    if(packageUOMsByItems.containsKey(assembly.skid.Item__c)) {
						packagingUOMs = packageUOMsByItems.get(assembly.skid.Item__c);
					} else {
						List<Id> lstPkgUom = (List<Id>) JSON.deserialize(assembly.skid.Item__r.Packaging_UOM__c, List<Id>.class);
						packageUOMsByItems.put(assembly.skid.Item__c, lstPkgUom);
						packagingUOMs = lstPkgUom;
					}

					Decimal convFactor = KSE.getConversionFactor(assembly.skid.Item__c, workOrder.Facility__r.Facility_Identifier__c, workOrder.Packaging_UOM__c, packagingUOMs[0], packagingUOMs);
					
                    Id pkgUOMId;
					
                    fullCase = params.containsKey('isFullCase') ? bFullCase : isFullCase (caseQuantity, convFactor);
					if( workOrder.Packaging_UOM__c != packagingUOMs[0] && fullcase == true) {
						quantityReturned = caseQuantity / convFactor;
						pkgUOMId = packagingUOMs[1];
					} else {
						quantityReturned = caseQuantity;
						pkgUOMId = packagingUOMs[0];
					}
					
                    // Assembly uncompletion in the UOM completed in
                    if ( assembly.skid.Packaging_UOM__c != pkgUOMId ) {
                        continue;
                    }
                    
                    assembly.skid.Quantity_To_Return__c = quantityReturned;
                    
					fromUOMId = pkgUOMId;
					itemId = assembly.skid.Item__c;
					
					if (assembly.skid.Input_Quantity__c > 0) {
                        hoursToUnconsume = assembly.skid.Input_Quantity__c;
                    }
                    
                    assemblySW = assembly;
                    break;
                }
                
                if ( assemblySW == null ) {
                    // throw exception: assembly not found
                    throw new ScannerServiceException('No assembly to uncomplete');
                }
                
                // backflush data for uncompletion
                JSONResult backflushResult = WorkOrderUncompleteExtV2.getComponentData (workOrder, op.Id, true, assemblySW);
                
                WorkOrderService.UncompleteWrapper wrapper = new WorkOrderService.UncompleteWrapper(
                    											workOrder,
                    											op,
                    											null,
                    											assemblySW,
                    											(List<WorkOrderWrapper>)backflushResult.records, // backflush records
                    											true,
                    											hoursToUnconsume);
                wrappers.add(wrapper);
                
                // TODO support for byproduct and WIP
                // JSONResult byproductResult = WorkOrderUncompleteExtV2.getByproductData (woId, op.Id, true);
                // JSONResult wipResult = WorkOrderUncompleteExtV2.getWIPData (woId, op.Id, true);
                
                WorkOrderService.uncompleteV2( wrappers, true);
                
                // remove contents on uncomplete
                removeWorkOrderContents(workOrder.Id, caseNumber.split(','));
                resp.success = true;
            } catch ( Exception ex) {
                resp.error.put('message', ex.getMessage());
                resp.error.put('stackTrace', ex.getStackTraceString());
                resp.success = false;
                Database.rollback(sp);
            }
            
            // TODO Err handling.
            return resp;
        }
    }
    
    public class runWorkOrderJob implements Action.Target{
    	
        public Action.Response execute(Object obj) {
        	
            Action.Response resp = new Action.Response();
            
            Map<String, Object> params = (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(obj));
                
            String woId = String.valueOf(params.get('woId'));
            String caseNumber = String.valueOf(params.get('caseNumber'));
            Decimal caseQuantity = Decimal.valueOf(String.valueOf(params.get('caseQuantity')));
            Boolean bFullCase = params.containsKey('isFullCase') ? Boolean.valueOf(params.get('isFullCase')) : false;
            
            Work_Order__c workOrder = new Work_Order__c(Id = woId);
            
            try {
                workOrder = WorkOrderCompleteExtV2.getWorkOrder(workOrder.Id);
                Operation_Tracking__c operationTracking = workOrder.Operation_Trackings__r[workOrder.Operation_Trackings__r.size() - 1];
                
                if (workOrder.Number_of_Operations__c > 1 && operationTracking.Quantity_Available__c <= 0 ) throw new CustomException('Complete the previous operations before completing the work order.');

                List<SkidService3.SerialWrapper> assemblies = (List<SkidService3.SerialWrapper>)WorkOrderCompleteExtV2.getAssemblyData(workOrder, operationTracking, true).records;
                SkidService3.SerialWrapper assembly = assemblies[assemblies.size() - 1];    //always take new line
                Decimal convFactor = KSE.getConversionFactor(workOrder.Item__c, workOrder.Facility__r.Facility_Identifier__c, workOrder.Packaging_UOM__c, workOrder.Item__r.Stocking_UOM__c, (List<Id>)JSON.deserialize(workOrder.Item__r.Packaging_UOM__c, List<Id>.Class));
                Boolean fullCase = params.containsKey('isFullCase') == true ? bFullCase : isFullCase(caseQuantity, convFactor);
                
                assembly.skid.Item__r = workOrder.Item__r;
                if (workOrder.Packaging_UOM__c != workOrder.Item__r.Stocking_UOM__c && fullCase == true) {
                    assembly.skid.Quantity_Used__c = caseQuantity / convFactor;
                } else {
                    assembly.skid.Packaging_UOM__c = workOrder.Item__r.Stocking_UOM__c;
                    assembly.skid.Quantity_Used__c = caseQuantity;

                    List<Object> uomData = WorkOrderCompleteExtV2.uomChange(workOrder.Item__r, workOrder.Facility__r.Facility_Identifier__c, workOrder.Item__r.Stocking_UOM__c,workOrder.Packaging_UOM__c).records;
                    assembly.skid.Packaging_UOM__r = (UOM__c)uomData[0];
                    assembly.skid.Container_Item__r = (Item__c)uomData[1];
                    assembly.skid.Container_Item__c = assembly.skid.Container_Item__r.Id;
                    assembly.conversionFactor = (Decimal)uomData[2];
                }
				
				Decimal woCompleteConvFactor = KSE.getConversionFactor(workOrder.Item__c, workOrder.Facility__r.Facility_Identifier__c, workOrder.Packaging_UOM__c, assembly.skid.Packaging_UOM__c, (List<Id>)JSON.deserialize(workOrder.Item__r.Packaging_UOM__c, List<Id>.Class));
				assembly.skid.Input_Quantity__c = assembly.skid.Quantity_Used__c * operationTracking.Standard_Hours__c / woCompleteConvFactor;
				    
                Savepoint sp = Database.setSavepoint();
                try {
                    WorkOrderService.scannerComplete(new List<WorkOrderService.CompleteWrapper>{ new WorkOrderService.CompleteWrapper(
                        workOrder,
                        operationTracking,
                        null,
                        assembly,
                        null,
                        null,
                        true
                    )});

                    resp.success = true;

                    addWorkOrderContents(workOrder.Id, new List<Object>{ caseNumber });
				}catch(Exception ex) {
					system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
					Database.rollback(sp);
					//removeWorkOrderContents(workOrder.Id, new List<Object>{caseNumber});
					throw ex;
				}
            }catch(Exception ex){
                system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
                resp.error.put('message', ex.getMessage());
				resp.error.put('stackTrace', ex.getStackTraceString());
				resp.success = false;
				
                if ( !ex.getMessage().contains('Record Currently Unavailable') ) {
                    ExceptionUtil.WO_COMPLETE_EXCEPTION.description += '\n' + ex.getMessage();
                    exService.setException(workOrder, ExceptionUtil.WO_COMPLETE_EXCEPTION);
                }
            }
            
            exService.finishTasks();
            return resp;
        }
    }
	
    public static Boolean isFullCase ( Decimal qty, Decimal convFactor ) {
    	Decimal res = qty / convFactor;
        return Math.floor(res) == res;
    }
    
    public class getInventory implements Action.Target{
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();
	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
		    	String companyId = params.get('Company__c') != null ? (String) params.get('Company__c') : userDefaults.Default_Company__c;
				String toFacilityId = params.get('Facility__c') != null ? (String) params.get('Facility__c') : userDefaults.Default_Facility__c;
				String fromLocationId = params.get('Location__c') != null ? (String) params.get('Location__c') : userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c;
				
				String itemId = (String) params.get('Item__c');
				String groupBy = params.get('groupBy') == null ? 'Item__c' : (String) params.get('groupBy');
				
				Map<Id, Item__c> itemsMap = InventoryChangeService.getItems(new Set<String>{itemId});
				
				Item__c containerItem = new Item__c();
				
	        	if(itemsMap.size() > 0){

	        		Item__c item = itemsMap.get(itemId);
			        
			        if(! String.isBlank(item.Packaging_UOM__c)){	
			        	List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
			        	
		        		String caseUOMId = packagingUOMs[1];
						String palletUOMId = packagingUOMs[2];
	
						Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));
		        		map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
	
						if(!itemsWithPackagingUOM.containskey(item)){
							itemsWithPackagingUOM.put(item, new Set<UOM__c>());
						}
	
				    	itemsWithPackagingUOM.get(item).add(uomsMap.get(palletUOMId));
	
						map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
				        if(itemsWithPackagingUOM.values().size()>0){
					        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
				        }
		        		
			    		containerItem = containersByItem.get(item.Id).get(palletUOMId);
					}

	        	}else{
	        		throw new ScannerServiceException('Item not found');
	        	}
		        	
				Map<String, Object> smrParams = new Map<String, Object>();
				smrParams.put('Company__c', companyId);
				smrParams.put('Facility__c', toFacilityId);
				smrParams.put('Location__c', fromLocationId);
				smrParams.put('Item__c', itemId);
				smrParams.put('Source_Document__c', params.get('Source_Document__c'));
				smrParams.put('Type__c', params.get('Type__c'));
				
				if(String.isBlank(containerItem.Container_Package_Class__c) == false){
					smrParams.put('Container_Package_Class__c', containerItem.Container_Package_Class__c);
				}
				
				String response = getToLocation(smrParams);

				Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);
				
				Set<Id> toLocationsIds = new Set<Id>();
				
				if((Boolean)responseMap.get('success')){
					Map<String, Object> locationsMap = (Map<String, Object>) responseMap.get('records');
					List<Object> locations = (List<Object>) locationsMap.values()[0];
					for(Object locationObject : locations){
						Map<String, Object> toLocation = (Map<String, Object>) locationObject;
						toLocationsIds.add((Id) toLocation.get('Id'));
					}
					
				}else{
					Map<String, Object> error = (Map<String, Object>) responseMap.get('error');
					throw new ScannerServiceException((String)error.get('message'));
				}

				
				Map<String,Set<Id>> filters = new Map<String,Set<Id>>{
		        								'Item__c' => new Set<Id>{ itemId },
		        								'Facility2__c' => new Set<Id>{ toFacilityId },
		        								'Location__c' => toLocationsIds
		        							  };

				List<String> groupingFields = groupBy.split(',');

		    	Map<String, List<SkidService3.SerialWrapper>> serialWrapperMap = new Map<String, List<SkidService3.SerialWrapper>>();
				
				Decimal palletCapacity = getPalletCapacity(itemId);
				
				for (SkidService3.SerialWrapper sw : InventoryChangeService.getSkids(filters, null, ' AND Consigned_Owner__c = null ',false)) {
		    		
		    		Item__c item = itemsMap.get(itemId);
			        
			        if(! String.isBlank(item.Packaging_UOM__c)){	
			        	List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
			        	
		        		String palletUOMId = packagingUOMs[2];
		        		
		        		if(sw.skid.Packaging_UOM__c == palletUOMId){
		        			sw.skid.Quantity__c = palletCapacity;
		        		}
			        }
			        
		    		String groupingKey = '';

		    		for(String groupingField : groupingFields){
		    			if(groupingField.toLowerCase() == 'facility__c'){
		    				groupingField = 'Facility2__c';
		    			}
		    			groupingKey += sw.skid.get(groupingField);
		    		}

		    		if(! serialWrapperMap.containsKey(groupingKey)){
		    			serialWrapperMap.put(groupingKey, new List<SkidService3.SerialWrapper>());
		    		}

		    		serialWrapperMap.get(groupingKey).add(sw);
		    	}

		    	if(serialWrapperMap.size() > 0){
			    	resp.success = true;
					resp.results.put('records', serialWrapperMap) ;
    			}else{
		    		resp.success = false;
		    		resp.error.put('message', 'No matching inventory found') ;
		    	}

	    	} catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
	    		resp.error.put('message', ex.getMessage()) ;
	        }

	        return resp;
        }
    }

    public class getPutawayBin implements Action.Target{
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();
	
	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
				
				SKID__c putawaySkid;
	    		Item__c item;
	    		
	    		Boolean isTransfer = params.get('isTransfer') != null ? (Boolean) params.get('isTransfer') : false;
		    	
				if(params.get('lpnName') != null){
			    	String lpnName = (String) params.get('lpnName');
	
			    	LPN__c lpn = getLPNsByName(new Set<String>{lpnName}).get(lpnName);
	
			    	if(lpn.SKIDs__r.size() > 0){
			    		putawaySkid = lpn.SKIDs__r[0];
			    		item = putawaySkid.Item__r;
			    	}else{
			    		throw new ScannerServiceException('Pallet is empty');
			    	}
		    	}
		    	else
		    	if(params.get('itemCode') != null){
		    		String itemCode = (String) params.get('itemCode');
		    		Decimal quantity = Decimal.valueOf((String)params.get('quantity'));
		    		String fromBinName = params.get('fromBin') != null ? (String) params.get('fromBin') : '';
		    		Map<String, Bin__c> binMap = getBinsByName(new Set<String>{ fromBinName });
					
					Bin__c fromBin;
			    	if(String.isBlank(fromBinName) == false){
			    		if(binMap.containsKey(fromBinName)){
				    		fromBin = binMap.get(fromBinName);
				    	}else{
				    		throw new ScannerServiceException('Bin not found: ' + fromBinName);
				    	}	
			    	}
			    	
		    		Map<String,Item__c> itemsMap = getItemsByCode(new Set<String>{itemCode});
	
		        	if(itemsMap.size() > 0){
						
		        		item = itemsMap.get(itemCode);
			        	
			        	putawaySkid = new SKID__c(
			    						Company__c = userDefaults.Default_Company__c,
			    						Facility2__c = userDefaults.Default_Facility__c,
										Facility2__r = userDefaults.Default_Facility__r,
			    						Location__c = fromBin != null ? fromBin.Location__c :  userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c,
			    						Item__c = item.Id,
			    						Item__r = item
		    						  );
						
		    			List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
						
			        	String eachUOMId = packagingUOMs[0];
						String caseUOMId = packagingUOMs[1];
						String palletUOMId = packagingUOMs[2];
						
						Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));
		        		map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
	
						if(!itemsWithPackagingUOM.containskey(item)){
							itemsWithPackagingUOM.put(item, new Set<UOM__c>());
						}
	
				    	itemsWithPackagingUOM.get(item).add(uomsMap.get(caseUOMId));
				    	itemsWithPackagingUOM.get(item).add(uomsMap.get(eachUOMId));
	
						map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
				        if(itemsWithPackagingUOM.values().size()>0){
					        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
				        }
				        
						Decimal caseCapacity = KSE.getConversionFactor(item.Id,userDefaults.Default_Facility__r.Facility_Identifier__c, caseUOMId, eachUOMId, packagingUOMs);
						
						String packagingUOMId = '';
						
						if(quantity == caseCapacity){
					        packagingUOMId = caseUOMId;
					        quantity = 1;
						}else{
							packagingUOMId = eachUOMId;
						}
						
						putawaySkid.Packaging_UOM__c = packagingUOMId;
						putawaySkid.Quantity__c = quantity;
						
						Item__c containerItem = containersByItem.get(item.Id).get(packagingUOMId);
	
				    	if(containerItem !=null){
				        	putawaySkid.Container_Item__c = containerItem.Id;
				        	putawaySkid.Container_Item__r = containerItem;
				        }
	
		        	}else{
		        		throw new ScannerServiceException('Item not found: ' + itemCode);
		        	}
		    	}else{
		    		throw new ScannerServiceException('Item or pallet is required');
		    	}
	
		    	Stock_Movement_Rule__c stockMovementRule = new Stock_Movement_Rule__c();
		    	stockMovementRule.Source_Document__c = isTransfer ? 'Transfer' : 'Directed Putaway';
		    	stockMovementRule.Item__r = item;
		    	
		    	if(stockMovementRule.Source_Document__c == 'Transfer'){
		    		List<Stock_Movement_Rule__c> transferRules = [SELECT Id FROM Stock_Movement_Rule__c WHERE Source_Document__c = 'Transfer'];
			    	if(transferRules.size() == 0){
			    		throw new ScannerServiceException('Transfer rules not setup');
			    	}	
		    	}
		    	
				for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
	    
		            if( smrs.Source_Document__c == stockMovementRule.Source_Document__c ){
		                
		                if( smrs.Source_Document_Path__c == null || smrs.Source_Document_Path_Putaway__c == null ){
		                    throw new ScannerServiceException(Label.Source_Document_Path_Fields_Not_Populated);
		                }
		                
		                string smrKeyField = smrs.Stock_Movement_Rule_Field__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),'');
		                string sDocPathPutaway = smrs.Source_Document_Path_Putaway__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),'');
		                system.debug(LoggingLevel.DEBUG, smrKeyField);
		                system.debug(LoggingLevel.DEBUG, sDocPathPutaway);
		                
		                if(smrKeyField.contains('facility__c')){
		                	sDocPathPutaway = 'facility2__c';
		                }
		                
		                if(smrKeyField.contains('source_location__c')){
		                	smrKeyField = 'location__c';
		                }
		                
		                if(smrKeyField.contains('container_package_class__c')){
		                	system.debug(LoggingLevel.DEBUG, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid.Container_Item__r));
		                	stockMovementRule.put(smrKeyField, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid.Container_Item__r));
		                }else{
		                	system.debug(LoggingLevel.DEBUG, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid));
		                	stockMovementRule.put(smrKeyField, AccountingRuleService.getValue(sDocPathPutaway, putawaySkid));
		                }
		            }
		        }
		    	
		    	SkidService3.DirectPutawayWrapper putawayWrapper = new SkidService3.DirectPutawayWrapper(stockMovementRule, putawaySkid);

	    		map<Integer, Bin__c> binMap = SkidService3.availableBinForDirectPutaway(new List<SkidService3.DirectPutawayWrapper>{putawayWrapper});
		    	
		    	list<sObject> dummySmrs = new list<sObject>();
		        Set<String> sourceDocumentLineNames = new Set<String>();
        
	        	dummySmrs.add(putawayWrapper.stockMovementRule);  
	        	sourceDocumentLineNames.add(putawayWrapper.stockMovementRule.Source_Document__c);
		        
		        Set<String> UOMfieldStrings = new Set<String>{'Id','Package_Class__c'};
		        
		        SOQLUtil soql = new SOQLUtil('UOM__c', true); //enforceFLS=true, running in user mode
		        soql.addFields(UOMfieldStrings);
		        soql.setWhereClause('Id IN :UOMIds');
		        
		        //to find matching location 
		        map<string, list<Location__c>> locationMap =  SkidService3.locationsFromStockMovementRules(  
		        												dummySmrs, 
		        												'Putaway', 
		        												sourceDocumentLineNames,
																null, 
																null  
															  );
				
	    		resp.success = true;
				resp.results.put('item', item);
				resp.results.put('binMap', binMap);
				resp.results.put('locationMap', locationMap);

        	}catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
	    		resp.error.put('message', ex.getMessage()) ;
	        }

	        return resp;
        }
    }

    public class replenish implements Action.Target{
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();

	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
	        	//params.put('attributesToCorrect', new List<String>{'Packaging_UOM__c'});
	        	resp = transfer(params);
	        }
	        catch(Exception ex){
	        	resp.success = false;
	        	resp.error.put('message', ex.getMessage());
	        }

	        return resp;
        }
    }
    
	public class transferInventory implements Action.Target {
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();

	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
	        	String lpnName = (String) params.get('lpnName');
		    	String fromBinName = params.get('fromBin') != null ? (String) params.get('fromBin') : '';
		    	String toBinName = (String) params.get('toBin');
		    	String itemId = params.get('itemId') != null ? (String) params.get('itemId') : '';
		    	List<String> woNames = new List<String>();
		    	
		    	List<Object> lineItems =  params.get('lines') != null ?  (List<Object>) params.get('lines') : new List<Object>(); 
		    	
    	    	List<String> attributesToCorrect = params.get('attributesToCorrect') != null ? (List<String>) JSON.deserialize((String) params.get('attributesToCorrect'), List<String>.class) : null;
		    	
		    	String companyId = userDefaults.Default_Company__c;
		    	String facilityId = userDefaults.Default_Facility__c;
				String locationId = userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c;
				
				Set<String> companyIds = new Set<String>();
		        if(!String.isBlank(companyId)){
		    		companyIds.add(companyId);
		    	}
		    	
		    	Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(companyIds);
	            
    			// Get the bin info
				Map<String, Bin__c> binMap = getBinsByName(new Set<String>{fromBinName, toBinName});
				
				Bin__c toBin;
		    	if(binMap.containsKey(toBinName)){
		    		toBin = binMap.get(toBinName);
		    	}else{
		    		throw new ScannerServiceException('Bin not found: ' + toBinName);
		    	}
		    	
		    	Bin__c fromBin;
		    	if(String.isBlank(fromBinName) == false){
		    		if(binMap.containsKey(fromBinName)){
			    		fromBin = binMap.get(fromBinName);
			    		locationId = fromBin.Location__c; 
			    	}else{
			    		throw new ScannerServiceException('Bin not found: ' + fromBinName);
			    	}	
		    	}
		    	
		    	Map<String, SKID__c> putawaySkids = new Map<String, SKID__c>();
	
		    	List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());
		    	
		    	if(!String.isBlank(lpnName)){
			    	Map<String, LPN__c> lpnMap = getLPNsByName(new Set<String>{lpnName});
	
			        if(lpnMap.size() > 0 && lpnMap.containsKey(lpnName)){
				        if(lpnMap.get(lpnName).SKIDs__r.size() > 0){
				    		LPN__c lpn = lpnMap.get(lpnName);
				    		
				    		SKID__c putawaySkid = lpn.SKIDs__r[0];
				    		companyId = putawaySkid.Company__c;
				    		facilityId = putawaySkid.Facility2__c;
				    		locationId = putawaySkid.Location__c;
				    		itemId = putawaySkid.Item__c;
				    		
				    		List<String> contents = String.isBlank(lpn.Contents__c) == false ? lpn.Contents__c.split(','): new List<String>();
				    		
				    		String woName = 'WO-00';
				    		
				    		if(contents.size() > 0){
					    		// Support for old and new case formats.
					    		String barCode = contents[0].replaceAll('\'', '');
					    			
					    		if(barCode.length() == 28){
					    			woName += barCode.substring(20, 28);
					    		}
					    		else
					    		if(barCode.length() == 32){
					    			woName += barCode.substring(26, barCode.length());
					    		} 
					    		
					    		if(String.isNotBlank(woName)){
					    			woNames.add(woName);
					    		
						    		// Assuming all the quantity in the LPN belongs to the same WO. 
						    		putawaySkid.Work_Order__r = new Work_Order__c(Name = woName);	
					    		}
				    		}
				    		
				    		String putawaySkidKey = '' + putawaySkid.Item__c + putawaySkid.Packaging_UOM__c;
				    		putawaySkids.put(putawaySkidKey, putawaySkid);
				    	}else{
				    		throw new ScannerServiceException('Pallet is empty: ' + lpnName);
				    	}
			        }else{
			        	throw new ScannerServiceException('Pallet not found: ' + lpnName);
			        }
		    	}
		    	else
		    	if(String.isBlank(itemId)){
		    		throw new ScannerServiceException('Item or pallet is required');
		    	}
				
	            // Get the location skids 
		        Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 
		        								'Item__c' => new Set<Id>{ itemId }, 
		        								'Facility2__c' => new Set<Id>{ facilityId }, 
		        								'Location__c' => new Set<Id>{ locationId } 
		        							  };
				
		    	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
		        for (SkidService3.SerialWrapper sw : InventoryChangeService.getSkids(filters, null, ' AND Consigned_Owner__c = null ', false)) {
					
		            SKID__c toSkid = sw.skid.clone(false, true);
		            toSkid.Location__c = toBin.Location__c;
		            toSkid.Location__r = toBin.Location__r;
		            toSkid.Bin__c = toBin.Id;
		            toSkid.Bin__r = toBin;
					
					toSkid.Packaging_UOM__c = null;
					toSkid.Packaging_UOM__r = null;
					
		        	sw.skid.Input_Quantity__c = 0;
		            
		            List<String> skidKey = SkidService3.generateKey(sw.skid, attributeList);
		    		serialWrapperMap.put(skidKey, new SkidService3.SerialWrapper(sw.skid, null, null, toSkid));
		        }
		        
		        DateTime transactionDate = system.now();
		        Inventory_Change__c inventoryChange = new Inventory_Change__c();
		    	inventoryChange.Company__c = companyId;
		    	inventoryChange.Company__r = mCompanies.get(inventoryChange.Company__c);
		    	inventoryChange.Transaction_Date__c = transactionDate;
				inventoryChange.Type__c = 'Transfer';
	            
				Map<List<String>, SkidService3.SerialWrapper> icSerialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
				
				Map<Id, Item__c> itemsMap = InventoryChangeService.getItems(new Set<String>{itemId}); 
		    	Map<Id, Map<Id, Item__c>> containersByItem = new Map<Id, Map<Id, Item__c>>();
		        Map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new Map<Item__c, Set<UOM__c>>();
			    
			    Item__c item = itemsMap.get(itemId);
			    
				List<String> packagingUOMs = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
							
				String eachUOMId = packagingUOMs[0];
				String caseUOMId = packagingUOMs[1];
				String palletUOMId = packagingUOMs[2];
				
				Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));
	        		
		        if(!itemsWithPackagingUOM.containskey(item)){
					itemsWithPackagingUOM.put(item, new Set<UOM__c>());
				}

			    itemsWithPackagingUOM.get(item).add(uomsMap.get(caseUOMId));
			    itemsWithPackagingUOM.get(item).add(uomsMap.get(eachUOMId));
				
				if(itemsWithPackagingUOM.values().size()>0){
			        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
		        }
		        
		        if(lineItems.size() > 0){
		        	for (Object line: lineItems) {
			        	if(itemsMap.size() > 0){
	                        Map<String, Object> lineItem = (Map<String, Object>) line;
							Decimal quantity = Decimal.valueOf(String.valueOf(lineItem.get('quantity')));
							
							String woName = lineItem.get('orderNumber') != null ? 'WO-00' + String.valueOf(lineItem.get('orderNumber')) : '';
							
							if(String.isBlank(woName) == false){
								woNames.add(woName);
							}							
							
							String putawaySkidType, packagingUOMId;
	                        
	                        Decimal caseCapacity = KSE.getConversionFactor(itemId, userDefaults.Default_Facility__r.Facility_Identifier__c, caseUOMId, eachUOMId, packagingUOMs);
						
	                        if ( quantity == caseCapacity ) {
	                            packagingUOMId = caseUOMId;
	                            quantity = 1;
	                        } else {
	                            packagingUOMId = eachUOMId;
	                        }
	                        
	                        String putawaySkidKey = '' + itemId + packagingUOMId;
				    		
							SKID__c putawaySkid;
							
							if(putawaySkids.containsKey(putawaySkidKey)){
								putawaySkid = putawaySkids.get(putawaySkidKey);
								putawaySkid.Quantity__c = KSE.addQuantityToField(putawaySkid.Quantity__c, quantity);
							}else{
								putawaySkid = new SKID__c(
					    						Company__c = companyId,
					    						Facility2__c = facilityId,
												Facility2__r = userDefaults.Default_Facility__r,
					    						Location__c = locationId,
					    						Item__c = itemId,
					    						Item__r = item,
					    						Bin__c = fromBin != null ? fromBin.Id : null,
					    						Packaging_UOM__c = packagingUOMId,
					    						Quantity__c = quantity
				    						  );
				    			
				    			if(String.isBlank(woName) == false){
				    				putawaySkid.Work_Order__r = new Work_Order__c(Name = woName);
								}
											  
								Item__c containerItem = containersByItem.get(item.Id).get(packagingUOMId);
		
						    	if(containerItem !=null){
						        	putawaySkid.Container_Item__c = containerItem.Id;
						        }
						    						  
				    			putawaySkids.put(putawaySkidKey, putawaySkid);
	                    	}
	                    
			        	}else{
			        		throw new ScannerServiceException('Item not found');
			        	}
			        }
		        }
		        
		        List<Map<String, Object>> linesToPlan = new List<Map<String, Object>>();
							
		        for(SKID__c putawaySkid : putawaySkids.values()){
					List<String> skidKey = SkidService3.generateKey(putawaySkid, attributeList);
			
			    	SkidService3.SerialWrapper serialWrapper;
			    	if(serialWrapperMap.containsKey(skidKey)){
			    		serialWrapper = serialWrapperMap.get(skidKey);
			    	}
			    	else{
	                    throw new ScannerServiceException('Not enough quantity for: ' + putawaySkid.Item__r.Name);
			    	}
			
			    	SKID__c fromSkid = serialWrapper.skid;
			    	SKID__c toSkid = serialWrapper.toSkid;
			    	
			    	
			    	toSkid.Item__r = item;
		    		
			    	Decimal inputQuantity = putawaySkid.Quantity__c; // Using count quantity for now.
					Decimal qtyAvaialble = toSkid.Quantity_Available__c;
					
					//KNDY-17649: Change container item if the bin's location container package class level is lower than the pallet container's package class level
		    		if(toBin.Location__r.Container_Package_Class__r.Level__c < toSkid.Container_Item__r.Container_Package_Class__r.Level__c){
				        toSkid.Packaging_UOM__c = caseUOMId;
				        
		    			List<Id> lstPkgUom = (List<Id>) JSON.deserialize(toSkid.Item__r.Packaging_UOM__c, List<Id>.class);
		    			Decimal conversionFactor = KSE.getConversionFactor(toSkid.Item__c, userDefaults.Default_Facility__r.Facility_Identifier__c, putawaySkid.Packaging_UOM__c, toSkid.Packaging_UOM__c, lstPkgUom);
		    		
		    			inputQuantity = inputQuantity * conversionFactor;
		    			qtyAvaialble = qtyAvaialble * conversionFactor;
					
						attributesToCorrect = new List<String>{ 'Packaging_UOM__c' };
						
						Item__c containerItem = containersByItem.get(toSkid.Item__c).get(toSkid.Packaging_UOM__c);
			    		toSkid.Container_Item__c = containerItem.Id;
			    		
			    		putawaySkid.Packaging_UOM__c = caseUOMId;
		    		}
		    		
		    		fromSkid.Input_Quantity__c = KSE.addQuantityToField(fromSkid.Input_Quantity__c, inputQuantity);
		    		toSkid.Quantity_Available__c = KSE.addQuantityToField(toSkid.Quantity_Available__c, qtyAvaialble);
		    		
		    		if(putawaySkid.Work_Order__r != null){
			    		Map<String, Object> lineToPlan = new Map<String, Object>();
						lineToPlan.put('quantity', fromSkid.Input_Quantity__c);
						lineToPlan.put('Packaging_UOM__c', uomsMap.get(putawaySkid.Packaging_UOM__c).Name);	
						lineToPlan.put('fromBinId', toSkid.Bin__c);
						lineToPlan.put('woName', putawaySkid.Work_Order__r.Name);	
						
						linesToPlan.add(lineToPlan);
			    	}
			    	
		    		icSerialWrapperMap.put(skidKey, serialWrapper);
					
				}
				
		        List<SkidService3.SerialWrapper> inventoryAdded = new List<SkidService3.SerialWrapper>();
				inventoryAdded.addAll(icSerialWrapperMap.values());
		    	
		    	List<InventoryChangeWrapper> icWrapperList = new List<InventoryChangeWrapper>();
		    		
		    	if(inventoryAdded.size() > 0){
		    		InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(inventoryChange, inventoryAdded);
			    	icWrapperList.add(icWrapper);
		    	}
		    
		        Savepoint sp = Database.setSavepoint();
		
		        try{
					
		        	if(icWrapperList.size() > 0){
		        		DML.insertAsSystem(inventoryChange);
		        		InventoryChangeService.inventoryTransfer( icWrapperList, attributesToCorrect);
		        	}
					
					if(woNames.size() > 0){
						
						Map<String, Shipment_Line__c> woToShlMap = new Map<String, Shipment_Line__c>();
						
						for(Sales_Order_Line__c sol : [SELECT Id, Work_Order__r.Name, (SELECT Id FROM Shipment_Lines__r) FROM Sales_Order_Line__c WHERE Work_Order__r.Name IN :woNames]){
							if(sol.Shipment_Lines__r.size() > 0){
								woToShlMap.put(sol.Work_Order__r.Name, sol.Shipment_Lines__r[0]);	
							}
						}
						
						if(woToShlMap.size() > 0){
							for(Map<String, Object> lineToPlan : linesToPlan){
								String woName = (String) lineToPlan.get('woName');
								
								if(woToShlMap.containsKey(woName)){
									lineToPlan.put('Shipment_Line__c', woToShlMap.get(woName).Id);	
								}
							} 
							
							Map<String, Object> pickParams = new Map<String, Object>();
							pickParams.put('inventory', linesToPlan);
							
							generatePicks pickGenerator = new generatePicks();
							pickGenerator.execute(JSON.serialize(pickParams));
						}
					}
					
		        	resp.success = true;
					resp.results.put('bin', toBin) ;
					resp.results.put('location', toBin.Location__r);
		
		        }catch(Exception ex){
		        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
		        	Database.rollback(sp);
		        	resp.success = false;
					resp.error.put('message', ex.getMessage()) ;
		        }
	        }
	        catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
	        	resp.error.put('message', ex.getMessage());
	        }

        	return resp;
        }
    }
    
    public static Action.Response transfer(Map<String, Object> params){

    	Action.Response resp = new Action.Response();

    	String lpnName = (String) params.get('lpnName');
    	String binName = (String) params.get('toBin');
    	String itemId = (String) params.get('itemId');
    	Boolean doBreakPallet = params.get('doBreakPallet') != null ? (Boolean) params.get('doBreakPallet') : false;
    	
    	List<String> attributesToCorrect = params.get('attributesToCorrect') != null ? (List<String>) JSON.deserialize((String)params.get('attributesToCorrect'), List<String>.class) : null;

    	SKID__c putawaySkid;

    	List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());
	
		if(!String.isBlank(lpnName)){
			Map<String, LPN__c> lpnMap = getLPNsByName(new Set<String>{lpnName});
			
			if(lpnMap.size() > 0){
		        if(lpnMap.get(lpnName).SKIDs__r.size() > 0){
		    		putawaySkid = lpnMap.get(lpnName).SKIDs__r[0];
		    		itemId = putawaySkid.Item__c;
		    	}else{
		    		throw new ScannerServiceException('Pallet is empty: ' + lpnName);
		    	}
	        }else{
	        	throw new ScannerServiceException('Pallet not found: ' + lpnName);
	        }
		}
		
		Map<Id, Item__c> itemsMap = InventoryChangeService.getItems(new Set<String>{itemId});
		
		Map<String, UOM__c> uomsMap;
		String caseUOMId;
		
		if(itemsMap.size() > 0){
			List<String> packagingUOMs = (List<String>) JSON.deserialize(itemsMap.get(itemId).Packaging_UOM__c, List<String>.class);
			caseUOMId = packagingUOMs[1];
			
			uomsMap = getUOMs(new Set<String>(packagingUOMs));
		}else{
    		throw new ScannerServiceException('Item not found');
    	}
    	
    	if(String.isBlank(lpnName)){
    		
    		Item__c item = itemsMap.get(itemId);
        	Decimal quantity = Decimal.valueOf((String)params.get('quantity'));

        	putawaySkid = new SKID__c(
    						Company__c = userDefaults.Default_Company__c,
    						Facility2__c = userDefaults.Default_Facility__c,
							Facility2__r = userDefaults.Default_Facility__r,
    						Location__c = userDefaults.Default_Facility__r.Default_Work_Order_Complete_to_Location__c,
    						Item__c = item.Id,
    						Quantity__c = quantity
						  );

			
    		map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();

			if(!itemsWithPackagingUOM.containskey(item)){
				itemsWithPackagingUOM.put(item, new Set<UOM__c>());
			}

	    	itemsWithPackagingUOM.get(item).add(uomsMap.get(caseUOMId));

			map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
	        if(itemsWithPackagingUOM.values().size()>0){
		        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
	        }

    		Item__c containerItem = containersByItem.get(item.Id).get(caseUOMId);

	    	if(containerItem !=null){
	        	putawaySkid.Container_Item__c = containerItem.Id;
	        }

	        putawaySkid.Packaging_UOM__c = caseUOMId;
    	}

    	String companyId = putawaySkid.Company__c;
		String facilityId = putawaySkid.Facility2__c;
		String locationId = putawaySkid.Location__c;
		
		Map<String, Bin__c> binMap = getbinsByName(new Set<String>{binName});
		
    	Bin__c toBin = binMap.get(binName);

        Map<String,Set<Id>> filters = new Map<String,Set<Id>>{
        								'Item__c' => new Set<Id>{ itemId },
        								'Facility2__c' => new Set<Id>{ facilityId },
        								'Location__c' => new Set<Id>{ locationId }
        							  };

    	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();

        for (SkidService3.SerialWrapper sw : InventoryChangeService.getSkids(filters, null, ' AND Consigned_Owner__c = null ',false)) {
            SKID__c toSkid = sw.skid.clone(false, true);
            toSkid.Location__c = toBin.Location__c;
            toSkid.Location__r = toBin.Location__r;
            toSkid.Bin__c = toBin.Id;
            toSkid.Bin__r = toBin;
			toSkid.Packaging_UOM__c = caseUOMId;
			toSkid.Packaging_UOM__r = uomsMap.get(caseUOMId);

        	sw.skid.Input_Quantity__c = 0;

            List<String> skidKey = SkidService3.generateKey(sw.skid, attributeList);
    		serialWrapperMap.put(skidKey, new SkidService3.SerialWrapper(sw.skid, null, null, toSkid));
        }

    	Set<String> companyIds = new Set<String>();

    	if(!String.isBlank(putawaySkid.Company__c)){
    		companyIds.add(putawaySkid.Company__c);
    	}

    	Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(companyIds);

        List<String> skidKey = SkidService3.generateKey(putawaySkid, attributeList);

    	SkidService3.SerialWrapper serialWrapper;
    	if(serialWrapperMap.containsKey(skidKey)){
    		serialWrapper = serialWrapperMap.get(skidKey);
    	}else{
    		throw new ScannerServiceException('Not enough quantity for: ' + putawaySkid.Item__r.Name);
    	}

    	SKID__c fromSkid = serialWrapper.skid;
    	SKID__c toSkid = serialWrapper.toSkid;

    	DateTime transactionDate = system.now();

    	Inventory_Change__c inventoryChange = new Inventory_Change__c();
    	inventoryChange.Company__c = putawaySkid.Company__c;
    	inventoryChange.Company__r = mCompanies.get(inventoryChange.Company__c);
    	inventoryChange.Transaction_Date__c = transactionDate;
		inventoryChange.Type__c = 'Transfer';
		
		Map<String, Inventory_Change__c> icMap = new Map<String, Inventory_Change__c>();

    	String icKey = '' + inventoryChange.Company__c + inventoryChange.Transaction_Date__c;

        if(icMap.containsKey(icKey) == false){
    	    icMap.put(icKey, inventoryChange);
	    }else{
	    	inventoryChange = icMap.get(icKey);
	    }

        Decimal inputQuantity = putawaySkid.Quantity__c; // Using count quantity for now.

		if(putawaySkid.Packaging_UOM__c != null && putawaySkid.Packaging_UOM__c != toSkid.Packaging_UOM__c){
		    List<Id> lstPkgUom = (List<Id>) JSON.deserialize(toSkid.Item__r.Packaging_UOM__c, List<Id>.class);
			inputQuantity = inputQuantity * KSE.getConversionFactor(toSkid.Item__c,userDefaults.Default_Facility__r.Facility_Identifier__c, putawaySkid.Packaging_UOM__c, toSkid.Packaging_UOM__c, lstPkgUom);
			toSkid.Quantity_Available__c = fromSkid.Quantity_Available__c *  KSE.getConversionFactor(toSkid.Item__c,userDefaults.Default_Facility__r.Facility_Identifier__c, putawaySkid.Packaging_UOM__c, toSkid.Packaging_UOM__c, lstPkgUom);
		}

		fromSkid.Input_Quantity__c += inputQuantity;

		Map<List<String>, SkidService3.SerialWrapper> icSerialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
		icSerialWrapperMap.put(skidKey, serialWrapper);

        List<SkidService3.SerialWrapper> inventoryAdded = new List<SkidService3.SerialWrapper>();
		inventoryAdded.addAll(icSerialWrapperMap.values());

    	List<InventoryChangeWrapper> icWrapperList = new List<InventoryChangeWrapper>();

    	if(inventoryAdded.size() > 0){
    		InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(icMap.get(icKey), inventoryAdded);
	    	icWrapperList.add(icWrapper);
    	}

        Savepoint sp = Database.setSavepoint();

        try{

        	if(icWrapperList.size() > 0){
        		DML.insertAsSystem(icMap.values());
        		InventoryChangeService.inventoryTransfer( icWrapperList, attributesToCorrect);
        	}

        	resp.success = true;
			resp.results.put('bin', toBin) ;
			resp.results.put('location', toBin.Location__r);

        }catch(Exception ex){
        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
        	Database.rollback(sp);
        	resp.success = false;
			resp.error.put('message', ex.getMessage()) ;
        }

        return resp;
    }
	/*
    	Cycle count per bin
    */
    public class cycleCount implements Action.Target{
        public Action.Response execute(Object obj){

            Action.Response resp = new Action.Response();

	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));

	        	List<Object> inventory = (List<Object>) params.get('inventory');
				String binName = (String) params.get('binName');

				/* Initializations Start */
		        List<SKID__c> skidList = new List<SKID__c>();

				Set<String> itemIds = new Set<String>();
				Set<String> companyIds = new Set<String>();
		    	Set<String> locationIds = new Set<String>();
		    	Set<String> lpnNames = new Set<String>();
				Set<String> uomIds = new Set<String>();

		    	Map<String, Inventory_Change__c> positiveICMap = new Map<String, Inventory_Change__c>();
		    	Map<String, Inventory_Change__c> negativeICMap = new Map<String, Inventory_Change__c>();

		    	Map<String, Map<List<String>, SkidService3.SerialWrapper>> positiveSerialWrapperMap = new Map<String, Map<List<String>, SkidService3.SerialWrapper>>();
		    	Map<String, Map<List<String>, SkidService3.SerialWrapper>> negativeSerialWrapperMap = new Map<String, Map<List<String>, SkidService3.SerialWrapper>>();

		    	List<InventoryChangeWrapper> positiveICWrappers = new List<InventoryChangeWrapper>();
		    	List<InventoryChangeWrapper> negativeICWrappers = new List<InventoryChangeWrapper>();

		    	List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());
				
				Map<String, Bin__c> binMap = getBinsByName(new Set<String>{binName});
		        Bin__c bin;
		        Map<Id, Bin__c> updatedBins = new Map<Id, Bin__c>();
		        
		        if(binMap.containsKey(binName) == false){
		        	throw new ScannerServiceException('Bin not found');
		        }else{
	        		bin = binMap.get(binName);
		        }

		        SOQLUtil soql = new SOQLUtil('Reason_Code__c');
		        soql.addFields(new Set<String>{'Id'});
		        soql.setWhereClause('Type__c = \'Cycle Count\'');
		        soql.setLimit(1);

		        List<Reason_Code__c> cycleCountReasons = Database.query(soql.getQuery());

		        if(cycleCountReasons.size() == 0){
		        	throw new ScannerServiceException('Reason code not found');
		        }

		        for(Object inventoryItem : inventory){
					Map<String, Object> reqParams = (Map<String, Object>) inventoryItem;
					String itemId = String.valueOf(reqParams.get('Item__c'));
					String lpnName = String.valueOf(reqParams.get('License_Plate_Number__c'));
					String uomId = String.valueOf(reqParams.get('Packaging_UOM__c'));

					if ( !String.isBlank(itemId) ) {
					    itemIds.add(itemId);
					}

					if ( !String.isBlank(lpnName) ) {
					    lpnNames.add(lpnName);
					}
					
					if ( !String.isBlank(uomId) ) {
					    uomIds.add(uomId);
					}
		        }
				
				Map<String, LPN__c> lpnMap = getLPNsByName(lpnNames);
				
				for(LPN__c lpn : lpnMap.values()){
					if(lpn.SKIDs__r.size() > 0){
						for(SKID__c lpnSkid : lpn.SKIDs__r){
						    itemIds.add(lpnSkid.Item__c);
						    uomIds.add(lpnSkid.Packaging_UOM__c);
						}
					}
		        }

		        Map<Id, Item__c> mItems = InventoryChangeService.getItems(itemIds);
		        Map<String,UOM__c> uomsMap = getUOMs(uomIds);

		    	/* Initializations End */
		    	
				for(Object inventoryItem : inventory){
					Map<String, Object> reqParams = (Map<String, Object>) inventoryItem;

					String itemId = String.valueOf(reqParams.get('Item__c'));
					String lpnName = String.valueOf(reqParams.get('License_Plate_Number__c'));

			        SKID__c newSkid = new SKID__c(
			        						Company__c = userDefaults.Default_Company__c,
				        					Type__c = SKIDService.SKID_TYPE_LOCATION,
				        					Facility2__c = userDefaults.Default_Facility__c,
											Facility2__r = userDefaults.Default_Facility__r,
				        					Count_Quantity__c = Decimal.valueOf( String.valueOf(reqParams.get('Count_Quantity__c'))),
				        					Item__c = itemId,
				        					Item__r = mItems.get(itemId),
				        					Packaging_UOM__c = (String) reqParams.get('Packaging_UOM__c'),
				        					Packaging_UOM__r = uomsMap.get((String) reqParams.get('Packaging_UOM__c')),
				        					Location__c = bin.Location__c,
			        						Bin__c = bin.Id
	        					 	 );
	        					 	 
	        		if ( mItems.containsKey(itemId) ) {
	        		    newSkid.Item__r = mItems.get( itemId );
	        		}
					
	        		if(lpnMap.containsKey(lpnName)){
	        			LPN__c existingLPN = lpnMap.get(lpnName); 
	        			newSkid.License_Plate_Number__c = existingLPN.Id;
	        			
	        			if(existingLPN.Skids__r.size() > 0){
	        				if(existingLPN.Skids__r[0].Bin__c != null && existingLPN.Skids__r[0].Bin__c != bin.Id){
		        				
		        				SKID__c existingSkid = existingLPN.Skids__r[0];
		        				
		        				SKID__c oldSkid = new SKID__c(
	        						Company__c = existingSkid.Company__c,
		        					Type__c = SKIDService.SKID_TYPE_LOCATION,
		        					Facility2__c = existingSkid.Facility2__c,
									Facility2__r = existingSkid.Facility2__r,
		        					Count_Quantity__c = 0,
		        					Item__c = existingSkid.Item__c,
		        					Item__r = mItems.get(existingSkid.Item__c),
		        					Packaging_UOM__c = existingSkid.Packaging_UOM__c,
			        				Packaging_UOM__r = uomsMap.get(existingSkid.Packaging_UOM__c),
			        				Location__c = existingSkid.Location__c,
		        					Bin__c = existingSkid.Bin__c,
		        					License_Plate_Number__c = existingLPN.Id
	    					 	);
	        					 	 
		        				skidList.add(oldSkid);
		        				
		        				system.debug(LoggingLevel.DEBUG, oldSkid);
		        				
		        				existingLPN.Skids__r[0].Bin__r.Blocked__c = true;
		        				updatedBins.put(existingLPN.Skids__r[0].Bin__c, existingLPN.Skids__r[0].Bin__r);
		        				
	        				}
	        			}
	        		}else{
	        			newSkid.Temporary_LPN_Holder__c = lpnName;
	        		}

					skidList.add(newSkid);

		        	if(!String.isBlank(userDefaults.Default_Company__c)){
		        		companyIds.add(userDefaults.Default_Company__c);
		        	}

					if(!String.isBlank(newSkid.Location__c)){
		        		locationIds.add(newSkid.Location__c);
		        	}
		        }
				system.debug(LoggingLevel.DEBUG, skidList);

		        Map<List<String>, SKID__c> existingSkidMap = SkidService3.generateExistingSkidMap(attributeList, skidList, true, '');

		        Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(companyIds);
		        Map<Id, Location__c> mLocations = InventoryChangeService.getLocations(locationIds);

		    	// Populate container items
		    	Map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new Map<Item__c, Set<UOM__c>>();

		    	for(SKID__c skid : skidList){

		        	//skid.Item__r = mItems.get(skid.Item__c);

		        	if(!itemsWithPackagingUOM.containskey(skid.Item__r)){
	    				itemsWithPackagingUOM.put(skid.Item__r,new Set<UOM__c>());
	    			}

		        	if(!String.isBlank(skid.License_Plate_Number__c)){// If palletizing
		        		try{
			        		Id nextLevelUomId = SkidService3.getNextLevelUomId(skid, skid.Item__r);
			        		itemsWithPackagingUOM.get(skid.item__r).add(new UOM__c(Id = nextLevelUomId));
			        	}catch(Exception ex){
			        		itemsWithPackagingUOM.get(skid.item__r).add(new UOM__c(Id = skid.Packaging_UOM__c));
			        	}
		        	}else{// If cases or eaches.
		        		itemsWithPackagingUOM.get(skid.item__r).add(new UOM__c(Id = skid.Packaging_UOM__c));
		        	}
		        }

		        map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
	            if(itemsWithPackagingUOM.values().size()>0){
			        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
	            }
				
				DateTime transactionDate = system.now();
				
		        for(SKID__c skid : skidList){

		        	Boolean hasError = false;
		        	Item__c containerItem;

		        	if(!String.isBlank(skid.License_Plate_Number__c)){// If palletizing
			        	try{
			        		Id nextLevelUomId = SkidService3.getNextLevelUomId(skid, skid.Item__r);
			        		containerItem = containersByItem.get(skid.Item__c).get(nextLevelUomId);
			        	}catch(Exception ex){
			        		containerItem = containersByItem.get(skid.Item__c).get(skid.Packaging_UOM__c);
			        	}
		        	}else{// If cases or eaches.
		        		containerItem = containersByItem.get(skid.Item__c).get(skid.Packaging_UOM__c);
		        	}

		        	if(containerItem !=null){
	                	skid.Container_Item__c = containerItem.Id;
	                	skid.Container_Item__r = containerItem;
	                }/*
	                else{
	                	resp.error.put('message', 'Container Item needs to defined on Item or package class.');
	                	resp.success = false;
		        		hasError = true;
	                }*/

		        	if(hasError){
		        		continue;
		        	}

		        	Inventory_Change__c inventoryChange = new Inventory_Change__c();
		        	inventoryChange.Company__c = userDefaults.Default_Company__c;
		        	inventoryChange.Company__r = mCompanies.get(inventoryChange.Company__c);
		        	inventoryChange.Reason_Code__c = cycleCountReasons[0].Id;
		        	inventoryChange.Transaction_Date__c = transactionDate;
					inventoryChange.Type__c = 'Cycle Count';
    				
		        	String icKey = '' + inventoryChange.Company__c + inventoryChange.Transaction_Date__c;

			        if(positiveICMap.containsKey(icKey) == false){
		        	    positiveICMap.put(icKey, inventoryChange);
				    }else{
				    	inventoryChange = positiveICMap.get(icKey);
				    }

		        	List<String> skidKey = SkidService3.generateKey(skid, attributeList);

		        	if(existingSkidMap.containsKey(skidKey)){
		        		skid.Id = existingSkidMap.get(skidKey).Id;
		        	}else{
		        		system.debug(LoggingLevel.DEBUG, JSON.serialize(attributeList));
			        	system.debug(LoggingLevel.DEBUG, JSON.serialize(skidKey));
			        	system.debug(LoggingLevel.DEBUG, JSON.serialize(existingSkidMap.keySet()));
		        	}

		        	List<Serial__c> serialList = new List<Serial__c>();

		        	Decimal countQuantity = skid.Count_Quantity__c != null ? skid.Count_Quantity__c : 0;
		        	skid.Count_Quantity__c = 0; // To prevent double count when initializing serial wrapper.

		        	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap;

		        	if(countQuantity > 0){
			        	if(positiveSerialWrapperMap.containsKey(icKey) == false){
			        		serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
			        		positiveSerialWrapperMap.put(icKey, serialWrapperMap);
			        	}

		        		serialWrapperMap = positiveSerialWrapperMap.get(icKey);
			        }else{
		        		if(negativeSerialWrapperMap.containsKey(icKey) == false){
			        		serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
			        		negativeSerialWrapperMap.put(icKey, serialWrapperMap);
			        	}

						serialWrapperMap = negativeSerialWrapperMap.get(icKey);
		        	}

	        		SkidService3.SerialWrapper serialWrapper = serialWrapperMap.get(skidKey);
		        	if(serialWrapper == null){
	        			serialWrapper = new SkidService3.SerialWrapper(skid, new List<Serial__c>());
	        			serialWrapperMap.put(skidKey, serialWrapper);
	        		}

	        		serialWrapper.skid.Count_Quantity__c += countQuantity;

	        		if(serialWrapper.serialList == null){
	        			serialWrapper.serialList = new List<Serial__c>();
	        		}

	        		if(countQuantity > 0){
	        			serialWrapper.serialList.addAll(serialList);
	        		}
	        	}

		        for(String icKey : negativeSerialWrapperMap.keySet()){
		        	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = negativeSerialWrapperMap.get(icKey);

		        	List<SkidService3.SerialWrapper> inventoryRemoved = new List<SkidService3.SerialWrapper>();

		        	for(List<String> skidKey : serialWrapperMap.keySet()){
		        		inventoryRemoved.add(serialWrapperMap.get(skidKey));
		        	}

		        	if(inventoryRemoved.size() > 0){

			        	if(negativeICMap.containsKey(icKey) == false){
			        		negativeICMap.put(icKey, positiveICMap.get(icKey).clone());
			        	}

			        	Inventory_Change__c negativeIC = negativeICMap.get(icKey);

			        	InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(negativeIC, inventoryRemoved);
				    	negativeICWrappers.add(icWrapper);
				    }

		        }

		    	for(String icKey : positiveSerialWrapperMap.keySet()){
		        	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = positiveSerialWrapperMap.get(icKey);

		        	List<SkidService3.SerialWrapper> inventoryAdded = new List<SkidService3.SerialWrapper>();

		        	for(List<String> skidKey : serialWrapperMap.keySet()){
	        			inventoryAdded.add(serialWrapperMap.get(skidKey));
		        	}

		        	if(inventoryAdded.size() > 0){
		        		InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(positiveICMap.get(icKey), inventoryAdded);
				    	positiveICWrappers.add(icWrapper);
		        	}
		        }

		        Savepoint sp = Database.setSavepoint();

		        try{
		        	if(negativeICWrappers.size() > 0){
		        		DML.insertAsSystem(negativeICMap.values());
		            	InventoryChangeService.inventoryAdjustment(negativeICWrappers, 'Cycle Count');
		        	}

		        	if(positiveICWrappers.size() > 0){
		        		DML.insertAsSystem(positiveICMap.values());
		            	InventoryChangeService.inventoryAdjustment(positiveICWrappers, 'Cycle Count');
		        	}
					
					bin.Blocked__c = false;
					bin.Last_Cycle_Count__c = system.now();
					updatedBins.put(bin.Id, bin);
					
					DML.updateAsSystem(updatedBins.values());
					resp.success = true;
					
		        }catch(Exception ex){
		        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
		        	Database.rollback(sp);
		        	resp.success = false;
        			resp.error.put('message', ex.getMessage());
		        }
		    }
	        catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
	        	resp.error.put('message', ex.getMessage());
	        }

	        return resp;
        }
    }
	
	public class generatePicks implements Action.Target{
        public Action.Response execute(Object obj){

            Action.Response resp = new Action.Response();

	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
	        	
	        	String shipmentId = params.get('Shipment__c') != null ? (String) params.get('Shipment__c') : null;
	        	String shipmentLineIds = '';
	        	Set<Id> itemsToPlan = new Set<Id>();
	        	Map<Id, LineWrapper> shlWrapperToPlanMap = new Map<Id, LineWrapper>();
					
	        	List<Object> inventoryLines = params.get('inventory') != null ? (List<Object>) params.get('inventory') : new List<Object>();
	        	List<Object> skippedBins = params.get('skippedBins') != null ? (List<Object>) params.get('skippedBins') : new List<Object>();
	        	List<Object> skippedLocations = params.get('skippedLocations') != null ? (List<Object>) params.get('skippedLocations') : new List<Object>();
               
               	for(Object inventoryLine : inventoryLines){
					Map<String, Object> lineToPlan = (Map<String, Object>) inventoryLine;
					
					String shlId = (String) lineToPlan.get('Shipment_Line__c');
					shipmentLineIds += '\'' + shlId + '\',';
               	}
               	
               	if(shipmentLineIds.length() > 0){
               		shipmentLineIds = shipmentLineIds.removeEnd(',');
               		shipmentLineIds = '(' + shipmentLineIds + ')';
               		
               		Map<Id, Shipment_Line__c> shlMap = new Map<Id, Shipment_Line__c>(ShipmentWorkbenchExt.getShipmentLines(new Map<String, Object>{ 'Id' => shipmentLineIds }, 'planpick'));
  
                	shipmentId = shlMap.values()[0].Shipment__c;
			        
			        List<LineWrapper> wrappers = ShipmentInventoryService.getInventoryForPlan(shlMap.values());
			        
					Map<Id, List<LineWrapper>> shlWrapperMap = new Map<Id, List<LineWrapper>>();
					 
					for (LineWrapper shlWrapper : wrappers) {
						if(shlWrapperMap.containsKey(shlWrapper.line.Id) == false){
							shlWrapperMap.put(shlWrapper.line.Id, new List<LineWrapper>());	
						}
						
						shlWrapperMap.get(shlWrapper.line.Id).add(shlWrapper);
					}
					
					for(Object inventoryLine : inventoryLines){
						Map<String, Object> lineToPlan = (Map<String, Object>) inventoryLine;
						
						String shlId = lineToPlan.get('Shipment_Line__c') != null ? (String) lineToPlan.get('Shipment_Line__c') : '';
						
						if(String.isNotBlank(shlId)){
							Decimal quantity = (Decimal) lineToPlan.get('quantity');
							String packagingUOMName = (String) lineToPlan.get('Packaging_UOM__c');
							String fromBinId = lineToPlan.get('fromBinId') != null ? (String) lineToPlan.get('fromBinId') : null;
							String fromLocationId = lineToPlan.get('fromLocationId') != null ? (String) lineToPlan.get('fromLocationId') : null;
							
							if(shlWrapperToPlanMap.containsKey(shlId) == false){
			                	shlWrapperToPlanMap.put(shlId, new LineWrapper(shlMap.get(shlId).Shipment__r, shlMap.get(shlId), new List<SkidService3.SerialWrapper>()));	
			                }
			                
			                LineWrapper shlWrapper = shlWrapperToPlanMap.get(shlId);
				        
					        for (LineWrapper uomWrapper : shlWrapperMap.get(shlId)) {
					            if (uomWrapper.uom == packagingUOMName) {
					            	for (SkidService3.SerialWrapper serialWrapper : uomWrapper.serialWrappers) {
						            	if(String.isNotBlank(fromBinId) && serialWrapper.skid.Bin__c == fromBinId){
					                        serialWrapper.skid.Quantity_to_Issue__c = quantity;
					                        serialWrapper.skid.Input_Quantity__c = serialWrapper.skid.Quantity_to_Issue__c * serialWrapper.skid.Quantity_Issued__c;
							                serialWrapper.skid.Item__r = (Item__c) shlWrapper.line.getSObject('Item__r');
						                	
						                	shlWrapper.serialWrappers.add(serialWrapper);
						                	
						                	if(quantity < 0){
								            	itemsToPlan.add(serialWrapper.skid.Item__r.Id);
								            }
						                }
						                else
						                if(String.isNotBlank(fromLocationId) && serialWrapper.skid.Location__c == fromLocationId){
					                        serialWrapper.skid.Quantity_to_Issue__c = quantity;
					                        serialWrapper.skid.Input_Quantity__c = serialWrapper.skid.Quantity_to_Issue__c * serialWrapper.skid.Quantity_Issued__c;
							                serialWrapper.skid.Item__r = (Item__c) shlWrapper.line.getSObject('Item__r');
						                	
						                	shlWrapper.serialWrappers.add(serialWrapper);
						                	
						                	if(quantity < 0){
								            	itemsToPlan.add(serialWrapper.skid.Item__r.Id);
								            }
						                }
					                }
					            }
					        }
						}
					}
				}
				
				Savepoint sp = Database.setSavepoint();
					
				try{
					if(shlWrapperToPlanMap.size() > 0){
						
						ShipmentInventoryService.plan(shlWrapperToPlanMap.values());
						
						if(itemsToPlan.size() > 0){
							
							Set<Id> binsToIgnore = new Set<Id>();
							for(Integer i=0; i < skippedBins.size(); i++){
								binsToIgnore.add((Id) skippedBins[i]);
							} 
							
							Set<Id> locationsToIgnore = new Set<Id>();
							for(Integer i=0; i < skippedLocations.size(); i++){
								locationsToIgnore.add((Id) skippedLocations[i]);
							} 
							resp.success = planShipment(shipmentId, itemsToPlan, binsToIgnore, locationsToIgnore);
						}
					}else{
						resp.success = planShipment(shipmentId);
					}
				}catch(Exception ex){
					system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
		       		Database.rollback(sp);
		       		throw ex;
				}
            }catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
	        	resp.error.put('message', ex.getMessage());
	        }

	        return resp;
        }
    }
    
	public class managePicks implements Action.Target{
        public Action.Response execute(Object obj){

            Action.Response resp = new Action.Response();

	        try{
	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
				
				List<String> pickSkidIds = new List<String>();
				List<Object> pickLines = params.get('pickLines') != null ? (List<Object>) params.get('pickLines') : new List<Object>();
				
				for(Object inventoryLine : pickLines){
					Map<String, Object> pickLine = (Map<String, Object>) inventoryLine;
					pickSkidIds.add(String.valueOf(pickLine.get('Id')));
				}
				
				Boolean isPicking = (Boolean) params.get('isPicking');
				String currentUserId = UserInfo.getUserId();

				Map<Id, SKID__c> plannedPickSkids = new Map<Id, SKID__c>([SELECT Id, Scanned_For_Pick__c, Current_Picker__c
																			FROM SKID__c 
																		   WHERE Id IN :pickSkidIds 
																		   	 //AND Type__c = 'Planned Pick' 
																		   	 //AND (Current_Picker__c = null OR Current_Picker__c = :currentUserId) 
																		   	 AND ((Picker__c = :currentUserId) OR (Picker__c = null AND (Current_Picker__c = null OR Current_Picker__c = :currentUserId)))
																		   	 FOR UPDATE
																		 ]);

				if(plannedPickSkids.size() == 0){
					throw new ScannerServiceException('Lines not available for picking');
				}
				
				for(Object inventoryLine : pickLines){
					Map<String, Object> pickLine = (Map<String, Object>) inventoryLine;
					
					String pickLineId = (String) pickLine.get('Id');
					
					if(plannedPickSkids.containsKey(pickLineId)){
						SKID__c pickSkid = plannedPickSkids.get(pickLineId); 
					
						if(isPicking){
							pickSkid.Current_Picker__c = currentUserId;
						}else{
							pickSkid.Current_Picker__c = null;
						}
						
						if(pickLine.get('contents') != null){
							Set<String> contents = new Set<String>();
	
							if(!String.isBlank(pickSkid.Scanned_For_Pick__c)){
								contents = new Set<String>(pickSkid.Scanned_For_Pick__c.split(','));
							}
							
							List<Object> caseNumbers = (List<Object>) pickLine.get('contents');
							
							for(Object caseNumber : caseNumbers){
								String caseString = String.valueOf(caseNumber);
								contents.add(caseString);
							}
					
							pickSkid.Scanned_For_Pick__c = String.join(new List<String>(contents), ',');
						}
					}else{
						throw new ScannerServiceException('Lines not available for picking');
					}
				}
				
				update plannedPickSkids.values();
				
				resp.success = true;
		    }
	        catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
	        	resp.error.put('message', ex.getMessage());
	        }

	        return resp;
        }
    }

	public class pickInventory implements Action.Target{
		public Action.Response execute(Object obj){
			Action.Response resp = new Action.Response();

			try{
				Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
				Boolean isUndo = params.containsKey('isUndo') ? (Boolean) params.get('isUndo') : false ;
				List<Object> inventory = (List<Object>) params.get('inventory');

				Set<String> lpnNames = new Set<String>();
				Set<String> binNames = new Set<String>();

				String lpnField = isUndo ? 'toLPN' : 'fromLPN';

				// 1. Get line wrappers
				String shipmentLineIds = '(';

				for(Object inventoryLine : inventory){
					Map<String, Object> pickLine = (Map<String, Object>) inventoryLine;

					lpnNames.add((String)pickLine.get(lpnField));
					binNames.add((String)pickLine.get('fromBin'));
					binNames.add((String)pickLine.get('toBin'));

					shipmentLineIds += '\'' + (String)pickLine.get('Shipment_Line__c') + '\'';
					shipmentLineIds += ',';
				}

				shipmentLineIds = shipmentLineIds.removeEnd(',');
				shipmentLineIds += ')';

				Map<Id, Shipment_Line__c> shlMap = new Map<Id, Shipment_Line__c>(
						ShipmentWorkbenchExt.getShipmentLines(
								new Map<String, Object>{ 'Id' => shipmentLineIds },
								'pick'
						)
				);

				// For undo, getting the existing location skids for ship lines
				Map<String, Skid__c> skidMap = new Map<String, Skid__c>();
				if ( isUndo ) {
					SOQLUtil util = new SOQLUtil ('Skid__c');
					util.addAllCustomFields();
					util.addfield('Packaging_UOM__r.name');
					util.addAllCustomFields(Location__c.sObjectType, 'Location__r');
					util.addAllCustomFields(Bin__c.sObjectType, 'Bin__r');
					util.setWhereClause(' Shipment_Line__c IN '+ shipmentLineIds + ' AND Type__c = \'Location\'');
					for ( Skid__c sk : Database.query(util.getQuery()) ) {
						skidMap.put(''+sk.Shipment_Line__c+sk.Packaging_UOM__r.Name+sk.License_Plate_Number__c, sk);
					}
				}
                
				Map<String, Bin__c> binMap = getBinsByName(binNames);
				Map<String, LPN__c> lpnMap = getLPNsByName(lpnNames);

				Map<String, SkidService3.SerialWrapper> serialWrapperMap = new Map<String, SkidService3.SerialWrapper>();

				Map<String, LineWrapper> pickedLineWrappersMap = new Map<String, LineWrapper>();
				Map<String, SkidService3.SerialWrapper> pickedSerialWrapperMap = new Map<String, SkidService3.SerialWrapper>();

				List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());

                // hold the pick inventory location by skid key, takes care of overwrites
                // on skidserial wrapper
                Map<String, Id> mapOriginalLocation = new Map<String, Id>();

				for(LineWrapper lineWrapper : ShipmentInventoryService.getInventoryForPick(shlMap.values())){
					for (SkidService3.SerialWrapper serialWrapper : lineWrapper.serialWrappers) {
						String skidKey = isUndo 
											? ('' + lineWrapper.line.Id + serialWrapper.skid.Packaging_UOM__r.Name + serialWrapper.skid.License_Plate_Number__c) 
											: ('' + lineWrapper.line.Id + lineWrapper.uom + serialWrapper.skid.Location__c + serialWrapper.skid.Bin__c + serialWrapper.skid.License_Plate_Number__c);
						serialWrapper.skid.Quantity_To_Issue__c = 0;
						serialWrapper.skid.Quantity_To_Return__c = 0;

						if ( !serialWrapperMap.containskey(skidKey) ) {
							serialWrapperMap.put(skidKey, serialWrapper);
						} else {
							SkidService3.SerialWrapper sw = serialWrapperMap.get(skidKey);
							sw.skid.Quantity_Used__c += serialWrapper.skid.Quantity_Used__c;
							serialWrapperMap.put(skidKey, sw);
						}
						
					}
				}

				for(Object inventoryLine : inventory){

					Map<String, Object> pickLine = (Map<String, Object>) inventoryLine;

					String shipmentLineId = (String) pickLine.get('Shipment_Line__c');
					String packagingUOMName = (String) pickLine.get('Packaging_UOM__c');
					String fromLPN = (String) pickLine.get(lpnField);
					String fromLocationId = (String) pickLine.get('Location__c');
					String fromBin = (String) pickLine.get('fromBin');
					String toBin = (String) pickLine.get('toBin');
                    
					Skid__c locnSkid;
					
					// NOTE: For undo pick, from bin and tobin info is derived from the Location skids for Ship Lines
					String fromBinId;
					Bin__c shippingBin;

					String lpnId=null;
					if (!String.isBlank(fromLPN)) {
						if (lpnMap.containsKey(fromLPN)) {
							lpnId = lpnMap.get(fromLPN).Id;
						} else {
							throw new ScannerServiceException('LPN not found: ' + fromLPN);
						}
					}

					if ( isUndo ) {
                        String key = ''+shipmentLineId + packagingUOMName + lpnId;
						if ( skidMap.containsKey(key) == false) {
							throw new ScannerServiceException ('Pick lines not found for the shipment line ' );
						}
						locnSkid = skidMap.get(key);
						shippingBin = locnSkid.Bin__r;
					} else {
						if(binMap.containsKey(fromBin)){
							fromBinId = binMap.get(fromBin).Id;
						}
						//else{
						//	throw new ScannerServiceException('Bin not found: ' + fromBin);
						//}

						if (String.isBlank(toBin) == false) {
							if (binMap.containsKey(toBin) == true) {
								shippingBin = binMap.get(toBin);
							}
							else{
								throw new ScannerServiceException('Bin not found: ' + toBin);
							}
						}
					}

					String serialWrapperKey = isUndo ? ('' + shipmentLineId + packagingUOMName + lpnId) : ('' + shipmentLineId + packagingUOMName + fromLocationId + fromBinId + lpnId);
					SkidService3.SerialWrapper serialWrapper = null;
					
					Item__c shlItem = shlMap.get(shipmentLineId).Item__r;
						
					List<String> packagingUoMs = (List<String>) JSON.deserialize(shlItem.Packaging_UOM__c, List<String>.class);
					Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));
					
					String eachUOMName = packagingUoMs.size() > 0 ? uomsMap.get(packagingUoMs[0]).Name : '';
					String caseUOMName = packagingUoMs.size() > 1 ? uomsMap.get(packagingUoMs[1]).Name : '';
					String palletUOMName = packagingUoMs.size() > 2 ? uomsMap.get(packagingUoMs[2]).Name : '';
					
					Decimal quantity = (packagingUOMName == eachUOMName) ? (Decimal) pickLine.get('quantity') : 1;
					
					if(isUndo == false && packagingUOMName == eachUOMName){
						if(serialWrapperMap.containsKey(serialWrapperKey) && serialWrapperMap.get(serialWrapperKey).skid.Quantity_Available__c >= quantity){
							serialWrapper = serialWrapperMap.get(serialWrapperKey);
						}else{
							serialWrapperKey = '' + shipmentLineId + caseUOMName + fromLocationId + fromBinId + lpnId;
							serialWrapper = serialWrapperMap.get(serialWrapperKey);
						}
					}
					else
					if(serialWrapperMap.containsKey(serialWrapperKey)){
						serialWrapper = serialWrapperMap.get(serialWrapperKey);
					} 
					else
					if(packagingUOMName == caseUOMName){
						serialWrapperKey = '' + shipmentLineId + palletUOMName + fromLocationId + fromBinId + lpnId;
						serialWrapper = serialWrapperMap.get(serialWrapperKey);
					}
						
					if(serialWrapper != null){
						// Hold the pick inventory location by skid key, takes care of overwrites
                		// on skidserial wrapper
						if (!mapOriginalLocation.containsKey(serialWrapperKey)){
	                        mapOriginalLocation.put(serialWrapperKey, serialWrapper.skid.Location__c);
						}
	                        
                        Id originalLoc = mapOriginalLocation.get(serialWrapperKey);
                            
						LineWrapper shlWrapper;
				        
				        if(pickedLineWrappersMap.containsKey(shipmentLineId)){
				        	shlWrapper = pickedLineWrappersMap.get(shipmentLineId);
				        }else{
					        shlWrapper = new LineWrapper(shlMap.get(shipmentLineId).Shipment__r, shlMap.get(shipmentLineId), new List<SkidService3.SerialWrapper>());
					        shlWrapper.line = shlMap.get(shipmentLineId);
					        shlWrapper.header = shlWrapper.line.getSObject('Shipment__r');
					        pickedLineWrappersMap.put(shipmentLineId, shlWrapper);
				        }   
				        
				        SKID__c skid = serialWrapper.skid;

                        if (shippingBin != null) {
                        	serialWrapper.toSkid = new SKID__c(Bin__c = shippingBin.Id, Bin__r = shippingBin);
                        }

						if ( isUndo  ) {
							skid.Temporary_Value_Holder1__c = locnSkid.Bin__c;
							quantity = -quantity;
							// For undo returning back to Ship From Location instead of stock
							// temporaryValueHolder = stockLocation + stockBin + shippingBin
							serialWrapper.temporaryValueHolder = originalLoc + '|' + skid.Bin__c + '|' + locnSkid.Bin__c ;
							skid.Location__c = locnSkid.Location__c;
							skid.Location__r = locnSkid.Location__r;
							skid.Bin__c = locnSkid.Bin__c;
							skid.Bin__r = locnSkid.Bin__r;
                        } else {
                            //KNDY-20178
				        	serialWrapper.temporaryValueHolder = skid.Location__c + '|' + skid.Bin__c + '|' + shippingBin.Id;
                        }

						if(packagingUOMName == skid.Packaging_UOM__r.Name){
							skid.Quantity_to_Issue__c += quantity;
						}else{
							skid.Quantity_to_Return__c += quantity;
						}
				        
				        if(pickedSerialWrapperMap.containsKey(serialWrapperKey) == false){
				        	pickedSerialWrapperMap.put(serialWrapperKey, serialWrapper);
					        shlWrapper.serialWrappers.add(serialWrapper);
				        }   
				    }else{
				    	system.debug(LoggingLevel.INFO, serialWrapperKey);
				    	system.debug(LoggingLevel.INFO, JSON.serialize(serialWrapperMap.keySet()));

				    	String shipmentLine = shlMap.get(shipmentLineId).Name;
						throw new ScannerServiceException('Inventory not found for: ' + shipmentLine);
					}
				}

				Savepoint sp = Database.setSavepoint();

				try{
					if(pickedLineWrappersMap.size() > 0){
						system.debug(LoggingLevel.INFO, JSON.serialize(pickedLineWrappersMap));
						ShipmentInventoryService.pick(pickedLineWrappersMap.values());
						resp.success = true;
					}else{
						resp.success = false;
						resp.error.put('message', 'No lines found to pick');
					}
				} catch(Exception ex) {
					system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
					Database.rollback(sp);
					throw ex;
				}
			}
	        catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
	        	resp.error.put('message', 'Pick Error: ' + ex.getMessage());
	        }

	        return resp;
        }
	}

	/**
	 * Get IT's for the shipment lines grouped by it type.
	 *
	 * Note: This will <em>possibly<em> fail in case of multi location issues
	 * For JCI it should be ok.
	 */
	static Map<Id, Map<Id, List<Inventory_Transaction__c>>> getShipmentLineITs (Set<Id> shipmentLineIds) {
		Set<String> itTypes = new Set<String> {
				'Transfer',
                'Sales Order Pick Transfer',
				'Sales Order Pick',
				'Sales Order Undo Pick'
		};
		SOQLUtil util = new SOQLUtil ('Inventory_Transaction__c');
		util.addAllCustomFields();
		util.addFields ( new Set<String> { 'License_Plate_Number__r.Name', 'From_Bin__r.Name' });
		util.setWhereClause( 'Shipment_Line__c in :shipmentLineIds AND Type__c in :itTypes' );
		util.setOrderByClause('CreatedDate ASC');

		List<Inventory_Transaction__c> its = Database.query(util.getQuery());

		List<String> itAttributes = new List<String>{
			'Shipment_Line__c',
			'Packaging_UOM__c',
			'License_Plate_Number__c',
			'Bin__c'
		};

		Map<String, Inventory_Transaction__c> pickMap = new Map<String, Inventory_Transaction__c>();
		Map<List<String>, Inventory_Transaction__c> tmpMap = new Map<List<String>, Inventory_Transaction__c>();

		for ( Inventory_Transaction__c it : its ) {
//            if (it.Type__c == 'Sales Order Pick Transfer'){
//                throw new ScannerServiceException ('Partial Ship Shipments are not supported for unpack.');
//            }
            if ( it.Type__c == 'Sales Order Pick' || it.Type__c == 'Sales Order Pick Transfer' ) {
                pickMap.put(it.To_Skid_Identifier__c, it );
            } else if ( it.Type__c == 'Sales Order Undo Pick') {
                pickMap.put(it.From_Skid_Identifier__c, it );
            } else if ( it.Type__c == 'Transfer' ) {
                Inventory_Transaction__c relatedIT;
                // is this an incoming transfer or outgoing
                if ( pickMap.containskey (it.From_Skid_Identifier__c)) {
                    relatedIT = pickMap.get( it.From_Skid_Identifier__c );
                    it.License_Plate_Number__c = relatedIT.License_Plate_Number__c;
                    it.License_Plate_Number__r = relatedIT.License_Plate_Number__r;
                } else {
                    it.Quantity__c = -it.Quantity__c;
                    it.Quantity_Stocking_UOM__c = -it.Quantity_Stocking_UOM__c;
                }

                List<String> key = new List<String>();
                for ( String attr : itAttributes ) {
                    key.add(String.valueOf(it.get(attr)));
                }

				if ( !tmpMap.containsKey(key)) {
					tmpMap.put(key, it);
				} else {
					tmpMap.get(key).Quantity__c += it.Quantity__c;
					tmpMap.get(key).Quantity_Stocking_UOM__c += it.Quantity_Stocking_UOM__c;
				}
			}
		}

		Map<Id, Map<Id, List<Inventory_Transaction__c>>> mapITs = new Map<Id, Map<Id, List<Inventory_Transaction__c>>>();

		for ( Inventory_Transaction__c it : tmpMap.values() ) {
			if ( it.Quantity__c <= 0 ) continue;
			if ( !mapITs.containsKey(it.Shipment_Line__c) ) {
				mapITs.put(it.Shipment_Line__c, new Map<Id, List<Inventory_Transaction__c>>());
			}
			if (!mapITs.get(it.Shipment_Line__c).containsKey(it.Packaging_UOM__c)) {
				mapITs.get(it.Shipment_Line__c).put(it.Packaging_UOM__c, new List<Inventory_Transaction__c>());
			}

			mapITs.get(it.Shipment_Line__c).get(it.Packaging_UOM__c).add(it);
		}

		return mapITs;
	}

	//@future
	// for part pallets, after the undo pack/undo pick operation
	// it will have the previous lpn which was issued from. this lpn
	// was broken when moving it to mixed pallet as part of pack operation
	// and the old lpn doesn't exist anymore (this is JCI specific)
	// hence the transfer operation is called again.
	private static void breakPackageForPartPallet ( String obj ) {

		Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
		List<Object> inventory = params.containsKey('inventory') ? ((List<Object>) params.get('inventory')) : new List<Object>();

		Set<String> lpnNames = new Set<String> ();

		for ( Object line : inventory ) {
			Map<String, Object> inventoryLine = (Map<String, Object>) line;
			// as part of undo pack - toLPN will be populated for inventory
			if ( inventoryLine.containsKey('toLPN') && String.isNotEmpty( (String) inventoryLine.get('toLPN')) )
				lpnNames.add( (String) inventoryLine.get('toLPN') );
		}

		if ( !lpnNames.isEmpty() ) {
			Map<String, LPN__c> lpnMap = getLPNsByName(lpnNames);
			// Fetching the skid wrappers based on the toLPN of the inventory lines
			List<SkidService3.SerialWrapper> wrappers = InventoryChangeService.getSkids(new Map<String, Set<Id>>{
					'License_Plate_Number__c' => KSE.grepRelatedIdSetFromList(lpnMap.values(), 'Id', true )
			}, null, null, true);

			Inventory_Change__c inventoryChange;
			List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
			DateTime transactionDate = system.now();

			if ( wrappers!= null && !wrappers.isEmpty()) {
				for (SkidService3.SerialWrapper sw : wrappers) {
					if (inventoryChange == null) {
						inventoryChange = new Inventory_Change__c();
						inventoryChange.Company__c = sw.skid.Company__c;
						inventoryChange.Transaction_Date__c = transactionDate;
						inventoryChange.Type__c = 'Transfer';
					}

					SKID__c toSkid = new SKID__c(Company__c = sw.skid.Company__c, Item__c = sw.skid.Item__c, Item__r = sw.skid.Item__r,
							Facility2__c = sw.skid.Facility2__c);
					toSkid.Location__c = sw.skid.Location__c;
					toSkid.Location__r = sw.skid.Location__r;
					toSkid.Bin__c = sw.skid.Bin__c;
					toSkid.Bin__r = sw.skid.Bin__r;
					toSkid.Stocking_UOM__c = null;
					toSkid.Stocking_UOM__r = null;
					toSkid.Quantity_Available__c = sw.skid.Quantity_Available__c;
					toSkid.Packaging_UOM__c = sw.skid.Packaging_UOM__c;
					toSkid.Packaging_UOM__r = sw.skid.Packaging_UOM__r;
					toSkid.License_Plate_Number__c = null;
					sw.skid.Input_Quantity__c = sw.skid.Quantity_Available__c;
					swList.add(new SkidService3.SerialWrapper(sw.skid, null, sw.serialList, toSkid));
				}

				Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(new Set<String>{
						inventoryChange.Company__c
				});
				inventoryChange.Company__r = mCompanies.get(inventoryChange.Company__c);

				List<String> attrsToCorrect = new List<String>{
						'Packaging_UOM__c'
				};
				InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(inventoryChange, swList);
				DML.insertAsSystem(inventoryChange);
				InventoryChangeService.inventoryTransfer(new List<InventoryChangeWrapper>{
						icWrapper
				}, attrsToCorrect);
			}
		}

	}

	/**
	 * @description removes the ship lines from the shipment.
	 * 				mixed pallet: unpack and unpick
	 *              full pallet : unpick only
	 *
	 */
	public class RemoveFromShipment implements Action.Target {
		public Action.Response execute(Object obj){
			// inventory for which unpack needs to be performed
			Action.Response resp = new Action.Response();
			Savepoint sp = Database.setSavePoint();
			try {
				/**
				 * params : {
				 * 		fromLPN: 'LPN NAME',
				 * 		inventory : [
				 * 			{
				 * 				itemId				: 	'',
				 * 				quantity			: 	100,
				 * 			    caseNumber          :   ''
				 * 			}
				 * 		]
				 * }
				 */
				Boolean isfullPallet = false;
				List<String> contents = new List<String>();
				Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
				Map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new Map<Item__c, Set<UOM__c>>();

				Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
				params.put('isUndo', true);

				// check for inventory. if inventory doesn't exist then lpn will be used
				// to fill the inventory information.
				List<Object> inventory = params.containsKey('inventory') ? ((List<Object>) params.get('inventory')) : new List<Object>();

				// check for fromLPN if this is pallet
				// LPN is required to remove from shipment - full or mixed pallet
				if ( params.containsKey('fromLPN') == false ) {
					throw new ScannerServiceException ('You need to specify LPN to remove from shipment.');
				}

				String fromLPN = (String) params.get('fromLPN');

				// Get lpn info
				SOQLUtil util = new SOQLUtil ('LPN__c');
				util.addFields( new Set<String>{'Id', 'Name', 'Contents__c'} );
				util.setWhereClause('Name = :fromLPN');

				// Get skids for the LPN and shipment
				SOQLUtil.ChildRelationship skidUtil = new SOQLUtil.ChildRelationship(util, 'Skids__r');
				skidUtil.addFields(new Set<String>{'Id', 'Quantity__c', 'Packaging_UOM__c', 'Packaging_UOM__r.Name', 'Packaging_UOM__r.Package_Class__r.Level__c',
						'Container_Item__c', 'Shipment_Line__c', 'Item__c',
						'License_Plate_Number__r.Contents__c', 'Item__r.Packaging_UOM__c',
						'Stocking_UOM__c', 'Facility2__r.Facility_Identifier__c', 'Mixed_Palletized__c',
						'Item__r.Container_Item__c', 'Item__r.Container_Item__r.Container_Package_Class__c'});
				skidUtil.addAllCustomFields(Item__c.sObjectType, 'Item__r' );
				skidUtil.setWhereClause('Type__c =\'Location\' AND Shipment_Line__c != null');
				skidUtil.setOrderByClause('Packaging_UOM__r.Package_Class__r.Level__c DESC');
				util.addChildRelationship(skidUtil);

				List<LPN__c> lpns = Database.query(util.getQuery());

				// LPN is required
				if ( lpns.isEmpty() )
					throw new ScannerServiceException('LPN not found');

				if ( String.isNotEmpty(lpns[0].Contents__c) )
					contents = lpns[0].Contents__c.split(',');

				List<Skid__c> skids = lpns[0].Skids__r;

				// if no skids for lpn exists, then there is no inventory movement possible
				if ( skids.isEmpty() ) {
					throw new ScannerServiceException('No lines found for the LPN');
				} else 
				if ( skids.size() == 1 && skids[0].Packaging_UOM__r.Package_Class__r != null && skids[0].Packaging_UOM__r.Package_Class__r.Level__c == 3 ) {
					isFullPallet = true;
				}

				Iterator<String> iter = contents.iterator();
				Set<Id> shipmentLines = new Set<Id> ();
				Map<Id, List<Skid__c>> skidsByItem = new Map<Id, List<Skid__c>>();

                Set<String> uomIds = new Set<String>();
				for ( Skid__c sk : skids ) {
					if ( itemPackagingUomCache.containsKey(sk.Item__c) == false) {
						itemPackagingUomCache.put(sk.Item__c, (List<Id>) JSON.deserialize(sk.Item__r.Packaging_UOM__c, List<Id>.class ));
                        List<String> uoms = itemPackagingUomCache.get(sk.Item__c);
                        uomIds.addAll(uoms);
					}

					if ( !skidsByItem.containsKey(sk.Item__c) ) skidsByItem.put(sk.Item__c, new List<Skid__c>());
					skidsByItem.get(sk.Item__c).add(sk);

					if(!itemsWithPackagingUOM.containskey(sk.item__r)){
						itemsWithPackagingUOM.put(sk.item__r, new Set<UOM__c>());
					}

					for ( Id pkgUomId : itemPackagingUomCache.get(sk.Item__c) ) {
                        itemsWithPackagingUOM.get(sk.item__r).add(new UOM__c(Id = pkgUomId));
                    }

					shipmentLines.add(sk.Shipment_Line__c);
				}

                Map<String, UOM__c> uomMap = getUOMs(uomIds);

				// get its by shipment line (pick, transfer)
				Map<Id, Map<Id,List<Inventory_Transaction__c>>> shipmentIts = getShipmentLineITs(shipmentLines);

				map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
				if(itemsWithPackagingUOM.values().size() > 0){
					containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
				}

				if ( inventory.isEmpty() ) {
					for (List<Skid__c> lstSkids : skidsByItem.values()) {
						Id shipLineID = lstSkids[0].Shipment_Line__c;
						for (Skid__c sk : lstSkids) {
							Decimal convFactor = KSE.getConversionFactor(sk.Item__c, sk.Facility2__r.Facility_Identifier__c, sk.Packaging_UOM__c, sk.Stocking_UOM__c, itemPackagingUomCache.get(sk.Item__c));

							Map<String, Object> inventoryLine = new Map<String, Object>{
									'itemId' => sk.Item__c,
									'Shipment_Line__c' => sk.Shipment_Line__c,
									'Packaging_UOM__c' => sk.Packaging_UOM__r.Name,
									'Container_Item__c' => sk.Container_Item__c,
									'fromLPN' => fromLPN,
									'pkgUOMId' => sk.Packaging_UOM__c
							};

							if (sk.Mixed_Palletized__c) {
								if (sk.Packaging_UOM__c == sk.Stocking_UOM__c) {
									// for eaches, we will have only one inventory line
									// Assuming that there will be only one part case
									// Not enforcing caseNumber on part eaches, as there is no
									// distinction of part cases to loose eaches.
									inventoryLine.put('quantity', sk.Quantity__c);
									if (iter.hasNext() == false) throw new ScannerServiceException('Invalid or no cases to remove from shipment.');
									inventoryLine.put('caseNumber', iter.next());
									
									inventory.add(inventoryLine);
								} else {
									// cases - each case needs its own inventory line with case number
									for (Integer ii = 0; ii < Integer.valueOf(sk.Quantity__c); ii++) {

										Decimal caseQuantity = 1 * convFactor;
										Map<String, Object> caseInventory = inventoryLine.clone();
										caseInventory.put('quantity', caseQuantity);

										if (iter.hasNext() == false) throw new ScannerServiceException('Invalid or no cases to remove from shipment.');
										caseInventory.put('caseNumber', iter.next());
										inventory.add(caseInventory);
									}
								}
							} else {
								// this is the case when removing whole pallets
								inventoryLine.put('quantity', sk.Quantity__c);
                                inventoryLine.put('toLPN', fromLPN);
								inventory.add(inventoryLine);
							}
						}
					}

					params.put('inventory', inventory);
				} else {
					Map<Id, List<Id>> itemPackagingUoms = new Map<Id, List<Id>>();
					// case when the inventory info is passed to the Remove api
					for ( Object invObj : inventory){
						Map<String, Object> inventoryLine = (Map<String, Object>) invObj;
						Id itemId = (Id)inventoryLine.get('itemId');
                        Decimal quantity = (Decimal) inventoryLine.get('quantity');
						if ( itemId == null ) {
							throw new ScannerServiceException('Invalid or missing item');
						}
						List<Skid__c> lstSkids = skidsByItem.get(itemId);
						List<Id> itemUOMS = itemPackagingUomCache.get(itemId);

						String eachUOMId = itemUOMS.size() > 0 ? itemUOMS[0] : null;
						String caseUOMId = itemUOMS.size() > 1 ? itemUOMS[1] : null;
                        String palletUOMId = itemUOMS.size() > 2 ? itemUOMS[2] : null;

						if ( lstSkids== null || lstSkids.isEmpty() )
							throw new ScannerServiceException('Invalid item for the shipment.');

                        // This restricts 1 shipment line for 1 item
                        Id shipmentLineId = lstSkids[0].Shipment_Line__c;

						Id pkgUomId;
						
						if(String.isNotBlank(caseUOMId)){
							Decimal caseCapacity = KSE.getConversionFactor(itemId,userDefaults.Default_Facility__r.Facility_Identifier__c, caseUOMId, eachUOMId, itemUOMS);

							if(quantity == caseCapacity){
								pkgUomId = caseUOMId;
							}else{
								pkgUomId = eachUOMId;
							}
						}else{
							pkgUomId = eachUOMId;
						}
				
						if ( !containersByItem.containsKey(itemId) || !containersByItem.get(itemId).containsKey(pkgUomId) ) {
							throw new ScannerServiceException('Container item not found for shipment line.');
						}
						
						// This assumes that multiple ship lines can't have same item.
						inventoryLine.put('Shipment_Line__c', shipmentLineId);
						inventoryLine.put('Packaging_UOM__c', uomMap.get(pkgUomId).Name );
						inventoryLine.put('pkgUOMId', pkgUomId);
					}
				}

				// IT iteratot
				if ( !isFullPallet && !inventory.isEmpty()) {
					for ( Object invObj : inventory){
						Map<String, Object> inventoryLine = (Map<String, Object>) invObj;
						Id itemId = (Id)inventoryLine.get('itemId');
                        Id shipmentLineId = (Id) inventoryLine.get('Shipment_Line__c');
                        Decimal quantity = (Decimal) inventoryLine.get('quantity');
                        Id pkgUomId = (Id) inventoryLine.get('pkgUOMId');
						
						List<Id> itemUOMS = itemPackagingUomCache.get(itemId);
						String palletUOMId = itemUOMS.size() > 2 ? itemUOMS[2] : null;

						Map<Id, List<Inventory_Transaction__c>> mapPickIts = shipmentIts.get(shipmentLineId);
						List<Inventory_Transaction__c> pickITs = mapPickIts.get(pkgUomId);
						Iterator<Inventory_Transaction__c> pickITIterator = pickITs.iterator();
						Inventory_Transaction__c currentPickIT = pickITIterator != null && pickITIterator.hasNext() ? pickITIterator.next() : null;

						if ( currentPickIT.Quantity_Stocking_UOM__c <= 0 ) {
                            currentPickIT = null;
                            while ( pickITIterator.hasNext () ) {
                                Inventory_Transaction__c it = pickITIterator.next ();
                                if ( it.Quantity_Stocking_UOM__c <= 0 ) continue;
                                currentPickIT = it;
                                break;
                            }
                        }

						if ( currentPickIT != null && currentPickIT.License_Plate_Number__c != null ) {
                            inventoryLine.put('toLPN', currentPickIT.License_Plate_Number__r.Name);
                            
                            if(String.isNotBlank(palletUOMId)){
                            	inventoryLine.put('Container_Item__c', containersByItem.get(itemId).get(palletUOMId).Id);
                            }else{
                            	inventoryLine.put('Container_Item__c', containersByItem.get(itemId).get(null).Id);
                            }
                        } else {
                            inventoryLine.put('Container_Item__c', containersByItem.get(itemId).get(pkgUomId).Id);
                        }

                        currentPickIT.Quantity_Stocking_UOM__c -= quantity;
					}
				}
                
				String serializedObj = JSON.serialize(params);
                system.debug (LoggingLevel.INFO, serializedObj);

				Inventory_Change__c ic;

				// mixed pallet - do undo pack
				if ( !isFullPallet ) {
					ScannerService.packShipment undoPack = new ScannerService.packShipment();
					resp = undoPack.execute(serializedObj);
					ic = (Inventory_Change__c) resp.result.resultObject;
				}

				// full pallet or mixed pallet (after undo pack) do the undo pick
				if ( isFullPallet || resp.success == true ) {
					ScannerService.pickInventory pick = new ScannerService.pickInventory();
					resp = pick.execute(serializedObj);
				}

				// break part pallets as that lpn was already broken during pack
				// (JCI requirement)
				if ( !isFullPallet && resp.success ) {
					try {
						breakPackageForPartPallet (serializedObj);
					} catch (Exception e) {
						system.debug (LoggingLevel.ERROR, e.getMessage());
						system.debug (LoggingLevel.ERROR, e.getStackTraceString());
						throw new ScannerService.ScannerServiceException('Break Package Issue: ' + e.getMessage());
					}
				}
				// reverts pack updates when the pick fails
				if ( resp.success == false )
					Database.rollback(sp);
			} catch (Exception ex){
				Database.rollback(sp);
				system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
				resp.success = false;
				resp.error.put('message', ex.getMessage());
			}
			return resp;
		}
	}

	public class packShipment implements Action.Target{
        public Action.Response execute(Object obj){

            Action.Response resp = new Action.Response();
			Set<Id> itemIds = new Set<Id>();
			Set<String> lpnNames = new Set<String>();
				
	        try{
				Set<String> attributesToCorrect = new Set<String>{ 'Packaging_UOM__c' };

	        	Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(String.valueOf(obj));
	        	system.debug(LoggingLevel.DEBUG, String.valueOf(params));
				
	        	String companyId = userDefaults.Default_Company__c;
				String facilityId = userDefaults.Default_Facility__c;
				Set<Id> packedShipLines = new Set<Id>();

				String toLPNName = params.get('toLPN') != null ? (String) params.get('toLPN') : '';
				String fromLPNName = params.get('fromLPN') != null ? (String) params.get('fromLPN') : '';
				lpnNames.addAll(new Set<String>{fromLPNName, toLPNName});
				
				String fromBinName = (String) params.get('fromBin');
				Boolean isUndo = params.containsKey('isUndo') && (Boolean) params.get('isUndo') ? true : false;
				
				List<Object> inventory = (List<Object>) params.get('inventory');

				Set<Id> shipmentLines = new Set<Id> ();
				Set<String> binNames = new Set<String>();
				for(Object inventoryLine : inventory){
					Map<String, Object> packLine = (Map<String, Object>) inventoryLine;
					itemIds.add((String)packLine.get('itemId'));
					lpnNames.add((String)packLine.get('fromLPN'));
					lpnNames.add((String)packLine.get('toLPN'));
					binNames.add((String)packLine.get('toBin'));
					if ( packLine.containsKey('Shipment_Line__c') )
						shipmentLines.add( (Id) packLine.get('Shipment_Line__c'));
				}

				Map<String, LPN__c> lpnMap = getLPNsByName(lpnNames);
				
				Bin__c bin = new Bin__c();
				LPN__c fromLPN = new LPN__c();
		        
				String locationId = '';
				
				if ( isUndo && String.isBlank(fromLPNName)) {
					throw new ScannerServiceException('LPN not found ');
				}

				binNames.add(fromBinName);
				Map<String, Bin__c> binMap = getBinsByName(binNames);

				if(!String.isBlank(fromLPNName)){
					if(lpnMap.containsKey(fromLPNName) == false){
			        	throw new ScannerServiceException('LPN not found: ' + fromLPNName);
			        }else{
		        		fromLPN = lpnMap.get(fromLPNName);
			        }
	
					locationId = fromLPN.SKIDs__r[0].Location__c;
					 	
				}else{ // bin not needed on isUndo
					if(binMap.containsKey(fromBinName) == false){
						throw new ScannerServiceException('Bin not found: ' + fromBinName);
					}else{
	 	        		bin = binMap.get(fromBinName);
	  		        }
	  		        
	  		        locationId = bin.Location__c;
				}
				
				Map<String,Set<Id>> filters = new Map<String,Set<Id>>{
		        								'Facility2__c' => new Set<Id>{ facilityId },
		        								'Location__c' => new Set<Id>{ locationId },
		        								'Item__c' => itemIds
		        							  };
				system.debug(LoggingLevel.DEBUG, filters);
				List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());

		    	Map<List<String>, SkidService3.SerialWrapper> serialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
				String skidFilter = ' AND Consigned_Owner__c = null ';
				if (isUndo ) {
					skidFilter += ' AND Mixed_Palletized__c = true ';
				}

				for (SkidService3.SerialWrapper sw : InventoryChangeService.getSkids(filters, null, skidFilter, true)) {

		            SKID__c toSkid = new SKID__c(Company__c = sw.skid.Company__c, Item__c = sw.skid.Item__c, Item__r = sw.skid.Item__r);
		            toSkid.Location__c = sw.skid.Location__c;
		            toSkid.Location__r = sw.skid.Location__r;
		            toSkid.Bin__c = sw.skid.Bin__c;
		            toSkid.Bin__r = sw.skid.Bin__r;

		            sw.skid.Input_Quantity__c = 0;

		            List<String> skidKey = SkidService3.generateKey(sw.skid, attributeList);

					if ( isUndo ) packedShipLines.add(sw.skid.Shipment_Line__c);

		    		serialWrapperMap.put(skidKey, new SkidService3.SerialWrapper(sw.skid, null, sw.serialList, toSkid));

		        }

				if ( isUndo && packedShipLines.isEmpty() ) {
					// there are no lines to unpack
					// RemoveFromShipment api does a 2 step process of unpack and unpick
					// unpack needs a success to continue unpick.
					resp.success = true;
					return resp;
				}

		    	//Assign container item.
		        Map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new Map<Item__c, Set<UOM__c>>();

		    	Map<Id, Company__c> mCompanies = InventoryChangeService.getCompanies(new Set<String>{companyId});
		        Map<Id, Location__c> mLocations = InventoryChangeService.getLocations(new Set<String>{locationId});
		        
		        Map<Id, Item__c> mItems = InventoryChangeService.getItems((Set<String>)JSON.deserialize(JSON.serialize(itemIds), Set<String>.class));

		        Set<String> packagingUOMs = new Set<String>();

		        for(Item__c item : mItems.values()){
		        	packagingUOMs.addAll((List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class));
		        }

				Map<String, UOM__c> uomsMap = getUOMs(new Set<String>(packagingUOMs));

		        Map<String, Inventory_Change__c> icMap = new Map<String, Inventory_Change__c>();
		    	Map<String, Map<List<String>, SkidService3.SerialWrapper>> positiveSerialWrapperMap = new Map<String, Map<List<String>, SkidService3.SerialWrapper>>();

				DateTime transactionDate = system.now();

				for(Object inventoryLine : inventory){
					
					Map<String, Object> packLine = (Map<String, Object>) inventoryLine;
					Item__c item = mItems.get((String)packLine.get('itemId'));

					List<String> itemUOMS = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
					
					String caseUOMId = itemUOMS.size() > 1 ? itemUOMS[1] : '';
					String palletUOMId = itemUOMS.size() > 2 ? itemUOMS[2] : '';

					if(!itemsWithPackagingUOM.containskey(item)){
						itemsWithPackagingUOM.put(item, new Set<UOM__c>());
					}
					
			    	if(String.isNotBlank(caseUOMId)){
			    		itemsWithPackagingUOM.get(item).add(uomsMap.get(caseUOMId));
			    	}
			    	
			    	if(String.isNotBlank(palletUOMId)){
			    		itemsWithPackagingUOM.get(item).add(uomsMap.get(palletUOMId));
			    	}
				}

				map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
		        if(itemsWithPackagingUOM.values().size() > 0){
			        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
		        }

				Map<List<String>, SkidService3.SerialWrapper> icSerialWrapperMap = new Map<List<String>, SkidService3.SerialWrapper>();
			    List<String> contents = new List<String>();

				for(Object inventoryLine : inventory){

					Map<String, Object> packLine = (Map<String, Object>) inventoryLine;
					Item__c item = mItems.get((String) packLine.get('itemId'));
					String caseNumber = (String) packLine.get('caseNumber');
					Decimal quantity = (Decimal) packLine.get('quantity');
					String shipmentLineId = packLine.get('Shipment_Line__c') != null ? (String) packLine.get('Shipment_Line__c') : null;
					
					if ( isUndo && packedShipLines.contains(shipmentLineId) == false) 
						continue; // skipping inventory lines which are not packed

					String pickLPNName = packLine.get('fromLPN') != null ? (String) packLine.get('fromLPN') : null;
					LPN__c pickLPN = lpnMap.get(pickLPNName) ;

					String toLPN = packLine.get('toLPN') != null ? (String) packLine.get('toLPN') : null;
					String toBin = packLine.get('toBin') != null ? (String) packLine.get('toBin') : null;
					
					List<String> itemUOMS = (List<String>) JSON.deserialize(item.Packaging_UOM__c, List<String>.class);
					
					String eachUOMId = itemUOMS.size() > 0 ? itemUOMS[0] : '';
					String caseUOMId = itemUOMS.size() > 1 ? itemUOMS[1] : '';
					String palletUOMId = itemUOMS.size() > 2 ? itemUOMS[2] : '';

					SKID__c fromSkid = new SKID__c();
			    	fromSkid.Company__c = companyId;
			    	fromSkid.Facility2__c = facilityId;
					fromSkid.Facility2__r = userDefaults.Default_Facility__r;
			    	fromSkid.Location__c = locationId;
			    	fromSkid.Item__c = item.Id;
			    	fromSkid.Shipment_Line__c = shipmentLineId;
				    
				    Decimal caseCapacity = String.isNotBlank(caseUOMId) ? KSE.getConversionFactor(item.Id,userDefaults.Default_Facility__r.Facility_Identifier__c, caseUOMId, eachUOMId, itemUOMS) : 0;
					
                    ID uomId;
					if(caseCapacity > 0 && quantity == caseCapacity){
						quantity = 1;
                        uomId = caseUOMId;
					}
					else{
						uomId = eachUOMId;
					}

                    fromSkid.Packaging_UOM__c = uomId;

			    	if(!String.isBlank(fromLPNName)){
			    		
			    		if(!String.isBlank(fromLPNName)){
			    			fromSkid.License_Plate_Number__c = fromLPN.Id;
                            fromSkid.License_Plate_Number__r = fromLPN;
			    			fromSkid.Bin__c = fromLPN.SKIDs__r[0].Bin__c;	
			    		}
			    		
				    	for(SKID__c lpnSkid : fromLPN.SKIDs__r){
				        	if(lpnSkid.Shipment_Line__c == shipmentLineId){
				        		fromSkid.Shipment_Line__r = lpnSkid.Shipment_Line__r;
				        		break;		
				        	}
				        }
					} 
					else{
			    		fromSkid.Bin__c = bin.Id;
			    		
			    		// Special case for when the part pallet carries over the LPN.
			    		if(!String.isBlank(pickLPNName)){
			    			if(lpnMap.containsKey(pickLPNName) == true){
//								LPN__c pickLPN = lpnMap.get(pickLPNName);
			    				
			    				// Only do this if the part pallet is at the same location as the toBin
			    				if(pickLPN.SKIDs__r.size() > 0 && pickLPN.SKIDs__r[0].Location__c == bin.Location__c){
			    					fromSkid.License_Plate_Number__c = pickLPN.Id;
                                    fromSkid.License_Plate_Number__r = pickLPN;
			    				}	
			    			}
			    		}
			    	}
			    	
			    	//Assign container item
			    	if(!String.isBlank(fromSkid.License_Plate_Number__c)){
			    		Item__c containerItem = String.isBlank(palletUOMId) ? containersByItem.get(item.Id).get(null) : containersByItem.get(item.Id).get(palletUOMId);

				    	if(containerItem != null){
				        	fromSkid.Container_Item__c = containerItem.Id;
				        }
			    	}
					else{
						if(fromSkid.Packaging_UOM__c == eachUOMId){
							fromSkid.Container_Item__c = item.Id;
						} 
						else{
							Item__c containerItem = containersByItem.get(item.Id).get(fromSkid.Packaging_UOM__c);

							if(containerItem != null){
								fromSkid.Container_Item__c = containerItem.Id;
							}
						}
					}
					
					List<String> skidKey = SkidService3.generateKey(fromSkid, attributeList);
                    List<String> skidKey2 = SkidService3.generateKey(fromSkid, attributeList);

					// Adding the toLPN in case unpack to a LPN
					// differentiates loose cases with part pallets serialwrappers
                    if ( isUndo ) {
                        skidKey2.add(toLPN);
                    }
                    
			    	SkidService3.SerialWrapper serialWrapper;
                    
                    if (isUndo && icSerialWrapperMap.containsKey(skidKey2) ) {
                        serialWrapper = icSerialWrapperMap.get(skidKey2);
                    }
					else 
                    if(serialWrapperMap.containsKey(skidKey)){
                        serialWrapper = serialWrapperMap.get(skidKey);
                        
                        if (isUndo ) {
			    			serialWrapper = new SkidService3.SerialWrapper(serialWrapperMap.get(skidKey));
	                    	serialWrapper.toSkid = serialWrapperMap.get(skidKey).toSkid != null ? serialWrapperMap.get(skidKey).toSkid.clone(true, true) : null;
                        }
			    	}else{
			    		system.debug(LoggingLevel.DEBUG, JSON.serialize(attributeList));
			    		system.debug(LoggingLevel.DEBUG, JSON.serialize(skidKey));
			    		system.debug(LoggingLevel.DEBUG, JSON.serialize(serialWrapperMap.keySet()));
			    		// No matching quantity found in the system
						throw new ScannerServiceException('Quantity not available ' + caseCapacity );
			    	}

			    	SKID__c skid = serialWrapper.skid;

			    	Boolean hasError = false;

			    	Inventory_Change__c inventoryChange = new Inventory_Change__c();
			    	inventoryChange.Company__c = companyId;
			    	inventoryChange.Company__r = mCompanies.get(companyId);
			    	inventoryChange.Transaction_Date__c = transactionDate;
			    	inventoryChange.Type__c = 'Transfer';
			    	
			    	String icKey = '' + inventoryChange.Company__c + inventoryChange.Transaction_Date__c;

			        if(icMap.containsKey(icKey) == false){
			    	    icMap.put(icKey, inventoryChange);
				    }else{
				    	inventoryChange = icMap.get(icKey);
				    }

			    	List<Serial__c> serialList = new List<Serial__c>();

			    	serialWrapper.toSkid.Location__r = mLocations.get(skid.Location__c);

					if(isUndo){
						if(lpnMap.containsKey(toLPN)){
							serialWrapper.toSkid.License_Plate_Number__c = lpnMap.get(toLPN).Id;
                            serialWrapper.toskid.License_Plate_Number__r = lpnMap.get(toLPN);
						}else{
							serialWrapper.toSkid.License_Plate_Number__c = null;
                            serialWrapper.toSkid.License_Plate_Number__r = null;
						}
						serialWrapper.toSkid.Temporary_LPN_Holder__c = null;
					} 
					else 
					if(lpnMap.containsKey(toLPNName)){
			    		serialWrapper.toSkid.License_Plate_Number__c = lpnMap.get(toLPNName).Id;
                        serialWrapper.toSkid.License_Plate_Number__r = lpnMap.get(toLPNName);
		    		}
		    		else{
		    			serialWrapper.toSkid.Temporary_LPN_Holder__c = toLPNName;
		    		}

					if ( isUndo && serialWrapper.toSkid.License_Plate_Number__c == null ) {
						serialWrapper.toSkid.Packaging_UOM__c = serialWrapper.skid.Packaging_UOM__c;
					} 
					else
					if(String.isNotBlank(palletUOMId)){
						serialWrapper.toSkid.Packaging_UOM__c = palletUOMId;
					}else{
						serialWrapper.toSkid.Packaging_UOM__c = eachUOMId;
					}

					if ( isUndo ) {
						serialWrapper.toSkid.Mixed_Palletized__c = false;
						
						// serialWrapper.toskid.Shipment_Line__c = shipmentLineId;
						if ( serialWrapper.toSkid.License_Plate_Number__c != null ) {
							Item__c containerItem = containersByItem.get(item.Id).get(palletUOMId);
							
							serialWrapper.toSkid.Container_Item__c = containerItem.Id;
							serialWrapper.toSkid.Container_Item__r = containerItem;
						} 
						else 
						if(serialWrapper.toSkid.Packaging_UOM__c == eachUOMId){
							serialWrapper.toSkid.Container_Item__c = item.Id;
							serialWrapper.toSkid.Container_Item__r = item;
						}
						else{
							Item__c containerItem = containersByItem.get(item.Id).get(serialWrapper.toSkid.Packaging_UOM__c);

							if(containerItem != null){
								serialWrapper.toSkid.Container_Item__c = containerItem.Id;
								serialWrapper.toSkid.Container_Item__r = containerItem;
							}
						}
					} else {
                        serialWrapper.toSkid.Mixed_Palletized__c = true;
                        serialWrapper.toSkid.Container_Item__c = item.Container_Item__c;
						serialWrapper.toSkid.Container_Item__r = item.Container_Item__r;
					}
			    
					serialWrapper.skid.Input_Quantity__c += quantity;

                    if (String.isNotBlank(caseNumber) == true) contents.add(caseNumber);

                    icSerialWrapperMap.put(skidKey2, serialWrapper);
				}

                List<InventoryChangeWrapper> icWrapperList = new List<InventoryChangeWrapper>();

		    	if(icSerialWrapperMap.size() > 0){
		    		String icKey = '' + companyId + transactionDate;
	    			InventoryChangeWrapper icWrapper = new InventoryChangeWrapper(icMap.get(icKey), icSerialWrapperMap.values());
	    			icWrapperList.add(icWrapper);
		    	}else{
	        		resp.success = false;
	        		resp.error.put('message', 'No matching inventory found');
	        		return resp;
	        	}

		        Savepoint sp = Database.setSavepoint();

		        try{
					system.debug(LoggingLevel.DEBUG, JSON.serialize(icWrapperList));

					if(icWrapperList.size() > 0){
						DML.insertAsSystem(icMap.values());

						if(String.isNotBlank(toLPNName)){
							InventoryChangeService.inventoryTransfer(icWrapperList, new List<String>(attributesToCorrect), true);
						}else{
							InventoryChangeService.inventoryTransfer(icWrapperList, new List<String>(attributesToCorrect));	
						}

                        if (contents.size() > 0) {
                            if (isUndo == true) {
                                removePalletContents(fromLPNName, contents);
                                if (String.isNotBlank(toLPNName) == true) addPalletContents(toLPNName, contents);
                            } else {
                                addPalletContents(toLPNName, contents);
                                if (String.isNotBlank(fromLPNName) == true) removePalletContents(fromLPNName, contents);
                            }
                        }

		        		resp.success = true;
		        	}
				}catch(Exception ex){
		        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
		        	Database.rollback(sp);
		        	throw ex;
		        }
	        }
	        catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	resp.success = false;
				resp.error.put('message', 'Pack Error: '+ ex.getMessage());
	        }

	        return resp;
        }
    }

    public static Map<String, Item__c> getItemsByCode(Set<String> itemCodes){
    	SchemaUtil util = SchemaUtil.getInstance();

    	Set<String> fieldStrings = new Set<String>{ 'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Company__c','Container__c',
                                    				'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c', 'Packaging_UOM__c',
                                    				'Item_Attribute__r.License_Plate_Number__c',
                                    				'Container_Package_Class__c', 'Container_Package_Class__r.Name', 'Container_Package_Class__r.Level__c',
                                    				'Container_Item__c', 'Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 
                                    				'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Name',
                                    				'Container_Item__r.Container_Package_Class__r.Level__c', 'Item_Identifier__c'};

        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));

        String whereClause = 'Item_Identifier__c IN :itemCodes';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(fieldStrings);
        soql.addAllCustomFields();
        soql.setWhereClause(whereClause);

		Map<String, Item__c> itemsMap = new Map<String, Item__c>();
		for(Item__c item : Database.query(soql.getQuery())){
			itemsMap.put(item.Item_Identifier__c, item);
		}
        return itemsMap;
    }

    public static Map<String, UOM__c> getUOMs(Set<String> uoms) {
        SOQLUtil uomQuery = new SOQLUtil('UOM__c');
        uomQuery.addFields(new Set<String>{ 'Id', 'Name', 'Package_Class__c', 'Package_Class__r.Default_Container_Item__c',
            'Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Package_Class__r.Default_Container_Item__r.Item_Attribute__c', 'Package_Class__r.Fractional_Quantities_Allowed__c',
            'Package_Class__r.Level__c' });
        uomQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        uomQuery.setWhereClause('Id IN :uoms');

        Map<String, UOM__c> uomMap = new Map<String, UOM__c>();
        for (UOM__c uom:Database.query(uomQuery.getQuery())) {uomMap.put(uom.Id, uom);uomMap.put(uom.Name, uom);}
        return uomMap;
    }

    public static Map<String, Bin__c> getBinsByName(Set<String> binNames){
    	SchemaUtil util = SchemaUtil.getInstance();
		String facilityId = userDefaults.Default_Facility__c;

    	Set<String> fieldStrings = new Set<String>{ 
    								'Id', 'Name', 'Description__c', 'Max_Capacity__c', 
					    			'Location__c', 'Location__r.Name','Location__r.Mixed_Bins_Allowed__c',
					    			'Location__r.Default_Max_Capacity__c', 'Location__r.Track_Bin_Capacity__c',
					    			'Location__r.Facility__r.Default_Mixed_Bins_Allowed__c', 
					    			'Location__r.Container_Package_Class__c', 'Location__r.Container_Package_Class__r.Level__c',
					    			'Location__r.Container_Package_Class__r.Parent_Package_Class__c',
					    			'Packaging_UOM__c', 'Packaging_UOM__r.Package_Class__c', 
					    			'Packaging_UOM__r.Package_Class__r.Level__c',
					    			'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
					    			'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
					    			'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c'
						    	   };
        					           
        String whereClause = 'Name IN :binNames AND Location__r.Facility__c = :facilityId';

        SOQLUtil soql = new SOQLUtil('Bin__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);

		Map<String, Bin__c> binsMap = new Map<String, Bin__c>();
		for(Bin__c bin : (List<Bin__c>)Database.query(soql.getQuery())){
			binsMap.put(bin.Name, bin);
		}

        return binsMap;
    }

    public static Map<String, LPN__c> getLPNsByName(Set<String> lpns){
    	SchemaUtil util = SchemaUtil.getInstance();

    	Set<String> fieldStrings = new Set<String>{ 'Id','Name', 'Contents__c' };
        String whereClause = 'Name IN :lpns';

        SOQLUtil soql = new SOQLUtil('LPN__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);
	
		SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
        skids.addAllCustomFields();
        skids.addFields(new Set<String>{'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c',
        								'Item__c', 'Item__r.Packaging_UOM__c', 'Item__r.Id', 'Item__r.Name', 'Item__r.Item_Identifier__c',
										'Item__r.Description__c', 'Item__r.Packaging_UOM__c', 'Facility2__c', 'Facility2__r.Facility_Identifier__c',
										'Bin__r.Name', 'Bin__r.Blocked__c', 'Bin__r.Last_Cycle_Count__c', 'Location__c', 'Location__r.Name', 'Location__r.Bin_Tracked__c',
										'Shipment_Line__c', 'Shipment_Line__r.Shipment__c'});
        skids.addAllCustomFields(Item__c.sObjectType,'Item__r');
        skids.setWhereClause('Type__c = \'Location\'');
        
        soql.addChildRelationship(skids);
		        
		Map<String, LPN__c> lpnsMap = new Map<String, LPN__c>();
		for(LPN__c lpn : (List<LPN__c>)Database.query(soql.getQuery())){
			lpnsMap.put(lpn.Name, lpn);
		}

        return lpnsMap;
    }
    
    public static Boolean planShipment(Id shipmentId) { return planShipment(shipmentId, null, null, null); }
	public static Boolean planShipment(Id shipmentId, Set<Id> itemIds) { return planShipment(shipmentId, itemIds, null, null); }
	public static Boolean planShipment(Id shipmentId, Set<Id> itemIds, Set<Id> binsToIgnore){ return planShipment(shipmentId, itemIds, binsToIgnore, null); }
    public static Boolean planShipment(Id shipmentId, Set<Id> itemIds, Set<Id> binsToIgnore, Set<Id> locationsToIgnore) {
        if (shipmentId == null) 
        	return false;
        
        if (itemIds == null) itemIds = new Set<Id>();
        if (binsToIgnore == null) binsToIgnore = new Set<Id>();
        if (locationsToIgnore == null) locationsToIgnore = new Set<Id>();

        SOQLUtil shlQuery = new SOQLUtil('Shipment_Line__c');
        ShipmentWorkbenchExt.addShlFields(shlQuery, 'planpick');
        
        String whereClause = '';

		if(itemIds.size() > 0){
			whereClause += 'Item__c IN :itemIds AND ';	
		}

        whereClause += 'Shipment__c = :shipmentId AND ' +
						'Item__r.Non_Inventory__c = false ' +
                        'AND (Sales_Order_Line__c = null ' +
                        'OR (Sales_Order_Line__r.Fulfillment_Source__c != \'' + SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_DROPSHIP + '\' ' +
                        'AND Sales_Order_Line__r.Status__c = \'' + SalesOrderLineService.SO_LINE_STATUS_OPEN + '\')) ' +
                        'AND (Order_Line__c = null ' +
                        'OR Order_Line__r.Status__c = \'' + OrderService.O_STATUS_OPEN + '\')';
                                                        
        shlQuery.setWhereClause(whereClause);
        shlQuery.setForUpdate();

        Map<Id, Shipment_Line__c> shipmentLines = new Map<Id, Shipment_Line__c>((List<Shipment_Line__c>)Database.query(shlQuery.getQuery()));
        if (shipmentLines.size() == 0) throw new CustomException('Shipment has no lines to plan.');

        Id companyId;
        Map<Id, Item__c> mItems = new Map<Id, Item__c>();
        List<sObject> linesForLocation = new List<sObject>();
        Set<String> lineTypes = new Set<String>();
        Map<Id, Id> itemsByLine = new Map<Id, Id>();
        Decimal qtyAllocated = 0;
        String shipmentName;
        for (Shipment_Line__c shl:shipmentLines.values()) {
            if (shl.Shipment__r.Status__c == ShipmentService.SHIPMENT_STATUS_CONFIRMED) throw new CustomException(shl.Shipment__r.Name + ' has been confirmed.');
            
            if(itemIds.size() == 0){
            	if (shl.Sales_Order_Line__r.Fulfillment_Source__c == 'Inventory' && shl.Quantity_To_Pick__c > 0) 
            		throw new CustomException(shl.Shipment__r.Name + ' has already been planned.');
	            
	            if (shl.Quantity_Picked__c > 0) throw new CustomException(shl.Shipment__r.Name + ' has been picked.');
	            if (shl.Quantity_Shipped__c > 0) throw new CustomException(shl.Shipment__r.Name + ' has been shipped.');	
            }
            
            if (shl.Sales_Order__c != null) {
                if (shl.Sales_Order__r.Hold__c == true) 
                	throw new CustomException(shl.Sales_Order__r.Name + ' is on hold.');
                
                if(itemIds.size() == 0){
                	if (shl.Sales_Order_Line__r.Fulfillment_Source__c == 'Inventory' && shl.Sales_Order__r.Ship_Complete__c == true && shl.Quantity_Planned__c != shl.Quantity_Allocated__c) 
                		throw new CustomException(shl.Shipment__r.Name + ' has not been fully allocated.');
                }
            }
			
            Decimal convFactor = shl.Sales_Order_Line__c != null ? KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, shl.Sales_Order_Line__r.Selling_UOM__c, shl.Item__r.Stocking_UOM__c, (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class)) : 1;
            shl.Quantity_Planned__c *= convFactor;
            shl.Quantity_Allocated__c *= convFactor;
            shl.Quantity_Shipped__c *= convFactor;

            companyId = shl.Company__c;
            mItems.put(shl.Item__c, shl.Item__r);
            linesForLocation.add(shl.Sales_Order_Line__c != null ? (sObject)shl.Sales_Order_Line__r : (sObject)shl.Order_Line__r);
            lineTypes.add(shl.Sales_Order_Line__c != null ? 'sales_order_line__c' : 'order_line__c');
            itemsByLine.put(shl.Sales_Order_Line__c != null ? shl.Sales_Order_Line__c : shl.Order_Line__c, shl.Item__c);
            qtyAllocated += shl.Quantity_Allocated__c;
            shipmentName = shl.Shipment__r.Name;
        }

        if (qtyAllocated == 0) throw new CustomException(shipmentName + ' has not been allocated.');

        SkidService3.setAllocAttributes(companyId, mItems);

        Set<Id> shlIds = shipmentLines.keySet();

        Set<Id> locationIds = new Set<Id>();
        Map<String, List<Location__c>> locationMap = SkidService3.locationsFromStockMovementRules(linesForLocation, 'Pick', lineTypes, null, locationIds);
        Map<Id, Set<Id>> locMap = new Map<Id, Set<Id>>();

        for (String lineId:locationMap.keySet()) 
        	locMap.put(itemsByLine.get((Id)lineId), (new Map<Id, Location__c>(locationMap.get(lineId))).keySet());
	
		if(locationsToIgnore.size() > 0){
			locationIds.removeAll(locationsToIgnore);
		}
		
		List<Item__c> items = mItems.values();
		
        whereClause = 'Item__c IN :items ' +
                      'AND Receipt_Line__c = null ' +
                      'AND ((Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\' ' +
                      'AND Shipment_Line__c IN :shlIds) ' +
                      'OR (Location__c IN :locationIds ' +
                      'AND (Bin__c = null OR (Bin__r.Blocked__c != true AND Bin__c NOT IN :binsToIgnore)) ' +
                      'AND ((Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' ' +
                      'AND Shipment_Line__c = null) ' +
                      'OR Type__c = \'' + SkidService3.SKID_TYPE_PLANNED + '\')))';

        String orderBy = 'Type__c ASC, Quantity_Stocking_UOM__c DESC, Bin__r.Picking_Order__c ASC';

        Map<List<String>, SKID__c> allocSkids = new Map<List<String>, SKID__c>();
        Map<Id, Map<Integer, Map<Integer, List<SKID__c>>>> skidMap = new Map<Id, Map<Integer, Map<Integer, List<SKID__c>>>>();
        Map<Id, Map<Integer, Map<Integer, Map<List<String>, List<SKID__c>>>>> skidsByKey = new Map<Id, Map<Integer, Map<Integer, Map<List<String>, List<SKID__c>>>>>();
        for (SKID__c skid:Database.query(SkidService3.getSkidQuery(new Map<String, String>{ 'WHERE' => whereClause, 'ORDER' => orderBy }))) {
            skid.Shipment_Line__c = null;

            Set<Id> locIds = locMap.get(skid.Item__c);
            if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                allocSkids.put(SkidService3.generateKey(skid, SkidService3.allocAttributes.get(skid.Item__c)), skid);
            } else if (skid.Type__c == SkidService3.SKID_TYPE_LOCATION && locIds.contains(skid.Location__c) == true) {
                Integer level = skid.Packaging_UOM__r.Package_Class__c != null ? skid.Packaging_UOM__r.Package_Class__r.Level__c.intValue() : 1;
                Integer containerLevel = skid.Container_Item__r.Container_Package_Class__c != null ? (Integer)skid.Container_Item__r.Container_Package_Class__r.Level__c : 1;
                List<String> planKey = SkidService3.generateKey(skid, SkidService3.planAttributes);
                if (skidMap.containsKey(skid.Item__c) == false) {
                    skidMap.put(skid.Item__c, new Map<Integer, Map<Integer, List<SKID__c>>>{ level => new Map<Integer, List<SKID__c>>{ containerLevel => new List<SKID__c>{ skid }}});
                    skidsByKey.put(skid.Item__c, new Map<Integer, Map<Integer, Map<List<String>, List<SKID__c>>>>{ level => new Map<Integer, Map<List<String>, List<SKID__c>>>{ containerLevel => new Map<List<String>, List<SKID__c>>{ planKey => new List<SKID__c>{ skid }}}});
                } else if (skidMap.get(skid.Item__c).containsKey(level) == false) {
                    skidMap.get(skid.Item__c).put(level, new Map<Integer, List<SKID__c>>{ containerLevel => new List<SKID__c>{ skid }});
                    skidsByKey.get(skid.Item__c).put(level, new Map<Integer, Map<List<String>, List<SKID__c>>>{ containerLevel => new Map<List<String>, List<SKID__c>>{ planKey => new List<SKID__c>{ skid }}});
                } else if (skidMap.get(skid.Item__c).get(level).containsKey(containerLevel) == false) {
                    skidMap.get(skid.Item__c).get(level).put(containerLevel, new List<SKID__c>{ skid });
                    skidsByKey.get(skid.Item__c).get(level).put(containerLevel, new Map<List<String>, List<SKID__c>>{ planKey => new List<SKID__c>{ skid }});
                } else {
                    skidMap.get(skid.Item__c).get(level).get(containerLevel).add(skid);
                    if (skidsByKey.get(skid.Item__c).get(level).get(containerLevel).containsKey(planKey) == false) skidsByKey.get(skid.Item__c).get(level).get(containerLevel).put(planKey, new List<SKID__c>{ skid });
                    else skidsByKey.get(skid.Item__c).get(level).get(containerLevel).get(planKey).add(skid);
                }
            } else if (skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                Integer level = skid.Packaging_UOM__r.Package_Class__c != null ? skid.Packaging_UOM__r.Package_Class__r.Level__c.intValue() : 1;
                if (skidsByKey.containsKey(skid.Item__c) == false || skidsByKey.get(skid.Item__c).containsKey(level) == false) continue;
                    
                List<String> planKey = SkidService3.generateKey(skid, SkidService3.planAttributes);
                Map<Integer, Map<List<String>, List<SKID__c>>> skidsByContainer = skidsByKey.get(skid.Item__c).get(level);
                for (Integer containerLevel = level; containerLevel <= level + 1; containerLevel++) {
                    if (skidsByContainer.containsKey(containerLevel) == false || skidsByContainer.get(containerLevel).containsKey(planKey) == false) continue;
                            
                    List<SKID__c> skids = skidsByContainer.get(containerLevel).get(planKey);
                    for (Integer i = skids.size() - 1; i >= 0; i--) {
                        SKID__c locSkid = skids[i];
                        Decimal qtyPlanned = Math.min(locSkid.Quantity__c, skid.Quantity__c);
                        Decimal qtyPlannedStocking = Math.min(locSkid.Quantity_Stocking_UOM__c, skid.Quantity_Stocking_UOM__c);
                        locSkid.Quantity__c -= qtyPlanned;
                        locSkid.Quantity_Stocking_UOM__c -= qtyPlannedStocking;
                        skid.Quantity__c -= qtyPlanned;
                        skid.Quantity_Stocking_UOM__c -= qtyPlannedStocking;

                        if (skid.Quantity__c == 0) break;
                    }

                    if (skid.Quantity__c == 0) break;
                }
            }
        }

        List<LineWrapper> shlWrappers = new List<LineWrapper>();
        List<String> shlErrors = new List<String>();
        for (Shipment_Line__c shl:shipmentLines.values()) {
            Decimal qtyToPlan = shl.Quantity_Allocated__c;
            List<String> allocAttrs = SkidService3.allocAttributes.get(shl.Item__c);
            Map<Integer, Map<Integer, List<SKID__c>>> skids = skidMap.containsKey(shl.Item__c) == true ? skidMap.get(shl.Item__c) : new Map<Integer, Map<Integer, List<SKID__c>>>();
            Map<Id, SkidService3.SerialWrapper> swMap = new Map<Id, SkidService3.SerialWrapper>();

            List<Id> pkgUoms = (List<Id>)JSON.deserialize(shl.Item__r.Packaging_UOM__c, List<Id>.Class);
            Map<Integer, Decimal> convFactors = new Map<Integer, Decimal>();
            if (pkgUoms.size() > 1) convFactors.put(2, KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, pkgUoms[1], shl.Item__r.Stocking_UOM__c, pkgUoms));
            if (pkgUoms.size() > 2) convFactors.put(3, KSE.getConversionFactor(shl.Item__c, shl.Facility__r.Facility_Identifier__c, pkgUoms[2], shl.Item__r.Stocking_UOM__c, pkgUoms));

            // Full Pallets
            if (skids.containsKey(3) && skids.get(3).containsKey(3)) {
                List<SKID__c> pallets = skids.get(3).get(3);
                Decimal convFactor = convFactors.get(3);
                Decimal caseConvFactor = convFactors.get(2);
                for (Integer i = 0; i < pallets.size(); i++) {
                    if (qtyToPlan < convFactor) break;

                    SKID__c skid = pallets[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c < convFactor) continue;

                    skid.Quantity_to_Issue__c = 1;
                    skid.Quantity_Issued__c = convFactor;
                    skid.Quantity_Required__c = caseConvFactor;
                    skid.Total_Material__c = Math.ceil(allocSkid.Quantity__c / convFactor);
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    qtyToPlan -= convFactor;
                    allocSkid.Quantity_Stocking_UOM__c -= convFactor;
                    pallets.remove(i--);
                }
            }

            // Full Part Pallets
            if (skids.containsKey(2) && skids.get(2).containsKey(3)) {
                List<SKID__c> partPallets = skids.get(2).get(3);
                Decimal convFactor = convFactors.get(2);
                for (Integer i = 0; i < partPallets.size(); i++) {
                    if (qtyToPlan < convFactor) break;

                    SKID__c skid = partPallets[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c < skid.Quantity_Stocking_UOM__c) continue;

                    skid.Quantity_to_Issue__c = skid.Quantity__c;
                    skid.Quantity_Issued__c = convFactor;
                    skid.Quantity_Required__c = 1;
                    skid.Total_Material__c = Math.ceil(allocSkid.Quantity__c / convFactor);
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    qtyToPlan -= skid.Quantity_Stocking_UOM__c;
                    allocSkid.Quantity_Stocking_UOM__c -= skid.Quantity_Stocking_UOM__c;
                    partPallets.remove(i--);
                }
            }

            // Full Cases
            if (skids.containsKey(2) && skids.get(2).containsKey(2)) {
                List<SKID__c> cases = skids.get(2).get(2);
                Decimal convFactor = convFactors.get(2);
                for (Integer i = 0; i < cases.size(); i++) {
                    if (qtyToPlan < convFactor) break;

                    SKID__c skid = cases[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c < convFactor) continue;

                    skid.Quantity_to_Issue__c = (Math.min(allocSkid.Quantity_Stocking_UOM__c, skid.Quantity_Stocking_UOM__c) / convFactor).intValue();
                    skid.Quantity_Issued__c = convFactor;
                    skid.Quantity_Required__c = 1;
                    skid.Total_Material__c = Math.ceil(allocSkid.Quantity__c / convFactor);
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    Decimal qtyPlanned = skid.Quantity_to_Issue__c * convFactor;
                    qtyToPlan -= qtyPlanned;
                    allocSkid.Quantity_Stocking_UOM__c -= qtyPlanned;
                    if (qtyPlanned == skid.Quantity_Stocking_UOM__c) cases.remove(i--);
                    else skid.Quantity_Stocking_UOM__c -= qtyPlanned;
                }
            }

            // Eaches - Single Bin
            if (skids.containsKey(1) && skids.get(1).containsKey(1)) {
                List<SKID__c> eaches = skids.get(1).get(1);
                for (Integer i = 0; i < eaches.size(); i++) {
                    if (qtyToPlan == 0) break;

                    SKID__c skid = eaches[0];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c > skid.Quantity_Stocking_UOM__c) continue;

                    skid.Quantity_to_Issue__c = allocSkid.Quantity_Stocking_UOM__c;
                    skid.Quantity_Issued__c = 1;
                    skid.Quantity_Required__c = 1;
                    skid.Total_Material__c = allocSkid.Quantity__c;
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    qtyToPlan -= skid.Quantity_to_Issue__c;
                    allocSkid.Quantity_Stocking_UOM__c = 0;
                    if (skid.Quantity_to_Issue__c == skid.Quantity_Stocking_UOM__c) eaches.remove(i--);
                    else skid.Quantity_Stocking_UOM__c -= skid.Quantity_to_Issue__c;
                }
            }

            // Eaches From Cases - Single Bin
            if (skids.containsKey(2) && skids.get(2).containsKey(2)) {
                List<SKID__c> cases = skids.get(2).get(2);
                Decimal convFactor = convFactors.get(2);
                for (Integer i = 0; i < cases.size(); i++) {
                    if (qtyToPlan == 0) break;

                    SKID__c skid = cases[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c > skid.Quantity_Stocking_UOM__c) continue;

                    skid.Quantity_To_Return__c = allocSkid.Quantity_Stocking_UOM__c;
                    skid.Quantity_Issued__c = convFactor;
                    skid.Quantity_Required__c = 1;
                    skid.Total_Material__c = Math.ceil(allocSkid.Quantity__c / convFactor);
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    qtyToPlan -= skid.Quantity_To_Return__c;
                    allocSkid.Quantity_Stocking_UOM__c = 0;
                    if (skid.Quantity_To_Return__c == skid.Quantity_Stocking_UOM__c) cases.remove(i--);
                    else skid.Quantity_Stocking_UOM__c -= skid.Quantity_To_Return__c;
                }
            }

            // Eaches - Multiple Bins
            if (skids.containsKey(1) && skids.get(1).containsKey(1)) {
                List<SKID__c> eaches = skids.get(1).get(1);
                for (Integer i = 0; i < eaches.size(); i++) {
                    if (qtyToPlan == 0) break;

                    SKID__c skid = eaches[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c == 0) continue;

                    skid.Quantity_to_Issue__c = Math.min(allocSkid.Quantity_Stocking_UOM__c, skid.Quantity_Stocking_UOM__c);
                    skid.Quantity_Issued__c = 1;
                    skid.Quantity_Required__c = 1;
                    skid.Total_Material__c = allocSkid.Quantity__c;
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    qtyToPlan -= skid.Quantity_to_Issue__c;
                    allocSkid.Quantity_Stocking_UOM__c -= skid.Quantity_to_Issue__c;
                }
            }

            // Eaches From Cases - Multiple Bins
            if (skids.containsKey(2) && skids.get(2).containsKey(2)) {
                List<SKID__c> cases = skids.get(2).get(2);
                Decimal convFactor = convFactors.get(2);
                for (Integer i = 0; i < cases.size(); i++) {
                    if (qtyToPlan == 0) break;

                    SKID__c skid = cases[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c == 0) continue;

                    skid.Quantity_To_Return__c = Math.min(allocSkid.Quantity_Stocking_UOM__c, skid.Quantity_Stocking_UOM__c);
                    skid.Quantity_Issued__c = convFactor;
                    skid.Quantity_Required__c = 1;
                    skid.Total_Material__c = Math.ceil(allocSkid.Quantity__c / convFactor);
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    qtyToPlan -= skid.Quantity_To_Return__c;
                    allocSkid.Quantity_Stocking_UOM__c -= skid.Quantity_To_Return__c;
                }
            }

            // Partial Part Pallets
            if (skids.containsKey(2) && skids.get(2).containsKey(3)) {
                List<SKID__c> partPallets = skids.get(2).get(3);
                Decimal convFactor = convFactors.get(2);
                for (Integer i = 0; i < partPallets.size(); i++) {
                    if (qtyToPlan < convFactor) break;

                    SKID__c skid = partPallets[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c < convFactor) continue;

                    skid.Quantity_to_Issue__c = (Math.min(allocSkid.Quantity_Stocking_UOM__c, skid.Quantity_Stocking_UOM__c) / convFactor).intValue();
                    skid.Quantity_Issued__c = convFactor;
                    skid.Quantity_Required__c = 1;
                    skid.Total_Material__c = Math.ceil(allocSkid.Quantity__c / convFactor);
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    Decimal qtyPlanned = skid.Quantity_to_Issue__c * convFactor;
                    qtyToPlan -= qtyPlanned;
                    allocSkid.Quantity_Stocking_UOM__c -= qtyPlanned;
                }
            }

            // Cases From Pallets
            if (skids.containsKey(3) && skids.get(3).containsKey(3)) {
                List<SKID__c> pallets = skids.get(3).get(3);
                Decimal palletConvFactor = convFactors.get(3);
                Decimal convFactor = convFactors.get(2);
                for (Integer i = 0; i < pallets.size(); i++) {
                    if (qtyToPlan < convFactor) break;

                    SKID__c skid = pallets[i];
                    SKID__c allocSkid = allocSkids.get(SkidService3.generateKey(skid, allocAttrs));
                    if (allocSkid == null || allocSkid.Quantity_Stocking_UOM__c < convFactor) continue;

                    skid.Quantity_To_Return__c = (Math.min(allocSkid.Quantity_Stocking_UOM__c, skid.Quantity_Stocking_UOM__c) / convFactor).intValue();
                    skid.Quantity_Issued__c = palletConvFactor;
                    skid.Quantity_Required__c = convFactor;
                    skid.Total_Material__c = Math.ceil(allocSkid.Quantity__c / palletConvFactor);
                    skid.Count_Quantity__c = allocSkid.Quantity__c;
                    skid.Quantity_Allocated__c = allocSkid.Quantity__c;
                    swMap.put(skid.Id, new SkidService3.SerialWrapper(skid));

                    Decimal qtyPlanned = skid.Quantity_To_Return__c * convFactor;
                    qtyToPlan -= qtyPlanned;
                    allocSkid.Quantity_Stocking_UOM__c -= qtyPlanned;
                }
            }

            if (itemIds.size() == 0 && shl.Sales_Order__c != null && shl.Sales_Order__r.Ship_Complete__c == true && qtyToPlan > 0) 
            	shlErrors.add(shl.Name);
            else 
            if (swMap.size() > 0) 
            	shlWrappers.add(new LineWrapper(shl.Shipment__r, shl, swMap.values()));
        }

        if (shlErrors.size() > 0) 
        	throw new CustomException('The following shipment lines can\'t be fully planned: ' + String.join(shlErrors, ', '));

        if (shlWrappers.size() > 0) {
        	ShipmentInventoryService.plan(shlWrappers);
        	return true;
        }
        else
        if(itemIds.size() == 0){
        	throw new CustomException('No inventory available to plan');
        }else{
        	return false;
        }
    }
}