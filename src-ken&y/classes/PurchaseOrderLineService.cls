public with sharing class PurchaseOrderLineService {

    class PurchaseOrderLineException extends Exception{
        
    }

    // TODO Create a generic flow cache
    private static Map<id, Facility__c> facilityCache = new Map<id, Facility__c>();

    public static Map<Id, Facility__c> cachedFacilities (Set<Id> facilitySet) {
        if ( facilitySet != null && !facilitySet.isEmpty() ) {
            if ( !facilityCache.keySet().containsAll (facilitySet)) {
                SOQLUtil facilityQuery = new SOQLUtil('Facility__c');
                facilityQuery.addField('Id');
                facilityQuery.addField('Facility_Identifier__c');
                facilityQuery.setWhereClause('Id = :facilitySet');
                facilityCache = new Map<Id, Facility__c>((List<Facility__c>) Database.Query(facilityQuery.getQuery()));
            }
        }
        return facilityCache;
    }
    
    public static Map<id,Item__c> setUOM(Map<Id,Item__c> items, Map<id,Item__c> itemsForUpdate) {
        
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){

            List<Purchase_Order_Line__c> polines = new List<Purchase_Order_Line__c>();
            
            for(Purchase_Order_Line__c pol: (List<Purchase_Order_Line__c>) ProcessHandler.getUnprocessedRecords(trigger.new)) {
                
                if( trigger.isInsert || 
                    (trigger.isUpdate &&
                        (KSE.isFieldChanging('item__c', pol, trigger.oldMap) || KSE.isFieldChanging('Purchase_UOM__c', pol, trigger.oldMap) ||
                         KSE.isFieldChanging('Order_Quantity__c', pol, trigger.oldMap)
                        )
                    )
                ){
                    polines.add(pol);
                }
            }
            //system.debug(logginglevel.info,'POLINES' + polines);
            if(!polines.isEmpty()){
                return PurchaseOrderLineService.setWeightUOM( polines,items,itemsForUpdate );
            }
            
        }
        return itemsForUpdate;
        
    }
    
    
    public static Map<Id,Item__c> setWeightUOM(List<Purchase_Order_Line__c> poLines, Map<Id,Item__c> items, Map<id,Item__c> itemsForUpdate)
    {
    	// Updates the Weight of the Item only if the Item Is changed  KNDY-614
        Set<ID> ItemSet = new Set<ID>();
        
        //system.debug(logginglevel.info,'INSIDE SETWEIGHT' + polines);
        
        Map<Id, List<Id>> mapItemPackagingUOM = new Map<Id, List<Id>> ();
        for(Purchase_Order_Line__c POL: poLines){
            Purchase_Order_Line__c oldPOL;
            if(trigger.isUpdate){
            	oldPOL = (Purchase_Order_Line__c)Trigger.oldMap.get(POL.ID);
            }
            if (( POL.Item__c != null && items.containsKey( POL.item__c ) && POL.Status__c != 'Closed')|| (trigger.isUpdate && POL.Item__c != oldPOL.Item__c)) {
                Item__c item = items.get(POL.Item__c);
                
                if ( !mapItemPackagingUOM.containsKey (item.id) ) {
                    List<Id> lstPkgUom = (List<Id>) JSON.deserialize( item.Packaging_UOM__c, List<Id>.class );
                    mapItemPackagingUOM.put(item.id, lstPkgUom);
                }
                
                POL.Weight__c = item.Weight__c;
                POL.Weight_UOM__c = item.Weight_UOM__c;
                POL.Quantity_To_Stock__c = (POL.Order_Quantity__c * KSE.getConversionFactor(item.id,POL.Delivery_Facility__r.Facility_Identifier__c, POL.Purchase_UOM__c, Item.Stocking_UOM__c, mapItemPackagingUOM.get(item.id))).setscale(6,System.RoundingMode.HALF_UP);
                //system.debug(logginglevel.info,'POL.Quantity_To_Stock__c' + POL.Quantity_To_Stock__c);
                //system.debug(logginglevel.info,'POL.Purchase_UOM__c + Item.Stocking_UOM__c' + POL.Purchase_UOM__c + Item.Stocking_UOM__c);
        
                itemsForUpdate.put( item.id, item );
            }
        }
        return itemsForUpdate;
    }
    public static void dropshipPOLDeleteValidation(){
    	List<Purchase_Order_Line__c> dropshipPOLs = new List<Purchase_Order_Line__c>();
    	for(Purchase_Order_Line__c pol : (List<Purchase_Order_Line__c>)trigger.old){
    		system.debug(logginglevel.error, 'List<Purchase_Order_Line__c>)trigger.old' +(List<Purchase_Order_Line__c>)trigger.old);
    		if(pol.Sales_Order_Line__c != null){
    			dropshipPOLs.add(pol);
    			system.debug(logginglevel.error, 'dropshipPOLs'+ dropshipPOLs);
    		}
    	}
    	if(dropshipPOLs.size()>0){
    		system.debug(logginglevel.error, 'in if loop');
    		for(Purchase_Order_Line__c validPOLs : dropshipPOLs){
    			system.debug('in for loop' + validPOLs);
    			validPOLs.addError('Drop Ship Purchase Order Line cannot be deleted.');
    		}	
    	}	
    }
    public static void approvedPOLDeleteValidation(){
    	for(Purchase_Order_Line__c pol : (List<Purchase_Order_Line__c>)trigger.old){
    		if(pol.Approved__c ){
    			pol.addError('Approved Purchase Order lines cannot be deleted.');
    		}
    	}
    }
    
    // KNDY-10604 This method is called from a trigger.isBefore context
    public static void defaultPurchaseUOMFromItem (List<Purchase_Order_Line__c> recordsNew, Map<Id,Item__c> itemsMap){
        if (itemsMap.size() == 0) return;
        for (Purchase_Order_Line__c line : recordsNew){
            if (line.Item__c != null && line.Purchase_UOM__c == null && itemsMap.containsKey(line.Item__c)){
                String src = itemsMap.get(line.Item__c).Source__c;
                if (ContractService.itemsSourceRequiringUOM.contains(src)){
                    if( itemsMap.get(line.Item__c).Purchasing_UOM__c == null){
                        line.addError(Label.Purchase_UOM_is_required_Cannot_default_from_item_as_there_is_no_purchasing_uom + 'Purchase Order Line ' + line.Line__c);
                    }
                    else{// Default from Item
                        line.Purchase_UOM__c = itemsMap.get(line.Item__c).Purchasing_UOM__c;
                    }
                }
                
            }
            
        }
    }
    public static void defaultsFromSupplier(){ 
    	set<Id> supIds = new set<Id>();
    	for(Purchase_Order_Line__c pol : (List<Purchase_Order_Line__c>)trigger.new){
    		if((pol.Invoice_Matching__c == null || pol.Overage_Percentage__c == null) && pol.Contract_Line__c == null && pol.Supplier__c != null && pol.Approved__c == false && pol.Sales_Order_Line__c == null){
    			supIds.add(pol.Supplier__c);
    		}
    	}
    	if(supIds.size() > 0){
    	    SOQLUtil supSoql = new SOQLUtil ( 'Supplier__c' );
    	    Set<String> supFields = new Set<String> {
    	                              'ID', 'Name', 'Invoice_Matching__c', 'Default_Receiving_Tolerance__c'
    	                       };
    	    supSoql.addFields( supFields);
    	    supSoql.setWhereClause ( 'ID IN: supIds');
    	    //Map<Id,Supplier__c> supplierMap = new Map<Id,Supplier__c>([SELECT Id, name, Invoice_Matching__c FROM Supplier__c WHERE Id IN : supIds]);
    	    Map<Id,Supplier__c> supplierMap = new Map<Id, Supplier__c>( (List<Supplier__c>) Database.query (supSoql.getQuery() ) );
    	
    	
    	    if(supplierMap.values().size() > 0){
    		    for(Purchase_Order_Line__c pol : (List<Purchase_Order_Line__c>)trigger.new){
    		    	if(pol.Invoice_Matching__c == null){
    			    	pol.Invoice_Matching__c = supplierMap.get(pol.Supplier__c).Invoice_Matching__c;
    		    	}
    		    	if(pol.Overage_Percentage__c == null){
    		    		pol.Overage_Percentage__c = supplierMap.get(pol.Supplier__c).Default_Receiving_Tolerance__c;
    		    	}
    		
    		    }	
        	}
        }	
    	
    }
}