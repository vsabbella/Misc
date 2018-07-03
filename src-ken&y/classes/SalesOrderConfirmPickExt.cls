public with sharing class SalesOrderConfirmPickExt {
    
    private ApexPages.StandardController con;
    private Id salesOrderId;
    public boolean disableConfirmPick {get;set;}
    public boolean disableUnallocate {get;set;}
    public SalesOrderService salesOrderService;
    private SchemaUtil util = SchemaUtil.getInstance();
    public list<String> attributesForDisplay { get; set; } { attributesForDisplay = new list<String>();}
    public map<Id,Shipment__c> shipmentMap = new map<Id, Shipment__c>(); 
    public Boolean hideSave { get; set; } { hideSave = false; }
    
    private Boolean fromVisualforce = ApexPages.currentPage() != null;
    
    // main list in memory of all lines we got from DB
    @TestVisible private list<Sales_Order_Line__c> soLineList = new list< Sales_Order_Line__c>();

    public class SOConfirmPickExtException extends Exception{
    
    }
    
    //Constructor
    public SalesOrderConfirmPickExt(ApexPages.StandardController sc){
        try{
            con = sc;
                
            Sales_Order__c conSalesOrder = (Sales_Order__c) con.getRecord();
            salesOrderId = con.getId();
            
            if(salesOrderId == null){
                throw new SOConfirmPickExtException(Label.Invalid_SO);
            }
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Customer__r.Top_Parent_Customer__r.Status__c','Ship_Complete__c','Status__c','Customer__c','Currency__c',
				'Company__c','Hold__c','Released_to_3PL__c'
			});
			soql.setWhereClause('Id = :salesOrderId');
			soql.setLimit(1);

			Sales_Order__c salesOrder = Database.query(soql.getQuery());
                                          
            if(salesOrder.Hold__c == true){
                 Apexpages.addMessage( new Apexpages.Message( 
                 ApexPages.Severity.ERROR, Label.SO_not_Picked) );
                 disableConfirmPick = true;
                 disableUnallocate = true;
            }
            else {

	            if (salesOrder.Status__c != 'Open') {
	                throw new SOConfirmPickExtException(Label.SO_not_open);
	            }
	            
	            //OTC-384
	            if (salesOrder.Customer__r.Top_Parent_Customer__r.Status__c != 'Approved') {
	                throw new SOConfirmPickExtException(Label.Top_Parent_Customer_not_status_Approved);
	            }
	            
	            //KNDY 4748            
	            if (salesOrder.Status__c == 'Open' && salesOrder.Released_to_3PL__c == true) {
	                if (fromVisualforce)
	                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.SO_released_to_3PL));
	                else
	                    throw new SOConfirmPickExtException(Label.SO_released_to_3PL); 
	                
	                hideSave = true;                   
	            }  
	            
	            //String subquery = '( Select ';
	            String skidType = skidService2.SKID_TYPE_ALLOCATED;
	            //Integer count = 0;
	            
	            
	            attributesForDisplay.addAll( SkidService2.attributesForPutaway( new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c'))));
	
	            set<String> skidFields = new set<String>{ 'Id', 'Name','Sales_Order_Line__r.Ship_From_Location__c' , 'Bin__r.Location__c', 'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c',
	                                    'Shipment_Line__r.Shipment__c','Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__c', 'Sales_Order_Line__r.Product__r.Item__r.Packaging_UOM__c',
	                                    'Sales_Order_Line__r.Name','Shipment_Line__r.Quantity_Allocated__c','Shipment_Line__r.Quantity_Picked__c','Sales_Order_Line__r.Quantity_From_Stock__c','Sales_Order_Line__r.Quantity_Ordered__c'};
	            skidFields.addAll(util.getAllCustomFieldsFromObject(null, 'Skid__c'));            
	            
	            set<String> fieldStrings = new set<string>{ 'ID','Name','Line__c','Product__r.Item__c','Product__r.Item__r.Description__c','Product__r.Item__r.Name','Product__r.Item__r.Class__c',
	                              'Quantity_Available_to_Ship__c','Quantity_Backordered__c','Company__c', 'Selling_UOM__r.Name', 'Product__r.Item__r.Packaging_UOM__c',
	                              'Quantity_From_Stock__c','Quantity_Ordered__c','Product__r.Item__r.Packaging_UOM__c',
	                              'Product__c','Product__r.Name','Quantity_Ordered__c','Quantity_Shipped__c','Quantity_to_Ship__c','Ship_From_Location__c', 'Product__r.Item__r.Stocking_UOM__r.Name',
	                              'Required_Date__c','Sales_Order__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c','Status__c','Discount_Percent__c',
	                              'Unit_Price__c','SystemModStamp','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c', 'Fulfillment_Source__c',
	                              'Sales_Order__r.Currency__c','Sales_Order__r.Company__c','Description__c','Selling_UOM__c','Sales_Order__r.Company__r.Comp_Currency__c' };
	                            
	            String whereClause =  'Sales_Order__c =:salesOrderId and Has_Exceptions__c = false and Product__r.Item__r.Non_Inventory__c = false and Fulfillment_Source__c != \'Drop Ship\' order by Line__c ASC';
        
		        soql = new SOQLUtil('Sales_Order_Line__c');
		        soql.addFields('Fulfillment_RO');
		        soql.addFields(fieldStrings);
		        soql.setWhereClause(whereClause);
		        
		        SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
			    skids.addFields(skidFields);
			    skids.addFields('ConfirmPickRO');
			    skids.setWhereClause('Type__c = :skidType');
			    
			    soql.addChildRelationship(skids);
	    		
	            list<Sales_Order_Line__c>tmp = Database.query(soql.getQuery());                   
	            
	            for(Sales_Order_Line__c sol : tmp ){                
	                if(sol.Skids__r == null || sol.Skids__r.size() == 0){
	                    // will not use this line                  
	                } else {
	                    soLineList.add( sol );
	                }
	            }
	
	            if(soLineList == null || soLineList.size() == 0){
	            	disableConfirmPick = true;
            		disableUnallocate = true;
            
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, + Label.No_available_SOL ));
	                return; //throw new SOConfirmShipExtException(Label.No_available_SOL);
	            }
            }
        }catch(Exception e){
            disableConfirmPick = true;
            disableUnallocate = true;
            ApexPages.addMessages(e);
        }
        
        if ( ApexPages.CurrentPage().getParameters().get('size') != null ) {
            pageSize = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('size'));
        }
        
        // prepare the page we will show OTC-470
        setCon = new ApexPages.StandardSetController(soLineList);                
        setCon.setPageSize(pageSize);
        first();  
        // OTC-470
    }
    
    // begin page support OTC-470
    public Integer pageSize {get; set;} { pageSize = 20; }
    public Integer noOfRecords { get{ return setCon.getResultSize();} }    
    @TestVisible
    ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new list<Sales_Order_Line__c>()); // OTC-330
	// list we will show on the VF page ( subset of full list )
    public list<Sales_Order_Line__c> solPageList {get; set; } 	{ solPageList = new list<Sales_Order_Line__c>();}
    
    void populatePageList ( list<Sales_Order_Line__c> solList ) {        
        solPageList.clear();
        for( sales_Order_Line__c sol : solList ) {
            solPageList.add( sol );
        }
    }
    
    public Boolean hasNext {  		get {  return setCon.getHasNext();  }    }
    public Boolean hasPrevious { 	get { return setCon.getHasPrevious(); }  }
    
    public Integer pageNumber { 	get {  return setCon.getPageNumber(); }  }
    
    public void first() {
        setCon.first();
        populatePageList( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void last() {
        setCon.last();
        populatePageList( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void previous() {
        setCon.previous();
        populatePageList( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void next() {
        setCon.next();
        populatePageList( (list<Sales_Order_Line__c>)setCon.getRecords() );
    }
    // end OTC-470
    
    public PageReference unallocate(){
        try{
            salesOrderService = new SalesOrderService();
            
            Set<Id> allocatedSkidIds = new Set<Id>();
            if(ApexPages.currentPage().getParameters().get('selectedIndexes') != null){
                for(String allocId : ApexPages.currentPage().getParameters().get('selectedIndexes').split(',')){
                    allocatedSkidIds.add(allocId);    
                }
            }
            else{
                throw new SOConfirmPickExtException(Label.SelectedIndexes_not_found);
            }
            
            if(allocatedSkidIds.size() != 0){
                salesOrderService.unallocateNew(allocatedSkidIds); 
            }
            else{
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Select_records ));
                 return null;
            }
        }catch(Exception e){
            ApexPages.addMessages(e);
            return null;
        }
        
        //OTC-134
        salesOrderService.updateShipmentStatus(new Set<Id>{con.getId()});
        
        PageReference reload = Page.SalesOrderConfirmPick;
        reload.setRedirect(true);
        reload.getParameters().put('id', salesOrderId);
        return reload;  // redraw the page since we did un-allocate some rows.
    }
    
    public PageReference confirmPick(){
       
        Savepoint sp = Database.setSavepoint();
        
        try{
            map<Id, SKID__c> locationSkidsPerAllocatedSkid;
            list<SKID__c> allocatedSkids = new list<SKID__c>();
            map< String, SKID__c > toSkids;
            set<Id> uniqueLocations = new set<Id>();
            map<Id, List<SKID__c>> quantitySkidsByHeader = new map<Id, list<SKID__c>>();
            map< String, SKID__c> fromToSkidMap = new map<String,SKID__c>();
                
            Set<Id> inventoryTransactionIds = new Set<Id>();
            Set<Id> shipmentIds = new Set<Id>();

            Map<Id,Shipment_Line__c> shipmentLinesToUpdate = new Map<Id,Shipment_Line__c>();
            
            for(Sales_Order_Line__c sol : soLineList){
                
                allocatedSkids.addAll( sol.SKIDs__r);
                sol.SKIDs__r[0].Shipment_Line__r.Shipment__r.Status__c = 'Staged';
                shipmentMap.put(sol.SKIDs__r[0].Shipment_Line__r.Shipment__c, sol.SKIDs__r[0].Shipment_Line__r.Shipment__r);
                shipmentIds.add(sol.SKIDs__r[0].Shipment_Line__r.Shipment__c);
            }
            
            Map<Id,Boolean> finalizedShipments = ShipmentService.checkFinalized(shipmentIds);
            map<Id,Skid__c> allocSkids = new map<Id,Skid__c>();
            
            for( SKID__c allocSkid : allocatedSkids ){
                
                allocSkids.put( allocSkid.id, allocSkid.clone(true,true) );
                allocSkid.Type__c = SkidService2.SKID_TYPE_LOCATION;
                uniqueLocations.add( allocSkid.Sales_Order_Line__r.Ship_From_Location__c );
                if( allocSkid.Location__c != allocSkid.Sales_Order_Line__r.Ship_From_Location__c ){
                    allocSkid.Bin__c = null;
                }
                else if (allocSkid.Consigned_Owner__c == null){
                    allocSkid.Quantity__c = 0;
                }
                
                allocSkid.Consigned_Owner__c = null;
                allocSkid.Purchase_Order_Line__c = null;
                
                allocSkid.Location__c = allocSkid.Sales_Order_Line__r.Ship_From_Location__c;

                if (!shipmentLinesToUpdate.containsKey(allocSkid.Shipment_Line__c)) {
                    shipmentLinesToUpdate.put(allocSkid.Shipment_Line__c,new Shipment_Line__c(Id = allocSkid.Shipment_Line__c, Quantity_Allocated__c = allocSkid.Shipment_Line__r.Quantity_Allocated__c, Quantity_Picked__c = allocSkid.Shipment_Line__r.Quantity_Picked__c));
                }
                Decimal convFactor;
                if (allocSkid.Sales_Order_Line__r.Quantity_From_Stock__c == null || allocSkid.Sales_Order_Line__r.Quantity_From_Stock__c == 0) {
                	convFactor = KSE.getConversionFactor(allocSkid.Sales_Order_Line__r);
                } else {
                	convFactor = KSE.getConversionFactorFromQuantity(allocSkid.Sales_Order_Line__r.Quantity_From_Stock__c,allocSkid.Sales_Order_Line__r.Quantity_Ordered__c);
                }	
                Shipment_Line__c shl = shipmentLinesToUpdate.get(allocSkid.Shipment_Line__c);
                shl.Quantity_Picked__c = KSE.addQuantityToField(shl.Quantity_Picked__c,allocSkid.Quantity__c);
                shl.Quantity_Allocated__c = KSE.subtractDecimals(shl.Quantity_Allocated__c,allocSkid.Quantity__c / convFactor);
            }
            
            toSkids = SkidService2.putAwayService(allocatedSkids, attributesForDisplay, uniqueLocations, 'Location', true);
            
            locationSkidsPerAllocatedSkid = SkidService2.locationSkidsForAllocatedSkids(allocSkids.values(), attributesForDisplay, 'Sales_Order_Line__r');

            Map<Id, Sales_Order_Line__c> soLineMap = new Map<Id, Sales_Order_Line__c>(soLineList);
            Map<Id,Boolean> createICs = new Map<Id,Boolean>();
            for( SKID__c allocSkid : allocatedSkids ){
                
                if( !quantitySkidsByHeader.containsKey( allocSkid.Sales_Order_Line__c ))
                    quantitySkidsByHeader.put( allocSkid.Sales_Order_Line__c, new list<SKID__c>() );
                    
                SKID__c locationSkid =  locationSkidsPerAllocatedSkid.get( allocSkid.id ).clone(true, true );   //KNDY-5173
                
                if(soLineMap.get(allocSkid.Sales_Order_Line__c).Quantity_From_Stock__c==null || soLineMap.get(allocSkid.Sales_Order_Line__c).Quantity_From_Stock__c==0)
                {   
                    soLineMap.get(allocSkid.Sales_Order_Line__c).Quantity_From_Stock__c =  (soLineMap.get(allocSkid.Sales_Order_Line__c).Quantity_Ordered__c * KSE.getConversionFactor(soLineMap.get(allocSkid.Sales_Order_Line__c))).setscale(6,System.RoundingMode.HALF_UP);
                }
                locationSkid.Quantity_Allocated__c = (allocSkids.get(allocSkid.Id).Quantity__c / KSE.getConversionFactorFromQuantity(soLineMap.get(allocSkid.Sales_Order_Line__c).Quantity_From_Stock__c,soLineMap.get(allocSkid.Sales_Order_Line__c).Quantity_Ordered__c)).setscale(6,System.RoundingMode.HALF_UP);
                
                quantitySkidsByHeader.get( allocSkid.Sales_Order_Line__c ).add( locationSkid );
                
                fromToSkidMap.put( SkidService2.generateKeyForSkid( locationSkidsPerAllocatedSkid.get( allocSkid.id ), null, null, null), toSkids.get( SkidService2.generateKeyForSkid(allocSkid, null, null, null) ));
                if (finalizedShipments != null && finalizedShipments.containsKey(allocSkid.Shipment_Line__r.Shipment__c) && finalizedShipments.get(allocSkid.Shipment_Line__r.Shipment__c))
                	createICs.put(allocSkid.Sales_Order_Line__c,false);
            }
            
            SkidService2.inventoryTransactionForPullFrom((list<sObject>)soLineList, quantitySkidsByHeader, 'Sales Order Pick', attributesForDisplay, null, 'Quantity_Allocated__c', fromToSkidMap, true, null,null,null,null,createICs);
            DML.deleteAsSystem(allocatedSkids);
            DML.updateAsUser(shipmentMap.values());
            DML.updateAsUser(shipmentLinesToUpdate.values());
            
            
           
        }catch(Exception e){
            Database.rollback(sp);
            if (fromVisualforce) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
            }
            else
                throw new SOConfirmPickExtException(e);
            return null;
        }
        
        return new PageReference('/'+salesOrderId);
    }
    
}