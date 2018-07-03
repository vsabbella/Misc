public with sharing class InventoryChangeService implements ServiceRequestHandler {
    public static final String IT_TYPE = 'ITType';
    public static final String IC_TYPE = 'ICType';
    public static final String ST_TYPE = 'STType';

    public class InventoryChangeServiceException extends Exception { }

    public static List<SkidService3.SerialWrapper> getSkids(Map<String, Set<Id>> filters, String fieldSet, String addlWhere, Boolean shipMode) {
        Set<Id> facilityIds = new Set<Id>();
        if (filters.containsKey('Location__c')) {
            Set<Id> locIds = filters.get('Location__c');
            SOQLUtil locQuery = new SOQLUtil('Location__c');
            locQuery.addFields(new Set<String>{ 'Id', 'Name', 'Facility__c' });
            locQuery.setWhereClause('Id IN :locIds');

            for (Location__c loc:Database.query(locQuery.getQuery())) facilityIds.add(loc.Facility__c);
        }

        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Item__c.sObjectType, 'Item__r');
        skidQuery.addAllCustomFields(Item__c.sObjectType,'Item__r.Container_Item__r');
        skidQuery.addAllCustomFields(Bin__c.sObjectType,'Bin__r');
        skidQuery.addAllCustomFields(Package_Class__c.sObjectType, 'Packaging_UOM__r.Package_Class__r');
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Item__r.Item_Attribute__r');
        if (fieldSet != null) skidQuery.addFields(fieldSet);
        skidQuery.addFields(new Set<String>{ 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',
            'Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Item__r.Container_Item__r.Container_Package_Class__c', 'Item__r.Container_Item__r.Container_Package_Class__r.Level__c','Item__r.Container_Item__r.Container_Package_Class__r.Fractional_Quantities_Allowed__c',
            'Item__r.Container_Item__r.Item_Attribute__c', 'Item__r.Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__r.Package_Class__c', 'Item__r.Container_Item__r.Packaging_UOM__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c', 'Packaging_UOM__r.Package_Class__r.Level__c', 'Location__r.Bin_Tracked__c', 'Location__r.Track_Bin_Capacity__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container__c', 'Shipment_Line__r.Shipment__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c', 'Location__r.Facility__c', 'Item__r.Packaging_UOM__c', 'Facility2__r.Facility_Identifier__c'
        });

        String whereClause = 'Receipt_Line__c = null ' +
                             'AND (Type__c IN (\'' + SkidService3.SKID_TYPE_ALLOCATED + '\', \'' + SkidService3.SKID_TYPE_PLANNED + '\') ';
        
        if (shipMode) whereClause += 'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\')) ';
        else whereClause += 'OR (Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' AND Shipment_Line__c = null)) ';
        
        for (String filterField:filters.keySet()) {
            if (filterField == 'Location__c') whereClause += ' AND Facility2__c IN :facilityIds ';
            else whereClause += 'AND ' + filterField + ' IN (\'' + String.join(new List<Id>(filters.get(filterField)), '\',\'') + '\') ';
        }

        if (addlWhere != null) whereClause += addlWhere;
        skidQuery.setWhereClause(whereClause);

        List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
        List<SKID__c> skids = Database.query(skidQuery.getQuery());
        if (skids.size() == 0) return swList;

        Id companyId;
        Map<Id, Item__c> items = new Map<Id, Item__c>();
        Map<Id, List<Id>> pkgUoms = new Map<Id, List<Id>>();
        for (SKID__c skid:skids) {
            companyId = skid.Company__c;
            items.put(skid.Item__c, skid.Item__r);
            if (pkgUoms.containsKey(skid.Item__c) == false) pkgUoms.put(skid.Item__c, (List<Id>)JSON.deserialize(skid.Item__r.Packaging_UOM__c, List<Id>.Class));
        }

        Map<Id, List<String>> allocAttributes = AllocationService.getSkidAttributes(companyId, items);
        List<String> planAttributes = SkidService3.attributesForPutaway(null, new Set<String>{ 'license_plate_number__c' });

        List<SKID__c> locationSkids = new List<SKID__c>();
        Map<List<String>, Decimal> allQtys = new Map<List<String>, Decimal>();
        Map<List<String>, Decimal> allocQtys = new Map<List<String>, Decimal>();
        for (SKID__c skid:skids) {
            if (skid.Type__c != SkidService3.SKID_TYPE_LOCATION) {
                skid.Shipment_Line__c = null;
                skid.Material_Tracking__c = null;
            }

            List<String> allocKey = SkidService3.generateKey(skid, allocAttributes.get(skid.Item__c));
            List<String> planKey = SkidService3.generateKey(skid, planAttributes);

            if (skid.Type__c == SkidService3.SKID_TYPE_LOCATION) {
                if (!filters.containsKey('Location__c') || filters.get('Location__c').contains(skid.Location__c)) locationSkids.add(skid);

                allQtys.put(allocKey, KSE.addQuantityToField(allQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
                allQtys.put(planKey, KSE.addQuantityToField(allQtys.get(planKey), skid.Quantity_Stocking_UOM__c));
            } else if (skid.Type__c == SkidService3.SKID_TYPE_ALLOCATED) {
                allocQtys.put(allocKey, KSE.addQuantityToField(allocQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
            } else if (skid.Type__c == SkidService3.SKID_TYPE_PLANNED) {
                allocQtys.put(allocKey, KSE.addQuantityToField(allocQtys.get(allocKey), skid.Quantity_Stocking_UOM__c));
                allocQtys.put(planKey, KSE.addQuantityToField(allocQtys.get(planKey), skid.Quantity_Stocking_UOM__c));
            }
        }

        Map<Id, List<Serial__c>> serialMap = new Map<Id, List<Serial__c>>();
        if (locationSkids.size() > 0) {
            SOQLUtil serialQuery = new SOQLUtil('Serial__c');
            serialQuery.addAllCustomFields();
            serialQuery.setWhereClause('SKID__c IN :locationSkids');
            
            for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                if (!serialMap.containsKey(serial.SKID__c)) serialMap.put(serial.SKID__c, new List<Serial__c>{ serial });
                else serialMap.get(serial.SKID__c).add(serial);
            }
        }

        for (SKID__c skid:locationSkids) {
            skid.Lot_Number__c = skid.Lot__r.Name;

            List<String> allocKey = SkidService3.generateKey(skid, allocAttributes.get(skid.Item__c));
            List<String> planKey = SkidService3.generateKey(skid, planAttributes);

            skid.Quantity_Required__c = allQtys.get(allocKey);
            skid.Total_Material__c = allQtys.get(planKey);
            if (allocQtys.containsKey(allocKey) == true) skid.Quantity_Required__c -= allocQtys.get(allocKey);
            if (allocQtys.containsKey(planKey) == true) skid.Total_Material__c -= allocQtys.get(planKey);
            skid.Quantity_Available__c = skid.Quantity__c; //Math.min(skid.Quantity_Stocking_UOM__c, Math.min(skid.Quantity_Required__c, skid.Total_Material__c)) / KSE.getConversionFactor(skid.Item__c,skid.Facility2__r.Facility_Identifier__c, skid.Packaging_UOM__c, skid.Item__r.Stocking_UOM__c, pkgUoms.get(skid.Item__c));

            swList.add(new SkidService3.SerialWrapper(skid, serialMap.containsKey(skid.Id) ? serialMap.get(skid.Id) : new List<Serial__c>()));
        }

        return swList;
    }

    public static void checkAdjustmentErrors(List<InventoryChangeWrapper> wrappers, String transactionName) {
        if (wrappers == null || wrappers.size() == 0) return;

        Map<Id, Location__c> locations = new Map<Id, Location__c>();
        Map<Item__c, Set<UOM__c>> itemsWithPackagingUom = new Map<Item__c, Set<UOM__c>>();
        Map<String, LPN__c> lpnMap = new Map<String, LPN__c>();
        List<Lot__c> lots = new List<Lot__c>();
        for (InventoryChangeWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (sw.skid.Count_Quantity__c == null || (transactionName == 'Adjustment' && sw.skid.Count_Quantity__c == 0)) continue;

                if (sw.skid.Item__r.Non_Inventory__c)  throw new CustomException(sw.skid.Item__r.Name + ': ' + Label.Cannot_Transact_Non_Inventory_Item);
                if ((transactionName == 'Cycle Count' || sw.skid.Id == null) && sw.skid.Count_Quantity__c < 0) throw new CustomException((transactionName == 'Cycle Count' ? 'Count' : 'Change') + ' quantity cannot be negative');
                if (sw.skid.Id != null && transactionName == 'Adjustment' && -sw.skid.Count_Quantity__c > sw.skid.Quantity__c) throw new CustomException('You cannot reduce the quantity by more (' + -sw.skid.Count_Quantity__c + ') than the quantity-on-hand (' + sw.skid.Quantity__c + ').');

                if (sw.skid.Id == null) {
                    if (sw.skid.Location__c == null) throw new CustomException('Location ' + Label.Required_On_New_Inventory_Lines + ' Item: ' + sw.skid.Item__r.Name);
                    //need this to validate container items. all other attributes will be validated as part of check required attributes below. 
                    if (sw.skid.Packaging_UOM__c == null) throw new CustomException('Packaging UOM ' + Label.Required_On_New_Inventory_Lines + ' Item: ' + sw.skid.Item__r.Name);

                    sw.skid.Company__c = wrapper.inventoryChange.Company__c;
                    sw.skid.Type__c = SkidService3.SKID_TYPE_LOCATION;
                    sw.skid.Quantity__c = 0;

                    if (sw.skid.Packaging_UOM__c != null) {
                        if (sw.skid.Packaging_UOM__r == null) sw.skid.Packaging_UOM__r = new UOM__c(Id = sw.skid.Packaging_UOM__c);
                        if (!itemsWithPackagingUom.containsKey(sw.skid.Item__r)) itemsWithPackagingUom.put(sw.skid.Item__r, new Set<UOM__c>{ sw.skid.Packaging_UOM__r });
                        else itemsWithPackagingUom.get(sw.skid.Item__r).add(sw.skid.Packaging_UOM__r);
                    }

                    locations.put(sw.skid.Location__c,new Location__c());
                    if (sw.skid.License_Plate_Number__c == null && sw.skid.Temporary_LPN_Holder__c != null) lpnMap.put(sw.skid.Temporary_LPN_Holder__c, new LPN__c(Name = sw.skid.Temporary_LPN_Holder__c));
                    if (sw.skid.Lot_Number__c != null && sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Lot_Number__c == true) lots.add(SkidService3.populateLotNames(sw.skid, null));
                }
            }
        }
        
        if (locations.size() > 0) {
            SOQLUtil locQuery = new SOQLUtil('Location__c');
            locQuery.addAllCustomFields();
            locQuery.addField('Facility__r.Facility_Identifier__c');
            locQuery.setWhereClause('Id IN (\'' + String.join(new List<Id>(locations.keySet()),'\',\'') + '\')');
            locations = new Map<Id, Location__c>((List<Location__c>)Database.query(locQuery.getQuery()));
        }

        Map<Id, Map<Id, Item__c>> containersByItem = itemsWithPackagingUom.size() > 0 ? SkidService3.getContainerforItems(itemsWithPackagingUom) : new Map<Id, Map<Id, Item__c>>();
        
        Map<List<String>, Lot__c> createdLots = lots.size() > 0 ? SkidService3.createLots(lots) : new Map<List<String>, Lot__c>();
        lpnMap = lpnMap.size() > 0 ? SkidService3.createLPNs(lpnMap) : new Map<String, LPN__c>();

        for (InventoryChangeWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (sw.skid.Id == null && sw.skid.Count_Quantity__c != null && (transactionName == 'Cycle Count' || sw.skid.Count_Quantity__c != 0)) {
                    sw.skid.Location__r = locations.get(sw.skid.Location__c);
                    sw.skid.Facility2__c = sw.skid.Location__r.Facility__c;
                    sw.skid.Facility2__r = sw.skid.Location__r.Facility__r;

                    Item__c containerItem = containersByItem.get(sw.skid.Item__c).get(sw.skid.Packaging_UOM__c);

                    if (sw.skid.License_Plate_Number__c == null && sw.skid.Temporary_LPN_Holder__c != null && containerItem.Item_Attribute__r != null && containerItem.Item_Attribute__r.License_Plate_Number__c == true && lpnMap.containsKey(sw.skid.Temporary_LPN_Holder__c)) {
                        sw.skid.License_Plate_Number__c = lpnMap.get(sw.skid.Temporary_LPN_Holder__c).Id; 
                    }

                    if (sw.skid.Lot_Number__c != null && sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Lot_Number__c == true) {
                        sw.skid.Lot__c = createdLots.get(SkidService3.lotUniqueKey(sw.skid)).Id;
                    }

                    Integer minimumShelfLife = sw.skid.Item__r.Class__r != null && sw.skid.Item__r.Class__r.Minimum_Shelf_Life_In_Days__c != null ? Integer.valueOf(sw.skid.Item__r.Class__r.Minimum_Shelf_Life_In_Days__c) : 0;
                    SkidService3.checkRequiredAttributes(sw.skid, SkidService3.trackedAttributes(null, sw.skid.Location__r, sw.skid.Item__r, containerItem), null, minimumShelfLife, ' ' + Label.Required_On_New_Inventory_Lines + ' Item: ' + sw.skid.Item__r.Name);
                }
            }
        }
    }
    
    /**
    * @description : List of inventory change wrappers are passed in which contains an inventory change record and a list of serial wrappers.
    * for non-serial cases, the serial wrappers can contain the skid and an empty serial list.
    * this method expects the inventory change record to be already committed to the database before it gets here.
    */
    public static void inventoryAdjustment(List<InventoryChangeWrapper> icWrapperList,String transactionName) {
        
        map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
        if (icWrapperList == null || icWrapperList.size() == 0) {
            return;
        }
        
        checkAdjustmentErrors(icWrapperList,transactionName);
        List<SKID__c> skids = new List<SKID__c>();
        for (InventoryChangeWrapper wrapper:icWrapperList) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (sw.skid.Count_Quantity__c != null && (transactionName == 'Cycle Count' || sw.skid.Count_Quantity__c != 0)) {
                    skids.add(sw.skid);
                    if(sw.skid.Id == null && sw.skid.Packaging_UOM__c != null ){
                    	 if(!itemsWithPackagingUOM.containskey(sw.skid.Item__r)){
	        				itemsWithPackagingUOM.put(sw.skid.Item__r,new Set<UOM__c>());
	        			 }
                         
        			     if(sw.skid.Packaging_UOM__r == null) sw.skid.Packaging_UOM__r = new UOM__c(Id = sw.skid.Packaging_UOM__c);
	        		     itemsWithPackagingUOM.get(sw.skid.item__r).add(sw.skid.Packaging_UOM__r);
                    }
                }
            }
        }
        map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
        if(itemsWithPackagingUOM.values().size()>0)
		    containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
		    
		Map<List<String>,SKID__c> existingSkidMap = skids.size() > 0 ? SkidService3.generateExistingSkidMap(null,skids,false,null) : new Map<List<String>,SKID__c>();
        Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
        if (existingSkidMap.size() > 0) {
            SOQLUtil serialQuery = new SOQLUtil('Serial__c');
            serialQuery.addAllCustomFields();
            serialQuery.setWhereClause('SKID__c IN (\'' + String.join(new List<Id>((new Map<Id,SKID__c>(existingSkidMap.values())).keySet()),'\',\'') + '\')');
            for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                if (!serialMap.containsKey(serial.SKID__c)) {
                    serialMap.put(serial.SKID__c,new List<Serial__c>());
                }
                serialMap.get(serial.SKID__c).add(serial);
            }
        }

        Set<Id> facilityIds = new Set<Id>();
        Set<List<Id>> facilityItemKey = new Set<List<Id>>();
        Set<List<String>> skidKeys = new Set<List<String>>();
        Set<String> serialKeys = new Set<String>();
        List<SkidService3.SerialWrapper> serialWrapperList = new List<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> data = new Map<Id,SkidService3.ParameterData>();
        List<Inventory_Change__c> icList = new List<Inventory_Change__c>();
        map<Id, Item__c> itemMap = new map<Id, Item__c>();

        for (InventoryChangeWrapper icw:icWrapperList) {
            if (transactionName == 'Cycle Count'){
                facilityIds.add(icw.inventoryChange.Facility__c);
                facilityItemKey.add(new List<Id>{ icw.inventoryChange.Facility__c, icw.inventoryChange.Item__c });
            }
            
            for (SkidService3.SerialWrapper sw:icw.serialWrapperList) {
                Decimal countQuantity = sw.skid.Count_Quantity__c;
                
                if (sw.skid.Count_Quantity__c != null && (transactionName == 'Cycle Count' || sw.skid.Count_Quantity__c != 0)) {
                    
                    if(transactionName.toLowerCase() == 'cycle count'){
                        
                        itemMap.put( sw.skid.Item__c , new Item__c(Id=sw.skid.Item__c, ABC_Code__c = sw.skid.Item__r.ABC_Code__c ,Last_Cycle_Count__c = system.today() ) );
                    }
                    Item__c containerItem;
                    if(sw.skid.Container_item__r !=null){
                    	containerItem = sw.skid.Container_item__r;
                    }
                    else if(sw.skid.Id == null && sw.skid.Packaging_UOM__c !=null){
                    	containerItem = containersByItem.get(sw.skid.Item__c).get(sw.skid.Packaging_UOM__c);
                    	//package class field is not populated for new skids and it will be the same as the container class, avoiding query
                    	if(containerItem != null && sw.skid.Packaging_UOM__r != null && sw.skid.Packaging_UOM__r.Package_Class__c == null){
                    	    sw.skid.Packaging_UOM__r.Package_Class__c = containerItem.Container_Package_Class__c;
                    	    sw.skid.Packaging_UOM__r.Package_Class__r = containerItem.Container_Package_Class__r;
                    	}
                    }
                    if(containerItem !=null){
                    	sw.skid.Container_Item__c = containerItem.Id;
                    	sw.skid.Container_Item__r = containerItem;
                    }
                    else{
                    	throw new InventoryChangeServiceException('Container Item needs to defined on Item or package class.');
                    }
                    
                    List<String> key = SkidService3.generateKey(sw.skid,null);

                    if (!skidKeys.contains(key)) {
                        skidKeys.add(key);
                    } else {
                        throw new InventoryChangeServiceException(Label.Same_Attributes_On_More_than_One_Line + ' Item: ' + sw.skid.Item__r.Name + ' and Location: ' + sw.skid.Location__r.Name);
                    }

                    if (existingSkidMap.containsKey(key)) {
                        if (sw.skid.Id == null) {
                            throw new InventoryChangeServiceException(Label.Attributes_on_New_Line_Already_Exists + ' Item: ' + sw.skid.Item__r.Name + ' and Location: ' + sw.skid.Location__r.Name);
                        }
                        
                        sw.skid = existingSkidMap.get(key);
                        sw.skid.Count_Quantity__c = countQuantity;
                    } else {
                        sw.skid.Quantity__c = 0;
                    }
                    
                    if(transactionName.toLowerCase() != 'cycle count'){
                        sw.skid.Count_Quantity__c += sw.skid.Quantity__c;
                    }
                    Decimal conversionFactor = 1;
                    if(sw.conversionFactor !=null)
                    	conversionFactor = sw.conversionFactor;
                    if (icw.inventoryChange.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Serial_Number__c) {
                        if (sw.skid.Count_Quantity__c * conversionFactor != sw.serialList.size()) {
                            throw new InventoryChangeServiceException(Label.Number_Of_Serials_Not_Matching_Count_Quantity + ' Total Quantity: ' + sw.skid.Count_Quantity__c + ' Number of Serials: ' + sw.serialList.size());
                        }

                        for (Serial__c serial:sw.serialList) {
                            String uniqueKey = icw.inventoryChange.Company__c + '-' + sw.skid.Item__c + '-' + serial.Name;

                            if (!serialKeys.contains(uniqueKey)) {
                                serialKeys.add(uniqueKey);
                            } else {
                                throw new InventoryChangeServiceException(serial.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
                            }
                        }

                        List<Serial__c> serials = new List<Serial__c>();
                        List<Serial__c> existingSerials = serialMap.containsKey(sw.skid.Id) ? serialMap.get(sw.skid.Id) : new List<Serial__c>();
                        Boolean modifiedSerials = false;

                        for (Serial__c serial:existingSerials) {
                            if (!serialKeys.contains(serial.Unique_Key2__c)) {
                                serial.SKID__c = null;
                                serial.Allow_Reentry__c = true;
                                serials.add(serial);
                                modifiedSerials = true;
                            } else {
                                serialKeys.remove(serial.Unique_Key2__c);
                            }
                        }

                        for (Serial__c serial:sw.serialList) {
                            String uniqueKey = icw.inventoryChange.Company__c + '-' + sw.skid.Item__c + '-' + serial.Name;
                            if (serialKeys.contains(uniqueKey)) {
                                serials.add(serial);
                                modifiedSerials = true;
                            }
                        }

                        sw.serialList = serials;

                        if (!modifiedSerials && sw.skid.Quantity__c == sw.skid.Count_Quantity__c) {
                            sw.serialList = new List<Serial__c>();

                            if (transactionName != 'Cycle Count') {
                                continue;
                            }
                        }
                    }
                    
                    sw.skid.Quantity__c = sw.skid.Count_Quantity__c - sw.skid.Quantity__c;
                    serialWrapperList.add(sw);
                    
                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(icw.inventoryChange, transactionName, sw.skid.Quantity__c,sw.skid, sw.skid, null);
                    if(icw.inventoryChange.Transaction_Date__c != null){
                       it.Transaction_Date__c = icw.inventoryChange.Transaction_Date__c; 
                    }
                    
                    Id companyId = icw.inventoryChange.Company__c;
                    Id sourceDocId = icw.inventoryChange.Id;
                    SkidService3.ParameterData d = data.get(sourceDocId);
                    
                    if (d == null) {
                        d = new SkidService3.ParameterData();
                        d.sourceDoc = new Inventory_Change__c(Company__c = companyId);
                        data.put(sourceDocId,d);
                    }
                    d.itList.add(it);
                }
            }
        }
        
        if( serialWrapperList.size() == 0 ){
            throw new InventoryChangeServiceException(Label.No_Quantities_Entered);
        }
        
        map<String,String> configMap =  new map<String,String>{'adjustFromSkidQuantity'=>'none','putawayDirection'=>'to','serialTransactionType'=>transactionName,
            'adjustInventoryOnSameSkid'=>'true'};
        
        // merges or creates location (To) skids ( i.e putaway )
        map<List<String>, SkidService3.SerialWrapper > toSkidsMap = SkidService3.putAwayService(serialWrapperList, null, 
                                                                    new map<String,Boolean>{SkidService3.MIXED_SERIAL=>true}); 
        skidService3.inventoryTransactionsForPutAway(data, null, toSkidsMap, configMap);
        
        if(transactionName.toLowerCase() == 'cycle count'){
            //KNDY#5509 Checking the record in FacilityItem Object  and updating Last Cycle Count Date     
           
            List<Facility_Item__c> fiObjlist = new List<Facility_Item__c>();
			
			/*
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			*/
			
			SOQLUtil soql = new SOQLUtil('Facility_Item__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ABC_Code__c','Facility__c','Item__c','Last_Cycle_Count__c','Next_Cycle_Count_Date__c'
			});
			
            set<id> itemSet = itemMap.keySet();
            soql.setWhereClause('Facility__c IN:facilityIds and Item__c IN:itemSet and Active__c = true');
            for(Facility_Item__c fiObj: Database.query(soql.getQuery())){



                
                if(FacilityItemKey.contains(new list<Id>{fiObj.Facility__c,fiObj.Item__c})){
                    
                    if(fiObj.ABC_Code__c == null){
                        //Get it from Item record.
                        fiObj.ABC_Code__c = itemMap.get(fiObj.Item__c).ABC_Code__c;
                    }           
                    
                    fiObj.Last_Cycle_Count__c = system.today();
                    fiObjlist.add(fiObj);               
                }
            }
            DML.updateAsUser( itemMap.values() ); 
            DML.updateAsUser( fiObjlist ); //KNDY#5509
        }
        
        for( InventoryChangeWrapper icw : icWrapperList ){
            Inventory_Change__c ic = new Inventory_Change__c( Id = icw.inventoryChange.Id, Finalized__c = true );
            icList.add(ic);
        }
        
        DML.updateAsUser( icList ); 
    }

    public static Map<Id, UOM__c> checkTransferErrors(List<InventoryChangeWrapper> wrappers) {
        Map<Id, UOM__c> packagingUOMMap = new Map<Id, UOM__c>();

        if (wrappers == null || wrappers.size() == 0) return packagingUOMMap;

        Set<Id> packagingUOMSet = new Set<Id>();
        Map<Id, Decimal> skidQty = new Map<Id, Decimal>();
        for (InventoryChangeWrapper wrapper:wrappers) {
            for (SkidService3.SerialWrapper sw:wrapper.serialWrapperList) {
                if (sw.skid.Input_Quantity__c != null && sw.skid.Input_Quantity__c != 0) {
                    if (sw.skid.Input_Quantity__c < 0) throw new CustomException('Transfer quantity cannot be negative');
                    
                    String fromLPNName = sw.skid.License_Plate_Number__c != null? sw.skid.License_Plate_Number__r.Name : null;
                    String toLPNName = sw.toSkid.License_Plate_Number__c != null? sw.toSkid.License_Plate_Number__r.Name : sw.toSkid.Temporary_LPN_Holder__c != null ? sw.toSkid.Temporary_LPN_Holder__c : null;
                    
                    if( sw.skid.Packaging_UOM__c != null && sw.toSkid.Packaging_UOM__c != null && sw.skid.Packaging_UOM__c == sw.toSkid.Packaging_UOM__c
                    	&& sw.skid.Packaging_UOM__r.Package_Class__c != null
                        && (fromLPNName == null || (fromLPNName != null && (toLPNName == null || fromLPNName == toLPNName) ))
                        && (sw.skid.Item__r.Container__c == true || (sw.skid.Packaging_UOM__r.Package_Class__c == sw.skid.Container_Item__r.Container_Package_Class__c))){
                      //from and to pkg uom cannot be the same. but for the pallets case, user might want to just change the lpn
                      //To lpn field is not editable unless the To pkg uom is pallet, so the from and to pkg uom will be same in this case.
                      //Also for part pallets, the from and to UOM's will be Cases if we need to break the pallets into cases.
                        throw new InventoryChangeServiceException('From and To Packaging UOM cannot be the same');        
                    }
                    
                    if(sw.skid.Packaging_UOM__r == null || sw.skid.Packaging_UOM__r.Package_Class__c == null){
                        
                        packagingUOMSet.add(sw.skid.Packaging_UOM__c);
                    } 
                    
                    if(sw.toSkid.Packaging_UOM__r == null || sw.toSkid.Packaging_UOM__r.Package_Class__c == null ){
                        
                        packagingUOMSet.add(sw.toSkid.Packaging_UOM__c);
                    }
                    
                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize( sw.skid.Item__r.Packaging_UOM__c, List<Id>.class );
                    
                    Decimal conversionBetweenPackaging = 1;
                    if( sw.skid.Packaging_UOM__c != null && sw.toskid.Packaging_UOM__c != null && 
                        sw.skid.Packaging_UOM__c != sw.toskid.Packaging_UOM__c){
                        //When moving from PT to CS or CS to EA, we need to convert the available quantity as the input quantity will be in
                        //the smaller UOM 
                        conversionBetweenPackaging = KSE.getConversionFactor(sw.skid.Item__c, sw.skid.Facility2__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c,sw.toskid.Packaging_UOM__c,lstPkgUom);
                        if(conversionBetweenPackaging < 1){
                            //When moving from CS to PT or EA to CS, the input needs to be in the from UOM, the quantity available and input
                            //quantity is in this UOM, so there is no need to convert. 
                            conversionBetweenPackaging = 1;
                        }
                    }
                    
                    Id packagingUOM = sw.skid.Packaging_UOM__c;
                    if( sw.toSkid.Packaging_UOM__c != null && conversionBetweenPackaging > 1 ){
                        packagingUOM = sw.toSkid.Packaging_UOM__c;
                    }
                    
                    Decimal convFactor = KSE.getConversionFactor(sw.skid.Item__c, sw.skid.Facility2__r.Facility_Identifier__c,  packagingUOM, sw.skid.Item__r.Stocking_UOM__c, lstPkgUom);
                    Decimal qty = skidQty.containsKey(sw.skid.Id) == true ? skidQty.get(sw.skid.Id) : sw.skid.Quantity_Stocking_UOM__c;
                    Decimal qtyAvailable = Math.min(qty, (sw.toSkid != null && sw.toSkid.Quantity_Available__c != null ? (sw.toSkid.Quantity_Available__c * convFactor) : qty));

                    Decimal transferQty = sw.skid.Input_Quantity__c * convFactor;
                    if (transferQty > qtyAvailable) throw new CustomException('Transfer quantity (' + sw.skid.Input_Quantity__c + ') cannot be greater than available (' + String.valueOf(qtyAvailable / convFactor) + ')');
                        
                    skidQty.put(sw.skid.Id, sw.skid.Quantity_Stocking_UOM__c - transferQty);
                }
            }
        }
        
        if( packagingUOMSet.size() > 0 ){
            SOQLUtil uomQuery = new SOQLUtil('UOM__c');
            uomQuery.addFields(new set<String>{'Id','Name','Package_Class__c','Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c'
                ,'Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Package_Class__r.Default_Container_Item__r.Container_Package_Class__c'
            });
            uomQuery.addAllCustomFields(Package_Class__c.sObjectType,'Package_Class__r');
            uomQuery.setWhereClause('Id IN :packagingUOMSet');
            packagingUOMMap = new map<Id,UOM__c>((list<UOM__c>) Database.Query(uomQuery.getQuery()));
        }
        
        return packagingUOMMap;
    }
    
    /**
    * @description : List of inventory change wrappers are passed in which contains an inventory change record and a list of serial wrappers.
    * for non-serial cases, the serial wrappers can contain the skid and an empty serial list.
    * this method expects the inventory change record to be already committed to the database before it gets here.
    * 
    * NOTE: The to location and the to bin for the inventory transfer is passed, comma separated, in the Temporary_Value_Holder__c field of the InventoryChange object  
    */
    public static void inventoryTransfer(List<InventoryChangeWrapper> icWrapperList, List<String> attributesTocorrect) { inventoryTransfer(icWrapperList, attributesTocorrect, false); }
    public static void inventoryTransfer(List<InventoryChangeWrapper> icWrapperList, List<String> attributesTocorrect, Boolean pack) {
        if (icWrapperList == null || icWrapperList.size() == 0) {
            return;
        }
        
        map<Id,UOM__c> packagingUOMMap = checkTransferErrors(icWrapperList);
        map<String,LPN__c> lpnMap = new map<String,LPN__c>();
        map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();

        Set<Id> locationIds = new Set<Id>();
        Set<Id> binIds = new Set<Id>();
        List<Lot__c> lots = new List<Lot__c>();
        List<SKID__c> skids = new List<SKID__c>();
        for (InventoryChangeWrapper icw:icWrapperList) {
            for (SkidService3.SerialWrapper sw:icw.serialWrapperList) {
                if (sw.skid.Input_Quantity__c != null && sw.skid.Input_Quantity__c != 0) {
                    
                    if (sw.skid.Item__r.Non_Inventory__c) {
                        throw new InventoryChangeServiceException(sw.skid.Item__r.Name + ': ' + Label.Cannot_Transact_Non_Inventory_Item);
                    }

                    if (sw.toskid.Location__c != null) {
                        locationIds.add(sw.toskid.Location__c);
                    }
                    if (sw.skid.Location__c != null) {
                        locationIds.add(sw.skid.Location__c);
                    }

                    if (sw.skid.Bin__c != null) binIds.add(sw.skid.Bin__c);
                    if (sw.toskid.Bin__c != null) binIds.add(sw.toskid.Bin__c);

                    if (sw.toskid.Lot_Number__c != null
                            //&& sw.skid.Lot_Number__c != sw.toskid.Lot_Number__c
                            && sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Lot_Number__c) {
                        lots.add(SkidService3.populateLotNames(sw.toskid,null));
                    }
                    //if the lpn does not already exist, the Temporary_LPN_Holder__c will hold the lpn name that needs to be created.
                    if( sw.toskid.License_Plate_Number__c == null && sw.toskid.Temporary_LPN_Holder__c != null ){
                        lpnMap.put(sw.toskid.Temporary_LPN_Holder__c, new LPN__c(Name = sw.toskid.Temporary_LPN_Holder__c));
                    }
                    
                    if( packagingUOMMap.containsKey(sw.toSkid.Packaging_UOM__c)){
                        sw.toSkid.Packaging_UOM__r = packagingUOMMap.get(sw.toSkid.Packaging_UOM__c);
                    }
                    
                    if( packagingUOMMap.containsKey(sw.skid.Packaging_UOM__c)){
                        sw.skid.Packaging_UOM__r = packagingUOMMap.get(sw.skid.Packaging_UOM__c);
                    }

                    if( sw.skid.Packaging_UOM__c != sw.toSkid.Packaging_UOM__c  && sw.toSkid.Packaging_UOM__c != null ){
                    	
                    	if(!itemsWithPackagingUOM.containskey(sw.skid.Item__r)){
	        				itemsWithPackagingUOM.put(sw.skid.Item__r,new Set<UOM__c>());
	        	  		}
                         itemsWithPackagingUOM.get(sw.skid.Item__r).add(sw.toSkid.Packaging_UOM__r);

                    }
                    else if( ((sw.toSkid.Packaging_UOM__c == null && sw.skid.Quantity__c != sw.skid.Input_Quantity__c) || (sw.skid.Packaging_UOM__c == sw.toSkid.Packaging_UOM__c))
                        && sw.skid.Packaging_UOM__r.Package_Class__c != null
                        && sw.skid.Packaging_UOM__r.Package_Class__c != sw.skid.Container_item__r.Container_Package_Class__c){
                    //If the container class does not match the packaging uom of the skid (i.e pkg UOM is CS and container is PT container)
                    //which indicates its a part pallet, in the case of part pallets , if we transfer just some of the cases , 
                    //the transferred cases should convert back to case container and should lose the lpn, and the remainining cases should
                    //stay the same. But if all the cases of the part pallet was transferred , it should transfer as part pallet and retain
                    //the container. So we need to know the case container as we have only the pallet container on the skid, so adding it here.
                         if(!itemsWithPackagingUOM.containskey(sw.skid.Item__r)){
	        				itemsWithPackagingUOM.put(sw.skid.Item__r,new Set<UOM__c>());
	        	  		 }
	        	  		 itemsWithPackagingUOM.get(sw.skid.Item__r).add(sw.skid.Packaging_UOM__r);                                
                    }

                    skids.add(sw.skid);
                }
            }
        }

        Map<Id, Bin__c> bins = new Map<Id, Bin__c>();
        if (binIds.size() > 0) {
            SOQLUtil binQuery = new SOQLUtil('Bin__c');
            binQuery.addFields(new Set<String>{ 'Id', 'Name', 'Description__c', 'Blocked__c', 'Location__c', 'Max_Capacity__c', 'Packaging_UOM__c',
                'Packaging_UOM__r.Package_Class__c', 'Location__r.Bin_Tracked__c', 'Location__r.Default_Max_Capacity__c', 'Location__r.Facility__c',
                'Location__r.Mixed_Bins_Allowed__c', 'Location__r.Track_Bin_Capacity__c', 'Location__r.Facility__r.Default_Mixed_Bins_Allowed__c'
            });
            binQuery.setWhereClause('Id IN :binIds');
            binQuery.setForUpdate();
            bins = new Map<Id, Bin__c>((List<Bin__c>)Database.query(binQuery.getQuery()));
        }
        
        map<Id, map<Id, Item__c>> containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);

        Map<List<String>,Lot__c> createdLotMap = lots.size() > 0 ? SkidService3.createLots(lots) : new Map<List<String>,Lot__c>();
        map<String,LPN__c> createdLPNMap = lpnMap.values().size() > 0 ? SkidService3.createLPNs(lpnMap) : new map<String,LPN__c>();

        Map<List<String>,SKID__c> existingSkids = skids.size() > 0 ? SkidService3.generateExistingSkidMap(null,skids,false,null) : new Map<List<String>,SKID__c>();

        Map<Id,Location__c> locations = new Map<Id,Location__c>();
        if (locationIds.size() > 0) {
            SOQLUtil locQuery = new SOQLUtil('Location__c');
            locQuery.addAllCustomFields();
            locQuery.addField('Facility__r.Facility_Identifier__c');
            locQuery.setWhereClause('Id IN :locationIds');
            locations = new Map<Id,Location__c>((List<Location__c>)Database.query(locQuery.getQuery()));
        }
       
        list<SkidService3.SerialWrapper> serialWrapperList = new list<SkidService3.SerialWrapper>();
        list<SkidService3.SerialWrapper> inTransitWrapperList = new list<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> data = new Map<Id,SkidService3.ParameterData>();
        Map<Id,SkidService3.ParameterData> shipmentData = new Map<Id,SkidService3.ParameterData>();
        List<Inventory_Change__c> icList = new List<Inventory_Change__c>();
        map<List<String>, List<Inventory_Transaction__c>> ReceiptITs = new map<List<String>, List<Inventory_Transaction__c>>();
        set< list<String> > userEnteredByKey = new set< list<String> >();
        List<String> attributesFortransfer = new List<String>();
        Set<String> serialKeys = new Set<String>();
        
        set<id> fromSkidId = new set<id>();
        list<SkidService3.ParameterData> dataList = new list<SkidService3.ParameterData>();
        map<list<String>,list<String>> itKeyToSkidKeyMap = new map<list<String>,list<String>>();
        
        for (InventoryChangeWrapper icw:icWrapperList) {
            for (SkidService3.SerialWrapper sw:icw.serialWrapperList) {
            	fromSkidId.add(sw.skid.id) ;

                if (sw.skid.Input_Quantity__c != null && sw.skid.Input_Quantity__c != 0) {
                    if (sw.skid.Bin__c != null) sw.skid.Bin__r = bins.get(sw.skid.Bin__c);

                    Location__c toLocation;
                    Decimal transferQuantity = sw.skid.Input_Quantity__c;
                    Boolean attributeCorrection = false;
                    
                    if (sw.toskid.Location__c != null) {
                        if (locations.containsKey(sw.toskid.Location__c)) {
                            toLocation = locations.get(sw.toskid.Location__c);
                        } 
                    }
                    
                    if( toLocation == null ){
                        throw new InventoryChangeServiceException(Label.To_Location_Not_Valid);
                    }
                    
                    if(attributesTocorrect !=null){
                        for(String attr:attributesTocorrect){
                            if(sw.toskid.get(attr) != null && !attributeCorrection){
                                attributeCorrection = true;
                                continue;
                            }
                        }
                    }
                    
                    Id toBinId;
                    if( sw.toskid.Bin__c != null){
                        toBinId = (Id) sw.toskid.Bin__c;
                    }
                    
                    if( toLocation.Bin_Tracked__c == true && toBinId == null ){
                        throw new InventoryChangeServiceException(Label.To_Bin_Required);
                    }
                    
                    if( toLocation.Bin_Tracked__c == false && toBinId != null ){
                        throw new InventoryChangeServiceException(Label.To_Bin_Specified_For_Non_Bin_Tracked_Location);
                    }

                    Item__c containerItem = pack && sw.toskid.Container_Item__r != null ? sw.toskid.Container_Item__r : sw.skid.Container_item__r;
                    Decimal fromLevel =1;
                    
                    if(sw.skid.Packaging_UOM__c != null && sw.skid.Packaging_UOM__r.Package_Class__c != null ){
                        fromLevel = sw.skid.Packaging_UOM__r.Package_Class__r.Level__c;
                    }
                    
                    Decimal toLevel = fromLevel;
                    
                    if(sw.toskid.Packaging_UOM__c != null && sw.toskid.Packaging_UOM__r.Package_Class__c != null ){
                        toLevel = sw.toskid.Packaging_UOM__r.Package_Class__r.Level__c;
                    }
                    //allowing multi level transfer for skids at the shipping dock for mixed pallets
                    if( fromLevel != toLevel && Math.abs(toLevel-fromLevel) != 1  && sw.skid.Shipment_Line__c == null){ 

                        throw new InventoryChangeServiceException('Cannot transfer across multiple levels of packaging UOM' );
                    }
                    
                    if(sw.toSkid.Packaging_UOM__c != null && fromLevel != toLevel ){
                        containerItem = containersByItem.get(sw.toSkid.Item__c).get(sw.toSkid.Packaging_UOM__c);
                    }
                    
                    List<String> trackedAttributes = SkidService3.trackedAttributes(null,null,sw.skid.Item__r,containerItem);
                    
                    if(sw.toskid.Bin__c != null && sw.skid.Bin__c != sw.toskid.Bin__c){
                        trackedAttributes.add('Bin__c');
                    }
                        
                    List<String> key = SkidService3.generateKey( sw.skid, null );
                    
                    if(existingSkids.containsKey(key)){
                        
                        sw.skid = existingSkids.get(key);
                        sw.skid.Input_Quantity__c = transferQuantity;
                    }
                    else{
                        sw.skid.Quantity__c = 0;
                    }

                    if( toLocation.Bin_Tracked__c == false && sw.skid.Location__c == sw.toskid.Location__c && attributeCorrection != true){
                        throw new InventoryChangeServiceException(Label.From_and_to_locations_cannot_be_the_same);        
                    }
                    
                    if( toLocation.Bin_Tracked__c == true && sw.skid.Location__c == sw.toskid.Location__c && sw.skid.Bin__c == sw.toskid.Bin__c && attributeCorrection != true){
                        throw new InventoryChangeServiceException(Label.From_To_Location_Bin_Cannot_Be_Same);
                    }
                    
                    Decimal cf = 1;
                    if(sw.conversionFactor != null){
                        cf = sw.conversionFactor;
                    }
                    
                    if (sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Serial_Number__c && icw.inventoryChange.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT) {
                        if ((sw.skid.Input_Quantity__c*cf) != sw.serialList.size()) {
                            throw new InventoryChangeServiceException(Label.Number_Of_Serials_Not_Matching_Quantity + ' Transfer Quantity: ' + sw.skid.Input_Quantity__c + ' Number of Serials: ' + sw.serialList.size());
                        }
                    
                        for (Serial__c serial:sw.serialList) {
                            String serialKey = sw.skid.Company__c + '-' + sw.skid.Item__c + '-' + serial.Name;
                            if (!serialKeys.contains(serialKey)) {
                                serialKeys.add(serialKey);
                            } else {
                                throw new InventoryChangeServiceException(serial.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
                            }
                        }
                    }
                    
                    if(sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Lot_Number__c == true && sw.toskid.Lot_Number__c != null ){
                    
                        List<String> uniqueString = SkidService3.lotUniqueKey(sw.toskid );              
                        sw.toskid.Lot__c = createdLotMap.get( uniqueString ).id;
                    }
                    
                    if( sw.toskid.License_Plate_Number__c == null && sw.toskid.Temporary_LPN_Holder__c != null && containerItem.Item_Attribute__r != null
                        && containerItem.Item_Attribute__r.License_Plate_Number__c == true && createdLPNMap.containsKey(sw.toskid.Temporary_LPN_Holder__c)){
                        
                        sw.toskid.License_Plate_Number__c = createdLPNMap.get(sw.toskid.Temporary_LPN_Holder__c).Id; 
                    }

                    Skid__c transferSkid = sw.skid.clone(false, true);
                    transferSkid.Facility2__c = toLocation.Facility__c;
                    transferSkid.Facility2__r = toLocation.Facility__r;
                    transferSkid.Location__c = toLocation.Id;
                    transferSkid.Location__r = toLocation;
                    transferSkid.Quantity__c = sw.skid.Input_Quantity__c;

                    if(sw.toSkid.Packaging_UOM__c != null ){
                        transferSkid.Packaging_UOM__c = sw.toskid.Packaging_UOM__c;
                        transferSkid.Packaging_UOM__r = sw.toskid.Packaging_UOM__r;
                    }

                    transferSkid.Bin__c = toBinId;
                    if(toBinId != null){
                        transferSkid.Bin__r = sw.toskid.Bin__r;
                    }
                    
                    for (String attr:trackedAttributes) {
                        if (sw.toskid.get(attr) != null) {
                            if (attr == 'Lot_Number__c') {
                                transferSkid.Lot__c = sw.toskid.Lot__c;
                                transferSkid.Lot_Number__c = sw.toskid.Lot_Number__c;
                                attributesFortransfer.add('Lot__c');
                            } else if (attr == 'Bin__c') {
                                transferSkid.Bin__c = sw.toskid.Bin__c;
                                transferSkid.Bin__r = bins.get(transferSkid.Bin__c);
                                attributesFortransfer.add('Bin__c');
                            }
                            else{
                                transferSkid.put(attr,sw.toskid.get(attr));
                                
                                if( attr == 'License_Plate_Number__c'){
                                    transferSkid.License_Plate_Number__r = sw.toSkid.License_Plate_Number__r;
                                }
                                attributesFortransfer.add(attr);
                            }
                        }
                    }

                    if ( sw.skid.Packaging_UOM__c == sw.toskid.Packaging_UOM__c || sw.toskid.Packaging_UOM__c == null ) {
                        List<Id> pkgUoms = (List<Id>) JSON.deserialize(sw.skid.Item__r.Packaging_UOM__c, List<Id>.class);
                        // TODO Change this to do break package scneario when transfering from a facillity with
                        // lower uom conversion to higher uom conversion
                        if ( pkgUoms.size() > 1 && pkgUoms[pkgUoms.size()-1] == sw.skid.Packaging_UOM__c ) {
                            Id levelBelowPkgUom = SkidService3.getLevelBelowUomId(sw.skid.Packaging_UOM__c, pkgUoms);
                            Decimal fromFacilityConvFactor = KSE.getConversionFactor(sw.skid.Item__c, locations.get(sw.skid.Location__c).Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, levelBelowPkgUom, pkgUoms);
                            Decimal toFacilityConvFactor = KSE.getConversionFactor(sw.skid.Item__c, locations.get(sw.toskid.Location__c).Facility__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, levelBelowPkgUom, pkgUoms);

                            if (fromFacilityConvFactor > toFacilityConvFactor) {
                                throw new OrderLinesAddManageExt.OrderLinesAddManageException('You can\'t transfer item from facility with higher uom conversion to a facility with lower uom conversion.');
                            } else if (fromFacilityConvFactor < toFacilityConvFactor) {
                                transferSkid.Quantity__c = sw.skid.Input_Quantity__c * fromFacilityConvFactor;
                                transferSkid.Packaging_UOM__c = levelBelowPkgUom;
                                transferSkid.Packaging_UOM__r = null;
                            }
                        }
                    }
                    
                    if( transferSkid.Item__r.Container__c == false && transferSkid.License_Plate_Number__c == null && containerItem != null &&
                        containerItem.Item_Attribute__r != null && containerItem.Item_Attribute__r.License_Plate_Number__c == true){
                        throw new InventoryChangeServiceException('License Plate Number is a required attribute for Packaging: '+transferSkid.Packaging_UOM__r.Name);    
                    }
                    serialWrapperList.add( new SkidService3.SerialWrapper(transferskid, sw.serialList));
                    
                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize( sw.skid.Item__r.Packaging_UOM__c, List<Id>.class );
                    
                    //transferring from a higher packaging uom to a smaller one, input qty will be in the smaller UOM,
                    //but from skid is in the higher UOM, so need to break the needed qty.
                    //e.g. If moving from 3 Cases to 13 eaches, 13 eaches have to move to new location, but the remaining 1 case and 7 eaches,
                    // have to remain in the same location, but in the from location, there should now be two skids (in case and in each)
                    // the break package IT will move the 2 Cases to 20 eaches at the same location , the transfer IT, will then move
                    //13 eaches from the 20 eaches to the new location.
                    SKID__c negativeSkid = sw.skid.clone(true,true);
                    Inventory_Transaction__c breakPalletIT;
                    Inventory_Transaction__c it;
                    
                    if( fromLevel > toLevel ){
                        
                        transferSkid.Container_Item__c = containerItem.Id;
                        transferSkid.Container_Item__r = containerItem;
                        transferSkid.Mixed_Palletized__c = false;
                        
                        Decimal conversionFactor = KSE.getConversionFactor( sw.skid.Item__c , sw.skid.Facility2__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c , sw.toSkid.Packaging_UOM__c, lstPkgUom );
                        Decimal fromSkidQuantity = (transferSkid.Quantity__c / conversionFactor).round(System.RoundingMode.CEILING);
                        
                        Decimal brokenQuantity = fromSkidQuantity*conversionFactor;//math.mod((Integer)transferSkid.Quantity__c , (Integer)conversionFactor.round(System.RoundingMode.CEILING));
                        Decimal remainingQty = brokenQuantity - transferSkid.Quantity__c;
                        
                        SKID__c remainingQtySkid = sw.skid.clone(false,true);
                        remainingQtySkid.Packaging_UOM__c = transferSkid.Packaging_UOM__c;
                        remainingQtySkid.Packaging_UOM__r = transferSkid.Packaging_UOM__r;
                        
                        if(sw.skid.License_Plate_Number__c != null){
                            remainingQtySkid.Container_Item__c = sw.skid.Container_Item__c;
                            remainingQtySkid.Container_Item__r = sw.skid.Container_Item__r;
                            transferSkid.License_Plate_Number__c = null;
                        }
                        remainingQtySkid.Quantity__c = remainingQty;
                        
                        //the entire broken quantity is being moved.
                        
                        
                        //To DO: need to handle the serial case here.
                        if(sw.serialList != null && sw.serialList.size() > 0){
                            throw new InventoryChangeServiceException('Serials are not supported when breaking package for now');
                        }
                        serialWrapperList.add( new SkidService3.SerialWrapper(remainingQtySkid, new list<Serial__c>()));
                        breakPalletIT = SkidService3.createInventoryTransaction(icw.inventoryChange, 'Break Package', brokenQuantity, sw.skid, remainingQtySkid, null);
                        breakPalletIT.Purchase_Order_Line__c = transferskid.Purchase_Order_Line__c;
                        breakPalletIT.Consigned_Owner__c = transferskid.Consigned_Owner__c;
                        
                        it = SkidService3.createInventoryTransaction(icw.inventoryChange, 'Transfer', transferskid.Quantity__c, remainingQtySkid, transferskid, null);
                        //used to match the from skid to the IT as we do not have a from skid created for this IT yet.
                        //IT will not have some of the from attributes like the from container and from LPN, so need to form this map
                        //to recover the from skid later.
                        itKeyToSkidKeyMap.put(SkidService3.generateKey(it, null), skidService3.generateKey(remainingQtySkid,null));
                        negativeSkid.Quantity__c = -fromSkidQuantity;
                    }else{
                        negativeSkid.Quantity__c = -sw.skid.Input_Quantity__c;
                        //only when we are doing transfers in the same Case UOM, we have to worry about partial quantities of a partial pallet moving
                        
                        if( ((sw.toSkid.Packaging_UOM__c == null && sw.skid.Quantity__c != transferSkid.Quantity__c)||(sw.skid.Packaging_UOM__c == sw.toSkid.Packaging_UOM__c)) 
                            && sw.skid.Packaging_UOM__r.Package_Class__c != null
                            && sw.skid.Packaging_UOM__r.Package_Class__c != sw.skid.Container_item__r.Container_Package_Class__c && pack == false){
                                
                            Item__c fromContainerItem = containersByItem.get(sw.skid.Item__c).get(sw.skid.Packaging_UOM__c);
                            transferSkid.Container_Item__c = fromContainerItem.Id;
                            transferSkid.Container_Item__r = fromContainerItem;
                            transferSkid.License_Plate_Number__c = null;
                            transferSkid.Mixed_Palletized__c = false;
                        }
                        
                        if(fromLevel < toLevel || pack == true){
                            Decimal conversionFactor = KSE.getConversionFactor( sw.skid.Item__c , locations.get(sw.skid.Location__c).Facility__r.Facility_Identifier__c, sw.toSkid.Packaging_UOM__c, sw.skid.Packaging_UOM__c, lstPkgUom );
                            Decimal transferQty  = transferSkid.Quantity__c /conversionFactor ;
                            if(transferQty.scale() > 0 && containerItem.Item_Attribute__r.License_Plate_Number__c == false){
                                //throw error if not lpn tracked as cannot allow part quantities of a higher uom
                                throw new InventoryChangeServiceException(sw.skid.Item__r.Name+'Cannot transfer partial quantities to a larger UOM. Transfer Quantity should be a multiple of :'+conversionFactor);
                            }
                            else if(containerItem.Item_Attribute__r.License_Plate_Number__c == true){
                                //when moving from cases to pallets, if the number of cases is less than a full pallet, it will be represented
                                //as cases, but the container will be the pallet container
                                transferSkid.Packaging_UOM__c = sw.skid.Packaging_UOM__c;
                                transferSkid.Packaging_UOM__r = sw.skid.Packaging_UOM__r;
                                if(transferSkid.Shipment_Line__c != null){
                                    transferSkid.Mixed_Palletized__c = sw.toSkid.Mixed_Palletized__c;
                                }
                            }
                            else{
                                transferSkid.Quantity__c = transferQty;
                            }
                            
                            transferSkid.Container_Item__c = containerItem.Id;
                            transferSkid.Container_Item__r = containerItem;
                        }
                        it = SkidService3.createInventoryTransaction(icw.inventoryChange, 'Transfer', transferskid.Quantity__c, sw.skid, transferskid, null);
                    }

                    sw.skid.Input_Quantity__c = null;

                    it.Purchase_Order_Line__c = transferskid.Purchase_Order_Line__c;
                    it.Consigned_Owner__c = transferskid.Consigned_Owner__c;
                    
                    serialWrapperList.add( new SkidService3.SerialWrapper(negativeSkid, new list<Serial__c>()));
                    
                    
     
                    if(transferSkid.Location__r.Facility__c != sw.skid.Location__r.Facility__c ){
                        SKID__c inTransitSkid = transferSkid.clone(false,true);
                        //setting the intransit skid quantity as 0 as this is an immediate transfer from one facility to another
                        //need this skid id on the IT's for genealogy
                        inTransitSkid.Quantity__c = 0;
                        inTransitSkid.Type__c = SkidService3.SKID_TYPE_INTRANSIT;
                        List<Serial__c> inTransitSerials = new list<Serial__c>();
                        
                        for(Serial__c ser : sw.serialList){
                            inTransitSerials.add(ser.clone(true,true));
                        }
                        
                        inTransitWrapperList.add(new SkidService3.SerialWrapper(inTransitSkid, inTransitSerials));
                        it.Type__c = 'Transfer Shipment';
                        
                        Inventory_Transaction__c receiptIT = SkidService3.createInventoryTransaction(icw.inventoryChange, 'Transfer Receipt', transferskid.Quantity__c, inTransitSkid, transferskid, null);
                        receiptIT.Purchase_Order_Line__c = transferskid.Purchase_Order_Line__c;
                        receiptIT.Consigned_Owner__c = transferskid.Consigned_Owner__c;
                        List<String> rkey = SkidService3.generateKey(receiptIT, null);
                        
                        if(! ReceiptITs.containsKey(rkey)){
                            ReceiptITs.put( rkey, new list<Inventory_Transaction__c>() );
                        }
                        ReceiptITs.get(rkey).add(receiptIT);
                    }
                    
                    Id companyId = icw.inventoryChange.Company__c;
                    Id sourceDocId = icw.inventoryChange.Id;
                    
                    if( it.Type__c != 'Transfer Shipment'){
                        SkidService3.ParameterData d = data.get(sourceDocId);
                        
                        if (d == null) {
                            d = new SkidService3.ParameterData();
                            d.sourceDoc = new Inventory_Change__c(Company__c = companyId);
                            data.put(sourceDocId,d);
                        }
                        if(breakPalletIT != null){
                            d.itList.add(breakPalletIT);
                        }
                        d.itList.add(it);
                    }
                    else{
                        SkidService3.ParameterData sd = shipmentData.get(sourceDocId);
                        
                        if (sd == null) {
                            sd = new SkidService3.ParameterData();
                            sd.sourceDoc = new Inventory_Change__c(Company__c = companyId);
                            shipmentData.put(sourceDocId,sd);
                        }
                        if(breakPalletIT != null){
                            sd.itList.add(breakPalletIT);
                        }
                        sd.itList.add(it);
                    }
                    sw.toskid = null;
                }
            }
        }
        
        if( serialWrapperList.size() == 0 ){
            throw new InventoryChangeServiceException(Label.No_Quantities_Entered);
        }
        
        map<List<String>, SkidService3.SerialWrapper > inTransitSkidsMap;
        // merges or creates location (To) skids ( i.e putaway )
        if( inTransitWrapperList.size() > 0){
            inTransitSkidsMap = SkidService3.putAwayService(inTransitWrapperList,null, new map<String,Boolean>{SkidService3.CREATE_SERIAL=>false}); 
                                                                            
            for( List<String> key : receiptITs.keySet() ){
                
                for(Inventory_Transaction__c it : receiptITs.get(key)){
                    if( inTransitSkidsMap.containsKey(key) ){
                        it.From_Skid__c = inTransitSkidsMap.get(key).skid.Id;
                        it.From_Skid__r = inTransitSkidsMap.get(key).skid;
                        it.From_Location__c = it.From_Skid__r.Location__c;
                        it.From_Facility__c = it.From_Skid__r.Location__r.Facility__c;
                        it.From_Bin__c = it.From_Skid__r.Bin__c;
                    }
                    
                    if( data.containsKey(it.Inventory_Change__c) ){
                        data.get(it.Inventory_Change__c).itList.add(it);
                    }
                    else{
                        SkidService3.ParameterData d = new SkidService3.ParameterData();
                        d.sourceDoc = new Inventory_Change__c(Company__c = it.Company__c);
                        d.itList.add(it);
                        data.put(it.Inventory_Change__c,d);
                    }
                }
            }       
        }
        
        map<List<String>, SkidService3.SerialWrapper > toSkidsMap = SkidService3.putAwayService(serialWrapperList,null, 
                                                                        new map<String,Boolean>{SkidService3.CREATE_SERIAL=>false});
                                                                      
        map<Id,SKID__c> skidsMap = new map<Id,SKID__c>();
        for(SkidService3.SerialWrapper sw : toSkidsMap.values()){
            skidsMap.put(sw.skid.Id, sw.skid);
        }
        
        dataList.addAll(data.values());
        dataList.addAll(shipmentData.values());

        for(SkidService3.ParameterData p: dataList){
            for(Inventory_Transaction__c it:p.itList){
                
                if(it.From_SKID__c == null){ //this will happen only for the transfer IT's after break package
                    List<String> key = itKeyToSkidKeyMap.get(SkidService3.generateKey(it, null));
                    if(toSkidsMap.containsKey(key)){
                        it.From_SKID__c = toSkidsMap.get(key).skid.id;
                    }
                }
                else if(skidsMap.containsKey(it.From_Skid__c)){
                    //refreshing the from skid as the inventoryTransactionsForPutAway will delete the from skid if the from skid qty is 0
                    it.From_SKID__r = skidsMap.get(it.From_Skid__c);
                }
            }
        }
        
        if(inTransitSkidsMap != null && inTransitSkidsMap.keySet().size() > 0 ){
            //need the intransit skids to exist to be the from skid of the intransit IT's, so passing in deleteToSkids as false
            skidService3.inventoryTransactionsForPutAway(shipmentData, null, inTransitSkidsMap, new map<String,String>{'serialTransactionType'=>'Transfer Shipment','adjustFromSkidQuantity'=>null,'deleteToSkids'=>'false'});
        }
        
        skidService3.inventoryTransactionsForPutAway(data, null, toSkidsMap, new map<String,String>{'adjustFromSkidQuantity'=>null}); 
        for( InventoryChangeWrapper icw : icWrapperList ){
            Inventory_Change__c ic = new Inventory_Change__c( Id = icw.inventoryChange.Id, Finalized__c = true, Temporary_Value_Holder__c = null );
            icList.add(ic);
        }
        
        DML.updateAsUser( icList );
    }

    /**
    * @description : List of inventory change wrappers are passed in which contains an inventory change record and a list of serial wrappers.
    * for non-serial cases, the serial wrappers can contain the skid and an empty serial list.
    * this method expects the inventory change record to be already committed to the database before it gets here.
    * 
    * NOTE: The to location and the to bin for the inventory transfer is passed, comma separated, in the Temporary_Value_Holder__c field of the InventoryChange object  
    */
    public static void inventoryOwnerTransfer(List<InventoryChangeWrapper> icWrapperList) {
        if (icWrapperList == null || icWrapperList.size() == 0) {
            return;
        }
        
        checkTransferErrors(icWrapperList);

        List<SKID__c> skids = new List<SKID__c>();
        for (InventoryChangeWrapper icw:icWrapperList) {
            for (SkidService3.SerialWrapper sw:icw.serialWrapperList) {
                if (sw.skid.Input_Quantity__c > 0) {
                    if (sw.skid.Item__r.Non_Inventory__c) {
                        throw new InventoryChangeServiceException(Label.Cannot_Transact_Non_Inventory_Item);
                    }
                    
                    skids.add(sw.skid);
                }
            }
        }
        
        Map<List<String>, SKID__c> existingSkids = skids.size() > 0 ? SkidService3.generateExistingSkidMap(null, skids, false, null) : new Map<List<String>, SKID__c>();
        
        Set<String> serialKeys = new Set<String>();
        List<SkidService3.SerialWrapper> serialWrapperList = new List<SkidService3.SerialWrapper>();
        Map<Id, SkidService3.ParameterData> data = new Map<Id, SkidService3.ParameterData>();
        Map<List<String>, List<String>> keyMap = new Map<List<String>, List<String>>();
        for (InventoryChangeWrapper icw:icWrapperList) {
            SkidService3.ParameterData d = new SkidService3.ParameterData();
            d.sourceDoc = icw.inventoryChange;
            d.inventoryChange = icw.inventoryChange;
            d.icType = icw.inventoryChange.Type__c;
            data.put(icw.inventoryChange.Id, d);

            for (SkidService3.SerialWrapper sw:icw.serialWrapperList) {
                if (sw.skid.Input_Quantity__c > 0) {
                    List<String> key = SkidService3.generateKey(sw.skid, null);
                    if (existingSkids.containsKey(key)) {
                        SKID__c existingSkid = existingSkids.get(key);
                        existingSkid.Input_Quantity__c = sw.skid.Input_Quantity__c;
                        existingSkid.Quantity_Available__c = sw.skid.Quantity_Available__c;
                        sw.skid = existingSkid;
                    }
                    Decimal conversionFactor = 1;
                    if(sw.conversionFactor !=null)
                    	conversionFactor = sw.conversionFactor;

                    if (sw.skid.Item__r != null && sw.skid.Item__r.Item_Attribute__c != null && sw.skid.Item__r.Item_Attribute__r != null && sw.skid.Item__r.Item_Attribute__r.Serial_Number__c && icw.inventoryChange.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT) {
                        if (sw.skid.Input_Quantity__c * conversionFactor != sw.serialList.size()) {
                            throw new InventoryChangeServiceException(Label.Number_Of_Serials_Not_Matching_Quantity + ' Transfer Quantity: ' + sw.skid.Input_Quantity__c + ' Number of Serials: ' + sw.serialList.size());
                        }

                        for (Serial__c serial:sw.serialList) {
                            String uniqueKey = icw.inventoryChange.Company__c + '-' + sw.skid.Item__c + '-' + serial.Name;
                            if (serialKeys.contains(uniqueKey)) {
                                throw new InventoryChangeServiceException(serial.Name + ': ' + Label.Serial_Number_Specified_More_than_Once);
                            } else {
                                serialKeys.add(uniqueKey);
                            }
                        }
                    }
                    Skid__c negativefromSkid =  sw.skid.clone(false,true);
                    SKID__c toSkid = sw.skid.clone(false, true);
                    toSkid.Quantity__c = sw.skid.Input_Quantity__c;
                    toSkid.Purchase_Order_Line__c = null;
                    toSkid.Consigned_Owner__c = null;
                    
                    negativefromSkid.Quantity__c = KSE.subtractDecimals(0, toSkid.Quantity__c);
                   
                    serialWrapperList.add(new SkidService3.SerialWrapper(toSkid, sw.serialList));
                    serialWrapperList.add(new SkidService3.SerialWrapper (negativefromSkid, null));  

                    Inventory_Transaction__c it = SkidService3.createInventoryTransaction(icw.inventoryChange, 'Transfer Of Ownership', toSkid.Quantity__c, sw.skid, toSkid, null); 
                    it.Purchase_Order_Line__c = sw.skid.Purchase_Order_Line__c;
                    d.itList.add(it);

                    keyMap.put(SkidService3.generateKey(it, null), SkidService3.generateKey(toSkid, null));
                }
            }
        }

        if (serialWrapperList.size() == 0) {
            throw new InventoryChangeServiceException(Label.No_Quantities_Entered);
        }

        Map<List<String>, SkidService3.SerialWrapper> toSkids = SkidService3.putAwayService(serialWrapperList, null, null);

        Map<Id, List<String>> toSkidsMap = new Map<Id, List<String>>();
            for ( List<String> key : toSkids.keySet() ) {
                toSkidsMap.put(toSkids.get(key).skid.Id, key );
            }
        
        for(SkidService3.ParameterData p: data.values()){
            for(Inventory_Transaction__c it:p.itList){
               List<String> key = toSkidsMap.get(it.From_Skid__c);  
               it.From_SKID__r =  toSkids.get(key).skid;
            }
            
        }
        
        

        for (List<String> itKey:keyMap.keySet()) {
            List<String> skidKey = keyMap.get(itKey);
            if (toSkids.containsKey(skidKey)) toSkids.put(itKey, toSkids.get(skidKey));
        }

        SkidService3.inventoryTransactionsForPutAway(data, null, toSkids, new Map<String,String>{ 'serialTransactionType' => 'Transfer Of Ownership', 'consume' => 'true','adjustFromSkidQuantity' => null});
    }


    /*
     * TRANSFER SECTION
     */
    public static Map<Id,SKID__c> checkTransferErrors(List<SkidService3.SerialWrapper> swList,List<String> attributes) {
        Set<String> specifiedSerials = new Set<String>();
        Set<Id> skidIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid != null) {
                if (sw.skid.Id != null) skidIds.add(sw.skid.Id);
                if (sw.skid.Location__c != null) locationIds.add(sw.skid.Location__c);
            }
        }
        
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
        skidQuery.addFields(new Set<String>{ 'Location__r.Facility__c','Location__r.Facility__r.Company__c','Location__r.Facility__r.Company__r.Serial_Control__c','Sales_Order_Line__c','Sales_Order_Line__r.Ship_From_Facility__c' });
        skidQuery.setWhereClause('Id IN :skidIds');
        Map<Id,SKID__c> skids = new Map<Id,SKID__c>((List<SKID__c>)Database.query(skidQuery.getQuery()));
        
        SOQLUtil locationQuery = new SOQLUtil('Location__c');
        locationQuery.addAllCustomFields();
        locationQuery.addFields(new Set<String>{ 'Facility__r.Company__c','Facility__r.Company__r.Serial_Control__c' });
        locationQuery.setWhereClause('Id IN :locationIds');
        Map<Id,Location__c> locations = new Map<Id,Location__c>((List<Location__c>)Database.query(locationQuery.getQuery()));
    
        for (SkidService3.SerialWrapper sw:swList) {
            if (sw.skid == null || sw.skid.Id == null) {
                throw new InventoryChangeServiceException('From skid must already exist');
            }
            
            SKID__c fromSkid = skids.get(sw.skid.Id);
            
            SKID__c toSkid = sw.skid;
            
            if (fromSkid.Type__c != SkidService3.SKID_TYPE_LOCATION && fromSkid.Type__c != SkidService3.SKID_TYPE_INSTALLBASE) {
                throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': From skid must be a location or install base skid');
            }
            
            if (toSkid.Type__c != SkidService3.SKID_TYPE_LOCATION && toSkid.Type__c != SkidService3.SKID_TYPE_INSTALLBASE) {
                throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': To skid must be a location or install base skid');
            }
            
            if (toSkid.Type__c != SkidService3.SKID_TYPE_INSTALLBASE && toSkid.Location__c == null) {
                throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': To skid location is required');
            }

            if (toSkid.Location__c != null) {
                toSkid.Location__r = locations.get(toSkid.Location__c);
                toSkid.Facility2__c = toSkid.Location__r.Facility__c;
            }
            
            if (fromSkid.Type__c != SkidService3.SKID_TYPE_INSTALLBASE && toSkid.Type__c != SkidService3.SKID_TYPE_INSTALLBASE && fromSkid.Facility2__c != toSkid.Facility2__c) {
                throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': Cannot transfer inventory across facilities');
            }
            
            if (fromSkid.Type__c != SkidService3.SKID_TYPE_INSTALLBASE && toSkid.Type__c != SkidService3.SKID_TYPE_INSTALLBASE && fromSkid.Facility2__c != toSkid.Facility2__c) {
                throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': Cannot transfer inventory across facilities');
            }
            
            SkidService3.checkRequiredAttributes(toSkid,SkidService3.trackedAttributes(null,toSkid.Location__r,fromSkid.Item__r),null,null,' is required for item ' + fromSkid.Item__r.Name);
            
            if (toSkid.Quantity__c == null || toSkid.Quantity__c <= 0) {
                throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': To skid quantity must be greater than zero');
            }
            
            if (toSkid.Location__r.Facility__r.Company__r.Serial_Control__c == SkidService3.AT_RECEIPT && fromSkid.Item__r.Item_Attribute__c != null && fromSkid.Item__r.Item_Attribute__r.Serial_Number__c) {
                if (sw.serialList.size() != toSkid.Quantity__c) {
                    throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': ' + Label.Number_Of_Serials_Not_Matching_Quantity + ' - Transfer Quantity: ' + toSkid.Quantity__c + ' Number of Serials: ' + sw.serialList.size());
                }
                
                for (Serial__c serial:sw.serialList) {
                    String uniqueKey = toSkid.Location__r.Facility__r.Company__c + '-' + fromSkid.Item__c + '-' + serial.Name;
                    if (specifiedSerials.contains(uniqueKey)) {
                        throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': ' + serial.Name + ' - ' + Label.Serial_Number_Specified_More_than_Once);
                    } else {
                        specifiedSerials.add(uniqueKey);
                    }
                }
            }
            
            if (fromSkid.Type__c == toSkid.Type__c) {
                Boolean anyDifference = false;
                for (String attr:attributes) {
                    if (!SkidService3.attributesToExclude.contains(attr.toLowerCase()) && attr.toLowerCase() != 'item__c' && fromSkid.get(attr) != toSkid.get(attr)) {
                        anyDifference = true;
                        break;
                    }
                }
                if (!anyDifference) {
                    throw new InventoryChangeServiceException(fromSkid.Item__r.Name + ': No difference detected');
                }
            }
        }
        
        return skids;
    }

    public static void transfer(List<SkidService3.SerialWrapper> swList,List<String> attributes,Map<String,String> config) {
        String icType = config != null && config.containsKey(IC_TYPE) ? config.get(IC_TYPE) : 'Transfer';
        String itType = config != null && config.containsKey(IT_TYPE) ? config.get(IT_TYPE) : 'Transfer';
        String stType = config != null && config.containsKey(ST_TYPE) ? config.get(ST_TYPE) : 'Transfer';
        
        List<SkidService3.SerialWrapper> skidsForPutaway = new List<SkidService3.SerialWrapper>();
        Map<Id,SkidService3.ParameterData> itData = new Map<Id,SkidService3.ParameterData>();
        Map<Id,Inventory_Change__c> icMap = new Map<Id,Inventory_Change__c>();
        
        if (attributes == null) attributes = SkidService3.attributesForPutaway();
        attributes.add('Customer__c');
        attributes.add('Sales_Order_Line__c');
        attributes.add('Receipt_Line__c');

        Map<Id,SKID__c> fromSkids = checkTransferErrors(swList,attributes);
        
        for (SkidService3.SerialWrapper sw:swList) {
        	SKID__c fromSkid = fromSkids.get(sw.skid.Id);
            SKID__c toSkid = sw.skid;
            Skid__c negativefromSkid;
            toSkid.Company__c = fromSkid.Company__c;
            toSkid.Item__c = fromSkid.Item__c;
            toSkid.Item__r = fromSkid.Item__r;
            if (toSkid.Type__c == SkidService3.SKID_TYPE_INSTALLBASE) {
                toSkid.Facility2__c = null;
                toSkid.Location__c = null;
                toSkid.Bin__c = null;
            } else if (toSkid.Type__c == SkidService3.SKID_TYPE_LOCATION) {
                toSkid.Customer__c = null;
                toSkid.Sales_Order_Line__c = null;
            }
            
            negativefromSkid =  fromSkid.clone(false,true);
            negativefromSkid.Quantity__c = KSE.subtractDecimals(0, toSkid.Quantity__c);
            skidsForPutaway.add(new SkidService3.SerialWrapper(toSkid.clone(false,true),sw.serialList));
            if(negativefromSkid != null){
                skidsForPutaway.add(new SkidService3.SerialWrapper (negativefromSkid, null));   
            }

            Id facilityId;
            if (fromSkid.Location__c != null) {
                facilityId = fromSkid.Facility2__c;
            } else if (toSkid.Location__c != null) {
                facilityId = toSkid.Facility2__c;
            } else {
                facilityId = fromSkid.Sales_Order_Line__r.Ship_From_Facility__c;
            }

            if (!icMap.containsKey(facilityId)) {
                icMap.put(facilityId,new Inventory_Change__c(
                    Type__c = icType,
                    Company__c = fromSkid.Company__c,
                    Facility__c = facilityId,
                    Posting_Date__c = System.now(),
                    Transaction_Date__c = System.now()
                ));
            }
        }
        
        Map<List<String>,SkidService3.SerialWrapper> toSkids = SkidService3.putAwayService(skidsForPutaway,attributes,null);
        
        DML.insertAsUser(icMap.values());
        
        Set<Id> skidIds = fromSkids.keySet();
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addAllCustomFields();
        skidQuery.addAllCustomFields(Item__c.sObjectType,'Item__r');
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
        skidQuery.addFields(new Set<String>{ 'Location__r.Facility__c','Location__r.Facility__r.Company__c','Location__r.Facility__r.Company__r.Serial_Control__c','Sales_Order_Line__c','Sales_Order_Line__r.Ship_From_Facility__c', 'Facility2__r.Facility_Identifier__c' });
        skidQuery.setWhereClause('Id IN :skidIds');
        
        fromSkids.putAll(new Map<Id,SKID__c>((List<SKID__c>)Database.query(skidQuery.getQuery())));
        for (SkidService3.SerialWrapper sw:swList) {
            SKID__c fromSkid = fromSkids.get(sw.skid.Id);
            SKID__c toSkid = toSkids.get(SkidService3.generateKey(sw.skid,attributes)).skid;

            Id facilityId;
            if (fromSkid.Location__c != null) {
                facilityId = fromSkid.Facility2__c;
            } else if (toSkid.Location__c != null) {
                facilityId = toSkid.Facility2__c;
            } else {
                facilityId = fromSkid.Sales_Order_Line__r.Ship_From_Facility__c;
            }

            Inventory_Change__c ic = icMap.get(facilityId);
        
            if (!itData.containsKey(ic.Id)) {
                SkidService3.ParameterData itInfo = new SkidService3.ParameterData();
                itInfo.sourceDoc = new Inventory_Change__c(Company__c = fromSkid.Company__c);
                itInfo.inventoryChange = ic;
                itData.put(ic.Id,itInfo);
            }

            if (sw.itType != null) {
                stType = null;
            }

            Inventory_Transaction__c it = SkidService3.createInventoryTransaction(ic,sw.itType != null ? sw.itType : itType,sw.skid.Quantity__c,fromSkid,toSkid,attributes);
            if (sw.assetBookValue != null) it.Book_Value_of_Related_Fixed_Asset__c = sw.assetBookValue;
            itData.get(ic.Id).itList.add(it);
        }

        Map<String,String> configMap = stType != null ? new Map<String,String>{ 'serialTransactionType' => stType ,'adjustFromSkidQuantity' => null } : new Map<String,String>{ 'adjustFromSkidQuantity' => null };
        
        SkidService3.inventoryTransactionsForPutaway(itData,attributes,toSkids,configMap);
    }
    
    
    public class ICWrapperException extends Exception{}
    
    public static ExceptionService exService = new ExceptionService();

    public ServiceResponse serviceResponse = new ServiceResponse();
    
    // Not using skidservice3 variable as the field names are being lowercased.
    public static set<String> attributesToExclude {
        get {
            if (attributesToExclude == null) {
               	attributesToExclude = new set<string>{ 'Minimum_Shelf_Life_In_Days__c','Serial_Number__c','ExtId__c' };
               	
               	for( String serialField : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes')){
                    attributesToExclude.add(serialField.replace( KSE.namespaceUU, '').trim());
                }  
            }
            return attributesToExclude;
        }
        set;
    }
	    
    public class CycleCountParam extends ServiceParam {
    	
    	Inventory_Change__c inventoryChange = new Inventory_Change__c();
    	SKID__c skid = new SKID__c();
    	Serial__c serial = new Serial__c();
    	
    	public override ServiceParam inflate(Object obj){
			
			map<String, Object> params = (map<String, Object>)JSON.deserializeUntyped(String.valueOf(obj));
			
			Set<String> icFields = new Set<String>{'Company__c', 'Reason_Code__c', 'Transaction_Date__c'};
	        Set<String> skidFields = new Set<String>{'Bin__c', 'Company__c', 'Count_Quantity__c', 'Item__c', 'Location__c', 'Facility__c','Packaging_UOM__c','License_Plate_Number__c'};
	        
	        Set<String> excludedFields = new Set<String>(attributesToExclude);
        	
	        // Getting field names directly here so that the field names are not lowercased.
	        Schema.DescribeSObjectResult dsr = Item_Attribute__c.sObjectType.getDescribe();
			Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();
	        
	        for(String attributeField : fieldMap.keySet()){
	        	String fieldName = fieldMap.get(attributeField).getDescribe().getLocalName();
	        	
	        	if(attributeField.endsWith('__c') && excludedFields.contains(fieldName) == false){
	        		if(fieldName.toLowerCase() == 'facility2__c'){
	        			fieldName = 'Facility__c';
	        		}
	        		skidFields.add(fieldName);
	        	}
	        }
	        
	        this.skid = new SKID__c(Type__c = SKIDService.SKID_TYPE_LOCATION);
	        
	        List<String> inputFields = new List<String>();
	        inputFields.addAll(icFields);
	        inputFields.addAll(skidFields);
	        
	        Map<String, FieldInfo> mfieldInfo = new Map<String, FieldInfo>();
	        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Process_Request__c', inputFields);
	        
	        for(FieldInfo fInfo : fieldInfoList){
	        	mfieldInfo.put(fInfo.field, fInfo);
	        }
        	
			if(params.get('Id') != null){
				this.requestId = (String) params.get('Id');
			}
			
			if(params.get(KSE.NamespaceUU + 'Serial_Number__c') != null){
				assignFieldValue(this.serial, 'Name', 'text', params.get(KSE.NamespaceUU + 'Serial_Number__c'));
			} 
			
			for(String fieldName : icFields){
				String fieldNameNS = KSE.NamespaceUU + fieldName;
    	    	assignFieldValue(this.inventoryChange, fieldName, mfieldInfo.get(fieldName).fieldType, params.get(fieldNameNS));
        	}
        	
        	for(String fieldName : skidFields){
        		String skidField = fieldName;

                if(skidField.toLowerCase() == 'facility__c'){
                	skidField = 'Facility2__c';
               	}

        		String fieldNameNS = KSE.NamespaceUU + fieldName;
        		assignFieldValue(this.skid, skidField, mfieldInfo.get(fieldName).fieldType, params.get(fieldNameNS) == null ? params.get(fieldName) : params.get(fieldNameNS));
	        }	
			
	        return this;
		}
		
		private void assignFieldValue(SObject record, String fieldName, String fieldType, Object fieldValue){
			
			if(fieldValue != null){
				if(fieldType == 'date'){
					record.put(fieldName, Date.valueOf((String) fieldValue));
				}
				else
				if(fieldType == 'decimal'){
					record.put(fieldName, Decimal.valueOf((String) fieldValue));
				}
				else
				if(fieldType == 'datetime'){
					List<String> dateTimeStrings = String.valueOf(fieldValue).split('\\.')[0].split('T');
					Datetime transactionDate = DateTime.valueOfGMT(dateTimeStrings[0] + ' ' + dateTimeStrings[1]);
					record.put(fieldName, transactionDate);
				}
				else{
					record.put(fieldName, fieldValue);
				}
			}else{
				//throw new CycleCountParamException('Please enter a value for \'' + fieldName + '\'.');
			}
		}
    } 
    
    public ServiceResponse handleRequest(ServiceRequest serviceRequest){
		
		List<CycleCountParam> ccParams = new List<CycleCountParam>();
		
		for(String reqParams : (list<String>) serviceRequest.params){
			CycleCountParam ccParam = new CycleCountParam();
			
			try{
				ccParam.inflate(reqParams);
				ccParams.add(ccParam);
			}catch(ICWrapperException ex){
				serviceResponse.addMessage(ccParam.requestId, new Message(Message.SEVERITY_ERROR, ex.getMessage(), ''));
			}
		}
		
		if(ccParams.size() == 0){
			return serviceResponse;
		}	
		
		if(serviceRequest.actionName == 'Cycle Count'){	
			
			List<SKID__c> skidList = new List<SKID__c>();
	    	
	    	Set<String> itemIds = new Set<String>();
	    	Set<String> companyIds = new Set<String>();
	    	Set<String> locationIds = new Set<String>();
	    	Set<String> lotNumbers = new Set<String>();
	    	
	    	for(CycleCountParam ccParam : ccParams){
	        	
	        	SKID__c skid = ccParam.skid;
				skidList.add(skid);
	        	
	        	if(!String.isBlank(skid.Item__c)){
	        		itemIds.add(skid.Item__c);
	        	}
	        	
	        	if(!String.isBlank(ccParam.inventoryChange.Company__c)){
	        		companyIds.add(ccParam.inventoryChange.Company__c);
	        	}
	        	
	        	if(!String.isBlank(ccParam.skid.Location__c)){
	        		locationIds.add(ccParam.skid.Location__c);
	        	}
	        	
	        	if(!String.isBlank(ccParam.skid.Lot_Number__c)){
	        		lotNumbers.add(ccParam.skid.Lot_Number__c);
	        	}
                 
			    if(skid.Packaging_UOM__c != null) skid.Packaging_UOM__r = new UOM__c(Id = skid.Packaging_UOM__c);
	        }
	        
	        List<String> attributeList = new List<String>(SkidService3.attributesForPutaway());
	        Map<List<String>, SKID__c> existingSkidMap = SkidService3.generateExistingSkidMap(attributeList, skidList, true, '');
	        
	        Map<Id, Item__c> mItems = getItems(itemIds);
	        Map<Id, Company__c> mCompanies = getCompanies(companyIds);
	        Map<Id, Location__c> mLocations = getLocations(locationIds);
	        Map<String, Lot__c> mLots = getLots(lotNumbers);
	        
	        Map<String, Inventory_Change__c> positiveICMap = new Map<String, Inventory_Change__c>();
	    	Map<String, Map<List<String>, SkidService3.SerialWrapper>> positiveSerialWrapperMap = new Map<String, Map<List<String>, SkidService3.SerialWrapper>>();
	    	Map<String, Map<List<String>, SkidService3.SerialWrapper>> negativeSerialWrapperMap = new Map<String, Map<List<String>, SkidService3.SerialWrapper>>();
	    	
	    	Set<String> itemAttributeFields = new Set<String>(SkidService3.getAttributeFields());
	    	itemAttributeFields.removeAll(SkidService3.attributesToExclude);
	    	map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
	    	
	        for(CycleCountParam ccParam : ccParams){
	        	
	        	SKID__c skid = ccParam.skid;
	        	skid.Item__r = mItems.get(skid.Item__c);
	        	
	        	if(!itemsWithPackagingUOM.containskey(skid.Item__r)){
    				itemsWithPackagingUOM.put(skid.Item__r,new Set<UOM__c>());
    			}
	        	
	        	itemsWithPackagingUOM.get(skid.item__r).add(skid.Packaging_UOM__r);
	        	
	        	if(!String.isBlank(skid.License_Plate_Number__c)){// If palletizing
	        		try{
		        		Id nextLevelUomId = SkidService3.getNextLevelUomId(skid, skid.Item__r);
		        		itemsWithPackagingUOM.get(skid.item__r).add(new UOM__c(Id = nextLevelUomId));
		        	}catch(Exception ex){
		        		// Ignore for now. Will catch later
		        	}
	        	}
	        }
	        
	        map<Id, map<Id, Item__c>> containersByItem = new map<Id, map<Id, Item__c>>();
            if(itemsWithPackagingUOM.values().size()>0)
		        containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
	        
	        for(CycleCountParam ccParam : ccParams){
	            
	            SKID__c skid = ccParam.skid;
	        	
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
		        
	        	Set<String> trackedAttributeSet = new Set<String>(SkidService3.trackedAttributes(new List<String>(itemAttributeFields), mLocations.get(skid.Location__c), skid.Item__r, containerItem));
	        	
	        	for(String attributeField : itemAttributeFields){
	        		if(skid.get(attributeField) != null && skid.get(attributeField) != false){
	        			Boolean found = false;
		        		for(String trackedAttributeField : trackedAttributeSet){
		        			if(trackedAttributeField.toLowerCase() == attributeField){
		        				found = true;
		        				break;
		        			}	
		        		}
		        		
		        		if(!found){
		        			serviceResponse.addMessage(ccParam.requestId, new Message(Message.SEVERITY_ERROR, Label.Invalid_attribute + ' ' + attributeField, ''));
	        				hasError = true;
		        		}
	        		}
	        	}
	        	
	        	if(containerItem !=null){
                	skid.Container_Item__c = containerItem.Id;
                	skid.Container_Item__r = containerItem;
                }
                else{
                	serviceResponse.addMessage(ccParam.requestId, new Message(Message.SEVERITY_ERROR, 'Container Item needs to defined on Item or package class.', ''));
	        		hasError = true;
                }
	        	
	        	if(hasError){
	        		continue;
	        	}
	        	
	        	Inventory_Change__c inventoryChange = ccParam.inventoryChange;
	        	inventoryChange.Company__r = mCompanies.get(inventoryChange.Company__c);
	        	inventoryChange.Type__c = 'Cycle Count';
                
	        	String icKey = '' + inventoryChange.Company__c + inventoryChange.Transaction_Date__c;
		        
		        if(positiveICMap.containsKey(icKey) == false){
	        	    positiveICMap.put(icKey, inventoryChange);
			    }else{
			    	inventoryChange = positiveICMap.get(icKey);
			    }
		        
				if(mLots.containsKey(skid.Lot_Number__c)){
		    		skid.Lot__c = mLots.get(skid.Lot_Number__c).Id;
		    	}
	    	    
	        	List<String> skidKey = SkidService3.generateKey(skid, attributeList);
	        	
	        	if(existingSkidMap.containsKey(skidKey)){
	        		skid.Id = existingSkidMap.get(skidKey).Id;
	        	}
	        	
	        	List<Serial__c> serialList = new List<Serial__c>();
	        	
	        	if(!String.isBlank(ccParam.serial.Name)){
	        		serialList.add(ccParam.serial);
	        	}
	        	
	        	Decimal countQuantity = skid.Count_Quantity__c != null ? skid.Count_Quantity__c : 0;
	        	skid.Count_Quantity__c = 0; // To prevent double count when initalizing serial wrapper.
	        	
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
	        
	        List<InventoryChangeWrapper> positiveICWrappers = new List<InventoryChangeWrapper>();
	    	List<InventoryChangeWrapper> negativeICWrappers = new List<InventoryChangeWrapper>();
	    	
	    	Map<String, Inventory_Change__c> negativeICMap = new Map<String, Inventory_Change__c>();
	    	
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
	            
	            serviceResponse.isSuccess = true;
	        }catch(Exception ex){
	        	system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
	        	Database.rollback(sp);
	        	serviceResponse.isSuccess = false;
	    		serviceResponse.addErrorMessage(ex.getMessage());
	        }
    	}
    	else{
    		serviceResponse.isSuccess = false;
	    	serviceResponse.addErrorMessage('Invalid service action.');
	    }
	    
    	return serviceResponse;
    }
    
    public static Map<Id, Item__c> getItems(Set<String> itemIds){
    	SchemaUtil util = SchemaUtil.getInstance();
    	
    	Set<String> fieldStrings = new Set<String>{ 'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Company__c','Container__c',
                                    				'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c', 'Container_Item__c', 'Stocking_UOM__c',
                                                    'Container_Item__r.Stocking_UOM__c', 'Container_Item__r.Item_Attribute__r.License_Plate_Number__c', 'Packaging_UOM__c',
                                    				'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Name',
                                    				'Container_Item__r.Container_Package_Class__r.Level__c'};
        
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));
         
        String whereClause = 'Id IN :itemIds';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);	

        return new Map<Id, Item__c>((List<Item__c>)Database.query(soql.getQuery()));
    }
    
    public static Map<Id, Company__c> getCompanies(Set<String> companyIds){
    	SchemaUtil util = SchemaUtil.getInstance();
    	
    	Set<String> fieldStrings = new Set<String>{ 'Id','Name', 'Serial_Control__c' };
        String whereClause = 'Id IN :companyIds';
        
        SOQLUtil soql = new SOQLUtil('Company__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);	

        return new Map<Id, Company__c>((List<Company__c>)Database.query(soql.getQuery()));
    }
    
    public static Map<Id, Location__c> getLocations(Set<String> locationIds){
    	SchemaUtil util = SchemaUtil.getInstance();
    	
    	Set<String> fieldStrings = new Set<String>{ 'Id','Name', 'Bin_Tracked__c', 'Facility__c' };
        String whereClause = 'Id IN :locationIds';
        
        SOQLUtil soql = new SOQLUtil('Location__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);	

        return new Map<Id, Location__c>((List<Location__c>)Database.query(soql.getQuery()));
    }
    
    public static Map<String, Lot__c> getLots(Set<String> lotNumbers){
    	SchemaUtil util = SchemaUtil.getInstance();
    	
    	Set<String> fieldStrings = new Set<String>{ 'Id','Name' };
        String whereClause = 'Name IN :lotNumbers';
        
        SOQLUtil soql = new SOQLUtil('Lot__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);	
		
		Map<String, Lot__c> lotsMap = new Map<String, Lot__c>();
		for(Lot__c lot : (List<Lot__c>)Database.query(soql.getQuery())){
			lotsMap.put(lot.Name, lot);
		}
		
        return lotsMap;
    }
}