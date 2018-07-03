//KNDY-2170

public with sharing class StandardCostingService {

    private static Set<String> allUniqueObjects {
        get {
            return new Set<String>{'Receipt_Line__c','Receipt_Invoice_Line__c','Inventory_Transaction__c','SKID__c','Purchase_Order_Line__c','Shipment_Line__c'};
        }
    }
    private static Set<String> objectsWithItemLookup {
        get {
            return new Set<String>{'Receipt_Line__c','Receipt_Invoice_Line__c','Inventory_Transaction__c','SKID__c','Purchase_Order_Line__c'};
        }
    }
    private static Set<String> objectsWithProductLookup {
        get {
            return new Set<String>{'Shipment_Line__c'};
        }
    }
    private static Set<String> extendedCostWithConversionFactorObjects {
        get {
            return new Set<String>{'Receipt_Line__c','Receipt_Invoice_Line__c'};
        }
    }
    private static Set<String> extendedCostWithoutConversionFactorObjects {
        get {
            return new Set<String>{'SKID__c','Shipment_Line__c'};
        }
    }
    private static Set<String> extendedCostWithoutStandardCostField {
        get {
            return new Set<String>{'SKID__c','Shipment_Line__c','Receipt_Invoice_Line__c'};
        }
    }
    private static Set<String> allExtendedCostObjects{
        get {
            Set<String> objects = new Set<String>();
            objects.addAll(extendedCostWithConversionFactorObjects);
            objects.addAll(extendedCostWithoutConversionFactorObjects);
            return objects;
        }
    }
    private static Map<String,String> extendedCostQuantity {
        get {
            return new Map<String,String>{'Purchase_Order_Line__c'=>'Quantity_Received__c','Receipt_Line__c'=>'Quantity_Received__c','Receipt_Invoice_Line__c'=>'Quantity_Received__c','Inventory_Transaction__c'=>'Quantity__c','SKID__c'=>'Quantity__c','Shipment_Line__c'=>'Quantity_Shipped__c'};
        }
    }
    private static Set<String> standardCostObjects {
        get {
            return new Set<String>{'Receipt_Line__c'};
        }
    }
    private static Set<String> standardCostWithToAndFromObjects {
        get {
            return new Set<String>{'Inventory_Transaction__c'};
        }
    }
    private static Set<String> standardCostWithDeliveryFacility {
        get {
            return new Set<String>{'Purchase_Order_Line__c'};
        }
    }
    

	//SK: Below call was modified to populate date as Datetime.now instead Date.today. Currently this method is not being used anywhere in the codebase. 
    //If it is to be used please make sure the parameters passed to method ItemService.getActiveStandardCost are per requirement
    public static void updateStandardAndExtendedCost(List<sObject> objects) {
        Set<Id> facilityIds = new Set<Id>();
        Set<Id> itemIdSet = new Set<Id>();
        Set<Id> productSet = new Set<Id>();
        
        String sObjectType = String.valueOf(objects[0].getSObjectType());
        
        

        for(sObject obj : objects) {
            if(standardCostObjects.contains(sObjectType) || extendedCostWithoutStandardCostField.contains(sObjectType)) {
                facilityIds.add((Id) obj.get('Facility__c'));  
            }
            else if(standardCostWithToAndFromObjects.contains(sObjectType)) { 
                facilityIds.add((Id) obj.get('From_Facility__c'));
                facilityIds.add((Id) obj.get('To_Facility__c'));  
            }
            else if(standardCostWithDeliveryFacility.contains(sObjectType)) {
                facilityIds.add((Id) obj.get('Delivery_Facility__c'));
            }
            if(objectsWithProductLookup.contains(sObjectType)) {
                productSet.add((Id) obj.get('Product__c'));
            }
            
        }
        
        
                    
        Map<Id,Id> FacilityCompanyMap = new Map<Id,Id>();

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Company__c'
		});
		soql.setWhereClause('Company__c != null');
		
		for(Facility__c f : Database.query(soql.getQuery())){
            FacilityCompanyMap.put(f.Id,f.Company__c);
        }
        
        soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Item__c'
		});
		soql.setWhereClause('Id IN :productSet');

		Map<Id, Product__c> productMap = new Map<Id, Product__c >((List<Product__c>)Database.query(soql.getQuery()));
        
        Map<Id,Decimal> itemStandardCostMap = new Map<Id,Decimal>();
        Set<Id> ItemIds = new Set<Id>();
        for(sObject obj : objects) {        
        	if(objectsWithItemLookup.contains(sObjectType)) {
                ItemIds.add((Id) obj.get('Item__c'));
            }
        }
        for(sObject obj : objects) {
            Id itemId;
            if(objectsWithItemLookup.contains(sObjectType)) {
                itemId = (Id) obj.get('Item__c');
            }
            else if(objectsWithProductLookup.contains(sObjectType)) {
                Id productId = (Id) obj.get('Product__c');
                itemId = (Id) productMap.get(productId).Item__c;    
            }
            itemIdSet.add(itemId);
            
			set<Id> facilitySet = new set<Id>();
            if(standardCostObjects.contains(sObjectType)) { 
                Id facility = (Id) obj.get('Facility__c');
                facilitySet.add(facility);
                Decimal standardCost = getCost(ItemService.getActiveStandardCost(ItemIds,facilitySet, FacilityCompanyMap.get(Facility),facility,Datetime.now()).get(itemId));
                obj.put('Standard_Cost__c',standardCost);
                itemStandardCostMap.put((Id) obj.get('Id'),(Decimal) obj.get('Standard_Cost__c'));
            }
            else if(standardCostWithToAndFromObjects.contains(sObjectType)) { 
                Id fromFacility = (Id) obj.get('From_Facility__c');
                Id toFacility = (Id) obj.get('To_Facility__c'); 
                facilitySet.add(fromFacility);
                facilitySet.add(toFacility);
                Decimal fromStandardCost = getCost(ItemService.getActiveStandardCost(ItemIds,facilitySet, FacilityCompanyMap.get(fromFacility),fromFacility,Datetime.now()).get(itemId));
                Decimal toStandardCost = getCost(ItemService.getActiveStandardCost(ItemIds,facilitySet, FacilityCompanyMap.get(toFacility),toFacility,Datetime.now()).get(itemId));
                obj.put('From_Standard_Cost__c',fromStandardCost);
                obj.put('To_Standard_Cost__c',toStandardCost);
            }
            else if(extendedCostWithoutStandardCostField.contains(sObjectType)) {
                Id facilityId = (Id) obj.get('Facility__c');
                facilitySet.add(facilityId);
                Id companyId = (Id) (facilityId==null?obj.get('Company__c'):FacilityCompanyMap.get(facilityId));
                Decimal standardCost = getCost(ItemService.getActiveStandardCost(ItemIds,facilitySet, companyId,facilityId,Datetime.now()).get(itemId));
                itemStandardCostMap.put((Id) obj.get('Id'),standardCost);
            }
            
        }
            
        map<id,decimal> itemconversionFactor = new map<id,decimal>(); 
        map<id,decimal> extendedCostMap = new map<id,decimal>();
        map<id,decimal> convertedExtendedCostMap = new map<id,decimal>();
        map<id,decimal> combinedExtendedCostMap = new map<id,decimal>();
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Purchasing_UOM__c','Stocking_UOM__c','Stocking_UOM__r.Name','Purchasing_UOM__r.Name','Packaging_UOM__c'
		});
		soql.setWhereClause('Id IN :itemIdSet');
		
		for(Item__c item : Database.query(soql.getQuery())){
            
            decimal convFactor = KSE.getConversionFactor(item);
            itemConversionFactor.put(item.id,convFactor);
            
            for(sObject obj : objects) {  
                 
                Decimal standardCost = itemStandardCostMap.get(item.Id);
                if(standardCost == null) {
                    standardCost = 0;
                }
                Decimal extendedCost = standardCost;
                String quantityField = '';
                if(extendedCostQuantity.containsKey(sObjectType)) {
                    quantityField = extendedCostQuantity.get(sObjectType);
                    if(obj.get(quantityField)==null) {
                        obj.put(quantityField,0);
                    }
                }
                
                if(extendedCostWithoutConversionFactorObjects.contains(sObjectType)) {
                    if(extendedCostQuantity.containsKey(sObjectType)) {
                        System.Debug(logginglevel.info,'$$$sobjectType--' + sObjectType );
                        System.Debug(logginglevel.info,'$$$extendedCost--' + extendedCost );
                        System.Debug(logginglevel.info,'$$$extendedCostQuantity--' + extendedCostQuantity );
                        System.Debug(logginglevel.info,'$$$quantityField value--' + obj.get(quantityField) );
                        System.Debug(logginglevel.info,'$$$quantityField--' + quantityField );
                        extendedCost = extendedCost * (Decimal) obj.get(quantityField);
                    }
                    extendedCostMap.put(item.id,extendedCost);
                }
                else if(extendedCostWithConversionFactorObjects.contains(sObjectType)) {
                    if(extendedCostQuantity.containsKey(sObjectType)) {
                        System.Debug(logginglevel.info,'$$$sobjectType--' + sObjectType );
                        System.Debug(logginglevel.info,'$$$extendedCost--' + extendedCost );
                        System.Debug(logginglevel.info,'$$$extendedCostQuantity--' + extendedCostQuantity );
                        System.Debug(logginglevel.info,'$$$quantityField value--' + obj.get(quantityField) );
                        System.Debug(logginglevel.info,'$$$quantityField--' + quantityField );
                        extendedCost = extendedCost * (Decimal) obj.get(quantityField) * itemConversionFactor.get(item.Id);
                    }
                    convertedExtendedCostMap.put(item.id,extendedCost);
                }
            }
            
            combinedExtendedCostMap.putAll(extendedCostMap);
            combinedExtendedCostMap.putAll(convertedExtendedCostMap);
        }
            
        for(sObject obj : objects) {
            if(allExtendedCostObjects.contains(sObjectType)) {
            	Decimal extendedCost;
            	if(objectsWithItemLookup.contains(sObjectType)) {
                	extendedCost = (Decimal) combinedExtendedCostMap.get((Id) obj.get('Item__c'));
            	}
            	else if(objectsWithProductLookup.contains(sObjectType)) {
            		extendedCost = (Decimal) combinedExtendedCostMap.get((Id) obj.get('Product__c'));
            	}
                obj.put('Extended_Cost__c',getCost(extendedCost)); 
            }
        }
    
    }

    public static Decimal getCost(Decimal cost) {
        return KSE.addQuantityToField(cost, 0);
    }
    
    
    
    /*
    	RS: FIN-894 Refactor to support incorrect/random item cost return from service
    */
   
   /*
	* @description: 
	*/
	public class ItemCostDefinition{
		
		public Id itemId;
		public Id facilityId;
		public Id companyId;
		
		public ItemCostDefinition(Id itemId, id facilityId, Id companyId){
			this.itemId = itemId;
			this.facilityId = facilityId;
			this.companyId = companyId;
		}
		
		//Defines uniqueness when comparing an apex class as key in sets or maps
		//http://www.salesforce.com/us/developer/docs/apexcode/Content/langCon_apex_collections_maps_keys_userdefined.htm
		public boolean equals(object obj){
			ItemCostDefinition icd = (ItemCostDefinition)obj;
			if(itemId == icd.itemId
					&& facilityId == icd.facilityId
					&& companyId == icd.companyId){
				return true;			
			}else{
				return false;
			}
		}
		
		public integer hashCode(){
			return HashCodeGenerator.getHashCode(this);  
		}
		
	}
	
	
	public static List<Item_Cost__c> returnItemCosts(set<Id> itemIds, List<Date> dates, string costType){
		dates.sort();
		Date beginDate = dates[0];
		Date endDate = dates[dates.size()-1]; 
		String queryString = 'SELECT ' + ItemService.costRollupFieldsForQuery + ' Id, Item__c,Status__c, Facility__c, Company__c, Standard_Cost__c, Item__r.Name, Date_Activated__c' +
                                 ' FROM Item_Cost__c' + 
                                 ' WHERE Status__c =:costType' + 
                                 ' AND (Date_Activated__c <= :endDate OR Date_Activated__c = null)' + 
                                 ' AND (Date_Deactivated__c >= :beginDate OR Date_Deactivated__c = null)' + 
                                 ' AND Item__c IN :ItemIds '+
                                 ' ORDER BY Date_Activated__c asc';
		
		Set<String> itemCostFields = new Set<String>();
		
		for(Schema.FieldSetMember fsMember : ItemService.costRollupFields){
			itemCostFields.add(fsMember.getFieldPath());
		}
		
		String whereClause = 'Status__c =:costType' + 
                             ' AND (Date_Activated__c <= :endDate OR Date_Activated__c = null)' + 
                             ' AND (Date_Deactivated__c >= :beginDate OR Date_Deactivated__c = null)' + 
                             ' AND Item__c IN :ItemIds '+
                             ' ORDER BY Date_Activated__c asc';
        
	    SOQLUtil soql = new SOQLUtil('Item_Cost__c');
	    soql.addFields(itemCostFields);
	    soql.addFields(new Set<String>{'Id', 'Item__c', 'Status__c', 'Facility__c', 'Company__c', 'Standard_Cost__c', 'Item__r.Name', 'Date_Activated__c'}); 
	    soql.setWhereClause(whereClause);
	                                     
        List<Item_Cost__c> itemCosts = Database.query(soql.getQuery());   
        system.debug('itemCosts: ' + itemCosts.size() + ' - ' + itemCosts);                   
        return itemCosts;                                      
	}
	
	public static Decimal getActiveStandardCostAmount(Id itemId, Id facilityId, Id companyId, Date activeStandardCostDate){
		return getActiveStandardCostRecords(itemId, facilityId, companyId, activeStandardCostDate).standard_cost__c;
	}
	
	public static Item_Cost__c getActiveStandardCostRecords(Id itemId, Id facilityId, Id companyId, Date activeStandardCostDate){
		Map<ItemCostDefinition, List<Item_Cost__c>> mICDs = getActiveStandardCostDefinitions(new set<Id>{itemId}, new List<Date>{activeStandardCostDate});
		ItemCostDefinition facilityICD = new ItemCostDefinition(itemId, facilityId, companyId);
		ItemCostDefinition companyICD = new ItemCostDefinition(itemId, null, companyId);
		List<Item_Cost__c> itemCosts = mICDs.get(facilityICD) != null ? mICDs.get(facilityICD) : mICDs.get(companyICD);
		if(itemCosts.size() > 0){
			return itemCosts[0];
		}else{
			return null;
		}
	}
	
	public static Map<ItemCostDefinition, List<Item_Cost__c>> getActiveStandardCostDefinitions(set<Id> itemIds, List<Date> activeStandardCostDates){
		List<Item_Cost__c> itemCosts = returnItemCosts(itemIds, activeStandardCostDates, 'Active');
		Map<ItemCostDefinition, List<Item_Cost__c>> mICDs = new Map<ItemCostDefinition, List<Item_Cost__c>>();
		for(Item_Cost__c ic : itemCosts){
			ItemCostDefinition icd = new ItemCostDefinition(ic.item__c, ic.facility__c, ic.company__c);  
			if(mICDs.containsKey(icd)){
				mICDs.get(icd).add(ic);
			}else{
				mICDs.put(icd, new List<Item_Cost__c>{ic});
			}
		}
		system.debug('returning mICDs: ' + mICDs);
		return mICDs;
	}
    

}