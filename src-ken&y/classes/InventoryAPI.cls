global with sharing class InventoryAPI {
    public class Transfer implements Action.Target {
        public Action.Response execute(Object obj) {
            Savepoint sp = Database.setSavepoint();
            Action.Response resp = new Action.Response();
            resp.success = true;
            try {
                List<Object> lines = (List<Object>)JSON.deserializeUntyped(String.valueOf(obj));
                if (lines.size() == 0) return resp;

                Set<Id> itemIds = new Set<Id>();
                Set<Id> locationIds = new Set<Id>();
                List<Map<String, Object>> skidWrappers = new List<Map<String, Object>>();
                for (Object line:lines) {
                    Map<String, Object> skidWrapper = (Map<String, Object>)line;
                    if (skidWrapper.containsKey('fromSkid') == false) throw new CustomException('From SKID is required.');
                    if (skidWrapper.containsKey('toSkid') == false) throw new CustomException('To SKID is required.');
                    if (skidWrapper.containsKey('reasonCode') == false) throw new CustomException('Reason Code is required.');

                    SKID__c fromSkid = (SKID__c)JSON.deserialize(JSON.serialize(skidWrapper.get('fromSkid')), SKID__c.Class);
                    SKID__c toSkid = (SKID__c)JSON.deserialize(JSON.serialize(skidWrapper.get('toSkid')), SKID__c.Class);
                    if (fromSkid.Item__c == null) throw new CustomException('Item must be populated on the from SKID');
                    if (fromSkid.Location__c == null) throw new CustomException('Location must be populated on the from SKID');
                    if (toSkid.Location__c == null) throw new CustomException('Location must be populated on the to SKID');
                    itemIds.add(fromSkid.Item__c);
                    locationIds.add(fromSkid.Location__c);

                    skidWrapper.put('fromSkid', fromSkid);
                    skidWrapper.put('toSkid', toSkid);
                    if (skidWrapper.containsKey('serials') == true) {
                        skidWrapper.put('serials', (List<Serial__c>)JSON.deserialize(JSON.serialize(skidWrapper.get('serials')), List<Serial__c>.Class));
                    }
                    skidWrappers.add(skidWrapper);
                }

                Map<Id, Item__c> items = new Map<Id, Item__c>();
                Map<Id, Location__c> locs = new Map<Id, Location__c>();
                Map<List<String>, SKID__c> skids = new Map<List<String>, SKID__c>();
                for (SkidService3.SerialWrapper sw:InventoryChangeService.getSkids(new Map<String, Set<Id>>{ 'Item__c' => itemIds, 'Location__c' => locationIds }, null, null, false)) {
                    SKID__c skid = sw.skid;
                    if (items.containsKey(skid.Item__c) == false) items.put(skid.Item__c, skid.Item__r);
                    if (locs.containsKey(skid.Location__c) == false) locs.put(skid.Location__c, skid.Location__r);
                    skids.put(SkidService3.generateKey(skid, SkidService3.attributes), skid);
                }

                List<Inventory_Change__c> ics = new List<Inventory_Change__c>();
                Map<List<Id>, InventoryChangeWrapper> icWrappers = new Map<List<Id>, InventoryChangeWrapper>();
                for (Map<String, Object> skidWrapper:skidWrappers) {
                    SKID__c fromSkid = (SKID__c)skidWrapper.get('fromSkid');
                    if (fromSkid.Packaging_UOM__c == null) fromSkid.Packaging_UOM__c = items.get(fromSkid.Item__c).Stocking_UOM__c;
                    if (fromSkid.Container_Item__c == null) fromSkid.Container_Item__c = fromSkid.Item__c;
                    if (fromSkid.Facility2__c == null) fromSkid.Facility2__c = locs.get(fromSkid.Location__c).Facility__c;

                    List<String> skidKey = SkidService3.generateKey(fromSkid, SkidService3.attributes);
                    if (skids.containsKey(skidKey) == false) throw new CustomException('Inventory not found.');
                    SkidService3.SerialWrapper sw = new SkidService3.SerialWrapper(skids.get(skidKey).clone(false, true), skidWrapper.containsKey('serials') == true ? (List<Serial__c>)skidWrapper.get('serials') : null);
                    sw.skid.Input_Quantity__c = fromSkid.Input_Quantity__c;
                    
                    SKID__c toSkid = (SKID__c)skidWrapper.get('toSkid');
                    sw.toskid = new SKID__c(
                        Location__c = toSkid.Location__c,
                        Bin__c = toSkid.Bin__c
                    );

                    Id rcId = (Id)skidWrapper.get('reasonCode');
                    List<Id> key = new List<Id>{ sw.skid.Facility2__c, sw.skid.Item__c, rcId };
                    if (icWrappers.containsKey(key) == false) {
                        Inventory_Change__c ic = new Inventory_Change__c(
                            Company__c = sw.skid.Company__c,
                            Company__r = sw.skid.Company__r,
                            Facility__c = sw.skid.Facility2__c,
                            Facility__r = sw.skid.Facility2__r,
                            Item__c = sw.skid.Item__c,
                            Item__r = sw.skid.Item__r,
                            Reason_Code__c = rcId,
                            Type__c = 'Transfer'
                        );
                        ics.add(ic);
                        icWrappers.put(key, new InventoryChangeWrapper(ic, new List<SkidService3.SerialWrapper>{ sw }));
                    } else {
                        icWrappers.get(key).serialWrapperList.add(sw);
                    }
                }

                DML.insertAsUser(ics);
                InventoryChangeService.inventoryTransfer(icWrappers.values(), null);
            } catch (Exception e) {
                Database.rollback(sp);
                resp.success = false;
                resp.error.put('message', CustomException.getMessage(e));
            }
            return resp;
        }
    }

    
    private static SchemaUtil util = SchemaUtil.getInstance();
    private static List<String> attributesForDisplay = new List<String>(SkidService2.attributesForPutaway(new List<String>(util.getAllCustomFieldsFromObject(null,'Item_Attribute__c'))));

    global static Map<String,List<SKID__c>> getAvailableInventory(Set<Id> itemIds,Set<Id> locationIds) {
        Map<Id,Item__c> itemMap = getItemMap(itemIds);
        List<SKID__c> skidList = new List<SKID__c>();
        for (Id itemId:itemIds) {
            for (Id locationId:locationIds) {
                SKID__c skidObj = new SKID__c();
                skidObj.Item__c = itemId;
                skidObj.Location__c = locationId;
                skidList.add(skidObj);
            }
        }
        return SkidService2.pullSortedSkids(skidList,null,null,' and Quantity__c > 0 ','Item',null, null);
    }
    global static Map<String,InventoryStatus> createInventoryChanges(Map<String,InventoryData> icDataList) {
        if (icDataList == null || icDataList.size() == 0)
            return null;
        icDataList = icDataList.clone();
        Map<String,InventoryStatus> result = new Map<String,InventoryStatus>();
        Set<Id> itemIds = new Set<Id>();
        Set<Id> reasonCodeIds = new Set<Id>();
        Set<Id> locationIds = new Set<Id>();
        Set<String> binNames = new Set<String>();
        for (String icDataKey:icDataList.keySet()) {
            InventoryData icData = icDataList.get(icDataKey);
            String errorMessage = '';
            if (icData.itemId == null || icData.reasonCodeId == null || icData.locationId == null || icData.quantity == null)
                errorMessage = Label.The_following_are_required_inventoryapi_change;
            else if (icData.quantity == 0)
                errorMessage = Label.Quantity_must_be_non_zero;
            if (errorMessage != '') {
                result.put(icDataKey,createErrorResult(errorMessage));
                icDataList.remove(icDataKey);
            } else {
                itemIds.add(icData.itemId);
                reasonCodeIds.add(icData.reasonCodeId);
                locationIds.add(icData.locationId);
                binNames.add(icData.bin);
            }
        }
        Map<Id,Item__c> itemMap = getItemMap(itemIds);

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Reason_Code__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Type__c'
		});
		soql.setWhereClause('Id IN :reasonCodeIds');
        Map<Id,Reason_Code__c> reasonCodeMap = new Map<Id,Reason_Code__c>((List<Reason_Code__c>)Database.query(soql.getQuery()));

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Facility__c','Bin_Tracked__c'
		});
		soql.setWhereClause('Id IN :locationIds');        
        Map<Id,Location__c> locationMap = new Map<Id,Location__c>((List<Location__c>)Database.query(soql.getQuery()));
        
        Map<String,Bin__c> bins = getBins(locationIds,binNames);
        List<SKID__c> skidList = new List<SKID__c>();
        for (String icDataKey:icDataList.keySet()) {
            InventoryData icData = icDataList.get(icDataKey);
            String errorMessage = '';
            if (!itemMap.containsKey(icData.itemId))
                errorMessage = Label.Invalid_Item;
            else if (!reasonCodeMap.containsKey(icData.reasonCodeId))
                errorMessage = Label.Invalid_reason_code;
            else if (icData.locationId.getSObjectType() != Schema.Location__c.SObjectType)
                errorMessage = Label.Invalid_location;
            if (errorMessage != '') {
                result.put(icDataKey,createErrorResult(errorMessage));
                icDataList.remove(icDataKey);
            } else {
                SKID__c skidObj = new SKID__c();
                skidObj.Item__c = icData.itemId;
                skidObj.Location__c = icData.locationId;
                skidList.add(skidObj);
            }
        }

        //get inventory and sort by attributes
        Map<String,List<SKID__c>> itemLocationSkidList = SkidService2.pullSortedSkids(skidList,null,null,' and Consigned_Owner__c = null ','Item',null, null);
        List<String> attributes = getAttributesForSorting();
        Map<String,List<SKID__c>> sortedSkidList = sortSkidsByAttributes(itemLocationSkidList,attributes);

        //Set input quantity on SKIDs
        Map<String,Inventory_Change__c> icList = new Map<String,Inventory_Change__c>();
        Map<String,List<SKID__c>> updatedSkids = new Map<String,List<SKID__c>>();
        Map<String,SKID__c> toSkids = new Map<String,SKID__c>();
        Map<String,Lot__c> lotMap = new Map<String,Lot__c>();
        Set<String> lotNames = new Set<String>();
        List<SKID__c> newQuantitySkids = new List<SKID__c>();
        for (String icDataKey:icDataList.keySet()) {
            String errorMessage = '';
            InventoryData icData = icDataList.get(icDataKey);
            Inventory_Change__c icObj = new Inventory_Change__c();
            icObj.Company__c = itemMap.get(icData.itemId).Company__c; //#JUSTDOIT Not changing these as there is no other means of getting company id
            icObj.Company__r = itemMap.get(icData.itemId).Company__r;
            icObj.Type__c = 'Adjustment';
            icObj.Item__c = icData.itemId;
            icObj.Reason_Code__c = icData.reasonCodeId;
            if (reasonCodeMap.get(icData.reasonCodeId).Type__c != 'Inventory Change') {
                result.put(icDataKey,createErrorResult(Label.Enter_a_reason_code_of_type_Inventory_Change));
                icDataList.remove(icDataKey);
                continue;
            }
            SKID__c tempSKID = new SKID__c(Item__c = icData.itemId,Location__c = icData.locationId,Item__r = itemMap.get(icData.itemId), Quantity__c = 0,Input_Quantity__c = icData.quantity,Type__c = 'Location');
			tempSkid.Company__c = itemMap.get(icData.itemId).Company__c; //#JUSTDOIT Not changing these as there is no other means of getting company id
            
            if (tempSkid.Item__r.Item_Attribute__r.Lot_Number__c) {
                if (icData.lot == null || icData.lot == '') {
                    result.put(icDataKey,createErrorResult(Label.Missing_a_lot_number));
                    icDataList.remove(icDataKey);
                    continue;
                }
                tempSkid.Lot_Number__c = icData.lot;
            }
            if (tempSkid.Item__r.Item_Attribute__r.Expiration_Date__c) {
                if (icData.expirationDate == null) {
                    result.put(icDataKey,createErrorResult(Label.Missing_an_expiration_date));
                    icDataList.remove(icDataKey);
                    continue;
                }
                tempSkid.Expiration_Date__c = icData.expirationDate;
            } 
            if (tempSkid.Item__r.Item_Attribute__r.Date_Received__c) {
                if (icData.dateReceived == null) {
                    result.put(icDataKey,createErrorResult(Label.Missing_a_date_received));
                    icDataList.remove(icDataKey);
                    continue;
                }
                tempSkid.Date_Received__c = icData.dateReceived;
            }
            if (locationMap.get(icData.locationId).Bin_Tracked__c) {
                if (icData.bin == null || icData.bin == '' || !bins.containsKey(icData.bin + icData.locationId)) {
                    result.put(icDataKey,createErrorResult(Label.Invalid_or_missing_bin));
                    icDataList.remove(icDataKey);
                    continue;
                }
                tempSkid.Bin__c = bins.get(icData.bin + icData.locationId).Id;
            }
            for (String attributeField:icData.attributes.keySet()) 
                if ((Boolean)tempSkid.Item__r.Item_Attribute__r.get(attributeField))
                    tempSkid.put(attributeField,icData.attributes.get(attributeField));
            String key = SkidService2.generateKeyforSkid(tempSkid,attributes,null,null);
            List<SKID__c> quantitySkids = new List<SKID__c>();
            if (!sortedSkidList.containsKey(key)) {
                //Create a zero-quantity SKID if no inventory exists
                if (tempSkid.Item__r.Item_Attribute__r.Lot_Number__c)
                    SkidService2.populateLotNames(tempSkid,null,lotMap,lotNames);
                newQuantitySkids.add(tempSkid);
                quantitySkids.add(tempSkid);
            } else {
                Decimal tempQty = icData.quantity;
                quantitySkids = sortedSkidList.get(key).deepClone(true,true,true);
                for (SKID__c skid:quantitySkids) {
                    if (skid.Quantity__c < tempQty)
                        skid.Input_Quantity__c = skid.Quantity__c;
                    else
                        skid.Input_Quantity__c = tempQty;
                    tempQty -= skid.Input_Quantity__c;
                }
                //If there is reminaing quantity, drive the first SKID negative
                if (tempQty > 0)
                    quantitySkids[0].Input_Quantity__c = KSE.addQuantityToField(quantitySkids[0].Input_Quantity__c,tempQty);
            }
            icList.put(icDataKey,icObj);
            updatedSkids.put(icDataKey,quantitySkids);
        }
        Map<String,Lot__c> createdLotMap = SkidService2.createLots(lotMap,lotNames);
        Map<String,List<SKID__c>> quantitySkids = new Map<String,List<SKID__c>>();
        Map<String,SKID__c> skidsToInsert = new Map<String,SKID__c>();
        for (SKID__c qtySkid:newQuantitySkids) {
            if (qtySkid.Item__r.Item_Attribute__r.Lot_Number__c) {
                String uniqueLotString = SkidService2.lotUniqueKey(qtySkid,null);
                qtySkid.Lot__c = createdLotMap.get(uniqueLotString).Id;
            }
            String skidKey = SkidService2.generateKeyForSkid(qtySkid,attributesForDisplay,null,null);
            if (!quantitySkids.containsKey(skidKey))
                quantitySkids.put(skidKey,new List<SKID__c>());
            quantitySkids.get(skidKey).add(qtySkid);
            if (!skidsToInsert.containsKey(skidKey)) {
                SKID__c skidToInsert = qtySkid.clone(false,true);
                skidToInsert.Input_Quantity__c = 0;
                skidsToInsert.put(skidKey,skidToInsert);
            }
        }
        DML.insertAsSystem(skidsToInsert.values());
        for (String skidKey:skidsToInsert.keySet()) {
            Id skidId = skidsToInsert.get(skidKey).Id;
            for (SKID__c qtySkid:quantitySkids.get(skidKey)) {
                qtySkid.Id = skidId;
                //The inserted SKID has a quantity of zero, queried and then adjusted.
                //The skid we're making changes to here is a deep clone of the inserted skid, and isn't the skid instance that actually gets adjusted, so the quantity is arbritrary.
                //We need to set the quantity of skids in the quantitySkidsByHeader to a non-zero number so that it doesn't get deleted.
                //This block of code is only executed for skids that we're creating on the fly.
                qtySkid.Quantity__c = qtySkid.Input_Quantity__c;
            }
        }
        DML.insertAsUser((List<sObject>)icList.values());
        Map<Id,List<SKID__c>> quantitySkidsByHeader = new Map<Id,List<SKID__c>>();
        for (String key:icList.keySet()) {
            quantitySkidsByHeader.put(icList.get(key).Id,updatedSkids.get(key));
            result.put(key,createSuccessResult(icList.get(key).Id));
        }
        Map<String,SKID__c> fromToSkidMap = SkidService2.createToSkidsOnPull((List<sObject>)icList.values(),quantitySkidsByHeader,'Input_Quantity__c','InventoryChange',attributesForDisplay,false,null);
        SkidService2.inventoryTransactionForPullFrom((List<sObject>)icList.values(),quantitySkidsByHeader,'Adjustment',attributesForDisplay,null,'Input_Quantity__c',fromToSkidMap,false,null);
        for (Inventory_Change__c ic:icList.values())
            ic.finalized__c = true;
        DML.updateAsUser((List<sObject>)icList.values());
        return result;
    }


    private static Map<Id,Item__c> getItemMap(Set<Id> itemIds) { 
        /*
        String query = 'SELECT Id,Name,Company__c';
        for (String itemAttrField:util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'))
            query += ',' + itemAttrField;
        query += ' FROM Item__c WHERE Id IN :itemIds';
        return new Map<Id,Item__c>((List<Item__c>)Database.query(query));*/
        //KNDY-8796
        Set<String> cusFields = new Set<String>();
        for (String itemAttrField:util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'))
            cusFields.add(itemAttrField);
        
        
        String whereClause = 'Id IN :itemIds';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(new Set<String>{'Id', 'Name', 'Company__c','Company__r.Default_Transaction_Currency__c' ,'Packaging_UOM__c' }); // #JUSTDOIT Remove company when we remove dependencies in other places in the file.
        soql.addFields(cusFields);
        soql.setWhereClause(whereClause);
        return new Map<Id,Item__c>((List<Item__c>)Database.query(soql.getQuery()));
    }
    public static Map<String,List<SKID__c>> sortSkidsByAttributes(Map<String,List<SKID__c>> itemLocationSkidList,List<String> attributes) {
        Map<String,List<SKID__c>> sortedMap = new Map<String,List<SKID__c>>();
        for (String key:itemLocationSkidList.keySet()) {
            for (SKID__c skid:itemLocationSkidList.get(key)) {
                String skidKey = SkidService2.generateKeyforSkid(skid,attributes,null,null);
                if (!sortedMap.containsKey(skidKey))
                    sortedMap.put(skidKey,new List<SKID__c>());
                sortedMap.get(skidKey).add(skid);
            }
        }
        return sortedMap;
    }
    public static List<String> getAttributesForSorting() {
        Set<String> tempAttributes = new Set<String>(attributesForDisplay);
        tempAttributes.removeAll(new Set<String> { 'Consigned_Owner__c','Purchase_Order_Line__c','Lot__c' });
        tempAttributes.add('Lot_Number__c');
        return new List<String>(tempAttributes);
    }
    public static Map<String,Bin__c> getBins(Set<Id> locationIds,Set<String> binNames) {
        Map<String,Bin__c> binMap = new Map<String,Bin__c>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Bin__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Location__c'
		});
		soql.setWhereClause('Location__c IN :locationIds AND Name IN :binNames');
        for (Bin__c bin:Database.query(soql.getQuery())){



            binMap.put(bin.Name + bin.Location__c,bin);
        }    
        return binMap;
    }
    public static Map<String,Bin__c> getBins(List<Location__c> locations,Set<String> binNames) {
        Set<Id> locationIds = new Set<Id>();
        for (Location__c location:locations)
            locationIds.add(location.Id);
        return getBins(locationIds,binNames);
    }

    
    global class InventoryData {
        global Id itemId { get; set; }
        global Id reasonCodeId { get; set; }
        global Id locationId { get; set; }
        global Id fromLocationId { get; set; }
        global Id toLocationId { get; set; }
        global String lot { get; set; }
        global String bin { get; set; }
        global String toBin { get; set; }
        global Date expirationDate { get; set; }
        global Date dateReceived { get; set; }
        global Decimal quantity { get; set; }
        global Map<String,Object> attributes { get; private set; }
        global InventoryData() { attributes = new Map<String,Object>(); }
    }
    global class InventoryStatus {
        global Id recordId { get; set; }
        global Boolean success { get; set; }
        global String errorMessage { get; set; }
    }
    private static InventoryStatus createErrorResult(String errorMessage) {
        InventoryStatus status = new InventoryStatus();
        status.success = false;
        status.errorMessage = errorMessage;
        return status;
    }
    private static InventoryStatus createSuccessResult(Id recId) {
        InventoryStatus status = new InventoryStatus();
        status.success = true;
        status.recordId = recId;
        return status;
    }
    

    // DEPRECATED
    global static void createInventoryChange(InventoryData icData) { throw new CustomException('Deprecated'); }
    global static void transferInventory(InventoryData itData) { throw new CustomException('Deprecated'); }
    global static Map<String,InventoryStatus> massInventoryTransfer(Map<String,InventoryData> itDataList) { throw new CustomException('Deprecated'); }

    global class InventoryAPIException extends Exception {
        public InventoryAPIException(Object obj) { throw new CustomException('Deprecated'); }
    }
}