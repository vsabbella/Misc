public with sharing class CycleCountExtV2 extends BaseController {
    
    ApexPages.StandardController con;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    public Inventory_Change__c inventoryChange { get; set; }

    public GridRelatedListController.GridRelatedListConfig skidsConfig {get; set;}     
    public string serialFieldList { get; set; }
    public Integer gridSize {get;set;}
    public static Boolean serialTracked {get;set;}
    final String TYPE_REFERENCE = 'reference' ;
    public String skidsFieldList = null;
    public static string serialAttributes { get;set;}

    public String allocatedSerialFields { get; set; }

    public CycleCountExtV2(ApexPages.StandardController controller) {
        con = controller;
        
        inventoryChange = new Inventory_Change__c();
        
        inventoryChange.Type__c  = 'Cycle Count';
        
        User_Preference__c up = UserPreference.getInstance().Preference;
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
        
        skidsConfig = new GridRelatedListController.GridRelatedListConfig();
        skidsConfig.uniqueId = 'skidsGrid';
        skidsConfig.title = 'Location Information';
        skidsConfig.parentRecord = inventoryChange;
        skidsConfig.objectName = 'SKID__c';  
        skidsConfig.parentField = 'Inventory_Change__c';
        skidsConfig.buttons = 'create, search, excel';
        
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
        
        if( up == null || (up.Allow_access_to_all_facilities__c == false && up.default_facility__c == null) ){
            
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, Label.Default_facility_not_setup));
            return;
        }
        
        //PTM-205 Defaulting Facility from User Preference
        if(up.Default_Facility__c != null){
            inventoryChange.Facility__c = up.Default_Facility__c;
        } 
        
        if(inventoryChange.Facility__c != null){
            Id facilityId = inventoryChange.Facility__c;
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql1 = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			soql1.addFields(new set<string>{
				'id','Name','Company__c','Company__r.Name','Company__r.Serial_Control__c', 'Facility_Identifier__c'
			});
			soql1.setWhereClause('Id=:facilityId');
			List<Facility__c> facList = Database.query(soql1.getQuery());

            if(facList.size() > 0){
                inventoryChange.Facility__r = facList[0];
                inventoryChange.Company__r = facList[0].Company__r;
            }
        }
        
        
    }
    
    public string getInventoryChangeJson() {
        return JSON.serialize(inventoryChange);  
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
                fi.editable = facilityEditable;
                fi.required = fi.editable;
            }
            
            
            if(fi.field.toLowerCase() == 'company__c'  || fi.field.toLowerCase() == 'item__c' || fi.field.toLowerCase() == 'reason_code__c')
            	fi.required = true;
        }
        
        InventoryChangeHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return InventoryChangeHeaderFieldList;
    }
    
    public string getSkidsConfigJson() {
        String configStr = JSON.serialize(this.skidsConfig);
          
        return configStr;
    }
    @RemoteAction
    public static list<String> refreshTrackedAttr( Location__c location , Item__c item){
        
        return SkidService3.refreshTrackedAttr(null, location, item); 
    }
    
    @RemoteAction
    public static JSONResult refreshLPNAttr(Item__c item, String facilityId, String PkgUOMId, String StockingUOMId){
       
        JsonResult result = new JsonResult();

        SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
        facilityQuery.addField('Id');
        facilityQuery.addField('Facility_Identifier__c');
        facilityQuery.setWhereClause('Id = :facilityId');
        Facility__c facility = Database.Query(facilityQuery.getQuery());

        Id pkgUOM = (Id)PkgUOMId;
    	Id stockUOM = (Id)StockingUOMId;
    	SOQLUtil soql = new SOQLUtil('UOM__c');
        soql.addFields(new set<String>{'Package_Class__c','Package_Class__r.Default_Container_Item__c','Package_Class__r.Level__c','Package_Class__r.Default_Container_Item__r.Packaging_UOM__c', 
        'Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c'});
        soql.setWhereClause('Id =:pkgUOM');
        
        UOM__c pkgUOMRec = Database.Query(soql.getQuery());
        map<Item__c, Set<UOM__c>> itemsWithPackagingUOM = new map<Item__c, Set<UOM__c>>();
       	itemsWithPackagingUOM.put(item , new Set<UOM__c>{pkgUOMRec});
        map<Id, map<Id, Item__c>> containersByItem = SkidService3.getContainerforItems(itemsWithPackagingUOM);
           
        Item__c containerItem = containersByItem.get(item.Id).get(pkgUOM);
        List<String> addlFields = SkidService3.trackedAttributes(null, null, item, containerItem);
        System.debug(Logginglevel.Info,'addlFields'+addlFields);
        List<object> records = (List<object>) addlFields;
        result.records = records;//JSON.serialize
        List<Id> lstPkgUom = (List<Id>) JSON.deserialize( item.Packaging_UOM__c, List<Id>.class );
        Decimal conversionFactor = KSE.getConversionFactor(item.Id,facility.Facility_Identifier__c, pkgUOM,stockUOM, lstPkgUom );
        result.additionalInfo = String.valueOf(conversionFactor);
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
    public static JsonResult getItemDetails(String itemId) {
        JsonResult result = new JsonResult();
        Id itId = (Id)itemId;
        Set<String> fieldStrings = new Set<String>{'Id','Name','Item_Attribute__c','Non_Inventory__c','Source__c','Company__c','Container__c',
                                    'Class__r.Minimum_Shelf_Life_In_Days__c','ABC_Code__c', 'Stocking_UOM__c','Stocking_UOM__r.Package_Class__c', 'Stocking_UOM__r.Package_Class__r.Default_Container_Item__c',
	                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__c','Packaging_UOM__c',
	                                    'Stocking_UOM__r.Package_Class__r.Default_Container_Item__r.Item_Attribute__r.License_Plate_Number__c',
	                                    'Container_Item__c','Container_Item__r.Item_Attribute__r.License_Plate_Number__c','Container_Item__r.Container_Package_Class__c', 'Container_Item__r.Packaging_UOM__c'};
        fieldStrings.addAll(util.getAllCustomFieldsFromObject('Item_Attribute__r.','Item_Attribute__c'));
         
        String whereClause = 'Id =:itId ';
        SOQLUtil soql = new SOQLUtil('Item__c');
        soql.addFields(fieldStrings);
        soql.setWhereClause(whereClause);	

        Item__c it;
        List<String> packagingUOMs = new List<String>();
        
        List<Item__c> items = database.query(soql.getQuery());
     
        if(items.size() > 0 ){
            it = items[0];
            if(!String.isBlank(it.Packaging_UOM__c))
            	packagingUOMs.add(it.Packaging_UOM__c);
        }
        
        result.records = items;
        
        Item__c containerItem = SkidService3.getContainerforItem( it, null );
        
        String[] addlFields = SkidService3.trackedAttributes(null, null, it, containerItem);
        addlFields.add('Bin__c');
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c','Cycle_Count_RO',null);
        addlFields.add('Count_Quantity__c');
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', addlFields));
    
        for(FieldInfo fi : fieldInfoList ){
            
            if(fi.field == 'License_Plate_Number__c'){
                fi.validateLookupOnBlur = true;
            }
            
            fi.field = 'skid.'+fi.field;
        }
        if(fieldInfoList.size() > 0){
            fieldInfoList[fieldInfoList.size()-1].editable = true;
        }
        String skidsFieldList = JSON.serialize(fieldInfoList);
        result.additionalInfo = skidsFieldList;
        return result;
           
    }

    @RemoteAction
    public static JsonResult getSkids(Id itemId,Id facilityId) {
        JsonResult result = new JsonResult();
        try {
            result.records = InventoryChangeService.getSkids(new Map<String,Set<Id>>{ 'Item__c' => new Set<Id>{ itemId }, 'Facility2__c' => new Set<Id>{ facilityId } },'Cycle_Count_RO',' AND Consigned_Owner__c = null AND Customer__c = null AND Sales_Order_Line__c = null ', false);
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
    
    @RemoteAction
    public static JsonResult saveAction(Inventory_Change__c invChange, List<String> headerDateFields, List<SkidService3.SerialWrapper> updatedList, List<String> dateFields) {
        
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        
        try{
            KendoUtils.UpdateDateFields(invChange, headerDateFields);
    
            if (updatedList.size() > 0) {
                for (SkidService3.SerialWrapper sw : updatedList) {
                    KendoUtils.UpdateDateFields(sw.skid, dateFields);
                }
            }
            
            if(invChange.Id == null){
                DML.insertAsUser(invChange);
            }
            
            InventoryChangeWrapper icw = new InventoryChangeWrapper(invChange, updatedList);
            InventoryChangeService.inventoryAdjustment( new list<InventoryChangeWrapper>{icw}, 'Cycle Count');
            result.success = true;
            result.additionalInfo = invChange.id;
        } catch (Exception e) {
            Database.rollback(sp);
            CustomException.addError(result, e);
        }
        return result;
    }
}