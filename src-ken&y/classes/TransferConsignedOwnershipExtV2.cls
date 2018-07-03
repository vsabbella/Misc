public with sharing class TransferConsignedOwnershipExtV2 extends BaseController {
    
    ApexPages.StandardController con;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    public static Inventory_Change__c transferOfOwner { get; set; }
    public static User_Preference__c up { get; set; }
    public GridRelatedListController.GridRelatedListConfig skidsConfig {get; set;}     
    public string serialFieldList { get; set; }
    public Integer gridSize {get;set;}
    public static Boolean serialTracked {get;set;}
    final String TYPE_REFERENCE = 'reference' ;
    final String TYPE_STRING = 'STRING' ;
    public static integer ndays;
    public String previousPage { get; set; }
    public static String saveButtonLabel { get; set;}
    public static string serialAttributes { get;set;}

    public String allocatedSerialFields { get; set; }

    public TransferConsignedOwnershipExtV2(ApexPages.StandardController controller) {
        con = controller;
        transferOfOwner = new Inventory_Change__c();
        up = UserPreference.getInstance().Preference;
        
        previousPage = ApexPages.currentPage().getHeaders().get('Referer');
        if( up == null || (up.Allow_access_to_all_facilities__c == false && up.default_facility__c == null) ){
            
            ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.ERROR, Label.Default_facility_not_setup));
            return;
        }
        transferOfOwner.Company__c = up.default_Company__c;
		transferOfOwner.Type__c = Label.Consigned;
        
        //PTM-205 Defaulting Facility from User Preference
        if(up.Default_Facility__c != null){
            transferOfOwner.Facility__c = up.Default_Facility__c;
        }  
        
        if(transferOfOwner.Facility__c != null){
            Id facilityId = transferOfOwner.Facility__c;
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name','Company__c','Company__r.Name','Company__r.Serial_Control__c'
			});
			soql.setWhereClause('Id = :facilityId');
			
			List<Facility__c> facList = Database.query(soql.getQuery());

            if(facList.size() > 0){
                transferOfOwner.Facility__r = facList[0];
                transferOfOwner.Company__r = facList[0].Company__r;
            }
        }
        else{
            Id companyId = transferOfOwner.Company__c;
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name', 'Serial_Control__c'
			});
			soql.setWhereClause('Id = :companyId');

			List<Company__c> cmpList = Database.query(soql.getQuery());

            if(cmpList.size() > 0)
                transferOfOwner.Company__r = cmpList[0];
        }
        
        skidsConfig = new GridRelatedListController.GridRelatedListConfig();
        skidsConfig.uniqueId = 'skidsGrid';
        skidsConfig.title = 'Location Information';
        skidsConfig.parentRecord = transferOfOwner;
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
    }
    
    public string getTransferOfOwnerJson() {
        return JSON.serialize(transferOfOwner);  
    }
    
    public string getTransferConsignedOwnershipHeaderFieldList() {
        String TransferConsignedOwnershipHeaderFieldList = '';
        FieldInfo fieldInfoItem;
        Boolean facilityEditable = true;
         up = UserPreference.getInstance().Preference;
        
        if( up == null || (up.Allow_access_to_all_facilities__c == false)){
            facilityEditable = false;
        }
        List<FieldInfo> fieldInfoSkidList = FieldInfo.fetchJsonFieldInfos('Skid__c', 'Transfer_Consigned_Inventory_Header');
        fieldInfoSkidList.remove(0);
        // get the requisition header field info list
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Inventory_Change__c', 'TransferConsignedOwnershipHeader');
        fieldInfoList.remove(0); // Remove Id field from the list
        fieldInfoList.addAll(fieldInfoSkidList);
        FieldInfo field = new FieldInfo('','Days Older Than',TYPE_STRING);
        field.editable = true;
        field.required = false;
        fieldInfoList.add(field);
        
        for(FieldInfo fi : fieldInfoList){
            if(fi.field.contains('Facility__c')){
                fi.editable = facilityEditable;
            }
            if(!(fi.title.contains('Days Older Than'))){
            	fi.required = fi.editable;
            }
        }
        
        TransferConsignedOwnershipHeaderFieldList = JSON.serialize(fieldInfoList);
        
        return TransferConsignedOwnershipHeaderFieldList;
    }
    
    public string getSkidsConfigJson() {
        String configStr = JSON.serialize(this.skidsConfig);
          
        return configStr;
    }
    
    public String skidsFieldList {
        get {
            if (skidsFieldList == null) {
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c','Transfer_Consigned_Inventory',null);
                fiList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c',SkidService3.attributesForDisplay(null,new List<String>{ 'Consigned_Owner__c','Purchase_Order_Line__c','Quantity_Available__c','Input_Quantity__c' },false)));
                for (FieldInfo fi:fiList) {
                    if (fi.field == 'Input_Quantity__c') {
                        fi.title = 'Transfer Quantity';
                    } else {
                        fi.editable = false;
                    }
                    fi.field = 'skid.' + fi.field;
                }
                skidsFieldList = JSON.serialize(fiList);
            }
            return skidsFieldList;
        } set;
    }
    
        
    
   @RemoteAction
    public static JsonResult getItemRecord(String itemId) {
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
        //List<String> packagingUOMs = new List<String>();
        
        List<Item__c> items = database.query(soql.getQuery());
     
        if(items.size() > 0 ){
            it = items[0];
        }
        
        result.records = items;
        
        List<String> addlFields = SkidService3.trackedAttributes(null, null, it );
        addlFields.add('Location__c');
        addlFields.add('Bin__c');
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('SKID__c','Transfer_Consigned_Inventory',null);
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c', addlFields));
        fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos('SKID__c',new List<String>{'Consigned_Owner__c','Purchase_Order_Line__c','Quantity_Available__c','Input_Quantity__c' }));  
        
        for (FieldInfo fi:fieldInfoList) {
            if (fi.field == 'Input_Quantity__c') {
                fi.title = 'Transfer Quantity';
            } else {
                fi.editable = false;
            }
            fi.field = 'skid.' + fi.field;
        }
        
        String skidsFieldList = JSON.serialize(fieldInfoList);
        result.additionalInfo = skidsFieldList;
        return result;
           
    }
    
        
    @RemoteAction
    public static JsonResult saveAction(Inventory_Change__c invChange, List<SkidService3.SerialWrapper> updatedList, List<String> dateFields) {
        
        JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        
        try{
            if (updatedList.size() > 0) {
            	
                for (SkidService3.SerialWrapper sw : updatedList) {
                    KendoUtils.UpdateDateFields(sw.skid, dateFields);
                }
            }
            
            if(invChange.Id == null){
                DML.insertAsUser(invChange);
            }
            
           	InventoryChangeWrapper icw = new InventoryChangeWrapper(invChange, updatedList);
            InventoryChangeService.inventoryOwnerTransfer( new list<InventoryChangeWrapper>{icw});
            
            result.success = true;
            result.additionalInfo = invChange.id;
            
        }
        catch(Exception e){
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e.getMessage(), ApexPages.Severity.ERROR);
        }
        
        return result;
        
    }

    @RemoteAction
    public static JsonResult getSkids(Id itemId,Id facilityId,Id locationId,Id supplierId,Integer numberOfDays) {
        JsonResult result = new JsonResult();
        try {
            Map<String,Set<Id>> filters = new Map<String,Set<Id>>{ 'Item__c' => new Set<Id>{ itemId }, 'Facility2__c' => new Set<Id>{ facilityId } };
            String addlWhere = ' AND Purchase_Order_Line__c != null ';

            if (!String.isEmpty(locationId)) {
                filters.put('Location__c',new Set<Id>{ locationId });
            }

            if (!String.isEmpty(supplierId)) {
                filters.put('Consigned_Owner__c',new Set<Id>{ supplierId });
            } else {
                addlWhere += ' AND Consigned_Owner__c != null ';
            }

            result.records = InventoryChangeService.getSkids(filters,'Transfer_Consigned_Inventory',addlWhere,false);
        } catch (Exception e) {
            result.success = false;
            result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
        }
        return result;
    }
}