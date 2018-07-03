/**
 * @description controller class for SKID operations
 */
global with sharing class SKIDService { 

    public static final String SKID_TYPE_LOCATION = 'Location' ;
    public static final String SKID_TYPE_PO_SUPPLY = 'PO Supply' ;
    public static final String SKID_TYPE_SO_DEMAND = 'SO Demand' ;
    public static final String SKID_TYPE_WO_SUPPLY = 'WO Supply' ;
    public static final String SKID_TYPE_ALLOCATED = 'Allocated' ;
    public static final String SKID_TYPE_HISTORY = 'History';
    public static final String SKID_TYPE_IN_TRANSIT = 'In Transit' ;
     
    
    
    // Custom Exception for Stockpoint Service Class
    public class SKIDServiceException extends Exception{

    }
    
        
    
        
    
    /*********************** OLD CODE *************************/
    /**
     * @description delete skids with a single query and single dml statement
     */
    public static void deleteSkids(Map<Id, sObject> oldMap,String skidType){
        
        List<SKID__c> deleteSKIDList = new List<SKID__c>(); 
        // on deletion of sales order lines, delete the related skids
        if (oldMap.getSObjectType()==Sales_Order_Line__c.sObjectType) {            
            for(SKID__c SKIDObj:[select Id from SKID__c where  Type__c =:skidType and 
                                 Sales_Order_Line__c in:oldMap.keyset()]){ //KNDY-1874 Using the oldMap passed in rather than the Trigger.oldMap which was wrong              
                deleteSKIDList.add(SKIDObj);
            }
        }
        else if (oldMap.getSObjectType()== Work_Order__c.sObjectType) {            
            for(SKID__c SKIDObj:[select Id from SKID__c where  Type__c =:skidType and 
                                 Work_Order__c in:oldMap.keyset()]){  //KNDY-1874 Using the oldMap passed in rather than the Trigger.oldMap which was wrong             
                deleteSKIDList.add(SKIDObj);
            }
        }
        else if (oldMap.getSObjectType()== Purchase_Order_Line__c.sObjectType) {            
            for(SKID__c SKIDObj:[select Id from SKID__c where  Type__c =:skidType and 
                                 Purchase_Order_Line__c in:oldMap.keyset()]){      //KNDY-1874 Using the oldMap passed in rather than the Trigger.oldMap which was wrong          
                deleteSKIDList.add(SKIDObj);
            }
        }

        DML.deleteAsSystem(deleteSKIDList); //PTP-187 Deleting SKIDs for a non Admin user
    }
    
     /**
     * @description update Skids , called from trigger , operates on purchase order, sales order , work order
     */  
    public static void updateSkids(Map<Id, sObject> oldMap,Map<Id, sObject> newMap,String skidType,Map<Id,Id> assemblyItemMap){
        
        List<SKID__c> updateSKIDList = new List<SKID__c>();
        
        map<Id,Sales_Order_Line__c> soLineMap=new map<Id,Sales_Order_Line__c>();
        map<Id,Work_Order__c> woMap=new map<Id,Work_Order__c>();
        map<Id,Purchase_Order_Line__c> poMap=new map<Id,Purchase_Order_Line__c>();
        
        for(sObject obj:newmap.values()){
            
            if(obj.getSObjectType()==Sales_Order_Line__c.sObjectType){
                Sales_Order_Line__c soLineObj=(Sales_Order_Line__c)obj;
                if(KSE.isFieldChanging('Product__c', soLineObj, oldMap)||
                		KSE.isFieldChanging('Selling_UOM__c', soLineObj, oldMap)||
                        KSE.isFieldChanging('Ship_From_Location__c', soLineObj, oldMap)||
                        KSE.isFieldChanging('Quantity_Shipped__c', soLineObj, oldMap)||
                        KSE.isFieldChanging('Quantity_Backordered__c', soLineObj, oldMap)||
                        KSE.isFieldChanging('Required_Date__c', soLineObj, oldMap)){
                  soLineMap.put(soLineObj.Id,soLineObj);             
                }
            
            }
            
            else if(obj.getSObjectType()==Work_Order__c.sObjectType){
                  Work_Order__c woObj=(Work_Order__c)obj;
                    woMap.put(woObj.Id,woObj);
                  }
            
            else if( obj.getSObjectType() == Purchase_Order_Line__c.sObjectType ) {
                  Purchase_Order_Line__c pobj = (Purchase_Order_Line__c)obj;
                  if(   KSE.isFieldChanging('Item__c', pobj, oldMap) ||
                        KSE.isFieldChanging('Quantity_Still_Due__c', pobj, oldMap) || 
                        KSE.isFieldChanging('Need_date__c', pobj, oldMap) ||
                        KSE.isFieldChanging('Purchase_UOM__c', pobj, oldMap) || 
                        KSE.isFieldChanging('Delivery_Location__c', pobj, oldMap) ) {
                    poMap.put(pobj.id,pobj);
                  }     
            }
        
        }
        
        /* maps are ready, now run the queries */
        map<id,Skid__c> skidMap = new map<id,Skid__c>(); 
        
        if(newMap.getSObjectType()==Purchase_Order_Line__c.sObjectType&&poMap.size()>0){
            //update skids related to the purchase order lines
            
            List< Purchase_Order_Line__c > poLines = new List< Purchase_Order_Line__c >();
            
            if( skidType == SKID_TYPE_PO_SUPPLY ){
            	poLines = [select Id, Purchase_UOM__c, Purchase_UOM__r.Name, Item__r.Packaging_UOM__c,
            									Item__r.Stocking_UOM__c, Item__r.Stocking_UOM__r.Name
                                              from Purchase_Order_Line__c where Id in :poMap.keyset() ];
            	 	for( Skid__c s : [select Id, Location__c, Quantity__c,Order_date__c, Purchase_Order_Line__c
                                                         from SKID__c 
                                                         where  (Type__c=:SKID_TYPE_PO_SUPPLY or Type__c=:SKID_TYPE_IN_TRANSIT) 
                                                         AND Purchase_Order_Line__c in :poMap.keyset()  FOR UPDATE ] ) {
	             	skidMap.put( s.purchase_Order_line__c , s);	
	             }
            }
            else{
            	poLines = [select Id, Purchase_UOM__c, Purchase_UOM__r.Name, Item__r.Packaging_UOM__c,
            									Item__r.Stocking_UOM__c, Item__r.Stocking_UOM__r.Name, Delivery_Facility__r.Facility_Identifier__c
                                              from Purchase_Order_Line__c where Id in :poMap.keyset() ];	
                   for( Skid__c s : [select Id, Purchase_Order_Line__c, Location__c, Quantity__c,Order_date__c
                                                         from SKID__c 
                                                         where  Type__c=:skidType 
                                                         AND Purchase_Order_Line__c in :poMap.keyset() FOR UPDATE ] ) {
	             	skidMap.put( s.purchase_Order_line__c , s);	
	             }
            }
            decimal quantityToStock;
           	for(Purchase_Order_Line__c pol : poLines ) {
                                    
                //update skid only if Item or quantity shipped on the order line changes
                if( skidMap.containsKey( pol.id ) ){
                        SKID__c SKIDObj = skidMap.get( pol.id );
                        SKIDObj.Item__c = poMap.get(pol.Id).Item__c;
                        SKIDObj.Location__c = poMap.get(pol.Id).Delivery_Location__c;
                        
                        if(poMap.get(pol.Id).Quantity_To_Stock__c==null)
			            {   
			                quantityToStock = (decimal)poMap.get(pol.Id).Order_Quantity__c * KSE.getConversionFactor(pol);
			            }
			            else{
			                quantityToStock = poMap.get(pol.Id).Quantity_To_Stock__c;
			            }
			            	
                        SKIDObj.Quantity__c = (poMap.get(pol.Id).Quantity_Still_Due__c * KSE.getConversionFactorFromQuantity(quantityToStock,poMap.get(pol.Id).Order_Quantity__c)).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(pol);
                        SKIDObj.Order_Date__c = poMap.get(pol.Id).Need_Date__c;
                        
                        updateSKIDList.add(SKIDObj);
                }
            }
        }
        
        //for work orders
        else if(newMap.getSObjectType()==Work_Order__c.sObjectType&&woMap.size()>0){
            
            List<Work_Order__c> woList = new List<Work_Order__c>(); 
            Map<id, list<skid__c>> skidMapList = new map<id, list<skid__c>>(); 
            
            woList = [select Id, Start_Date2__c,Item__c,Item__r.Packaging_UOM__c,Facility__r.Facility_Identifier__c,Packaging_UOM__c,Item__r.Stocking_UOM__c from Work_Order__c where Id in:woMap.keyset()];
             
             for( Skid__c s : [select Id, Work_Order__c, quantity__c, quantity_issued__c, quantity_required__c, quantity_scrapped__c,
                                       quantity_short__c
                                                         from SKID__c 
                                                         where  Type__c=:skidType 
                                                         AND Work_Order__c in :woMap.keyset() FOR UPDATE ] ) {
	             	if ( ! skidMapList.containsKey( s.work_order__c ) )  
	             		skidMapList.put( s.Work_Order__c,  new List<Skid__c>() );
	             		
	             	skidMapList.get( s.Work_Order__c ).add(s);	
	             }
	             
            for(Work_Order__c woObj: woList ) {
                //update skid only if item specification or quantity has changed
                if( skidMapList.containsKey( woObj.Id ) ){
                    Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<ID>> ();
                    if ( !itemPackagingUomCache.containsKey(woObj.Item__c) ) {
                        List<Id> lstPkgUom = (List<Id>) JSON.deserialize(woObj.Item__r.Packaging_UOM__c, List<Id>.class);
                        itemPackagingUomCache.put(woObj.Item__c, lstPkgUom );
                    }
                    Decimal assemblyConversionFactor = 1;
                    assemblyConversionFactor = KSE.getConversionFactor ( woObj.Item__c, woObj.Facility__r.Facility_Identifier__c, woObj.Packaging_UOM__c, woObj.Item__r.Stocking_UOM__c, itemPackagingUomCache.get(woObj.Item__c) );
            
                   
                   if ( skidType == 'WO Supply' ) { 

                        SKID__c SKIDObj =skidMapList.get( woObj.id )[0]; // there is only one supply skid
                        SKIDObj.Packaging_UOM__c = woMap.get(woObj.Id).Packaging_UOM__c;

                        SKIDObj.Quantity__c = woMap.get(woObj.Id).Quantity_to_Complete__c;
                        SKIDObj.Quantity_Stocking_UOM__c = woMap.get(woObj.Id).Quantity_to_Complete__c * assemblyConversionFactor;

                        SKIDObj.Location__c = woMap.get(woObj.Id).Complete_to_Location__c;
                        if(assemblyItemMap.get(woMap.get(woObj.Id).Assembly_Item_Specification__c)!=null)
                            SKIDObj.item__c=assemblyItemMap.get(woMap.get(woObj.Id).Assembly_Item_Specification__c);
                        if( woMap.get(woObj.Id).Need_date2__c != null ){
                            SKIDObj.Order_Date__c=woMap.get(woObj.Id).Need_date2__c.date();
                        }
                        updateSKIDList.add(SKIDObj);
                        
                   }
                }
            }
        }
        
        // PTM-522 avoid locking the company record when updating skids
        //for ( Skid__c s : updateSKIDList ) { s.Company__c  = null ; }          
        DML.updateAsSystem(updateSKIDList);    
    }
    
    /** 
     * @description main method for building skids, takes a list of sobjects which 
     * can be related to the skids we are creating , salesorders, purchase orders, etc..
     *
     */
    public static void insertSkids(Map<Id, sObject> newMap,String skidType,Map<Id,Id> assemblyItemMap){
        
        List<SKID__c> newSKIDList = new List<SKID__c>();
        //system.debug( LoggingLevel.INFO, ' insert skids new map ' + newMap);
        
        // skid needs line needs product, but for that we need to query the produt table
        // the map only has one kind of sobject, find that
        set<id> prodSet = new Set<id>(); 
        for(sObject obj:newMap.values()) {
            if(obj.getSObjectType()==Sales_Order_Line__c.sObjectType){
                Sales_Order_Line__c soLineObj=(Sales_Order_Line__c)obj;
                prodSet.add(soLineObj.Product__c);  
            }
        }
        
        Map<Id, Purchase_Order_Line__c> purchaseOrderLineMap; 
        if(newMap.getSObjectType() == Purchase_Order_Line__c.sObjectType){
        	purchaseOrderLineMap = new Map<Id, Purchase_Order_Line__c>([select Id, Purchase_UOM__c, Purchase_UOM__r.Name,Packaging_UOM__c,Packaging_UOM__r.Name, Item__r.Packaging_UOM__c,
        												Item__r.Stocking_UOM__c, Item__r.Stocking_UOM__r.Name,Quantity_To_Stock__c,Order_Quantity__c,Quantity_Still_Due__c,Delivery_Location__r.Facility__c,
        												Delivery_Facility__r.Facility_Identifier__c
        												from Purchase_Order_Line__c where Id IN :newMap.values()
        												AND Sales_Order_Line__r.Fulfillment_Source__c != 'Drop Ship']);
        }
        
        Map<Id, Sales_Order_Line__c> salesOrderLineMap; 
        if(newMap.getSObjectType() == Sales_Order_Line__c.sObjectType){
        	salesOrderLineMap = new Map<Id, Sales_Order_Line__c>([select Id, Selling_UOM__c, Selling_UOM__r.Name, Sales_Order__r.Status__c,
        												Product__r.Item__r.Stocking_UOM__c,Product__r.Item__r.Packaging_UOM__c, Product__r.Item__r.Stocking_UOM__r.Name,
        												Ship_From_Location__r.Facility__r.Facility_Identifier__c
        												from Sales_Order_Line__c where Id IN :newMap.values()]);
        }
        
        Map<Id, Work_Order__c> woMap; 
        if (newMap.getSObjectType() == Work_Order__c.sObjectType ) {
            woMap = new Map<Id, Work_Order__c> ([SELECT id, Item__c, Item__r.Stocking_UOM__c, Facility__r.Facility_Identifier__c,Packaging_UOM__c, Item__r.Packaging_UOM__c, Assembly_Item_Specification__r.Item__r.Packaging_UOM__c FROM Work_Order__c WHERE Id in : newMap.values()]);            
        }
        
        
        Map<id,Product__c> prodMap = new Map<id,Product__c>(); 
        if ( prodSet.size() > 0 ) 
            prodMap = new Map<id,Product__c>([ select Id, Item__c, Item__r.Packaging_UOM__c  from Product__c where id in :prodSet ]);
        
        Map<Id, List<Id>> itemPackagingUomCache = new Map<Id, List<Id>>();
        for(sObject obj:newMap.values()) {
            
            // allocate a new object, fill in a few common fields 
            SKID__c SKIDObj = new SKID__c();
            SKIDObj.Company__c = (Id)obj.get('Company__c'); 
            SKIDObj.Type__c = skidType;
              
            // new purchase order lines, need skids
            if(obj.getSObjectType()==Purchase_Order_Line__c.sObjectType){
                
                Purchase_Order_Line__c POL = (Purchase_Order_Line__c)obj;
                //system.debug( LoggingLevel.INFO, 'POL line is ' + POL);
                if ( purchaseOrderLineMap.containsKey(POL.Id) && POL.Quantity_Still_Due__c > 0 && POL.Status__c == 'Open' ) {
                    SKIDObj.Item__c = POL.Item__c;
                    SKIDObj.Quantity__c = (purchaseOrderLineMap.get(POL.Id).Quantity_Still_Due__c * KSE.getConversionFactor(purchaseOrderLineMap.get(POL.Id))).setscale(6,System.RoundingMode.HALF_UP);
                    SKIDObj.Quantity_Stocking_UOM__c = SKIDObj.Quantity__c;
                    SKIDObj.Purchase_Order_Line__c = POL.Id;
                    SKIDObj.Order_Date__c = POL.Need_Date__c;
                    SKIDObj.Location__c = POL.Delivery_Location__c;
                    SKIDObj.Facility2__c = purchaseOrderLineMap.get(POL.Id).Delivery_Facility__c;
                    SKIDObj.Facility2__r = purchaseOrderLineMap.get(POL.Id).Delivery_Facility__r;
                    SKIDObj.Stocking_UOM__c = purchaseOrderLineMap.get(POL.Id).Item__r.Stocking_UOM__c;
                    SKIDObj.Packaging_UOM__c = purchaseOrderLineMap.get(POL.Id).Item__r.Stocking_UOM__c;
                    newSKIDList.add(SKIDObj);
                }
            }
            
            //for new sales order line
            if(obj.getSObjectType()==Sales_Order_Line__c.sObjectType) {
                        
                Sales_Order_Line__c soLineObj=(Sales_Order_Line__c)obj;
                //create skids for every sales order line 
                // NOTE we must fetch the product__r.item ??? 
                //system.assert( soLineObj.Product__r != null );  
                if(salesOrderLineMap.get(soLineObj.Id).Sales_Order__r.Status__c == 'Open'){
	                SKIDObj.Item__c = prodMap.get(soLineObj.Product__c).Item__c;
	                SKIDObj.Sales_Order_Line__c = soLineObj.ID;
	                SKIDObj.Quantity__c = (KSE.addQuantityToField(soLineObj.Quantity_Backordered__c,0) * KSE.getConversionFactor(salesOrderLineMap.get(soLineObj.Id))).setscale(6,System.RoundingMode.HALF_UP);
	                SKIDObj.Quantity_Stocking_UOM__c = SKIDObj.Quantity__c;
	                SKIDObj.Order_Date__c=soLineObj.Required_Date__c;
	                SKIDObj.Location__c =soLineObj.Ship_From_Location__c;
	                SKIDObj.Stocking_UOM__c = prodMap.get(soLineObj.Product__c).Item__r.Stocking_UOM__c;
	                SKIDObj.Packaging_UOM__c = prodMap.get(soLineObj.Product__c).Item__r.Stocking_UOM__c;
	                newSKIDList.add(SKIDObj);
                }
            }
            
            if (obj.getSObjectType() == Work_Order__c.sObjectType) {
                Work_Order__c woObj = (Work_Order__c)obj;
                
                if (woObj.Item__c != null) {
                    SKIDObj.Item__c = woObj.Item__c;
                } else if (assemblyItemMap.get(woObj.Assembly_Item_Specification__c) != null) {
                    SKIDObj.Item__c = assemblyItemMap.get(woObj.Assembly_Item_Specification__c);
                }
                
                if ( !itemPackagingUomCache.containsKey (SKIDObj.Item__c) ) {//Assembly_Item_Specification__r.
                    List<Id> lstPkgUom = new List<Id>();
                    if(woMap.get(woObj.Id).Item__c != null){
                        lstPkgUom = (List<Id>) JSON.deserialize(woMap.get(woObj.Id).Item__r.Packaging_UOM__c, List<Id>.class); 
                    }else {
                       lstPkgUom = (List<Id>) JSON.deserialize(woMap.get(woObj.Id).Assembly_Item_Specification__r.Item__r.Packaging_UOM__c, List<Id>.class); 
                    }
                    
                    itemPackagingUomCache.put( SKIDObj.Item__c, lstPkgUom );
                }
                
                SKIDObj.Packaging_UOM__c = woObj.Packaging_UOM__c;
                SKIDObj.Stocking_UOM__c = woMap.get(woObj.Id).Item__r.Stocking_UOM__c;
                SKIDObj.Facility2__c = woMap.get(woObj.Id).Facility__c;
                SKIDObj.Facility2__r = woMap.get(woObj.Id).Facility__r;
                SKIDObj.Work_Order__c = woObj.ID;
                
                if (woObj.Quantity_to_Complete__c != null) {
                    SKIDObj.Quantity__c = woObj.Quantity_to_Complete__c;
                } else {
                    SKIDObj.Quantity__c = woObj.Order_Quantity__c;
                }
                Decimal cf = KSE.getConversionFactor(SKIDObj.Item__c, SKIDObj.Facility2__r.Facility_Identifier__c, SKIDObj.Packaging_UOM__c, SKIDObj.Stocking_UOM__c, itemPackagingUomCache.get(SKIDObj.Item__c));
                SKIDObj.Quantity_Stocking_UOM__c = SKIDObj.Quantity__c * cf;
                
                if (woObj.Need_Date2__c != null) {
                    SKIDObj.Order_Date__c = woObj.Need_Date2__c.date();
                }
                
                SKIDObj.Location__c = woObj.Complete_to_Location__c;
                newSKIDList.add(SKIDObj);
            }
        }
        
        DML.insertAsSystem(newSKIDList);
    }
}