public with sharing class MassInventoryChangeExt extends GridRelatedListController{
    
    public static String NamespaceUU { get { return KSE.NamespaceUU; } }
    public Boolean serialTracked { get; set; } { serialTracked = false; }
    private static SchemaUtil util = SchemaUtil.getInstance();
    public GridRelatedListController.GridRelatedListConfig skidsConfig {get; set;}   
    public Boolean allowAllFacilities { get; set; } { allowAllFacilities = false; }
    public String defaultCompany { get; set; } { defaultCompany = ''; }
    public String defaultFacility { get; set; } { defaultFacility = ''; }
    public String retURL { get; set; }
    final String TYPE_REFERENCE = 'reference';
    
    public MassInventoryChangeExt(ApexPages.StandardSetController con) {  
       
        UserPreference up = UserPreference.getInstance();
        defaultCompany = up.preference.Default_Company__c;
        defaultFacility = up.preference.Default_Facility__c;
        allowAllFacilities = up.preference.Allow_Access_to_all_Facilities__c;
        retURL = ApexPages.CurrentPage().getParameters().get('retURL');
        
        if(defaultCompany == null  ){
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, Label.Default_company_has_not_been_setup));
            return;
        }
        
         SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Name', 'Serial_Control__c'
        });
        soql.setWhereClause('Id=:defaultCompany');
        Company__c cmp = Database.query(soql.getQuery());
        if (cmp.Serial_Control__c != null && cmp.Serial_Control__c == 'At receipt and all processes') {
                serialTracked = true;
        }
        
    }
    
    @RemoteAction
    public static String save(Id companyId,Id facilityId,Id reasonCodeId,List<SkidService3.SerialWrapper> rows,List<String> dateFields) {
        Savepoint sp = Database.setSavepoint();
        JsonResult result = new JsonResult();
        Inventory_Change__c ic = new Inventory_Change__c(Company__c = companyId,Type__c = 'Adjustment',Reason_Code__c = reasonCodeId,Facility__c = facilityId);
        DML.insertAsUser(ic);
        SOQLUtil icQuery = new SOQLUtil ( 'Inventory_Change__c', true);
        icQuery.addFields ( new Set<String> {'Name','Company__r.Serial_Control__c'});
        icQuery.addAllCustomFields();
        icQuery.setWhereClause ( 'Id = \'' + ic.Id +'\'');
        List<Inventory_Change__c> lstInvChange = Database.query ( icQuery.getQuery () );
        ic.Name = lstInvChange[0].Name;
        try {
            for (SkidService3.SerialWrapper row:rows) {
                if(row.skid.lot__c != null && row.skid.lot__r.name != null && row.skid.lot_number__c == null){
                  row.skid.lot_number__c =   row.skid.lot__r.name;
                }
                KendoUtils.UpdateDateFields(row.skid,dateFields);
            }
            
            InventoryChangeWrapper icw = new InventoryChangeWrapper(lstInvChange[0],rows);
            InventoryChangeService.inventoryAdjustment( new list<InventoryChangeWrapper>{icw}, 'Adjustment');
            result = new JsonResult(new List<Inventory_Change__c>{ic},1);
            
         
        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return JSON.serialize(result);
    }
    
    public List<FieldInfo> serialFieldList {
        get {
            if (serialFieldList == null) {
                FieldInfo fiInt = new FieldInfo('','','integer');
                fiInt.editable = false;
                serialFieldList = new List<FieldInfo>{ fiInt };
                serialFieldList.addAll(FieldInfo.fetchJsonFieldInfos('Serial__c','Serial',SkidService3.serialAttributes.size() > 0 ? String.join(SkidService3.serialAttributes,',') : null,false));

                for (FieldInfo fi:serialFieldList) {
                   
                    String field = fi.field.replace(KSE.NamespaceUU,'');
                    if (field.toLowerCase() == 'name') {
                        fi.field = 'SerialNameId';
                        fi.fieldType = TYPE_REFERENCE;
                        fi.referenceTo = 'Serial__c';
                    } else if (field.toLowerCase() == 'fixed_asset__c') {
                        fi.editable = false;
                    }
                }
            }
            return serialFieldList;
        } set;
    }
    
    public String serialFieldListJson {
        get {
            if (serialFieldListJson == null) {
                serialFieldListJson = JSON.serialize(serialFieldList);
            }
            return serialFieldListJson;
        } set;
    }

    public String serialAttributesJson {
        get {
            if (serialAttributesJson == null) {
                serialAttributesJson = JSON.serialize(SkidService3.serialAttributes); 
            }
            return serialAttributesJson;
        } set;
    }
    
    public Integer gridSize {
        get {
            return serialFieldList.size() * 150;
        } set;
    }
    
   
    
    public String skidHeaderFieldListJson {
        get {
            if (skidHeaderFieldListJson == null) {
                List<String> skidFields = new List<String>{ 'Item__c','Location__c' };
                
                Boolean locFound = false;
                
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c',skidFields);
                for (FieldInfo fi:fiList) {
                    	fi.field = fi.field.toLowerCase();
                        if (fi.field == 'location__c') {
                            fi.title = 'From Location';
                            locFound = true;
                        }
                        fi.field = 'fromSKID.' + fi.field;
                    
                }
                
                skidHeaderFieldListJson = JSON.serialize(fiList);
            }
            return skidHeaderFieldListJson;
        } set;
    }
    
    public String skidFieldListJson {
        get {
            if (skidFieldListJson == null) {
                List<String> skidFields = new List<String>();
                list<String> additionalFields = new list<String> {'Packaging_UOM__c','License_Plate_Number__c','Stocking_UOM__c'};    
                skidFields.addAll(additionalFields);
                skidFields.addAll(SkidService3.attributesForDisplay(new Set<String>{ 'location__c'},new List<String>{ 'Quantity_Available__c','Count_Quantity__c' },false));
                
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c',skidFields);
                for (FieldInfo fi:fiList) {
                    fi.editable = true;
                    if (fi.field == 'Count_Quantity__c') {
                            fi.title = 'Change Quantity';
                             fi.editable = true;
                        } 
                     
                    if (fi.field == 'Quantity_Available__c') {
                             fi.editable = false;
                        }     
                     
                    fi.field = 'skid.' + fi.field; 
                    
                }
                
                skidFieldListJson = JSON.serialize(fiList);
            }
            return skidFieldListJson;
        } set;   
    }

   
    
    
    @RemoteAction
    public static JSONResult refreshLPNAttr(Item__c item,String facilityId, String PkgUOMId, String StockingUOMId){
       
        JsonResult result = new JsonResult();
        
        Id pkgUOM = (Id)PkgUOMId;
    	Id stockUOM = (Id)StockingUOMId;
    	
    	SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
        facilityQuery.addField('Id');
        facilityQuery.addField('Facility_Identifier__c');
        facilityQuery.setWhereClause('Id = :facilityId');
        Facility__c facility = Database.Query(facilityQuery.getQuery());
    	
    	SOQLUtil soql = new SOQLUtil('UOM__c');
        soql.addFields(new set<String>{'Package_Class__c','Package_Class__r.Default_Container_Item__c','Package_Class__r.Level__c', 'Package_Class__r.Default_Container_Item__r.Packaging_UOM__c',
        'Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c'});
        soql.setWhereClause('Id =:pkgUOM');
        
        UOM__c pkgUOMRec = Database.Query(soql.getQuery());
        map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
       	itemsWithPackagingUOM.put(item , new Set<UOM__c>{pkgUOMRec});
        map<Id, map<Id, Item__c>> containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
           
        Item__c containerItem = containersByItem.get(item.Id).get(pkgUOM);
        List<String> addlFields = SkidService3.trackedAttributes(null, null, item, containerItem);
        List<object> records = (List<object>) addlFields;
        result.records = records;//JSON.serialize
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize( item.Packaging_UOM__c, List<Id>.class );
        Decimal conversionFactor = KSE.getConversionFactor(item.Id,facility.Facility_Identifier__c,pkgUOM,stockUOM, lstPkgUom);
        //Decimal conversionFactor = KSE.getConversionFactor(item.Id,pkgUOM,stockUOM, lstPkgUom);
        result.additionalInfo = String.valueOf(conversionFactor);
         
        return result; 
    }
    
    
    @RemoteAction
    public static JsonResult getItemDetails(Id itemId,  Id locId) {  
        JsonResult result = new JsonResult();
        try {
            
            Id locationId = (Id)locId;
            Set<String> locationfieldStrings = new Set<String>{'Id','Bin_Tracked__c'};
            String whereClause = 'Id =:locationId ';
            SOQLUtil locationQuery = new SOQLUtil('Location__c');
            locationQuery.addFields(locationfieldStrings);
            locationQuery.setWhereClause(whereClause);
            List<Location__c> locationList = Database.query(locationQuery.getQuery());
            
            
            Id itId = (Id)itemId;
            Set<String> fieldStrings = new Set<String>{'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Company__c', 'Container__c',
                                        'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c', 'Stocking_UOM__c','Stocking_UOM__r.Package_Class__c', 'Stocking_UOM__r.Package_Class__r.Default_Container_Item__c',
    	                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Packaging_UOM__c',
    	                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
    	                                    'Container_Item__c','Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container_Package_Class__c'};
            fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));
             
            whereClause = 'Id =:itId ';
            SOQLUtil itemQuery = new SOQLUtil('Item__c');
            itemQuery.addFields(fieldStrings);
            itemQuery.setWhereClause(whereClause);
            // itemQuery.addAllCustomFields();
            Item__c item;
            List<String> packagingUOMs = new List<String>();
            
            List<Item__c> itemList = Database.query(itemQuery.getQuery());
            
            if(itemList.size() > 0 ){
            item = itemList[0];
            if(!String.isBlank(item.Packaging_UOM__c))
            	packagingUOMs.add(item.Packaging_UOM__c);
            }

            Item__c containerItem = SkidService3.getContainerforItem( item, null );
 

            List<FieldInfo> fiList = new List<FieldInfo>();

            List<String> skidFields = new List<String>{ 'Location__c' };
            if(locationList.size() > 0 && locationList[0].Bin_Tracked__c){
                skidFields.add('Bin__c');
            }
            skidFields.addAll(SkidService3.trackedAttributes(null, null, item, containerItem));

            fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c',skidFields));
            fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c','Inventory_Change_RO_New',null));
            fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c',new List<String>{ 'Stocking_UOM__c','Quantity_Available__c','Count_Quantity__c' }));
            
            
            for (FieldInfo fi:fiList) {
                if (fi.field != 'temporaryValueHolder') {
                    if (fi.field == 'lot_number__c') {
                       fi.field = 'Lot__c'; 
                    }
                    
                    if (fi.field == 'Count_Quantity__c') {
                        fi.title = 'Change Quantity';
                    } else if (fi.field == 'Quantity_Available__c') {
                        fi.editable = false;
                    }
                     if(fi.field == 'License_Plate_Number__c'){
                        fi.validateLookupOnBlur = true;
                    }
                    fi.field = 'skid.' + fi.field; 
                }
            }
            if(fiList.size() > 0){
                fiList[fiList.size()-1].editable = true;
            }
            result.records = itemList;
            result.additionalInfo = JSON.serialize(fiList);
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
   
    @RemoteAction
    public static JsonResult getLocationSKIDS( String  itemId, String locationId){
        JsonResult result = new JsonResult();
        
        if(locationId == null || itemId == null || locationId =='' || itemId == '' )
            return new JsonResult(new List<sObject>(), 0);
        
        try {
            result.records = InventoryChangeService.getSkids(new Map<String,Set<Id>>{ 'Item__c' => new Set<Id>{ itemId }, 'Location__c' => new Set<Id>{ locationId } },null,' AND Consigned_Owner__c = null ',false);
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    @RemoteAction

    public static JSONResult getPackagingUOM(Id pkgUOMId){
		JsonResult result = new JsonResult();
		
        SOQLUtil soql = new SOQLUtil('UOM__c');
        soql.addFields(new Set<String>{'Id','Name'});
        soql.setWhereClause('Id =:pkgUOMId');
        
        List<UOM__c> uomObjs = database.query(soql.getQuery());
        
        result.records = uomObjs;
        return result;
           
    } 
    
    
    @RemoteAction
    public static JsonResult addRow(Id fromLocationId) {
        SOQLUtil locationQuery = new SOQLUtil ('Location__c', true);
        locationQuery.addFields ( new Set<String> {'Id','Name'});
        locationQuery.setWhereClause ( 'Id = :fromLocationId' );
        List<Location__c> lstLocations = Database.query ( locationQuery.getQuery() );
        Map<Id,Location__c> locations = new Map<Id,Location__c>( lstLocations );
    
        MassInventoryService.InventoryData row = new MassInventoryService.InventoryData();
        if (fromLocationId != null && locations.containsKey(fromLocationId)) {
            row.fromSKID.Location__c = fromLocationId;
            row.fromSKID.Location__r = locations.get(fromLocationId);
        }
        
        return new JsonResult(new List<MassInventoryService.InventoryData>{ row },1);
    }
}