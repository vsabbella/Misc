public with sharing class SkidService3 {
    public static final String SKID_TYPE_LOCATION = 'Location';
    public static final String SKID_TYPE_PO_SUPPLY = 'PO Supply';
    public static final String SKID_TYPE_SO_DEMAND = 'SO Demand';
    public static final String SKID_TYPE_TO_DEMAND = 'TO Demand';
    public static final String SKID_TYPE_TO_SUPPLY = 'TO Supply';
    public static final String SKID_TYPE_WO_SUPPLY = 'WO Supply';
    public static final String SKID_TYPE_ALLOCATED = 'Allocated';
    public static final string SKID_TYPE_INTRANSIT = 'In-Transit';
    public static final string SKID_TYPE_INSTALLBASE = 'Install Base';
    public static final string SKID_TYPE_WIP = 'WIP';
    public static final String SKID_TYPE_PLANNED = 'Planned Pick';

    public static final String SERIAL_STATUS_VOIDED = 'Voided';
    public static final String SERIAL_STATUS_INTRANSIT = 'In-Transit';
    public static final String SERIAL_STATUS_DRAFTINTRANSIT = 'Draft In-Transit';
    public static final String SKID_TYPE_DRAFTINTRANSIT = 'Draft In-Transit';

    public static final String ALLOW_SERIAL_REENTRY = 'AllowSerialReentry';
    public static final String VOID_SERIALS = 'VoidSerials';
    
    public static final string CREATE_SERIAL = 'CreateSerial';
    public static final string UNDO_SERIAL = 'UndoSerial';
    public static final string MIXED_SERIAL = 'MixedSerial';
    public static final string UPDATE_SKID_QUANTITY = 'updateSkidQuantity';
    public static final string DELETE_SKIDS = 'deleteSkids';
    public static final String AT_RECEIPT = 'At receipt and all processes';
    public static final String AT_SHIPMENT = 'At shipment only';

    private static SchemaUtil util = SchemaUtil.getInstance();
    private static final Map<String, Schema.sObjectField> skidFieldMap = util.getFieldsMap('SKID__c');
    private static final Map<String, Schema.SObjectField> otFieldMap = util.getFieldsMap('Operation_Transaction__c');

    public static final Map<String, String> fromAttributes = new Map<String, String>{
        'Facility2__c' => 'From_Facility__c',
        'Location__c' => 'From_Location__c',
        'Bin__c' => 'From_Bin__c',
        'Packaging_UOM__c' => 'From_Packaging_UOM__c',
        'Lot__c' => 'From_Lot__c'
    };
    public static final Map<String, String> toAttributes = new Map<String, String>{
        'Facility2__c' => 'To_Facility__c',
        'Location__c' => 'To_Location__c'
    };
    
    public static set<String> attributesToExclude {
        get {
            if (attributesToExclude == null) {
               	attributesToExclude = new set<string>{ 'minimum_shelf_life_in_days__c','serial_number__c','extid__c' };
               	
               	for( String serialField : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes')){
                    attributesToExclude.add(serialField.replace( KSE.namespaceUU, '').toLowerCase().trim());
                }  
            }
            return attributesToExclude;
        }
        set;
    }
    
    public static set<String> doNotDeleteSkidTypes = new set<string>{SKID_TYPE_INSTALLBASE};
    public static set<String> deleteSkidTypesIfNegative = new set<string>{ SKID_TYPE_PO_SUPPLY };
    public static map<String,String> lineToSourceDocumentMap = new map<String,String>{  
																	'purchase_order_line__c' => 'Purchase Order','order_line__c' => 'Transfer Order',
                                                                    'material_tracking__c' => 'Work Order','sales_order_line__c'=>'Sales Order',
                                                                    'asn_line__c'=>'Purchase Order', 'receipt_line__c'=>'Receiving Document',
                                                                    'transfer'=>'Transfer', 'directed putaway'=>'Directed Putaway' 
                                        	                    };

    public static set<String> sourceDocumentLineTypes = new set<String>{'sales_order_line__c','shipment_line__c','work_order__c','purchase_order_line__c','order_line__c','receipt_line__c' };

    public static Set<String> excludeITTypesForIC = new Set<String> { 'Activate Proposed Costs','Transfer','Adjustment Decrease','Adjustment Increase','Cycle Count','QA Sample','Sales Order Allocation Temp','Transfer Receipt','Transfer Shipment','Break Package' };
    public static Map<String,String> defaultSerialTransactionTypes = new Map<String,String>{ 

        'Work Order Component Issue' => 'Component Issue',
        'Work Order Repair Component Issue' => 'Component Issue',
        'Work Order Component Return' => 'Component Return',
        'Work Order Repair Component Return' => 'Component Return',
        'Work Order Issue From WIP' => 'WIP Translate',
        'Work Order Repair Issue From WIP' => 'WIP Translate',
        'Work Order Return To WIP' => 'WIP Untranslate',
        'Work Order Repair Return To WIP' => 'WIP Untranslate',
        'Work Order Assembly Completion' => 'Assembly Completion',
        'Work Order Repair Assembly Completion' => 'Assembly Completion',
        'Work Order Assembly Uncompletion' => 'Assembly Uncompletion',
        'Work Order Repair Assembly Uncompletion' => 'Assembly Uncompletion',
        'Work Order Assembly Scrap' => 'Assembly Scrap',
        'Work Order Repair Assembly Scrap' => 'Assembly Scrap',
        'Work Order Component Scrap' => 'Component Scrap',
        'By-product' => 'By-product Completion',
        'By-product Uncompletion' => 'By-product Uncompletion',
		'In-Transit' => 'In-Transit',
        'RMA Receipt' => 'RMA Receipt',
	    'Logical RMA Receipt' => 'Logical RMA Receipt',
        'RMA Receipt For Repair' => 'RMA Receipt For Repair',
        'RMA Scrap' => 'RMA Scrap',
        'Miscellaneous Receipt' => 'Miscellaneous Receipt',
        'Logical Purchase Order Receipt' => 'Logical Receipt',

        'Purchase Order Receipt' => 'Receipt',
        'Return Receipt' => 'Return Receipt',
        'Logical Sales Order Shipment' => 'Logical Shipment',
    	'Sales Order Pick' => 'Pick',
    	'Sales Order Undo Pick' => 'Undo Pick',
        'Sales Order Shipment' => 'Shipment',
        'Transfer Order Pick' => 'Pick',
        'Transfer Order Undo Pick' => 'Undo Pick',
        'Transfer Order Shipment' => 'Shipment',
        'Transfer Order Undo Shipment' => 'Undo Shipment',
        'Work Order Component Scrap' => 'Component Scrap',   
    	'Purchase Order Return' => 'Return To Vendor',
    	'Logical Purchase Order Return' => 'Logical Return To Vendor',
    	'Sales Order Undo Shipment' => 'Undo Shipment',
        'Purchase Order Return' => 'Return To Vendor',
        'Transfer Receipt' => 'Transfer Receipt',
        'Transfer' => 'Transfer',
        'Rental Exchange In' => 'Rental Exchange In',
        'Rental Exchange Out' => 'Rental Exchange Out'
    };
    
    public class SkidService3Exception extends Exception { }
    
    /**
     * @description in case of part pallets, checks if the pallets have been filled. For full pallets, 
     * it will change the UOM from the granular level to the (appropriate) level above
     * Currently, as per design this feature is applicable only on top level with LPN tracked 
     * 
     * @param Skid__c 
     * @param Item__c
     * 
     */ 
    static Skid__c handleSkidPartQuantities ( Skid__c skid, Item__c item ) {
        Skid__c newSkid;
        if ( skid.Container_Item__r == null || skid.Packaging_UOM__r == null || skid.Packaging_UOM__r.Package_Class__c == null ) return null;
        if (skid != null && skid.License_Plate_Number__c != null && skid.Packaging_UOM__r.Package_Class__c != skid.Container_Item__r.Container_Package_Class__c ) {
            
            Id parentUomId = getNextLevelUomId(skid, item);
            
            UOM__c parentUom = new UOM__c(Id=parentUomId);
            List<Id> lstPkgUom = (List<Id>) JSON.deserialize(item.Packaging_UOM__c, List<Id>.class);
            Decimal cf = KSE.getConversionFactor( skid.Item__c, skid.Facility2__r.Facility_Identifier__c, parentUom.Id, skid.Packaging_UOM__c, lstPkgUom );
            Decimal cfParentUomToStocking = KSE.getConversionFactor( skid.Item__c, skid.Facility2__r.Facility_Identifier__c, parentUom.Id, skid.Stocking_UOM__c, lstPkgUom );
            
            if ( (skid.Quantity__c /cf) > 1 ) {
                throw new SkidService3Exception('Pallet cannot be overfilled');  // TODO refine message
            }
            // check if hte pallet has been filled
            if ( (skid.Quantity__c / cf) == 1 ) { 
                newSkid = skid.clone(true, true);
                newSkid.Quantity__c = 1; 
                newSkid.Quantity_Stocking_UOM__c = newSkid.Quantity__c * cfParentUomToStocking;
                newSkid.Packaging_UOM__c = parentUom.Id;
                newSkid.Packaging_UOM__r = parentUom;
                newSkid.Unique_Key__c = generateSkidUniqueKey(newSkid); //need to recompute the unique key as we are changing attributes
            }
        }
        
        return newSkid;
    }
    
    /**
     * @description Get's the next (upper) level packaging uom for the skid packaging UOM
     * from the Item Packaging UOM.
     * @param skid__c Packaging UOM should not be null  
     * @param item__c Packaging UOM should not be null. ensure that the hierarchy is setup correct
     * 
     */ 
    public static Id getNextLevelUomId ( Skid__c skid, Item__c item ) {
        Id parentUomId = null;
        if (item != null && item.Packaging_UOM__c != null && skid != null && skid.Packaging_UOM__c != null ) {
            List<Id> pkgUOMIds = (List<Id>)JSON.deserialize(item.Packaging_UOM__c,List<Id>.class);
            Iterator<Id> iter = pkgUOMIds.iterator();
            while( iter.hasNext()){
                if ( skid.Packaging_UOM__c == iter.next() ) {
                    if ( iter.hasNext() ) {
                        parentUomId = iter.next();
                        break;
                    } else {
                        throw new SkidService3Exception('Packaging UOM not configured for Item: ' + item.name ); // TODO Refine message/add to custom labels
                    }
                }
            }
        }
        return parentUomId;
    }

    /**
     *
     */
    public static Id getLevelBelowUomId (Id packagingUom, List<Id> sortedUoms) {
        if ( packagingUom == null || sortedUoms == null || sortedUoms.isEmpty() ){
            throw new SkidService3Exception('');
        }
        Id returnUom = null;
        for (Id uom : sortedUoms ) {
            if ( uom != packagingUom ) {
                returnUom = uom;
            } else {
                break;
            }
        }
        if ( returnUom == null ) throw new SkidService3Exception('Not found packaging uom');
        return returnUom;
    }
    
    /**
    * @description : creates or merges skids based on the attributes of skids. Serials that need to be created/updated and/or 
    * tied to a skid need to be passed along in the serialWrapper. Prevents Duplicate serial creation.
    * allow_reentry__c flag on the serial is checked if the serial is currently out of the system, but if it can be allowed again inside the system
    * ConfigMap is a map of parameters that is used by the service. CREATE_SERIAL, UNDO_SERIAL, CONSIGNED are some of the current parameters
    * UNDO_SERIAL can be used in voiding or cancelling cases where the serials should not refer to any skids.
    * MIXED_SERIAL specifies that serials should be updated if the serial has id and otherwise it should be inserted. We have a separate CREATE_SERIAL flag
    * to ensure serials dont get updated during a transaction that is only supposed to create serials like receiving.
    * UPDATE_SKID_QUANTITY updates and overwrites the existing skid quantity with specified quantity instead of merging.
    * 
    * IMPORTANT: Please ensure the skids in the serialWrappers that are passed in have the Type__c field populated accordingly.
    * 
    * TODO allow/disallow fractional quantities on LPN tracked item ??
    * 
    */
    public static map< list<String>, SerialWrapper > putAwayService( List< SerialWrapper > skidSerialList, list< String > attributes, map<String,Boolean> configMap ){
        Map<String,Schema.SObjectField> skidFields = util.getFieldsMap('SKID__c');
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
        list< String > attributeList = new list< String >();

        Boolean allowReentry = true;    //Only allows service to get ids from voided and in-transit serials
        Boolean voidSerials = false;    //Will set serial status to voided
        
        Boolean serialCreation = false;
        Boolean UndoSerial = false;
        Boolean mixedSerial = false;
        Boolean updateSkidQuantity = false;
        Boolean deleteSkids = false;
        
        if (configMap != null) {
            allowReentry = configMap.containsKey(ALLOW_SERIAL_REENTRY) ? configMap.get(ALLOW_SERIAL_REENTRY) : true;
            voidSerials = configMap.containsKey(VOID_SERIALS) ? configMap.get(VOID_SERIALS) : false;
            
            serialCreation = configMap.containsKey(CREATE_SERIAL) ? configMap.get(CREATE_SERIAL) : false;
            UndoSerial = configMap.containsKey(UNDO_SERIAL) ? configMap.get(UNDO_SERIAL) : false;
            mixedSerial = configMap.containsKey(MIXED_SERIAL) ? configMap.get(MIXED_SERIAL) : false;
            updateSkidQuantity = configMap.containsKey(UPDATE_SKID_QUANTITY) ? configMap.get(UPDATE_SKID_QUANTITY) : false;
            deleteSkids = configMap.containsKey(DELETE_SKIDS) ? configMap.get(DELETE_SKIDS) : false;
        }
        
        if(attributes == null ){
            attributeList = attributesForPutaway();
        }
        else{
            attributeList = attributes.clone();
        }
        
        list<SKID__c> skidList = new list<SKID__c>();
        map< list<String>, SKID__c > existingSkidKeys = new map< list<String>, SKID__c >();
        map< list<String>, SKID__c > toSkids = new map< list<String>, SKID__c >();
        map<Id, Skid__c> deleteSkidsMap = new map<Id, Skid__c>();
        map< list<String>, SerialWrapper> serialWrapperByKey = new map<list<String>, SerialWrapper>();
        map< list<String>, SerialWrapper> existingserialWrapperByKey = new map<list<String>, SerialWrapper>();
        Map<String,Serial__c> serialsForInsert = new Map<String,Serial__c>();
        Map<String,Serial__c> serialMap = new Map<String,Serial__c>();
        List<Serial__c> serialsForUpdate = new List<Serial__c>();
        Boolean includeSerials = false;

        Set<Id> binIds = new Set<Id>();
        Map<Id, bin__c> binMap = new Map<Id, Bin__c>();
        Map<Id, String> itemNames = new Map<Id, String>();
        
        for (SerialWrapper sw:skidSerialList) {
            if (sw.skid != null) {
                list<Id> pkgUOMIds;
                if ( !itemPackagingUomCache.containsKey(sw.skid.Item__c) ) {
                    pkgUOMIds = (List<Id>) JSON.deserialize(sw.skid.item__r.Packaging_UOM__c, List<Id>.class);
                    itemPackagingUomCache.put(sw.skid.Item__c, pkgUOMIds);
                } 
                
                if (sw.skid.Facility2__c == null && sw.skid.Location__c != null) {
                    sw.skid.Facility2__c = sw.skid.Location__r.Facility__c;
                    sw.skid.Facility2__r = sw.skid.Location__r.Facility__r;
                }
                
                if (sw.skid.Stocking_UOM__c == null && sw.skid.Item__r != null && sw.skid.Item__r.Stocking_UOM__c != null) sw.skid.Stocking_UOM__c = sw.skid.Item__r.Stocking_UOM__c;
                
                skidList.add(sw.skid);

                for (String attr:attributeList) {
                    attr = attr.toLowerCase();
                    if (!attributesToExclude.contains(attr)) {
                        DescribeFieldResult dfr = skidFields.get(attr).getDescribe();
                        if (dfr.getType() == Schema.DisplayType.Boolean && sw.skid.get(attr) == null) {
                            sw.skid.put(attr,false);
                        } else if ((dfr.getType() == Schema.DisplayType.Currency || dfr.getType() == Schema.DisplayType.Double || dfr.getType() == Schema.DisplayType.Integer || dfr.getType() == Schema.DisplayType.Percent) && sw.skid.get(attr) != null) {
                            sw.skid.put(attr,((Decimal)sw.skid.get(attr)).setScale(dfr.getScale()));
                        }
                    }
                }
            }

            if (sw.skid.Type__c == SKID_TYPE_LOCATION && sw.skid.Bin__c != null) {
                try {
                    if (sw.skid.Bin__r == null || sw.skid.Bin__r.Location__r == null || sw.skid.Bin__r.Location__r.Track_Bin_Capacity__c == null || sw.skid.Bin__r.Location__r.Mixed_Bins_Allowed__c == null || sw.skid.Bin__r.Max_Capacity__c == null || sw.skid.Bin__r.Packaging_UOM__c == null) binIds.add(sw.skid.Bin__c);
                    else binMap.put(sw.skid.Bin__c, sw.skid.Bin__r);
                } catch (Exception e) {
                    binIds.add(sw.skid.Bin__c);
                }
            }
            
            if ((sw.skid.Type__c == SKID_TYPE_INTRANSIT || sw.skid.Type__c == SKID_TYPE_DRAFTINTRANSIT) && !includeSerials && sw.skid.ASN_Line__c != null) {

                includeSerials = true;
            }
        
        }
        //sorted wrapper based on skid.quantity .
        skidSerialList.sort();
        //queries existing skids to check if there are any existing skids with matching attributes
        if( skidList.size() > 0)
            existingSkidKeys = generateExistingSkidMapForPutaway(attributeList, skidList, includeSerials, null);
        
        Map<String, Serial__c> serialkeymap = new Map<String, Serial__c>();
        Map<Id, Decimal> binQty = new Map<Id, Decimal>();
        Map<Id, Id> binItem = new Map<Id, Id>();
        Map<Id, Set<Id>> lpnToShipments = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> lpnToOrders = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> lpnToSkids = new Map<Id, Set<Id>>();
        for (List<String> key:existingSkidKeys.keySet()) {
            SKID__c sk = existingSkidKeys.get(key);
            list<Id> pkgUOMIds;
            if ( !itemPackagingUomCache.containsKey(sk.Item__c) ) {
                pkgUOMIds = (List<Id>) JSON.deserialize(sk.item__r.Packaging_UOM__c, List<Id>.class);
                itemPackagingUomCache.put(sk.Item__c, pkgUOMIds);
            } else {
                pkgUOMIds = itemPackagingUomCache.get(sk.Item__c);
            }
            
            if (!itemNames.containsKey(sk.Item__c)) itemNames.put(sk.Item__c, sk.Item__r.Name);

            if (sk.License_Plate_Number__c != null && sk.Quantity__c != 0) {
                if (sk.Type__c == SKID_TYPE_LOCATION && sk.Shipment_Line__c != null) {
                    if (lpnToShipments.containsKey(sk.License_Plate_Number__c) == false) lpnToShipments.put(sk.License_Plate_Number__c, new Set<Id>{ sk.Shipment_Line__r.Shipment__c });
                    else lpnToShipments.get(sk.License_Plate_Number__c).add(sk.Shipment_Line__r.Shipment__c);
                } else if (sk.Type__c == SKID_TYPE_INTRANSIT && sk.Order_Line__c != null) {
                    if (lpnToOrders.containsKey(sk.License_Plate_Number__c) == false) lpnToOrders.put(sk.License_Plate_Number__c, new Set<Id>{ sk.Order_Line__r.Order__c });
                    else lpnToOrders.get(sk.License_Plate_Number__c).add(sk.Order_Line__r.Order__c);
                } else {
                    if (lpnToSkids.containsKey(sk.License_Plate_Number__c) == false) lpnToSkids.put(sk.License_Plate_Number__c, new Set<Id>{ sk.Id });
                    else lpnToSkids.get(sk.License_Plate_Number__c).add(sk.Id);
                }
            }
            
            if (includeSerials && sk.Type__c == SKID_TYPE_INTRANSIT) {
                for(Serial__c serial:sk.Serials__r){
                
                    Id companyId = (Id)sk.Company__c;
                    Id itemId = (Id)sk.get('Item__c');
                    serialkeymap.put(companyId+'-'+itemId+'-'+serial.Name,serial);
                }
            }

            if (sk.Type__c == SKID_TYPE_LOCATION && sk.Bin__c != null) {
                binMap.put(sk.Bin__c, sk.Bin__r);
                binIds.remove(sk.Bin__c);

                checkBinCapacity(sk.Bin__r, sk, binQty, null, true, false);

                if (sk.Bin__r.Location__r.Mixed_Bins_Allowed__c == false) {
                    if (binItem.containsKey(sk.Bin__c) && binItem.get(sk.Bin__c) != sk.Item__c) throw new CustomException('Bin ' + sk.Bin__r.Name + ' has multiple items. Please check the bin\'s inventory.');
                    else binItem.put(sk.Bin__c, sk.Item__c);
                }
            }
        }
        
        set<Id> itemIds = new set<Id>();
        set<String> serialUniqueKeys = new set<String>();

        if (binIds.size() > 0) {
            SOQLUtil binQuery = new SOQLUtil('Bin__c');
            binQuery.addFields(new Set<String>{ 'Id', 'Name', 'Description__c', 'Location__c', 'Max_Capacity__c', 'Packaging_UOM__c',
                'Location__r.Default_Max_Capacity__c', 'Location__r.Mixed_Bins_Allowed__c', 'Location__r.Track_Bin_Capacity__c',
                'Location__r.Facility__r.Default_Mixed_Bins_Allowed__c'
            });
            binQuery.setWhereClause('Id IN :binIds');
            binMap.putAll(new Map<Id, Bin__c>((List<Bin__c>)Database.query(binQuery.getQuery())));
        }
       
        for( SerialWrapper sw : skidSerialList ) {
            
            list<String> key = new list<String>();
            SKID__c skid = sw.skid;
            SObject itSkid = skid == null ? (SObject)sw.it : (SObject)skid;
            key = generateKey( itSkid, attributeList );
            if( sw.serialList != null && sw.serialList.size() > 0 ){
                
                //Collecting unique keys of serials when the mode is CREATE_SERIAL or MIXED_SERIAL as those are the two possible modes where serials can be created.
                //These unique keys are then used to query existing allow_reentry__c checked serials to verify if the serial can be allowed to enter the system or not.
                if (serialCreation || mixedSerial) { 
                    for (Serial__c sr:sw.serialList) {
                        sr.Name = sr.Name.trim();
                        if (serialCreation || (mixedSerial && sr.Id == null)) {
                            Id companyId = (Id)itSkid.get('Company__c');
                            if (skid != null && skid.Company__c != null) {
                                companyId = skid.Company__c;
                            }
                        
                            Id itemId = (Id)itSkid.get('Item__c');
                            itemIds.add(itemId);
                        
                            serialUniqueKeys.add(companyId + '-' + itemId + '-' + sr.Name);
                        }
                    }
                }
                
                if(!serialWrapperByKey.containsKey(key)){ //structure serialWrappers By the attribute keys.
                    serialWrapperByKey.put( key, new SerialWrapper(skid, sw.it, sw.serialList ));
                }
                else{
                    serialWrapperByKey.get(key).serialList.addAll(sw.serialList);
                }
            }
            else{
                serialWrapperByKey.put( key, new SerialWrapper(skid, sw.it,serialWrapperByKey.containsKey(key) ? serialWrapperByKey.get(key).serialList : new List<Serial__c>()));
            }

            if (skid != null) {
                if (toSkids.containsKey(key) == true) {
                    toSkids.get(key).Quantity__c += skid.Quantity__c;
                } else if (existingSkidKeys.containsKey(key) == true) {
                    SKID__c sk = existingSkidKeys.get(key);
                    sk.Quantity__c = updateSkidQuantity == true ? skid.Quantity__c : KSE.addQuantityToField(sk.Quantity__c, skid.Quantity__c);
                    toSkids.put(key, sk);
                } else {
                    SKID__c newSkid = skid.clone(false, true);
                    if (configMap != null && configMap.get('transferofowner') == true) {
                        newSkid.Purchase_Order_Line__c = null;
                        newSkid.Consigned_Owner__c = null;
                    }

                    if (newSkid.License_Plate_Number__c != null && newSkid.Quantity__c != 0 && (newSkid.Type__c != SKID_TYPE_LOCATION || newSkid.Shipment_Line__c == null) && (newSkid.Type__c != SKID_TYPE_INTRANSIT || newSkid.Order_Line__c == null)) {
                        if (lpnToSkids.containsKey(newSkid.License_Plate_Number__c) == true) throw new CustomException('LPN ' + newSkid.License_Plate_Number__r.Name + ' already exists.');
                        else lpnToSkids.put(newSkid.License_Plate_Number__c, new Set<Id>{ newSkid.Company__c });    // DUMMY ID
                    }

                    toSkids.put(key, newSkid);
                }
                
                SKID__c toSkid = toSkids.get(key);
                blankOutInputFieldsOnSkidPutaway(toSkid);
                toSkid.Unique_Key__c = generateSkidUniqueKey(toSkid);

                if (skid.Type__c == SKID_TYPE_LOCATION && skid.Bin__c != null) {
                    Bin__c bin = binMap.get(skid.Bin__c);
                    checkBinCapacity(bin, skid, binQty, lpnToSkids, false, (skid.Quantity__c < 0 && toSkid.Quantity__c < 0) || (skid.Quantity__c > 0 && toSkid.Quantity__c > 0));

                    if (bin.Location__r.Mixed_Bins_Allowed__c == false) {
                        if (binItem.containsKey(bin.Id) && binItem.get(bin.Id) != skid.Item__c) throw new CustomException('Can\'t putaway item ' + skid.Item__r.Name + ' to bin ' + bin.Name + '. Mixed bins are not allowed.');
                        else binItem.put(skid.Bin__c, skid.Item__c);
                    }
                }

                if (toSkid.License_Plate_Number__c != null) {
                    String lpn = toSkid.License_Plate_Number__c;
                    String lpnName = toSkid.License_Plate_Number__r.Name;
                    if (toSkid.Type__c == SKID_TYPE_LOCATION && toSkid.Shipment_Line__c != null) {
                        Id shipmentId = toSkid.Shipment_Line__r.Shipment__c;
                        if (toSkid.Quantity__c != 0) {
                            if (lpnToOrders.containsKey(lpn) == true || lpnToSkids.containsKey(lpn) == true) {
                                throw new CustomException('LPN ' + lpnName + ' already exists.');
                            } else if (lpnToShipments.containsKey(lpn) == true && lpnToShipments.get(lpn).contains(shipmentId) == false) {
                                throw new CustomException('LPN ' + lpnName + ' already exists on a different shipment.');
                            } else if (lpnToShipments.containsKey(lpn) == false) {
                                lpnToShipments.put(lpn, new Set<Id>{ shipmentId });
                            }
                        } else if (lpnToShipments.containsKey(lpn) == true && lpnToShipments.get(lpn).contains(shipmentId) == true) {
                            lpnToShipments.get(lpn).remove(shipmentId);
                            if (lpnToShipments.get(lpn).size() == 0) lpnToShipments.remove(lpn);
                        }
                    } else if (toSkid.Type__c == SKID_TYPE_INTRANSIT && toSkid.Order_Line__c != null) {
                        Id orderId = toSkid.Order_Line__r.Order__c;
                        if (toSkid.Quantity__c != 0) {
                            if (lpnToShipments.containsKey(lpn) == true || lpnToSkids.containsKey(lpn) == true) {
                                throw new CustomException('LPN ' + lpnName + ' already exists.');
                            } else if (lpnToOrders.containsKey(lpn) == true && lpnToOrders.get(lpn).contains(orderId) == false) {
                                throw new CustomException('LPN ' + lpnName + ' already exists on a different transfer order.');
                            } else if (lpnToOrders.containsKey(lpn) == false) {
                                lpnToOrders.put(lpn, new Set<Id>{ orderId });
                            }
                        } else if (lpnToOrders.containsKey(lpn) == true && lpnToOrders.get(lpn).contains(orderId) == true) {
                            lpnToOrders.get(lpn).remove(orderId);
                            if (lpnToOrders.get(lpn).size() == 0) lpnToOrders.remove(lpn);
                        }
                    } else {
                        if (toSkid.Quantity__c != 0) {
                            if (lpnToShipments.containsKey(lpn) == true || lpnToOrders.containsKey(lpn) == true || (toSkid.Id != null && lpnToSkids.containsKey(lpn) == true && lpnToSkids.get(lpn).contains(toSkid.Id) == false)) {
                                throw new CustomException('LPN ' + lpnName + ' already exists.');
                            } else if (toSkid.Id != null && lpnToSkids.containsKey(lpn) == false) {
                                lpnToSkids.put(lpn, new Set<Id>{ toSkid.Id });
                            }
                        } else if (toSkid.Id != null && lpnToSkids.containsKey(lpn) == true && lpnToSkids.get(lpn).contains(toSkid.Id) == true) {
                            lpnToSkids.get(lpn).remove(toSkid.Id);
                            if (lpnToSkids.get(lpn).size() == 0) lpnToSkids.remove(lpn);
                        }
                    }
                }
            }
        }
        
        if (toSkids.values().size() > 0) {
            for (List<String> key:toSkids.keySet()) {
                SKID__c skid = toSkids.get(key);
                List<Id> pkgUoms = (List<Id>)JSON.deserialize(skid.Item__r.Packaging_UOM__c, List<Id>.Class);
                skid.Quantity__c = skid.Quantity__c.setScale(6, System.RoundingMode.HALF_UP);
                skid.Quantity_Stocking_UOM__c = (skid.Quantity__c * KSE.getConversionFactor(skid.Item__c, skid.Facility2__r.Facility_Identifier__c, skid.Packaging_UOM__c, skid.Stocking_UOM__c, pkgUoms)).setScale(6, System.RoundingMode.HALF_UP);
                
                if (deleteSkids) {
                    if ((skid.Quantity__c == 0 && !doNotDeleteSkidTypes.contains(skid.Type__c)) || (skid.Quantity__c < 0 && deleteSkidTypesIfNegative.contains(skid.Type__c))) {
                        if (skid.Id != null) {
                            deleteSkidsMap.put(skid.Id,skid);
                        }
                        toSkids.remove(key);
                        continue;
                    }
                }
                //Check to stop putaway in fractional qty.
                if(skid.Quantity__c != null && skid.Quantity__c > 0 ){
                    UOM__c tempUOM = new UOM__c();
                    tempUOM = skid.Packaging_UOM__r;  
                    Decimal convertedQty =  skid.Quantity__c.stripTrailingZeros();  
                
                    if((convertedQty.scale() >0) && tempUOM !=null && tempUOM.Package_Class__r !=null && tempUOM.Package_Class__r.Fractional_Quantities_Allowed__c != true ){
                        
                       throw new SkidService3Exception(skid.item__r.name +' : ' +'Fractional Quantities are not allowed on the package class associated to Packaging UOM.');
                    }  
                }
                // LPN tracked item can have a max qty of 1
                if ( skid.Type__c == SKID_TYPE_LOCATION && skid.License_Plate_Number__c != null ) {
                    if ( skid.Packaging_UOM__r.Package_Class__c == skid.Container_Item__r.Container_Package_Class__c ) {
                        // pallet number can be assigned to a single skid
                        if ( skid.Quantity__c != 1 && skid.quantity__c != 0) {
                            throw new SkidService3Exception ('Invalid quantity specified: ' + skid.Quantity__c + '. Quantity expected : 1 as the container is LPN Tracked'); // TODO refine message
                        }
                    } else if(skid.Shipment_Line__c == null && skid.Order_Line__c == null) { //no pallet capacity and no auto palletize for mixed pallets
                        Skid__c newSkid = handleSkidPartQuantities ( skid, skid.Item__r );
                        
                        if ( newSkid != null ){
                            serialWrapperByKey.get(key).toSkid = newskid;
                            toSkids.put( key, newSkid );
                        }
                    }
                }
            }
            
            DML.upsertAsSystem(); upsert toSkids.values();
            DML.deleteAsSystem(deleteSkidsMap.values());
        }
        
        Map<String,Id> reentrySerials = new Map<String,Id>();
        if (serialUniqueKeys.size() > 0) {
            String whereClause = 'Item__c IN :itemIds AND Unique_Key2__c IN :serialUniqueKeys AND Allow_Reentry__c = true ';
            if (allowReentry == false) {
                whereClause += 'AND Status__c IN (\'' + SERIAL_STATUS_VOIDED + '\',\'' + SERIAL_STATUS_INTRANSIT + '\',\'' + SERIAL_STATUS_DRAFTINTRANSIT + '\')';
            }

            SOQLUtil serialQuery = new SOQLUtil('Serial__c');
            serialQuery.addFields(new Set<String>{ 'Id','Unique_Key2__c' });
            serialQuery.setWhereClause(whereClause);
            for (Serial__c serial:Database.query(serialQuery.getQuery())) {
                reentrySerials.put(serial.Unique_Key2__c,serial.Id);
            }
        }
        
        if(serialkeymap.size() > 0){
            //Removing Skid from existing Serial on the Skid and marking Alllow ReEntry as true:
                    
            for(String s:serialkeymap.keyset()){
                
                if(!serialUniqueKeys.contains(s)){
                    Serial__c serialobj = serialkeymap.get(s);
                    serialobj.SKID__c = null;
                    serialobj.allow_reentry__c = true;
                    serialsForUpdate.add(serialobj);
                }
            }
        }
        for(list<String> key: serialWrapperByKey.keySet()){
            
            SerialWrapper sw = serialWrapperByKey.get(key);
            if(toSkids.containsKey(key)){
                sw.Skid = toSkids.get(key);
            }
            
            SObject itSkid = (sw.Skid == null) ? (SObject)sw.it : (SObject)sw.Skid;

            for (Serial__c sr:sw.serialList) {
                sr.Name = sr.Name.trim();
                sr.Company__c = (Id)itSkid.get('Company__c');
                sr.Item__c = (Id)itSkid.get('Item__c');
                sr.Unique_Key2__c = sr.Company__c + '-' + sr.Item__c + '-' + sr.Name;

                Serial__c oldSr = sr.clone(true,true);

                //Set allow reentry flag if there is no skid, UndoSerial is set, Allow_Reentry__c is set, or skid is in-transit or install base
                //Set skid to null if no skid, UndoSerial is set, or Allow_Reentry__c is set
                if (!toSkids.containsKey(key) || sw.skid == null || UndoSerial == true || sr.Allow_Reentry__c == true || sw.skid.Type__c == SKID_TYPE_INTRANSIT || sw.skid.Type__c == SKID_TYPE_DRAFTINTRANSIT || sw.skid.Type__c == SKID_TYPE_INSTALLBASE) {
                    sr.Allow_Reentry__c = true;
                } else {
                    sr.Allow_Reentry__c = false;
                }

                //Set skid to null if no skid, UndoSerial is set, or Allow_Reentry__c is set
                if (!toSkids.containsKey(key) || sw.skid == null || UndoSerial == true || (oldSr.Allow_Reentry__c == true && sw.skid.Type__c != SKID_TYPE_INTRANSIT && sw.skid.Type__c != SKID_TYPE_DRAFTINTRANSIT)) {
                    sr.SKID__c = null;
                } else {
                    sr.SKID__c = sw.skid.Id;
                }

                if (sr.Allow_Reentry__c == true && ((sr.SKID__c == null && voidSerials) || (sr.SKID__c != null && sw.skid.Type__c == SKID_TYPE_INTRANSIT) || (sr.SKID__c != null && sw.skid.Type__c == SKID_TYPE_DRAFTINTRANSIT))) {
                    if (sr.SKID__c == null && voidSerials) {
                        sr.Status__c = SERIAL_STATUS_VOIDED;
                    } else if (sr.SKID__c != null && sw.skid.Type__c == SKID_TYPE_INTRANSIT) {
                        sr.Status__c = SERIAL_STATUS_INTRANSIT;
                    }
                    else if (sr.SKID__c != null && sw.skid.Type__c == SKID_TYPE_DRAFTINTRANSIT) {
                        sr.Status__c = SERIAL_STATUS_DRAFTINTRANSIT;//Marking it to Draft In Transit
                    }
                } else {
                    sr.Status__c = null;
                }

                //Serial creation requires the serial to either have Allow_Reentry__c == true OR not exist
                //Mixed serial will take the id if populated, otherwise it will function like serial creation
                //If not serial creation or mixed serial, Id must be populated
                Boolean serialInserted = false;
                if (serialCreation || mixedSerial) {
                    if (serialCreation) {
                        sr.Id = null;
                    }

                    if (sr.Id == null && reentrySerials.containsKey(sr.Unique_Key2__c)) {
                        sr.Id = reentrySerials.get(sr.Unique_Key2__c);
                    }

                    if (sr.Id == null) {
                        if (sr.Temporary_Value_Holder__c != null) {
                            Serial__c serial = sr.clone(true,true);
                            serial.Temporary_Value_Holder__c = null;
                            serialsForInsert.put(serial.Unique_Key2__c,serial);
                            serialMap.put(serial.Unique_Key2__c,sr);
                        } else {
                            serialsForInsert.put(sr.Unique_Key2__c,sr);
                        }
                        serialInserted = true;
                    }
                }

                if (serialInserted == false) {
                    //Temporary value holder is needed for inventory transaction method
                    Serial__c serial = sr.clone(true,true);
                    serial.Temporary_Value_Holder__c = null;
                    serialsForUpdate.add(serial);
                }
            }
        }
        
        if (serialsForInsert.size() > 0) {
            try {
                insert serialsForInsert.values();
            } catch (DMLException de) {
                if (de.getMessage().contains('DUPLICATE_VALUE')){ //attempting to create a serial that already exists in the system
                    throw new SkidService3Exception(serialsForInsert.values()[de.getDmlIndex(0)].Name + ': ' + Label.Serial_Number_Exists);
                } else {
                    throw de;
                }
            }

            for (String serialKey:serialMap.keySet()) {
                serialMap.get(serialKey).Id = serialsForInsert.get(serialKey).Id;
            }
        }
        
        if( serialsForUpdate.size() > 0 ){
            DML.updateAsSystem( serialsForUpdate);
        }
        return serialWrapperByKey;
    }

    private static void checkBinCapacity(Bin__c bin, SKID__c skid, Map<Id, Decimal> binQty, Map<Id, Set<Id>> lpnMap, Boolean existing, Boolean validate) {
        if (skid.Quantity__c != null && skid.Quantity__c != 0 && bin.Location__r.Track_Bin_Capacity__c == true && bin.Max_Capacity__c != null && bin.Packaging_UOM__c != null) {
            List<Id> pkgUoms = (List<Id>)JSON.deserialize(skid.Item__r.Packaging_UOM__c, List<Id>.Class);
            Decimal qty = skid.Quantity__c;
            Id uom = skid.Packaging_UOM__c;
            if (skid.Item__r.Container__c == false && skid.Packaging_UOM__r.Package_Class__c != null && skid.Container_Item__r.Container_Package_Class__c != null && skid.Packaging_UOM__r.Package_Class__r.Level__c != skid.Container_Item__r.Container_Package_Class__r.Level__c) {
                // If we have a partial container, consider it a full container for bin capacity purposes
                if (pkgUoms.size() < skid.Container_Item__r.Container_Package_Class__r.Level__c) throw new CustomException(existing == true ? 'Item ' + skid.Item__r.Name + '\'s inventory has an invalid container. Please check the item\'s inventory.' : 'Invalid container on item ' + skid.Item__r.Name + '.');
                uom = pkgUoms[skid.Container_Item__r.Container_Package_Class__r.Level__c.intValue() - 1];
                qty = (qty / KSE.getConversionFactor(skid.Item__c, skid.Facility2__r.Facility_Identifier__c, uom, skid.Packaging_UOM__c, pkgUoms)).round(System.RoundingMode.CEILING);
                if (qty == 0) return;
            }

            Decimal convFactor;
            Boolean isBinUomLarger = true;
            try {
                convFactor = KSE.getConversionFactor(skid.Item__c, skid.Facility2__r.Facility_Identifier__c, bin.Packaging_UOM__c, uom, pkgUoms);
                if (convFactor < 1) {
                    isBinUomLarger = false;
                    convFactor = KSE.getConversionFactor(skid.Item__c, skid.Facility2__r.Facility_Identifier__c, uom, bin.Packaging_UOM__c, pkgUoms);
                }
            } catch (Exception e) {
                if (validate == true) throw new CustomException('Can\'t find a valid conversion factor between the item\'s and bin\'s UOMs.');
            }

            if (convFactor != null && (lpnMap == null || skid.License_Plate_Number__c == null || lpnMap.containsKey(skid.License_Plate_Number__c) == false)) {
                qty = isBinUomLarger == true ? (qty / convFactor) : (qty * convFactor);
                binQty.put(bin.Id, KSE.addQuantityToField(binQty.get(bin.Id), qty.setScale(6, System.RoundingMode.HALF_UP)));
                if (validate == true && binQty.get(bin.Id) > bin.Max_Capacity__c) throw new CustomException('Bin ' + bin.Name + ' has exceeded the maximum capacity.');
            }
        }
    }
    
    /**
     * @description : blanks out scratch/ input fields that may be populated on the skid
     */
    public static void blankOutInputFieldsOnSkidPutaway(SKID__c sk){
        sk.Temporary_Value_Holder__c = null;
        sk.Temporary_Value_Holder1__c = null;
        sk.Temporary_LPN_Holder__c = null;
        sk.Count_Quantity__c = null;
        sk.Input_Quantity__c = null;
        sk.Quantity_To_Issue__c = null;
        sk.Quantity_To_Scrap__c = null;
        sk.Quantity_To_Return__c = null;
        sk.Quantity_Scrapped__c = null;
        sk.Quantity_Used__c = null;
        sk.Quantity_Allocated__c = null;
        sk.Quantity_Available__c = null;
        sk.Quantity_Issued__c = null;
    }
    
    /**
     * @description : queries existing skids based on attributes with or without related serials and returns a map based on attributes.
     * Query of existing skids is based on the collection of attribute values of the skids that are passed in.
     * Please ensure the skids that are passed in have the Type__c field populated accordingly.
     */
    public static map<list<String>, SKID__c> generateExistingSkidMap(list<String> attributeList, List<SKID__c> skidList, Boolean includeSerials, String additionalWhereClause){
        Map<String,Schema.SObjectField> skidFields = util.getFieldsMap('SKID__c');
        map< list<String>, SKID__c > existingSkidKeysMap = new map< list<String>, SKID__c >();
        Set<String> attributeSet = new Set<String>();
        set<Id> skidIds = new set<Id>();
        
        if(skidList.size() > 0){
            if( attributeList == null ){
                attributeList = new List<String>(attributesForPutaway());
            } 
            
            for(SKID__c sk : skidList ){
                if(sk.Id != null){
                    skidIds.add(sk.Id);
                }
            }
            
            attributeSet.addAll(attributeList);
            attributeSet.add('Type__c');
            
            String whereClause = SchemaUtil.getQueryFilter(skidList, attributeSet);
            
            if( additionalWhereClause != null ) 
                whereClause += additionalWhereClause;
            
            SOQLUtil skidQuery = new SOQLUtil('SKID__c');
            Set<String> skidFieldStrings = new Set<String>{ 'CreatedDate','LastModifiedDate','Quantity_Stocking_UOM__c','Location__r.Facility__r.Name','Location__r.Name','Lot__r.Name','Lot__r.Lot_Hold__c','Lot__r.Expiration_Date__c','Lot__r.Lot_Unique__c',
            	'Sales_Order_Line__r.Ship_From_Location__c','Consigned_Owner__r.Name','Purchase_Order_Line__r.Name','Company__c','Company__r.Serial_Control__c','Location__r.Bin_Tracked__c','Bin__r.Name','Location__r.Facility__c','Location__r.Nettable__c',
            	'ASN_Line__c','Company__c','Customer__c','Lot_Number__c','Material_Tracking__c','Order_Line__c','Quantity__c','Receipt_Line__c','Sales_Order_Line__c','Type__c','Unique_Key__c','Work_Order__c','Bin__r.Location__c','Item__r.Packaging_UOM__c', 'Shipment_Line__c', 'Shipment_Line__r.Shipment__c',
            	'Item__r.Non_Inventory__c','Item__r.Non_Shippable__c','Item__r.Source__c','Item__r.Item_Attribute__c','Item__r.Company__c','Item__r.Active__c','Item__r.Purchasing_UOM__c','Item__r.Stocking_UOM__c','Item__r.Track_Install_Base__c','Item__r.Container__c','Container_Item__r.Container__c',
            	'Packaging_UOM__r.Package_Class__c', 'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'License_Plate_Number__c', 'Stocking_UOM__c','Location__r.Mixed_Bins_Allowed__c','Location__r.Track_Bin_Capacity__c','Bin__r.Location__r.Mixed_Bins_Allowed__c',
                'Facility2__r.Facility_Identifier__c'
            };	
            skidFieldStrings.addAll(SkidService3.attributesForPutaway());
            skidFieldStrings.addAll(attributeSet);
            skidQuery.addFields(skidFieldStrings);
            skidQuery.addAllCustomFields(Bin__c.sObjectType,'Bin__r');
            skidQuery.addAllCustomFields(Package_Class__c.sObjectType,'Packaging_UOM__r.Package_Class__r');
            skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
            skidQuery.setWhereClause(whereClause);
            
            if (includeSerials) {
                SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
                serialQuery.addAllCustomFields();
                skidQuery.addChildRelationship(serialQuery);
            }
            
            for (SKID__c existingSkid:Database.query(skidQuery.getQuery())) {
                for (String attr:attributeList) {
                    attr = attr.toLowerCase();
                    if (!attributesToExclude.contains(attr)) {
                        DescribeFieldResult dfr = skidFields.get(attr).getDescribe();
                        if ((dfr.getType() == Schema.DisplayType.Currency || dfr.getType() == Schema.DisplayType.Double || dfr.getType() == Schema.DisplayType.Integer || dfr.getType() == Schema.DisplayType.Percent) && existingSkid.get(attr) != null) {
                            existingSkid.put(attr,((Decimal)existingSkid.get(attr)).setScale(dfr.getScale()));
                        }
                    }
                }
                
                list<String> key = generateKey(existingSkid, attributeList);
                
                if( !(existingSkidKeysMap.containsKey(key) && existingSkidKeysMap.get(key).Quantity__c > existingSkid.Quantity__c) ){
                
                    existingSkidKeysMap.put( key, existingSkid );    
                }
            
                if(skidIds.contains(existingSkid.Id)){
                    existingSkidKeysMap.put( key, existingSkid );
                }
            }
        }
        
        return existingSkidKeysMap;
    }
    //for max capacity 
    public static map<list<String>, SKID__c> generateExistingSkidMapForPutaway(list<String> attributeList, List<SKID__c> skidList, Boolean includeSerials, String additionalWhereClause){
        Map<String,Schema.SObjectField> skidFields = util.getFieldsMap('SKID__c');
        map< list<String>, SKID__c > existingSkidKeysMap = new map< list<String>, SKID__c >();
        Set<String> attributeSet = new Set<String>();
        set<Id> skidIds = new set<Id>();
        set<Id> binIds = new set<Id>();
        set<Id> LPNIds = new set<Id>();
        
        if(skidList.size() > 0){
            if( attributeList == null ){
                attributeList = new List<String>(attributesForPutaway());
            } 
            
            for(SKID__c sk : skidList ){
                if(sk.Id != null){
                    skidIds.add(sk.Id);
                }
                if(sk.bin__c != null && sk.Location__r != null && (sk.Location__r.Track_Bin_Capacity__c == true || sk.Location__r.Mixed_Bins_Allowed__c == false)){
                      binIds.add(sk.bin__c);  
                    }
                    if(sk.License_Plate_Number__c != null){
                      LPNIds.add(sk.License_Plate_Number__c);  
                    }
                    
                }
    
            attributeSet.addAll(attributeList);
            attributeSet.add('Type__c');
            
            String whereClause = ' ( ' ;
            whereClause += SchemaUtil.getQueryFilter(skidList, attributeSet);
            whereClause += ' ) ' ;

            
            string binCapacityWhereClause = ' OR (BIN__C IN :binIds AND Type__c = \'Location\')  ';
            string LPNWhereClause = 'OR License_Plate_Number__c IN :LPNIds ';
            if(!binIds.isEmpty()){
            whereClause += binCapacityWhereClause;
            }
            if(!LPNIds.isEmpty()){  
             whereClause += LPNWhereClause;   
            }
            
            
            if( additionalWhereClause != null ) 
                whereClause += additionalWhereClause;
            
            SOQLUtil skidQuery = new SOQLUtil('SKID__c');
            Set<String> skidFieldStrings = new Set<String>{ 'CreatedDate','LastModifiedDate','Location__r.Facility__r.Name','Location__r.Name','Lot__r.Name','Lot__r.Lot_Hold__c','Lot__r.Expiration_Date__c','Lot__r.Lot_Unique__c',
            	'Sales_Order_Line__r.Ship_From_Location__c','Consigned_Owner__r.Name','Purchase_Order_Line__r.Name','Company__c','Company__r.Serial_Control__c','Location__r.Bin_Tracked__c','Bin__r.Name','Location__r.Facility__c','Location__r.Nettable__c',
            	'ASN_Line__c','Company__c','Customer__c','Lot_Number__c','Material_Tracking__c','Order_Line__c','Quantity__c','Receipt_Line__c','Sales_Order_Line__c','Type__c','Unique_Key__c','Work_Order__c','Bin__r.Location__c','Item__r.Container__c','Container_Item__r.Container__c',
            	'Item__r.Non_Inventory__c','Item__r.Non_Shippable__c','Item__r.Source__c','Item__r.Item_Attribute__c','Item__r.Company__c','Item__r.Active__c','Item__r.Purchasing_UOM__c','Item__r.Stocking_UOM__c','Item__r.Track_Install_Base__c','item__r.Packaging_UOM__c','Container_Item__r.Container_Package_Class__r.Level__c',
            	'Packaging_UOM__r.Package_Class__c', 'Container_Item__r.Container_Package_Class__c', 'License_Plate_Number__c', 'Stocking_UOM__c','Shipment_Line__c', 'Shipment_Line__r.Shipment__c',
                'Bin__r.Location__r.Default_Max_Capacity__c', 'Bin__r.Location__r.Mixed_Bins_Allowed__c', 'Bin__r.Location__r.Track_Bin_Capacity__c', 'Bin__r.Location__r.Facility__r.Default_Mixed_Bins_Allowed__c',
                'Location__r.Default_Max_Capacity__c', 'Location__r.Mixed_Bins_Allowed__c', 'Location__r.Track_Bin_Capacity__c', 'Location__r.Facility__r.Default_Mixed_Bins_Allowed__c', 'Facility2__r.Facility_Identifier__c',

                'Order_Line__c', 'Order_Line__r.Order__c'
            };
            skidFieldStrings.addAll(SkidService3.attributesForPutaway());
            skidFieldStrings.addAll(attributeSet);
            skidQuery.addFields(skidFieldStrings);
            skidQuery.addAllCustomFields(Bin__c.sObjectType,'Bin__r');
            skidQuery.addAllCustomFields(Package_Class__c.sObjectType,'Packaging_UOM__r.Package_Class__r');
            skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
            skidQuery.setWhereClause(whereClause);
            // KNDY-19162
            skidQuery.setForUpdate();
            
            if (includeSerials) {
                SOQLUtil.ChildRelationship serialQuery = new SOQLUtil.ChildRelationship(skidQuery,'Serials__r');
                serialQuery.addAllCustomFields();
                skidQuery.addChildRelationship(serialQuery);
            }
            
            for (SKID__c existingSkid:Database.query(skidQuery.getQuery())) {
                for (String attr:attributeList) {
                    attr = attr.toLowerCase();
                    if (!attributesToExclude.contains(attr)) {
                        DescribeFieldResult dfr = skidFields.get(attr).getDescribe();
                        if ((dfr.getType() == Schema.DisplayType.Currency || dfr.getType() == Schema.DisplayType.Double || dfr.getType() == Schema.DisplayType.Integer || dfr.getType() == Schema.DisplayType.Percent) && existingSkid.get(attr) != null) {
                            existingSkid.put(attr,((Decimal)existingSkid.get(attr)).setScale(dfr.getScale()));
                        }
                    }
                }
                
                list<String> key = generateKey(existingSkid, attributeList);
                
                if( !(existingSkidKeysMap.containsKey(key) && existingSkidKeysMap.get(key).Quantity__c > existingSkid.Quantity__c) ){
                
                    existingSkidKeysMap.put( key, existingSkid );    
                }
            
                if(skidIds.contains(existingSkid.Id)){
                    existingSkidKeysMap.put( key, existingSkid );
                }
            }
        }
        
        return existingSkidKeysMap;
    }
    
    /**
     * @description : returns existing location skid with matching attributes by the corresponding allocated skid id.
     * the list of skids that are passed in are of type allocated
     */
    public static map<Id,SKID__c> locationSkidsForAllocatedSkids( list<SKID__c> skidList, list<String> attributes ){
        
        map<Id, SKID__c> locationSkidsPerAllocatedSkid = new map<Id,SKID__c>();
        if( attributes == null ){
            attributes = new List<String>(attributesForPutaway());
        } 
        
        for( SKID__c allocSkid : skidList ){
            
            allocSkid.Type__c = SkidService3.SKID_TYPE_LOCATION;
        }
        //( Expiration_Date__c = null or Expiration_Date__c >=:tod ) and  
        String additionalWhere = ' and (Lot__c = null OR Lot__r.Lot_Hold__c = false) and Location__r.Nettable__c = true ';
        map<list<String>, SKID__c> locationSkids = generateExistingSkidMap(attributes, skidList, true, additionalWhere);
        
        for( SKID__c allocSkid : skidList ){
            
            list<String> key = generateKey(allocSkid, attributes);
            
            if( locationSkids.containsKey( key )  ){
                
                SKID__c sk = locationSkids.get(key);
                locationSkidsPerAllocatedSkid.put( allocSkid.id, sk );
            }

        }
        
        
        return locationSkidsPerAllocatedSkid;
    }
    
    /**
     * @description : Returns a map of already allocated quantity by attributeKeys
     */
    public static map<List<String>, Decimal> allocatedQuantitiesByKey(List<SKID__c> skidList, List<String> attributes){
        
        map< list<String>, Decimal > allocatedQuantitiesByKeyMap = new map< list<String>, Decimal >();
        Set<String> attributeSet = new Set<String>();
        set<Id> skidIds = new set<Id>();
        List<SKID__c> skids = skidList.deepClone(true,true,true);
        
        if(skids.size() > 0){
            if( attributes == null ){
                attributes = new List<String>(attributesForPutaway(null, new set<String>{'shipment_line__c'}));
            } 
            
            for(SKID__c sk : skids ){
                sk.Type__c = SKID_TYPE_ALLOCATED;
            }
            
            attributeSet.addAll(attributes);
            attributeSet.add('Type__c');
            
            String whereClause = SchemaUtil.getQueryFilter(skids, attributeSet);
            
            set<String> skidFields = new set<string>{ 'id', 'quantity__c', 'location__r.facility__c', 
                                        'bin__r.location__c', 'bin__r.location__r.name', 'quantity_allocated__c',
                                        'Company__c','Company__r.Serial_Control__c','Facility2__r.Facility_Identifier__c'};
            skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'SKID__c'));
            skidFields.addAll(util.getAllCustomFieldsFromObject('Item__r.Item_Attribute__r.', 'Item_Attribute__c'));
            
            SOQLUtil soql = new SOQLUtil('SKID__c');
            soql.addFields(skidFields);
            soql.setWhereClause(whereClause);
        
            for( SKID__c allocatedSkid : (list<SKID__c>) Database.query(soql.getQuery())){
                
                list<String> key = generateKey(allocatedSkid, attributes);
                
                if( !(allocatedQuantitiesByKeyMap.containsKey(key)) ){
                    allocatedQuantitiesByKeyMap.put( key, 0 );    
                }
                allocatedQuantitiesByKeyMap.put( key,KSE.addQuantityToField(allocatedQuantitiesByKeyMap.get(key), allocatedSkid.Quantity__c));
            }
        }
        
        return allocatedQuantitiesByKeyMap;
    } 
    
    /**
     * @description : creates inventory transactions and attaches it to the skids specified in toSkids based on the matching inventory attributes.
     * Also creates serial transactions if the skids in toSkids has associated serials.
     * config map hold the variety of parameters that can specify behavior different than the default one.
     * Some of the parameters used now are adjustFromSkidQuantity, putawayDirection, serialTransactionType
     * valid  values for adjustfromskidquantity are 'positive' , 'negative' ,'none'
     * valid values for putawayDirection are 'from', 'to'
     * it list is prefilled with quantity , type, object reference and from skid info by the process controller ( e.g. receiving controller)
     * deduction from the from skid is done here with it quantity ( e.g. deducting the quantity on the PO Supply skids )
     * creates inventory trancations for putaway.
     * Also will generate Inventory Change headers for inventory transactions
     * ParameterData Hold the list of inventory transactions and the corresponding inventory change for every sourceDoc.
     * data is a map of sourceDocId with a value of ParameterData
     */
    public static void inventoryTransactionsForPutaway(Map<Id,ParameterData> data,List<String> attributes,Map<List<String>,SerialWrapper> toSkids,Map<String,String> configMap) {

        generateICsForITs(data);
        
        List<Inventory_Transaction__c> itList = new List<Inventory_Transaction__c>();
        map<Id,List<Serial__c>> fromSerialListBySkid = new map<Id,List<Serial__c>>();
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
        
        for (ParameterData d:data.values()) {
            itList.addAll(d.itList);
            
            if( d.fromSerialListBySkid != null && d.fromSerialListBySkid.keySet().size() > 0 ){
                for( id fromSkidId : d.fromSerialListBySkid.keySet() ){
                    
                    if( d.fromSerialListBySkid.get(fromSkidId) != null  && d.fromSerialListBySkid.get(fromSkidId).size() > 0 ){
                        if(!fromSerialListBySkid.containsKey(fromSkidId)){
                            fromSerialListBySkid.put(fromSkidId, new list<Serial__c>());
                        }
                        fromSerialListBySkid.get(fromSkidId).addAll( d.fromSerialListBySkid.get(fromSkidId) );
                    }
                }
            }
        }
         
        map< Id, SKID__c> updateFromSkids = new map<Id, SKID__c>();
        map< Id, SKID__c> deleteFromSkids = new map<Id, SKID__c>();
        map< Id, SKID__c> updateFromSkids_ReceiptLines = new map<Id, SKID__c>();
        set<String> processedSerials = new set<String>(); //to avoid duplicating serial transactions when skids merge.
        //e.g: receiving serial 1 on one line and serial 2 on other line, but if both serials end up belonging to the same skid, 
        //we might end up creating duplicating serial transactions as IT and ST are based on skids.
        List<SObject> stList = new list<SObject>();
        String adjustFromSkidQuantity = 'negative';
        String putawayDirection = 'to';
        String serialTransactionType = 'Receipt';
        String adjustInventoryOnSameSkid = 'false'; //copies toSkid info to fromSkid when set to true
        String deleteToSkids = 'true';
        String retainToSkidInfo = 'false';
        if( attributes == null ) attributes = attributesForPutaway();
        Boolean finalizeICs = true;
        
        if( configMap != null && configMap.size() > 0){
            if( configMap.containsKey('adjustFromSkidQuantity') ) adjustFromSkidQuantity = configMap.get('adjustFromSkidQuantity');
            if( configMap.containsKey('putawayDirection') ) putawayDirection = configMap.get('putawayDirection');
            if( configMap.containsKey('serialTransactionType') ) serialTransactionType = configMap.get('serialTransactionType');
            if( configMap.containsKey('adjustInventoryOnSameSkid') ) adjustInventoryOnSameSkid = configMap.get('adjustInventoryOnSameSkid');
            if( configMap.containsKey('doNotFinalizeICs') ) finalizeICs = false;
            if( configMap.containsKey('deleteToSkids') ) deleteToSkids = configMap.get('deleteToSkids').toLowerCase();
            if( configMap.containsKey('retainToSkidInfo') ) retainToSkidInfo = configMap.get('retainToSkidInfo').toLowerCase();
        }
        
        
        List<Inventory_Transaction__c> addlIts = new LisT<Inventory_Transaction__c>();
        Map<Id,SKID__c> toSkidMapForReceiptLineUpdate = new Map<Id,SKID__c>();
        for (Inventory_Transaction__c it:itList) {
            it.Quantity__c = it.Quantity__c.setScale(6, System.RoundingMode.HALF_UP);
            it.Quantity_Stocking_UOM__c = it.Quantity_Stocking_UOM__c.setScale(6, System.RoundingMode.HALF_UP);
            
            set<String> serialUniqueKeys = new set<String>();
            
            if(configMap != null && configMap.size() > 0 && configMap.containsKey('serialTransactionType') ) serialTransactionType = configMap.get('serialTransactionType');
            
            if((configMap== null ||( configMap!= null && !configMap.containsKey('serialTransactionType'))) && defaultSerialTransactionTypes.containsKey(it.Type__c)){
                serialTransactionType = defaultSerialTransactionTypes.get(it.Type__c);
            }
            
            List<String> key;
            if (serialTransactionType == 'WIP Translate') {
                key = generateKey(it.From_SKID__r,attributes);
                key.addAll(generateKey(it.To_SKID__r,attributes));
            } else {
                key = generateKey(it,attributes);
            }
                        
            it.Master_Id__c = getGUID();
            
            if (toSkids != null && toSkids.containsKey(key)) { //matching skid found for this inventory transaction!
                SerialWrapper sw = toSkids.get(key);
                if (sw.skid != null) {
                    it.put(putawayDirection + '_SKID__c', sw.skid.Id);
                    it.put(putawayDirection + '_Location__c', sw.skid.Location__c);
                    it.put(putawayDirection + '_Facility__c', sw.skid.Facility2__c);
                    it.putSObject(putawayDirection + '_SKID__r', sw.skid);
                    if(sw.skid.Consigned_Owner__c != null && sw.skid.Purchase_Order_Line__c !=null && configMap !=null && configMap.get('Undo transferofowner') == 'true'){
	                	toSkidMapForReceiptLineUpdate.put(sw.skid.Id,sw.skid);
	                }
                }
                
                Decimal quantity = Math.abs(it.Quantity_Stocking_UOM__c), count = 0;
                
                //Create serial transactions for the serials.
                for( Serial__c sr : sw.serialList ){
                    
                    String uniqueKey = sr.Company__c+'-'+sr.Item__c+'-'+sr.Name;
                    serialUniqueKeys.add(uniqueKey);
                    
                    if( (!processedSerials.contains(uniqueKey+'-'+serialTransactionType)) && (count<quantity || adjustInventoryOnSameSkid == 'true') ){

                        Serial_Transaction__c st = new Serial_Transaction__c(Item__c = sr.Item__c, Serial__r = new Serial__c(unique_Key2__c = uniqueKey), Facility__c = (Id)it.get('From_Facility__c'),
                                                Type__c = serialTransactionType,Inventory_Transaction__r = new Inventory_Transaction__c(Master_Id__c = it.Master_Id__c),
                                                Company__c = sr.Company__c);
                                                
                        for( String serialField : SchemaUtil.getInstance().getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes')){
                             serialField = serialField.replace( KSE.namespaceUU, '').toLowerCase().trim();
                             st.put(serialField, sr.get(SerialField));
                        }
                        
                        if ((serialTransactionType == 'WIP Translate' || serialTransactionType == 'WIP Untranslate') && sr.Temporary_Value_Holder__c != null) {
                            Id assemblyItem;

                            if (serialTransactionType == 'WIP Translate') {
                                assemblyItem = it.To_SKID__r.Item__c;
                            } else if (serialTransactionType == 'WIP Untranslate') {
                                assemblyItem = it.From_SKID__r.Item__c;
                            }

                            String parentKey = sr.Company__c + '-' + assemblyItem + '-' + sr.Temporary_Value_Holder__c;
                            st.Serial_Parent__r = new Serial__c(Unique_Key2__c = parentKey);
                        }
						/*
                        if ((serialTransactionType == 'WIP Translate' || serialTransactionType == 'WIP Untranslate') && sr.Temporary_Value_Holder__c == null) {
                            continue;
                        }*/
                        
                        if(st.Facility__c == null){
                            st.Facility__c = (Id)it.get('To_Facility__c');    
                        }                        
                        processedSerials.add(uniqueKey + '-' + serialTransactionType);//the same serial cannot be issued or received more than once in the same transaction.
                        count++;
                        stList.add(st);
                    }
                }
            }
            
            if (it.Type__c != 'Work Order Issue From WIP' && it.Type__c != 'Work Order Repair Issue From WIP' && it.Type__c != 'Work Order Return To WIP' && it.Type__c != 'Work Order Repair Return To WIP' && it.From_Lot__c == null) {
                it.From_Lot__c = it.Lot__c;
            }
            
            if(adjustInventoryOnSameSkid.equalsIgnoreCase('true')){
                it.From_SKID__c = it.to_skid__c;
                it.From_SKID__r = it.To_SKID__r;
            }
            
            SKID__c fromSkid;
            
            if( it.From_SKID__c != null && (adjustFromSkidQuantity != null || it.From_SKID__r.Quantity__c == 0) ){
                if( updateFromSkids.containsKey( it.From_SKID__c ) ){
                    fromSkid = updateFromSkids.get( it.From_SKID__c );      
                }
                else{
                    fromSkid = it.From_SKID__r.clone(true,true);
                }
            }

            if (fromSkid != null && fromSkid.Id != null && it.Type__c != 'Work Order Return To WIP' && it.Type__c != 'Work Order Repair Return To WIP') { 
                Decimal quantityToAdjust = it.Quantity__c;
                
                if( adjustFromSkidQuantity == 'negative'){
                    
                    if( fromSkid.Type__c == SkidService3.SKID_TYPE_INSTALLBASE && fromSerialListBySkid != null && fromSerialListBySkid.containsKey( fromSkid.Id ) 
                        && fromSerialListBySkid.get( fromSkid.Id ).size() > 0 ){
                            
                        quantityToAdjust = 0;    
                        
                        for( Serial__c fromSerial : fromSerialListBySkid.get( fromSkid.Id ) ){
                            String uniqueKey = fromSerial.Company__c+'-'+fromSerial.Item__c+'-'+fromSerial.Name;
                            if(serialUniqueKeys.contains(uniqueKey)){
                                quantityToAdjust++;
                            }
                        }
                    }
            
                    fromSkid.Quantity__c -= quantityToAdjust;
                    
                    if (it.Type__c == 'Work Order Assembly Uncompletion' || it.Type__c == 'Work Order Repair Assembly Uncompletion' || it.Type__c == 'Work Order Component Return' || it.Type__c == 'Work Order Repair Component Return' || it.Type__c == 'By-product Uncompletion') {
                        Decimal facilityIdentifier = it.From_Facility__c != null ? it.From_Facility__r.Facility_Identifier__c : it.To_Facility__r.Facility_Identifier__c;
                        fromSkid.Quantity_Stocking_UOM__c = fromSkid.Quantity__c * KSE.getConversionFactor(it.Item__c, facilityIdentifier, it.Packaging_UOM__c, it.Stocking_UOM__c, (List<Id>)JSON.deserialize(it.Item__r.Packaging_UOM__c, List<Id>.Class));
                    }
                }
                else if (adjustFromSkidQuantity == 'positive'){
                    fromSkid.Quantity__c += it.Quantity__c;
                }

                fromSkid.Quantity__c = fromSkid.Quantity__c.setScale(6, System.RoundingMode.HALF_UP);
                if (fromSkid.Quantity_Stocking_UOM__c != null) fromSkid.Quantity_Stocking_UOM__c = fromSkid.Quantity_Stocking_UOM__c.setScale(6, System.RoundingMode.HALF_UP);
                
                blankOutInputFieldsOnSkidPutaway(fromSkid);     
                updateFromSkids.put( fromSkid.id, fromSkid );
            }
            
            if(deleteToSkids == 'true' && (it.to_skid__c != null && ((it.to_skid__r.Quantity__c == 0 && (!doNotDeleteSkidTypes.contains( it.to_skid__r.Type__c ))) ||
                (it.to_skid__r.Quantity__c < 0 && (deleteSkidTypesIfNegative.contains( it.to_skid__r.Type__c ))))) ){
                //add to skids to the update list if the to skid needs to be deleted as well because the skid quantity is <=0 
                updateFromSkids.put( it.to_skid__c, it.to_skid__r.clone(true,true) );
            }
            if(putawayDirection == 'from' && retainToSkidInfo == 'false'){
                it.to_Location__c = null;
                it.to_facility__c = null;
                it.Bin__c = null;
            }

            if(it.From_SKID__r!=null && it.From_SKID__r.Consigned_Owner__c != null)
                updateFromSkids_ReceiptLines.put( it.From_SKID__c, it.From_SKID__r.clone(true,true));
            it.From_SKID__r = null;
            it.To_SKID__r = null;
           
           if( toSkids != null && toSkids.containsKey( key ) ){ //matching skid found for this inventory transaction!
                
                SerialWrapper sw =toSkids.get(key);
                if(sw.toskid != null ){
                    Inventory_Transaction__c itClone = it.clone(false, false);
                    itClone.Quantity__c = sw.toSkid.Quantity__c;
                    itClone.Type__c = 'Palletize'; // change this
                    
                    itclone.From_SKID__c = itClone.To_SKID__c;
                    itClone.From_SKID__r = null;
                    
                    itClone.Packaging_UOM__c = sw.toskid.Packaging_UOM__c;
                    itClone.Stocking_UOM__c = sw.toskid.Item__r.Stocking_UOM__c;
                    
                    if ( !itemPackagingUomCache.containsKey(sw.toSkid.Item__c) ) {
                        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(sw.toSkid.Item__r.Packaging_UOM__c, List<Id>.class);
                        itemPackagingUomCache.put(sw.toSkid.Item__c, lstPkgUom);
                    }
                    
                    itClone.Quantity_Stocking_UOM__c = (itClone.Quantity__c * KSE.getConversionFactor(sw.toskid.Item__c, sw.toskid.Facility2__r.Facility_Identifier__c,sw.toskid.Packaging_UOM__c, sw.toskid.Item__r.Stocking_UOM__c, itemPackagingUomCache.get(sw.toskid.Item__c ) )) ;
                    
                    itClone.Quantity__c = itClone.Quantity__c.setScale(6, System.RoundingMode.HALF_UP);
                    itClone.Quantity_Stocking_UOM__c = itClone.Quantity_Stocking_UOM__c.setScale(6, System.RoundingMode.HALF_UP);
                    sw.toSkid.Quantity__c = sw.toSkid.Quantity__c.setScale(6, System.RoundingMode.HALF_UP);
                    sw.toSkid.Quantity_Stocking_UOM__c = sw.toSkid.Quantity_Stocking_UOM__c.setScale(6, System.RoundingMode.HALF_UP);
                    
                    addlIts.add(itClone);
                    
                    // this is the skid that needs to be updated - this might be happening twice !!
                    updateFromSkids.put( sw.toSkid.Id, sw.toSkid ); // FIX THIS
                    
                }
           }
        }
        
        itList.addall(addlIts);
        
        Map<Id,SKID__c> fromSkidMapForReceiptLineUpdate = new Map<Id,SKID__c>();
        for (Id skidId:updateFromSkids.keySet()) {
            SKID__c skid = updateFromSkids.get(skidId);
            
            fromSkidMapForReceiptLineUpdate.put(skidId,skid);
            
            if ((skid.Quantity__c == 0 && !doNotDeleteSkidTypes.contains(skid.Type__c)) || 
                (skid.Quantity__c < 0 && deleteSkidTypesIfNegative.contains(skid.Type__c))) {
                    deleteFromSkids.put(skidId,skid);
                    updateFromSkids.remove(skidId);
            }
        }
        
        DML.insertAsSystem(itList);
        if (stList.size() > 0) {
            DML.insertAsSystem(stList);
        }
        
        Map<String,SerialWrapper> lstSW = new Map<String,SerialWrapper>();
        Map<String,SerialWrapper> lstSWUndo = new Map<String,SerialWrapper>();
        List<Inventory_Transaction__c> itsToConsume = new List<Inventory_Transaction__c>();
        List<Inventory_Transaction__c> itsToUnConsume = new List<Inventory_Transaction__c>();
        List<Inventory_Transaction__c> itsToUpdate = new List<Inventory_Transaction__c>();
        for (Inventory_Transaction__c it:itList) {
            Inventory_Transaction__c itToUpdate = new Inventory_Transaction__c(Id = it.Id);
            SKID__c fromSkid = updateFromSkids.get(it.From_SKID__c);
            
            if (fromSkid == null){
                fromSkid = deleteFromSkids.get(it.From_SKID__c);
            }

             if(fromSkid==null && updateFromSkids_ReceiptLines.containsKey(it.From_SKID__c) && updateFromSkids_ReceiptLines.get(it.From_SKID__c).Consigned_Owner__c != null){
                 fromSkid = updateFromSkids_ReceiptLines.get(it.From_SKID__c);
                 fromSkidMapForReceiptLineUpdate.put(fromSkid.Id,fromSkid);
             }


            if (configMap != null && fromSkid != null && fromSkid.Consigned_Owner__c != null && it.Consigned_Owner__c == null ) {
                if (configMap.get('transferofowner') == 'true') {
                    Inventory_Transaction__c itClone = it.clone(false,true);
                    itClone.Purchase_Order_Line__c = fromSkid.Purchase_Order_Line__c;
                    SerialWrapper sw = new SerialWrapper(itClone,new List<Serial_Transaction__c>());
                    lstSW.put(itClone.Master_Id__c,sw);
                }   
                itsToConsume.add(it.clone(true,true));
                itToUpdate.Consigned_Owner__c = null;
            }   
                
            if (configMap != null && fromSkid != null && fromSkid.Consigned_Owner__c == null && it.Consigned_Owner__c != null) {
            	if (configMap.get('Undo transferofowner') == 'true') {
                	Inventory_Transaction__c itClone = it.clone(false,true);
                	itClone.Shipment_Line__c = fromSkid.Shipment_Line__c;
                	
                    SerialWrapper sw = new SerialWrapper(itClone,new List<Serial_Transaction__c>());
                    lstSWUndo.put(itClone.Master_Id__c,sw);
                  }		                  
                
                itsToUnConsume.add(it.clone(true,true));
            }
            itToUpdate.Master_Id__c = null; //nulling out the external ID as the link has been done
            //if(!(it.Type__c == 'Purchase Order Receipt'))
            itsToUpdate.add(itToUpdate);
        }
        
        if (configMap != null && configMap.get('transferofowner') == 'true') {
            for (Serial_Transaction__c st:(List<Serial_Transaction__c>)stList) {
                if (lstSW.containsKey(String.valueOf(st.Inventory_Transaction__r.Master_Id__c))) {
                    lstSW.get(String.valueOf(st.Inventory_Transaction__r.Master_Id__c)).serialTransactions.add(st.clone(false,true));
                }
                if (lstSWUndo.containsKey(String.valueOf(st.Inventory_Transaction__r.Master_Id__c))) {
                    lstSWUndo.get(String.valueOf(st.Inventory_Transaction__r.Master_Id__c)).serialTransactions.add(st.clone(false,true));
                }
            }
        }

        if (itsToConsume.size() > 0) updateReceiptLinesOnConsumption(itsToConsume, fromSkidMapForReceiptLineUpdate, 'Quantity_To_Consume__c');
        if (itsToUnconsume.size() > 0) updateReceiptLinesOnConsumption(itsToUnconsume, toSkidMapForReceiptLineUpdate, 'Quantity_Consumed__c');
        
        DML.updateAsSystem(itsToUpdate);

        Set<Id> skidIds = new Set<Id>(updateFromSkids.keySet());
        skidIds.addAll(deleteFromSkids.keySet());

        List<SKID__c> skidsToUpdate = new List<SKID__c>();
        List<SKID__c> skidsToDelete = new List<SKID__c>();
        for (SKID__c skid:[SELECT Id FROM SKID__c WHERE Id IN :updateFromSkids.values() OR Id IN :deleteFromSkids.values()]) {
            if (updateFromSkids.containsKey(skid.Id)) {
                skidsToUpdate.add(updateFromSkids.get(skid.Id));
            } else if (deleteFromSkids.containsKey(skid.Id)) {
                skidsToDelete.add(skid);
            }
        }
        
        DML.updateAsSystem(skidsToUpdate);
        
        if (lstSW != null && configMap != null && configMap.get('transferofowner') == 'true')
            createConsignedTransactions(lstSW.values(),'Transfer of Ownership');
        
	    if (lstSWUndo != null && configMap != null && configMap.get('Undo transferofowner') == 'true'){
	        createConsignedTransactions(lstSWUndo.values(),'Undo Transfer of Ownership');
	    }
        DML.deleteAsSystem(skidsToDelete); 
        if (finalizeICs) {
            List<Inventory_Change__c> icList = new List<Inventory_Change__c>();
            for (ParameterData d:data.values()) {   
                if (d.inventoryChange != null) {
                    icList.add(d.inventoryChange);
                }
            }
            DML.updateAsSystem(icList);
        }
    }

    public static void deleteSkids(List<SerialWrapper> swList) {
        List<SKID__c> skidsToDelete = new List<SKID__c>();
        for (SerialWrapper sw:swList) {
            if (sw.skid != null && sw.skid.Id != null && ((sw.skid.Quantity__c == 0 && !doNotDeleteSkidTypes.contains(sw.skid.Type__c)) || (sw.skid.Quantity__c < 0 && deleteSkidTypesIfNegative.contains(sw.skid.Type__c)))) {
                skidsToDelete.add(sw.skid);
            }
        }
        if (skidsToDelete.size() > 0) DML.deleteAsSystem(skidsToDelete);
    }
    
    
    public static string getGUID()
    {
        string guid;
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        return guid;
    }
    
    public static void createConsignedTransactions(List<SerialWrapper> lstSW,String itType) {
        List<Inventory_Transaction__c> newITs = new List<Inventory_Transaction__c>();
        List<Inventory_Transaction__c> updateITs = new List<Inventory_Transaction__c>();
        List<Serial_Transaction__c> newSTs = new List<Serial_Transaction__c>();
        
        try {
            for (SerialWrapper sw:lstSW) {
                Inventory_Transaction__c itTransfer = sw.it;
                itTransfer.Type__c = itType;
                
                if(itType == 'Transfer of Ownership'){
                	itTransfer.Consigned_Owner__c = null;
                	itTransfer.to_location__c = itTransfer.from_location__c;
                	if(itTransfer.from_bin__c !=null){
                	    itTransfer.bin__c = itTransfer.from_bin__c;
                	}
                }
                else if(itType == 'Undo Transfer of Ownership'){
                	itTransfer.from_location__c =itTransfer.to_location__c;
                	if(itTransfer.bin__c !=null){
                	    itTransfer.from_bin__c =itTransfer.bin__c;
                	}
                }
                
                itTransfer.Master_Id__c = getGUID();
                
                for (Serial_Transaction__c st:sw.serialTransactions) {
                    st.Type__c = itType;
                    st.Inventory_Transaction__r = new Inventory_Transaction__c(Master_Id__c = itTransfer.Master_Id__c);
                    newSTs.add(st);
                }
                
                newITs.add( itTransfer );
            }
            
            if (newITs.size() > 0) {
                DML.insertAsSystem(newIts);
            }
            if (newSTs.size() > 0) {
                DML.insertAsSystem(newSTs);
            }
                
            for (Inventory_Transaction__c it:newITs) {
                it.Master_Id__c = null;
                updateITs.add(it);
            }
            if (updateITs.size() > 0) {
                DML.updateAsSystem(updateITs);
            }
        } catch(DMLException ex) {
            throw new SkidService3Exception(ex.getMessage());   
        }
    }
    
    
    
    public static void updateReceiptLinesOnConsumption( List<Inventory_Transaction__c> itList  ,Map<id,Skid__c> fromSkidMapForReceiptLineUpdate, String searchfield){
        map<Id, Decimal> quantityConsumedPerPOLine = new map< Id, Decimal>(); 
        
        map<Id, list<Receipt_Line__c>> receiptLinesByPOLine = new map<Id, list<Receipt_Line__c>>();
        list<Receipt_Line__c> rlListForUpdate = new list<Receipt_Line__c>();
        
        for(Inventory_Transaction__c it:itList){
            Id skidId = it.From_Skid__c;
            if(searchfield == 'Quantity_Consumed__c'){
             	skidId = it.To_Skid__c;
            }
            if( !quantityConsumedPerPOLine.containsKey(fromSkidMapForReceiptLineUpdate.get(skidId).Purchase_Order_Line__c ))
                    quantityConsumedPerPOLine.put( fromSkidMapForReceiptLineUpdate.get(skidId).Purchase_Order_Line__c, it.Quantity__c );
            else
                quantityConsumedPerPOLine.put( fromSkidMapForReceiptLineUpdate.get(skidId).Purchase_Order_Line__c, 
                    quantityConsumedPerPOLine.get(fromSkidMapForReceiptLineUpdate.get(skidId).Purchase_Order_Line__c) + it.Quantity__c );
                        
            
        }
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        Set<Id> polIds = quantityConsumedPerPOLine.keySet();
        set<string> stat = new set<string>{'Cancelled','Void'};
        SOQLUtil soql = new SOQLUtil('Receipt_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Quantity_Received__c','Quantity_Consumed__c','Quantity_To_Consume__c','Uninvoiced_Quantity__c','Purchase_Order_Line__c',
            'Purchase_Order_Line__r.Quantity_To_Stock__c','Purchase_Order_Line__r.Order_Quantity__c','Purchase_Order_Line__r.Purchase_UOM__c',
            'Purchase_Order_Line__r.Purchase_UOM__r.Name','Purchase_Order_Line__r.Item__r.Stocking_UOM__c','Purchase_Order_Line__r.Item__r.Stocking_UOM__r.Name',
            'Purchase_Order_Line__r.Delivery_Facility__r.Facility_Identifier__c'
        });
        soql.setWhereClause('Purchase_Order_Line__c IN :polIds and '+ searchfield+ ' > 0 and status__c not in :stat');
        soql.setOrderByClause('CreatedDate');

        list<Receipt_Line__c> receiptLines = Database.query(soql.getQuery());
        
        for( Receipt_Line__c rl : receiptLines ){
            
            if(! receiptLinesByPOLine.containsKey( rl.Purchase_Order_Line__c ) )
                receiptLinesByPOLine.put( rl.Purchase_Order_Line__c, new list<Receipt_Line__c>() );
            
            receiptLinesByPOLine.get( rl.Purchase_Order_Line__c ).add(rl);
        }
        
        
        for( Id polId : quantityConsumedPerPOLine.keySet() ){
        	Decimal quantityToConsume;
        	Decimal quantityToFill;
        	 
        	if(searchfield == 'Quantity_Consumed__c'){
        		quantityToFill = quantityConsumedPerPOLine.get( polId );
        	}
        	else{
        		quantityToConsume = quantityConsumedPerPOLine.get( polId );
        	}
            
            
            if( receiptLinesByPOLine.containsKey( polId ) ){
                
                for( Receipt_Line__c rl : receiptLinesByPOLine.get( polId )){
                    
                    Decimal conversionFactor = KSE.getConversionFactorFromQuantity(rl.Purchase_Order_Line__r.Quantity_To_Stock__c,rl.Purchase_Order_Line__r.Order_Quantity__c);//KSE.getConversionFactor(rl.Purchase_Order_Line__r);
                    
                    if( quantityToConsume > 0 ){
                        
                        Decimal quantityToAssign = Math.min(rl.Quantity_To_Consume__c, quantityToConsume/conversionFactor );
                        
                        rl.quantity_Consumed__c = KSE.addQuantityToField(rl.quantity_Consumed__c, 
                                                    quantityToAssign);
                        rl.Uninvoiced_Quantity__c = KSE.addQuantityToField(rl.Uninvoiced_Quantity__c, quantityToAssign);                            
                        
                        quantityToConsume -= Math.min(rl.Quantity_To_Consume__c, quantityToConsume/conversionFactor );
                       
                        rlListForUpdate.add( rl );
                    } 
                    
                    if(quantityToFill > 0){
                    	Decimal quantityToAssign = Math.min(rl.Quantity_Consumed__c, quantityToFill/conversionFactor );
                        rl.quantity_Consumed__c = KSE.addQuantityToField(rl.quantity_Consumed__c, 
                                                    -quantityToAssign);
                        rl.Uninvoiced_Quantity__c = KSE.addQuantityToField(rl.Uninvoiced_Quantity__c, -quantityToAssign);  
                        if(rl.Uninvoiced_Quantity__c < 0){
                        	throw new SkidService3Exception('You cannot undo pick more than uninvoiced quantity. ');
                        }
                        else if(rl.Uninvoiced_Quantity__c == 0){
                        	rl.Uninvoiced_Quantity__c = null;
                        }                         
                       
                        quantityToFill -= Math.min(rl.Quantity_Consumed__c, quantityToFill/conversionFactor );
                        rlListForUpdate.add( rl );
                   }                            
                }
            }
        }
        
        DML.allowUpdateFields( new list<string>{'quantity_Consumed__c','Uninvoiced_Quantity__c'}, Receipt_Line__c.SobjectType );
        DML.sobjectUpdate( rlListForUpdate);                                        
    }
    
    
    /**
     * @description : generates the key based on passed attributes for skids or inventory transactions
     */
    public static List<String> generateKey(sObject itSkid,List<String> attributes) {
        return generateKey(itSkid,attributes, null);
    }
    public static List<String> generateKey(sObject itSkid,List<String> attributes, map<String,String> configMap) {
        Map<String,Schema.SObjectField> fieldMap;
        if (itSkid.getSObjectType() == Inventory_Transaction__c.sObjectType) fieldMap = util.getFieldsMap('Inventory_Transaction__c');
        if (itSkid.getSObjectType() == SKID__c.sObjectType) fieldMap = util.getFieldsMap('SKID__c');
        if (itSkid.getSObjectType() == Operation_Transaction__c.sObjectType) fieldMap = util.getFieldsMap('Operation_Transaction__c');

        List<String> keyList = new List<String>();
        Set<String> attributesSet = new Set<String>();
        if (attributes == null) attributes = SkidService3.attributes;
        attributesSet.addAll(attributes);
        
        String putawayDirection = 'To';
        if( configMap != null && configMap.size() > 0){
            if( configMap.containsKey('putawayDirection') ) putawayDirection = configMap.get('putawayDirection');
        }
        
        for (String attributeName:attributesForPutaway()) {
            if (attributesSet.contains(attributeName)) {
                attributesSet.remove(attributeName);
                
                if (itSkid.getSObjectType() == Inventory_Transaction__c.sObjectType) {
                    if (attributeName == 'Location__c') {
                        attributeName = putawayDirection+'_Location__c';
                    } else if (attributeName == 'Facility2__c') {
                        attributeName = putawayDirection+'_Facility__c';
                    }
                    else if( attributeName == 'Packaging_UOM__c' && putawayDirection.toLowerCase() == 'from' ){
                        attributeName = putawayDirection+'_Packaging_UOM__c';
                    }
                } else if (itSkid.getSObjectType() == Operation_Transaction__c.sObjectType) {
                    if (attributeName == 'Facility2__c') {
                        attributeName = 'Facility__c';
                    }
                }

                if (!attributesToExclude.contains(attributeName.toLowerCase())) {
                    if (attributeName == 'Lot_Number__c') {
                        keyList.add(itSkid.get('Lot__c') + '');
                    } else if (fieldMap.containsKey(attributeName)) {
                        if (fieldMap.get(attributeName).getDescribe().getType() == Schema.DisplayType.Boolean && itSkid.get(attributeName) == null) {
                            keyList.add('' + false);
                        } else {
                            keyList.add(itSkid.get(attributeName) + '');
                        }
                    } else {
                        keyList.add('null');
                    }
                }
            }
        }
        
        if (attributesSet.size() > 0) {
            for (String attributeName:attributesSet) {
                if (!attributesToExclude.contains(attributeName.toLowerCase())) {
                    if (fieldMap.get(attributeName).getDescribe().getType() == Schema.DisplayType.Boolean && itSkid.get(attributeName) == null) {
                        keyList.add('' + false);
                    } else {
                        keyList.add(itSkid.get(attributeName) + ''); 
                    }
                }
            }
        }
        
        return keyList;
    }
    
    /**
     * @description : generates the key based on passed attributes for skids or inventory transactions
     */
    public static List<String> generateKeyfromFieldMap(sObject itSkid,List<String> attributes,Map<String,Schema.SObjectField> fieldMap,List<String> attributesForPutaway,Map<String,Schema.DisplayType> fieldTypemap) {
        
        List<String> keyList = new List<String>();
        Set<String> attributesSet = new Set<String>();
        if (attributes == null){
        	 attributesSet.addAll(attributesForPutaway);
        }
        else{
        	attributesSet.addAll(attributes);
        }
        
        
        for (String attributeName:attributesForPutaway) {
            if (attributesSet.contains(attributeName)) {
                attributesSet.remove(attributeName);
                
                if (itSkid.getSObjectType() == Inventory_Transaction__c.sObjectType && attributeName == 'Location__c') {
                    attributeName = 'To_Location__c';
                }

                if (!attributesToExclude.contains(attributeName.toLowerCase())) {
                    if (attributeName == 'Lot_Number__c') {
                        keyList.add(itSkid.get('Lot__c') + '');
                    } else if (fieldMap.containsKey(attributeName)) {
                        if (fieldTypemap.get(attributeName) == Schema.DisplayType.Boolean && itSkid.get(attributeName) == null) {
                            keyList.add('' + false);
                        } else {
                            keyList.add(itSkid.get(attributeName) + '');
                        }
                    }
                }
            } else {
                keyList.add('null');
            }
        }
        
        if (attributesSet.size() > 0) {
            for (String attributeName:attributesSet) {
                if (!attributesToExclude.contains(attributeName.toLowerCase())) {
                    if (fieldTypemap.get(attributeName) == Schema.DisplayType.Boolean && itSkid.get(attributeName) == null) {
                        keyList.add('' + false);
                    } else {
                        keyList.add(itSkid.get(attributeName) + ''); 
                    }
                }
            }
        }
        
        return keyList;
    }
    
    /**
     * @description : Constructs a map of allocated quantity based on attribute keys from the allocated skids that are passed in
     */
    public static Map<List<String>, Decimal> calculateAllocatedQty( list<SKID__c> allocatedSkids ){
        
         Map<List<String>, Decimal> allocatedQty = new  Map<List<String>, Decimal>();
        
        for( SKID__c sk : allocatedSkids ){
            List<String> key =  generateKey(sk, null);
            
            if( !allocatedQty.containsKey( key )){
                
                allocatedQty.put( key, 0);
            }
            allocatedQty.put( key, KSE.addQuantityToField(allocatedQty.get( key ) , sk.Quantity__c) );
        }
        return allocatedQty;
    }
    
    /**
     * @description : calculates the available quantity for each skid. As the same skid might appear multiple times on different lines,
     * the available quantity should vary for each occurence. If the allocatedQty map is passed in, it will also deduct the allocated quantity
     * from the available quantity.
     */
    public static void calculateQuantityAvailable( SKID__c qtySkid, map<Id, Decimal> quantityBySkid, Map<List<String>, Decimal> allocatedQty, String availableField, Decimal conversionFactor ){

        if( quantityBySkid.containsKey( qtySkid.id )){
            qtySkid.put( availableField, (quantityBySkid.get(qtySkid.id) / conversionFactor).setscale(6,System.RoundingMode.HALF_UP) );
        }
        else {
            qtySkid.put( availableField, (qtySkid.Quantity__c/conversionFactor).setscale(6,System.RoundingMode.HALF_UP) );
        }
            
        if( allocatedQty != null ){
            List<String> skidKey = generateKey(qtySkid, null);
             
            if( allocatedQty.containsKey(skidKey) ){
                Decimal quantityAllocated = Math.min((Decimal)qtySkid.get( availableField), allocatedQty.get(skidKey)/conversionFactor );
                allocatedQty.put( skidKey , (allocatedQty.get(skidKey)/conversionFactor) - quantityAllocated  );
                qtySkid.put( availableField, (Decimal)qtySkid.get(availableField) - quantityAllocated );
                 
                if( allocatedQty.get(skidKey) == 0 ) allocatedQty.remove(skidKey);
            } 
        }  
        quantityBySkid.put( qtySkid.id, (Decimal)qtySkid.get(availableField) );
    }
    
    /**
     * @description : Checks if all the required attributes are populated on the skid that is passed in. Only the tracked attributes should be passed in.
     * The default error message can also be passed in , which will be used with the field label prepended. The minimum shelf life if applicable should also be
     * passed in. The header sobject is the source document line, which can be passed in to support the below mentioned feature.
     * 
     * New feature: The tracked attributes ensure that the attribute is populated. For e.g. if color is a custom attribute, the system ensures that color is populated.
     * If we want to ensure that for a particular line, only red color can be accepted, then we need to create a field on the source document line called color (same 
     * name as the attribute) and populate red in that field on the source document line. This method will ensure that only red is allowed.
     */
    public static Boolean checkRequiredAttributes(SKID__c sk,List<String> attributes,sObject header,Integer minimumShelfLife,String errorMessage) {
        Map<String,Schema.SObjectField> skidFields = util.getFieldsMap('SKID__c');
        
        String errMsg = ' is required';
        if (errorMessage != null) {
            errMsg = errorMessage;
        } else if (header != null) {
            errMsg += ' for line: ' + (String)header.get('Name');
        }

        String str = JSON.serialize(header).toLowerCase();
        Map<String,Object> obj = (Map<String,Object>)JSON.deserializeUntyped(str);  //Deserialize it back into a key/value map

        Map<String, Object> itemAttributeMap;
        if ( sk.Item__r.Item_Attribute__r != null){
            itemAttributeMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sk.Item__r.Item_Attribute__r) );
        }

        String namespace = KSE.namespace.toLowerCase();
        for (String attr:attributes) {
            attr = attr.toLowerCase();
            if (attributesToExclude.contains(attr) == false) {
                if (skidFields.get(attr).getDescribe().getType() != Schema.DisplayType.Boolean && ((attr == 'license_plate_number__c' && sk.License_Plate_Number__c == null && String.isBlank(sk.Temporary_LPN_Holder__c) == true) || (attr != 'license_plate_number__c' && String.isBlank(String.valueOf(sk.get(attr))) == true))) {
                    throw new CustomException(skidFields.get(attr).getDescribe().getLabel() + errMsg);
                }
                
                if (header != null && itemAttributeMap != null) {
                    // KNDY-17641
                    if ((obj.containsKey(namespace + '__' + attr) || obj.containsKey(attr)) && header.get(attr) != null
                           && ( itemAttributeMap.containsKey(namespace + '__' + attr) || itemAttributeMap.containsKey(attr) ) ) {
                        if (skidFields.get(attr).getDescribe().getType() == Schema.DisplayType.Boolean && sk.get(attr) == null) {
                            Boolean attrValue;
                            attrValue = false;
                            if( attrValue != header.get(attr))
                                throw new SkidService3Exception(attr + ': ' + Label.Attribute_value_does_not_match + (String)header.get('Name'));
                        } else {
                            if(sk.get(attr)  != header.get(attr))
                                throw new SkidService3Exception(attr + ': ' + Label.Attribute_value_does_not_match + (String)header.get('Name'));
                        }
                        
                    }
                }
            }
        }
            
        if (minimumShelfLife != null) {
            Date min = System.today() + minimumShelfLife;
                                
            if (sk.Item__r.Item_Attribute__c != null && sk.Item__r.Item_Attribute__r.Minimum_Shelf_Life_in_Days__c == true && sk.Expiration_Date__c != null && sk.Expiration_Date__c < min) {
                throw new SkidService3Exception(Label.Expiration_Date_less_than_Minimum_Shelf_life + (String)header.get('Name') + ': ' + min.format());                                    
            } 
        }
        return false;
    }
    
    /**
     * @description : Constructs the lot unique key from the sobject that is passed in. Currently the sobjects that are passed in are skids or lots.
     * The sobject's item's company must be queried and populated.
     */
    public static List<String> lotUniqueKey( SObject lotInfo){
        
        String lotName;
        if( lotInfo.getSObjectType() == Lot__c.sObjectType ) lotName = (String)lotInfo.get('Name');
        else
            lotName = (String)lotInfo.get('Lot_Number__c');
        
        return new List<String>{(lotName+'').toUpperCase() , lotInfo.get('Item__c')+'' , getCompanyFromSObject(lotInfo)+'' , lotInfo.get('Expiration_Date__c')+''};
    }
    
    /**
     * @description : Gets the company from the sobject
     */
    public static Id getCompanyFromSObject( SObject sobj ) {
        
        Id companyId = AccountingRuleService.getValue('Company__c', sobj );
        
        if(companyId == null){
            throw new SkidService3Exception(Label.Expected_Not_Null_Company);
        }    
            
        return companyId; 
    }
    
    /**
     * @description : Creates and uncommitted lot sobject with the attributes populated from the passed in skid and supplier id.
     * The skid's item attribute record needs to be queried.
     */
    public static Lot__c populateLotNames(SKID__c skid, Id supplierId) {
        Lot__c lot;
        if (skid.Lot_Number__c != null && skid.Item__r != null && skid.Item__r.Item_Attribute__r != null && skid.Item__r.Item_Attribute__r.Lot_Number__c) {
            skid.Lot_Number__c = skid.Lot_Number__c.toUpperCase();

            lot = new Lot__c(
                Name = skid.Lot_Number__c,
                Item__c = skid.Item__c,
                Supplier__c = supplierId,
                Expiration_Date__c = skid.Expiration_Date__c,
                Company__c = getCompanyFromSObject(skid),
                Lot_Hold__c = false
            );
            lot.Item__r = new Item__c(Id = skid.Item__c);
        }
        return lot;
    }
    
    /**
     * @description : Queries existing lots and creates new lots if it does not exist. Returns a map of committed lot records based on lot unique key.
     */
    public static Map<List<String>, Lot__c> createLots(List<Lot__c> lots) {
        Map<List<String>, Lot__c> inputLotMap = new Map<List<String>, Lot__c>();
        Set<String> uniqueLotNames = new Set<String>();

        for (Lot__c lot:lots) {
            List<String> lotKey = lotUniqueKey(lot);
            inputLotMap.put(lotKey, lot);
            uniqueLotNames.add(lot.Name);
        }

        SOQLUtil lotQuery = new SOQLUtil('Lot__c');
        lotQuery.addAllCustomFields();
        lotQuery.setWhereClause('Name IN :uniqueLotNames');
        
        for (Lot__c existingLot:Database.query(lotQuery.getQuery())) {
            existingLot.Name = existingLot.Name.toUpperCase();
            
            List<String> lotKey = lotUniqueKey(existingLot);
            if (inputLotMap.containsKey(lotKey)) inputLotMap.put(lotKey, existingLot);
        }
        DML.upsertAsSystem(); upsert inputLotMap.values();
        
        return inputLotMap;
    }
    
    public static map<String, LPN__c> createLPNs( map<String, LPN__c> inputLPNMap ){
        
        set<String> lpnNames = inputLPNMap.keySet();
        
        SOQLUtil lpnQuery = new SOQLUtil('LPN__c');
        lpnQuery.addFields(new set<String>{'Id','Name'});
        lpnQuery.setWhereClause('Name IN :lpnNames');
        
        for(LPN__c existingLPN : Database.query(lpnQuery.getQuery())) {
            
            if (inputLPNMap.containsKey(existingLPN.Name)) inputLPNMap.put(existingLPN.Name, existingLPN);
        }
        DML.upsertAsSystem(); upsert inputLPNMap.values();
        
        return inputLPNMap;
    }
    
    /**
     * @description : Constructs an uncommitted InventoryTransaction sobject populated with attributes from the fromSkid, toSkid. Also populates the type of IT and 
     * the sourceDocument reference that is passed in. The values are copied from the toSkid based on the attributeFields that are passed in. If attributeFields is
     * null, it uses the default set of attributes.
     * 
     * NOTE: If to skid is null, the implementation should set the UOM's ( Stocking and Packaging)
     */
    public static Inventory_Transaction__c createInventoryTransaction(sObject sourceDocument, String transactionType, Decimal quantity, SKID__c fromSkid, SKID__c toSkid, List<String> attributes) {
        return createInventoryTransaction((toSkid != null && toSkid.Item__r != null) ? toSkid.Item__r : ((fromSkid != null && fromSkid.Item__r != null) ? fromSkid.Item__r : null), sourceDocument, transactionType, quantity, fromSkid, toSkid, attributes);
    }
    public static Inventory_Transaction__c createInventoryTransaction(Item__c item, sObject sourceDocument, String transactionType, Decimal quantity, SKID__c fromSkid, SKID__c toSkid, List<String> attributes) {
        Id companyId;
        Id sourceDocId = sourceDocument.Id;
        String sourceDocField = sourceDocId.getSObjectType().getDescribe().getLocalName();

        if (sourceDocField.equalsIgnoreCase('Material_Tracking__c')) {
            companyId = (Id)sourceDocument.getSObject('Work_Order__r').get('Company__c');
        } else if (sourceDocField.equalsIgnoreCase('Order_Line__c')) {
            companyId = (Id)sourceDocument.get('Shipping_Company__c');
        } else {
            companyId = (Id)sourceDocument.get('Company__c');
        }

        if (String.isBlank(companyId)) {
            throw new SkidService3Exception('No company found on the source document: ' + sourceDocId);
        }
        
        Inventory_Transaction__c it = new Inventory_Transaction__c(
            Company__c = companyId,
            Finalized__c = true,
            Quantity__c = quantity.setScale(6, System.RoundingMode.HALF_UP),
            Transaction_Date__c = System.now(),
            Type__c = transactionType
        );
        it.put(sourceDocField, sourceDocId);
        if (item != null) {
            it.Item__c = item.Id;
            it.Item__r = item;
            it.Stocking_UOM__c = item.Stocking_UOM__c;
        }

        if (it.Type__c == 'Adjustment') {
            if (it.Quantity__c >= 0) {
                it.Type__c = 'Adjustment Increase';
            } else {
                it.Type__c = 'Adjustment Decrease';
            }
        }
	    	        	
        if (toSkid != null) copyToSkidAttributesToIT(it, toSkid, attributes);   
        if (fromSkid != null) {
            it.From_SKID__c = fromSkid.Id;
            it.From_SKID__r = fromSkid.clone(true, true);
            it.From_Facility__c = fromSkid.Facility2__c;
            it.From_Facility__r = fromSkid.Facility2__r;
            it.From_Location__c = fromSkid.Location__c;
            it.From_Bin__c = fromSkid.Bin__c;
            it.From_Lot__c = fromSkid.Lot__c;
            it.From_Packaging_UOM__c = fromSkid.Packaging_UOM__c;
            if (it.Packaging_UOM__c == null) it.Packaging_UOM__c = fromSkid.Packaging_UOM__c;
        }
        
        if (item != null) {
            Id pkgUom = (it.Type__c == 'Work Order Issue From WIP' || it.Type__c == 'Work Order Repair Issue From WIP') && it.Item__c != it.To_SKID__r.Item__c ? it.From_Packaging_UOM__c : it.Packaging_UOM__c;
            Decimal facilityId = (it.To_Facility__r != null && it.To_Facility__r.Facility_Identifier__c != null) ? it.To_Facility__r.Facility_Identifier__c : ((it.From_Facility__r != null && it.From_Facility__r.Facility_Identifier__c != null) ? it.From_Facility__r.Facility_Identifier__c : null);
            it.Quantity_Stocking_UOM__c = (it.Quantity__c * KSE.getConversionFactor(item.Id, facilityId, pkgUom, item.Stocking_UOM__c, (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class))).setScale(6, System.RoundingMode.HALF_UP);
        }
        
        return it;
    }
    
    /**
     * @description : Copies the attributes from the Skid to the Inventory transaction based on the attribute list that is passed in
     */
    public static void copyToSkidAttributesToIT(Inventory_Transaction__c it, SKID__c toSkid, List<String> attributes) {
        Map<String,Schema.SObjectField> itFields = util.getFieldsMap('Inventory_Transaction__c');

        if (attributes == null) attributes = attributesForPutaway();

        it.To_Facility__c = toSkid.Facility2__c;
        it.To_Facility__r = toSkid.Facility2__r;
        it.To_Location__c = toSkid.Location__c;
        it.To_SKID__c = toSkid.Id;
        it.To_SKID__r = toSkid.clone(true, true);

        if ( it.To_SKID__r.Mixed_Palletized__c ) {
            it.Mixed_Palletized__c = it.To_SKID__r.Mixed_Palletized__c;
        }

        for (String attr:attributes) {
            attr = attr.toLowerCase();
            if (attributesToExclude.contains(attr) == false && attr != 'facility2__c' && attr != 'location__c' && attr != 'purchase_order_line__c' && toSkid.get(attr) != null && it.get(attr) == null) {
                it.put(attr, toSkid.get(attr));
            }
        }
    }

    public static SKID__c copyAttributes(SKID__c source, List<String> attributes) { return copyAttributes(source, null, attributes, null); }
    public static SKID__c copyAttributes(SKID__c source, List<String> attributes, Set<String> attrsToIgnore) { return copyAttributes(source, null, attributes, attrsToIgnore); }
    public static SKID__c copyAttributes(SKID__c source, SKID__c target, List<String> attributes) { return copyAttributes(source, target, attributes, null); }
    public static SKID__c copyAttributes(SKID__c source, SKID__c target, List<String> attributes, Set<String> attrsToIgnore) {
        if (target == null) target = new SKID__c();
        if (attrsToIgnore == null) attrsToIgnore = new Set<String>();

        for (String attr:attributes) {
            if (attrsToIgnore.contains(attr) == true || source.get(attr) == null || target.get(attr) != null) continue;

            target.put(attr, source.get(attr));
            if (attr == 'Lot__c' && source.Lot__c != null) target.Lot_Number__c = source.Lot__r != null ? source.Lot__r.Name : source.Lot_Number__c;
            if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                attr = attr.replace('__c', '__r');
                target.putSObject(attr, source.getSObject(attr));
            }
        }

        return target;
    }
    
    /**
     * @description : Copies the attributes from the IT to the Skid based on the attribute list that is passed in
     */
    public static void copyITAttributesToSkid(SKID__c skid, Inventory_Transaction__c it, List<String> attributes) { generateSkids(it, attributes, null, skid); }
    public static SKID__c generateFromSkid(Inventory_Transaction__c it, List<String> attributes) { return generateItSkids(it, attributes).get('FROM'); }
    public static SKID__c generateToSkid(Inventory_Transaction__c it, List<String> attributes) { return generateItSkids(it, attributes).get('TO'); }
    public static Map<String, SKID__c> generateItSkids(Inventory_Transaction__c it, List<String> attributes) { return generateItSkids(it, attributes, null, null); }
    public static Map<String, SKID__c> generateItSkids(Inventory_Transaction__c it, List<String> attributes, SKID__c fromSkid, SKID__c toSkid) {
        List<SKID__c> skids = generateSkids(it, attributes, fromSkid, toSkid);
        return new Map<String, SKID__c>{ 'FROM' => skids[0], 'TO' => skids[1] };
    }
    public static SKID__c generateOtSkid(Operation_Transaction__c ot, List<String> attributes) { return generateSkids(ot, attributes, null, null)[0]; }
    private static List<SKID__c> generateSkids(sObject obj, List<String> attributes, SKID__c skid1, SKID__c skid2) {
        if (skid1 == null) skid1 = new SKID__c();
        if (skid2 == null) skid2 = new SKID__c();
        if (attributes == null) attributes = SkidService3.attributes;

        for (String attr:attributes) {
            if (sourceDocumentLineTypes.contains(attr.toLowerCase()) == true) continue;

            String attr1;
            String attr2;
            if (obj.getSObjectType() == Inventory_Transaction__c.sObjectType) {
                attr1 = fromAttributes.containsKey(attr) == true ? fromAttributes.get(attr) : attr;
                attr2 = toAttributes.containsKey(attr) == true ? toAttributes.get(attr) : attr;
            } else {
                attr1 = attr == 'Facility2__c' ? 'Facility__c' : (otFieldMap.containsKey(attr) == true ? attr : null);
            }

            if (attr1 != null && obj.get(attr1) != null) {
                skid1.put(attr, obj.get(attr1));
                if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                    String refField = attr1.replace('__c', '__r');
                    if (attr == 'Lot__c') skid1.Lot_Number__c = (String)obj.getSObject(refField).get('Name');
                    skid1.putSObject(attr.replace('__c', '__r'), obj.getSObject(refField));
                }
            }

            if (attr2 != null && obj.get(attr2) != null) {
                skid2.put(attr, obj.get(attr2));
                if (skidFieldMap.get(attr).getDescribe().getType() == Schema.DisplayType.Reference) {
                    String refField = attr2.replace('__c', '__r');
                    if (attr == 'Lot__c') skid2.Lot_Number__c = (String)obj.getSObject(refField).get('Name');
                    skid2.putSObject(attr.replace('__c', '__r'), obj.getSObject(refField));
                }
            }
        }

        return new List<SKID__c>{ skid1, skid2 };
    }
    
    /**
     * @description : Collects the stock movement rule fields specified in the Stock_Movement_Rule_Settings__c custom setting to include in queries
     */
    public static set<String> getStockMovementRuleFields( String sourceDocument ){
        
        set<String> fieldStrings = new set<string>();
        
        for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
        
            if( smrs.Source_Document__c == sourceDocument ){
                
                if( smrs.Source_Document_Path__c == null || smrs.Source_Document_Path_Putaway__c == null ){
                    throw new SkidService3Exception(Label.Source_Document_Path_Fields_Not_Populated);
                }
                
                string sDocPath = smrs.Source_Document_Path__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),'');
                string sDocPathPutaway = smrs.Source_Document_Path_Putaway__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),'');
                fieldStrings.add( sDocPath );
                fieldStrings.add(sDocPathPutaway);
            }
        }
        
        return fieldStrings;
    }
    
    /**
     * @description : calls the trackedAttributes method after querying the location and item records with the necessary fields populated.
     */
    public static List<String> refreshTrackedAttr(List<String> attributeFields,Location__c location,Item__c item) {
        Location__c loc;
        if (location != null) {
            SOQLUtil locQuery = new SOQLUtil('Location__c',true);
            locQuery.addAllCustomFields();
            locQuery.addField('Facility__r.Facility_Identifier__c');
            locQuery.setWhereClause('Id = \'' + location.Id + '\'');
            loc = Database.query(locQuery.getQuery());
        }

        SOQLUtil itemQuery = new SOQLUtil('Item__c',true);
        itemQuery.addAllCustomFields();
        itemQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item_Attribute__r');
        itemQuery.addField('Class__r.Minimum_Shelf_Life_In_Days__c');
        itemQuery.setWhereClause('Id = \'' + item.Id + '\'');
        Item__c i = Database.query(itemQuery.getQuery());

        return trackedAttributes(null,loc,i);
    }
    
    /**
     * @description : Constructs the list of tracked attributes from the location and the item attribute record of the item.
     * Please ensure the item has the related item attribute record queried.
     */
    public static list<String> trackedAttributes( list<String> attributeFields, Location__c putAwayLocation, SObject item ){
        return trackedAttributes( attributeFields, putAwayLocation, item, null );
    } 
    
    /**
     * @description : Gets the LPN Item attribute from the container Item in addition to the other tracked attributes.
     */
    public static List<String> trackedAttributes(List<String> attrFields, Location__c putAwayLocation, SObject item, Item__c ContainerItem) {
        if (attrFields == null) attrFields = attributeFields;
        List<String> trackedAttrs = new List<String>();

        for (String attr:attrFields) {
            if(!attributesToExclude.contains(attr.toLowerCase())){
                if( item.get('Item_Attribute__c') != null && item.getSObject('Item_Attribute__r') != null && attr.toLowerCase() != 'license_plate_number__c' ){
                    if( item.getSObject('Item_Attribute__r').get(attr) == true && (item.get('Non_Inventory__c') !=true || item.get('Source__c') == 'Outside Processing' )){
                        
                        trackedAttrs.add( attr );
                    }
                }
            }
        }
        
        trackedAttrs.add('Packaging_UOM__c');
        
        if( item.get('Container__c') == false && containerItem != null && containerItem.getSObject('Item_Attribute__r') != null && 
            containerItem.getSObject('Item_Attribute__r').get('License_Plate_Number__c') == true ){
            
            trackedAttrs.add( 'License_Plate_Number__c' );    
        }
        
        if(putAwayLocation != null && putAwayLocation.get('Bin_Tracked__c') == true && (item.get('Non_Inventory__c') !=true || item.get('Source__c') == 'Outside Processing'))
            trackedAttrs.add( 'Bin__c');
            
        return trackedAttrs;
    }
    
     /**
     * @description : Constructs the list of tracked attributes from the location and the item attribute record of the items passed.
     * Please ensure the item has the related item attribute record queried.
     */
    public static map<Item__c,list<String>> trackedAttributes( list<String> attributeFields, Location__c putAwayLocation, list<Item__c> items ){
        
        Map<Item__c,list<String>> trackedAttributesService = new Map<Item__c,list<String>>();   
        
        if(attributeFields == null ) attributeFields = getAttributeFields();
        for(Item__c item : items){
        	list<String> trackedAttributeslist = new list<String>();
            for( String attr : attributeFields ){
                if(!attributesToExclude.contains(attr.toLowerCase())){
                    if( item.get('Item_Attribute__c') != null && item.getSObject('Item_Attribute__r') != null ){
                        if( item.getSObject('Item_Attribute__r').get(attr) == true && (item.get('Non_Inventory__c') !=true || item.get('Source__c') == 'Outside Processing' )){
                        
                            trackedAttributeslist.add(attr );
                        }
                    }
                }
            }  
            if(putAwayLocation != null && putAwayLocation.get('Bin_Tracked__c') == true && (item.get('Non_Inventory__c') !=true || item.get('Source__c') == 'Outside Processing'))
                trackedAttributeslist.add( 'Bin__c');
            
                trackedAttributesService.put( item, trackedAttributeslist);
                
        }
            
        return trackedAttributesService;
    }
    
    /**
     * @description : This method can be used to form a list of fields that needs to be shown on the UI from the Skid object.
     * The attributes to exclude can be specified in doNotDisplayAttributes. These need to be in lowercase.
     * Also additional display attributes can be specified and the boolean parameter can be used to specify if the additional attributes
     * need to be at the front or at the end of the list. If containerItem is LPN tracked, LPN attribute will be added to the SKID
     */
    public static List<String> attributesForDisplay(set<String> doNotDisplayAttributes, list<String> additonalDisplayAttributes, Boolean addAdditionalAttrAtFront, Item__c containerItem){
        
        list<String> attributes = getAttributeFields();
        list<String> attributesForDisplay = new list<String>();
        
        if(additonalDisplayAttributes != null && addAdditionalAttrAtFront){
            attributesForDisplay.addAll(additonalDisplayAttributes);
        }
        
        if(doNotDisplayAttributes == null || !doNotDisplayAttributes.contains('location__c'))attributesForDisplay.add('Location__c');
        for( String att : attributes ){
            
            if( att != 'License_Plate_Number__c' && !attributesToExclude.contains(att.toLowerCase()) && (doNotDisplayAttributes == null || !doNotDisplayAttributes.contains(att.toLowerCase()))) {
                if( att == 'Lot_Number__c')
                    attributesForDisplay.add('Lot__c');
                else    
                    attributesForDisplay.add( att );
            }
        }

        if(doNotDisplayAttributes == null || !doNotDisplayAttributes.contains('bin__c'))attributesForDisplay.add('Bin__c');
        
        if (containerItem != null && containerItem.Item_Attribute__r != null && containerItem.Item_Attribute__r.License_Plate_Number__c == true) {
            attributesForDisplay.add('License_Plate_Number__c');    
        }
        
        if(additonalDisplayAttributes != null && !addAdditionalAttrAtFront){
            attributesForDisplay.addAll(additonalDisplayAttributes);
        }
        
        return attributesForDisplay;
    }
    
    /**
     * @description : Returns all the custom fields of the item attribute object.
     */
    public static list<String> getAttributeFields(){
        
        return new list<String>(util.getAllCustomFieldsFromObject(null,'Item_Attribute__c'));
    }
    
    /**
     * @description : Calls the attributesForPutaway method with null, which will then make the method use the all the item attribute fields.
     */
    public static List<String> attributesForPutaway() {
        return attributesForPutaway(null);
    }
    
    /**
     * @description : Adds the item attribute fields and other important fields that needs to be considered for putaway and other skidservice actions.
     * This method adds lot__c if the attribute is Lot_Number__c as that is the field with the reference to the lot record.
     */
    public static List<String> attributesForPutaway(List<String> attributes) {
        return attributesForPutaway(attributes,null);
    }
    
    /**
     * @description : Performs the same actions as the other attributesForPutaway method, but also provides the ability to exclude any attributes that maybe added.
     * all the strings in additionalAttrToExclude must be in lowercase !!
     */
    public static List<String> attributesForPutaway(List<String> attributes, Set<String> additionalAttrToExclude) { return attributesForPutaway(attributes, additionalAttrToExclude, false); }
    public static List<String> attributesForPutaway(List<String> attributes,Set<String> additionalAttrToExclude, Boolean fromApi) {
        if (attributes == null) attributes = getAttributeFields();
        if (additionalAttrToExclude == null) additionalAttrToExclude = new Set<String>();

        List<String> attrFront = new List<String>{ 'Facility2__c','Item__c','Location__c', 'Customer__c' };
        List<String> attrEnd = new List<String>{ 'Bin__c','Consigned_Owner__c','Purchase_Order_Line__c','Shipment_Line__c','Receipt_Line__c','Packaging_UOM__c','Container_Item__c','Sales_Order_Line__c' };
        List<String> attr = new List<String>();

        for (String attrf:attrFront){
            if(!additionalAttrToExclude.contains(attrf.toLowerCase())) {
                attr.add(attrf);
            }
        }
        
        for (String att:attributes) {
            if (!attributesToExclude.contains(att.toLowerCase()) && !additionalAttrToExclude.contains(att.toLowerCase())) {
                if (att == 'Lot_Number__c' && fromApi == false) attr.add('Lot__c');
                else if (att == 'License_Plate_Number__c' && fromApi == true) attr.add('Temporary_LPN_Holder__c');
                else attr.add(att);
            }
        }
        
        for (String attre:attrEnd){
            if (!additionalAttrToExclude.contains(attre.toLowerCase())) {
                attr.add(attre);
            }
        }
        
        return attr;
    }
    
    /**
     * @description : This method can be used to form a list of fields that needs to be shown on the UI from the Skid object.
     * The attributes to exclude can be specified in doNotDisplayAttributes. These need to be in lowercase.
     * Also additional display attributes can be specified and the boolean parameter can be used to specify if the additional attributes
     * need to be at the front or at the end of the list.
     */
    public static List<String> attributesForDisplay(set<String> doNotDisplayAttributes, list<String> additonalDisplayAttributes, Boolean addAdditionalAttrAtFront){
        
        list<String> attributes = getAttributeFields();
        list<String> attributesForDisplay = new list<String>();
        
        if(additonalDisplayAttributes != null && addAdditionalAttrAtFront){
            attributesForDisplay.addAll(additonalDisplayAttributes);
        }
        
        if(doNotDisplayAttributes == null || !doNotDisplayAttributes.contains('location__c'))attributesForDisplay.add('Location__c');
        for( String att : attributes ){
            
            if(att != 'License_Plate_Number__c' && !attributesToExclude.contains(att.toLowerCase()) && (doNotDisplayAttributes == null || !doNotDisplayAttributes.contains(att.toLowerCase()))) {
                if( att == 'Lot_Number__c')
                    attributesForDisplay.add('Lot__c');
                else    
                    attributesForDisplay.add( att );
            }
        }

        if(doNotDisplayAttributes == null || !doNotDisplayAttributes.contains('bin__c'))attributesForDisplay.add('Bin__c');
        
        if(additonalDisplayAttributes != null && !addAdditionalAttrAtFront){
            attributesForDisplay.addAll(additonalDisplayAttributes);
        }
        
        return attributesForDisplay;
    }
    
    /**
     * @description : Validates that the Stock_Movement_Rule_Settings__c custom setting has the records for company and facility at a minimum, for 
     * the source documents specified.
     */
    public static Boolean checkRequiredStockMovementSettings( set<String> sourceDocuments ){
        
        Decimal numberOfRequiredSettings = 2;
        map<String,Decimal> actualNumberOfRequiredSettings = new map<String,Decimal>();
        Set<String> requiredSettings = new set<String>{ 'company__c', 'facility__c' }; 
    
        for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
        
            if( sourceDocuments.contains(smrs.Source_Document__c) ){
                
                if( requiredSettings.contains(( smrs.Stock_Movement_Rule_Field__c).toLowerCase()) ){
                    
                    if(!actualNumberOfRequiredSettings.containsKey(smrs.Source_Document__c)) actualNumberOfRequiredSettings.put(smrs.Source_Document__c,0);
                    
                    actualNumberOfRequiredSettings.put(smrs.Source_Document__c,actualNumberOfRequiredSettings.get(smrs.Source_Document__c)+1);
                }
            }
        }
        
        for(String sourceDoc : sourceDocuments){
             if( !actualNumberOfRequiredSettings.containsKey(sourceDoc) || actualNumberOfRequiredSettings.get(sourceDoc) != numberOfRequiredSettings  ){
                return false;
             }
        }
         
		return true;
    }
    
    //prevent deletion of LPN if  onhand inventory associated with LPN
    public static void allowLPNDelete(){
    	if(trigger.isBefore && trigger.isDelete){
    	set<id> lpnIds = new  set<id>();   
    	for(LPN__C lpn : (List<LPN__c>)Trigger.old){
    	    lpnIds.add(lpn.id);
    	}
    	
    	SOQLUtil soql = new SOQLUtil('skid__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','License_Plate_Number__c'
        });
        soql.setWhereClause('License_Plate_Number__c IN :lpnIds');
        Map<Id,skid__c> skidMap = new Map<Id, skid__c>((List<skid__c>)Database.query(soql.getQuery())); 
        map<id,id> LPNtoSkidMap = new map<id,id>();
        
        soql = new SOQLUtil('inventory_transaction__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','License_Plate_Number__c'
        });
        soql.setWhereClause('License_Plate_Number__c IN :lpnIds');
        Map<Id,inventory_transaction__c> itMap = new Map<Id, inventory_transaction__c>((List<inventory_transaction__c>)Database.query(soql.getQuery())); 
        map<id,id> LPNtoITMap = new map<id,id>();
        
        for(skid__c sk:skidMap.values()){
            if(!LPNtoSkidMap.containsKey(sk.License_Plate_Number__c)){
                LPNtoSkidMap.put(sk.License_Plate_Number__c,sk.id);
            }
        }
        for(inventory_transaction__c it:itMap.values()){
            if(!LPNtoITMap.containsKey(it.License_Plate_Number__c)){
                LPNtoITMap.put(it.License_Plate_Number__c,it.id);
            }
        }
        for(LPN__C lpn : (List<LPN__c>)Trigger.old){
    	    if(LPNtoSkidMap.containsKey(lpn.id) || LPNtoITMap.containsKey(lpn.id)){
    	       lpn.addError('You cannot delete an LPN that has any SKIDs or inventory transactions tied to it.');
    	    }
    	}
    		
    	}
    }  
    
    //prevent deletion of Bin if  onhand inventory associated with Bin
    public static void allowBinDelete(){
    	
    	set<id> binIds = new  set<id>();   
    	for(Bin__c bin : (List<Bin__c>)Trigger.old){
    	    binIds.add(bin.id);
    	}
    	
    	SOQLUtil soql = new SOQLUtil('skid__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Bin__c'
        });
        soql.setWhereClause('Bin__c IN :binIds');
        Map<Id,skid__c> skidMap = new Map<Id, skid__c>((List<skid__c>)Database.query(soql.getQuery())); 
        map<id,id> bintoSkidMap = new map<id,id>();
        
        for(skid__c sk:skidMap.values()){
            if(!bintoSkidMap.containsKey(sk.bin__c)){
                bintoSkidMap.put(sk.bin__c,sk.id);
            }
        }
       
        for(bin__C bin : (List<bin__c>)Trigger.old){
    	    if(bintoSkidMap.containsKey(bin.id) ){
    	       bin.addError('You cannot delete Bin that has any SKIDs tied to it.');
    	    }
    	}
    	
    }  
    
     //validates bin create  if location is bin tracked or not
    //validates bin create and update if location is track bin capacity true then max capacity and package UOM should not be blank
    
    public static void validateinsertUpdateBin(List<bin__c> binList){
        set<id> locationIds = new set<id>();    
        for(bin__c b:binList){
           locationIds.add(b.location__c);
        }        
    	SOQLUtil soql = new SOQLUtil('location__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Bin_Tracked__c','Track_Bin_Capacity__c'
        });
        
        soql.setWhereClause('Id IN :locationIds');
        
        
        Map<Id,location__c> locationMap = new Map<Id, location__c>((List<location__c>)Database.query(soql.getQuery()));   
        
        for(bin__c b:binList){
            if(locationMap.get(b.location__c).Bin_Tracked__c == false ) {
                b.addError('Location for this bin is not bin tracked');
            } else{
                if(locationMap.get(b.location__c).Bin_Tracked__c == true && locationMap.get(b.location__c).Track_Bin_Capacity__c == true ){
                if(b.max_capacity__c == null){
                 b.addError('Max capacity cannot be null');
                } 
                if(b.Packaging_UOM__c == null){
                 b.addError('Packaging UOM cannot be null');  
                }
            }
        }	        
        
    }
    }
    
    
    //validates bin Capacity :should not  be less than what bin is having in skids.
    
    public static void validateUpdateBinCapacity(List<bin__c> binList){
        set<id> binIds = new set<id>();    
        map<id,bin__c> binMap = new map<id,bin__c>();
        for(bin__c b:binList){
           //max capacity and pkg UOm  changing 
           if(b.Max_Capacity__c != null && b.Packaging_UOM__c != null && (KSE.isFieldChanging('Max_Capacity__c', b, trigger.oldMap) || 
						KSE.isFieldChanging('Packaging_UOM__c', b, trigger.oldMap))){
             binIds.add(b.id);  
           }
           if(!binMap.containsKey(b.id)){
              binMap.put(b.id,b); 
           }
             
        }  
       if(!binIds.isEmpty()){
            set<string> SkidTypes = new set<string>{'Location'};  
           	SOQLUtil soql = new SOQLUtil('skid__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Bin__c','Quantity__c','Packaging_UOM__c','Item__c','Item__r.Container__c','bin__r.Packaging_UOM__c','bin__r.max_capacity__c','Packaging_UOM__r.Package_Class__c','Container_Item__r.Container_Package_Class__c','Item__r.Packaging_UOM__c','Container_Item__r.Container_Package_Class__r.Level__c', 'Facility2__r.Facility_Identifier__c'
            });
            soql.setWhereClause('bin__c IN :binIds AND Type__c IN :SkidTypes');
            Map<Id,skid__c> skidMap = new Map<Id, skid__c>((List<skid__c>)Database.query(soql.getQuery())); 
            map<id,decimal> binTotalQty = new map<id,decimal>();
            Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
            for(skid__c sk:skidMap.values()){
                
                 if(sk.bin__c != null && sk.quantity__c != null && sk.bin__r.max_capacity__c != null){
                    decimal changedQty = sk.Quantity__c;
                    id changedUOM = sk.Packaging_UOM__c ;
                     //handle capacity in case we have on hand inventory in bin is part pallet.
                    list<Id> pkgUOMIds;
                    if ( !itemPackagingUomCache.containsKey( sk.Item__c ) ) {
                        pkgUOMIds = (List<Id>) JSON.deserialize(sk.item__r.Packaging_UOM__c, List<Id>.class);
                        itemPackagingUomCache.put (sk.Item__c, pkgUOMIds );
                    } else {
                        pkgUOMIds = itemPackagingUomCache.get(sk.Item__c);
                    }
                    if ( sk.Packaging_UOM__r.Package_Class__c != sk.Container_Item__r.Container_Package_Class__c && sk.Item__r.Container__c == false ){
                        
                        // if( sk.item__r.Packaging_UOM__c != null ) {
                            decimal containerClassLevel = 1;
                            
                            if(sk.Container_Item__r.Container_Package_Class__r != null ){
                                containerClassLevel = sk.Container_Item__r.Container_Package_Class__r.Level__c;
                            }
                            
                            if(pkgUOMIds.size() < containerClasslevel ){
                              throw new SkidService3Exception('Item package UOM level mismatch with container package class level');
                            }else {
                              changedUOM = pkgUOMIds[Integer.valueOf(containerClassLevel-1)];  
                            }
                        // }
                        decimal tempConFac =  KSE.getConversionFactor( sk.Item__c , sk.Facility2__r.Facility_Identifier__c,changedUOM ,  sk.Packaging_UOM__c, pkgUOMIds );  
                        changedQty =  ( sk.Quantity__c / tempConFac ).round(System.RoundingMode.CEILING);
                    }
                    
                    decimal conversionForTotal =  KSE.getConversionFactor(sk.item__c, sk.Facility2__r.Facility_Identifier__c,  binMap.get(sk.bin__c).Packaging_UOM__c , changedUOM, pkgUOMIds ) ; 
                    binTotalQty.put(sk.bin__c,(KSE.addQuantityToField(binTotalQty.get(sk.bin__c), ((changedQty / conversionForTotal).setScale(6,System.RoundingMode.HALF_UP))) )); 
                 }
            }
            for(bin__c b:binList){
                if(b.max_capacity__c < binTotalQty.get(b.id)){
                    b.addError('Cannot change bin max capacity less than '+binTotalQty.get(b.id));  
                }
            }
       }
    }
    
    public class DirectPutawayWrapper {
        //assuming putaway skid have item__c(same as stockMovementRule.item__c),Quantity__c,Packaging_UOM__c,License_Plate_Number__c,Container_Item__c
        //assuming stockMovementRule have item,source location,company,facility.
        public Stock_Movement_Rule__c stockMovementRule { get; set; }
        public skid__c putawaySkid { get; set; }
        
        public directPutawayWrapper(Stock_Movement_Rule__c stockMovementRule,skid__c putawaySkid ) {    
            this.stockMovementRule = stockMovementRule;
            this.putawaySkid = putawaySkid;
        }
    }
    
    //This method prompt with bin with enough capacity for direct putaway, also considers part pallet and match LPN and prompt with bin.
    public static map<Integer, Bin__c> availableBinForDirectPutaway(List<DirectPutawayWrapper> putawayWrapper){
    	
        map<integer, Bin__c> binMap = new map<integer, Bin__c>(); //map of indexToBIN 
        list<sObject> dummySmrs = new list<sObject>();
        set<id> itemIds = new set<id>();
        set<id> UOMIds = new set<id>();
        Set<String> sourceDocumentLineNames = new Set<String>();
        
        for(DirectPutawayWrapper dw : putawayWrapper){
        	dummySmrs.add(dw.stockMovementRule);  
        	sourceDocumentLineNames.add(dw.stockMovementRule.Source_Document__c);
        	itemIds.add(dw.stockMovementRule.item__c); 
			itemIds.add(dw.putawaySkid.Container_Item__c);
			UOMIds.add(dw.putawaySkid.Packaging_UOM__c);
        }
        
        Set<String> UOMfieldStrings = new Set<String>{'Id','Package_Class__c'};
        
        SOQLUtil soql = new SOQLUtil('UOM__c', true); //enforceFLS=true, running in user mode
        soql.addFields(UOMfieldStrings);
        soql.setWhereClause('id IN :UOMIds');
        
        map<Id, UOM__c> UOMs = new map<Id, UOM__c>((List<UOM__c>) Database.query(soql.getQuery())); 
        
        //to find matching location 
        map<string, list<Location__c>> locationMap =  locationsFromStockMovementRules(  
        												dummySmrs, 
        												'Putaway', 
        												sourceDocumentLineNames,
														null, 
														null  
													  );
		
        set<Id> locationIds = new set<Id>(); 
        list<Location__c> locationList= new list<Location__c>();
        
        for(list<Location__c> loc : locationMap.values()){
        	locationList.addAll(loc);
        }
        
        for(Location__c l : locationList){
			locationIds.add(l.id);
        }
        
        soql = new SOQLUtil('Bin__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
        	'id','Name', 'Blocked__c', 'Description__c','Location__c','max_capacity__c',
        	'location__r.Facility__r.Default_Mixed_Bins_Allowed__c','location__r.Default_Max_Capacity__c',
        	'Packaging_UOM__c','location__r.Track_Bin_Capacity__c'
        });
        soql.setWhereClause('location__c IN :locationIds AND Blocked__c = false ');
        
        set<String> fieldStrings = new set<string>{
          'id','Name','Quantity__c','Item__c','Quantity_Stocking_UOM__c','Stocking_UOM__c','Packaging_UOM__c','location__c' ,'Container_Item__r.Container_Package_Class__c' ,'License_Plate_Number__c','Packaging_UOM__r.Package_Class__c', 'Facility2__r.Facility_Identifier__c'
        };
        
        set<string> SkidTypes = new set<string>{'Location','Allocated'};  
        
        SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
        skids.addFields(fieldStrings);
        skids.setWhereClause('Type__c IN :SkidTypes');
        soql.addChildRelationship(skids);
        
        map<Id, Bin__c> bins = new map<Id, Bin__c>((List<Bin__c>)Database.query(soql.getQuery())); 
        map<Id, Bin__c> binsNotCapTracked = new map<Id, Bin__c>();
        map<Id, list<Bin__c>> locToBins = new map<Id, list<Bin__c>>();
        map<Id, set<Bin__c>> locToEmptyBin = new map<Id, set<Bin__c>>();
        map<Id, map<id,list<Bin__c>>> locToItemBins = new map<Id, map<Id, list<Bin__c>>>();
        map<Id, decimal> binTotalQty = new map<Id, decimal>();
        map<Id, Bin__c> LPNToBinMap  = new map<Id, Bin__c>();
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
        
		for(Bin__c b : bins.values() ){
            for(skid__c sk:b.SKIDs__r){
               itemIds.add(sk.Item__c); 
               itemIds.add(sk.Container_Item__c);
            } 
        }
        
        Set<String> itemfieldStrings = 	new Set<String>{
        									'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Container_Package_Class__c',  
		                                    'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c','Packaging_UOM__c','Stocking_UOM__c','Container__c',
		                                    'Stocking_UOM__r.Package_Class__c', 'Stocking_UOM__r.Package_Class__r.Default_Container_Item__c',
		                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
		                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
		                                    'Container_Item__c','Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container_Package_Class__c'
										};
        
        soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
        soql.addFields(itemfieldStrings);
        soql.addAllCustomFields();
        soql.setWhereClause('id IN :itemIds');
        
        map<Id, item__c> items = new map<Id, item__c>((List<item__c>)Database.query(soql.getQuery()));  
        
        for(Bin__c b : bins.values() ){
            if(!locToBins.containskey(b.location__c)){
                locToBins.put(b.Location__c,new List<Bin__c>()); 
            }
            
            locToBins.get(b.Location__c).add(b); 
            
            if(b.SKIDs__r.isempty()){
                if(!locToEmptyBin.containskey(b.location__c)){
                	locToEmptyBin.put(b.Location__c,new set<Bin__c>()); 
                }
                locToEmptyBin.get(b.Location__c).add(b); 
            }
           
        	for(Skid__c sk : b.SKIDs__r){
               	//setting UOMOfItem to default to skid package UOM ,in case of normal pallet we need to convert skid package UOM to BIN packaging UOM.
            
                id UOMOfItem = sk.Packaging_UOM__c;
                List<Id> lstPkgUom;
                
                if ( !itemPackagingUomCache.containskey (sk.Item__c ) ) {
                    lstPkgUom = (List<Id>) JSON.deserialize(items.get(sk.Item__c).Packaging_UOM__c, List<Id>.class);
                    itemPackagingUomCache.put(sk.Item__c, lstPkgUom );
                } else {
                    lstPkgUom = itemPackagingUomCache.get(sk.Item__c);
                }
                
                //in case of part pallet where package class of package UOM is different than container item's package class ,we need to convert skid qty to uom of container item's package class
                if(sk.Packaging_UOM__r.Package_Class__c != null && 
                	sk.Container_Item__r.Container_Package_Class__c != null  && sk.Packaging_UOM__r.Package_Class__c != sk.Container_Item__r.Container_Package_Class__c  ){
                    //we need to get UOMForPackageClass in case of part pallets.
                    UOMOfItem = getNextLevelUomId ( sk, items.get(sk.Item__c) );
                
                    decimal tempConFac =  KSE.getConversionFactor( sk.Item__c , sk.Facility2__r.Facility_Identifier__c, UOMOfItem, sk.Packaging_UOM__c,lstPkgUom  );  
                    sk.Quantity__c =  ( sk.Quantity__c / tempConFac ).round(System.RoundingMode.CEILING); 
                }
                
                decimal conversionForTotal =  KSE.getConversionFactor(sk.item__c, sk.Facility2__r.Facility_Identifier__c,  b.Packaging_UOM__c ,UOMOfItem, lstPkgUom) ;
                
                binTotalQty.put(b.id, (KSE.addQuantityToField(binTotalQty.get(b.id), ((sk.Quantity__c / conversionForTotal).setScale(6,System.RoundingMode.HALF_UP)) ) )); 
                
                if( sk.License_Plate_Number__c != null){
                	LPNToBinMap.put(sk.License_Plate_Number__c,b);
                }
                
                if(!locToItemBins.containskey(sk.location__c)){
                    locToItemBins.put(sk.Location__c,new Map<Id,List<Bin__c>>()); 
                }

                if(!locToItemBins.get(sk.location__c).containsKey(sk.item__c)) {
	                locToItemBins.get(sk.location__c).put(sk.item__c,new List<Bin__c>());
                }
    
                locToItemBins.get(sk.Location__c).get(sk.item__c).add(b);  
            }
        }
        
        for(integer i=0; i< putawayWrapper.size(); i++) {
         
            id UOMForPutAway;
            decimal quantityToPutaway = 0;
            boolean foundBin = false;
            List<Id> lstPkgUom;
            
            if ( !itemPackagingUomCache.containskey (putawayWrapper[i].putawaySkid.item__c ) ) {
            	if(putawayWrapper[i].putawaySkid.item__r != null){
            		lstPkgUom = (List<Id>) JSON.deserialize(putawayWrapper[i].putawaySkid.item__r.Packaging_UOM__c, List<Id>.class);
            	}else{
            		lstPkgUom = (List<Id>) JSON.deserialize(items.get(putawayWrapper[i].putawaySkid.item__c).Packaging_UOM__c, List<Id>.class);
            	}
            	
                itemPackagingUomCache.put(putawayWrapper[i].putawaySkid.item__c, lstPkgUom );
            } else {
                lstPkgUom = itemPackagingUomCache.get(putawayWrapper[i].putawaySkid.item__c);
            }
            
            //to match LPN with existing LPN
            if( putawayWrapper[i].putawaySkid.License_Plate_Number__c != null && LPNToBinMap.containsKey(putawayWrapper[i].putawaySkid.License_Plate_Number__c) ){
                binMap.put(i, LPNToBinMap.get(putawayWrapper[i].putawaySkid.License_Plate_Number__c));
                foundBin = true;
                continue;
            }
            
            //in case of part pallet we are getting UOM of container item's package class and converting putaway quantity accordingly.
            
            String containerItemPackageClass = items.get(putawayWrapper[i].putawaySkid.Container_Item__c).Container_Package_Class__c;
            String uomPackageClass = UOMs.get(putawayWrapper[i].putawaySkid.Packaging_UOM__c).Package_Class__c;
            
            if ( containerItemPackageClass != null && uomPackageClass != null && containerItemPackageClass != uomPackageClass){    
              
                UOMForPutAway = getNextLevelUomId ( putawayWrapper[i].putawaySkid, items.get(putawayWrapper[i].putawaySkid.item__c) );
                Decimal conversionFactor = 1 ;
                
                if(UOMForPutAway != null){
                	conversionFactor = KSE.getConversionFactor( 
                							putawayWrapper[i].stockMovementRule.item__c , 
    										putawayWrapper[i].putawaySkid.Facility2__r.Facility_Identifier__c, 
    										UOMForPutAway , 
    										putawayWrapper[i].putawaySkid.Packaging_UOM__c, 
    										lstPkgUom  
    								   );  
                }
                
               	//changing putaway  qty acc to UOM .
                quantityToPutaway = (putawayWrapper[i].putawaySkid.Quantity__c / conversionFactor).round(System.RoundingMode.CEILING);
                
            } else {
            	quantityToPutaway =  putawayWrapper[i].putawaySkid.Quantity__c;   
            	UOMForPutAway =  putawayWrapper[i].putawaySkid.Packaging_UOM__c;
            }
            
            list<Location__c> matchLocationList = locationMap.containsKey(String.valueOf(i)) ? locationMap.get(String.valueOf(i)) : new list<Location__c>();
            
            if(items.containskey( putawayWrapper[i].stockMovementRule.item__c)){
                putawayWrapper[i].stockMovementRule.item__r = items.get(putawayWrapper[i].stockMovementRule.item__c); 
            }
               
            list<Bin__c> allBins = new list<Bin__c>();
              
            for(Location__c l : matchLocationList){
                
                if(l.Mixed_Bins_Allowed__c == true){
                    allBins.addAll(locToBins.get(l.id));        
                }else {
                    if(locToItemBins.containsKey(l.id) && locToItemBins.get(l.id).containsKey(putawayWrapper[i].stockMovementRule.item__c)){
						allBins.addAll(locToItemBins.get(l.id).get( putawayWrapper[i].stockMovementRule.item__c));
                    } 
                } 
                
                decimal putawayQuantity = 0;
                
                for(bin__c b: allBins){
                    if(b.Location__r.Track_Bin_Capacity__c == false){
                        binMap.put(i,b);  
                        foundBin = true;
                        break;
                    } else {
                        putawayQuantity = (quantityToPutaway / KSE.getConversionFactor(
	                        											putawayWrapper[i].stockMovementRule.item__c, 
	                        											putawayWrapper[i].putawaySkid.Facility2__r.Facility_Identifier__c,
	                        											b.Packaging_UOM__c, 
	                        											UOMForPutAway, 
	                        											lstPkgUom 
	                        										)
											).setScale(6, System.RoundingMode.HALF_UP) ;
                        
                        if( b.Max_Capacity__c >= KSE.addQuantityToField(binTotalQty.get(b.id), putawayQuantity)  ){
                            binMap.put(i,b);  
                            foundBin = true;
                            binTotalQty.put(b.id, KSE.addQuantityToField (binTotalQty.get(b.id), putawayQuantity) );
                            break; 
                        }
                    }
                }
                
                if(foundBin == false  && locToEmptyBin.containskey(l.id)){
                    
                    Set<Bin__c> binsToRemove = new Set<Bin__c> ();
                    
                    for(bin__c b : locToEmptyBin.get(l.id)){
                        if(b.Location__r.Track_Bin_Capacity__c == false){
	                        binMap.put(i,b);  
	                        foundBin = true;
	                        break;
	                    } else {
	                        putawayQuantity = (quantityToPutaway / KSE.getConversionFactor(putawayWrapper[i].stockMovementRule.item__c, 
	                        												putawayWrapper[i].putawaySkid.Facility2__r.Facility_Identifier__c, 
	                        												b.Packaging_UOM__c,
	                        												UOMForPutAway, 
	                        												lstPkgUom 
	                        											)
	                        					).setScale(6,System.RoundingMode.HALF_UP) ;
	                        
	                        if(b.Max_Capacity__c >= putawayQuantity){
	                           
	                            binMap.put(i,b) ;
	                            foundBin = true;
	                             
	                            binTotalQty.put(b.id, KSE.addQuantityToField (binTotalQty.get(b.id),putawayQuantity) );
	                            binsToRemove.add(b);
	                            
	                            if(!locToItemBins.containskey(b.location__c)){
	                                locToItemBins.put(b.Location__c,new Map<Id,List<bin__c>>()); 
	                            }
	                            
	                            if(!locToItemBins.get(b.location__c).containsKey(putawayWrapper[i].stockMovementRule.item__c)) {
	                                locToItemBins.get(b.location__c).put(putawayWrapper[i].stockMovementRule.item__c,new List<bin__c>());
	                            }
	                            
	                            locToItemBins.get(b.Location__c).get(putawayWrapper[i].stockMovementRule.item__c).add(b); 
	                            break;
	                        } 
	                    } 
                    }
                    
                    locToEmptyBin.get(l.Id).removeall(binsToRemove);
                }
                
                if(foundBin){
                    break;
                }
			}
		} 
      	
		return binMap;
	}
    
    /**
     * @description : Constructs a map of source document line ID and the list of locations from the matching stock movement rule. 
     * The Stock_Movement_Rule_Settings__c custom setting is used to map the fields of the stock movement rule object to the fields of the source document line object.
     * Based on the values of these fields in the source document line object and the stock movement rule object, the matching rule is found. If more than one matching
     * rule is present, the Priority__c of the rule is used to determine the highest priority matching rule.
     * The list of locations on the stock movement rule is in JSON in the Location_List__c field.
     */
    public static map<String, list<Location__c>> locationsFromStockMovementRules( list<SObject> sobjectList, String ruleType, set<String> sourceDocumentLineNames, 
                                                    map<Id, Stock_Movement_Rule__c> matchedRules, set<Id> allLocationIds  ){
        set<String> sourceDocumentsToRemove = new set<String>{
        	SalesOrderService.SO_TYPE_RMA.toLowerCase(), SalesOrderService.SO_TYPE_RMA_REPAIR.toLowerCase(), SalesOrderService.SO_TYPE_RMA_REPLACEMENT.toLowerCase(), 'Receiving Document'.toLowerCase()
        };
        sourceDocumentLineNames.removeAll(sourceDocumentsToRemove);
        
        map< string, list<Location__c>> locationMap = new map<string, list<Location__c>>();
        map< string, list<Id>> locationIdMap = new map<string, list<Id>>();
        set<String> sourceDocumentTypes = new set<String>();
        
        if( matchedRules == null ){
            matchedRules = new map<Id, Stock_Movement_Rule__c>();
        }
        
        if(allLocationIds == null){
            allLocationIds = new set<Id>();
        }

        for(String sourceDoc : sourceDocumentLineNames){
            sourceDocumentTypes.add(lineToSourceDocumentMap.get(sourceDoc.toLowerCase()));
        }
        
        set<String> smrFields = new set<string>{'id', 'name', 'rule_type__c', 'source_document__c', 'priority__c', 'location__c', 'location__r.name', 'company__c', 'class__c', 
                                                'item__c', 'facility__c', 'location__r.facility__c', 'location__r.bin_tracked__c', 'customer__c',
                                                'Location_List__c'};

        List<Stock_Movement_Rule_Settings__c> smrsList = Stock_Movement_Rule_Settings__c.getAll().values();
        smrFields.addAll( util.getAllCustomFieldsFromObject('', 'stock_movement_rule__c') );
        
        if( !checkRequiredStockMovementSettings(sourceDocumentTypes) ){
            throw new SkidService3Exception(Label.Stock_Movement_Rule_settings_has_not_been_setup);
        }
        
        String whereClause = 'Rule_Type__c= :ruleType and Source_Document__c IN :sourceDocumentTypes and Active__c = true Order By Priority__c ASC';
        
        SOQLUtil soql = new SOQLUtil('Stock_Movement_Rule__c');
        soql.addFields(smrFields);
        soql.setWhereClause(whereClause);
        
        /*list<Stock_Movement_Rule__c> smrList = (List<Stock_Movement_Rule__c>) Database.query( util.generateQueryFromFieldSet( 'Stock_Movement_Rule__c', new set<string>{}, 
                        smrFields,'Rule_Type__c=:ruleType and Source_Document__c IN:sourceDocumentTypes and Active__c = true Order By Priority__c ASC'));*/
        
        list<Stock_Movement_Rule__c> smrList = (List<Stock_Movement_Rule__c>) Database.query(soql.getQuery());                        
                                         
        String sourceField = 'Source_Document_Path__c';
        if( ruleType.toLowerCase() == 'putaway' ){
            sourceField = 'Source_Document_Path_Putaway__c';
        }
          
        for(integer i = 0; i< sobjectlist.size() ; i++) {
        
            String key='';
            String sObjType = String.valueOf(sobjectlist[i].getSObjectType()).replace(KSE.namespaceUU,'').toLowerCase();
            
            if(sObjType == 'stock_movement_rule__c'){
                sObjType = ((string)sobjectlist[i].get('Source_Document__c')).toLowerCase();   
            }
            
            String sourceDocument;
            sourceDocument = lineToSourceDocumentMap.get(sObjType);
                
            for( Stock_Movement_Rule_Settings__c smrs : smrsList ){
                if(smrs.Source_Document__c == sourceDocument ){
                    string fieldName = (String) smrs.get(sourceField);
                    key += AccountingRuleService.getValue(fieldName, sobjectlist[i]);
                }
            }
            
            for( Stock_Movement_Rule__c smr : smrList ){
                
                if( smr.Location_List__c != null && smr.Source_Document__c == sourceDocument ){
                    String smrKey = '';
                    Stock_Movement_Rule__c smrClone = smr.clone(true, true);
                    
                    for( Stock_Movement_Rule_Settings__c smrs : smrsList ){
                         
                         if(smrs.Source_Document__c == sourceDocument ){
                             
                             String smrKeyField = smrs.Stock_Movement_Rule_Field__c;
                             
                             if( smrClone.get(smrKeyField) == null ){
                             	smrClone.put( smrKeyField, AccountingRuleService.getValue((String)smrs.get(sourceField), sobjectlist[i]));
                             }
                             
                             smrKey+= smrClone.get(smrKeyField);  
                         }
                    }
                    
                    if( smrKey == key ){
                        list<Id> locationList = new list<Id>();
                        try{
                            locationList = (list<Id>)JSON.deserialize(String.valueOf(smr.get('Location_List__c')), list<Id>.Class);
                        }
                        catch(Exception e){
                            throw new SkidService3Exception(Label.Invalid_Location_On_Stock_Movement_Rule+smr.get('name'));
                        }
                        
                        if(sourceDocument =='Transfer' || sourceDocument =='Directed Putaway'){
                        	locationIdMap.put( String.valueOf(i), locationList );    
                        }else {
                        	locationIdMap.put( sobjectlist[i].id, locationList );  
                        }
                        
                        allLocationIds.addAll(locationList);
                        
                        matchedRules.put( sobjectlist[i].id, smr );
                        break;
                    }
                }
            }
        }
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new Set<String>{ 'Id', 'Name', 'Bin_Tracked__c', 'Facility__c', 'Facility__r.Company__c', 'Mixed_Bins_Allowed__c', 'Track_Bin_Capacity__c' });
        soql.setWhereClause('Id IN :allLocationIds');

        map<Id, Location__c> locations = new map<Id, Location__c>((List<Location__c>) Database.query(soql.getQuery()));
        for( string headerId : locationIdMap.keySet()) {
        
            for( string locationId : locationIdMap.get(headerId) ){
                
                if(!locationMap.containsKey(headerId))
                    locationMap.put(headerId, new list<Location__c>());
                
                if( locations.containsKey(locationId))    
                    locationMap.get(headerId).add(locations.get(locationId));    
            }
        }
        
        return locationMap;
    }
    
    
    /**
     * @description : This is used to generate inventory change records for groups of inventory transactions.
     */
    public static void generateICsForITs(Map<Id,ParameterData> data) {
        if (data == null)
            return;
            
        Map<Id,Inventory_Change__c> icsToInsert = new Map<Id,Inventory_Change__c>();
            
        for (Id sourceDocId:data.keySet()) {
            ParameterData d = data.get(sourceDocId);
            sObject sourceDoc = d.sourceDoc;
            List<Inventory_Transaction__c> itList = d.itList;
            
            if (sourceDoc == null || sourceDoc.get('Company__c') == null || itList == null || itList.size() == 0)
                continue;
                
            String type;
            if (d.icType != null)
                type = d.icType;
            else
                for (Inventory_Transaction__c it:itList)
                    if (it.Type__c != null && !excludeITTypesForIC.contains(it.Type__c) && (type == null || (type == 'Transfer Of Ownership' && it.Type__c != 'Transfer Of Ownership')))
                        type = it.Type__c;
            if (type == null)
                continue;

            if (d.inventoryChange == null) {
                Inventory_Change__c ic = new Inventory_Change__c(
                    Company__c = (Id)sourceDoc.get('Company__c'),
                    Posting_Date__c = System.now(),
                    Transaction_Date__c = itList[0].Transaction_Date__c,
                    Type__c = type
                );
                
                if(sourceDoc.get('Currency__c') != null){
                	ic.Currency__c = (Id)sourceDoc.get('Currency__c');
                }
                if (Work_Order__c.sObjectType == sourceDoc.getSObjectType())
                    ic.Work_Order__c = sourceDocId;
                icsToInsert.put(sourceDocId,ic);
                d.inventoryChange = ic;
            }
        }
        
        DML.insertAsSystem(icsToInsert.values());
        
        for (Id sourceDocId:data.keySet()) {
            ParameterData d = data.get(sourceDocId);
            if (d.inventoryChange != null) {
                d.inventoryChange.Finalized__c = true;
                d.inventoryChange.Finalized_Date__c = System.now();
                for (Inventory_Transaction__c it:d.itList)
                    it.Inventory_Change__c = d.inventoryChange.Id;
            }
        }     
    }
    
    public static list<String> populateSortCriteria( Id customerId, Id companyId ){
        
        list<String> sortFields = new list<String>();
        
        List<Pick_Sort_Criteria__c> mscList = new list<Pick_Sort_Criteria__c>();

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Pick_Sort_Criteria__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Name','Sort_Field__c','Sort_Order__c','Null_Values__c','Sort_Priority__c','Customer__c'
        });
        soql.setOrderByClause('Sort_Priority__c');
        
        if( customerId != null ){
            soql.setWhereClause('Customer__c =:customerId and Active__c = true');
        }

        if( companyId != null && mscList.size() == 0 ){
            soql.setWhereClause('Company__c =:companyId and Active__c = true');
        }           
        
        mscList = Database.query(soql.getQuery());
        
        for( Pick_Sort_Criteria__c msc : mscList ){
            if( msc.Sort_Field__c != null ){
                String criteria = msc.Sort_Field__c+' ';
                
                if( msc.Sort_Order__c != null )
                    criteria += msc.Sort_Order__c+' ';
                
                if( msc.Null_Values__c != null )
                    criteria += 'NULLS '+msc.Null_Values__c+' ';
                
                sortFields.add(criteria);    
            }
        }
        
        return sortFields;
    }
    
    public static Map<List<String>,List<SKID__c>> pullSkidsQuery(List<String> sortFields,Map<String,Set<Id>> filters,String additionalWhereClause,String skidType,Integer limiter,Integer offset) { return pullSkidsQuery(sortFields,filters,additionalWhereClause,skidType,limiter,offset,null,null); }
    public static Map<List<String>,List<SKID__c>> pullSkidsQuery(List<String> sortFields,Map<String,Set<Id>> filters,String additionalWhereClause,String skidType,Integer limiter,Integer offset,List<sObject> records,List<String> attributes) {
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        
        Set<String> skidFields = new Set<String>{ 'CreatedDate','LastModifiedDate','Location__r.Facility__r.Name','Location__r.Name','Lot__r.Name','Lot__r.Lot_Hold__c','Lot__r.Expiration_Date__c','Lot__r.Lot_Unique__c',
        	'Sales_Order_Line__r.Ship_From_Location__c','Consigned_Owner__r.Name','Purchase_Order_Line__r.Name','Company__c','Company__r.Serial_Control__c','Location__r.Bin_Tracked__c','Bin__r.Name','Location__r.Facility__c','Location__r.Nettable__c',
        	'ASN_Line__c','Company__c','Customer__c','Lot_Number__c','Material_Tracking__c','Order_Line__c','Quantity__c','Receipt_Line__c','Sales_Order_Line__c','Type__c','Unique_Key__c','Work_Order__c','Item__r.Container__c','Container_Item__r.Container__c',
        	'Item__r.Non_Inventory__c','Item__r.Non_Shippable__c','Item__r.Source__c','Item__r.Item_Attribute__c','Item__r.Company__c','Item__r.Active__c','Item__r.Purchasing_UOM__c','Item__r.Stocking_UOM__c','Item__r.Track_Install_Base__c','Item__r.Packaging_UOM__c','Facility2__r.Facility_Identifier__c',
        	'Packaging_UOM__r.Package_Class__c', 'Container_Item__r.Container_Package_Class__c','Container_Item__r.Container_Package_Class__r.Level__c', 'License_Plate_Number__c', 'Stocking_UOM__c', 'Quantity_Stocking_UOM__c','Location__r.Mixed_Bins_Allowed__c','Location__r.Track_Bin_Capacity__c','Bin__r.Location__r.Mixed_Bins_Allowed__c'
        };
        skidQuery.addFields(new set<String>(SkidService3.attributesForPutaway()));	
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType,'Item__r.Item_Attribute__r');
        skidQuery.addFields(skidFields);
        for (String fieldName:filters.keySet()) {
            skidQuery.addField(fieldName);
        }
        
        String whereClause = 'Type__c = :skidType';
        if (filters != null && filters.size() > 0) {
            whereClause += returnQueryFilters(filters);
        }
        
        List<Date> dateList = new List<Date>();
        if (records != null && records.size() > 0) {
            whereClause += getAttributeFilters(records,attributes,dateList);
        }
        if (additionalWhereClause != null) {
            whereClause += additionalWhereClause;
        }
        skidQuery.setWhereClause(whereClause);
        
        if (sortFields != null && sortFields.size() > 0) {
            skidQuery.setOrderByClause('Item__c,Location__c,' + String.join(sortFields,','));
        }
        
        if (limiter != null && limiter > 0) {
            skidQuery.setLimit(limiter);
        }
        
        if (offset != null && offset > 0) {
            skidQuery.setOffset(offset);
        }
        
        Map<List<String>,List<SKID__c>> skidMap = new Map<List<String>,List<SKID__c>>();
        for (SKID__c skid:Database.query(skidQuery.getQuery())) {
            List<String> key = new List<String>();

            if (filters != null && filters.size() > 0) {
                for (String fieldName:filters.keySet()){
                    key.add(AccountingRuleService.getValue(fieldName,skid));
                }
            }
            
            if (!skidMap.containsKey(key)) {
                skidMap.put(key,new List<SKID__c>());
            }
            skidMap.get(key).add(skid);
        }

        return skidMap;
    }
    
    public static String getAttributeFilters(List<sObject> records,List<String> attributes,List<Date> dateList) {
        String ns = KSE.NamespaceUU.toLowerCase();
        if (attributes == null) attributes = SkidService3.attributesForPutaway();
        
        Map<String,List<Object>> filterMap = new Map<String,List<Object>>();
        for (sObject record:records) {
            Map<String,Object> objMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(record).toLowerCase());
            
            for (String attr:attributes) {
                attr = attr.toLowerCase();

                if (!attributesToExclude.contains(attr) && attr != 'item__c' && attr != 'location__c') {
                    Object val;
                    if (objMap.containsKey(ns + attr)) {
                        val = record.get(ns + attr);
                    } else if (objMap.containsKey(attr)) {
                        val = record.get(attr);
                    }
                    
                    if (val != null) {
                        if (!filterMap.containsKey(attr)) {
                            filterMap.put(attr,new List<Object>());
                        }
                        filterMap.get(attr).add(val);
                    }
                }
            }
        }
        
        if (filterMap.size() > 0) {
            Map<String,Schema.SObjectField> skidFields = util.getFieldsMap('SKID__c');
            Integer ct = 0;
            String filter = ' AND (';
            for (String attr:filterMap.keySet()) {
                Schema.DisplayType attrType = skidFields.get(attr).getDescribe().getType();
                List<Object> vals = filterMap.get(attr);
                
                if (ct > 0) {
                    filter += ' OR ';
                }
                filter += attr + ' IN ';
                
                if (attrType == Schema.DisplayType.Boolean || attrType == Schema.DisplayType.Integer || attrType == Schema.DisplayType.Double || attrType == Schema.DisplayType.Percent || attrType == Schema.DisplayType.Currency) {
                    filter += '(' + String.join(vals,',') + ')';
                    
                } else if (attrType == Schema.DisplayType.Date) {
                	for (Object val:vals) dateList.add((Date)val);
                	
                	filter += ' :dateList ';
                } else {
                    filter += '(\'' + String.join(vals,'\',\'') + '\')'; 
                }
                ct++;
            }
            filter += ') ';
            return filter;
        }
        
        return '';
    }
    
    public static String returnQueryFilters(map<String, Set<Id>> filters){
        
        String filterString = ' ';
        
        for( String key : filters.keySet()){
            set<Id> idSet = filters.get(key);
            if( idSet.size() > 0 ){
                filterString+=' and '+key+' IN ';
                filterString+= '(\''+String.join( new List<Id>(idSet), '\',\'')+'\')';
            }
        }
        
        return filterString;
    }

    

    public static Boolean isValidSkid(SKID__c skid, sObject record, List<String> attributes) {
        String ns = KSE.NamespaceUU.toLowerCase();
        if (attributes == null) attributes = SkidService3.attributesForPutaway();

        Map<String, Object> objFields = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(record).toLowerCase());

        for (String attr:attributes) {
            attr = attr.toLowerCase();
            if (!attributesToExclude.contains(attr) && !sourceDocumentLineTypes.contains(attr) && attr != 'item__c' && attr != 'location__c') {
                Object val = objFields.containsKey(ns + attr) ? record.get(ns + attr) : (objFields.containsKey(attr) ? record.get(attr) : null);
                if (val != null && val != '' && val != skid.get(attr)) return false;
            }
        }

        return true;
    }
    
    /*
    //map fields keys should all be in lowercase.
    public static map<Id, map<String,String>> distribute( map<Id, List<SerialWrapper>> inventoryMap , map<Id, Decimal> toDistributeMap, map<String,String> configMap){
        
        String inputField = configMap.get('inputfield');
        String availableField = configMap.get('availablefield');
        map<Id, Decimal> updatedSkidQuantities = new map<Id, Decimal>();
        map<Id, map<String,String>> errorMessagesMap = new map<Id, map<String,String>>();
        
        for( Id lineId : toDistributeMap.keySet()){
            
            Decimal quantityToDistribute = toDistributeMap.get(lineId);
            map<String, String> errorMessages = new map<String,String>();
            
            if(!inventoryMap.containsKey(lineId)){
                continue;
            }
            
            for( SerialWrapper sw : inventoryMap.get(lineId) ){
                
                if(updatedSkidQuantities.containsKey(sw.skid.id)){
                    sw.skid.put(availableField, updatedSkidQuantities.get( sw.skid.id)); 
                }
                
                if( (Decimal)sw.skid.get(availableField) > quantityToDistribute ){
                    sw.skid.put(inputField, quantityToDistribute);
                }
                else{
                    sw.skid.put(inputField, (Decimal)sw.skid.get(availableField));
                }
                
                sw.skid.put(availableField, (Decimal)sw.skid.get(availableField) - (Decimal)sw.skid.get(inputField) );
                quantityToDistribute -= (Decimal)sw.skid.get(inputField);
                
                updatedSkidQuantities.put( sw.skid.id, (Decimal)sw.skid.get(availableField));
                
                if(quantityToDistribute == 0) break;
            }
            
            if( quantityToDistribute > 0 ){
                
                String lineName = '';
                
                if(configMap.containsKey(lineId)){
                    lineName = configMap.get(lineId);
                }
                
                if(!errorMessagesMap.containsKey(lineId)){
                    errorMessagesMap.put(lineId, new map<String, String>());
                }
                
                errorMessagesMap.get(lineId).put(MessageUtil.Severity.WARNING.name(), 'Not Enough Quantity for :'+lineName);
            }
        }
        
        return errorMessagesMap;
    }
    
    */
    //for pull sorted skids, we can pull the skids by item and location and then during distribute, just send the skids with the quantity needed to the UI and
    //remove the rest of the skids from memory. We can probably also limit by the number of lines. //then we can use offset with that item and location combination
    //when the user needs to see more.
    
    public static Set<Id> getSerialTrackedItems(List<SObject> sourceDocs, Boolean atShipment) {
        Set<Id> serialTrackedItemIds = new Set<Id>();
        Set<Id> sourceDocsIds = new Set<Id>();
        
        try{
	        String sObjectType;  //sourceDocs.getSObjectType() is returning null value, could be a bug.
	        
	        for (SObject sourceDoc : sourceDocs) {
	        	
	        	sObjectType = sourceDoc.Id.getSObjectType().getDescribe().getLocalName();
	        	
	        	Item__c item = sourceDoc.getSObject('Item__r') != null ? (Item__c) sourceDoc.getSObject('Item__r') : null;
		        
		        if(item == null || (item.Item_Attribute__c != null && item.Item_Attribute__r == null) 
		        	|| item.Item_Attribute__r.Serial_Number__c == null ){
		        	
		        	sourceDocsIds.add(sourceDoc.Id);
		        }
		        
		        if(sObjectType.equalsIgnoreCase('Material_Tracking__c')){
			        Work_Order__c workOrder = (Work_Order__c) sourceDoc.getSObject('Work_Order__r');
			       	// We can remove this if condition if/when we add company to the material tracking object.
		       		if(workOrder == null || workOrder.getSObject('Company__r') == null || workOrder.getSObject('Company__r').get('Serial_Control__c') == null ){
			        	sourceDocsIds.add(sourceDoc.Id);
			        }else{
				       	Item__c workOrderItem = workOrder.Item__r;
				       	
				       	if(workOrderItem == null || (workOrderItem.Item_Attribute__c != null && workOrderItem.Item_Attribute__r == null) 
				       		|| workOrderItem.Item_Attribute__r.Serial_Number__c == null ){
				        	
				        	sourceDocsIds.add(sourceDoc.Id);
				        }
		       		}
		        }else{
		        	if(sourceDoc.getSObject('Company__r') == null || sourceDoc.getSObject('Company__r').get('Serial_Control__c') == null ){
			        	sourceDocsIds.add(sourceDoc.Id);
			        }
		        }
		    }
	        
	        Map<Id, SObject> sourceDocsMap = new Map<Id, SObject>();
	        
	        if (sourceDocsIds.size() > 0) {
	        	Set<String> sourceDocFields = new Set<String>{ 'Id','Name','Item__r.Item_Attribute__c','Item__r.Item_Attribute__r.Serial_Number__c' };
	            
	            if(sObjectType.equalsIgnoreCase('Material_Tracking__c')){
	            	sourceDocFields.addAll(new Set<String>{'Work_Order__r.Company__c','Work_Order__r.Company__r.Serial_Control__c', 
	        											   'Work_Order__r.Item__r.Item_Attribute__c','Work_Order__r.Item__r.Item_Attribute__r.Serial_Number__c'});
	            }else{
	            	sourceDocFields.addAll(new Set<String>{'Company__c','Company__r.Serial_Control__c'});
	            }
	            
	            SOQLUtil soql = new SOQLUtil(sObjectType);
	            soql.addFields(sourceDocFields);
	            soql.setWhereClause('Id IN :sourceDocsIds');
	            
	            sourceDocsMap = new Map<Id, SObject>((List<SObject>) Database.query(soql.getQuery()));
	        }
	        
	        for (SObject sourceDoc : sourceDocs) {
	        	
	        	if(sourceDocsMap.containsKey(sourceDoc.Id)){
	        		sourceDoc = sourceDocsMap.get(sourceDoc.Id);
	        	}
	        	
	        	Item__c item = sourceDoc.getSObject('Item__r') != null ? (Item__c) sourceDoc.getSObject('Item__r') : null;
	        	
	        	Company__c company;
	        	
	        	if(sObjectType.equalsIgnoreCase('Material_Tracking__c')){
	        		company = (Company__c) sourceDoc.getSObject('Work_Order__r').getSObject('Company__r');
	        	}else{
	        		company = (Company__c) sourceDoc.getSObject('Company__r');
	        	}
	        	
	        	if (company.Serial_Control__c != null && (atShipment || company.Serial_Control__c == 'At receipt and all processes')){ 
	            	if(item.Item_Attribute__c != null && item.Item_Attribute__r.Serial_Number__c == true) {
	                	serialTrackedItemIds.add(item.Id);
	            	}
	            	
	            	if(sObjectType.equalsIgnoreCase('Material_Tracking__c')){
		            	Item__c workOrderItem = (Item__c) sourceDoc.getSObject('Work_Order__r').getSObject('Item__r');
		            
		            	if(workOrderItem.Item_Attribute__c != null && workOrderItem.Item_Attribute__r.Serial_Number__c == true) {
		                	serialTrackedItemIds.add(workOrderItem.Id);
		            	}
	            	}
		        }
	        }
        }catch(Exception e){
        	system.debug(LoggingLevel.ERROR, e.getStackTraceString());
        	throw e;
        }
        
        return serialTrackedItemIds;
    }
    
    /**
     * @description : returns if the item has any container with lpn tracked item attribute if packaging uom is not passed in. 
     * If packaging UOM is passed in, it will return the container based on the particular item and packaging UOM. 
     * use this method when packaging uom attributes have not been queried or only item is specified. 
     * To Do: need to bulkify this
     */
    public static Item__c getContainerforItem(Item__c item, UOM__c packagingUOM) {
        if (item.Container__c == true) return item;

        if (packagingUOM != null && packagingUOM.Package_Class__c != null) {
            if (item.Container_Item__c != null && item.Container_Item__r.Container_Package_Class__c == packagingUOM.Package_Class__c) return item.Container_Item__r;
            if (packagingUOM.Package_Class__r.Default_Container_Item__c != null) return packagingUOM.Package_Class__r.Default_Container_Item__r;
            if (packagingUOM.Id == item.Stocking_UOM__c) return item;
        } else if (packagingUOM == null) {
            if (item.Container_Item__c != null && item.Container_Item__r.Item_Attribute__c != null && item.Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true) {
                return item.Container_Item__r;
            }
        }
        
        list<Id> packagingUOMList = new list<Id>();
        if(packagingUOM != null){
            packagingUOMList.add(packagingUOM.Id);
        }
        else{
            try{
                packagingUOMList = (list<Id>)JSON.deserialize(String.valueOf(item.get('Packaging_UOM__c')), list<Id>.Class);
            }
            catch(Exception e){
                throw new SkidService3Exception('Invalid Packaging UOM');
            }
        }
        
        Item__c container;
        if(packagingUOMList.size() > 0 ){
            SOQLUtil soql = new SOQLUtil('UOM__c');
            soql.addFields(new set<String>{'Package_Class__c','Package_Class__r.Default_Container_Item__c','Package_Class__r.Fractional_Quantities_Allowed__c','Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Fractional_Quantities_Allowed__c',
            'Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c'});
            soql.setWhereClause('Id IN :packagingUOMList');
            
           for( UOM__c pkgUOM : Database.Query(soql.getQuery()) ){
               
               if(packagingUOM != null && packagingUOM.Id == pkgUOM.id ){
                   
                   if( item.Container_Item__c != null && item.Container_Item__r.Container_Package_Class__c == pkgUOM.Package_Class__c){
                       container = item.Container_Item__r;
                   }
                   else{
                        if( pkgUOM.Package_Class__r != null ){    
                            container = pkgUOM.Package_Class__r.Default_Container_Item__r;
                        }
                        
                       if( (packagingUOM.Package_Class__c == null || (packagingUOM.Package_Class__c != null && packagingUOM.Package_Class__r.Level__c == 1)) && container == null){
                            container = item;
                        }
                    }
                   break;
               }
               else if(pkgUOM.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true){
                   container =  pkgUOM.Package_Class__r.Default_Container_Item__r;
                   break;
               } 
           }
        }
        
        return container;    
    }
    
    public static map<Id, map<Id, Item__c>> getContainerforItems( map<Item__c, Set<UOM__c>> itemsWithPackagingUOM ){
        
        map<Id, map<Id, Item__c>> containerItems = new  map<Id, map<Id, Item__c>>();
        list<Id> packagingUOMList = new list<Id>();
        map<Id, List<Id>> packagingUOMIdsByItem = new map<Id, List<Id>>();
        
        for(Item__c item : itemsWithPackagingUOM.keySet()){
        	Boolean containerItemFound = false;
        	if(!containerItems.containskey(item.Id)){
        		containerItems.put( item.Id, new map<Id, Item__c>() );
        	}
        	
        	if(itemsWithPackagingUOM.get(item).size() == 0){
        	    
        	    if( item.Container__c == true ){
                    containerItems.get(item.Id).put(null, item);
		            containerItemFound = true;
                }
        		
        		if(item.Container_Item__c != null && item.Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true){
		              containerItems.get(item.Id).put(null, item.Container_Item__r);
		              containerItemFound = true;
		        }
        	}
        	
        	for(UOM__c packagingUOM:itemsWithPackagingUOM.get(item)){
        	    
        	    if( item.Container__c == true ){
                    containerItems.get(item.Id).put(packagingUOM.Id, item);
		            containerItemFound = true;
                }
        		
	            if(packagingUOM != null && packagingUOM.Package_Class__c != null && item.Container_Item__c != null
	                && item.Container_Item__r.Container_Package_Class__c == packagingUOM.Package_Class__c){
	                containerItems.get(item.Id).put(packagingUOM.Id, item.Container_Item__r);
	                containerItemFound = true;
	            }
	            
	            if( packagingUOM != null && packagingUOM.Package_Class__c != null && (!containerItems.get(item.Id).containsKey(packagingUOM.Id))){
	                
	                if(packagingUOM.Package_Class__r.Default_Container_Item__c != null){
	                    containerItems.get(item.Id).put(packagingUOM.Id, packagingUOM.Package_Class__r.Default_Container_Item__r);
	                }
	                else if(packagingUOM.Package_Class__r.Level__c == 1){
	                    containerItems.get(item.Id).put(packagingUOM.Id, item);
	                    
	                }
	                containerItemFound = true;
	            }
	            
	            if(!containerItemFound){
	            
	                if(packagingUOM != null){
	                    packagingUOMList.add(packagingUOM.Id);
	                }
	                else{
	                    try{
	                        List<Id> pkgUOMList = (list<Id>)JSON.deserialize(String.valueOf(item.get('Packaging_UOM__c')), list<Id>.Class);
	                        packagingUOMIdsByItem.put(item.Id, pkgUOMList);
	                        packagingUOMList.addAll(pkgUOMList);
	                    }
	                    catch(Exception e){
	                        throw new SkidService3Exception('Invalid Packaging UOM');
	                    }
	                }
	            }
	                
        	}

        }
        
        if(packagingUOMList.size() > 0 ){
            SOQLUtil soql = new SOQLUtil('UOM__c');
            soql.addFields(new set<String>{'Package_Class__c','Package_Class__r.Default_Container_Item__c','Package_Class__r.Level__c','Package_Class__r.Fractional_Quantities_Allowed__c',  
            'Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c','Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Fractional_Quantities_Allowed__c',
            'Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Package_Class__r.Default_Container_Item__r.Container_Package_Class__c','Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c'});
            soql.setWhereClause('Id IN :packagingUOMList');
            
            map<Id, UOM__c> packagingUOMMap = new map<Id, UOM__c>((List<UOM__c>)Database.Query(soql.getQuery()));
            
            for( Item__c item : itemsWithPackagingUOM.keySet() ){
                if(itemsWithPackagingUOM.get(item).size()==0){
                	
                    for(Id pkgUOMId : packagingUOMIdsByItem.get(item.Id)){
                        UOM__c pkgUOM = packagingUOMMap.get(pkgUOMId);
                        if(pkgUOM.Package_Class__c!= null && pkgUOM.Package_Class__r.Default_Container_Item__c != null && 
                            pkgUOM.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c == true){
                            containerItems.get(item.Id).put(null, pkgUOM.Package_Class__r.Default_Container_Item__r);
                        }
                    }
                
                }
                for(UOM__c packagingUOM:itemsWithPackagingUOM.get(item)){
                	
                	//dont enter if container is already found for some of the uom's
                    if(!(containerItems.containsKey(item.id) && containerItems.get(item.id).containsKey(packagingUOM.id))  ){
	                    UOM__c pkgUOM = packagingUOMMap.get(packagingUOM.id);
	                       
	                    if( pkgUOM.Package_Class__c!= null && item.Container_Item__c != null && item.Container_Item__r.Container_Package_Class__c == pkgUOM.Package_Class__c){
	                        containerItems.get(item.Id).put(packagingUOM.Id, item.Container_Item__r);
	                    }
	                    else{
	                        if(pkgUOM.Package_Class__c!= null && pkgUOM.Package_Class__r.Default_Container_Item__c != null){
	                            containerItems.get(item.Id).put(packagingUOM.Id, pkgUOM.Package_Class__r.Default_Container_Item__r);
	                        }
	
	                        else if(pkgUOM.Package_Class__r.Level__c == 1 || pkgUOM.Package_Class__c == null){
	                            //as the item itself is the container, setting the package class, this will not be committed.
	                            item.Container_Package_Class__c = pkgUOM.Package_Class__c;
	                            item.Container_Package_Class__r = pkgUOM.Package_Class__r;
	
	                            containerItems.get(item.Id).put(packagingUOM.Id, item);
	                        }
	                    }
                    }
                }
            }
        }
        
        return containerItems;    
    }

    public static String generateSkidUniqueKey(SKID__c skid) {
        return EncodingUtil.base64Encode(Crypto.generateDigest('SHA-1', Blob.valueOf(String.join(SkidService3.generateKey(skid, attributesForUniqueKey), ','))));
    }

    public static List<SKID__c> getSkids(Map<String, String> config) { return Database.query(getSkidQuery(config)); }
    public static String getSkidQuery(Map<String, String> config) { return getSkidSoql(config).getQuery(); }
    public static SOQLUtil getSkidSoql(Map<String, String> config) {
        SOQLUtil skidQuery = new SOQLUtil('SKID__c');
        skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Lot_Number__c', 'Mixed_Palletized__c', 'Quantity_Stocking_UOM__c', 'Quantity__c',
            'Scanned_For_Shipment__c', 'Stocking_UOM__c', 'Type__c',

            'Bin__r.Blocked__c', 'Bin__r.Location__c', 'Bin__r.Max_Capacity__c', 'Bin__r.Packaging_UOM__c', 'Bin__r.Packaging_UOM__r.Package_Class__c',

            'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',

            'Facility2__r.Facility_Identifier__c','Sales_Order_line__r.Sales_Order__r.Type__c',

            'Item__r.Container__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c',

            'Location__r.Bin_Tracked__c', 'Location__r.Facility__c', 'Location__r.Mixed_Bins_Allowed__c', 'Location__r.Track_Bin_Capacity__c',

            'Lot__r.Lot_Hold__c',

            'Material_Tracking__r.Work_Order__c',

            'Order_Line__r.Order__c',

            'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c', 'Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c',
            'Packaging_UOM__r.Package_Class__r.Level__c',

            'Shipment_Line__r.Shipment__c' });
        skidQuery.addFields(new Set<String>(attributesForUniqueKey));
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Container_Item__r.Item_Attribute__r');
        skidQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        if (config.containsKey('WHERE') == true) skidQuery.setWhereClause(config.get('WHERE'));
        if (config.containsKey('ORDER') == true) skidQuery.setOrderByClause(config.get('ORDER'));
        return skidQuery;
    }

    public static List<Serial__c> getSerials(Map<String, String> config) { return Database.query(getSerialQuery(config)); }
    public static String getSerialQuery(Map<String, String> config) { return getSerialSoql(config).getQuery(); }
    public static SOQLUtil getSerialSoql(Map<String, String> config) {
        SOQLUtil serialQuery = new SOQLUtil('Serial__c');
        serialQuery.addFields(new Set<String>{ 'Id', 'Name', 'Allocated_SKID__c', 'Allow_Reentry__c', 'Item__c', 'SKID__c', 'Status__c', 'Temporary_Value_Holder__c',

            'Allocated_SKID__r.Shipment_Line__c', 'Allocated_SKID__r.Type__c' });
        serialQuery.addFields(new Set<String>(SkidService3.serialAttributes));
        serialQuery.addFields('Serial');
        if (config.containsKey('WHERE') == true) serialQuery.setWhereClause(config.get('WHERE'));
        if (config.containsKey('ORDER') == true) serialQuery.setOrderByClause(config.get('ORDER'));
        return serialQuery;
    }

    public static List<Inventory_Transaction__c> getInventoryTransactions(Map<String, String> config) { return Database.query(getItQuery(config)); }
    public static String getItQuery(Map<String, String> config) {
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(new Set<String>{
            'From_Bin__r.Blocked__c', 'From_Bin__r.Location__c', 'From_Bin__r.Max_Capacity__c', 'From_Bin__r.Packaging_UOM__c',
            'From_Bin__r.Packaging_UOM__r.Package_Class__c', 'Bin__r.Blocked__c', 'Bin__r.Location__c', 'Bin__r.Max_Capacity__c', 'Bin__r.Packaging_UOM__c',
            'Bin__r.Packaging_UOM__r.Package_Class__c','Sales_Order_Line__r.Sales_Order__r.Type__c',

            'Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Container_Package_Class__r.Level__c', 'Container_Item__r.Item_Attribute__c',

            'From_Facility__r.Facility_Identifier__c', 'To_Facility__r.Facility_Identifier__c',

            'Inventory_Change__r.Work_Order__c', 'Inventory_Change__r.Work_Order__r.Field_Service__c',

            'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c',

            'From_Location__r.Bin_Tracked__c', 'From_Location__r.Facility__c', 'From_Location__r.Mixed_Bins_Allowed__c', 'From_Location__r.Track_Bin_Capacity__c',
            'To_Location__r.Bin_Tracked__c', 'To_Location__r.Facility__c', 'To_Location__r.Mixed_Bins_Allowed__c', 'To_Location__r.Track_Bin_Capacity__c',

            'From_Lot__r.Lot_Hold__c', 'Lot__r.Lot_Hold__c',

            'Operation_Tracking__r.Sequence__c',

            'Purchase_Order_Line__r.Supplier__c',

            'Assembly_Packaging_UOM__r.Package_Class__c', 'Assembly_Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
            'Assembly_Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Assembly_Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Assembly_Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
            'Assembly_Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c', 'Assembly_Packaging_UOM__r.Package_Class__r.Level__c',
            'From_Packaging_UOM__r.Package_Class__c', 'From_Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
            'From_Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'From_Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'From_Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c', 'From_Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c',
            'From_Packaging_UOM__r.Package_Class__r.Level__c', 'Packaging_UOM__r.Package_Class__c', 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Container_Package_Class__r.Level__c',
            'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c', 'Packaging_UOM__r.Package_Class__r.Fractional_Quantities_Allowed__c',
            'Packaging_UOM__r.Package_Class__r.Level__c',
            
            'Shipment_Line__r.Sales_Order_Line__c', 'Shipment_Line__r.Sales_Order_Line__r.Price_Type__c', 'Shipment_Line__r.Shipment__c',' Shipment_Line__r.Name ' });
        itQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Container_Item__r.Item_Attribute__r');
        itQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'From_Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        itQuery.addAllCustomFields(Item_Attribute__c.sObjectType, 'Packaging_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r');
        if (config.containsKey('WHERE') == true) itQuery.setWhereClause(config.get('WHERE'));
        if (config.containsKey('ORDER') == true) itQuery.setOrderByClause(config.get('ORDER'));

        if (config.containsKey('SERIALS') == true) {
            SOQLUtil.ChildRelationship stQuery = new SOQLUtil.ChildRelationship(itQuery, 'Serial_Transactions__r');
            stQuery.addFields(new Set<String>{ 'Id', 'Name', 'Serial_Parent__c', 'Serial__c',

                'Serial__r.Allocated_SKID__c', 'Serial__r.Allow_Reentry__c', 'Serial__r.Company__c', 'Serial__r.Item__c', 'Serial__r.SKID__c', 'Serial__r.Status__c',
                'Serial__r.Temporary_Value_Holder__c' });
            for (String attr:SkidService3.serialAttributes) stQuery.addField('Serial__r.' + attr);
            for (String fld:util.getFieldsFromFieldSetString(Serial__c.sObjectType, 'Serial')) stQuery.addField('Serial__r.' + fld);
            itQuery.addChildRelationship(stQuery);
        }

        return itQuery.getQuery();
    }
    
    
    public class ParameterData {
        public sObject sourceDoc { get; set; }  //Placeholder for the company value. If the source document is a work order, the IC will be linked to the work order, otherwise the sobject type does not matter. Also provides the ability to add custom logic based on the source document type.
        public List<Inventory_Transaction__c> itList { get; set; } { itList = new List<Inventory_Transaction__c>(); }
        public String icType { get; set; }  //Type override for the IC. If provided for a particular source document, the IC type will be set to the value in the map
        public Inventory_Change__c inventoryChange { get; set; }    //Created IC will be stored here. Also prevents additional ICs from being created if they've been created before.
        public map<Id, List<Serial__c>> fromSerialListBySkid { get; set; } //the list of serials of the from skid of the inventory transaction
    }
    
    public class SerialWrapper implements Comparable {
        public SKID__c skid { get; set; }
        public Inventory_Transaction__c it { get; set; }
        public List<Serial__c> serialList { get; set; } { serialList = new List<Serial__c>(); }
        public List<String> trackedAttributes { get; set; } { trackedAttributes = new List<String>(); }
        public Decimal conversionFactor { get; set; } { conversionFactor = 1; }
        
        public SKID__c toskid { get;set; }//this skid is used to provide attributes to correct from the exisitng skid.
        public String temporaryValueHolder { get;set;}
        public String lotValueHolder { get;set;}
        public list<Serial_Transaction__c> serialTransactions { get;set;}
        public double transactionUnitCost;        
        public double assetBookValue;
        public string itType;
        public Item__c containerItem {get;set;}
        
        public SerialWrapper(SKID__c skid) { this(skid, null, null, null); }
        public SerialWrapper(SKID__c skid, List<Serial__c> serials) { this(skid, null, serials, null); }
        public SerialWrapper(Inventory_Transaction__c it, List<Serial__c> serials) { this(null, it, serials, null); }
        public SerialWrapper(Inventory_Transaction__c it, List<Serial_Transaction__c> stList) {
            this.it = it;
            this.serialTransactions = stList;
        }
        public SerialWrapper(SKID__c skid, Inventory_Transaction__c it, List<Serial__c> serials) { this(skid, it, serials, null); }
        public SerialWrapper(SKID__c skid, Inventory_Transaction__c it, List<Serial__c> serials, SKID__c skid2) {
            this.skid = skid;
            this.it = it;
            if (serials != null) this.serialList = serials;
            this.toskid = skid2;
            setConversionFactor();
        }
        
        // this will clone the SerialWrapper 
        public SerialWrapper ( SerialWrapper wrapper ) {
            skid = wrapper.skid != null ? wrapper.skid.clone(true, true) : null;
            it = wrapper.it != null ? wrapper.it.clone (true, true) : null;
            serialList = wrapper.serialList != null ? wrapper.serialList.deepClone(true,false,false) : null;
            trackedAttributes = wrapper.trackedAttributes != null ? wrapper.trackedAttributes.clone() : null;
            serialTransactions = wrapper.serialTransactions != null ? wrapper.serialTransactions.deepClone(true,false,false) : null;
            temporaryValueHolder = String.valueOf ( wrapper.temporaryValueHolder );
            transactionUnitCost = Double.valueOf ( wrapper.transactionUnitCost);
            conversionFactor = wrapper.conversionFactor;
        }

        private void setConversionFactor() {
            if (skid != null && skid.Item__c != null && skid.Facility2__c != null && skid.Packaging_UOM__c != null) {
                conversionFactor = KSE.getConversionFactor(skid.Item__c, skid.Facility2__r.Facility_Identifier__c, skid.Packaging_UOM__c, skid.Item__r.Stocking_UOM__c, (List<Id>)JSON.deserialize(skid.Item__r.Packaging_UOM__c, List<Id>.Class));
            }
        }
        
        public Integer compareTo(Object compareTo) {
            SerialWrapper compareToWrapper = (SerialWrapper)compareTo;
            Decimal compareFromQty = this.skid == null ? this.it.Quantity__c : this.skid.Quantity__c;
            Decimal compareToQty = compareToWrapper.skid == null ? compareToWrapper.it.Quantity__c : compareToWrapper.skid.Quantity__c;

            Integer returnValue = 0;
            if (this.skid != null && this.skid.Packaging_UOM__r != null && this.skid.Packaging_UOM__r.Package_Class__c != null && this.skid.Packaging_UOM__r.Package_Class__r != null && this.skid.Packaging_UOM__r.Package_Class__r.Level__c != null &&
            compareToWrapper.skid != null && compareToWrapper.skid.Packaging_UOM__r != null && compareToWrapper.skid.Packaging_UOM__r.Package_Class__c != null && compareToWrapper.skid.Packaging_UOM__r.Package_Class__r != null && compareToWrapper.skid.Packaging_UOM__r.Package_Class__r.Level__c != null &&
            ((compareFromQty < 0 && compareToQty < 0) || (compareFromQty == 0 && compareToQty == 0) || (compareFromQty > 0 && compareToQty > 0))) {
                //If quantity is same sign, higher UOMs first
                if (this.skid.Packaging_UOM__r.Package_Class__r.Level__c < compareToWrapper.skid.Packaging_UOM__r.Package_Class__r.Level__c) {
                    returnValue = 1;
                } else if (this.skid.Packaging_UOM__r.Package_Class__r.Level__c > compareToWrapper.skid.Packaging_UOM__r.Package_Class__r.Level__c) {
                    returnValue = -1;
                }
            }

            if (returnValue == 0) {
                //If levels are not populated, quantity is different signs, or same level, sort lower quantity first
                if (compareFromQty > compareToQty) {
                    returnValue = 1;
                } else if (compareFromQty < compareToQty) {
                    returnValue = -1;
                }
            }

            return returnValue;
        }
    }
    

    public static List<String> attributeFields {
        get {
            if (attributeFields == null) {
                attributeFields = new List<String>();
                for (String attr:util.getAllCustomFieldsFromObject(null, 'Item_Attribute__c')) {
                    if (!attributesToExclude.contains(attr.toLowerCase())) attributeFields.add(attr);
                }
            }
            return attributeFields;
        } set;
    }

    public static List<String> attributes {
        get {
            if (attributes == null) attributes = attributesForPutaway();
            return attributes;
        } private set;
    }

    public static List<String> planAttributes {
        get {
            if (planAttributes == null) planAttributes = attributesForPutaway(null, new Set<String>{ 'container_item__c', 'license_plate_number__c' });
            return planAttributes;
        } private set;
    }

    public static Map<Id, List<String>> allocAttributes { get; private set; }
    public static void setAllocAttributes(Id companyId, Map<Id, Item__c> items) {
        if (allocAttributes == null) {
            allocAttributes = new Map<Id, List<String>>();
        } else {
            items = items.clone();
            for (Id itemId:allocAttributes.keySet()) items.remove(itemId);
        }
        if (items.size() > 0) allocAttributes.putAll(AllocationService.getSkidAttributes(companyId, items));
    }

    public static List<String> attributesForUniqueKey {
        get {
            if (attributesForUniqueKey == null) {
                attributesForUniqueKey = new List<String>{ 'Type__c', 'Item__c', 'Container_Item__c', 'Packaging_UOM__c', 'Facility2__c', 'Location__c', 'Bin__c', 
                    'Customer__c' };
                for (String attr:attributeFields) {
                    if (attr == 'Lot_Number__c') attributesForUniqueKey.add('Lot__c');
                    else attributesForUniqueKey.add(attr);
                }
                attributesForUniqueKey.addAll(new List<String>{ 'Consigned_Owner__c', 'Purchase_Order_Line__c', 'Shipment_Line__c', 'Receipt_Line__c', 'ASN_Line__c',
                    'Material_Tracking__c', 'Work_Order__c', 'Sales_Order_Line__c', 'Order_Line__c' });
            }
            return attributesForUniqueKey;
        } set;
    }

    public static List<String> serialAttributes {
        get {
            if (serialAttributes == null) {
                serialAttributes = new List<String>();
                for (String attr:util.getFieldsFromFieldSetString(Item_Attribute__c.sObjectType, 'Serial_Attributes')) {
                    serialAttributes.add(attr.replace(KSE.namespaceUU, '').toLowerCase().trim()); 
                }
            }
            return serialAttributes;
        } set;
    }
}