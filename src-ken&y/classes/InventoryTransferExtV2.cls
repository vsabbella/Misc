public with sharing class InventoryTransferExtV2 extends BaseController {
    
    ApexPages.StandardController con;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    public Inventory_Change__c inventoryChange { get; set; }
	public SKID__c skidObj { get; set; }
    public GridRelatedListController.GridRelatedListConfig skidsConfig {get; set;}     
    public string serialFieldList { get; set; }
    public Integer gridSize {get;set;}
    public static Boolean serialTracked {get;set;}
    final String TYPE_REFERENCE = 'reference' ;
    public String skidsFieldList = null;
    public static string serialAttributes { get;set;}
    public static list<string> attributesforCorrection{get;set;}{attributesforCorrection = new List<string>(); }

    public String allocatedSerialFields { get; set; }

    public InventoryTransferExtV2(ApexPages.StandardController controller) {
        
        con = controller;
        
        inventoryChange = new Inventory_Change__c();
        inventoryChange.Type__c  = 'Transfer';
        
        skidsConfig = new GridRelatedListController.GridRelatedListConfig();
        skidsConfig.uniqueId = 'skidsGrid';
        skidsConfig.title = 'Location Information';
        skidsConfig.parentRecord = inventoryChange;
        skidsConfig.objectName = 'SKID__c';  
        skidsConfig.parentField = 'Inventory_Change__c';
        skidsConfig.buttons = 'search';
        
        List<String> serialAttributesList = SkidService3.serialAttributes;
        serialAttributes = JSON.serialize(serialAttributesList);

        FieldInfo fiInt = new FieldInfo('','','integer');
        fiInt.editable = false;
        List<FieldInfo> fieldInfoList = new List<FieldInfo>{ fiInt };
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c','Serial',serialAttributesList.size() > 0 ? String.join(serialAttributesList,',') : null,false));

        allocatedSerialFields = JSON.serialize(fieldInfoList);

        for (FieldInfo fi:fieldInfoList) {
            String field = fi.field.replace(KSE.NamespaceUU,'');
            if (field.toLowerCase() == 'name') {
                fi.field = 'SerialNameId';
                fi.fieldType = TYPE_REFERENCE;
                fi.referenceTo = 'Serial__c';
            } else if (field.toLowerCase() == 'fixed_asset__c') {
                fi.editable = false;
            }
        }
        serialFieldList = JSON.serialize(fieldInfoList);
        
        gridSize = fieldInfoList.size() * 150;
        
        User_Preference__c up = UserPreference.getInstance().Preference;
        
        if( up == null || (up.Allow_access_to_all_facilities__c == false && up.default_facility__c == null) ){
            
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, Label.Default_facility_not_setup));
            return;
        }
        
        inventoryChange.Company__c = up.default_Company__c;
        Id companyId = inventoryChange.Company__c;

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name', 'Serial_Control__c'
        });
        soql.setWhereClause('Id=:companyId');
        List<Company__c> cmpList = Database.query(soql.getQuery());

        if(cmpList.size() > 0)
            inventoryChange.Company__r = cmpList[0];
        
        skidObj = new SKID__c();
        skidObj.Company__c = inventoryChange.Company__c;
        skidObj.Company__r = inventoryChange.Company__r;
        //PTM-205 Defaulting Facility from User Preference
        if(up.Default_Facility__c != null){
            inventoryChange.Facility__c = up.Default_Facility__c;
        } 
        
        if(inventoryChange.Facility__c != null){
            Id facilityId = inventoryChange.Facility__c;
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            SOQLUtil soql1 = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
            soql1.addFields(new set<string>{
                'id','Name','Company__c','Company__r.Name', 'Company__r.Serial_Control__c'
            });
            soql1.setWhereClause('Id=:facilityId');
            List<Facility__c> facList = Database.query(soql1.getQuery());

            if(facList.size() > 0){
                inventoryChange.Facility__r = facList[0];
                inventoryChange.Company__r = facList[0].Company__r;
                skidObj.Company__r = facList[0].Company__r;
            }
        }
        
        
    }
    
    public string getInventoryChangeJson() {
        return JSON.serialize(inventoryChange);  
    }
    
    public string getSkidObjJson() {
        return JSON.serialize(skidObj);  
    }
    
    public string getInventoryChangeHeaderFieldList() {
        String InventoryChangeHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Boolean facilityEditable = true;
        User_Preference__c up = UserPreference.getInstance().Preference;
        
        if( up == null || (up.Allow_access_to_all_facilities__c == false)){
            facilityEditable = false;
        }
        
        // get the requisition header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Inventory_Change__c', 'CycleCountHeader');
        fieldInfoList.remove(0); // Remove Id field from the list
        
        for(FieldInfo fi : fieldInfoList){
            if(fi.field.contains('Company__c')){
                fi.editable = false;
            }
            
            if(fi.field.contains('Facility__c')){
                fi.title = 'From Facility';
                fi.editable = facilityEditable;
                fi.required = fi.editable;
            }
            
            if(fi.field.toLowerCase() == 'company__c'  || fi.field.toLowerCase() == 'item__c' || fi.field.toLowerCase() == 'reason_code__c')
            	fi.required = true;
            
        }
        
        FieldInfo fii = new FieldInfo('To_Facility__c','To Facility',TYPE_REFERENCE);
        fii.referenceTo = 'Facility__c';
        fii.editable = facilityEditable;
        fii.title = 'To Facility';
        fii.required = fii.editable;
        fieldInfoList.add(3,fii);
        
        FieldInfo fi = new FieldInfo('To_Location__c','To Location',TYPE_REFERENCE);
        fi.referenceTo = 'Location__c';
        fi.editable = true;
        fi.title = 'Default To Location';
        fi.required = false;
        fieldInfoList.add(fi);

        FieldInfo fibin = new FieldInfo('To_Bin__c','To Bin',TYPE_REFERENCE);
        fibin.referenceTo = 'Bin__c';
        fibin.editable = true;
        fibin.title = 'Default To Bin';
        fibin.required = false;
        fieldInfoList.add(fibin);
        
        InventoryChangeHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return InventoryChangeHeaderFieldList;
    }
    
    public string getSkidsConfigJson() {
        String configStr = JSON.serialize(this.skidsConfig);
          
        return configStr;
    }
    
    
    @RemoteAction
    public static JSONResult refreshOnPkgUOMChange(Item__c item, Object facilityObj, Id fromPkgUOMId, Id pkgUOMId){
       
        JsonResult result = new JsonResult();

        SOQLUtil facilityQuery;
        Facility__c facility;
        if(facilityObj instanceof String){
            Id facilityId = (Id)facilityObj;
            facilityQuery= new SOQLUtil('Facility__c');
            facilityQuery.addField('Id');
            facilityQuery.addField('Facility_Identifier__c');
            facilityQuery.setWhereClause('Id = :facilityId');
            facility = Database.Query(facilityQuery.getQuery());
        }
        else if(facilityObj instanceof SObject){
            facility = (facility__c )facilityObj;
        }





        UOM__c pkgUOMRec = new UOM__c(Id = pkgUOMId);
        
        Id transferUOM;   
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize( item.Packaging_UOM__c, List<Id>.class );
        Item__c containerItem = SkidService3.getContainerforItem( item, pkgUOMRec );
        Decimal conversion = KSE.getConversionFactor(item.Id,facility.Facility_Identifier__c,fromPkgUOMId,pkgUOMId, lstPkgUom );
        if( conversion >=1){
            transferUOM = pkgUOMId;
        }
        else{
            conversion = 1;
            transferUOM = fromPkgUOMId;
        }
        
        result.records = new list<Object>{containerItem,transferUOM, conversion};
        Decimal conversionFactorForStocking = KSE.getConversionFactor(item.Id,facility.Facility_Identifier__c,transferUOM,item.Stocking_UOM__c, lstPkgUom);
        result.additionalInfo = String.valueOf(conversionFactorForStocking);
         
        return result; 
    }
   
    @RemoteAction
    public static JsonResult getItemDetails(SKID__c skidobj, List<String> headerDateFields,List<String> attributesToCorrect) {
        JsonResult result = new JsonResult();
        Id itId = skidobj.Item__c;
        Set<String> fieldStrings = new Set<String>{'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c', 'Container__c',
                                    'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c','Packaging_UOM__c','Stocking_UOM__c',
                                    'Stocking_UOM__r.Package_Class__c', 'Stocking_UOM__r.Package_Class__r.Default_Container_Item__c',
                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c',
                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
                                    'Container_Item__c','Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container_Package_Class__c'
        };
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));
       
        String whereClause = 'Id =:itId ';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);   

        Item__c item;
        
        List<Item__c> items = database.query(soql.getQuery());
        if(items.size() > 0 ){ 
            item = items[0];
        }
        
        result.records = items;


        List<FieldInfo> fiList = new List<FieldInfo>();

        FieldInfo f = new FieldInfo('Location__c', 'From Location', 'reference');
        f.referenceTo = 'Location__c';
        fiList.add(f);

        f = new FieldInfo('Bin__c', 'From Bin', 'reference');
        f.referenceTo = 'Bin__c';
        fiList.add(f);

        List<String> skidFields = new List<String>{ 'Customer__c', 'Consigned_Owner__c' };
        skidFields.addAll(SkidService3.trackedAttributes(null, null, item, SkidService3.getContainerforItem(item, null)));
        fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields));

        f = new FieldInfo('toskid.Location__c', 'To Location', 'reference');
        f.referenceTo = 'Location__c';
        f.editable = true;
        fiList.add(f);
        
        f = new FieldInfo('toskid.Bin__c', 'To Bin', 'reference');
        f.referenceTo = 'Bin__c';
        f.editable = true;
        fiList.add(f);
        
        Set<String> attrsToCorrectSet = new Set<String>();
        if (attributesToCorrect != null && attributesToCorrect.size() > 0) {
            attrsToCorrectSet = new Set<String>(attributesToCorrect);

            if (attrsToCorrectSet.contains('Packaging_UOM__c') == true && (new Set<String>(skidFields)).contains('License_Plate_Number__c') == true) {
                attributesToCorrect.add('License_Plate_Number__c');
            }
            
            List<FieldInfo> fiList2 = FieldInfo.fetchJsonFieldInfos('SKID__c', attributesToCorrect);
            for (FieldInfo fi:fiList2) {
                if (fi.field == 'License_Plate_Number__c') fi.validateLookupOnBlur = true;
                fi.required = false;
                fi.editable = true;
                fi.title = 'To ' + fi.title;
                fi.field = 'toskid.' + fi.field;
            }
            fiList.addAll(fiList2);
        }
        
        f = new FieldInfo('toskid.Quantity_Available__c', 'Quantity Available', 'double');
        f.editable = false;
        f.precision = 18;
        f.scale = 6;
        fiList.add(f);
            
        f = new FieldInfo('Input_Quantity__c', 'Quantity to Transfer/Update', 'double');
        f.precision = 18;
        f.scale = 6;
        fiList.add(f);
        
        for (FieldInfo fi:fiList) {
            if (fi.field.contains('toskid.') == false) {
                fi.field = 'skid.' + fi.field;
                fi.editable = false;
            }
        }
        
        fiList[fiList.size() - 1].editable = true;

        if (attrsToCorrectSet.contains('Packaging_UOM__c') == true) {
            f = new FieldInfo('Stocking_UOM__c', 'Transfer UOM', 'reference');
            f.editable = false;
            f.referenceTo = 'UOM__c';
            f.field = 'toskid.' + f.field;
            fiList.add(f);
        }
        
        result.additionalInfo = JSON.serialize(fiList);
        return result;
    }
   
    @RemoteAction
    public static string getInvAdditionalFields(String itemId) {
        String invAdditionalFieldList = '';
        Id itId = (Id)itemId;
        Set<String> fieldStrings = new Set<String>{'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Container__c',
                                    'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c'};
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));
       
        String whereClause = 'Id =:itId ';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);

        Item__c it;
        
        List<Item__c> items = database.query(soql.getQuery());
        if(items.size() > 0 ){
            it = items[0];
        }

         
        List<FieldInfo> fiList = new List<FieldInfo>();
        
        FieldInfo f = new FieldInfo('Location__c', 'From Location', 'reference');
        f.referenceTo = 'Location__c';
        f.editable = true;
        fiList.add(f);
                
        f = new FieldInfo('Bin__c', 'From Bin', 'reference');
        f.referenceTo = 'Bin__c';
        f.editable = true;
        fiList.add(f);

        List<String> skidFields = new List<String>{ 'Customer__c' };
        skidFields.addAll(SkidService3.trackedAttributes(null, null, it));
        Set<String> skidFieldSet = new Set<String>(skidFields);
        if (skidFieldSet.contains('lot_number__c')) {
            skidFieldSet.remove('lot_number__c');
            skidFieldSet.add('lot__c');
            skidFields = new List<String>(skidFieldSet);
        }
        
        fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', skidFields));
        return JSON.serialize(fiList);
    }

    @RemoteAction
    public static Map<String,Object> getAttrOptions(String itemId) {
        String invAdditionalFieldList = '';
        Id itId = (Id)itemId;
        Set<String> fieldStrings = new Set<String>{'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Container__c',
                'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c'};
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));

        String whereClause = 'Id =:itId ';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);

        Item__c it;

        List<Item__c> items = database.query(soql.getQuery());
        if(items.size() > 0 ){
            it = items[0];
        }

        if (attributesforCorrection == null) attributesforCorrection = new List<String>();

        Set<String> ignoreAttributes = new Set<String>();

        List<String> trackedFields = SkidService3.trackedAttributes(null, null, it);

        List<String> fieldlist = util.getFieldsFromFieldSetString( Item_Attribute__c.sObjectType , 'Attributes_To_Exclude');

        for (String str : fieldlist){
            String s = str.replace( KSE.namespaceUU, '').toLowerCase();
            ignoreAttributes.add(s);
        }
        for(String str: trackedFields){

            if(!ignoreAttributes.contains(str)){
                attributesforCorrection.add(str);
            }
        }
        List<FieldInfo> trackedfieldInfoList = new  List<FieldInfo>();
        trackedfieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c', attributesforCorrection);
        Map<String,FieldInfo> FieldInfoByField = new Map<String,FieldInfo>();
        for(FieldInfo tfi: trackedfieldInfoList){
            tfi.title = 'Default To ' +tfi.title;
            FieldInfoByField.put(tfi.field, tfi);
        }
        return FieldInfoByField;
    }
    @RemoteAction
    public static Location__c getLocationRecord( String locationId){
        
        Id locId = (Id)locationId;
        Set<String> fieldStrings = new Set<String>{'Id','Name','Bin_Tracked__c'};
        
        //String queryString = util.generateQueryFromFieldSet('Location__c', new Set<string>{}, fieldStrings, ' Id =:locId ');
        Location__c loc;
        
        SOQLUtil soql = new SOQLUtil('Location__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(' Id = :locId ');
        
        List<Location__c> locations = Database.query(soql.getQuery());
        
        if(locations.size() > 0 ){
            loc = locations[0];
        }
        return loc;
    }

    @RemoteAction
    public static JsonResult getSkids(Id itemId,Id facilityId,SKID__c filterSkid,Id toFacilityId,Id toLocationId,Id toBinId,String defPKGUOM,String skidAttributeStr,List<String> attrsToCorrect,List<String> dateFields) {
        JsonResult result = new JsonResult();

        try {
            KendoUtils.UpdateDateFields(filterSkid,dateFields);

            Location__c loc;
            Bin__c bin;
            Facility__c tofacility ;

            if (!String.isBlank(toLocationId)) {
                SOQLUtil locQuery = new SOQLUtil('Location__c');
                locQuery.addAllCustomFields();
                locQuery.addField('Facility__r.Name');
                locQuery.addField('Facility__r.Facility_Identifier__c');
                locQuery.setWhereClause('Id = \'' + toLocationId + '\'');
                loc = Database.query(locQuery.getQuery());
            }

            if(!String.isBlank(toBinId)){
                 bin=[select id,name from Bin__c where Id=:toBinId];
            }

            if(!String.isBlank(toFacilityId)){

                SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
                facilityQuery.addField('Id');
                facilityQuery.addField('Facility_Identifier__c');
                facilityQuery.setWhereClause('Id = :toFacilityId');
                tofacility = Database.Query(facilityQuery.getQuery());

            }

            Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 'Item__c' => new Set<Id>{ itemId }, 'Facility2__c' => new Set<Id>{ facilityId } };
            if (filterSkid.Location__c != null) filters.put('Location__c',new Set<Id>{ filterSkid.Location__c });

            if(String.isNotEmpty(skidAttributeStr)){
                Map<String,String> optionalAttributeFilters = (Map<String,String>) JSON.deserialize(skidAttributeStr,  Map<String,String>.class);
                for(String Str:optionalAttributeFilters.keyset() ){
                    if(String.isNotEmpty(optionalAttributeFilters.get(Str))){
                        filters.put(Str,new Set<Id>{optionalAttributeFilters.get(Str)});
                    }
                }
            }


            List<String> attrFields = SkidService3.attributesForPutaway();
            List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
            for (SkidService3.SerialWrapper sw:InventoryChangeService.getSkids(filters,null, null, false)) { 
                Boolean validSkid = true;
                for (String attr:attrFields) {
                    if ((!SkidService3.attributesToExclude.contains(attr.toLowerCase()))
                            && filterSkid.get(attr) != null
                            && (attr.toLowerCase() != 'lot__c'  && filterSkid.get(attr) != sw.skid.get(attr)))
                    {
                        validSkid = false;
                        break;
                    }
                }
                if (validSkid) {
                    SKID__c toSkid = new SKID__c(Company__c = sw.skid.Company__c, Item__c = sw.skid.Item__c, Item__r = sw.skid.Item__r,
                        Facility2__c = sw.skid.Facility2__c);
                        
                    if(toFacilityId != null){
                        toSkid.Facility2__c = toFacilityId;
                    }    
                      
                    if (loc != null) {
                        toSkid.Facility2__c = loc.Facility__c;
                        toSkid.Facility2__r = loc.Facility__r;
                        toSkid.Location__c = loc.Id;
                        toSkid.Location__r = loc;
                        if(bin!=null){
                            toSkid.Bin__c = bin.Id;
                            toSkid.Bin__r = bin;
                        }
                    }
                    else if (facilityId == toFacilityId && (attrsToCorrect!=null && attrsToCorrect.size()>0)) {
                        toSkid.Location__c = sw.skid.Location__c;
                        toSkid.Location__r = sw.skid.Location__r;
                        toSkid.Bin__c = sw.skid.Bin__c;
                        toSkid.Bin__r = sw.skid.Bin__r;
                    }
                    toSkid.Stocking_UOM__c = null;
                    toSkid.Stocking_UOM__r = null;
                    toSkid.Quantity_Available__c = sw.skid.Quantity_Available__c;
                    if(!String.isEmpty(defPKGUOM)){
                        Item__c item = sw.skid.Item__r;
                        JSONResult UOMConversionresult = refreshOnPkgUOMChange( item,  tofacility , sw.skid.Packaging_UOM__c,(Id) defPKGUOM);
                        List<Object> UOMConversionObjects = UOMConversionresult.records;
                        if(UOMConversionObjects.size()>0){
                            decimal UOMconversion = (decimal)UOMConversionObjects[2];
                            toSkid.Quantity_Available__c = sw.skid.Quantity_Available__c * UOMconversion;

                        }


                    }
                    swList.add(new SkidService3.SerialWrapper(sw.skid,null,sw.serialList,toSkid));
                }
            }

            result.records = swList;
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }

    @RemoteAction
    public static JsonResult saveAction(Inventory_Change__c ic, List<SkidService3.SerialWrapper> skids, List<String> attrsToCorrect, Id itemId, Id facilityId, SKID__c filterSkid, List<String> icDateFields, List<String> skidDateFields) {
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        try {
            Map<Id, SkidService3.SerialWrapper> existingSkids = new Map<Id, SkidService3.SerialWrapper>();
            for (SkidService3.SerialWrapper sw:(List<SkidService3.SerialWrapper>)getSkids(itemId, facilityId, filterSkid, null,null,null, null,null, null, skidDateFields).records) {
                existingSkids.put(sw.skid.Id, sw);
            }

            List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
            for (SkidService3.SerialWrapper sw:skids) {
                KendoUtils.UpdateDateFields(sw.skid, skidDateFields);
                KendoUtils.UpdateDateFields(sw.toskid, skidDateFields);

                if (!existingSkids.containsKey(sw.skid.Id)) throw new CustomException('Inventory could not be found. Please search and retry.');

                SkidService3.SerialWrapper existingSw = existingSkids.get(sw.skid.Id);
                existingSw.skid.Input_Quantity__c = sw.skid.Input_Quantity__c;
                existingSw.toskid = sw.toskid;

                if (existingSw.serialList != null && existingSw.serialList.size() > 0) {
                    Map<Id, Serial__c> existingSerials = new Map<Id, Serial__c>(existingSw.serialList);
                    for (Serial__c serial:sw.serialList) {
                        if (!existingSerials.containsKey(serial.Id)) throw new CustomException('Serial ' + serial.Name + ' could not be found. Please search and retry.');
                    }
                    existingSw.serialList = sw.serialList;
                }

                swList.add(existingSw);
            }

            KendoUtils.UpdateDateFields(ic, icDateFields);
            if (ic.Id == null) DML.insertAsUser(ic);
            InventoryChangeService.inventoryTransfer(new List<InventoryChangeWrapper>{ new InventoryChangeWrapper(ic, swList) }, attrsToCorrect);
            result.additionalInfo = ic.id;
        } catch (Exception e) {
            Database.rollback(sp);
            CustomException.addError(result, e);
        }
        return result;
    }
}