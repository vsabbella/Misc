public with sharing class InventoryTransactionService {
    public static final String LOGICAL_SALES_ORDER_SHIPMENT = 'Logical Sales Order Shipment' ;
    public static final String SALES_ORDER_SHIPMENT = 'Sales Order Shipment' ;
    public static final String TRANSFER_ORDER_SHIPMENT = 'Transfer Order Shipment' ;
    public static final String LOGICAL_PURCHASE_ORDER_RECEIPT = 'Logical Purchase Order Receipt' ;
    public static final String LOGICAL_RMA_RECEIPT = 'Logical RMA Receipt' ;
    public static final String LOGICAL_RMA_SCRAP = 'Logical RMA Scrap' ;
    public static final Map<String,Set<String>> netQuantity = new Map<String,Set<String>>{
        'Increase' => new Set<String>{ 'Purchase Order Receipt','Logical Purchase Order Receipt','Transfer Order Receipt',
            'Sales Order Undo Shipment','Transfer Order Undo Shipment','Work Order Assembly Completion','Work Order Assembly Scrap',
            'Work Order Return To WIP','By-product','Void - Purchase Order Return' },
        'Decrease' => new Set<String>{ 'Work Order Issue From WIP','Sales Order Shipment','Logical Sales Order Shipment',
            'Transfer Order Shipment','Work Order Assembly Uncompletion','By-product Uncompletion','Void - Transfer Order Receipt',
            'Void - Purchase Order Receipt','Purchase Order Return' }
    };
    
    
    public static void populateExtendedPrice(Set<Id> invTrxnIds,List<Inventory_Transaction__c> itList) {
    	
    	
        Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>> ();
    	Set<String> itFields = new Set<String>{'Receipt_Line__r.Quantity_Received__c','Quantity_Stocking_UOM__c','Receipt_Line__r.Purchase_Order_Line__r.Unit_Price__c', 'Receipt_Line__r.Purchase_Order_Line__r.Purchase_UOM__c','Purchase_Order_Line__r.Unit_Price__c','Receipt_Line__r.Purchase_Price__c','Item__r.Packaging_UOM__c','Item__r.Stocking_UOM__c','To_Facility__r.Facility_Identifier__c','Item__c' };

        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
        itQuery.addAllCustomFields();
        itQuery.addFields(itFields);
        itQuery.setWhereClause('Id IN :invTrxnIds');
        Map<Id,Inventory_Transaction__c> queriedITs = new Map<Id,Inventory_Transaction__c>((List<Inventory_Transaction__c>)Database.query(itQuery.getQuery()));
        
    	for(Inventory_Transaction__c invTrans:queriedITs.values()){
			if ( !itemPackagingUOMCache.containsKey (invTrans.Item__c) ) {
			    if(invTrans.Item__r !=null && invTrans.Item__r.Packaging_UOM__c !=null){
			        List<Id> lstPkgUom = (List<Id>) JSON.deserialize( invTrans.Item__r.Packaging_UOM__c, List<Id>.class );
                    itemPackagingUOMCache.put(invTrans.Item__c, lstPkgUom);
			    }
                
            }
    	}
    	
    	for (Inventory_Transaction__c it:itList) {
            Decimal cf= 1;
            Inventory_Transaction__c queriedITObj;
            if(queriedITs.containskey(it.Id)){
            	queriedITObj = queriedITs.get(it.Id);
            }
            if (queriedITObj !=null && queriedITObj.Receipt_Line__c == null) {
            	if(queriedITObj.Purchase_Order_Line__r !=null){
            		it.Extended_Price__c = queriedITObj.Purchase_Order_Line__r.Unit_Price__c * queriedITObj.Quantity__c;
            	}
            }
            else if(queriedITObj !=null && queriedITObj.Receipt_Line__c != null && queriedITObj.Receipt_Line__r.Purchase_Order_Line__r != null){
            	
            	cf = KSE.getConversionFactor(queriedITObj.item__c,queriedITObj.To_Facility__r.Facility_Identifier__c, queriedITObj.Stocking_UOM__c, queriedITObj.Receipt_Line__r.Purchase_Order_Line__r.Purchase_UOM__c, itemPackagingUOMCache.get(queriedITObj.Item__c));
            	it.Extended_Price__c = (queriedITObj.Quantity_Stocking_UOM__c * cf) * queriedITObj.Receipt_Line__r.Purchase_Order_Line__r.Unit_Price__c;
            }
        }
        
    }
    
    public static void populateCosts(List<Inventory_Transaction__c> itList) {
        Set<Id> locationIds = new Set<Id>();
        Set<Id> itemIds = new Set<Id>();
        Set<Id> facilityIds = new Set<Id>();
        Set<Id> icIds = new Set<Id>();
        List<DateTime> transdatelist = new List<DateTime>();
        Set<Id> ichangeCurrIds = new Set<Id>();
        Set<Id> companyCurrIds = new Set<Id>();
        for (Inventory_Transaction__c it:itList) {
            itemIds.add(it.Item__c);
            icIds.add(it.Inventory_Change__c);
            transdatelist.add(it.Transaction_Date__c);
            if (it.From_Location__c != null) {
                locationIds.add(it.From_Location__c);
            }
            if (it.To_Location__c != null) {
                locationIds.add(it.To_Location__c);
            }
        }
		
        SOQLUtil ichangequery = new SOQLUtil('Inventory_Change__c', true); //enforceFLS=true, running in user mode
        ichangequery.addFields(new set<string>{
            'Id','Currency__c','Company__r.Comp_Currency__c'
        });
        ichangequery.setWhereClause('Id IN :icIds');
        
        Map<Id,Inventory_Change__c> inventorymap = new Map<Id,Inventory_Change__c>((List<Inventory_Change__c>)Database.query(ichangequery.getQuery()));
		
		for(Inventory_Change__c ic:inventorymap.values()){
			if(ic.Currency__c != null && ic.Company__r.Comp_Currency__c != null && ic.Currency__c != ic.Company__r.Comp_Currency__c){
				ichangeCurrIds.add(ic.Currency__c);
				companyCurrIds.add(ic.Company__r.Comp_Currency__c);
			}
		}
		
		//Call ExchangeService to load exchange rates only if IC and Company Currency's are different.
		if(ichangeCurrIds.size() >0 && companyCurrIds.size()>0){
			ExchangeRateService.loadExchangeRates(companyCurrIds,ichangeCurrIds,transdatelist);
		}
         
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        SOQLUtil soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Facility__c'
        });
        soql.setWhereClause('Id IN :locationIds');
        Map<Id,Location__c> locations = new Map<Id,Location__c>((List<Location__c>)Database.query(soql.getQuery()));

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        soql = new SOQLUtil('Item__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id'
        });
        soql.setWhereClause('Id IN :itemIds');
        Map<Id,Item__c> items = new Map<Id,Item__c>((List<Item__c>)Database.query(soql.getQuery()));
        
        for (Location__c location:locations.values()) {
            facilityIds.add(location.Facility__c);
        }
        
        for (Inventory_Transaction__c it:itList) {
            if (it.From_Location__c != null) {
                it.From_Facility__c = locations.get(it.From_Location__c).Facility__c;
            }
            if (it.To_Location__c != null) {
                it.To_Facility__c = locations.get(it.To_Location__c).Facility__c;
            }
            
            if (it.Type__c.startsWith('Activate Proposed Costs') == false) {
                Id companyId = it.Company__c;
                
                it.From_Standard_Cost__c = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,companyId,it.From_Facility__c,System.now(),it.Item__c);
                it.To_Standard_Cost__c = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,companyId,it.To_Facility__c,System.now(),it.Item__c);
                
                Id facilityId;
                if (netQuantity.get('Increase').contains(it.Type__c) || (!netQuantity.get('Increase').contains(it.Type__c) && !netQuantity.get('Decrease').contains(it.Type__c))) {
                    facilityId = it.To_Facility__c;
                } else {
                    facilityId = it.From_Facility__c;
                }
            
                it.Standard_Cost__c = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,companyId,facilityId,System.now(),it.Item__c);
                
                if (it.Standard_Cost__c != null) {
                	
                	if(inventorymap.containskey(it.Inventory_Change__c)){
                		Inventory_Change__c ichange = inventorymap.get(it.Inventory_Change__c);
                		Id ichangeCurrency = ichange.Currency__c;
                		Id companyCurrency = ichange.Company__r.Comp_Currency__c;
                		ichangeCurrIds.add(ichangeCurrency);
                		companyCurrIds.add(companyCurrency);
                		
                		if(ichangeCurrency != companyCurrency){
                			//Call ExchangeService for conversion
                			Decimal convertedStandardCost = ExchangeRateService.convertReverseAmount(companyCurrency,ichangeCurrency,it.Transaction_Date__c, it.Standard_Cost__c);
                            convertedStandardCost = convertedStandardCost != null ? convertedStandardCost : 0;
                			
                			it.Extended_Cost__c = convertedStandardCost * it.Quantity_Stocking_UOM__c;
                			
                		}
                		else{
                			it.Extended_Cost__c = it.Standard_Cost__c * it.Quantity_Stocking_UOM__c;
                		}
                		
                	}
                    
                }
            }
        }
    }
    
public static void setLineCounts(Set<Id> headerIds) {
        
        SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c',true,true);
        itQuery.addFields(new Set<string>{ 'COUNT(Id) nRecs','Inventory_Change__c icId' });
        itQuery.setWhereClause('Inventory_Change__c IN :headerIds GROUP BY Inventory_Change__c');
        List<AggregateResult> totalLines = Database.query(itQuery.getQuery());
        
        List<sObject> recsToUpdate = new List<sObject>();
        Map<Id,Integer> lineCount = new Map<Id,Integer>();
        for (AggregateResult ar:totalLines) {
            Id icId = (Id)ar.get('icId');
            
            if (icId != null) {
                lineCount.put(icId,(Integer)ar.get('nRecs'));
            }
        }
        
        for (Id headerId:headerIds) {
            if (lineCount.containsKey(headerId)) {
                
              recsToUpdate.add(new Inventory_Change__c(Id = headerId, Total_Number_Of_Lines__c = lineCount.get(headerId)));
              
            } else {
                
               recsToUpdate.add(new Inventory_Change__c(Id = headerId, Total_Number_Of_Lines__c = 0));
              
            }
        }
        
        DML.updateAsSystem(recsToUpdate);
    }
}