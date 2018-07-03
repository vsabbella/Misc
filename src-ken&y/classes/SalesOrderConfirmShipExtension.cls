public with sharing class SalesOrderConfirmShipExtension {

    private ApexPages.StandardController con;
    private Id salesOrderId;
    private SchemaUtil util = SchemaUtil.getInstance();
    private Boolean fromVisualforce = ApexPages.currentPage() != null;
    public Sales_order__c salesOrder;
    public Shipment__c shipment {get; set;}
    public SalesOrderService soService;
    public Boolean disableConfirmShip {get;set;}
    public Boolean hideSave { get; set; } { hideSave = false; }
    public List<String> attributesForDisplay { get; set; } { attributesForDisplay = new List<String>();}
    public string returnUrl{get;set;}

    Map<Id, List<SKID__c>> quantitySkidsByHeader = new Map<Id, List<SKID__c>>();
    Map<Id, Shipment_Line__c> solshlMap = new Map<Id, Shipment_Line__c>();
    Map<Id, Shipment__c> shipmentMap = new Map<Id, Shipment__c>();
    Set<Id> uniqueToLocations = new Set<Id>();
    List<Skid__c> existingSkidList = new List<Skid__c>();
    
    // main list in memory of all lines we got from DB
    @TestVisible private List<Sales_Order_Line__c> soLineList = new List<Sales_Order_Line__c>();
    
    public class SOConfirmShipExtException extends Exception {}
    
    public SalesOrderConfirmShipExtension (ApexPages.StandardController sc){ 
        
        try{
            con = sc;
            salesOrderId = con.getId();           
			
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Customer__r.Top_Parent_Customer__r.Status__c','Ship_Complete__c','Status__c','Price_Determination_Date__c','Customer__c',
				'Currency__c','Company__c','Ship_to__c','Purchase_Order__c','Hold__c','Pricing_Date__c','Released_to_3PL__c'
			});
			soql.setWhereClause('Id = :salesOrderId');
			soql.setLimit(1);

			salesOrder = Database.query(soql.getQuery());

            if (salesOrder.Hold__c == true){
                disableConfirmShip = true;
                throw new SOConfirmShipExtException(Label.SO_not_packed);
            } else {                       
                if (salesOrder.Status__c != 'Open') 
                    throw new SOConfirmShipExtException(Label.SO_not_open);
                if (salesOrder.Customer__r.Top_Parent_Customer__r.Status__c != 'Approved') 
                   throw new SOConfirmShipExtException(Label.Top_Parent_Customer_not_status_Approved);
                
                //KNDY 4748            
                if (salesOrder.Status__c == 'Open' && salesOrder.Released_to_3PL__c == true) {
                    if (fromVisualforce)
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.SO_released_to_3PL));
                    else
                        throw new SOConfirmShipExtException(Label.SO_released_to_3PL); 
                                        
                    hideSave = true;                   
                }  
              
                //OTC-260 - Don't allow shipping when there are outstanding allocation SKIDs
                
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				String SKID_TYPE_ALLOCATED = SkidService2.SKID_TYPE_ALLOCATED;
				
				soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Sales_Order_Line__r.Name'
				});
				soql.setWhereClause('Type__c = :SKID_TYPE_ALLOCATED AND Sales_Order_Line__r.Sales_order__c = :salesOrderId');

				List<SKID__c> allocationSkids = Database.query(soql.getQuery());

                if (allocationSkids.size() > 0){
                    String solNames;
                    for (SKID__c sk : allocationSkids){
                        if (solNames != null){
                            solNames += sk.Sales_Order_Line__r.Name + ', ';
                        } else {
                            solNames = sk.Sales_Order_Line__r.Name + ', ';
                        }
                    }
                    solNames = solNames.substring(0, solNames.length()-2);
                    throw new SOConfirmShipExtException(Label.Please_pick_or_undo_allocate_the_following_sales_order_lines + ' ' + solNames);
                }
    
                String skidType = skidService2.SKID_TYPE_ALLOCATED;
                attributesForDisplay.addAll(SkidService2.attributesForPutaway(new List<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c'))));
                
                Set<String> itFields = new Set<String>{ 'Id', 'Name', 'Item__c', 'Item__r.Stocking_UOM__c', 'From_Location__c', 'From_Skid__c', 'From_Skid__r.Lot__c', 
                        'From_SKID__r.Bin__c', 'From_SKID__r.Bin__r.Name', 'From_Skid__r.Expiration_Date__c', 'From_Skid__r.Shipment_Line__c', 'To_Location__c', 'From_Skid__r.Item__r.Stocking_UOM__c',
                        'Quantity__c', 'Standard_Cost__c', 'Shipment_Line__r.Quantity_Shipped__c', 'Shipment_Line__r.Shipment__c', 'Shipment_Line__r.Extended_Price__c', 
                        'Shipment_Line__r.Shipment__r.Finalized__c', 'Shipment_Line__r.Shipment__r.Status__c', 'To_Skid__c','To_Skid__r.Id','To_Skid__r.Type__c','To_Skid__r.Lot__c',
                        'To_Skid__r.Expiration_Date__c', 'To_Skid__r.Item__c', 'To_Skid__r.Quantity__c', 'To_Skid__r.Sales_Order_line__c', 'To_Skid__r.Location__c', 'To_Skid__r.Packaging_UOM__c', 'To_Skid__r.Item__r.Packaging_UOM__c',
                        'Shipment_Line__r.Shipment__r.Date_Shipped__c','Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Name', 'To_Skid__r.Stocking_UOM__c', 'To_Skid__r.Item__r.Stocking_UOM__c'};
                        
                itFields.addAll(util.getAllCustomFieldsFromObject(null, 'Inventory_Transaction__c'));
                itFields.addAll(util.getAllCustomFieldsFromObject('To_Skid__r.', 'Skid__c'));
                
                String loc = SKIDService2.SKID_TYPE_LOCATION;
                
                Set<String> fieldStrings = new Set<String>{ 'ID','Name','Line__c','Product__r.Item__c','Product__r.Item__r.Description__c','Product__r.Item__r.Name','Product__r.Item__r.Class__c',
                                  'Product__r.Product_Group__c', 'Quantity_Available_to_Ship__c','Quantity_Backordered__c','Company__c', 'Selling_UOM__r.Name','Product__r.Item__r.Stocking_UOM__r.Name',
                                  'Quantity_From_Stock__c', 'Product__r.Item__r.Stocking_UOM__c','Product__r.Item__r.Packaging_UOM__c',
                                  'Product__c','Product__r.Name','Quantity_Ordered__c','Quantity_Shipped__c','Quantity_to_Ship__c','Ship_From_Location__c', 'Ship_From_Location__r.Facility__c', 
                                  'Required_Date__c','Sales_Order__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c','Status__c','Discount_Percent__c',
                                  'Unit_Price__c','SystemModStamp','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c','Product__r.Item__r.Non_Inventory__c',
                                  'Sales_Order__r.Currency__c','Sales_Order__r.Company__c','Description__c','Selling_UOM__c','Quantity_Allocated__c', 'Pricebook__c', 
                                  'Product__r.Pricebook_Line_Required__c','Sales_Order__r.Company__r.Comp_Currency__c'};
                
                Set<String> skidFields = new Set<String>{'Id','Type__c','Quantity__c','Shipment_Line__r.Quantity_Shipped__c','Shipment_Line__r.Shipment__c',
    											'Shipment_Line__r.Extended_Price__c','Shipment_Line__r.Shipment__r.Finalized__c','Shipment_Line__r.Shipment__r.Locked__c',
                            					'Shipment_Line__r.Shipment__r.Status__c','Shipment_Line__c','Shipment_Line__r.Shipment__r.Date_Shipped__c',
                                                'Item__r.Stocking_UOM__c', 'Item__r.Packaging_UOM__c'
                };
                            					
                String whereClause =  'Sales_Order__c =:salesOrderId and Has_Exceptions__c = false AND Fulfillment_Source__c != \'Drop Ship\' AND Status__c = \'' + SalesOrderService.SO_STATUS_OPEN + '\'';
        
		        soql = new SOQLUtil('Sales_Order_Line__c');
		        soql.addFields('Fulfillment_RO');
		        soql.addFields(fieldStrings);
		        soql.setWhereClause(whereClause);
		        
                SOQLUtil.ChildRelationship invTrans = new SOQLUtil.ChildRelationship(soql, 'Inventory_Transactions__r');
			    invTrans.addFields(itFields);
			    invTrans.addFields('ConfirmShipRO');
			    invTrans.setWhereClause('Type__c IN (\'Sales Order Pick\',\'Sales Order Allocation\') AND Finalized__c = true and Shipment_Line__r.Shipment__r.Status__c != \'Confirmed\' AND Reversed__c = false');
			    soql.addChildRelationship(invTrans);
			      
			    SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
			    skids.addFields(skidFields);
			    skids.setWhereClause('Type__c = \'SO Demand\'');
			    soql.addChildRelationship(skids);
	                      
				List<Sales_Order_Line__c> tmpSOLines  = Database.query(soql.getQuery()); 
				                                  
                Set<Id> itemsToRemoveFromMap = new Set<Id>();
                
                for(Sales_Order_Line__c salesOrderLine : tmpSOLines) {
                    if (salesOrderLine.Product__r.Item__r.Non_Inventory__c == true || (salesOrderLine.Inventory_Transactions__r != null && salesOrderLine.Inventory_Transactions__r.size() > 0)){
                        soLineList.add(salesOrderLine);
                        if (salesOrderLine.Inventory_Transactions__r.size() > 0){
                            for (Inventory_Transaction__c it : salesOrderLine.Inventory_Transactions__r){
                                uniqueToLocations.add(it.to_Location__c);
                                if (salesOrderLine.Product__r.Item__r.Non_Inventory__c == false){
                                    if (it.To_Skid__c == null){
                                        SKID__c esk = new SKID__c(Type__c='Location');
                                        SkidService2.copyITAttributesToSkid(esk, it, attributesForDisplay);
                                        existingSkidList.add(esk);
                                    }
                                }
                                shipment = it.Shipment_Line__r.Shipment__r;
                            }
                        } else if (salesOrderLine.skids__r != null && salesOrderLine.skids__r.size() > 0 ) {
                            // OTC-726 - Populate shipment when no IT present with non-inventory item by using Skids
                            shipment = salesOrderLine.skids__r[0].Shipment_line__r.Shipment__r;
                        } else {
                            system.debug(logginglevel.warn, 'shipment is null on SalesOrderConfirmShip');
                        }
                    }
                }

                if (soLineList == null || soLineList.size() == 0){
                    disableConfirmShip = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, + Label.No_available_SOL ));
                    return; //throw new SOConfirmShipExtException(Label.No_available_SOL);
                }
                if (shipment == null ){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, 'No valid shipment found on Sales Order.' ));
                    return; 
                }
                shipment.Date_Shipped__c = System.now();
            }
        } catch( Exception e ){
            disableConfirmShip = true; 
            if (fromVisualforce)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, + MessageUtil.toFriendlyErrorMessage(e.getMessage()) ));
            else
                throw new SOConfirmShipExtException(e);
        }


        if (ApexPages.CurrentPage().getParameters().get('size') != null) {
            pageSize = Integer.valueOf(ApexPages.CurrentPage().getParameters().get('size'));
        }
        
        setCon = new ApexPages.StandardSetController(soLineList);                
        setCon.setPageSize(pageSize);
        first();  

    }

    // Pagination Code
    public Integer pageSize {get; set;} { pageSize = 20; }
    public Integer noOfRecords { get{ return setCon.getResultSize();} } 
    @TestVisible
    ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(new List<Sales_Order_Line__c>()); 
    // list we will show on the VF page ( subset of full list )
    public List<Sales_Order_Line__c> solPageList {get; set;}   {solPageList = new List<Sales_Order_Line__c>();}
    
    void populatePageList (List<Sales_Order_Line__c> solList) {        
        solPageList.clear();
        for (Sales_Order_Line__c sol : solList) {
            solPageList.add(sol);
        }
    }

    public Boolean hasNext {        get { return setCon.getHasNext();  }    }
    public Boolean hasPrevious {    get { return setCon.getHasPrevious(); }  }    
    public Integer pageNumber {     get { return setCon.getPageNumber(); }  }
    
    public void first() {
        setCon.first();
        populatePageList( (List<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void last() {
        setCon.last();
        populatePageList( (List<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void previous() {
        setCon.previous();
        populatePageList( (List<Sales_Order_Line__c>)setCon.getRecords() );
    }
    
    public void next() {
        setCon.next();
        populatePageList( (List<Sales_Order_Line__c>)setCon.getRecords() );
    }

	
    public void confirmShip(){
        
        Map<Id, Inventory_Transaction__c> inventoryTransactionsForUpdate = new Map<Id, Inventory_Transaction__c>();
        Map<Id, SKID__c> skidsToDelete = new Map<Id,SKID__c>();
        list<Sales_Order_Line__c> solLineList = new list<Sales_Order_Line__c>();
    
        System.Savepoint sp = Database.setSavepoint();

        Set<Id> salesOrderIds = new Set<Id>();

        salesOrderIds.add(this.salesOrder.Id);
        
        try{
            Map<Id,Boolean> createICs = new Map<Id,Boolean>();
            Map<List<String>, SKID__c> existingSkidKeyListMap = SkidService2.generateExistingSkidKeyListMap(attributesForDisplay, uniqueToLocations, existingSkidList);
            itemIds = new Set<Id>();
            facilityIds = new Set<Id>();
            for (Sales_Order_Line__c sol : soLineList){
                itemIds.add(sol.Product__r.Item__c);
                facilityIds.add(sol.Ship_From_Location__r.Facility__c);
            }

            for (Sales_Order_Line__c sol : soLineList){
                if(sol.Quantity_From_Stock__c==null || sol.Quantity_From_Stock__c==0)
                {   
                    sol.Quantity_From_Stock__c =  (sol.Quantity_Ordered__c * KSE.getConversionFactor(sol)).setscale(6,System.RoundingMode.HALF_UP);
                }
                if (sol.Product__r.Item__r.Non_Inventory__c == false){
                    for (Inventory_Transaction__c it : sol.Inventory_Transactions__r){
                        if (it.To_Skid__c == null){                            
                            List<String> keyList =  SkidService2.generateKeyListForIT(it, attributesForDisplay);
                            if (existingSkidKeyListMap.containsKey(keyList)){                                
                                it.To_SKID__c = existingSkidKeyListMap.get( keyList ).id;
                                it.To_SKID__r = existingSkidKeyListMap.get( keyList );
                            } else{
                                continue;
                            }                           
                        }  

                        if (!quantitySkidsByHeader.containsKey(sol.id))
                            quantitySkidsByHeader.put(sol.id, new List<SKID__c>());
                          
                        if (it.To_Skid__r.Quantity_Allocated__c == null) 
                            it.To_Skid__r.Quantity_Allocated__c  = 0;   
                        
                        it.To_Skid__r.Quantity_Allocated__c = (it.Quantity__c/KSE.getConversionFactorFromQuantity(sol.Quantity_From_Stock__c,sol.Quantity_Ordered__c)).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(sol);
                        it.To_Skid__r.Sales_Order_Line__c = it.Sales_Order_Line__c;
                        it.To_Skid__r.Shipment_Line__c = it.Shipment_Line__c;

                        quantitySkidsByHeader.get(sol.id).add(it.To_Skid__r.clone(true,true));
                    	if (it.Inventory_Change__c == null)
                    		createICs.put(sol.Id,false);
                        Decimal quantityShipped = (it.Quantity__c/KSE.getConversionFactorFromQuantity(sol.Quantity_From_Stock__c,sol.Quantity_Ordered__c)).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(sol);
                        if (it.Shipment_Line__r != null){
                                updateShipments(it.Shipment_Line__r , sol, KSE.addQuantityToField(it.Shipment_Line__r.Quantity_Shipped__c, quantityShipped));         
                        } else{
                            disableConfirmShip = true;
                            if (fromVisualforce)
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.No_Shipment_line + sol.Name));
                            else
                                throw new SOConfirmShipExtException(Label.No_Shipment_line + sol.Name);
                        }
                    }
                } else {                   
                    for (SKID__c dsk : sol.SKIDs__r) {
                        
                        if (dsk.Shipment_Line__r != null) {
                            updateShipments(dsk.Shipment_Line__r , sol, sol.Quantity_Ordered__c );
                            sol.Quantity_Shipped__c = sol.Quantity_Ordered__c;
                            solLineList.add( sol );
                            skidsToDelete.put( dsk.id, dsk );
                        } else {
                            disableConfirmShip = true;
                            if (fromVisualforce)
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.No_Shipment_line+ sol.Name));
                            else
                                throw new SOConfirmShipExtException(Label.No_Shipment_line + sol.Name);
                        }
                    }
                }  
            }



            //Update the Sales Order Line unit price if the SO price determination date is Ship Date
            if (this.salesOrder.Price_Determination_Date__c == SalesOrderService.PRICE_DET_SHIPMENT){

                Date soPricingDate = date.newinstance(this.salesOrder.Pricing_Date__c.year(), this.salesOrder.Pricing_Date__c.month(), this.salesOrder.Pricing_Date__c.day());
                Date dateShipped = date.newinstance(shipment.Date_Shipped__c.year(), shipment.Date_Shipped__c.month(), shipment.Date_Shipped__c.day());

                //Update only if the SO pricing date matches the dateShipped. THe rest of the cases are taken care of the trigger when the pricing date is update if the ship
                //date is different from the Pricing date.
                if(soPricingDate == dateShipped){

                    DML.updateAsUser(SalesOrderLineService.validateSalesOrderPrices(salesOrderIds));
                }
                
            }
                

            DML.deleteAsSystem(skidsToDelete.values());
            SkidService2.inventoryTransactionForPullFrom(soLineList, quantitySkidsByHeader, 'Sales Order Shipment', attributesForDisplay, null, 'Quantity_Allocated__c', null, true, null,null,null,null,createICs);
            DML.updateAsUser(solshlMap.values());
            DML.updateAsUser(shipmentMap.values());
            DML.updateAsUser(solLineList);
            
            
            
        } catch(Exception e) {
            Database.rollback(sp);   
            disableConfirmShip = true;
            if (fromVisualforce)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,  MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            else
                throw new SOConfirmShipExtException(e);
        }

        if (fromVisualforce)
            returnUrl = (ApexPages.hasMessages() ? '' : con.cancel().getUrl() );
        
        return;
    }
    
    public Set<Id> itemIds;
    public Set<Id> facilityIds;
    
    public void updateShipments( Shipment_Line__c shl , Sales_Order_Line__c sol, Decimal QuantityShipped ){
        
        shl.Quantity_Shipped__c = QuantityShipped;
        Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds, sol.Company__c, sol.Ship_From_Location__r.Facility__c, System.Now(),sol.Product__r.Item__c);
        if (stdCost != null) {
            shl.Extended_Cost__c = stdCost * KSE.addQuantityToField(shl.Quantity_Shipped__c, 0) * KSE.getConversionFactorFromQuantity(sol.Quantity_From_Stock__c,sol.Quantity_Ordered__c);//KSE.getConversionFactor(sol);
            if( sol.product__r.Item__r.Non_Inventory__c == false)                       
                shl.Quantity_From_Stock__c = KSE.addQuantityToField(shl.Quantity_Shipped__c, 0) * KSE.getConversionFactorFromQuantity(sol.Quantity_From_Stock__c,sol.Quantity_Ordered__c);//KSE.getConversionFactor(sol);                                   
        } else {
            shl.Extended_Cost__c = 0;
        }
        
        solshlMap.put(sol.id,shl); //Created Map to pass for Reprice logic.
        
        shl.Shipment__r.Date_Shipped__c = (shipment.Date_Shipped__c == null)  ? System.now() : shipment.Date_Shipped__c; // OTC-502
        shl.Shipment__r.Status__c = 'Confirmed';
        shl.Shipment__r.Transaction_date__c = (shl.Shipment__r.Transaction_date__c == null) ? system.now() : shl.Shipment__r.Transaction_Date__c;
        //shl.Shipment__r.Finalized__c = true;
        shl.Shipment__r.Locked__c = true;
        shipmentMap.put(shl.Shipment__c, shl.Shipment__r);       
    }
    
    public void  undoConfirmPick(){
        
        System.Savepoint sp = Database.setSavepoint();
        try{
            soService = new SalesOrderService();
            
            Set<Id> inventoryTransactionIds = new Set<Id>();
            if(ApexPages.currentPage().getParameters().get('selectedIndexes') != null){
                for(String invTransId : ApexPages.currentPage().getParameters().get('selectedIndexes').split(',')){
                    inventoryTransactionIds.add(invTransId);    
                }
            } else{
                throw new SOConfirmShipExtException(Label.SelectedIndexes_not_found);
            }
            
            if (inventoryTransactionIds.size() != 0) {
                soService.undoConfirmPickNew(inventoryTransactionIds);
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.Select_records));
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage()) + ',' + e.getStackTraceString()));
            Database.rollback(sp);       
            
            return;
        }

        returnUrl = (ApexPages.hasMessages() ? null : con.cancel().getUrl() );
        return;
    }

}