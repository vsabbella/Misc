/*
Simple record cache for least commonly changed and oftenly queried records during Sales order or Sales Order Line trigger flows
*/
public with sharing class SalesOrderFlowCache {
    // Cache same SOQL records here
    // Note: please dont cache anything which is changed by SalesOrderLine trigger, i.e. Sales Order
    // As they might need to be refreshed for usage
    private static Map<id, sObject> recordCache = new Map<id, sObject>();
    
    public static void flush() {        recordCache.clear();    }
    
    public static void flush(SObjectType sObjType) { 
    	for(SObject sObj : recordCache.values()){
	    	if ( sObj.getSObjectType() == sObjType){
	    		recordCache.remove(sObj.Id);
	    	}
    	}
    }
    
    private static set<id> missing( set<id> lookingFor ) {
        set<id>missing = new set<id>();
        for ( id oid : lookingFor) {
            if ( recordCache.containsKey( oid ) == false ) missing.add( oid );        		
        }
        return missing;
    }
    

    public static Sales_Order_Line__c[] cachedSalesOrderLinesForIds(Set<Id> idSet){

        set<id>missing = missing(idSet);

        if (missing.isEmpty() != true ) {
            for( Sales_Order_Line__c obj: [select Id, Item_Source__c, Ship_From_Location__r.Facility__r.Facility_Identifier__c
                                            from Sales_Order_Line__c where Id in :missing]
                                            ){
                recordCache.put( obj.id, obj );
            }
        }
        return KSE.filter( recordCache.values(), Sales_Order_Line__c.sObjectType);
    }

    public static Hierarchy__c[] cachedHierarchyForIds(Set<Id> idSet){
        
        set<id>missing = missing(idSet);

        if (missing.isEmpty() != true ) {        
            for( Hierarchy__c obj: [select Id, name, Path__c, Parent_code__c, Code__c, 
                                            (select Id, Name, Sales_hierarchy__c, Sales_Hierarchy__r.Path__c from Products__r),
                                            (select Id, Name, Hierarchy__c, Hierarchy__r.Path__c from Product_Groups__r)
                                            from Hierarchy__c where Id in :missing]
                                            ){
                recordCache.put( obj.id, obj );
            }
        }
        return KSE.filter( recordCache.values(), Hierarchy__c.sObjectType);
    }
    
    public static Pricebook__c[] cachedPricebooksForIds(Set<Id> idSet) {
        set<id>missing = missing(idSet);

        if (missing.isEmpty() != true ) {  
            System.debug(logginglevel.info, 'missing: ' + missing);      
            for( Pricebook__c obj: [SELECT Id, Currency__c, Company__c, Default__c
                                  FROM Pricebook__c
                                  WHERE Id IN :missing    ])
            {
                recordCache.put( obj.id, obj );
            } 
        }
        
        return KSE.filter( recordCache.values(), Pricebook__c.sObjectType);
    }

    public static Product__c[] cachedProductsForIds(Set<Id> idSet) {
        
        set<id>missing = missing(idSet);
        
        if (missing.isEmpty() != true ) {        
            for( Product__c obj: [SELECT Id, Item__r.Stocking_UOM__c,Item__r.Non_Inventory__c, Weight__c, Weight_UOM__c, Weight_UOM__r.Name, 
                                  Dimension_UOM__r.Name, Units_per_Pallet__c, Units_per_Layer__c, UPC_Code__c, Item__r.Packaging_UOM__c, 
                                  Pricebook_Line_Required__c, Product_Group__c, Length__c, Item__r.Source__c,
                                  Width__c, Height__c, Dimension_UOM__c, Item__r.Purchasing_UOM__r.Name, Invoiceable__c,
                                  Item__r.Non_Shippable__c
                                  FROM Product__c
                                  WHERE Id IN :missing    ])
            {
                recordCache.put( obj.id, obj );
            } 
        }
        
        return KSE.filter( recordCache.values(), Product__c.sObjectType);
    }
    
    public static Location__c[] cachedLocationsForIds(Set<Id> idSet){
        set<id>missing = missing(idSet);

        if (missing.isEmpty() != true){
            for (Location__c obj : [SELECT Id, Facility__r.Address__c, Facility__r.Enable_Transit_Route_Optimization__c,
            								Facility__r.Sales_Order_Aggregation_Required__c, Facility__r.Facility_Identifier__c,
                                            Facility__r.Shipping_Calendar__c, Facility__r.Lead_time__c
                                        FROM Location__c
                                        WHERE Id IN :missing ]){
                recordCache.put(obj.id, obj);
            }
        }

        return KSE.filter ( recordCache.values(), Location__c.sObjectType);
    }
    
    public static Customer__c[] cachedCustomersForIds(Set<Id> idSet){
        set<id>missing = missing(idSet);

        if (missing.isEmpty() != true){
            for (Customer__c obj : [SELECT Id, Outstanding_Balance2__c, Risk_Class__c, Days_Past_Due_Max__c, Top_Parent_Customer__c,
										   Credit_Hold__c, Credit_Limit__c, Open_Past_Due__c, Use_Fixed_Pricing__c
                                      FROM Customer__c
                                     WHERE Id IN :missing ]){
                recordCache.put(obj.id, obj);
            }
        }

        return KSE.filter ( recordCache.values(), Customer__c.sObjectType);
    }
    
    /*	
    *	@description : Check if the orders are already in the map
    * 				   If not, collect the ids that are not in the map and requery for them.
    * 				   and return the latest map.
    *
    *	@return : Sales Orders[]  
    */
    public static Sales_Order__c[] cachedSalesOrdersForIds(Set<Id> idSet) {
        
        set<id>missing = missing(idSet);
        
        if (missing.isEmpty() != true ) {        
            for( Sales_Order__c obj : [ SELECT Id, Pricing_Date__c, Company__c, Company__r.Comp_Currency__c, Pricebook__c, Bracket_Price_Field_In_Use__c, Date_Time_Ordered__c,
                                       Customer__r.Pricebook__c, Customer__r.Order_Quantity_Factor_At__c, Customer__r.Top_Parent_Customer__c,Recurrence_Start_Date__c,
                                       Customer__r.Make_Order_Quantity_Even_With_Factor__c, Customer__r.Use_Fixed_Pricing__c, Customer__r.Customer_Group__c,
                                       Ship_to__r.Pallet_Product__r.Weight_UOM__r.Name, Ship_To__r.Earliest_Delivery_Window__c,
                                       Ship_To__r.Latest_Delivery_Window__c, Order_Total__c,Status__c,
                                       Ship_to__r.Pallet_Product__r.Weight_UOM__c, Ship_to__r.Pallet_Product__r.Item__c, Ship_to__r.Pallet_Product__r.Item__r.Packaging_UOM__c,
                                       Ship_to__r.Pallet_Product__r.Weight__c, Type__c,Currency__c,
                                       Ship_To__r.Customer_Street__c, Ship_To__r.Customer_Street_1__c, Ship_To__r.Customer_Street_2__c,Ship_To__r.Customer_State__c, 
                                       Ship_To__r.Customer_City__c, Ship_To__r.Customer_Country__c, Ship_To__r.Customer_Zip_Code__c, Ship_To__r.Lead_time__c, Price_Determination_Date__c,
                                       Means_of_Transport__c, Delivery_Method__c
                                       FROM Sales_Order__c 
                                       WHERE Id IN :missing                  ] ) 
            {	
                recordCache.put( obj.id, obj );
            }
        }
        
        return KSE.filter( recordCache.values(), Sales_Order__c.sObjectType);
    }
    
    // this one is a bit different for no reason i can see, so seperate cache
    private static Map<id, BracketPricingService.BracketPriceRange[]> companyPriceCache = new Map<id, BracketPricingService.BracketPriceRange[]>();
    public static Map<Id, BracketPricingService.BracketPriceRange[]> cachedBracketPriceRanges(Set<Id> inputIds) {
        set<id>missing = new set<id>();
        for ( id oid : inputIds) {
            if ( companyPriceCache.containsKey( oid ) == false ) missing.add( oid );        		
        }       
        if (missing.isEmpty() != true ) { 
	   		companyPriceCache.putAll(BracketPricingService.loadBracketPricesWithRange( missing )); 
        }
        return companyPriceCache;
    }
    
}