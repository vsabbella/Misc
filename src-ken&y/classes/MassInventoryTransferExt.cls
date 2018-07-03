public with sharing class MassInventoryTransferExt extends GridRelatedListController{
    
    public static String NamespaceUU { get { return KSE.NamespaceUU; } }
    public Boolean serialTracked { get; set; } { serialTracked = false; }
    public Boolean allowAllFacilities { get; set; } { allowAllFacilities = false; }
    public String defaultCompany { get; set; } { defaultCompany = ''; }
    public String defaultFacility { get; set; } { defaultFacility = ''; }
    public String retURL { get; set; }
    final String TYPE_REFERENCE = 'reference';
    
    public MassInventoryTransferExt(ApexPages.StandardSetController con) {    
        UserPreference up = UserPreference.getInstance();
        defaultCompany = up.preference.Default_Company__c;
        defaultFacility = up.preference.Default_Facility__c;
        allowAllFacilities = up.preference.Allow_Access_to_all_Facilities__c;
        retURL = ApexPages.CurrentPage().getParameters().get('retURL');
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
        Inventory_Change__c ic = new Inventory_Change__c(Company__c = companyId,Type__c = 'Transfer',Reason_Code__c = reasonCodeId,Facility__c = facilityId);
        DML.insertAsUser(ic);
        SOQLUtil icQuery = new SOQLUtil ( 'Inventory_Change__c', true);
        icQuery.addFields ( new Set<String> {'Name','Company__r.Serial_Control__c'});
        icQuery.addAllCustomFields();
        icQuery.setWhereClause ( 'Id = \'' + ic.Id +'\'');
        List<Inventory_Change__c> lstInvChange = Database.query ( icQuery.getQuery () );
        ic.Name = lstInvChange[0].Name;
        ic.Finalized__c = true;
        ic.Finalized_Date__c = System.now();
        //creating toskids for wrapper
        List<SkidService3.SerialWrapper> swList = new List<SkidService3.SerialWrapper>();
        for (SkidService3.SerialWrapper row:rows) {
            
            SKID__c toSkid = new SKID__c(Company__c = row.skid.Company__c, Item__c = row.skid.Item__c, Item__r = row.skid.Item__r,
                        Facility2__c = row.skid.Facility2__c, Facility2__r=row.skid.Facility2__r);
            toSkid.bin__c = null;
            toSkid.bin__r = null;
            toSkid.Location__c = null;
            toSkid.Location__r = null;
            toSkid.Quantity__c = row.skid.Input_Quantity__c;
            List<String> locAndBinId = row.skid.Temporary_Value_Holder1__c.split(',');
            toSkid.Location__c = locAndBinId[0];
            if (locAndBinId.size() > 1  ) 
            {
                toSkid.Bin__c = locAndBinId[1];
                
            }
            toSkid.Stocking_UOM__c = null;
            toSkid.Stocking_UOM__r = null;
             swList.add(new SkidService3.SerialWrapper(row.skid,null,row.serialList,toSkid));
             
        } 
        
        
        
        try {
            for (SkidService3.SerialWrapper row:rows) {
                KendoUtils.UpdateDateFields(row.skid,dateFields);
            }
          
            InventoryChangeWrapper icw = new InventoryChangeWrapper(lstInvChange[0],swList);
            InventoryChangeService.inventoryTransfer( new list<InventoryChangeWrapper>{icw}, null);
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
                    String field = fi.field.replace(KSE.NamespaceUU,'').toLowerCase();
                    if (field == 'name' || field == 'fixed_asset__c') {
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
                List<String> skidFields = new List<String>{ 'Item__c','Location__c','Location__c','Bin__c' };
                
                Boolean locFound = false;
                
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c',skidFields);
                for (FieldInfo fi:fiList) {
                    if (fi.field.toLowerCase() == 'location__c' && locFound  ) {
                        fi.field = 'toSKID.location__c';
                        fi.title = 'To Location';
                    }  else if (fi.field.toLowerCase() == 'bin__c'  ) {
                        fi.field = 'toSKID.bin__c';
                        fi.title = 'To Bin';
                    } else {
                    	fi.field = fi.field.toLowerCase();
                        if (fi.field == 'location__c') {
                            fi.title = 'From Location';
                            locFound = true;
                        }
                        fi.field = 'fromSKID.' + fi.field;
                    }
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
                list<String> additionalFields = new list<String> {'Packaging_UOM__c','License_Plate_Number__c'};
                skidFields.addAll(additionalFields);
                skidFields.addAll(SkidService3.attributesForDisplay(new Set<String>{ 'location__c'},new List<String>{ 'Quantity_Available__c','Input_Quantity__c' },false));
                
                List<FieldInfo> fiList = FieldInfo.fetchJsonFieldInfos('SKID__c',skidFields);
                for (FieldInfo fi:fiList) {
                    fi.editable = false;
                    if (fi.field == 'input_quantity__c') {
                            fi.title = 'Transfer Quantity';
                             fi.editable = true;
                        } 
                     
                    fi.field = 'skid.' + fi.field; 
                    
                }
                
                skidFieldListJson = JSON.serialize(fiList);
            }
            return skidFieldListJson;
        } set;   
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
        public static JsonResult getLocationSKIDS( String  itemId, String locationId){
            JsonResult result = new JsonResult();
             
            if( String.isBlank ( locationId ) || String.isBlank( itemId) ) {
              
                return new JsonResult(new List<sObject>(), 0);
            }
           
            try {
                result.records = InventoryChangeService.getSkids(new Map<String,Set<Id>>{ 'Item__c' => new Set<Id>{ itemId }, 'Location__c' => new Set<Id>{ locationId } },null,' AND Consigned_Owner__c = null ',false);
            } catch (Exception e) {
                result.success = false;
                result.addMessage(e.getMessage(),ApexPages.Severity.ERROR);
            }
            return result;
            }
        
    @RemoteAction
    public static JsonResult addRow(Id fromLocationId,Id toLocationId) {
        SOQLUtil locationQuery = new SOQLUtil ('Location__c', true);
        locationQuery.addFields ( new Set<String> {'Id','Name'});
        locationQuery.setWhereClause ( 'Id in (:fromLocationId,:toLocationId)' );
        List<Location__c> lstLocations = Database.query ( locationQuery.getQuery() );
        Map<Id,Location__c> locations = new Map<Id,Location__c>( lstLocations );
    
        MassInventoryService.InventoryData row = new MassInventoryService.InventoryData();
        if (fromLocationId != null && locations.containsKey(fromLocationId)) {
            row.fromSKID.Location__c = fromLocationId;
            row.fromSKID.Location__r = locations.get(fromLocationId);
        }
        if (toLocationId != null && locations.containsKey(toLocationId)) {
            row.toSKID.Location__c = toLocationId;
            row.toSKID.Location__r = locations.get(toLocationId);
        }
        return new JsonResult(new List<MassInventoryService.InventoryData>{ row },1);
    }
}