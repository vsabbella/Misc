public with sharing class ManageUOMConversionsExt extends BaseController {
    public String NamespaceUU { get { return KSE.NamespaceUU; }}
    public Id defaultUOMId { get; set; }
    public static Map<Id, UOM__c> uomsMap = new Map<Id, UOM__c>();
    public static Map<Id, Item__c> itemMap = new Map<Id, Item__c>();
    public static Map<String, Facility__c> facilityMap = new Map<String, Facility__c>();
    public static Map<Decimal, Facility__c> facilityByIdentifier = new Map<Decimal, Facility__c>();
    public String uomQuery { get; set; } { uomQuery = 'SELECT Id, Name, Key_1__c, Key_2__c, UOM_1__c, UOM_2__c, Item__c, UOM_1_Quantity__c, UOM_2_Quantity__c, Facility_Identifier__c FROM UOM_Conversion_Details__c '; }

    public GridRelatedListController.GridRelatedListConfig uomConversionLinesConfig { get; set; } {
        uomConversionLinesConfig = new GridRelatedListController.GridRelatedListConfig();
        uomConversionLinesConfig.uniqueId = 'UOMMasterViewGrid';
        uomConversionLinesConfig.title = 'UOM Conversions';
        uomConversionLinesConfig.buttons = 'create, save, delete, search';
    }

    public ManageUOMConversionsExt(ApexPages.StandardController con) { init(); }
    public ManageUOMConversionsExt(ApexPages.StandardSetController setCon) { init(); }
    public void init() {
        defaultUOMId = ApexPages.currentPage().getParameters().get('id');
    }

    public String getUomConversionLinesConfigJson() {
        return JSON.serialize(uomConversionLinesConfig);
    }

    public String getUomConversionLinesFieldList() {
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();

        // UOM-1 field
        FieldInfo fieldInfoItem = new FieldInfo('uom1Id', Schema.SObjectType.UOM_Conversion_Details__c.fields.UOM_1__c.getLabel(), 'reference');
        fieldInfoItem.editable = true;
        fieldInfoItem.referenceTo = 'Uom__c';
        fieldInfoList.add(fieldInfoItem);

        // UOM-1-Quantity field
        fieldInfoItem = new FieldInfo('uom1Quantity', Schema.SObjectType.UOM_Conversion_Details__c.fields.UOM_1_Quantity__c.getLabel(), 'string');
        fieldInfoItem.editable = true;
        fieldInfoList.add(fieldInfoItem);

        // UOM-2 field
        fieldInfoItem = new FieldInfo('uom2Id', Schema.SObjectType.UOM_Conversion_Details__c.fields.UOM_2__c.getLabel(), 'reference');
        fieldInfoItem.editable = true;
        fieldInfoItem.referenceTo = 'Uom__c';
        fieldInfoList.add(fieldInfoItem);

        // UOM-2-Quantity field
        fieldInfoItem = new FieldInfo('uom2Quantity', Schema.SObjectType.UOM_Conversion_Details__c.fields.UOM_2_Quantity__c.getLabel(), 'string');
        fieldInfoItem.editable = true;
        fieldInfoItem.scale = 6;
        fieldInfoList.add(fieldInfoItem);

        // Items field
        fieldInfoItem = new FieldInfo('itemId', Schema.SObjectType.UOM_Conversion_Details__c.fields.Item__c.getLabel(), 'reference');
        fieldInfoItem.editable = true;
        fieldInfoItem.referenceTo = 'Item__c';
        fieldInfoList.add(fieldInfoItem);

        fieldInfoItem = new FieldInfo('facilityId', Schema.SObjectType.Facility__c.getLabel(), 'reference');
        fieldInfoItem.editable = true;
        fieldInfoItem.referenceTo = 'Facility__c';
        fieldInfoList.add(fieldInfoItem);

        return JSON.serialize(fieldInfoList);
    }

    @RemoteAction
    public static JsonResult getUOMWrappers(List<UOM_Conversion_Details__c> uomList) {

	    List<UomConversionWrapper> result = new List<UomConversionWrapper>();

	    set<Id> uomSet = new set<Id>();
	    set<Id> itemSet = new set<Id>();
	    Set<Decimal> facilityIdentifiers = new Set<Decimal> ();

	    for(UOM_Conversion_Details__c uomC: uomList)
        {
            if(uomC.Uom_1__c!=null)
                uomSet.add(uomC.Uom_1__c);
            if(uomC.Uom_2__c!=null)
                uomSet.add(uomC.Uom_2__c);
            if(uomC.Item__c!=null)
                itemSet.add(uomC.Item__c);
            if ( uomC.Facility_Identifier__c != null )
                facilityIdentifiers.add(uomC.Facility_Identifier__c);
        }

        SOQLUtil soql = new SOQLUtil('Uom__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name'
        });
        soql.setWhereClause('id in:uomSet');
        uomsMap = new Map<id,Uom__c>((List<Uom__c>)Database.query(soql.getQuery()));

        soql = new SOQLUtil('item__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','Company__r.Id'
        });
        soql.setWhereClause('id in:itemSet');
        itemMap = new Map<id,item__c>((List<item__c>)Database.query(soql.getQuery()));

        soql = new SOQLUtil('facility__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','Facility_Identifier__c'
        });
        soql.setWhereClause('Facility_Identifier__c in:facilityIdentifiers');

        for (Facility__c facility: (List<facility__c>)Database.query(soql.getQuery()) ) {
            facilityByIdentifier.put(facility.Facility_Identifier__c, facility);
        }

	    for (UOM_Conversion_Details__c uom: uomList) {
			result.add(new UomConversionWrapper(uom));
		}

    	return new JsonResult(result, result.size());
    }

    private static String getConvName(UomConversionWrapper wrapper) {
        return wrapper.uom1.Name + ' -> ' + wrapper.uom2.Name + (String.isBlank(wrapper.conversion.Item__c) == false ? ' (' + wrapper.item.Name + ')' : '') + ': ';
    }

    private static UOM_Conversion_Details__c generateUomConversion(UomConversionWrapper wrapper) {
        String convName = getConvName(wrapper);
        if (String.isBlank(wrapper.uom1Id)) throw new CustomException('UOM 1 cannot be blank. Please select a valid UOM 1.');
        if (String.isBlank(wrapper.uom2Id)) throw new CustomException('UOM 2 cannot be blank. Please select a valid UOM 2.');
        if (String.isBlank(wrapper.uom1Quantity) || !(Decimal.valueOf(wrapper.uom1Quantity) > 0)) throw new CustomException(convName + 'UOM 1 quantity must be greater than 0.');
        if (String.isBlank(wrapper.uom2Quantity) || !(Decimal.valueOf(wrapper.uom2Quantity) > 0)) throw new CustomException(convName + 'UOM 2 quantity must be greater than 0.');
        if (wrapper.uom1Id == wrapper.uom2Id) throw new CustomException(convName + 'UOM 1 and UOM 2 cannot be the same');

        Decimal facilityIdentifier = wrapper.facility != null && facilityMap.containsKey(wrapper.facility.Id) ? facilityMap.get(wrapper.facility.Id).Facility_Identifier__c : null;
        return new UOM_Conversion_Details__c(
            Name = (wrapper.itemId != null ? wrapper.itemId.substring(3, 15) : '') + wrapper.uom1Id.substring(3, 15) + wrapper.uom2Id.substring(3, 15) + (facilityIdentifier == null ? '' : ''+facilityIdentifier),
            Item__c = wrapper.itemId != null ? wrapper.itemId : '',
            UOM_1__c = wrapper.uom1Id,
            UOM_2__c = wrapper.uom2Id,
            Facility_Identifier__c = facilityIdentifier,
            Uom_1_Quantity__c = Decimal.valueOf(wrapper.uom1Quantity),
            Uom_2_Quantity__c = Decimal.valueof(wrapper.uom2Quantity),
            Key_1__c = wrapper.uom1Id + wrapper.uom2Id + (wrapper.itemId != null ? wrapper.itemId : '') + (facilityIdentifier == null ? '' : ''+facilityIdentifier),
            Key_2__c = wrapper.uom2Id + wrapper.uom1Id + (wrapper.itemId != null ? wrapper.itemId : '') + (facilityIdentifier == null ? '' : ''+facilityIdentifier)
        );
    }

    @RemoteAction
    public static JsonResult saveUomConversionLines(List<UomConversionWrapper> updatedConvs, List<UomConversionWrapper> newConvs, List<UomConversionWrapper> deletedConvs) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            List<UomConversionWrapper> wrappersToDelete = new List<UomConversionWrapper>(deletedConvs);
            wrappersToDelete.addAll(updatedConvs);

            List<UOM_Conversion_Details__c> convsToDelete = new List<UOM_Conversion_Details__c>();
            Map<String, UOM_Conversion_Details__c> convsToCheck = new Map<String, UOM_Conversion_Details__c>();
            Set<String> keysDeleting = new Set<String>();
            for (UomConversionWrapper wrapper:wrappersToDelete) {
                UOM_Conversion_Details__c conv = wrapper.conversion;
                convsToDelete.add(conv);
                convsToCheck.put(conv.Key_1__c, conv);
                keysDeleting.add(conv.Key_1__c);
            }

            List<UomConversionWrapper> wrappersToInsert = new List<UomConversionWrapper>(updatedConvs);
            wrappersToInsert.addAll(newConvs);

            List<UOM_Conversion_Details__c> convsToInsert = new List<UOM_Conversion_Details__c>();
            Set<String> keysInserting = new Set<String>();
            Set<Id> uomIds = new Set<Id>();
            Set<Id> facilityIds = new Set<Id>();
            Map<Id, Facility__c> facilities = new Map<Id, Facility__c>();
            for (UomConversionWrapper wrapper:wrappersToInsert) {
                if ( wrapper.facility != null ) facilityIds.add(wrapper.facility.Id);
            }

            if ( !facilityIds.isEmpty()) {
                SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
                facilityQuery.addFields(new Set<String>{'Id','Name','Facility_Identifier__c'});
                facilityQuery.setWhereClause('Id in :facilityIds');
                facilityMap = new Map<String, Facility__c>((List<Facility__c>)Database.query(facilityQuery.getQuery()));
            }

            for (UomConversionWrapper wrapper:wrappersToInsert) {
                UOM_Conversion_Details__c conv = generateUomConversion(wrapper);
                wrapper.conversion = conv;

                if (keysInserting.contains(conv.Key_1__c)) throw new CustomException(getConvName(wrapper) + 'Duplicate UOM conversion');

                Set<String> keys = new Set<String>{ conv.Key_1__c, conv.Key_2__c };
                for (String key:keys) {
                    if (convsToCheck.containsKey(key)) {
                        Decimal convFactor = key == conv.Key_1__c ? conv.UOM_2_Quantity__c / conv.UOM_1_Quantity__c : conv.UOM_1_Quantity__c / conv.UOM_2_Quantity__c;
                        UOM_Conversion_Details__c oldConv = convsToCheck.get(key);
                        Decimal oldConvFactor = key == oldConv.Key_1__c ? oldConv.UOM_2_Quantity__c / oldConv.UOM_1_Quantity__c : oldConv.UOM_1_Quantity__c / oldConv.UOM_2_Quantity__c;
                        if (convFactor == oldConvFactor) convsToCheck.remove(key);
                    }
                }

                convsToInsert.add(conv);
                keysInserting.add(conv.Key_1__c);
                keysInserting.add(conv.Key_2__c);
                uomIds.add(conv.UOM_1__c);
                uomIds.add(conv.UOM_2__c);
                if (String.isBlank(conv.Item__c) == false) convsToCheck.put(conv.Key_1__c, conv);
            }

            Set<Id> uomsToCheck = new Set<Id>();
            Set<Id> itemIds = new Set<Id>();
            for (UOM_Conversion_Details__c conv:convsToCheck.values()) {
                uomIds.add(conv.UOM_1__c);
                uomIds.add(conv.UOM_2__c);
                uomsToCheck.add(conv.UOM_1__c);
                uomsToCheck.add(conv.UOM_2__c);

                if (String.isBlank(conv.Item__c)) itemIds = null;
                else if (itemIds != null) itemIds.add((Id)conv.Item__c);
            }

            SOQLUtil uomQuery = new SOQLUtil('UOM__c');
            uomQuery.addFields(new Set<String>{ 'Id', 'Name', 'Package_Class__c', 'Package_Class__r.Level__c', 'Package_Class__r.Parent_Package_Class__c', 'Package_Class__r.Parent_Package_Class__r.Parent_Package_Class__c', 'Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c' });
            uomQuery.setWhereClause('Id IN :uomIds');
            Map<Id, UOM__c> uoms = new Map<Id, UOM__c>((List<UOM__c>)Database.query(uomQuery.getQuery()));

            if (wrappersToInsert.size() > 0) {
                SOQLUtil uomConvQuery = new SOQLUtil('UOM_Conversion_Details__c');
                uomConvQuery.addFields(new Set<String>{ 'Id', 'Name', 'Key_1__c', 'Key_2__c' });
                uomConvQuery.setWhereClause('(Key_1__c IN :keysInserting OR Key_2__c IN :keysInserting) AND Key_1__c NOT IN :keysDeleting AND Key_2__c NOT IN :keysDeleting');
                Set<String> existingKeys = new Set<String>();
                for (UOM_Conversion_Details__c conv:Database.query(uomConvQuery.getQuery())) {
                    existingKeys.add(conv.Key_1__c);
                    existingKeys.add(conv.Key_2__c);
                }

                for (UomConversionWrapper wrapper:wrappersToInsert) {
                    UOM_Conversion_Details__c conv = wrapper.conversion;
                    String convName = getConvName(wrapper);

                    if (existingKeys.contains(conv.Key_1__c)) throw new CustomException(convName + 'UOM conversion already exists');

                    UOM__c uom1 = uoms.get(conv.UOM_1__c);
                    UOM__c uom2 = uoms.get(conv.UOM_2__c);
                    if (uom1.Package_Class__c != null && uom2.Package_Class__c != null ) {
                        if (uom1.Package_Class__c != uom2.Package_Class__c && uom1.Package_Class__r.Parent_Package_Class__c != uom2.Package_Class__c && uom1.Package_Class__c != uom2.Package_Class__r.Parent_Package_Class__c) {
                            throw new CustomException(convName + 'UOM conversions can only be between UOMs of the same or adjacent package classes');
                        }
                        if ( uom1.Package_Class__r.Parent_Package_Class__c != null && uom2.Package_Class__r.Parent_Package_Class__c != null && conv.Facility_Identifier__c != null) {
                            throw new CustomException(convName + 'You can\'t create a facility-based UOM conversion for a UOM that\'s not at the top level of your package class hierarchy.');
                        }
                        if ( conv.Facility_IDentifier__C != null ) {
                            if (uom1.Package_Class__r.Parent_Package_Class__c == uom2.Package_Class__c
                                    && (uom2.Package_Class__r.Default_Container_Item__r.Item_Attribute__c == null
                                    || !uom2.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c)) {
                                throw new CustomException(convName + 'You can\'t create a facility-based UOM conversion for a packaging UOM that\'s not LPN tracked.');
                            } else if (uom2.Package_Class__r.Parent_Package_Class__c == uom1.Package_Class__c
                                    && (uom1.Package_Class__r.Default_Container_Item__r.Item_Attribute__c == null
                                    || !uom1.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c)) {
                                throw new CustomException(convName + 'You can\'t create a facility-based UOM conversion for a packaging UOM that\'s not LPN tracked.');
                            }
                        }
                    }
                    if(conv.Facility_IDentifier__C != null && (uom1.Package_Class__c==null || uom2.Package_Class__c==null)){
                        throw new CustomException(convName + 'You can\'t create a facility-based UOM conversion for a packaging UOM that\'s not LPN tracked.');
                    }

                }
            }

            if (uomsToCheck.size() > 0) {
                //This should be recursive for n levels of UOMs
                Set<Id> packageClassIds = new Set<Id>();
                for (UOM__c uom:uoms.values()) {
                    if (uomsToCheck.contains(uom.Id) && uom.Package_Class__c != null) {
                        packageClassIds.add(uom.Package_Class__c);
                        if (uom.Package_Class__r.Parent_Package_Class__c != null) {
                            packageClassIds.add(uom.Package_Class__r.Parent_Package_Class__c);
                            if (uom.Package_Class__r.Parent_Package_Class__r.Parent_Package_Class__c != null) packageClassIds.add(uom.Package_Class__r.Parent_Package_Class__r.Parent_Package_Class__c);
                        }
                    }
                }

                uomQuery.setWhereClause('Package_Class__c IN :packageClassIds');
                uomQuery.setOrderByClause('Package_Class__r.Level__c DESC');
                Map<Id, Map<Integer, Set<Id>>> uomLevels = new Map<Id, Map<Integer, Set<Id>>>();
                for (UOM__c uom:Database.query(uomQuery.getQuery())) {
                    uoms.put(uom.Id, uom);

                    Map<Integer, Set<Id>> levels;
                    if (uomLevels.containsKey(uom.Package_Class__c)) levels = uomLevels.get(uom.Package_Class__c);
                    else if (uom.Package_Class__r.Parent_Package_Class__c != null && uomLevels.containsKey(uom.Package_Class__r.Parent_Package_Class__c)) levels = uomLevels.get(uom.Package_Class__r.Parent_Package_Class__c);
                    else if (uom.Package_Class__r.Parent_Package_Class__c != null && uom.Package_Class__r.Parent_Package_Class__r.Parent_Package_Class__c != null && uomLevels.containsKey(uom.Package_Class__r.Parent_Package_Class__r.Parent_Package_Class__c)) levels = uomLevels.get(uom.Package_Class__r.Parent_Package_Class__r.Parent_Package_Class__c);
                    else levels = new Map<Integer, Set<Id>>();

                    if (!levels.containsKey(uom.Package_Class__r.Level__c.intValue())) levels.put(uom.Package_Class__r.Level__c.intValue(), new Set<Id>{ uom.Id });
                    else levels.get(uom.Package_Class__r.Level__c.intValue()).add(uom.Id);

                    uomLevels.put(uom.Package_Class__c, levels);
                }

                SOQLUtil skidQuery = new SOQLUtil('SKID__c');
                skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Item__c', 'Packaging_UOM__c', 'Stocking_UOM__c', 'Facility2__r.Facility_identifier__c' });
                skidQuery.setWhereClause('(Packaging_UOM__c IN :uomsToCheck OR Packaging_UOM__r.Package_Class__c IN :packageClassIds)' + (itemIds != null ? ' AND Item__c IN :itemIds' : ''));
                Set<Id> uomsWithSkids = new Set<Id>();
                Map<Id, String> itemNames = new Map<Id, String>();
                Map<Id, Set<Id>> itemsWithSkids = new Map<Id, Set<Id>>();
                Map<String, Set<Id>> skidsForFacility = new Map<String, Set<Id>>();
                for (SKID__c skid:Database.query(skidQuery.getQuery())) {
                    if (skid.Packaging_UOM__c != skid.Stocking_UOM__c) {
                        uomsWithSkids.add(skid.Packaging_UOM__c);
                        itemNames.put(skid.Item__c, skid.Item__r.Name);

                        if (!itemsWithSkids.containsKey(skid.Item__c)) itemsWithSkids.put(skid.Item__c, new Set<Id>{ skid.Packaging_UOM__c });
                        else itemsWithSkids.get(skid.Item__c).add(skid.Packaging_UOM__c);

                        String key1 = skid.Item__c + '' + skid.Facility2__r.Facility_identifier__c;
                        String key2 = '' + skid.Facility2__r.Facility_identifier__c;
                        if (!skidsForFacility.containsKey(key1)) skidsForFacility.put(key1, new Set<Id>{ skid.Packaging_UOM__c });
                        else skidsForFacility.get(key1).add(skid.Packaging_UOM__c);

                        if (!skidsForFacility.containsKey(key2)) skidsForFacility.put(key2, new Set<Id>{ skid.Packaging_UOM__c });
                        else skidsForFacility.get(key2).add(skid.Packaging_UOM__c);
                    }
                }

                for (UOM_Conversion_Details__c conv:convsToCheck.values()) {
                    if (String.isBlank(conv.Item__c) == false && itemsWithSkids.containsKey((Id) conv.Item__c) == false ) continue;
                    String facilityIdWithItem = conv.Item__c + '' + ( conv.Facility_identifier__c != null ? ''+conv.Facility_Identifier__c : '');
                    String facilityId = '' + ( conv.Facility_identifier__c != null ? ''+conv.Facility_Identifier__c : '');

                    UOM__c uom1 = uoms.get(conv.UOM_1__c);
                    UOM__c uom2 = uoms.get(conv.UOM_2__c);
                    String exMsg = uom1.Name + ' -> ' + uom2.Name + (String.isBlank(conv.Item__c) == false ? ' (' + itemNames.get((Id) conv.Item__c) + ')' : '') + ': You can\'t make changes to a UOM conversion that\'s being used by inventory. Zero out all inventory that\'s using this UOM conversion before you add, modify, or delete the UOM conversion. (';
                    Set<Id> uomSet = String.isBlank(conv.Item__c)
                                        ? (!String.isBlank(facilityId) ? skidsForFacility.get(facilityId) : uomsWithSkids)
                                        : (!String.isBlank(facilityId) ? skidsForFacility.get(facilityIdWithItem): itemsWithSkids.get((Id) conv.Item__c));
                    if ( uomSet != null && !uomSet.isEmpty() ) {
                        if (uom1.Package_Class__c != null && uom2.Package_Class__c != null) {
                            Integer maxLv;
                            for (Integer lv : uomLevels.get(uom1.Package_Class__c).keySet()) {
                                if (maxLv == null || lv > maxLv) maxLv = lv;
                            }

                            Integer minLv = Math.min(uom1.Package_Class__r.Level__c, uom2.Package_Class__r.Level__c).intValue() + 1;

                            for (Integer i = minLv; i <= maxLv; i++) {
                                if ((i == uom1.Package_Class__r.Level__c || i == uom2.Package_Class__r.Level__c) && uomSet.contains(i == uom1.Package_Class__r.Level__c ? uom1.Id : uom2.Id)) {
                                    throw new CustomException(exMsg + (i == uom1.Package_Class__r.Level__c ? uom1.Name : uom2.Name) + ')');
                                } else {
                                    for (Id uomId : uomLevels.get(uom1.Package_Class__c).get(i)) {
                                        if (uomSet.contains(uomId)) throw new CustomException(exMsg + uoms.get(uomId).Name + ')');
                                    }
                                }
                            }
                        } else if (uomSet.contains(uom1.Id) || uomSet.contains(uom2.Id)) {
                            throw new CustomException(exMsg + (uomSet.contains(uom1.Id) ? uom1.Name : uom2.Name) + ')');
                        }
                    }
                }
            }

            DML.deleteAsSystem(convsToDelete);
            DML.insertAsSystem(convsToInsert);
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }

        return result;
    }


    public class UomConversionWrapper {
        public UOM_Conversion_Details__c conversion { get; set; }
        public String uomConversionId { get; set; }
        public String uom1Id { get; set; }
        public Uom__c uom1 { get; set; }
        public String uom2Id { get; set; }
        public Uom__c uom2 { get; set; }
        public String uom1Quantity { get; set; } { uom1Quantity = '0'; }
        public String uom2Quantity { get; set; } { uom2Quantity = '0'; }
        public String itemId { get; set; }
        public Item__c item { get; set; }
        public String facilityId {get;set;}
        public Facility__c facility {get;set;}

        public UomConversionWrapper(UOM_Conversion_Details__c uomConversion) {
            this.conversion = uomConversion;
            this.uomConversionId = uomConversion.Id;

            this.uom1Id = uomConversion.UOM_1__c;
            if (uomsMap != null && uomsMap.size() > 0 && uomsMap.containsKey(uomConversion.UOM_1__c)) this.uom1 = uomsMap.get(uomConversion.UOM_1__c);
            this.uom2Id = uomConversion.UOM_2__c;
            if (uomsMap != null && uomsMap.size() > 0 && uomsMap.containsKey(uomConversion.UOM_2__c)) this.uom2 = uomsMap.get(uomConversion.UOM_2__c);
            this.uom1Quantity = String.valueof(uomConversion.UOM_1_Quantity__c);
            this.uom2Quantity = String.valueof(uomConversion.UOM_2_Quantity__c);
            this.itemId = uomConversion.Item__c;
            if (itemMap != null && itemMap.size() > 0 && itemMap.containsKey(uomConversion.Item__c)) this.item = itemMap.get(uomConversion.Item__c);
            this.facilityId = String.valueOf(uomConversion.Facility_Identifier__c);
            if ( facilityByIdentifier != null && facilityByIdentifier.containsKey(uomConversion.Facility_Identifier__c)) {
                this.facility = facilityByIdentifier.get(uomConversion.Facility_Identifier__c);
            } else if (facilityMap != null && facilityMap.containsKey(this.facilityId)) {
                this.facility = facilityMap.get(this.facilityId);
            }
        }
    }
}