global with sharing class ItemService {
    private static SchemaUtil util = SchemaUtil.getInstance();
    private static String namespace = KSE.NamespaceUU;
    private static Map<Id, List<Id>> packagingUoms = new Map<Id, List<Id>>();

    public class ItemServiceException extends Exception { }
    
    public static final String ITEM_SOURCE_OSP = 'Outside Processing';
    public static final String ITEM_SOURCE_PHANTOM = 'Phantom';
    public static final String ITEM_SOURCE_MAKE_TO_ORDER = 'Build To Order';
    public static final String ITEM_SOURCE_BUILD_TO_ORDER = ITEM_SOURCE_MAKE_TO_ORDER;
    public static final String ITEM_SOURCE_KIT = 'Kit';
    public static final String ITEM_SOURCE_MANUFACTURED = 'Manufactured';
    public static final String ITEM_SOURCE_PURCHASED = 'Purchased';
    
    public static List<Schema.FieldSetMember> costRollupFields {
        get {
            if (costRollupFields == null) costRollupFields = util.getFieldsFromFieldSet(Item_Cost__c.sObjectType, 'Cost_Rollup_Fields');
            return costRollupFields;
        } private set;
    }
    
    public static Set<String> costRollupFieldSet {
        get {
            if (costRollupFieldSet == null) {
                costRollupFieldSet = new Set<String>();
                for (Schema.FieldSetMember f:costRollupFields) costRollupFieldSet.add(f.fieldPath.replace(namespace, ''));
            }
            return costRollupFieldSet;
        } private set;
    }
    
    public static String costRollupFieldsForQuery {
        get {
            if (costRollupFieldsForQuery == null) {
                costRollupFieldsForQuery = '';
                for (String fieldPath:costRollupFieldSet) costRollupFieldsForQuery += fieldPath + ', ';
            }
            return costRollupFieldsForQuery;
        } private set;
    }
    
    /**
     *@description determine if the records in oldMap can be deleted
    */
    public static void allowItemDelete( Map<id,Item__c> oldMap ) { 
        Map<Id, Nettable.NETcount > tmp = Nettable.getNettable( oldMap.values() ); 
        for ( Item__c itm : oldMap.values()  ) {
            if ( tmp.containsKey( itm.id ) ) {
                itm.addError(Label.Cannot_delete_item_with_quantity_on_hand);
            }
        }
    }
    
    public static Boolean allowItemCostUpdate = false;
    public static void checkItemCostStatus(Map<Id,Item_Cost__c> oldMap,List<Item_Cost__c> newIcList) {
        if (Trigger.isUpdate) {
            for (Item_Cost__c itemCost:newIcList) {
                Item_Cost__c oldItemCost = (Item_Cost__c)oldMap.get(itemCost.id);
                if (!allowItemCostUpdate && oldItemCost.Status__c.equalsIgnoreCase(Label.Approved)) {
                    itemCost.addError(Label.Cannot_edit_item_cost_in_active_status);
                    continue;
                } else if (!allowItemCostUpdate && (KSE.isFieldChanging('On_hand_Revaluation__c',itemCost,oldMap) || KSE.isFieldChanging('Invalid_Flag__c',itemCost,oldMap) || KSE.isFieldChanging('Date_Approved__c',itemCost,oldMap))) {
                    itemCost.addError(Label.Cannot_edit_item_cost_fields);
                    continue;
                } else if (!(oldItemCost.Status__c.equalsIgnoreCase(Label.Proposed) || oldItemCost.Status__c.equalsIgnoreCase(Label.Approved)) && Label.Approved.equalsIgnoreCase(itemCost.Status__c)) {
                    itemCost.addError(Label.Can_only_update_Item_cost_records_from_proposed_to_Approved_status);
                    continue;
                }
                if (Label.Approved.equalsIgnoreCase(itemCost.Status__c))
                    itemCost.Item_Cost_Unique__c = itemCost.Item__c  + '-' + itemCost.Facility__c + '-' + itemCost.Status__c + '-' + itemCost.Start_Date__c + '-' + itemCost.Invalid_Flag__c + '-' + itemCost.Date_Approved__c;
                else
                    itemCost.Item_Cost_Unique__c = itemCost.Item__c  + '-' + itemCost.Facility__c + '-' + itemCost.Status__c;
            }
        }
        if (Trigger.isDelete) {
            for (Item_Cost__c itemCost:oldMap.values()) {
                Item_Cost__c oldItemCost = (Item_Cost__c)oldMap.get(itemCost.id);
                if (Label.Approved.equalsIgnoreCase(oldItemCost.Status__c))
                    itemCost.addError(Label.Cannot_delete_item_cost_in_active_status);  
            }
        }
        if (Trigger.isInsert) {
            for (Item_Cost__c itemCost:newIcList) {
                if (Label.Approved.equalsIgnoreCase(itemCost.Status__c)) {
                    itemCost.addError(Label.Cannot_insert_item_cost_in_active_status);  
                    continue;  
                }
                if (Label.Approved.equalsIgnoreCase(itemCost.Status__c))
                    itemCost.Item_Cost_Unique__c = itemCost.Item__c  + '-' + itemCost.Facility__c + '-' + itemCost.Status__c + '-' + itemCost.Start_Date__c + '-' + itemCost.Invalid_Flag__c + '-' + itemCost.Date_Approved__c;
                else
                    itemCost.Item_Cost_Unique__c = itemCost.Item__c  + '-' + itemCost.Facility__c + '-' + itemCost.Status__c;
            }   
        }       
    }
    
    /**
     * @description sorts the packaging uom based on the Package Class level
     * 
     */ 
    public static void sortPackagingUOMByLevels(List<Item__c> items) {
         
        if ( Trigger.isBefore && (Trigger.isUpdate || trigger.isInsert ) ) {
            Set<Id> uomIds = new Set<Id> ();
            Map<String, Set<Id>> mapPkgUOMs = new Map<String, Set<Id>>();
            
            List<Item__c> itemWithPackagingUOMs = new List<Item__c>();
            
            if(trigger.isInsert){
            	for ( Item__c item : items ) {
	            	if ( item.Packaging_UOM__c != null) {
	            	    itemWithPackagingUOMs.add(item);
	                }
	            }
            }
            
            if(trigger.isUpdate){
            	for ( Item__c item : items ) {
	            	if ( item.Packaging_UOM__c != null && KSE.isFieldChanging ('Packaging_UOM__c', item, Trigger.oldMap)) {
	            	    itemWithPackagingUOMs.add(item);
	                }
	            }
	        } 
            
            if(itemWithPackagingUOMs.size() > 0){
	            for ( Item__c item : itemWithPackagingUOMs ) {
	            	mapPkgUOMs.put( item.Packaging_UOM__c, (Set<Id>) JSON.deserialize(item.Packaging_UOM__c, Set<Id>.class) );
            	    uomIds.addAll ( mapPkgUOMs.get( item.Packaging_UOM__c));
                }
	            
	            Map<Id, UOM__c> uoms = new Map<Id, UOM__c>([SELECT id, Package_Class__r.Level__c FROM UOM__c WHERE id in :uomIds ORDER BY Package_Class__r.Level__c ASC ]);
	            
	            for ( Item__c item : itemWithPackagingUOMs ) {
	                if (mapPkgUOMs.containsKey(item.Packaging_UOM__c) ) {
	                    List<UOM__c> UOMList = new List<UOM__c>();
	                    for ( Id uomId :mapPkgUOMs.get(item.Packaging_UOM__c)){
	                        if (uoms.containsKey ( uomId) ) {
	                            UOMList.add ( uoms.get(uomId) );
	                        } else {
	                            // throw err
	                        }
	                    }
	                    
	                    KSE.sortList (UOMList, 'Package_Class__r.Level__c', null);
	                    item.put('Packaging_UOM__c', JSON.serialize( KSE.grepFieldFromList (UOMList, 'Id', true)));
	                }
	            }
            }
        }
    }
    
   public static map<Id,Id> getAssembyItemIds(set<Id> assemblySet){
        
        map<Id,Id> assemblyItemMap=new map<Id,Id>();
        if (assemblySet.isEmpty()) return assemblyItemMap; 


        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
        SOQLUtil soql = new SOQLUtil('Item_Specification__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
        	'id','Item__c', 'Item__r.Packaging_UOM__c'
        });
        soql.setWhereClause('id in:assemblySet AND Active__c = true');
        for(Item_Specification__c itemSpecObj:Database.query(soql.getQuery())){



            assemblyItemMap.put(itemSpecObj.id,itemSpecObj.Item__c);
        }
        
        return assemblyItemMap;
    }
  
    public static void VerifyItemType(List<Item__c> items) {

        Set<String> strippedValues = new Set<String>();
        for (String fieldPath:costRollupFieldSet) {
            strippedValues.add(stripField(fieldPath));
        }
        for( Item__c item : items ){
         if(item.Item_Type__c != null && ! strippedValues.Contains(item.Item_Type__c) )            
                  item.addError(Label.Item_Type_does_not_match_cost_component);             
       }
    }
    
    public static void allowChangeinUOM(Map<Id, Item__c> items, Map<Id, Item__c> oldItems) {
        List<Item__c> itemList = new List<Item__c>();
        for (Item__c item:items.values()) {
            Item__c oldItem = oldItems.get(item.Id);

            if (item.Packaging_UOM__c != oldItem.Packaging_UOM__c) {
                List<Id> oldUoms = (List<Id>)JSON.deserialize(oldItem.Packaging_UOM__c, List<Id>.Class);
                List<Id> newUoms = (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class);

                for (Integer i = 0; i < oldUoms.size(); i++) {
                    if (newUoms.size() <= i || oldUoms[i] != newUoms[i]) {
                        itemList.add(item);
                        break;
                    }
                }
            }
        }
        
        set<Id> itemsWithInventory = ItemService.itemsWithInventory(new list<Item__c>(itemlist));
        for(Item__c item: itemlist){
        	if(itemsWithInventory.contains(item.Id)){
        		item.addError(Label.Packaging_UOM_Cannot_be_changed);
        	}
        }
        
    }
    
    public static void allowChangeInItemAttributeOnItem(map<Id,Item__c> items, Map<id,Item__c> oldMap ){
        
        List<Item__c> itemsWithChanges = new List<Item__c>();
        List<Item__c> itemsWithNonInventoryFlagChanges = new List<Item__c>();
	    Set<Id> itemIds = new Set<Id>();
	    Set<Id> pkgIds = new Set<Id>();
	    Map<Id,Item__c> itemAttributemap = new Map<Id,Item__c>();
        for( Item__c item : items.values() ){
			
			
			if(KSE.isFieldChanging('Item_Attribute__c', item, oldMap )){

                itemsWithChanges.add(item);
			}
            if(KSE.isFieldChanging('Item_Attribute__c', item, oldMap ) || KSE.isFieldChanging('Container__c', item, oldMap) || KSE.isFieldChanging('Container_Package_Class__c', item, oldMap)){

                if(!itemAttributemap.containskey(item.Item_Attribute__c)){
                	itemAttributemap.put(item.Item_Attribute__c,item);
                }
                
                itemIds.add(item.Id);
                if(item.Container_Package_Class__c !=null)
                	pkgIds.add(item.Container_Package_Class__c);
                
            }
             
            if(KSE.isFieldChanging('Non_Inventory__c', item, oldMap )){

                itemsWithNonInventoryFlagChanges.add(item);

            }
            
        
        }
        if(trigger.isUpdate){
        	List<Item__c> itemsChangedMasterList = new List<Item__c>();
	        itemsChangedMasterList.addAll(itemsWithChanges);
	        itemsChangedMasterList.addAll(itemsWithNonInventoryFlagChanges);
	         if( itemsChangedMasterList.size() > 0 ){
	          
	              set<Id> MasterItemSetwithInventory = itemsWithInventory(itemsChangedMasterList);
	              
	             for( Id itemId : MasterItemSetwithInventory ){
	                for( Item__c NonInvItem : itemsWithNonInventoryFlagChanges){
	                    if (NonInvItem.ID == itemId)
	                        NonInvItem.addError(Label.Non_Inventory_cannot_be_checked);
	                }
	                
	                for( Item__c attrChangedItem: itemsWithChanges){
	                    if (attrChangedItem.ID == itemId)
	                        attrChangedItem.addError(Label.Item_Attributes_Cannot_be_changed);
	                }
	              }
	              
	         }
        }    
        map<Id,Package_Class__c> packagemap = new map<Id,Package_Class__c> ();
        if(pkgIds.size()>0)
        	packagemap = getParentPkgmap(pkgIds);
        if(itemAttributemap.values().size()>0){
        	Set<Id> attributeIds = new Set<Id>();
        	attributeIds.addAll(itemAttributemap.keyset());
        	if(attributeIds.size()>0)
        		checkItemAttributes(attributeIds,itemAttributemap,packagemap);
        }
        
        
    }
    
    public static map<Id,Package_Class__c> getParentPkgmap(Set<Id>pkgIds){
    	
    	//Query the Packaging Class
	  	SOQLUtil soql = new SOQLUtil('Package_Class__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Parent_Package_Class__c'
        });
        
        soql.setWhereClause('Id IN :pkgIds');
        
        Map<Id,Package_Class__c> pkgClassmap = new Map<Id, Package_Class__c>((List<Package_Class__c>)Database.query(soql.getQuery()));
        return pkgClassmap;
    }
    
    public static void checkItemAttributes(Set<Id> attributeIds,Map<Id,Item__c> itemAttributemap,map<Id,Package_Class__c> packagemap){
    	Set<String> ignoreAttributes= new Set<String>();
        ignoreAttributes.addAll(SkidService3.attributesToExclude);
        Set<String> containerAttributes = new Set<String>();
        containerAttributes.add('license_plate_number__c');
        String lpnerror = '';
    	String containererrmsg = '';
    	
    	SOQLUtil attributesQuery = new SOQLUtil('Item_Attribute__c', true);
	 	attributesQuery.addAllCustomFields();
		attributesQuery.setWhereClause('Id IN:attributeIds');
		
		map<Id,Item_Attribute__c> attributesmap = new map<Id,Item_Attribute__c>((List<Item_Attribute__c>)Database.query(attributesQuery.getQuery()));
		for( Item_Attribute__c attr : attributesmap.values()){
	            
	            Item_Attribute__c attrRec;
	            Item__c itemRec = itemAttributemap.get(attr.id);
	            for(String fieldName : Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c') ){
	                if(!ignoreAttributes.contains(fieldName.toLowerCase()) && containerAttributes.contains(fieldName.toLowerCase())){
	                	if(itemRec.Container__c == false){
		                	if(attributesmap.get(attr.Id).get(fieldName) == true){
		                    	lpnerror += itemRec.Name+',';
		                    }
		                    
			             }
			             else if(itemRec.Container__c == true && packagemap !=null){
			             	if(attributesmap.get(attr.id).get(fieldName) == true && packagemap.containskey(itemRec.Container_Package_Class__c) && packagemap.get(itemRec.Container_Package_Class__c).Parent_Package_Class__c !=null){
		                    	containererrmsg += itemRec.Name+',';
		                    }
		                    
			             }
	                }
	            }
	            
	            if(lpnerror !=''){
	            	trigger.newMap.get(itemRec.Id).addError(lpnerror.subString(0,lpnerror.length()-1)+':License Plate Number Attribute cannot be associated to non container item. ');
	            	lpnerror = '';
	            }
	            
	            if(containererrmsg !=''){
	            	trigger.newMap.get(itemRec.Id).addError(containererrmsg.subString(0,containererrmsg.length()-1)+':Container Item can only be tracked by license plate number at the highest level of package hierarchy. ');
	            	containererrmsg = '';
	            }
	            
	        }
    }
    
    
    public static void allowChangeInItemAttribute(map<Id,Item_Attribute__c> itemAttributes, Map<id,Item_Attribute__c> oldMap ){
        
        set<Item__c> itemSet = new set<Item__c>();
        set<Id> itemAttributeSet = oldMap.keySet();
        String error = '';
        String lpnerror = '';
        String containererror = '';
        
        if( trigger.isUpdate ){
        	itemAttributeSet = itemAttributes.keySet();
        }

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
                */
        //V2
        SOQLUtil soql = new SOQLUtil('Item_Attribute__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
        	'id'
        });
        soql.setWhereClause('Id IN:itemAttributeSet');
                SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Items__r');
        childRel.addFields(new set<string>{
        	'id','Name','Container_Package_Class__r.Parent_Package_Class__c','Container__c'
        });
        soql.addChildRelationship(childRel);
        list<Item_Attribute__c> iaList = Database.query(soql.getQuery());
        
        for( Item_Attribute__c ia : iaList){
            
            itemSet.addAll( ia.Items__r );   
        }
        
        set<Id> itemsWithInventory = itemsWithInventory(new list<Item__c>(itemSet));
        
        Set<String> ignoreAttributes= new Set<String>();
        ignoreAttributes.addAll(SkidService3.attributesToExclude);
        Set<String> containerAttributes = new Set<String>();
        containerAttributes.add('license_plate_number__c');
        String serialAttr = 'Serial_Number__c';
        for(String s:ignoreAttributes){
                
            if(s == serialAttr.toLowerCase()){
                ignoreAttributes.remove(s); //KNDY-13026 Removing Serial Number from exclude list.
            }
        } 
        
        for( Item_Attribute__c ia : iaList){
            
            Item_Attribute__c iaRecord;
            
            if(trigger.isUpdate){
	            for(String fieldName : Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c') ){
	                
	                if( (!ignoreAttributes.contains(fieldName.toLowerCase())) && KSE.isFieldChanging(fieldName, itemAttributes.get(ia.id), oldMap)){
	                    
	                    for( Item__c i : ia.Items__r ){
	                        
	                        if( itemsWithInventory.contains(i.id) ){
	                            
	                            error += i.Name+',';
	                                   
	                        }
	                        if(i.Container__c == true){
	                        	if(containerAttributes.contains(fieldName.toLowerCase()) && i.Container_Package_Class__r.Parent_Package_Class__c !=null && itemAttributes.get(ia.id).get(fieldName) == true){
		                        	lpnerror += i.Name+',';
		                        }
		                        if(!containerAttributes.contains(fieldName.toLowerCase()) && itemAttributes.get(ia.id).get(fieldName) == true){
		                        	containererror += i.Name+',';
		                        }
	                        }
	                        
	                    }
	                    break;
	                }
	            }
	            iaRecord = itemAttributes.get(ia.id);
            }
            
            if(trigger.isDelete){
            	
            	for( Item__c i : ia.Items__r ){
	                        
                    if( itemsWithInventory.contains(i.id) ){
                        
                        error += i.Name+',';
                               
                    }
                }
                iaRecord = oldMap.get(ia.id);
            }
            
            if( error != ''){
            	iaRecord.addError(error.subString(0,error.length()-1)+': '+Label.Item_Attributes_Cannot_be_changed);
            	error = '';
            }
            if(lpnerror !=''){
            	iaRecord.addError(lpnerror.subString(0,lpnerror.length()-1)+':License Plate Number Attribute cannot be changed as the item(s) related package level is not at the highest level. ');
            	lpnerror = '';
            }
            if(containererror !=''){
            	iaRecord.addError(containererror.subString(0,containererror.length()-1)+':Container Item can only be tracked by license plate number. ');
            	containererror = '';
            }
            
        }
        
    }
    
    public static set<Id> itemsWithInventory( List<Item__c> items ){
        
        set<Id> itemSet = new set<Id>();
        
		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		        */
		SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Item__c','Location__r.Nettable__c','Quantity__c','Type__c', 'Company__c'
		});
		soql.setWhereClause('Item__c in :items and Type__c in (\'Location\',\'Allocated\',\'In-Transit\') and Quantity__c <> 0');
		soql.setOrderByClause('Location__r.Facility__r.Name, Location__r.Name ASC');
        
        for( SKID__c sk : Database.query(soql.getQuery())){
            itemSet.add(sk.Item__c);
        }
        
        return itemSet;
    }

    private static String stripField(String fieldPath) {
        return fieldPath.replace(namespace, '').replace('Cost', '').replace('__c', '').replace('_', ' ').trim();
    }

    private static Set<Id> facilitySet;
    private static Set<Id> pItemsForQuery;
    
    public static Map<Id, Map<Id,List<Item_Cost__c>>> getActiveStandardCostMap(Set<Id> ItemIds,Set<Id> FacilityIds, String costType, DateTime activeStandardCostDate) {
        
        if(preLoadedCostRecords == null || pItemsForQuery != ItemIds  || facilitySet != FacilityIds) {
            preLoadedCostRecords = new Map<Id, Map<Id,List<Item_Cost__c>>>();
            pItemsForQuery = ItemIds;
            facilitySet = facilityIds;
            
            String whereClause = ' Status__c =:costType' +
                                 ' AND (Start_Date__c <= :activeStandardCostDate)' + 
                                 ' AND Item__c IN :ItemIds AND (Facility__c IN :FacilityIds OR Facility__c = Null) AND Invalid_Flag__c = false ORDER BY Item__c,Start_Date__c Desc';
            
            SOQLUtil soql = new SOQLUtil('Item_Cost__c');
            soql.addFields(new Set<String>{'Id', 'Item__c', 'Status__c', 'Date_Activated__c', 'Facility__c', 'Company__c', 'Standard_Cost__c', 'Item__r.Name', 'Start_Date__c'});
            soql.addFields(costRollupFieldSet);
            soql.setWhereClause(whereClause); 

            for(Item_Cost__c itemCost : Database.query(soql.getQuery()))//Change to dynamic query to pull all items in Fieldset Cost_Rollup_Fields on Item Cost
            {   
                if(!preLoadedCostRecords.containsKey(itemCost.Facility__c)){
                    preLoadedCostRecords.put(itemCost.Facility__c, new map<Id, List<Item_Cost__c>>());
                }
                
                if(!preLoadedCostRecords.get(itemCost.Facility__c).containsKey(itemCost.Item__c)){
                    preLoadedCostRecords.get(itemCost.Facility__c).put(itemCost.Item__c, new List<Item_Cost__c>());
                }
                
                preLoadedCostRecords.get(itemCost.Facility__c).get(itemCost.Item__c).add(itemCost);
            }

        }
        return preLoadedCostRecords;
        
    }

    
    public static Map<Id,Map<Id,Decimal>> getActiveStandardCostDecimalMap(Set<Id> ItemIds, Set<Id> FacilityIds, String costType, DateTime activeStandardCostDate) {
        
        Map<Id,Map<Id,Decimal>> pActiveStandardCostDecimalMap = new Map<Id,Map<Id,Decimal>>();
        if(itemCostDecMap == null || pItemsForQuery != ItemIds || facilitySet != FacilityIds) {
            
            pItemsForQuery = ItemIds;
            facilitySet = FacilityIds;

			String whereClause = ' Status__c =:costType' + 
                                 ' AND (Start_Date__c <= :activeStandardCostDate)' + 
                                 ' AND Item__c IN :ItemIds' +
                                 ' And (Facility__c IN :FacilityIds OR Facility__c = Null) AND Invalid_Flag__c = false ORDER BY Item__c,Start_Date__c Desc';

            SOQLUtil soql = new SOQLUtil('Item_Cost__c');
            soql.addFields(new Set<String>{'Id', 'Item__c', 'Status__c', 'Facility__c', 'Company__c', 'Standard_Cost__c', 'Item__r.Name'});
            soql.addFields(costRollupFieldSet);
            soql.setWhereClause(whereClause); 

            for(Item_Cost__c itemCost : Database.query(soql.getQuery()))
            {   
                if(!pActiveStandardCostDecimalMap.containsKey(itemCost.Facility__c)){
                    pActiveStandardCostDecimalMap.put(itemCost.Facility__c, new map<Id, Decimal>());
                }
                
                if(!pActiveStandardCostDecimalMap.get(itemCost.Facility__c).containsKey(itemCost.Item__c)){
                    pActiveStandardCostDecimalMap.get(itemCost.Facility__c).put(itemCost.Item__c, itemCost.Standard_Cost__c);
                }                 
            }         
        }
        
        return pActiveStandardCostDecimalMap;
        
    }
    public static Map<Id,Map<Id, Decimal>> itemCostDecMap;
    //this method is supposed to be called when all the costs that are required are as of ONE particular date and not a range of dates. 
    // Most common use case is it is called as of right now. Also this returns only the standard cost and not the cost records.
    public static Decimal getActiveStandardCostDecimal(Set<Id> ItemIds, Set<id> FacilityIds, Id CompanyId, Id FacilityId, DateTime activeStandardCostDate, Id itemId){
        
        if(itemCostDecMap == null || pItemsForQuery != ItemIds || facilitySet != facilityIds ) {
            itemCostDecMap = getActiveStandardCostDecimalMap(ItemIds, FacilityIds, 'Approved',activeStandardCostDate);
        }
            
        if(itemCostDecMap.containsKey(facilityId) && itemCostDecMap.get(facilityId).containsKey(itemId)) {
            return itemCostDecMap.get(facilityId).get(itemId);
        }
        else if(itemCostDecMap.containsKey(null) && itemCostDecMap.get(null).containsKey(itemId)) {
            return itemCostDecMap.get(null).get(itemId);
        }
        else {
            return 0;
        }
    }
 
    
    /////////////////////////////////////////////////////////////
    @RemoteAction 
    global static Double getActiveStandardCost(Id ItemId, Id CompanyId, Id FacilityId, Date activeStandardCostDate) {
    	
    	DateTime costDate;
    	
    	if(activeStandardCostDate != null)
            	costDate = datetime.newInstance(activeStandardCostDate.year(), activeStandardCostDate.month(),activeStandardCostDate.day()); 
        
        return getActiveStandardCostDecimal(new Set<Id>{ItemId}, new Set<Id>{FacilityId}, CompanyId, FacilityId, costDate, ItemId);
    }
    
    public static Double getActiveStandardCost(Id ItemId, Id CompanyId, Id FacilityId, DateTime activeStandardCostDate) {
    	    	
        return getActiveStandardCostDecimal(new Set<Id>{ItemId}, new Set<Id>{FacilityId}, CompanyId, FacilityId, activeStandardCostDate, ItemId);
    }

    private static Map<Id,Double> pActiveStandardCost;
	//this method is supposed to be called when cost records are required as of many dates.
	//Please ensure to call the preCacheCostRecords method in this class before calling this method to ensure correct results
    public static Map<Id,Double> getActiveStandardCost(Set<Id> ItemIds,Set<Id> FacilityIds, Id CompanyId, Id FacilityId, DateTime activeStandardCostDate) {
		
		String currentCostKey = CompanyId+'-'+FacilityId+'-'+activeStandardCostDate;
		
        if(pActiveStandardCost == null || pItemsForQuery != ItemIds || costKey != currentCostKey ) {
        	Map<Id,Item_Cost__c> itemCostMap = getActiveStandardCostRecord(ItemIds,FacilityIds, CompanyId, FacilityId, activeStandardCostDate);
			pActiveStandardCost = new Map<Id,Double>();
			
	        for(Id key : itemCostMap.keyset()) {
	        	pActiveStandardCost.put(key,itemCostMap.get(key) != null ? itemCostMap.get(key).Standard_Cost__c : null);
	        }
        }
        
        return pActiveStandardCost;
    }
    
    private static Map<Id,Item_Cost__c> pActiveStandardCostRecord;
    private static Map<Id, Map<Id,List<Item_Cost__c>>> preLoadedCostRecords;
    private static String costKey = null;
    
    public static Map<Id,Item_Cost__c> getActiveStandardCostRecord(Set<Id> ItemIds,Set<Id> FacilityIds, Id CompanyId, Id FacilityId, DateTime activeStandardCostDate) {
        if(activeStandardCostDate == null) {activeStandardCostDate = System.now();}
        
        String currentCostKey = CompanyId+'-'+FacilityId+'-'+activeStandardCostDate;
		
        if(pActiveStandardCostRecord == null || pItemsForQuery != ItemIds || costKey != currentCostKey) {
        	
        	costKey = currentCostKey;
        	
        	Map<Id, Map<Id,List<Item_Cost__c>>> itemCostMap = getActiveStandardCostMap(ItemIds,FacilityIds,'Approved',activeStandardCostDate);
            
        	if(pActiveStandardCostRecord == null)
        	    pActiveStandardCostRecord = new Map<Id,Item_Cost__c>();
        	
	        for(Id ItemId : ItemIds) {
		        boolean costFound = false;
		        if(itemCostMap.containsKey(facilityId) && itemCostMap.get(facilityId).containsKey(itemId)) {
		            
		            for(Item_Cost__c ic : itemCostMap.get(facilityId).get(itemId) ){ 
		                if(ic.Start_Date__c <= activeStandardCostDate){
		                    pActiveStandardCostRecord.put(ItemId,ic);
		                    costFound = true;
		                    break;
		                }
		            }
		        }
		        else if(itemCostMap.containsKey(null) && itemCostMap.get(null).containsKey(itemId)) {
		            for(Item_Cost__c ic : itemCostMap.get(null).get(itemId) ){ 
		                
		                if(ic.Start_Date__c <= activeStandardCostDate){
		                    pActiveStandardCostRecord.put(ItemId,ic);
		                    costFound = true;
		                    break;
		                }
		            }
		        }
		        else {
		        	pActiveStandardCostRecord.put(ItemId,null);
		        }
		        if(!costFound){
                    pActiveStandardCostRecord.put(ItemId,null);
                 }
	        }
        }
        return pActiveStandardCostRecord;
    }
    
    public static void preCacheCostRecords( List<Datetime> dateList, set<id> itemIds, set<id> facilityIds ){
    	
    	if(dateList.size() > 0 && itemIds.Size() > 0){
			dateList.sort();
			Datetime biggestDate = dateList[dateList.size()-1];
			preLoadedCostRecords = null;
			ItemService.getActiveStandardCost(itemIds,facilityIds,null,null,biggestDate);
		}
    }

    // KNDY-19153
//    public static void validatePackagingUOMs (List<Item_Specification__c> itemSpecs) {
//        Set<Id> itemIds = new Set<Id>();
//        for (Item_Specification__c iSpec : itemSpecs ) {
//            itemIds.add(iSpec.Item__c);
//        }
//
//        SOQLUtil util = new SOQLUtil('Item__c', true);
//        util.addFields(new Set<String>{'Packaging_UOM__c', 'Id'});
//        util.setWhereClause('Id in :itemIDs');
//
//        Map<Id,Item__c> items = new Map<Id, Item__c> ( (List<Item__c>) Database.query(util.getQuery()));
//        for (Item_Specification__c iSpec : itemSpecs ) {
//            if ( items.containsKey(iSpec.Item__c) ) {
//                String itemPackagingUom = items.get(iSpec.Item__c).Packaging_UOM__c;
//                if ( iSpec.Packaging_UOM__c != null &&   itemPackagingUom.contains(iSpec.Packaging_UOM__c) == false ) {
//                    iSpec.addError(Label.Packaging_UOM_not_configured_for_the_Item);
//                } else if (iSpec.Default_Work_Order_Packaging_UOM__c != null && itemPackagingUom.contains(iSpec.Default_Work_Order_Packaging_UOM__c) == false) {
//                    iSpec.addError(Label.Packaging_UOM_not_configured_for_the_Item);
//                }
//            }
//        }
//
//
//    }

    public static void itemSpecWOCheck(List<Item_Specification__c> itemSpecs) {
     	
     	Set<Id> itemspecIds = new Set<Id>();     	
     	for(Item_Specification__c ispec: itemSpecs) {
     		itemspecIds.add(ispec.Id);     	
     	}
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
        SOQLUtil soql = new SOQLUtil('Work_Order__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Status__c'
        });
        soql.setWhereClause('Assembly_Item_Specification__c =: itemspecIds and Status__c NOT IN (\'Closed\',\'Cancelled\')');
        List<Work_Order__c> wolist = Database.query(soql.getQuery());

     	//PTM-761
		if(wolist.size() > 0) {
			
			for(Item_Specification__c ispec: itemSpecs) {
			    for(String str: util.getFieldsFromFieldSetString(Item_Specification__c.sObjectType , 'Read_Only_Fields')){
					if (KSE.isFieldChanging(str, ispec, Trigger.oldMap)){
						ispec.addError(Label.Cannot_edit_Item_Specification);
						break;
					}
			     }	
			}
			
		}
    }
    public static List<Id> cloneItemCosts(List<Item_Cost__c> itemCosts,String targetStatus) {
        if (targetStatus == 'Approved')
            return new List<Id>();

        /*List<Schema.sObjectField> itemCostFields = Item_Cost__c.sObjectType.getDescribe().fields.getMap().values();
        String itemCostQuery = 'SELECT ' + itemCostFields[0];
        for (Integer i=1;i<itemCostFields.size();i++)
            itemCostQuery += ',' + itemCostFields[i];
        itemCostQuery += ' FROM Item_Cost__c WHERE Id IN :itemCosts';*/
        
        Set<String> icFields = Item_Cost__c.sObjectType.getDescribe().fields.getMap().keySet();
        
        SOQLUtil soql = new SOQLUtil('Item_Cost__c');
        soql.addFields(icFields);
        soql.setWhereClause('Id IN :itemCosts');
 
        Map<Id,Item_Cost__c> queriedItemCosts = new Map<Id,Item_Cost__c>((List<Item_Cost__c>)Database.query(soql.getQuery()));
        List<Item_Cost__c> itemCostsToInsert = new List<Item_Cost__c>();
        for (Item_Cost__c itemCost:itemCosts) {
            Item_Cost__c queriedItemCost = queriedItemCosts.get(itemCost.Id);
            Item_Cost__c newItemCost = itemCost.clone(false,true,false,false);
            if (queriedItemCost.Item__c == newItemCost.Item__c)
                newItemCost.Planning_Reference__c = itemCost.Id;
            else
                newItemCost.Item_Specification__c = null;
            newItemCost.Status__c = targetStatus;
            newItemCost.Date_Approved__c = null;
            newItemCost.ExtId__c = null;  
            newItemCost.On_hand_Revaluation__c = false;
            newItemCost.Invalid_Flag__c = false;
            itemCostsToInsert.add(newItemCost);
        }
        try {
            DML.insertAsUser(itemCostsToInsert);
        } catch (DmlException e) {
            if (e.getDMLType(0) == StatusCode.DUPLICATE_VALUE)
                throw new ItemServiceException(Label.One_or_more_resulting_item_cost_already_exists);
            throw e;
        }
        return new List<Id>((new Map<Id,Item_Cost__c>(itemCostsToInsert)).keySet());
    }
    public static void setPackagingUOM(List<Item__c>items){
    	//Copy Stocking UOM if Packaging UOM is blank
		for(Item__c item : items){
			if(item.Stocking_UOM__c != null && item.Packaging_UOM__c == null){
            	item.Packaging_UOM__c = JSON.serialize(new List<Id>{ item.Stocking_UOM__c });
            }
		}
    }
    
    public static void populateItemIdentifier(){
    	
    	if((trigger.isAfter && trigger.isInsert) || (trigger.isBefore && trigger.isUpdate)){
	    	List<Item__c> updatedItems = new List<Item__c>();
	    	
	    	for(Item__c item : (List<Item__c>) trigger.new){
	    		
	    		if(trigger.isInsert || (trigger.isUpdate && KSE.isFieldChanging('Item_Identifier__c', item, trigger.oldMap))){
	    			
	    			if(trigger.isUpdate && trigger.oldMap.get(item.Id).get('Item_Identifier__c') != null){
	    				item.addError('Item Identifier value cannot be modified');
	    			}
		    		else
		    		if(String.isBlank(item.Item_Identifier__c)){
	    				updatedItems.add(
	    					new Item__c(
	    						Id = item.Id,
	    						Item_Identifier__c = String.valueOf(item.Id).substring(3, 15)
	    					)
	    				);
		    		}
		    		else
		    		if(String.valueOf(item.Item_Identifier__c).length() > 12){
		    			item.addError('Item Identifier value cannot be more than 12 characters');
		    		}
	    		}
	    	}
	    	
	    	if(updatedItems.size() > 0){
	    		DML.updateAsSystem(updatedItems);
	    	}
	    }
    }

    public static List<Id> getPackagingUoms(Item__c item) {
        if (packagingUoms.containsKey(item.Id) == false) packagingUoms.put(item.Id, (List<Id>)JSON.deserialize(item.Packaging_UOM__c, List<Id>.Class));
        return packagingUoms.get(item.Id);
    }


    public String scope { get; set; }
    public Boolean rollupRouting { get; set; } { rollupRouting = false; }
    public Boolean calcMfgOverhead { get; set; } { calcMfgOverhead = false; }
    public Id companyId { get; set; }
    public Id facilityId { get; set; }
    public Facility__c facility { get; set; }
    public Id itemSpecId { get; set; }
    public Boolean costing { get; set; }
    public Boolean production { get; set; }
    public String componentCostStatus { get; set; }
    public String assemblyCostStatus { get; set; }
    public String explosionBasis { get; set; }
    public String rollupBasis { get; set; }
    public Boolean wipeoutCosts { get; set; } { wipeoutCosts = false; }
    public Boolean explodePurchased { get; set; } { explodePurchased = true; }
    public DateTime startDate { get; set; } { startDate = System.now(); }
    public Boolean bypassPhantoms { get; set; } { bypassPhantoms = false; }
    public Boolean isRepair { get; set; } { isRepair = false; }
    public Integer maxLevel { get; set; } { maxLevel = 0; }

    private Item_Specification__c itemSpec;

    public static final Set<String> itemFields = new Set<String>{ 'Id', 'Name', 'Description__c', 'Item_Type__c', 'Source__c', 'Stocking_UOM__c', 'Stocking_UOM__r.Name','Packaging_UOM__c' };

    public Map<Id, Item_Specification__c> itemSpecs = new Map<Id, Item_Specification__c>();
    public void getItemSpecs(Set<Id> itemIds) {
        getItemSpecs(itemIds, false);
    }
    public void getItemSpecs(Set<Id> itemIds, Boolean fetchInactive) {
        Set<Id> itemIdsToQuery = new Set<Id>();
        for (Id itemId:itemIds) {
            if (!itemSpecs.containsKey(itemId)) {
                itemIdsToQuery.add(itemId);
            }
        }

        if (itemIdsToQuery.size() == 0) return;

        SOQLUtil itemSpecQuery = new SOQLUtil('Item_Specification__c');
        itemSpecQuery.addFields(new Set<String>{ 'Id', 'Name', 'Facility__c', 'Item__c', 'Facility__r.Facility_Identifier__c', 'Packaging_UOM__c', 'Item__r.Stocking_UOM__r.Name','Active__c' });
        for (String itemField:itemFields) itemSpecQuery.addField('Item__r.' + itemField);
        itemSpecQuery.setOrderByClause('Start_Date2__c DESC');

        String whereClause = 'Company__c = :companyId ' +
                             'AND (Facility__c = :facilityId OR Facility__c = null) ' +
                             'AND Start_Date2__c <= :startDate '+
                             'AND Item__c IN :itemIds ';
        if (scope != 'SINGLE FOR EXPANDED BOM') {
            if (explosionBasis == 'Costing') {
                whereClause += 'AND Costing__c = true ';
            } else if (explosionBasis == 'Production') {
                whereClause += ' AND Production__c = true '; 
            }
        } else if (costing != null && production != null) {
            whereClause += 'AND Costing__c = ' + costing + ' AND Production__c = ' + production + ' ';
        }
        if (isRepair) {
            whereClause += ' AND Type__c != \'Template\' ';
        } else {
            whereClause += ' AND Type__c = \'Assembly\' ';
        }
        if ( !fetchInactive ) {
            whereClause += ' AND Active__c = true ';
        }
        itemSpecQuery.setWhereClause(whereClause);

        SOQLUtil.ChildRelationship routingQuery = new SOQLUtil.ChildRelationship(itemSpecQuery, 'Routings__r');
        routingQuery.addFields(new Set<String>{ 'Id', 'Name', 'Resource_Quantity__c', 'Standard_Hours__c', 'Work_Center__c', 'Work_Center_Resource__c', 'Work_Center__r.Manufacturing_Overhead_Factor__c', 'Work_Center_Resource__r.Resource__c', 'Work_Center_Resource__r.Resource__r.Rate__c' });
        itemSpecQuery.addChildRelationship(routingQuery);

        SOQLUtil.ChildRelationship componentQuery = new SOQLUtil.ChildRelationship(itemSpecQuery, 'Components__r');
        componentQuery.addFields(new Set<String>{ 'Id', 'Name', 'Component_Item__c', 'Quantity_per_Assembly__c', 'Type__c', 'Yield__c', 'Component_Item__r.Stocking_UOM__r.Name' });
        for (String itemField:itemFields) componentQuery.addField('Component_Item__r.' + itemField);
        componentQuery.addFields('Component_BOM_FieldSet');
        componentQuery.setOrderByClause('Component_Sequence__c ASC');
        itemSpecQuery.addChildRelationship(componentQuery);

        for (Item_Specification__c spec:Database.query(itemSpecQuery.getQuery())) {
            if (itemSpecId == spec.Id) itemSpec = spec;
            if (!itemSpecs.containsKey(spec.Item__c) || (itemSpecs.get(spec.Item__c).Facility__c == null && spec.Facility__c != null)) {
                itemSpecs.put(spec.Item__c, spec);
            }
        }
        if (itemSpec != null) itemSpecs.put(itemSpec.Item__c, itemSpec);
    }

    public Map<Id, Item_Cost__c> existingItemCosts = new Map<Id, Item_Cost__c>();
    public void getExistingItemCosts(Map<Id, Item__c> items) {
        Set<Id> itemIdsToQuery = new Set<Id>();
        for (Id itemId:items.keySet()) {
            if (!existingItemCosts.containsKey(itemId)) {
                itemIdsToQuery.add(itemId);
            }
        }

        if (itemIdsToQuery.size() == 0) return;

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Facility__c','Facility__r.Facility_Identifier__c', 'Item__c', 'Standard_Cost__c' });
        costQuery.addFields(costRollupFieldSet);
        costQuery.setWhereClause('Item__c IN :itemIdsToQuery AND Status__c = :componentCostStatus AND Start_Date__c <= :startDate AND Invalid_Flag__c = false AND (Facility__c = :facilityId OR Facility__c = null)');
        costQuery.setOrderByClause('Start_Date__c DESC');

        for (Item_Cost__c itemCost:Database.query(costQuery.getQuery())) {
            if (!existingItemCosts.containsKey(itemCost.Item__c) || (existingItemCosts.get(itemCost.Item__c).Facility__c == null && itemCost.Facility__c != null)) {
                for (String fieldPath:costRollupFieldSet) {
                    if (itemCost.get(fieldPath) == null || (itemSpecs.containsKey(itemCost.Item__c) == true && ((fieldPath == 'Labor_Cost__c' && rollupRouting == true) || (fieldPath == 'Overhead_Cost__c' && calcMfgOverhead == true)))) {
                        if (itemCost.get(fieldPath) != null) itemCost.Standard_Cost__c -= (Decimal)itemCost.get(fieldPath);
                        itemCost.put(fieldPath, 0.0.setScale(6));
                    } else {
                        itemCost.put(fieldPath, ((Decimal)itemCost.get(fieldPath)).setScale(6));
                    }
                }
                existingItemCosts.put(itemCost.Item__c, itemCost);
            }
        }

        for (Id itemId:itemIdsToQuery) {
            if (!existingItemCosts.containsKey(itemId)) {
                Item__c item = items.get(itemId);
                Item_Cost__c itemCost = new Item_Cost__c(
                    Name = item.Name,
                    Item__c = item.Id,
                    Item__r = item,
                    Company__c = companyId,
                    Facility__c = facilityId,
                    Facility__r = facility,
                    Status__c = componentCostStatus,
                    Standard_Cost__c = 0.0.setScale(6)
                );
                for (String fieldPath:costRollupFieldSet) {
                    itemCost.put(fieldPath, 0.0.setScale(6));
                }
                existingItemCosts.put(item.Id, itemCost);
            }
        }
    }

    public Map<Id, Item_Cost__c> itemCosts = new Map<Id, Item_Cost__c>();
    public Item_Cost__c getItemCost(Item__c item, List<Id> parentItemIds) {
        Item_Cost__c itemCost = existingItemCosts.get(item.Id);

        if (itemCosts.containsKey(item.Id)) {
            itemCost = itemCosts.get(item.Id);
        } else if (itemSpecs.containsKey(item.Id)) {
            Item_Specification__c itemSpec = itemSpecs.get(item.Id);

            Decimal cf = 1.0;

            if ( String.isNotEmpty(item.Packaging_UOM__c) ) {
                List<Id> lstPkgUoms = (List<Id>) JSON.deserialize(item.Packaging_UOM__c, List<Id>.class);
                packagingUoms.put(item.Id, lstPkgUoms);
            }

            Decimal facilityIdentifier = (itemCost == null || itemCost.Facility__c == null) ? null : itemCost.Facility__r.Facility_Identifier__c;
            if ( packagingUoms.containsKey(item.Id)) {
                cf = KSE.getConversionFactor(item.Id, facilityIdentifier, itemSpec.Packaging_UOM__c, item.Stocking_UOM__c, packagingUoms.get(item.Id));
            }

            if (item.Item_Type__c == null || item.Item_Type__c == '' || !bypassPhantoms || rollupBasis == 'Linear') {
                item.Item_Type__c = 'Material';
            }

            for (String fieldPath:costRollupFieldSet) {
                String fld = stripField(fieldPath);
                if ((fld != 'Labor' || rollupRouting == false) && (fld != 'Overhead' || calcMfgOverhead == false) && (fld == item.Item_Type__c || (wipeoutCosts == true && (rollupBasis == 'Linear' || bypassPhantoms == true)))) {
                    itemCost.Standard_Cost__c -= (Decimal)itemCost.get(fieldPath);
                    itemCost.put(fieldPath, 0.0);
                }
            }

            if (rollupRouting == true || calcMfgOverhead == true) {
                Decimal laborCost = 0.0;
                Decimal overheadCost = 0.0;
                for (Routing__c routing:itemSpec.Routings__r) {
                    Decimal hrs = KSE.addQuantityToField(routing.Standard_Hours__c, 0);
                    Decimal rate = KSE.addQuantityToField(routing.Work_Center_Resource__r.Resource__r.Rate__c, 0);
                    if (rollupRouting == true) laborCost += ( (hrs * rate * KSE.addQuantityToField(routing.Resource_Quantity__c, 0))/cf );
                    if (calcMfgOverhead == true) overheadCost += ((hrs * rate * KSE.addQuantityToField(routing.Work_Center__r.Manufacturing_Overhead_Factor__c, 0))/cf);
                }

                Item_Cost__c laborOverheadCost;
                if (item.Source__c != ITEM_SOURCE_PHANTOM || bypassPhantoms == false || parentItemIds.size() == 0) {
                    laborOverheadCost = itemCost;
                } else {
                    for (Integer i = parentItemIds.size() - 1; i >= 0; i--) {
                        Id parentItemId = parentItemIds[i];
                        if (itemSpecs.get(parentItemId).Item__r.Source__c != ITEM_SOURCE_PHANTOM) {
                            laborOverheadCost = existingItemCosts.get(parentItemId);
                            break;
                        }
                    }
                    if (laborOverheadCost == null) laborOverheadCost = existingItemCosts.get(parentItemIds[0]);
                }

                laborOverheadCost.Labor_Cost__c += laborCost.setScale(6);
                laborOverheadCost.Overhead_Cost__c += overheadCost.setScale(6);
                laborOverheadCost.Standard_Cost__c += laborCost + overheadCost;
            }

            for (Component__c component:itemSpec.Components__r) {
                Item__c compItem = component.Component_Item__r;
                if ( String.isNotEmpty(compItem.Packaging_UOM__c) ) {
                    List<Id> lstPkgUoms = (List<Id>) JSON.deserialize(compItem.Packaging_UOM__c, List<Id>.class);
                    packagingUoms.put(compItem.Id, lstPkgUoms);
                }

                Item_Cost__c compCost = itemCosts.get(compItem.Id);
                Item_Specification__c compItemSpec = itemSpecs.get(compItem.Id);

                if (compItem.Item_Type__c == null || compItem.Item_Type__c == '' || !bypassPhantoms || rollupBasis == 'Linear') {
                    compItem.Item_Type__c = 'Material';
                }

                for (String fieldPath:costRollupFieldSet) {
                    Decimal costAmt;
                    if (rollupBasis == 'Linear' || (compItemSpec != null && compItem.Source__c == ITEM_SOURCE_PHANTOM && bypassPhantoms)) {
                        costAmt = (Decimal)compCost.get(fieldPath) * 100 / component.Yield__c;
                    } else if (stripField(fieldPath) == compItem.Item_Type__c) {
                        costAmt = (Decimal)compCost.Standard_Cost__c * 100 / component.Yield__c;
                    }

                    if (costAmt != null) {
                        costAmt = component.Quantity_per_Assembly__c * costAmt;
                        if (component.Type__c == ComponentService.TYPE_BYPRODUCT) costAmt = -costAmt;
                        itemCost.put(fieldPath, KSE.addQuantityToField((Decimal)itemCost.get(fieldPath), costAmt));
                        itemCost.Standard_Cost__c += costAmt;
                    }
                }
            }

            for (String fieldPath:costRollupFieldSet) {
                itemCost.put(fieldPath, ((Decimal)itemCost.get(fieldPath)).setScale(6));
            }
            itemCost.Standard_Cost__c = itemCost.Standard_Cost__c.setScale(6);
        }

        itemCosts.put(item.Id, itemCost);
        return itemCost;
    }

    public List<ItemSpecificationCostRollupExt.IndentedBomWrapper> getBoms(Map<Id, Item__c> items, Map<Id, Component__c> components, Integer level, List<Id> parentItemIds, Decimal parentQty, String mode) {
        if (level > maxLevel) maxLevel = level;

        if (components == null) components = new Map<Id, Component__c>();

        if (parentItemIds == null) parentItemIds = new List<Id>();
        Set<Id> parentIdSet = new Set<Id>(parentItemIds);

        Set<Id> itemIdsForSpec = new Set<Id>();
        Map<Id, Item__c> itemsForCost = new Map<Id, Item__c>();
        Map<Id, Map<Id, Item__c>> componentItems = new Map<Id, Map<Id, Item__c>>();
        Map<Id, Map<Id, Component__c>> componentMap = new Map<Id, Map<Id, Component__c>>();
        for (Id itemId:items.keySet()) {
            Item_Specification__c itemSpec = itemSpecs.get(itemId);
            if (itemSpec != null) {
                componentItems.put(itemId, new Map<Id, Item__c>());
                componentMap.put(itemId, new Map<Id, Component__c>());

                // getting conversion factor for item spec uom to stocking uom for costing purposes
                Decimal cf = 1.0;
                if ( String.isNotEmpty(itemSpec.Item__r.Packaging_UOM__c) ) {
                    List<Id> lstPkgUoms = (List<Id>) JSON.deserialize(itemSpec.Item__r.Packaging_UOM__c, List<Id>.class);
                    packagingUoms.put(itemSpec.Item__c, lstPkgUoms);
                }

                Decimal facilityIdentifier = (itemSpec == null || itemSpec.Facility__c == null) ? null : itemSpec.Facility__r.Facility_Identifier__c;
                if ( itemSpec != null && packagingUoms.containsKey(itemSpec.Item__c)) {
                    cf = KSE.getConversionFactor(itemSpec.Item__c, facilityIdentifier, itemSpec.Packaging_UOM__c, itemSpec.Item__r.Stocking_UOM__c, packagingUoms.get(itemSpec.Item__c));
                }

                for (Component__c comp:itemSpec.Components__r) {
                    Item__c compItem = comp.Component_Item__r;

                    if (parentIdSet.contains(compItem.Id)) {
                        throw new ItemServiceException(Label.Recursion_Found_at_Level + (level + 1));
                    }

                    if (compItem.Source__c == ITEM_SOURCE_MANUFACTURED || compItem.Source__c == ITEM_SOURCE_MAKE_TO_ORDER || compItem.Source__c == ITEM_SOURCE_PHANTOM || compItem.Source__c == ITEM_SOURCE_KIT || (explodePurchased && compItem.Source__c == ITEM_SOURCE_PURCHASED)) {
                        itemIdsForSpec.add(compItem.Id);
                    }
                    if (scope != 'SINGLE FOR EXPANDED BOM') itemsForCost.put(compItem.Id, compItem);

                    // updating the qpa based on the item spec conversion
                    // qpa updated here available to the item cost.
                    comp.Quantity_per_Assembly__c = comp.Quantity_per_Assembly__c / cf;
                    componentItems.get(itemId).put(compItem.Id, compItem);
                    componentMap.get(itemId).put(compItem.Id, comp);
                }
            }
        }

        if (itemIdsForSpec.size() > 0) getItemSpecs(itemIdsForSpec);
        if (itemsForCost.size() > 0) getExistingItemCosts(itemsForCost);

        List<ItemSpecificationCostRollupExt.IndentedBomWrapper> wrappers = new List<ItemSpecificationCostRollupExt.IndentedBomWrapper>();
        if (mode == 'READBATCH') wrappers.add(new ItemSpecificationCostRollupExt.IndentedBomWrapper());

        for (Id itemId:items.keySet()) {
            Item__c item = items.get(itemId);
            Component__c component = components.get(itemId);

            List<Id> parentIds = new List<Id>(parentItemIds);
            parentIds.add(itemId);

            List<ItemSpecificationCostRollupExt.IndentedBomWrapper> componentWrappers = new List<ItemSpecificationCostRollupExt.IndentedBomWrapper>();
            if (componentItems.containsKey(itemId)) {
                componentWrappers = getBoms(componentItems.get(itemId), componentMap.get(itemId), level + 1, parentIds, parentQty * (component != null ? component.Quantity_per_Assembly__c : 1), mode);
            }

            if (scope != 'SINGLE FOR EXPANDED BOM') getItemCost(item, parentItemIds);

            Item_Cost__c itemCost = itemCosts.get(itemId);
            Item_Specification__c itemSpec = itemSpecs.get(itemId);
            if (mode == 'READ') {
                ItemSpecificationCostRollupExt.IndentedBomWrapper wrapper = new ItemSpecificationCostRollupExt.IndentedBomWrapper();
                wrapper.levelCounter = level;
                wrapper.href = component != null ? component.Id : itemSpec.Id;
                wrapper.componentName = item.Name;
                if (component != null) {
                    wrapper.quantityPerAssembly = component.Quantity_per_Assembly__c.setScale(6);
                    wrapper.yield = component.Yield__c;
                    wrapper.totalQuantityPerAssembly = (parentQty * component.Quantity_per_Assembly__c).setScale(6);
                }
                if (scope == 'SINGLE FOR EXPANDED BOM') {
                    if (itemSpec != null) {
                        wrapper.href1 = itemSpec.Id;
                        wrapper.itemSpecName = itemSpec.Name;
                        wrapper.compObj = new Component__c(Component_Item__r = item);
                    }
                    if (component != null) {
                        wrapper.compObj = component;
                    }
                    if (item.Stocking_UOM__c != null) wrapper.componentUom = item.Stocking_UOM__r.Name;
                } else if (scope == 'SINGLE') {
                    wrapper.componentDescription = item.Description__c;
                    wrapper.componentSource = item.Source__c;
                    if (item.Stocking_UOM__c != null) wrapper.componentUom = item.Stocking_UOM__r.Name;
                    wrapper.compCost = itemCost;
                    wrapper.componentTotalCost = itemCost.Standard_Cost__c.setScale(6);
                }

                wrappers.add(wrapper);
                wrappers.addAll(componentWrappers);
            } else if (mode == 'READBATCH' && (parentItemIds.size() > 0 || itemSpec != null)) {
                wrappers[0].csvLine += generateExpandedBOMLine(item, component, itemCost, level, parentQty);
                if (componentWrappers.size() > 0) wrappers[0].csvLine += componentWrappers[0].csvLine;
            }
        }

        return wrappers;
    }

    public static String generateExpandedBOMHeader(Integer maxLevel) {
        String csvHeader = '';
        for (Integer i = 0; i <= maxLevel; i++) {
            csvHeader += '"",';
        }
        csvHeader += '"Description","Component Source","Component Stocking UOM","Quantity Per Assembly","Quantity per Top Assembly","Yield %","Yield Quantity"';
        for (Schema.FieldSetMember f:costRollupFields) {
            csvHeader += ',"' + f.getLabel() + '"';
        }
        csvHeader += ',"Cost per Assembly","Cost per Top Assembly"';
        return csvHeader;
    }

    public String generateExpandedBOMLine(Item__c item, Component__c component, Item_Cost__c itemCost, Integer level, Decimal parentQty) {
        String csvLine = '\n';
        for (Integer i = 0; i < level; i++) {
            csvLine += '"",';
        }
        csvLine += '"' + item.Name + '"';
        for (Integer i = level + 1; i <= maxLevel; i++) {
            csvLine += ',""';
        }
        csvLine += ',"' + item.Description__c + '"';
        csvLine += ',"' + item.Source__c + '"';
        csvLine += ',"' + (item.Stocking_UOM__c != null ? item.Stocking_UOM__r.Name : '') + '"';
        csvLine += ',"' + (component != null ? String.valueOf(component.Quantity_per_Assembly__c.setScale(6)) : '') + '"';
        csvLine += ',"' + (component != null ? String.valueOf((parentQty * component.Quantity_per_Assembly__c).setScale(6)) : '') + '"';
        csvLine += ',"' + (component != null ? String.valueOf(component.Yield__c) : '') + '"';
        csvLine += ',"' + (component != null ? String.valueOf((component.Quantity_per_Assembly__c * 100 / component.Yield__c).setScale(6)) : '') + '"';
        for (String fieldPath:costRollupFieldSet) {
            csvLine += ',"' + itemCost.get(fieldPath) + '"';
        }
        csvLine += ',"' + itemCost.Standard_Cost__c + '"';
        csvLine += ',"' + (parentQty * (component != null ? component.Quantity_per_Assembly__c : 1) * itemCost.Standard_Cost__c).setScale(6) + '"';
        return csvLine;
    }

    public void updateCosts(Set<Id> itemIds) {
        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addFields(new Set<String>{ 'Id', 'Name', 'Item__c' });
        costQuery.setWhereClause('Item__c IN :itemIds AND Status__c = :assemblyCostStatus AND Company__c = :companyId AND Facility__c = :facilityId');
        costQuery.setOrderByClause('Start_Date__c DESC');
        Map<Id, Item_Cost__c> costsToUpdate = new Map<Id, Item_Cost__c>();
        for (Item_Cost__c cost:Database.query(costQuery.getQuery())) {
            if (!costsToUpdate.containsKey(cost.Item__c)) costsToUpdate.put(cost.Item__c, cost);
        }

        for (Id itemId:itemIds) {
            Item_Cost__c rolledUpCost = itemCosts.get(itemId);
            Item_Cost__c costToUpdate = costsToUpdate.get(itemId);

            if (costToUpdate != null) {
                for (String fieldPath:costRollupFieldSet) {
                    costToUpdate.put(fieldPath, rolledUpCost.get(fieldPath));
                }
                costToUpdate.Standard_Cost__c = rolledUpCost.Standard_Cost__c;
            } else {
                costToUpdate = rolledUpCost.clone(false, true);
                costToUpdate.Facility__c = facilityId;
                costToUpdate.Status__c = assemblyCostStatus;
                costsToUpdate.put(itemId, costToUpdate);
            }
            costToUpdate.Item_Specification__c = itemSpecs.containsKey(itemId) ? itemSpecs.get(itemId).Id : null;
            costToUpdate.Start_Date__c = startDate;
        }

        if (costsToUpdate.size() > 0) {
            DML.checkUpsertAsUser(costsToUpdate.values()); upsert costsToUpdate.values();
        }
    }
}