public with sharing class SalesOrderLineService {

    public static final String SOL_FULFILLEMENT_SOURCE_DROPSHIP = 'Drop Ship';
    public static final String SOL_FULFILLEMENT_SOURCE_INVENTORY = 'Inventory';
    public static final String SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER = 'Build To Order';
    public static final String SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK = 'Back To Back'; //KNDY-13447
    public static final String SOL_FULFILLEMENT_SOURCE_RESALE = 'Resale';

    public static final String SOL_STATUS_DRAFT = 'Draft';

    public static Boolean IgnoreSalesOrderLineUpdate = false;
    public static ExceptionService exService = new ExceptionService();
    public static Boolean isExecuting = false;

    public static final String SO_LINE_STATUS_DRAFT = 'Draft' ;
    public static final String SO_LINE_STATUS_OPEN = 'Open' ;
    public static final String SO_LINE_STATUS_CLOSED = 'Closed' ;
    public static final String SO_LINE_STATUS_CANCELLED = 'Cancelled' ;


    public static final String SO_LINE_TYPE_KIT = 'Kit';
    public static final String SO_LINE_TYPE_KIT_CHILD = 'Kit-Child';
    public static final String SO_LINE_TYPE_REPAIR = 'Repair';
    

    class SalesOrderLineException extends Exception{
        
    }


    public static void validateFulfillmentSource(){

        Set<Id> soIds = new Set<Id>();

        if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){      

            for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new) {

                soIds.add(sol.Sales_Order__c);

            }

            Map<Id,Sales_Order__c> soMap = new Map<Id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soIds));

            for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new) {

                if(soMap.get(sol.Sales_Order__c) != null && soMap.get(sol.Sales_Order__c).Type__c != null){

                    if(soMap.get(sol.Sales_Order__c).Type__c == SalesOrderService.SO_TYPE_RESALE){

                        if(sol.Fulfillment_Source__c != SOL_FULFILLEMENT_SOURCE_RESALE){

                            sol.addError('Resale orders can only have Resale fulfillment source on the Sales order line');

                        }

                    } else{

                        if(sol.Fulfillment_Source__c == SOL_FULFILLEMENT_SOURCE_RESALE){

                            sol.addError('Resale fulfillment source cannot be part of ' + soMap.get(sol.Sales_Order__c).Type__c + ' Sales Order type');

                        }
                    }
                }
                
            }
        }
    }

    // OTC-948: Keep the Product Item Purchasing UOM the same as the SOL Selling UOM
    public static void validateItemUOM(){

        Set<Id> productSet = new Set<Id>();

        if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){  

            for (Sales_Order_Line__c obj : (List<Sales_Order_Line__c>) trigger.new) {

                if ((obj.Fulfillment_Source__c == SOL_FULFILLEMENT_SOURCE_DROPSHIP 
                     || obj.Fulfillment_Source__c == SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK)  
                    && (trigger.isInsert 
                       || (trigger.isUpdate && KSE.isFieldChanging('Selling_UOM__c', obj, Trigger.oldMap) 
                       || (trigger.isUpdate && KSE.isFieldChanging('Fulfillment_Source__c', obj, Trigger.oldMap))))){   

                        productSet.add(obj.Product__c);
                } 
            }

            if (!productSet.isEmpty()){
                SalesOrderLineService.validateItemUOM(productSet, (List<Sales_Order_Line__c>) trigger.new);
            }

        }
    }


    public static void validateItemUOM(Set<Id> productSet, List<Sales_Order_Line__c> soLines) {
        
        Map<id, Product__c> productMap = new Map<id,Product__c>(SalesOrderFlowCache.cachedProductsForIds(productSet));        
        
        for (Sales_Order_Line__c sol : soLines) {

            if(sol.Fulfillment_Source__c == SOL_FULFILLEMENT_SOURCE_DROPSHIP || 
               sol.Fulfillment_Source__c == SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK){

                if(sol.Selling_UOM__c == null){
                    sol.Selling_UOM__c.addError('Selling UOM cannot be empty for Drop-Ship or Back-To-back Sales order lines.');
                } else{
                    if(productMap.containsKey(sol.Product__c)){
                        if(sol.Selling_UOM__c != productMap.get(sol.Product__c).Item__r.Purchasing_UOM__c){
                            String purchasingUOM = (productMap.get(sol.Product__c).Item__r.Purchasing_UOM__r.Name != null) ? productMap.get(sol.Product__c).Item__r.Purchasing_UOM__r.Name : 'no value';
                            sol.Selling_UOM__c.addError(Label.The_Selling_UOM_should_remain_consistent_with_the_Item_Purchasing_UOM + ': ' + purchasingUOM); 
                        }
                    }
                }
            }
        }
    }

    /** 
     * @description  called from sales order lines trigger when inserting new records,
     * task is to validate the product is active and check or default price from pricebook.
     *
     * KNDY-407  If there is no active price for a product on a price book, users cannot order, allow and mark exception
     * 
     * Verify that prices are set on the sales order based on price book entry 
     * Verify that price book values are set based on effective prices 
     * price book lines may have empty dates for "end date" , this indicates they never expire
     * price book lines must have  start date <= today before we can use the price
     * flag and mark records which don't have or dont match (price book price == sales order line price)
     * 
     * KNDY-1061 except where product. require pricebook == false , these do not need price validation
     *         
     */
    
    public static void validateSalesOrderLinePrices( ) {
            
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            List<Sales_Order_Line__c> soLinesForPriceValidations = new List<Sales_Order_Line__c>();
            
            for( Sales_Order_Line__c obj: (List<Sales_Order_Line__c>) trigger.new) {
            
                if(trigger.isInsert || trigger.isUpdate && 
                     (KSE.isFieldChanging('Product__c', obj, Trigger.oldMap) ||
                      KSE.isFieldChanging('Pricebook__c', obj, Trigger.oldMap) ||
                      KSE.isFieldChanging('Unit_Price__c', obj, Trigger.oldMap) ||
                      KSE.isFieldChanging('Quantity_Ordered__c', obj, Trigger.oldMap))) {   

                    // historical data has status closed, dont check prices on those KNDY-5618
                    if ( obj.get('Historical__c') == false) {                   
                        
                        soLinesForPriceValidations.add(obj);
                    }
                }  

//                if(obj.Discount_Percent__c < 0){
//
//                    obj.addError('Discount percent cannot be negative');
//                    continue;
//                }
            }

            if ( !soLinesForPriceValidations.isEmpty() ) {
                SalesOrderLineService.validateSalesOrderLinePrices( soLinesForPriceValidations );
            }
        }
    }

    // validate pricing on SOLs that are being updated
    public static void validateSalesOrderLinePrices( Sales_Order_Line__c[] sols) {

		List<Sales_Order_Line__c> solForReprice = new List<Sales_Order_Line__c>();

        Set <Id> soSet = new Set<Id>();
        Set <Id> productSet = new Set<Id>();

        for (Sales_Order_Line__c sol : sols){
            soSet.add(sol.Sales_Order__c);
            productSet.add(sol.Product__c);
            
        }
        
        Map<Id,Sales_Order__c> soMap = new Map<Id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soSet));
        Map<id, Product__c> productMap = new Map<id, Product__c>(SalesOrderFlowCache.cachedProductsForIds(productSet));
        
        for (Sales_Order_Line__c sol : sols){
            sol.Sales_Order__r = soMap.get(sol.Sales_Order__c);
            sol.Product__r = productMap.get(sol.Product__c);

			if ( sol.Agreement_Line__c == null){
				solForReprice.add(sol);
			}
        }

		if (!solForReprice.isEmpty()) {
			System.debug( logginglevel.error, '~*~ (SOLS) Repricing :' + solForReprice );
			Map<String, Pricebook_Line__c> pblSolMap = PricingService.fetchSOLinesPriceBookInfo( solForReprice );
			updateSalesOrderLinePrices( solForReprice, pblSolMap );
		}
    }
    
    public static void updateSalesOrderLinePrices( Sales_Order_Line__c[] sols, Map<String, Pricebook_Line__c> pblSolMap){

        for(Sales_Order_Line__c sol: sols) {

            //Ignore price update on SOL for the following conditions
            if(sol.Type__c == SalesOrderLineService.SO_LINE_TYPE_KIT_CHILD ||
               (sol.Agreement_Line__c != null && sol.Unit_Price__c != null) || sol.Sales_Order__r.Type__c.contains('Price Adjustment')){
				System.debug( logginglevel.error, '~*~ SKIPPING reprice :' );
                continue; //Do not update price for Kit Child
            }

            if (sol.Customer_Transaction_lines__r != null){
                Decimal totalQuantity = 0;    
                for (customer_invoice_line__c ci : sol.Customer_Transaction_lines__r){
                    totalQuantity += ci.Quantity_shipped__c;
                }
                if (totalQuantity == sol.Quantity_Ordered__c){ // CI quanitty shipped matches sol quantity ordered. Dissalow pricing change.
                    continue;
                }
            }

            if (sol.Product__c == null){
                System.debug(logginglevel.ERROR, 'Product is missing on SOL : ' + sol);
                continue;
            }

            if (sol.Product__r.Pricebook_Line_Required__c == true &&
                (!pblSolMap.containsKey(sol.Sales_Order__c + '-' + sol.Line__c) ||
                pblSolMap.get(sol.Sales_Order__c + '-' + sol.Line__c).Pricebook__c == null)) {

                exService.setException(sol,ExceptionUtil.PRICEBOOK_LINE_NOT_FOUND);
                
            } else if(pblSolMap.containsKey(sol.Sales_Order__c + '-' + sol.Line__c)){
                exService.clearException(sol,ExceptionUtil.PRICEBOOK_LINE_NOT_FOUND);
                Pricebook_Line__c pbl = pblSolMap.get(sol.Sales_Order__c + '-' + sol.Line__c);

				System.debug( logginglevel.error, '~*~ pbl Update: PB FOUND:' + pbl);
				// KNDY-18341 - If matching pricebook line is found, populate List Price on SOL
				sol.List_Price__c = sol.Sales_Order__r.Bracket_Price_Field_In_Use__c != null ? ( Decimal ) pbl.get( sol.Sales_Order__r.Bracket_Price_Field_In_Use__c ) : pbl.Price__c;

                if(sol.Product__r.Pricebook_Line_Required__c &&
                   	sol.Unit_Price__c != null &&
                   	sol.Unit_Price__c != pbl.Price__c &&
					sol.New_Pricing_Rule__c == null){

                    if(!String.isBlank(sol.Sales_Order__r.Bracket_Price_Field_In_Use__c)){
                        exService.clearException(sol, ExceptionUtil.SOL_MISSING_PRICE);
						sol.Unit_Price__c = sol.Sales_Order__r.Bracket_Price_Field_In_Use__c != null ? ( Decimal ) pbl.get( sol.Sales_Order__r.Bracket_Price_Field_In_Use__c ) : sol.Unit_Price__c;

                        sol.Pricebook__c = pbl.Pricebook__c;
						sol.Pricebook_Line__c = pbl.Id;
                        sol.List_Price__c = sol.Unit_Price__c;
                    } else {
                        exService.setException(sol,ExceptionUtil.PRODUCT_PRICE_MISMATCH_UNIT_PRICE);
                    }

                } else {
                    exService.clearException(sol, ExceptionUtil.PRODUCT_PRICE_MISMATCH_UNIT_PRICE);
                    
                    if ( pbl.Use_Fixed_Pricing__c ||
                         String.isBlank(sol.Sales_Order__r.Bracket_Price_Field_In_Use__c) ||
                         sol.Sales_Order__r.Customer__r.Use_Fixed_Pricing__c )
					{

						// No brackets configured, do what was happening before
						// if the price is empty on the sales order line, default it from the price book
						sol.Pricebook_Line__c = pbl.Id;
						System.debug( logginglevel.error, '~*~ pbl Update: sol.Pricebook_Line__c :' + sol.Pricebook_Line__c);
						sol.Pricebook__c = pbl.Pricebook__c;

						if (sol.New_Pricing_Rule__c == null) {
							sol.Unit_Price__c = ( sol.Unit_Price__c != null && !sol.Product__r.Pricebook_Line_Required__c ) ? sol.Unit_Price__c : pbl.Price__c;
						}

                        sol.List_Price__c = pbl.Price__c;

                    } else if (!String.isBlank(sol.Sales_Order__r.Bracket_Price_Field_In_Use__c)){

                        if ((Decimal)pbl.get(sol.Sales_Order__r.Bracket_Price_Field_In_Use__c) == null) {
                            exService.setException(sol, ExceptionUtil.SOL_MISSING_PRICE);
                        } else {
                            exService.clearException(sol, ExceptionUtil.SOL_MISSING_PRICE);
                        }
                        // use brackets
						sol.Pricebook_Line__c = pbl.Id;
						System.debug( logginglevel.error, '~*~ pbl Update: sol.Pricebook_Line__c :' + sol.Pricebook_Line__c);
                        sol.Unit_Price__c = (Decimal)pbl.get(sol.Sales_Order__r.Bracket_Price_Field_In_Use__c);
                        sol.Pricebook__c = pbl.Pricebook__c;
                        sol.List_Price__c = (Decimal)pbl.get(sol.Sales_Order__r.Bracket_Price_Field_In_Use__c);
                    }
                }
            }

            
        }
    }

    public static Sales_Order_Line__c[] validateSalesOrderPrices( Set<Id> soIds) {
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        String SO_STATUS_CANCEL = SalesOrderService.SO_STATUS_CANCEL;
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Sales_Order__c','Product__c','Pricebook__c','Unit_Price__c','Quantity_Ordered__c','Product__r.Product_Group__c','Company__c',
            'Currency__c','Sales_Order__r.Company__c','Sales_Order__r.Pricebook__c','Sales_Order__r.Customer__c','Ordered_Date_Time__c',
            'Sales_Order__r.Currency__c','Pricebook__r.Currency__c','Sales_Order__r.Bracket_Price_Field_In_Use__c', 'Type__c',
            'Sales_Order__r.Type__c','Sales_Order__r.Price_Determination_Date__c','Sales_Order__r.Customer__r.Pricebook__c','Sales_Order__r.Pricing_Date__c',
            'Sales_Order__r.Date_Time_Ordered__c','Product__r.Pricebook_Line_Required__c','Sales_Order__r.Customer__r.Use_Fixed_Pricing__c',
            'Agreement_Line__c', 'Line__c'
        });
        soql.setWhereClause('Status__c != :SO_STATUS_CANCEL and Sales_Order__c IN :soIds');
        
        String STATUS_CLOSED = CustomerInvoiceService.STATUS_CLOSED;
        String STATUS_OPEN = CustomerInvoiceService.STATUS_OPEN;
        
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customer_transaction_lines__r');
        childRel.addFields(new set<string>{
            'id','Quantity_Shipped__c','Customer_invoice__r.Status__c'
        });
        childRel.setWhereClause('Customer_invoice__r.Status__c IN (:STATUS_CLOSED, :STATUS_OPEN)');
        soql.addChildRelationship(childRel);

        List<Sales_Order_Line__c> sols = Database.query(soql.getQuery());

        for (Sales_Order_Line__c sol : sols) {

            if(sol.Product__r.Pricebook_Line_Required__c){
                sol.unit_price__c = null;
            }

        }

        if(sols.size() > 0){
            validateSalesOrderLinePrices(sols);
        }

		return sols;
    }
    
    /*********************************  ORDER WEIGHT METHODS ***************************************/
    
    /** 
    * @description  KNDY-614 : Updates SOL with details from product and product's Item only if the product is changed
    */
    public static void setWeightAndUOM() {
        
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>();
            Set<Id> parentLineIds = new Set<Id>();

            for(Sales_Order_Line__c sol: (List<Sales_Order_Line__c>) ProcessHandler.getUnprocessedRecords(trigger.new)) {
                if( trigger.isInsert || 
                    (trigger.isUpdate &&
                        (KSE.isFieldChanging('Product__c', sol, trigger.oldMap) || KSE.isFieldChanging('Selling_Uom__c', sol, trigger.oldMap) ||
                         KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap) || KSE.isFieldChanging('Weight_UOM__c', sol, trigger.oldMap)
                        )
                    )
                ){
                    soLines.add(sol);
                    if (sol.Parent_Sales_Order_Line__c != null) {
                        parentLineIds.add(sol.Parent_Sales_Order_Line__c);
                }
            }
            }

            if(!soLines.isEmpty()){
                SalesOrderLineService.setWeightAndUOM( soLines, parentLineIds);
            }
        }
        
    } 
    
    public static List<Sales_Order_Line__c> setWeightAndUOM(List<Sales_Order_Line__c> soLines, Set<Id> parentSOLIds) {
    
        Set<id> productIdSet = KSE.grepRelatedIdSetFromList(soLines , 'Product__c', true);
        decimal conversionFactor=1;
        if (! soLines.isEmpty() && ! productIdSet.isEmpty()) {
            Set<Id> locationIds = KSE.grepRelatedIdSetFromList(soLines, 'Ship_From_Location__c', true);
            Set<id> soSet = KSE.grepRelatedIdSetFromList(soLines, 'Sales_Order__c', true);        
            Map<Id, Sales_Order__c> soMap = new Map<id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soSet));
            Map<Id, Product__c> ProductIdSalesOrderLineMap = new Map<Id, Product__c >(SalesOrderFlowCache.cachedProductsForIds(productIdSet));
            Map<Id, Sales_Order_Line__c> parentSOLMap;
            Map<Id, Location__c> locationMap = new Map<Id, Location__c>(SalesOrderFlowCache.cachedLocationsForIds(locationIds));

            if (parentSOLIds!= null && !parentSOLIds.isEmpty()) {
                parentSOLMap = new Map<Id, Sales_Order_Line__c>(SalesOrderFlowCache.cachedSalesOrderLinesForIds(parentSOLIds));
            }
            
            Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>>();
            for(Sales_Order_Line__c sol: soLines) {
                try{
                if ( sol.Product__c != null ) {
                    Product__c prod = ProductIdSalesOrderLineMap.get(sol.Product__c);
                    sol.Product__r = prod;
                    if ( !itemPackagingUOMCache.containsKey (prod.Item__c) ) {
                        List<Id> lstPkgUom = (List<Id>) JSON.deserialize( prod.Item__r.Packaging_UOM__c, List<Id>.class );
                        itemPackagingUOMCache.put(prod.Item__c, lstPkgUom);
                    }
                    
                    if(sol.Quantity_Ordered__c !=null){
                        Decimal facilityIdentifier = locationMap.containsKey(sol.Ship_From_Location__c) && locationMap.get(sol.Ship_From_Location__c).Facility__r != null ? locationMap.get(sol.Ship_From_Location__c).Facility__r.Facility_Identifier__c : null;
                        conversionFactor = KSE.getConversionFactor(prod.Item__c, facilityIdentifier,sol.Selling_Uom__c,prod.Item__r.Stocking_Uom__c, itemPackagingUOMCache.get(prod.Item__c));
                        
                        sol.Quantity_From_Stock__c = (sol.Quantity_Ordered__c * conversionFactor).setscale(6,System.RoundingMode.HALF_UP);
                    }
                    
                    if(prod.Weight__c != null && sol.Quantity_Ordered__c !=null){
                        conversionFactor = KSE.getSOConversionFactor(sol, 'weight');
                        
                       sol.Weight__c = (prod.Weight__c * sol.Quantity_Ordered__c * conversionFactor);//.setscale(6,System.RoundingMode.HALF_UP);  //KNDY 3621 UOM Conversion 
                       
                       sol.Product_Weight__c = sol.Weight__c;                       
                    }
                    
                    if(prod.Width__c != null && prod.Length__c != null && prod.Height__c != null && sol.Quantity_Ordered__c != null){
                        conversionFactor = KSE.getSOConversionFactor(sol, 'dimension');
                        
                       sol.Volume__c = ((prod.Width__c * prod.Length__c * prod.Height__c * sol.Quantity_Ordered__c)*(conversionFactor)).setscale(6,System.RoundingMode.HALF_UP);
                    }
                    
                    // KNDY-3688 : Add pallet weight to the order weight
                    Sales_Order__c so = soMap.get(sol.Sales_Order__c);
                    if (sol.Weight__c != null && so.Ship_to__r.Pallet_Product__r.Weight_UOM__c != null && sol.Weight_UOM__c != null) {
                        // Not depending on sol formula field (Number of Pallets), as it might not be evaluated correctly on product changes and other situations
                        // KNDY-4090: Added check for zero
                        //KNDY#4343 Rounding Number Of Pallets
                        Decimal numberOfPallets = prod.Units_per_Pallet__c != null && prod.Units_per_Pallet__c > 0 ? (sol.Quantity_Ordered__c / prod.Units_per_Pallet__c).round(roundingMode.CEILING) : 0;
                        
                        if ( !itemPackagingUOMCache.containsKey (so.Ship_to__r.Pallet_Product__r.Item__c) ) {
                            List<Id> lstPkgUom = (List<Id>) JSON.deserialize( so.Ship_to__r.Pallet_Product__r.Item__r.Packaging_UOM__c, List<Id>.class );
                            itemPackagingUOMCache.put(prod.Item__c, lstPkgUom);
                        }
                        conversionFactor = KSE.getConversionFactor(so.Ship_to__r.Pallet_Product__r.Item__c, sol.Ship_From_Location__r.Facility__r.Facility_Identifier__c, so.Ship_to__r.Pallet_Product__r.Weight_UOM__c, sol.Weight_UOM__c, itemPackagingUOMCache.get(so.Ship_to__r.Pallet_Product__r.Item__c));
                           
                        sol.Weight__c += ((so.Ship_to__r.Pallet_Product__r.Weight__c * numberOfPallets) * conversionFactor).setscale(6,System.roundingmode.HALF_UP);//KSE.getConversionFactor(so.Ship_to__r.Pallet_Product__r.Weight_UOM__r.Name, sol.Weight_UOM_Name__c);                              
                    }

                    if (prod.Item__r.Source__c != null && sol.Item_Source__c != prod.Item__r.Source__c){
                        sol.Item_Source__c = prod.Item__r.Source__c;
                    }

                        // Set SOL invoiceable according to product invoiceable flag, unless it was a kit Parent SOL
                    if (so.Type__c != SalesOrderService.SO_TYPE_REPAIR && so.Type__c != SalesOrderService.SO_TYPE_RMA_REPAIR && so.Type__c != SalesOrderService.SO_TYPE_RMA_REPLACEMENT && prod.Invoiceable__c != sol.Invoiceable__c && (sol.Parent_Sales_Order_Line__c == null || (sol.Parent_Sales_Order_Line__c != null && parentSOLMap.containskey(sol.Parent_Sales_Order_Line__c) && parentSOLMap.get(sol.Parent_Sales_Order_Line__c).Item_Source__c != 'Kit'))) {
                        sol.Invoiceable__c = prod.Invoiceable__c;
                    }
                    
                    if( so.Type__c != SalesOrderService.SO_TYPE_REPAIR){
                        sol.Non_Shippable__c = prod.Item__r.Non_Shippable__c;
                    }
            }
                } catch (exception e) {
                    System.debug(loggingLevel.Error, e.getMessage() + ' ' + e.getStackTraceString());
                    sol.addError(e);
        }
            }
        }

        return soLines;
    }
    
    /*********************************  SALES ORDER LINE DETAIL METHODS ***************************************/
    
    // KNDY-631 : before update see if the product is changing on a closed (shipped) line, don't allow it
    public static void validateChanges(){
        
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            Set <id> soSet = KSE.grepRelatedIdSetFromList(trigger.new, 'Sales_Order__c', true);        
            Map<id,Sales_Order__c> soMap = new Map<id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soSet));
                
            for( Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new) {
                
                Sales_Order__c sOrder = soMap.get(sol.Sales_Order__c);
                
                if(trigger.isBefore && trigger.isUpdate){
          
                    if (sol.Status__c != SOL_STATUS_DRAFT && trigger.oldMap.get(sol.id).get('Status__c') != SOL_STATUS_DRAFT ){
                         if (KSE.isFieldChanging('Non_Shippable__c', sol, trigger.oldMap)) {
                            sol.Non_Shippable__c.addError(Label.This_field_cannot_be_edited_once_a_Sales_Order_is_Released +': ' + Schema.SObjectType.Sales_Order_Line__c.fields.Non_Shippable__c.label);
                        }
                    }

                    if (sol.Status__c != SOL_STATUS_DRAFT){

                        if (KSE.isFieldChanging('Fulfillment_Source__c', sol, trigger.oldMap)) {
                            sol.Fulfillment_Source__c.addError(Label.This_field_cannot_be_edited_once_a_Sales_Order_is_Released  +': ' + Schema.SObjectType.Sales_Order_Line__c.fields.Fulfillment_Source__c.label);
                        }
	                    if (KSE.isFieldChanging('Product__c', sol, trigger.oldMap)) {
	                        sol.Product__c.addError(Label.This_field_cannot_be_edited_once_a_Sales_Order_is_Released  +': ' + Schema.SObjectType.Sales_Order_Line__c.fields.Product__c.label);
	                    } 
						
						if (KSE.isFieldChanging('Ship_From_Location__c', sol, trigger.oldMap)) {
	                        sol.Ship_From_Location__c.addError(Label.This_field_cannot_be_edited_once_a_Sales_Order_is_Released +': ' + Schema.SObjectType.Sales_Order_Line__c.fields.Ship_From_Location__c.label);
	                    }
	                    
	                    if (KSE.isFieldChanging('Required_Date__c', sol, trigger.oldMap)) {
	                        sol.Required_Date__c.addError(Label.This_field_cannot_be_edited_once_a_Sales_Order_is_Released +': ' + Schema.SObjectType.Sales_Order_Line__c.fields.Required_Date__c.label);
	                    }
						
						if(trigger.oldMap.get(sol.Id).get('Fulfillment_Source__c') == SOL_FULFILLEMENT_SOURCE_DROPSHIP || trigger.oldMap.get(sol.Id).get('Fulfillment_Source__c') == SOL_FULFILLEMENT_SOURCE_BACK_TO_BACK){ //KNDY-13447
	                    	if (KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap) && (sol.Quantity_Ordered__c < sol.Quantity_Shipped__c)) {
		                        sol.Quantity_Ordered__c.addError('Order quantity on open order lines should be greater than or equal to Quantity shipped.');
		                        continue;
		                    }
		                }
	                }
	                
	                if (KSE.isFieldChanging('Product__c', sol, trigger.oldMap) && (SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(sOrder.Type__c))) {
	                        sol.Product__c.addError(Label.Product_Cannot_Be_Changed_on_RMA);
	                }
					if ( KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap) 
						 && sol.Quantity_Change_Reason__c == null 
						 && sol.Status__c != SOL_STATUS_DRAFT) { 
					   
					   //KNDY-2551 Qty Line Change requires a Reason Code
					   //KNDY-5448 Qty change requiring Reason Code should only happen on the Sales Order Open status not draft status
					   sol.Quantity_Change_Reason__c.addError(Label.Reason_code_required_for_quantity_change);
					}
	    		}
	    		
	    		if(sol.Quantity_Ordered__c < KSE.addQuantityToField(sol.Quantity_Allocated__c, sol.Quantity_Shipped__c) && SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(sOrder.Type__c) == false && (SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(sOrder.Type__c) == false || (SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(sOrder.Type__c) == true && sol.Quantity_Ordered__c > 0))){
		            sol.addError('Quantity Ordered cannot be less than the sum of Quantity Allocated and Quantity Shipped.');
		            continue;
		        }
		        
                        if (KSE.isFieldChanging('Non_Shippable__c', sol, trigger.oldMap) && (sol.Non_Shippable__c == null || sol.Non_Shippable__c == FALSE) && sol.Item_Source__c == 'Kit') {
                            sol.Non_Shippable__c.addError(Label.Non_Shippable_Flag_should_not_be_unchecked);
                        }
        	}
        }
	}
    
    public static void populateData(){
        if(trigger.isBefore && ( trigger.isInsert || trigger.isupdate) ) {
            populateData(trigger.new);
        }
    }
    
    public static void populateData(List<Sales_Order_Line__c> soLines){
        // when sales order line is loaded, link it to a sales order if the parent lookup is null
        CompanyService.setLookupUsingField(soLines, true, 'Sales_Order__c', 'Sales_Order__c', 'Sales_Order_Number__c');
        
        // fill in the product on the line when we are given a UPC code
        CompanyService.setLookupUsingField(soLines, true, 'Product__c', 'Product__c', 'UPC_Code__c' );
        
        // fill in the product using Primary key f that is available
        Relate.setLookupUsingField(soLines, true, 
                'Product__c', 
                'Product__c', 
                'UPC_Code__c',          // field on sol
                'Primary_Key__c'     // field on product
                );
        
        // fill in the company if we can, using company_identifier 
        CompanyService.setDefaultCompany(soLines) ;
    }
    
    // KNDY-7965
    public static void calculateDiscountFields(){
    	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
    		List<Sales_Order_Line__c> sols = new List<Sales_Order_Line__c>();
    		
    		for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new){
	    		if(KSE.isFieldChanging('Discount_Amount__c', sol, trigger.oldMap) || 
	    		   KSE.isFieldChanging('Discount_Percent__c', sol, trigger.oldMap) ||
	    		   KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap) || 
	    		   KSE.isFieldChanging('Unit_Price__c', sol, trigger.oldMap) 
	    		){
	    			sols.add(sol);	
	    			
	    			if(KSE.isFieldChanging('Discount_Amount__c', sol, trigger.oldMap)){
	    				sol.Discount_Percent__c = null;
	    			}
	    			else
	    			if( KSE.isFieldChanging('Discount_Percent__c', sol, trigger.oldMap) ||
	    				KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap) || 
	    		   		KSE.isFieldChanging('Unit_Price__c', sol, trigger.oldMap)){
	    				
	    				sol.Discount_Amount__c = null;
	    			}
	    		}
    		}
    		
    		for(Sales_Order_Line__c sol : sols){
    			
    			if(sol.Extended_Price__c != null){
    				PricingService.RateBasis rb = PricingService.getRateBasis(sol.Rate_Basis__c);
                    Decimal qtyMult = rb == PricingService.RateBasis.FLAT ? 1 : sol.Quantity_Ordered__c;
    				Decimal extendedPriceBeforeDiscount = PricingService.returnPrice(qtyMult, sol.Unit_Price__c, sol.Off_Invoice_Rate__c, 0, 0, 0);

                  //  (sol.Quantity_Ordered__c * KSE.subtractDecimals(sol.Unit_Price__c, sol.Off_Invoice_Rate__c))
    														//- (sol.Allowances__c != null ? sol.Allowances__c : 0.0)
    														//- (sol.Freight_Allowance__c != null ? sol.Freight_Allowance__c : 0.0);
    				
    				if(sol.Discount_Amount__c != null && extendedPriceBeforeDiscount != 0){
    					sol.Discount_Percent__c = 100 * (sol.Discount_Amount__c / extendedPriceBeforeDiscount);
    				}
	    			else
	    			if(sol.Discount_Percent__c != null){
	    				sol.Discount_Amount__c = extendedPriceBeforeDiscount * sol.Discount_Percent__c / 100;
	    			}
	    		}
    		}
    	}
    }
    
    // KNDY-7966: Populate Active Standard Cost on the sales order 
    public static void populateStandardCost(){
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            
            List<Sales_Order_Line__c> sols = new List<Sales_Order_Line__c>();
            
            Set<Id> productIds = new Set<Id>();
            Set<Id> locationIds = new Set<Id>();
            
            for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new){
                if( KSE.isFieldChanging('Product__c', sol, trigger.oldMap) ||
                    KSE.isFieldChanging('Ship_From_Location__c', sol, trigger.oldMap)){
                        
                    productIds.add(sol.Product__c);
                    locationIds.add(sol.Ship_From_Location__c);
                    
                    sols.add(sol);
                }
            }
            
            Set<Id> itemIds = new Set<Id>();
            Set<Id> facilityIds = new Set<Id>();
            Map<Id, Product__c> productMap = new Map<Id, Product__c>(SalesOrderFlowCache.cachedProductsForIds(productIds));
            Map<Id, Location__c> locationMap = new Map<Id, Location__c>(SalesOrderFlowCache.cachedLocationsForIds(locationIds));
            
            for(Sales_Order_Line__c sol : sols){
                if(! String.isBlank(sol.Product__c)){
                    itemIds.add(productMap.get(sol.Product__c).Item__c);
                }
                if(! String.isBlank(sol.Ship_From_Location__c)){
                    facilityIds.add(locationMap.get(sol.Ship_From_Location__c).Facility__c);
                }
            }
            
            for(Sales_Order_Line__c sol : sols){
                
                String facilityId = locationMap.containsKey(sol.Ship_From_Location__c) ? locationMap.get(sol.Ship_From_Location__c).Facility__c : null;
                String itemId = productMap.containsKey(sol.Product__c) ?  productMap.get(sol.Product__c).Item__c : null;
                
                sol.Standard_Cost__c = ItemService.getActiveStandardCostDecimal(    
                                            itemIds, facilityIds, 
                                            sol.Company__c, facilityId, 
                                            system.now(), itemId 
                                       );
            }
        }
    }
    
    /** 
    * @description  Quantity backordered equals the quantity ordered minus the quantity shipped.
    *               and set the line to closed when quantity shipped >= quantity ordered
    */
    
    public static void updateSalesOrderLineDetail() {
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            updateSalesOrderLineDetail(ProcessHandler.getUnprocessedRecords(trigger.new));
        }
    }
    
    // KNDY-744 - Calculate quantity backordered based on Quantity Allocated and Quantity Shipped.
    public static void updateSalesOrderLineDetail( List<Sales_Order_Line__c> newLines ) {
        
        Map<Id, Map<Id,Sales_Order_Line__c>> woStatusBySol = new map<Id,Map<Id,Sales_Order_Line__c>>();
        
        for ( Sales_Order_Line__c sol : newLines ) {
            sol.Quantity_Backordered__c = KSE.subtractDecimals(sol.Quantity_Ordered__c, KSE.addQuantityToField(sol.Quantity_Allocated__c,sol.Quantity_Shipped__c));
            
            // KNDY - 1476
            sol.Quantity_Fulfilled__c = sol.Quantity_Fulfilled__c == null ? 0 : sol.Quantity_Fulfilled__c;
            if ( sol.Status__c == 'Open' && sol.Usage_Based__c != TRUE && (sol.Quantity_Fulfilled__c >=  MATH.abs(sol.Quantity_Ordered__c)) ) {
                sol.Status__c = 'Closed';
            }
            
            if( sol.Work_Order__c != null ){
                Sales_Order_Line__c oldSOLine;
                if( trigger.oldMap != null &&  trigger.oldMap.containsKey(sol.Id) ){
                    oldSOLine = (Sales_Order_Line__c)trigger.oldMap.get(sol.Id);
                }
                
                if(trigger.isUpdate && oldSOLine != null && ((sol.Status__c == 'Open' && oldSOLine.Status__c == 'Closed')
                    || ((sol.Status__c == 'Closed' || sol.Status__c == 'Cancelled') && (oldSOLine.Status__c == 'Open' || oldSOLine.Status__c == 'Draft') ))){
                    if ( !woStatusBySol.containsKey(sol.Work_Order__c) ) {
                        woStatusBySol.put(sol.Work_Order__c, new Map<Id,Sales_Order_Line__c>());
                    }
                    woStatusBySol.get(sol.Work_Order__c).put(sol.Id, sol);
                }
                    
            }
        }
        
        if(woStatusBySol.keySet().size() > 0){
            WorkOrderService.updateWOStatuses( woStatusBySol );
        }
    }
    
    /** 
     * @description  called from sales order lines trigger when inserting new records,
     * task is to set the line numbers on each record
     */
    public static void setLineNumbers() {
        if(trigger.isBefore) { 

            Boolean setLineNumbers = false;
            if(trigger.isInsert){

                setLineNumbers = true;

            } else if(trigger.isUpdate){

                setLineNumbers = false;
            
                for(Sales_Order_Line__c soLine: (list<Sales_Order_Line__c>)trigger.new) {
                    if(KSE.isFieldChanging('Line__c',soLine,trigger.oldMap)){
                        setLineNumbers = true;
                        break;
                    }    
                }
            }

            if(setLineNumbers){
                List<SObject> soLines = KSE.setLineNumbers((List<SObject>)trigger.new);
            }
        }
    }
    

    
    // KNDY-1230: Close sales order after all the sales order lines are closed.         
    public static Set<Id> sosBeingReleased = new Set<Id>(); // populated on SO release
    public static void updateSalesOrderStatus(){
        if(trigger.isAfter){
            //
            Set<Id> soIdSet = new Set<Id>();
            list<Sales_Order_Line__c> solList;
            if (trigger.isDelete){
                solList = (list<Sales_Order_Line__c>) trigger.old;

                for ( Sales_Order_Line__c obj : solList) {
                    soIdSet.add(obj.Sales_Order__c);
                }
            } else {
                solList = (list<Sales_Order_Line__c>)trigger.new;
                // dont run a query unless there is a status change on the lines we see in trigger.new
                for ( Sales_Order_Line__c obj : solList) {
                    
                    // ignore inserted draft lines
                    if ( KSE.isFieldChanging('Status__c',obj,trigger.oldMap) == true ){
                        if (!(trigger.oldMap == null && obj.Status__c == 'Draft') // no new lines that are draft since that will alwys be in draft
                        && !(trigger.oldMap != null && trigger.oldMap.get(obj.id).get('status__c') == 'Draft' && obj.Status__c == 'Open' && sosBeingReleased.contains(obj.Sales_Order__c)) // avoid updating SO that are already getting updated on release.
                        ){ 
                            soIdSet.add(obj.Sales_Order__c);
                        }

                        // clear sosBeingReleased lists for tests after the SOL is created.
                        if (obj.Status__c == 'Open' && trigger.oldMap != null && trigger.oldMap.get(obj.id).get('Status__c') == 'Draft' && sosBeingReleased.contains(obj.Sales_Order__c) && !sosBeingReleased.isEmpty()){
                            sosBeingReleased = new Set<Id>(); // empty it
                        }
                    }
                }
            }
            if( !soIdSet.isEmpty() ){
                updateSalesOrderStatus(soIdSet);
            }
        } 
    }

    private static void updateSalesOrderStatus(Set<Id> soIdSet){

        if(soIdSet.size() != 0){
            List<Sales_Order__c> salesOrdersStatusToUpdate = new List<Sales_Order__c>();

            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            
            SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Status__c'
            });
            soql.setWhereClause('id IN :soIdSet');
            
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Sales_Order_Lines__r');
            childRel.addFields(new set<string>{
                'Id','Status__c'
            });
            soql.addChildRelationship(childRel);

            for(Sales_Order__c so : Database.query(soql.getQuery())){
                
                //OTC-875 - used if there are 250+ lines
                Boolean hasSalesOrderLines = false;

                for(Sales_Order_Line__c soLine: so.Sales_Order_Lines__r){
                    hasSalesOrderLines = true;
                    break;

                }

                // Decide the status of the Sales Order based on the status of all the SO lines                                              
                if(hasSalesOrderLines){
                    Integer draftLines = 0;
                    Integer closedLines = 0;
                    Integer cancelledLines = 0;
                    Integer totalLines = 0; 

                    for(Sales_Order_Line__c soLine : so.Sales_Order_Lines__r){

                        totalLines = totalLines + 1;
                        if (soLine.Status__c == 'Draft'){
                            draftLines += 1;
                        }
                        if(soLine.Status__c == 'Closed'){
                            closedLines += 1;
                        }

                        if(soLine.Status__c == 'Cancelled'){
                            cancelledLines += 1;
                        }
                    }
                    
                    if(closedLines + cancelledLines == totalLines && closedLines > 0){

                        if (so.Status__c == 'Closed') continue;
                        so.Status__c = 'Closed';
                        salesOrdersStatusToUpdate.add(so);
                    
                    } else if (draftLines + cancelledLines == totalLines && draftLines > 0){

                        if (so.Status__c == 'Draft') continue;
                        so.Status__c = 'Draft';
                        salesOrdersStatusToUpdate.add(so);

                    } else if (cancelledLines == totalLines){ // && cancelledLines > 0 && closedLines == 0
                        
                        if (so.Status__c == 'Cancelled') continue;
                        so.Status__c = 'Cancelled';
                        salesOrdersStatusToUpdate.add(so);
                        
                    } else {
                        
                        if (so.Status__c == 'Open') continue;
                        so.Status__c = 'Open';
                        salesOrdersStatusToUpdate.add(so);
                    }
                }
            }

            if(salesOrdersStatusToUpdate.size() > 0){
                DML.updateAsUser(salesOrdersStatusToUpdate);
            }
        }

    }
    
    public static void manageSkids(){
        
        // Delete skids with type SO Demand
        
        if(trigger.isBefore && trigger.isDelete){
            SKIDService.deleteSkids(trigger.oldMap, SKIDService.SKID_TYPE_SO_DEMAND);
        }
        
        if(trigger.isAfter && trigger.isUpdate){
            // KNDY-1353: Create demand skids when the sales order lines changes from "Draft" to "Open"
            Map<Id, Sales_Order_Line__c> solMap = new Map<Id, Sales_Order_Line__c>();   
            
            // Find out which orders are moving from draft --> open
            for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) ProcessHandler.getUnprocessedRecords(trigger.new)){
                if(trigger.oldMap.get(sol.Id).get('Status__c') == 'Draft' && sol.Status__c == 'Open'){
                    solMap.put(sol.Id, sol);
                }
            }
            
            if(solMap.size() > 0){
                SKIDService.insertSkids(solMap, SKIDService.SKID_TYPE_SO_DEMAND, new map<Id,Id>());
            }
            
            // Update demand skids that have already been created with the changes in lines
            SKIDService.updateSkids(trigger.oldMap, trigger.newMap, SKIDService.SKID_TYPE_SO_DEMAND, new map<Id,Id>());
        }
    }
    
    public static void calculateRollupFields(){
        List<Sales_Order_Line__c> soLinesToRollUp = new List<Sales_Order_Line__c>();
        
        if ( trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUnDelete)){
            
            for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.new) {
                if( trigger.isInsert || trigger.isUnDelete){
                    soLinesToRollUp.add(sol);
                }
                else 
                if( trigger.isUpdate ){
                    Sales_Order_Line__c oldSOL = (Sales_Order_Line__c) trigger.oldMap.get(sol.Id);
                    
                    if (sol.Product__c != null 
                        && 
                        (sol.Product__c != oldSOL.Product__c || 
                         sol.Quantity_Ordered__c!= oldSOL.Quantity_Ordered__c
                        )
                        && 
                        sol.Status__c != 'Closed' 
                        && 
                        sol.Status__c != 'Cancelled' ) {
                            
                        soLinesToRollUp.add(sol);   
                    }
                    else 
                    if (sol.Quantity_Ordered__c != oldSOL.Quantity_Ordered__c) {
                        soLinesToRollUp.add(sol);   
                    }  
                }
                
            }
        }
        else
        if( trigger.isDelete ){
            soLinesToRollUp.addAll((List<Sales_Order_Line__c>) trigger.old);
        }
        
        if( !soLinesToRollUp.isEmpty() ){
            calculateRollupFields(soLinesToRollUp);
        }
    }
    
    public static void calculateRollupFields(List<Sales_Order_Line__c> soLines){
        list<RollUpSummaryUtility.fieldDefinition> fieldDefinitions =  new list<RollUpSummaryUtility.fieldDefinition> {
            //new RollUpSummaryUtility.fieldDefinition('SUM', 'Weight__c', 'Total_Weight__c'), //UOM Conversion  KNDY#4343 Adding Pallet Weight to Total Weight on SO.
            new RollUpSummaryUtility.fieldDefinition('SUM', 'Volume__c', 'Total_Order_Volume__c'),
            new RollUpSummaryUtility.fieldDefinition('SUM', 'Number_of_pallets__c', 'Number_of_pallets__c'),
            new RollUpSummaryUtility.fieldDefinition('SUM', 'Number_of_Floor_Spaces__c', 'Number_of_Floor_Spaces__c')
        };
        
        RollUpSummaryUtility.rollUpTrigger( fieldDefinitions, soLines, 'Sales_Order_Line__c', 'Sales_Order__c', 'Sales_Order__c', '');
    }
    
    /*********************************  ORDER QUANTITY METHODS ***************************************/
    
    // KNDY 3229
    public static void evenifyOrderQuantity(Sales_Order_Line__c soLine, Product__c prod, String orderQuantityFactorAt) {
        Long unitFactor = null;
        Long orderQty = soLine.Quantity_Ordered__c.longValue();
        
        exService.clearException(soLine, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION);
        
        if (orderQuantityFactorAt == 'Layer' && prod.Units_per_Layer__c > 0) {
            unitFactor = prod.Units_per_Layer__c.longValue();
        }
    
        if (orderQuantityFactorAt == 'Pallet' && prod.Units_per_Pallet__c > 0) {
            unitFactor = prod.Units_per_Pallet__c.longValue();
        }
        if (unitFactor != null && unitFactor > 0) {
            Long remainder =  Math.mod(orderQty, unitFactor);
            if (remainder > 0) {
                if (remainder < (unitFactor - remainder)) {
                    orderQty -= remainder; 
                    // if order qty is too small after rounding, making it unit factor
                    if (orderQty <= 0) orderQty = unitFactor;
                } else {
                    orderQty += unitFactor - remainder; 
                }
                soLine.Quantity_Ordered__c = orderQty;
            }
        }
    }

    /**
        KNDY-2891 
        Verifies if the Sales order line quantity is even with Product quantity
    */
    public static Boolean hasMinOrderQuantityException(Sales_Order_Line__c soLine, Product__c prod, String orderQuantityFactorAt) {
        Boolean hasMinOrderQuantityException = false;
        
        if (prod == null) return hasMinOrderQuantityException;
            
        if (orderQuantityFactorAt == 'Layer' && prod.Units_per_Layer__c > 0) {
            if (soLine.Quantity_Ordered__c > 0) {
                hasMinOrderQuantityException = Math.mod(soLine.Quantity_Ordered__c.longValue(), prod.Units_per_Layer__c.longValue()) != 0;    
            } else {
                hasMinOrderQuantityException = true; // A quantity should be there as product requires a minimum quantity
            }                
        }
    
        if (orderQuantityFactorAt == 'Pallet' && prod.Units_per_Pallet__c > 0) {
            if (soLine.Quantity_Ordered__c > 0) {
                hasMinOrderQuantityException = Math.mod(soLine.Quantity_Ordered__c.longValue(), prod.Units_per_Pallet__c.longValue()) != 0;    
            } else {
                hasMinOrderQuantityException = true; // A quantity should be there as product requires a minimum quantity
            }                
        }

        return hasMinOrderQuantityException;
    }
    
    //KNDY-3220 : Refire SO Quantity validations when customer changes on salesorder level   
    public static void  updateSalesOrderLineForQuantityFactorValidationsForSalesOrderIds(Set<Id> soIds) {                
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Sales_Order__c','Quantity_Ordered__c','Sales_Order__r.Customer__r.Order_Quantity_Factor_At__c','Sales_Order__r.Customer__r.Make_Order_Quantity_Even_With_Factor__c',
            'Product__c','Product__r.Units_per_Layer__c','Product__r.Units_per_Pallet__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
        });
        soql.setWhereClause('Sales_Order__c IN :soIds AND Status__c = \'Draft\'');

        Sales_Order_Line__c[] sols = Database.query(soql.getQuery());

        updateSalesOrderLineForQuantityFactorValidations(sols);                                                    
    }
       
    //KNDY-3220 : Refire SO Quantity validations when customer's field "Order_Quantity_Factor_At__c" is changed
    public static void  updateSalesOrderLineForQuantityFactorValidationsForCustomerIds(Set<Id> customerIds) {                
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Sales_Order__c','Quantity_Ordered__c','Sales_Order__r.Customer__r.Order_Quantity_Factor_At__c','Sales_Order__r.Customer__r.Make_Order_Quantity_Even_With_Factor__c',
            'Product__c','Product__r.Units_per_Layer__c','Product__r.Units_per_Pallet__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
        });
        soql.setWhereClause('Sales_Order__r.Customer__c IN :customerIds AND Status__c = \'Draft\'');
        
        Sales_Order_Line__c[] sols = Database.query(soql.getQuery());

        updateSalesOrderLineForQuantityFactorValidations(sols);                                                    
    }
    
    /*
        Utility method which update SO Lines having any changes in Order Factor exceptions
    */
    static void updateSalesOrderLineForQuantityFactorValidations(Sales_Order_Line__c[] sols) {
        Sales_Order_Line__c[] solsToUpdate = new Sales_Order_Line__c[]{};

        Set <id> soSet = KSE.grepRelatedIdSetFromList(sols, 'Sales_Order__c', true);        
        Map<id,Sales_Order__c> soMap = new Map<id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soSet));

        for ( Sales_Order_Line__c sol : sols) {      
            Sales_order__c sOrder = soMap.get(sol.Sales_order__c);
            if(SalesOrderService.STANDARD_ORDER_TYPES.contains(sOrder.Type__c)){                   
                Decimal oldOrderQty = sol.Quantity_Ordered__c;
                
                String orderFactorField = sol.Sales_Order__r.Customer__r.Order_Quantity_Factor_At__c;
                if (sol.Sales_Order__r.Customer__r.Make_Order_Quantity_Even_With_Factor__c && !String.isBlank(orderFactorField)) {
                    // KNDY-3229 evenify orders if enabled for a customer
                    evenifyOrderQuantity(sol, sol.Product__r, orderFactorField) ;

                    if (oldOrderQty != sol.Quantity_Ordered__c) {
                        // save unecessary updates and do only when really needed i.e. in case of change
                        solsToUpdate.add(sol);
                    }

                } else if (!String.isBlank(orderFactorField)) {
                    // OTC-381
                    Integer orderFactor = 1;
                    
                    if(orderFactorField == 'Layer'){
                        orderFactor = (Integer) KSE.addQuantityToField(sol.Product__r.Units_per_Layer__c, 0);
                    }
                    else
                    if(orderFactorField == 'Pallet'){
                        orderFactor = (Integer) KSE.addQuantityToField(sol.Product__r.Units_per_Pallet__c, 0);
                    }
                    
                    if(orderFactor > 0){
                        Integer abs = (Integer) (sol.Quantity_Ordered__c / orderFactor) ;
                        Integer lowerQuantity = (Integer) (abs * orderFactor) ;
                        Integer upperQuantity = (Integer) ((abs + 1) * orderFactor) ;   
                        ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.description = 'Please order in multiples of \'' + orderFactor + '\'.';
                        ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.description += 'The closest multiples are \'' + lowerQuantity + '\' and \'' + upperQuantity + '\'.'; 
                    }
                      
                    if (hasMinOrderQuantityException(sol, sol.Product__r, orderFactorField)) {
                        exService.setException(sol, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION);
                    } else {
                        exService.clearException(sol, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION);
                    }                          
                } else {
                    exService.clearException(sol, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION);
                }
            }
        }  

        if (!solsToUpdate.isEmpty()) {
            // KNDY-3590
            DML.updateAsUser(solsToUpdate);
        }        
    }
    
    
    /**
     * @description 
     * KNDY-2891 
     * Validates Sales Order lines, if they have minimum quantity exceptions. This validation kicks off only
     * if SOLD-TO customer in SO requires the same i.e. Customer > "Require Order Quantity Factor" field set to TRUE
     *   
    */
    
    public static void validateSalesOrderLineQuantities() {
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
            
            List<Sales_Order_Line__c> soLinesForQtyValidations = new List<Sales_Order_Line__c>();
            
            for( Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) ProcessHandler.getUnprocessedRecords(trigger.new)) {
                //If Quantity field is empty then add error and continue to process the next Sales Order Line
                if(sol.Quantity_Ordered__c == null){
                    sol.addError ('Quantity field is empty');
                    continue;
                }
                if( trigger.isInsert ||
                    ( trigger.isUpdate && 
                      ( KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap) ||
                        KSE.isFieldChanging('Product__c', sol, trigger.oldMap)
                      )
                    ) 
                ){
                    soLinesForQtyValidations.add(sol);                    
                }   
            }
            
            if (!soLinesForQtyValidations.isEmpty()) {
                SalesOrderLineService.validateSalesOrderLineQuantities( soLinesForQtyValidations ); 
            }
        }
    }   
     
    public static void validateSalesOrderLineQuantities( List<Sales_Order_Line__c> newLines ) {                

        Set <id> soSet = KSE.grepRelatedIdSetFromList(newLines, 'Sales_Order__c', true);        
        Map<id,Sales_Order__c> soMap = new Map<id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soSet));
        
        List<Sales_Order_Line__c> relevantSOLines = new List<Sales_Order_Line__c>();
        Set <Id> productIds = new Set<Id>();
        
        for ( Sales_Order_Line__c sol : newLines ) {
            Sales_Order__c sOrder = soMap.get(sol.Sales_Order__c);
                            
            if (sOrder != null && sOrder.Customer__r != null && SalesOrderService.STANDARD_ORDER_TYPES.contains(sOrder.Type__c) &&
                // Either raise order quantity exceptions or evenify the values
                ( !String.isBlank(sOrder.Customer__r.Order_Quantity_Factor_At__c) || sOrder.Customer__r.Make_Order_Quantity_Even_With_Factor__c)
                ){                    
                relevantSOLines.add(sol);
                productIds.add( sol.Product__c );
            }
        }
        
        // No SO line's SOLD TO customer is having validation enabled, so no sense in processing further
        if (relevantSOLines.isEmpty()) {
            return;
        }
        
        // Do this SQOL now as we have some SO Lines to validate against
        Map<Id, Product__c> productMap = new Map<Id, Product__c>(SalesOrderFlowCache.cachedProductsForIds(productIds));
        
        for ( Sales_Order_Line__c sol : relevantSOLines ) {
            
            
            Product__c product = productMap.get(sol.Product__c);     
            Sales_Order__c sOrder = soMap.get(sol.Sales_Order__c);
            String orderFactorField = sOrder.Customer__r.Order_Quantity_Factor_At__c;
            
            if (sOrder.Customer__r.Make_Order_Quantity_Even_With_Factor__c && !String.isBlank(orderFactorField)) {
                // KNDY-3229 evenify orders if enabled for a customer
                evenifyOrderQuantity(sol, product, orderFactorField) ;
            } else if (!String.isBlank(orderFactorField)) {
                // OTC-381
                Integer orderFactor = 1;
                
                if(orderFactorField == 'Layer'){
                    orderFactor = (Integer) KSE.addQuantityToField(sol.Product__r.Units_per_Layer__c, 0);
                }
                else
                if(orderFactorField == 'Pallet'){
                    orderFactor = (Integer) KSE.addQuantityToField(sol.Product__r.Units_per_Pallet__c, 0);
                }
                
                if(orderFactor > 0){
                    Integer abs = (Integer) (sol.Quantity_Ordered__c / orderFactor) ;
                    Integer lowerQuantity = (Integer) (abs * orderFactor) ;
                    Integer upperQuantity = (Integer) ((abs + 1) * orderFactor) ;   
                    ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.description = 'Please order in multiples of \'' + orderFactor + '\'.';
                    ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION.description += 'The closest multiples are \'' + lowerQuantity + '\' and \'' + upperQuantity + '\'.'; 
                }
                  
                if (hasMinOrderQuantityException(sol, product, orderFactorField)) {
                    exService.setException(sol, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION);
                } else {
                    exService.clearException(sol, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION);
                }                         
            } else {
                exService.clearException(sol, ExceptionUtil.SO_LINE_MIN_ORDER_QTY_EXCEPTION);
            }
        }        
    }
    
    /*********************************  MEANS OF TRANSPORT METHODS ***************************************/
    
    /*
    *   Determine the best means of transport to ship goods from facility to the customer.
    */
    
    public static void setMeansOfTransport() {
        // called from the Sales Order Line Trigger
        if(trigger.isBefore){
            if ( trigger.isInsert || trigger.isUpdate || trigger.isUnDelete){
                List<Sales_Order_Line__c> salesOrderIdsWithoutMoT = new List<Sales_Order_Line__c>();
                for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) ProcessHandler.getUnprocessedRecords(trigger.new)){
                    if(trigger.isInsert ||
                        (trigger.isUpdate && KSE.isFieldChanging('Ship_From_Location__c', sol, trigger.oldMap))){
                        salesOrderIdsWithoutMoT.add(sol);
                    }
                }
                
                if(salesOrderIdsWithoutMoT.size() > 0){
                    SalesOrderLineService.setMeansOfTransport(salesOrderIdsWithoutMoT);
                }
            }
        }
    }
    
    public static void setMeansOfTransport(List<Sales_Order_Line__c> salesOrderLines){
        
        // used for retrieving Maps of Sales Order Info and Location info
        Set<id> locationId = new Set<id>();
        Set<id> soId = new Set<id>();
        
        Map<Id, Sales_Order_Line__c> solBySoMap = new Map<Id, Sales_Order_Line__c>(); // used below to get Sol address for MoT population
        
        for (Sales_order_Line__c sol : salesOrderLines){
            if (sol.Ship_From_Location__c != null){
                locationId.add(sol.Ship_From_Location__c);
            }
            if (sol.Sales_Order__c != null){
                soId.add(sol.Sales_Order__c);
                solBySoMap.put(sol.sales_order__c, sol); 
            }
        }
         
        // used for Transit Route key. Record populated to SOL trigger list      
        Map<Id, Location__c> solLocs = new Map<Id, Location__c>(SalesOrderFlowCache.cachedLocationsForIds(locationId));
        Map<Id, Sales_Order__c> soMap = new Map<Id, Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soId));

        Set<Id> shipFromLocations = new Set<Id>();
        Set<Id> shipToLocation = new Set<Id>();

        for (Sales_order_Line__c sol : salesOrderLines){
            if (solLocs.containsKey(sol.Ship_From_Location__c)){
                if (solLocs.get(sol.Ship_From_Location__c).Facility__r.Address__c != null){
                    shipFromLocations.add(solLocs.get(sol.Ship_From_Location__c).Facility__r.Address__c);
                }
            }
            if (soMap.containsKey(sol.Sales_Order__c)){
                if (soMap.get(sol.Sales_Order__c).Ship_To__r.Address__c != null){
                    shipToLocation.add(soMap.get(sol.Sales_Order__c).Ship_To__r.Address__c);
                }
            }
        }

        setMeansOfTransport(shipFromLocations, shipToLocation, soMap, solBySoMap, solLocs);
    }
//
    public static void setMeansOfTransport(Set<Id> shipFromLocations, Set<Id> shipToLocation, Map<Id, Sales_order__c> soMap, Map<Id, Sales_Order_Line__c> solBySoMap, Map<Id, Location__c> solLocs){
        if(shipFromLocations.size() > 0 && shipToLocation.size() > 0 ){
            Map<String, List<Transit_Route__c>> primaryTransitRoutesMap = new Map<String, List<Transit_Route__c>>();
            Map<String, List<Transit_Route__c>> secondaryTransitRoutesMap = new Map<String, List<Transit_Route__c>>();
            
            // Populate primary and secondary transit route maps 
            for(Transit_Route__c transitRoute : TransitRouteService.getTransitRoutes(shipFromLocations, shipToLocation)){
                String transitRouteKey = '' + transitRoute.Origin__c + transitRoute.Destination__c;
                                    
                if(transitRoute.Primary__c == true){
                    if(primaryTransitRoutesMap.containsKey(transitRouteKey) == false){
                        primaryTransitRoutesMap.put(transitRouteKey, new List<Transit_Route__c>());
                    }
                    primaryTransitRoutesMap.get(transitRouteKey).add(transitRoute);
                }else{
                    if(secondaryTransitRoutesMap.containsKey(transitRouteKey) == false){
                        secondaryTransitRoutesMap.put(transitRouteKey, new List<Transit_Route__c>());
                    }
                    secondaryTransitRoutesMap.get(transitRouteKey).add(transitRoute);
                }
            }

            // Assign the best transit route available for the sales order.
            // Primary routes takes precedence to secondary routes. 
            Map<Id, Sales_Order__c> updatedSOMap = new Map<Id, Sales_Order__c>(); 
            for(Sales_order__c salesOrder : soMap.values()){
                if(salesOrder.Means_of_Transport__c == null){
                    String transitRouteKey;
                    if (solBySoMap != null && solLocs != null){
                        if (solBySoMap.containsKey(salesOrder.id)){
                            if (solBySoMap.get(salesOrder.id).Ship_From_Location__c != null){
                                if (solLocs.containsKey(solBySoMap.get(salesOrder.id).Ship_From_Location__c)) {
                                    transitRouteKey = '' + solLocs.get(solBySoMap.get(salesOrder.id).Ship_From_Location__c).Facility__r.Address__c + salesOrder.Ship_To__r.Address__c;
                                }
                            }
                        }
                    } else if (solBySoMap == null && solLocs == null){
                        transitRouteKey = '' + salesOrder.Sales_Order_Lines__r[0].Ship_From_Location__r.Facility__r.Address__c + salesOrder.Ship_To__r.Address__c;
                    }
                    
                    if(primaryTransitRoutesMap.containsKey(transitRouteKey) && primaryTransitRoutesMap.get(transitRouteKey).size() > 0){
                        if(primaryTransitRoutesMap.get(transitRouteKey).size() > 1){
                            throw new SalesOrderLineException('More than one matching primary transit routes found for the sales order.');
                        }else{
                            salesOrder.Means_of_Transport__c = primaryTransitRoutesMap.get(transitRouteKey)[0].Means_of_Transport__c;
                            if(primaryTransitRoutesMap.get(transitRouteKey)[0].Delivery_Method__c != null)
                                salesOrder.Delivery_Method__c = primaryTransitRoutesMap.get(transitRouteKey)[0].Delivery_Method__c; //KNDY#4843
                            
                            updatedSOMap.put(salesOrder.Id, salesOrder);
                        }
                    }
                    else
                    if(secondaryTransitRoutesMap.containsKey(transitRouteKey) && secondaryTransitRoutesMap.get(transitRouteKey).size() > 0){
                        if(secondaryTransitRoutesMap.get(transitRouteKey).size() > 1){
                            throw new SalesOrderLineException('More than one matching secondary transit routes found for the sales order.');
                        }else{
                            salesOrder.Means_of_Transport__c = secondaryTransitRoutesMap.get(transitRouteKey)[0].Means_of_Transport__c;
                            if(secondaryTransitRoutesMap.get(transitRouteKey)[0].Delivery_Method__c != null)
                                salesOrder.Delivery_Method__c = secondaryTransitRoutesMap.get(transitRouteKey)[0].Delivery_Method__c; //KNDY#4843
                            
                            updatedSOMap.put(salesOrder.Id, salesOrder);
                        }
                    }
                }
            }
            
            //system.debug(logginglevel.info, 'updatedSOMap: ' + updatedSOMap);
            if(updatedSOMap.values().size() > 0){
                DML.updateAsUser(updatedSOMap.values());
            }
        }
    }

    public static void setMeansOfTransport(Set<Id> salesOrderIds) {
        // retrieved from the Sales Order Trigger when MoT or Ship From Customer is changed.
        if(salesOrderIds.size() > 0){
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            
            SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Ship_To__r.Address__c','Ship_To__r.Lead_time__c','Ship_To__r.Earliest_Delivery_Window__c','Ship_To__r.Latest_Delivery_Window__c',
                'Means_of_Transport__c','Required_date__c'
            });
            soql.setWhereClause('Id IN :salesOrderIds');
            
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Sales_Order_Lines__r');
            childRel.addFields(new set<string>{
                'Id','Ship_From_Location__r.Facility__r.Address__c','Ship_From_Location__r.Facility__r.Enable_Transit_Route_Optimization__c',
                'Ship_From_Location__r.Facility__r.Shipping_Calendar__c','Ship_From_Location__r.Facility__r.Lead_time__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
            });
            soql.addChildRelationship(childRel);

            Map<Id, Sales_Order__c> soMap = new Map<Id, Sales_Order__c>((List<Sales_Order__c>)Database.query(soql.getQuery()));
            
            Set<Id> shipFromAddresses = new Set<Id>();
            Set<Id> shipToAddresses = new Set<Id>();
            
            for(Id salesOrderId : salesOrderIds){
                Sales_Order__c salesOrder = soMap.get(salesOrderId);
                
                if(salesOrder.Means_of_Transport__c == null){
                    if(salesOrder.Sales_Order_Lines__r != null && salesOrder.Sales_Order_Lines__r.size() > 0){
                        shipFromAddresses.add(salesOrder.Sales_Order_Lines__r[0].Ship_From_Location__r.Facility__r.Address__c);
                    }
                    
                    if(shipToAddresses.add(salesOrder.Ship_To__r.Address__c) != null){
                        shipToAddresses.add(salesOrder.Ship_To__r.Address__c);
                    }
                }
            }
            
            setMeansOfTransport(shipFromAddresses, shipToAddresses, soMap, null, null);
        }
    }

    public static void setEstimatedShipDate(){
        list<Sales_order_Line__c> solToUpdate = new List<Sales_order_Line__c>();
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate || trigger.isUnDelete)) { 
            for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) processHandler.getUnprocessedRecords(trigger.new)) {
                if (KSE.isFieldChanging('Required_Date__c', sol, trigger.oldMap )
                    || KSE.isFieldChanging('Ship_From_Location__c',sol, trigger.oldMap)
                    ||  sol.Ordered_Date_Time__c == null){
                    solToUpdate.add(sol);
                }
            }
        }
        
        if (!solToUpdate.isEmpty()){
            setEstimatedShipDate(solToUpdate);
        }
    }

    public static void setEstimatedShipDate(List<Sales_Order_Line__c> soLines){
        // soLines  come from SOL before insert
        if (soLines.isEmpty())
            return;

        Set<Id> locIds = new Set<Id>();
        Set<Id> soIds = new Set<Id>();

        for (Sales_order_Line__c sol : soLines){
            if (sol.Ship_From_Location__c != null){
                locIds.add(sol.Ship_From_Location__c);
            }
            if (sol.Sales_Order__c != null){
                soIds.add(sol.Sales_Order__c);
            }
        }

        Map<id,Location__c> locationMap = new Map<Id, Location__c>(SalesOrderFlowCache.cachedLocationsForIds(locIds));
        Map<id,Sales_Order__c> soMap = new Map<Id, Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soIds));

        for (Sales_order_Line__c sol : soLines){
            if (sol.Ship_From_Location__c != null){
                sol.Ship_From_Location__r = locationMap.get(sol.Ship_From_Location__c);
            }
            if (sol.Sales_Order__c != null){
                sol.Sales_Order__r = soMap.get(sol.Sales_Order__c);
            }
        }

        Set<Id> originIds = new Set<Id>();
        Set<Id> destinationIds = new Set<Id>();
        Set<Id> motIds = new Set<Id>();

        // K: SOL trigger, V SOL w/ RT info
        Map<Sales_Order_Line__c, Sales_Order_Line__c> solMap = new Map<Sales_Order_Line__c, Sales_Order_Line__c>();
        
        for (Sales_Order_Line__c sol : soLines){
            Sales_Order_Line__c sol2 = new Sales_Order_Line__c();

            if (sol.Ordered_Date_Time__c == null){
                if (sol.Sales_Order__r.Date_Time_Ordered__c == null){
                    sol.Ordered_Date_Time__c = system.now();
                } else {
                    sol.Ordered_Date_Time__c = sol.Sales_Order__r.Date_Time_Ordered__c;
                }
            }
            /* KNDY-10333
            if (locationMap.containsKey(sol.Ship_From_Location__c)){
                originIds.add(locationMap.get(sol.Ship_From_Location__c).Facility__r.Address__c);
                sol2.Ship_From_Location__r = locationMap.get(sol.Ship_From_Location__c);
            }
            
            if (soMap.containsKey(sol.Sales_Order__c)){
                Sales_Order__c so = soMap.get(sol.Sales_Order__c);
                sol2.Sales_Order__r = so;
                if (so.Means_of_Transport__c != null){
                    motIds.add(so.Means_of_Transport__c);
                }
                if (so.Ship_to__r.Address__c != null){
                    destinationIds.add(so.Ship_to__r.Address__c);
                }
            }
            solMap.put(sol, sol2);
            */
        }
        
        setEstimatedShipDate(destinationIds, originIds, motIds, soLines);

    }

    // returns a list of SOL for update
    public static Map<Id, Sales_order_Line__c> setEstimatedShipDate(Set<Id> shipToLocation, Set<Id> shipFromLocations, Set<Id> mot, list<Sales_Order_line__c> solToUpdate){
        Map<Id, Sales_order_Line__c> solUpdateMap = new Map<Id, Sales_order_Line__c>();

        List<Transit_Route__c> trList;
        Map<String, Transit_Route__c> trMap = new Map<String, Transit_Route__c>();
        String key = '';
        if (!mot.isEmpty() && !shipToLocation.isEmpty() && !shipFromLocations.isEmpty()){
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            
            SOQLUtil soql = new SOQLUtil('Transit_Route__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Origin__c','Destination__c','Means_of_Transport__c','Delivery_Method__c','Transit_Time__c','Shipping_Calendar__c'
            });
            soql.setWhereClause('Origin__c in :shipFromLocations and Destination__c in :shipToLocation and Means_of_Transport__c in :mot');
            
            trList = Database.query(soql.getQuery());
            
            for (Transit_Route__c tr : trList){
                key = '' + tr.Origin__c + tr.Destination__c + tr.Means_of_Transport__c + tr.Delivery_Method__c;
                trMap.put(key, tr);
            }
        }

        for(Sales_Order_Line__c sol : solToUpdate){
            Sales_Order__c so = sol.Sales_Order__r;

            Integer routeTime;
            Id facilityCal;
            if (sol.Ship_From_Location__r.Facility__r.Enable_Transit_Route_Optimization__c){
                String solRouteKey = ''; // KNDY-10333 + sol.Ship_From_Location__r.Facility__r.Address__c + sol.Sales_Order__r.Ship_To__r.Address__c + so.Means_of_Transport__c + so.Delivery_Method__c; // Null here
                if (trMap.containsKey(solRouteKey)){
                    Transit_route__c soRoute = trMap.get(solRouteKey); 
                    routeTime =  (Integer) KSE.addQuantityToField(soRoute.Transit_Time__c,0);
                    facilityCal = soRoute.Shipping_Calendar__c != null ? soRoute.Shipping_Calendar__c : sol.Ship_From_Location__r.Facility__r.Shipping_Calendar__c;    

                } else {
                    routeTime = 0;
                    facilityCal = sol.Ship_From_Location__r.Facility__r.Shipping_Calendar__c;
                }
            } else {
                routeTime = 0;
                facilityCal = sol.Ship_From_Location__r.Facility__r.Shipping_Calendar__c;
            }

            Date dateReq = sol.Required_date__c;

            if (dateReq != null) {
                sol.Estimated_ship_date__c = KSE.calculateStartDate(dateReq, routeTime, facilityCal);

            }else{
                // No Required Date 
                Decimal facilityLeadTime = sol.Ship_From_Location__r.Facility__r.Lead_time__c != null ? sol.Ship_From_Location__r.Facility__r.Lead_time__c: 0 ;
                Decimal customerLeadTime = so.Ship_To__r.Lead_time__c != null ? so.Ship_To__r.Lead_time__c : 0;
                Integer largerPrepTime = customerLeadTime > facilityLeadTime ? (Integer) customerLeadTime : (Integer) facilityLeadTime;

                // will retrieve today's date if facility and lead time is null. If calendar isn't null, it'll use the upcoming non-holiday date
                sol.Estimated_ship_date__c = KSE.calculateEndDate(system.today(), largerPrepTime, facilityCal); 
            }
            
            sol.Earliest_Ship_Date__c = KSE.calculateStartDate(sol.Estimated_Ship_Date__c, Integer.valueOf(sol.Sales_Order__r.Ship_To__r.Earliest_Delivery_Window__c), facilityCal);
            sol.Earliest_Ship_Date__c = KSE.convertTimeZones(sol.Earliest_Ship_Date__c, Timezone.getTimeZone('GMT'), UserInfo.getTimeZone());
            
            sol.Latest_Ship_Date__c = KSE.calculateEndDate(sol.Estimated_Ship_Date__c, Integer.valueOf(sol.Sales_Order__r.Ship_To__r.Latest_Delivery_Window__c), facilityCal);
            sol.Latest_Ship_Date__c = KSE.convertTimeZones(sol.Latest_Ship_Date__c, Timezone.getTimeZone('GMT'), UserInfo.getTimeZone());
            
            solUpdateMap.put(sol.id, sol);    
        }
        return solUpdateMap;
    }
    
    //@future
    public static void setEstimatedShipDate(set<Id> ids){
        // Ids      come from SO. 
//        System.debug(loggingLevel.Error, ' KNDY-17667 ***** ids :' + ids);
        if (ids == null || ids.isEmpty()) return;
        List<id> idList = new List<id>(ids);
        String whereClause = '';
        
       /* String query = 'SELECT Id, Ship_From_Location__r.Facility__r.Enable_Transit_Route_Optimization__c, Estimated_ship_date__c, Required_Date__c, ' +
            'Ship_From_Location__r.Facility__r.Address__c, Sales_Order__r.Ship_to__r.Address__c, Sales_Order__r.Means_of_Transport__c, Sales_Order__r.Delivery_Method__c, ' +
            'Ship_From_Location__r.Facility__r.Shipping_Calendar__c, Ship_From_Location__r.Facility__r.Lead_time__c, ' +
            'Sales_Order__r.Ship_To__r.Earliest_Delivery_Window__c, Sales_Order__r.Ship_To__r.Latest_Delivery_Window__c, ' +
            'Sales_Order__c,   Sales_Order__r.Ship_To__r.Lead_time__c ' +
            'FROM Sales_Order_line__c ';
        */
        
        if(idList[0].getSobjectType() == Sales_Order__c.getSobjectType()){ // from Sales order trigger
            whereClause =  'Sales_order__c IN :ids';
        }
        else 
            return;

        Set<String> fieldsToQuery = new Set<String>{
                                    'Id', 'Ship_From_Location__r.Facility__r.Enable_Transit_Route_Optimization__c', 'Estimated_ship_date__c', 'Required_Date__c',
                                    'Ship_From_Location__r.Facility__r.Address__c', 'Sales_Order__r.Ship_to__r.Address__c', 'Sales_Order__r.Means_of_Transport__c', 'Sales_Order__r.Delivery_Method__c',
                                    'Ship_From_Location__r.Facility__r.Shipping_Calendar__c', 'Ship_From_Location__r.Facility__r.Lead_time__c',
                                    'Sales_Order__r.Ship_To__r.Earliest_Delivery_Window__c', 'Sales_Order__r.Ship_To__r.Latest_Delivery_Window__c',
                                    'Sales_Order__c', 'Sales_Order__r.Ship_To__r.Lead_time__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
                                    };
                                    
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_line__c');
        soql.addFields(fieldsToQuery);
        soql.setWhereClause(whereClause);
        String query = soql.getQuery();
        
        
        Map<Id, Sales_Order_Line__c> solMap = new Map<Id, Sales_Order_Line__c>();
        list<Sales_Order_line__c> solQryList = Database.query(query);
        if (solQryList.isEmpty()){
            return;
        }
        for (Sales_Order_Line__c sol : solQryList){
            solMap.put(sol.id, sol);
        }

        //List<Sales_Order_Line__c> solUpdateMap = new List<Sales_Order_Line__c>();
        
        Set<Id> shipFromLocations = new set<Id>();
        Set<Id> shipToLocation = new set<Id>();
        Set<Id> mot = new set<Id>();

        for (Sales_Order_Line__c sol : solMap.values()){
            if (sol.Ship_From_Location__r.Facility__r.Address__c != null)
                shipFromLocations.add(sol.Ship_From_Location__r.Facility__r.Address__c);
            
            if (sol.Sales_Order__r.Ship_to__r.Address__c != null)
                shipToLocation.add(sol.Sales_Order__r.Ship_to__r.Address__c);
            
            if (sol.Sales_Order__r.Means_of_Transport__c != Null) 
                mot.add(sol.Sales_Order__r.Means_of_Transport__c);
        }
//        System.debug(loggingLevel.Error, ' KNDY-17667 ***** solMap :' + solMap);
        Map<Id, Sales_order_Line__c> solUpdateMap = setEstimatedShipDate(shipToLocation, shipFromLocations, mot, solMap.values());
//        System.debug(loggingLevel.Error, ' KNDY-17667 ***** solUpdateMap :' + solUpdateMap);
        //system.debug(LoggingLevel.debug, 'solUpdateMap: ' + solUpdateMap);
        
        DML.updateAsUser(solUpdateMap.values());
    }
    
    public static void validateAllocationRule(){
        List<Sales_Order_Line__c> solToUpdate = new List<Sales_Order_Line__c>();
        if(trigger.isAfter)
        {
            if(trigger.isInsert)
            {
                solToUpdate.addAll((List<Sales_Order_Line__c>) processHandler.getUnprocessedRecords(trigger.new));
            }
             if(trigger.isUpdate) {
                for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) processHandler.getUnprocessedRecords(trigger.new)) {
                    if (KSE.isFieldChanging('Estimated_Ship_Date__c', sol, trigger.oldMap) || KSE.isFieldChanging('Ship_From_Location__c', sol, trigger.oldMap) || KSE.isFieldChanging('Product__c', sol, trigger.oldMap) 
                        || KSE.isFieldChanging('Status__c', sol, trigger.oldMap) || KSE.isFieldChanging('Quantity_Ordered__c', sol, trigger.oldMap))
                    {
                        if(!(sol.Status__c == 'On Hold' )) //|| (trigger.oldmap.get(sol.Id).get('Status__c') == 'Draft' && sol.Status__c == 'Open') || (trigger.oldmap.get(sol.Id).get('Status__c') == 'Open' && sol.Status__c == 'Draft')
                          solToUpdate.add(sol);
                    }
                }
            }
            else if(trigger.isDelete)
                solToUpdate.addAll((List<Sales_Order_Line__c>) processHandler.getUnprocessedRecords(trigger.old));
            
        }
        
        if (!solToUpdate.isEmpty())
            validateAllocationRule(solToUpdate, trigger.isDelete);
    }
    
    public static void beforeDeleteValidation(){
        
        
        if(trigger.isBefore && trigger.isDelete){
            
            for(Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) trigger.old){
                
                if(sol.Status__c != 'Draft'){
                    
                    //sol.addError('Only Sales Order Lines in Draft status can be deleted.');
					sol.addError('Only Sales Order Lines in Draft status can be deleted.');
                    continue;
                }
				System.debug( logginglevel.error, '~*~ sol.Quantity_Shipped__c :' + sol.Quantity_Shipped__c );
				if (sol.Quantity_Shipped__c > 0){
					sol.addError('Cannot delete Sales Order Lines with Shipped Quantity.');
					continue;
				}
            }
            
        }
        
    }
    
    public static void validateAllocationRule(List<Sales_Order_line__c> solList, boolean isDelete){
        
        if (solList == null || solList.isEmpty()){
            return;
        }
        
       // AllocationRuleValidationRunning = true;
        Date smallestDate, biggestDate;
        
        // TO-DO: possible to optimize using a map and pass map to populateUsedAllocation to prevent SOL requery.
                
        //system.debug(soList);
        Set<Id> productIds = new Set<Id>();
        Set<Id> allocationRuleIds = new Set<Id>();
        set<Id> customerIds = new set<Id>();
        set<id> facilityids = new set<id>();
        set<Id> solIds = new set<id>();
        
        for (Sales_Order_Line__c sol : solList) {
            solIds.add(sol.Id);
            if (smallestDate == null || smallestDate < sol.Estimated_Ship_Date__c) 
                smallestDate = sol.Estimated_Ship_Date__c;
            if (biggestDate == null || biggestDate > sol.Estimated_Ship_Date__c) 
                biggestDate = sol.Estimated_Ship_Date__c;
            
            if (sol.Product__c != null) 
                productIds.add(sol.Product__c);
            if (sol.Allocation_Rule__c != null)
                allocationRuleIds.add(sol.Allocation_Rule__c);
            if(sol.Corporate_parent_Customer_ID__c != null)
                customerIds.add(sol.Corporate_parent_Customer_ID__c);
            if(sol.From_Facility_Id__c != null)
                facilityIds.add(sol.From_Facility_ID__c);
        }
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

		// ba-todo: cache this for reducing query limits in test cases
        SOQLUtil soql = new SOQLUtil('Allocation_Rule__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Start_Date__c','Product__c','Allocation_Used__c','End_Date__c','Company__c','Customer__c','Facility__c','Allocation__c'
        });
        soql.setWhereClause('(Id IN :allocationRuleIds OR ( ( (Start_Date__c <= :smallestDate AND End_Date__c >=: smallestDate) OR '
                            +' (Start_Date__c >= :smallestDate AND Start_Date__c <=: biggestDate) OR (Start_Date__c <= :biggestDate AND End_Date__c >=: biggestDate) ) '
                            +' AND Product__c IN :productIds AND Customer__c IN :customerIds AND Facility__c IN :facilityIds ))');
                            
        Map<Id, Allocation_Rule__c> allocRulesById = new Map<Id, Allocation_Rule__c>((List<Allocation_Rule__c>)Database.query(soql.getQuery()));
    
        system.debug('inside sol service: allocRulesById- '+allocRulesById);
        if (allocRulesById.isEmpty()) {
            //System.debug(LoggingLevel.WARN, '### No allocation rules found for critera >   productIds :' + productIds + ' smallestDate :' + smallestDate + ' biggestDate:' + biggestDate);
            return;
        }                       
        
        List<Allocation_Rule__c> allocRulesClone = new List<Allocation_Rule__c>();
        for (Allocation_Rule__c ar : allocRulesById.values()) {
            allocRulesClone.add(ar.clone(true));
        }
        system.debug('inside sol service: allocRulesClone- '+allocRulesClone);
        AllocationRuleService.populateUsedAllocation(allocRulesClone, solIds, isDelete);                                            
        
        List<Allocation_Rule__c> allocRulesForUpdate = new  List<Allocation_Rule__c>();
        for (Allocation_Rule__c ar : allocRulesClone) {
            // compare and see if value is changed
            if (ar.Allocation_Used__c != allocRulesById.get(ar.Id).Allocation_Used__c) {
                System.debug(LoggingLevel.INFO, '### Allocation Rule ' + ar.Name 
                    + ' changed used allocation from ' + allocRulesById.get(ar.Id).Allocation_Used__c 
                    + ' to ' + ar.Allocation_Used__c);
                allocRulesForUpdate.add(ar);
            }
        }
         
        if (!allocRulesForUpdate.isEmpty() ){ 
            // KNDY-3590
            DML.updateAsUser(allocRulesForUpdate);
        }
        
    }

    public static Set<Id> findMatchingPBLSOL(Pricebook_Line__c[] pblList){
        // Takes a list of PBL that are being updated, finds related SOLs and returns the Id Set of PBLs that match with related SOLs
        // used to clear PBL bracket pricing & to expire PBLs

        Set<id> pblIds = KSE.grepIdSetFromList(pblList);

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Pricebook_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Pricebook__c','Pricebook__r.Default__c','Min__c','Max__c','Price__c','Price_2__c','Price_3__c','Price_4__c','Price_5__c',
            'Product__c','Use_Fixed_Pricing__c','Customer__c','Pricebook__r.Name','Pricebook__r.Currency__c','Pricebook__r.Company__c',
            'Product_Group__c','Start_Date__c','End_Date__c'
        });
        soql.setWhereClause('ID IN :pblIds');

        pblList = Database.query(soql.getQuery());
        
        System.debug(loggingLevel.Error, '*** pblList: ' + pblList);
        //PricebookLineMatcher pbMatcher = new PricebookLineMatcher(pblList);

        Date startDate, endDate;
        Set<Id> uniqueProducts = new Set<Id>();
        Set<Id> uniquePricebooks = new Set<Id>();
        Set<Id> uniqueProductGroup = new Set<Id>();

        for (Pricebook_Line__c pbl : pblList) {
            if (startDate == null || startDate > pbl.Start_Date__c){
                startDate = pbl.Start_Date__c;
            }
            if (endDate == null || endDate < pbl.End_Date__c){
                endDate = pbl.End_Date__c;
            }
            
            uniquePricebooks.add(pbl.Pricebook__c);

            if(pbl.Product__c != null){

                uniqueProducts.add(pbl.Product__c);
            } else {

                uniqueProductGroup.add(pbl.Product_Group__c);
            }
        }


        Set<Id> productSOLMatch = new Set<Id>();
        // Prepare this for Price determination date: order and look only at SOL line for PDD: Order

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        String PRICE_DET_ORDER = SalesOrderService.PRICE_DET_ORDER;
        
        soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Product__r.Id','Pricebook__c','Product__r.Product_Group__c','sales_order__r.Company__c', 'sales_order__r.Pricebook__c', 'sales_order__r.Customer__c',
            'sales_order__r.Customer__r.Pricebook__c', 'sales_order__r.Customer__r.Customer_Group__c', 'Ordered_Date_Time__c','Quantity_Ordered__c', 'Line__c',
            'Sales_Order__r.Pricing_Date__c','Sales_Order__r.Price_Determination_Date__c','Sales_Order__r.Currency__c','Currency__c', 'Agreement_Line__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
        });
        soql.setWhereClause('(Product__c IN :uniqueProducts OR Product__r.Product_Group__c in :uniqueProductGroup) AND Pricebook__c IN :uniquePricebooks '
                            +' AND ((Sales_Order__r.Price_Determination_Date__c != :PRICE_DET_ORDER AND Sales_Order__r.Pricing_Date__c >= :startDate '
                            +' AND Sales_Order__r.Pricing_Date__c <= :endDate) OR (Sales_Order__r.Price_Determination_Date__c = :PRICE_DET_ORDER '
                            +' AND Ordered_Date_Time__c >= :startDate AND Ordered_Date_Time__c <= :endDate))');

        List<Sales_order_Line__c> solList = Database.query(soql.getQuery());
        System.debug(loggingLevel.Error, '*** solList: ' + solList);
        Map<String, Pricebook_Line__c> solPBLMap = PricingService.fetchSOLinesPriceBookInfo(solList);
        System.debug(loggingLevel.Error, '*** solPBLMap: ' + solPBLMap);
        for (Sales_Order_Line__c sol : solList){


            //Pricebook_Line__c PBL = pbMatcher.match(sol.Pricebook__c, SOL, sol.Sales_order__r, sol.product__r);
            Pricebook_Line__c pbl = solPBLMap.get(sol.Sales_Order__r.Id + '-' + sol.Line__c);
            System.debug(loggingLevel.Error, '*** pbl: ' + pbl);
            if (pbl != null){
                productSOLMatch.add(pbl.Id);
            }
        }
        System.debug(loggingLevel.Error, '*** productSOLMatch: ' + productSOLMatch);
        return productSOLMatch;
    }

    public static void mapLineDependencies(set<Id> soIds){
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Agreement_Line__c','Agreement_Line__r.Parent_Agreement_Line__c','Item_Specification__c','Component__c','Component__r.Assembly_Item_Specification__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
        });
        soql.setWhereClause('Sales_Order__c IN :soIds');

        List<Sales_Order_Line__c> sols = Database.query(soql.getQuery());

        map<Id, Id> mChildToParentAgreementLines = new Map<Id, Id>();
        map<Id, Id> mAgreementLineToSOL = new map<Id, Id>();
        map<Id, Id> mItemSpecToSOL = new map<Id, Id>();
        for(Sales_Order_Line__c sol : sols){
            if(sol.Item_Specification__c != null && sol.Component__c == null){
                //this is a top level item  and we want component order lines to map to this one
                mItemSpecToSOL.put(sol.Item_Specification__c, sol.Id);
            }
            mChildToParentAgreementLines.put(sol.Agreement_Line__c, sol.Agreement_Line__r.Parent_Agreement_Line__c);
            mAgreementLineToSOL.put(sol.Agreement_Line__c, sol.Id);
        }
        
        for(Sales_Order_Line__c sol : sols){
            if(sol.Component__c != null && mItemSpecToSOL.containsKey(sol.Component__r.Assembly_Item_Specification__c)){
                sol.Parent_Sales_Order_Line__c = mItemSpecToSOL.get(sol.Component__r.Assembly_Item_Specification__c);    
            }else if(mAgreementLineToSOL.containsKey(sol.Agreement_Line__r.Parent_Agreement_Line__c)){
                sol.Parent_Sales_Order_Line__c = mAgreementLineToSOL.get(sol.Agreement_Line__r.Parent_Agreement_Line__c);
            }
        }
        try{
            DML.updateAsUser(sols);
        }catch(Exception ex){
            //Better to fail silently than blow up right now...
        }
        
    }

    public static void getParentSalesOrderLine(set<Id> soIds){
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Agreement_Line__c','Agreement_Line__r.Parent_Agreement_Line__c'
        });
        soql.setWhereClause('Sales_Order__c IN :soIds');

        List<Sales_Order_Line__c> sols = Database.query(soql.getQuery());

        map<Id, Id> mChildToParentAgreementLines = new Map<Id, Id>();
        map<Id, Id> mAgreementLineToSOL = new map<Id, Id>();
        
        for(Sales_Order_Line__c sol : sols){
            mChildToParentAgreementLines.put(sol.Agreement_Line__c, sol.Agreement_Line__r.Parent_Agreement_Line__c);
            mAgreementLineToSOL.put(sol.Agreement_Line__c, sol.Id);
        }

        for(Sales_Order_Line__c sol : sols){
            if(!mChildToParentAgreementLines.isEmpty()){
               if(!mAgreementLineToSOL.isEmpty() ){
                 sol.Parent_Sales_Order_Line__c = mAgreementLineToSOL.get(mChildToParentAgreementLines.get(sol.Agreement_Line__c));  
               } 
            }
        }
        
        DML.updateAsUser(sols);
    }
    
    private static set<Id> processedOrderIds = new set<Id>();
    public static void manageLineDependencies(set<Id> soIds){
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Sales_Order__c','Parent_Sales_Order_Line__c','Status__c'
        });
        soql.setWhereClause('Sales_Order__c IN :soIds AND Sales_Order__c NOT IN :processedOrderIds');

        Map<Id, Sales_Order_Line__c> mSOLs = new map<Id, Sales_Order_Line__c>((List<Sales_Order_Line__c>)Database.query(soql.getQuery()));
                                                
        map<Id, List<Sales_Order_Line__c>> mParentToChildLines = new map<Id, List<Sales_Order_Line__c>>();
        map<Id, Boolean> mClosedChildLines = new Map<Id, Boolean>();
        for(Sales_Order_Line__c sol : mSOLs.values()){
            processedOrderIds.add(sol.Sales_Order__c);
            if(sol.Parent_Sales_Order_Line__c != null){
                if(mParentToChildLines.containsKey(sol.Parent_Sales_Order_Line__c)){
                    mParentToChildLines.get(sol.Parent_Sales_Order_Line__c).add(sol);
                }else{
                    mParentToChildLines.put(sol.Parent_Sales_Order_Line__c, new List<Sales_Order_Line__c>{sol});
                }
            }
            if(mClosedChildLines.containsKey(sol.Parent_Sales_Order_Line__c)){
                if(mClosedChildLines.get(sol.Parent_Sales_Order_Line__c)){
                    mClosedChildLines.put(sol.Parent_Sales_Order_Line__c, sol.Status__c == 'Closed');
                }
            }else{
                mClosedChildLines.put(sol.Parent_Sales_Order_Line__c, sol.Status__c == 'Closed');
            }
        }
        
        List<Sales_Order_Line__c> sols = new List<Sales_Order_Line__c>();
        for(Id parentSOLId : mClosedChildLines.keySet()){
            if(mClosedChildLines.get(parentSOLId)){
                sols.add(new Sales_Order_Line__c(Id = parentSOLId, Status__c = 'Closed'));
            }
        }
        if(sols.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                
                soql = new SOQLUtil('Fulfillment__c', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'Id'
                });
                soql.setWhereClause('Sales_Order_Line__c IN :sols AND Status__c = \'Pending\'');

                List<Fulfillment__c> fulfillments = Database.query(soql.getQuery());

                for(Fulfillment__c f : fulfillments){
                    f.Status__c = 'Complete';
                }

                DML.updateAsUser(fulfillments);

            }catch(Exception ex){
                Database.rollback(sp);
            }
        }
    }

    public static void createNegativeFulfillments(Map<Id, Fulfillment__c> parentSolToParentFul){

		List<Fulfillment__c> parentFul = new List<Fulfillment__c>();
        List<Fulfillment__c> updateparentFul = new List<Fulfillment__c>();
        for (Id soId : parentSolToParentFul.keySet()){


			parentFul.add(parentSolToParentFul.get(soId));
            Fulfillment__c newFul = new Fulfillment__c();
            newFul.Type__c = 'Reverse Kit';
            newFul.Quantity__c = -parentSolToParentFul.get(soId).Quantity__c;

            parentSolToParentFul.put(soId,newFul);
        }

        if(parentFul.size()>0){
        	for(Fulfillment__c ff:parentFul){
        		ff.Invoice_Ready__c = false;
        		updateparentFul.add(ff);
        	}
        }
        

        if (!parentSolToParentFul.keySet().isEmpty()){
            FulfillmentService.fulfillSalesOrders(parentSolToParentFul.keySet(), parentSolToParentFul);
        }

        if(updateparentFul.size()>0){
        	DML.updateAsSystem(updateparentFul);
        }
        

    }

    /*
        Checks parent SOL for conponent to verify that all items are shipped before closing parent SOL.
        Called from SkidServices2
    */
    public static void createFulfillmentForParentSOLs(Set<Id> parentSolIds, List<Shipment_line__c> shipmentLineList){

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Product__r.Item__r.Source__c','Quantity_Ordered__c','Sales_Order__r.Type__c','Product__r.Item__c','Item_Specification__c'
        });
        soql.setWhereClause('Id IN :parentSolIds and Product__r.Item__r.Source__c = \'Kit\' and Item_Specification__c != null');

        List<Sales_order_line__c> parentSolList = Database.query(soql.getQuery());

        Map<Id,Id> itemToItemSpec = new Map<Id,Id>();

        for (Sales_Order_Line__c soLine : parentSolList){
            itemToItemSpec.put(soLine.Product__r.Item__c, soLine.Item_Specification__c); // validation for Item spec on SoLine added during release process.
            parentSolIds.add(soLine.id);
            }

        if (itemToItemSpec.values().isEmpty()){
            return;
        }

        // retrieve Master Item Id -> Component Item
        Map<Id,List<Component__c>> itemSpecToComponent = new Map<Id,List<Component__c>>(); // Key: item Spec, Value: component List
        Set<Id> itemSet = new Set<Id>();

        // collect kit components from parent SOL
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        List<Id> itemSpecs = itemToItemSpec.values();
        
        soql = new SOQLUtil('Component__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Component_Item__c','Quantity_per_Assembly__c','Assembly_Item_Specification__c'
        });
        soql.setWhereClause('Assembly_Item_Specification__c IN :itemSpecs');

        for (Component__c itemComp : Database.query(soql.getQuery())){
            if (!itemSpecToComponent.containsKey(itemComp.Assembly_Item_Specification__c)){
                itemSpecToComponent.put(itemComp.Assembly_Item_Specification__c, new List<Component__c>());
            }
            itemSpecToComponent.get(itemComp.Assembly_Item_Specification__c).add(itemComp);
            itemSet.add(itemComp.Component_Item__c);
        }

        // key: sol.id + '-' + item.id
        Map<String, Shipment_Line__c> shlItemToQty = new Map<String, Shipment_Line__c>();
        Map<Id, List<id>> parentToSHL = new Map<Id, List<id>>();

        // iterate through the SHLs to create a item to qty map for relavent lines
        for (Shipment_Line__c shl : shipmentLineList){
            // if shipment line belongs to a kit SOL
            if ( parentSolIds.contains(shl.Sales_order_line__c)){
                if (!parentToSHL.containsKey(shl.Sales_order_line__c)){
                    parentToSHL.put(shl.Sales_order_line__c, new List<id>());
                }

                parentToSHL.get(shl.Sales_order_line__c).add(shl.id);
            }

            if (itemSet.contains(shl.Item__c)){
                if (shlItemToQty.containsKey(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c + '-' + shl.Item__c)){
                    shlItemToQty.put( shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c + '-' + shl.Item__c, shl); //KSE.addQuantityToField( shlItemToQty.get(shl.Item__c), shl.Quantity_Shipped__c));
                } else {
                    shlItemToQty.put( shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c + '-' + shl.Item__c, shl); //shl.Quantity_Shipped__c);
                }
            }
        }

            // iterate through parent SOL list to populate SOL fulfillment list
        Map<Id,Fulfillment__c> solFulfillMap = new Map<Id,Fulfillment__c>();


        // iterate through kit item source soLines
        for (Sales_Order_Line__c soLine : parentSolList){
            // iterate through item comp to check for item count
            Decimal fulfillmentQty;
            for (Component__c comp : itemSpecToComponent.get(soLine.Item_Specification__c)){

                if (shlItemToQty.containskey(soLine.id +'-'+ comp.Component_Item__c)){
                    Decimal shippedQty = shlItemToQty.get(soLine.id +'-'+ comp.Component_Item__c).Quantity_Shipped__c;
                    Decimal unitFactor = comp.Quantity_per_Assembly__c;
                    Decimal fulfillmentQtyTmp = (shippedQty/unitFactor).setscale(6,System.RoundingMode.HALF_UP);
                    
                    // KNDY-13929
                    if (fulfillmentQty == null ){
                        fulfillmentQty = fulfillmentQtyTmp;
                    } else if ( fulfillmentQty != fulfillmentQtyTmp ) {
                        throw new SalesOrderLineException('Invalid quantity entered for item ' + comp.Component_Item__r.Name);
                    }
                } else {
                    throw new CustomException('Missing quantity for kit item');
                }
            }

            Fulfillment__c f = new Fulfillment__c();
            f.Type__c = 'Kit'; // soLine.Sales_Order__r.Type__c;
            f.Sales_order_Line__c = soLine.id;
            f.Quantity__c = fulfillmentQty;

            solFulfillMap.put(soLine.id, f);
        }

        if (!solFulfillMap.keySet().isEmpty()){
            FulfillmentService.fulfillSalesOrders(solFulfillMap.keySet(), solFulfillMap);
        }
    }

    /* called from SalesOrderService during Plan method. Performed after initial plan query to reduce queries in testmethods. :( Maintaing query exceptions is difficult unless we use fieldsets across both queries) */
    public static List<Sales_Order_Line__c> insertKittedSalesOrderLines( Map<Id, List<Sales_Order_Line__c>> soToKitSolMap) {

        Map<Id,Id> itemToItemSpec = new Map<Id,Id>();

        // creates item to item_spec map for matching component items to master item
        for (Id soId : soToKitSolMap.keySet()){
            for (Sales_Order_Line__c soLine : soToKitSolMap.get(soId)) {
                if (soLine.Product__r.Item__r.Source__c == 'Kit') {
                    itemToItemSpec.put(soLine.Product__r.Item__c, soLine.Item_Specification__c);
                }
            }
        }

        if (itemToItemSpec.values().isEmpty()) {
            return new List<Sales_Order_Line__c>();
        }

        /* populate item components map from Item list */
        // Map: master item -> component List
        Map<Id,List<Component__c>> itemSpecToComponent = new Map<Id,List<Component__c>>();
        Set<Id> itemSet = new Set<Id>();

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        List<Id> itemSpecIds = itemToItemSpec.values();
        
        SOQLUtil soql = new SOQLUtil('Component__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','Component_Item__c','Quantity_per_Assembly__c','Assembly_Item_Specification__c'
        });
        soql.setWhereClause('Assembly_Item_Specification__c IN :itemSpecIds');

        for (Component__c itemComp : Database.query(soql.getQuery())){
            if (!itemSpecToComponent.containsKey(itemComp.Assembly_Item_Specification__c)){
                itemSpecToComponent.put(itemComp.Assembly_Item_Specification__c, new List<Component__c>());
            }
            itemSpecToComponent.get(itemComp.Assembly_Item_Specification__c).add(itemComp);
            itemSet.add(itemComp.Component_Item__c);
        }

        // retreive all products related to items: Map: Item -> Product
        Map<Id, Product__c> itemToProductMap = getProductsFromItems(itemSet);

        return createChildSOLs(soToKitSolMap, itemToProductMap, itemSpecToComponent);
    }

    // TODO: extend this to use SalesoRderMangesLines.getSalesOrderLineDetails?
    public static Map<Id, Product__c> getProductsFromItems(Set<Id> itemSet){

        Map<Id, Product__c> itemToProductMap = new Map<Id, Product__c>();

        //TODO: Get fieldset from SalesOrderService plan via params. We'll have to replace that query with Database.Query and use fieldsets.
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

		SOQLUtil soql = new SOQLUtil('Product__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Description__c','Item__c','Item__r.Name','Item__r.Fulfillment_Source__c','Pricebook_Line_Required__c',
			'Product_Group__c','Selling_UOM__r.Name','Units_per_Layer__c','Item__r.Stocking_UOM__c','Item__r.Stocking_UOM__r.Name','Weight__c',
			'Weight_UOM__r.Name','Dimension_UOM__r.Name','Item__r.Lead_Time__c','Width__c','Height__c','Length__c','Sales_hierarchy__c',
			'Sales_hierarchy__r.Path__c','Sales_hierarchy__r.Code__c','Product_group__r.Hierarchy__c','Product_group__r.Hierarchy__r.Path__c',
			'Product_group__r.Hierarchy__r.Code__c','Item__r.Non_Shippable__c','Units_per_Pallet__c','UPC_Code__c','Invoiceable__c','Item__r.Source__c',
			'Item__r.Non_Inventory__c', 'Item__r.Packaging_UOM__c'
		});
		soql.setWhereClause('Item__c IN :itemSet');
		
		for (Product__c prod : Database.query(soql.getQuery())) {
            if (!itemToProductMap.containsKey(prod.Item__c)){
                itemToProductMap.put(prod.Item__c, prod);
            } else {
                System.debug(loggingLevel.Error, 'Too many products for selected item for kitting' );
            }
        }

        return itemToProductMap;

    }

    public static List<Sales_order_Line__c> createChildSOLs( Map<Id, List<Sales_Order_Line__c>> soToKitSolMap, Map<Id, Product__c> itemToProductMap, Map<Id,List<Component__c>> itemSpecToComponent){

        List<Sales_order_Line__c> childLinesForInsert = new List<Sales_order_Line__c>();
        Set<Id> kitSalesOrders = new Set<Id>();

        for (Id soId : soToKitSolMap.keySet()){
            for (Sales_Order_Line__c parentSOLine : soToKitSolMap.get(soId)) {

                if (parentSOLine.Product__r.Item__r.Source__c != 'Kit' && parentSOLine.Item_Specification__c == null) {
                    return new List<Sales_order_Line__c>(); // new List<Sales_order_Line__c>();
                }

                if(itemSpecToComponent.containsKey(parentSOLine.Item_Specification__c)){

                    Id itemSpecId = parentSOLine.Item_Specification__c;
                    //Decimal count = .01;
                    for (Component__c itemComp : itemSpecToComponent.get(itemSpecId)){

                        if (itemToProductMap.containsKey(itemComp.Component_Item__c)) {

                            Sales_order_Line__c newSOLine = new Sales_Order_Line__c();
                            //// create sol's for parent line only if
                            //if (parentSOLine.Quantity_Ordered__c - parentSOLine.Quantity_Fulfilled__c <= 0){
                            //    continue;
                            //}
                            /* product info */
                            Product__c product = itemToProductMap.get(itemComp.Component_Item__c);

                            newSOLine.Selling_UOM__c = product.Selling_UOM__c;
                            newSOLine.Selling_UOM__r = product.Selling_UOM__r;
                            newSOLine.Description__c = product.Description__c;
                            newSOLine.Product__c = product.Id;
                            newSOLine.Product__r = product;
                            newSOLine.UPC_Code__c = product.UPC_Code__c;
                            newSOLine.Company__c = parentSOLine.Company__c;

                            newSOLine.Quantity_Ordered__c = itemComp.Quantity_per_Assembly__c * (parentSOLine.Quantity_Ordered__c - parentSOLine.Quantity_Fulfilled__c);

                            /* Kitted info */
                            newSOLine.Parent_Sales_Order_Line__c = parentSOLine.Id;
                            newSOLine.Invoiceable__c = false;
                            newSOLine.Unit_Price__c = 0;

                            newSOLine.Type__c = SalesOrderLineService.SO_LINE_TYPE_KIT_CHILD;
                            newSOLine.Sales_Order__c = soId;

                            /* Copied from Parent Line */
                            newSOLine.Pricebook__c = parentSOLine.Pricebook__c;
                            newSOLine.Ordered_Date_Time__c = parentSOLine.Ordered_Date_Time__c;
                            newSOLine.Required_Date__c = parentSOLine.Required_Date__c;
                            newSOLine.Ship_From_Location__c = parentSOLine.Ship_From_Location__c;
                            newSOLine.Ship_From_Location__r = parentSOLine.Ship_From_Location__r;
                            newSOLine.Status__c = SalesOrderLineService.SO_LINE_STATUS_OPEN;
                            //newSOLine.Ship_From_Location__r = parentSOLine.Ship_From_Location__r;

                            //newSOLine.Item_Specification__c = null; //

                            //newSOLine.Line__c = soLine.Line__c + count;
                            //count +=  .1;

                            childLinesForInsert.add(newSOLine);
                            //kitSalesOrders.add(newSOLine.Sales_Order__c);

                        } else {
                            System.debug(loggingLevel.Error, 'No product found for Item: ' + itemComp.Id);
                        }
                    }
                } else {
                    System.debug(loggingLevel.Error, 'No item Specification found for Kitted Item on SOL: ' + parentSOLine.Id);
                }
            }
        }

        Map<Id,Product__c> prodMap = new Map<Id,Product__c>(itemToProductMap.values());
        Map<Id,Sales_Order__c> soMap = new Map<Id,Sales_Order__c>(SalesOrderFlowCache.cachedSalesOrdersForIds(soToKitSolMap.keySet()));

        //Why?
        //SalesOrderLineService.updatePricebookOnSOL( soMap, childLinesForInsert, prodMap, new Map<Id,Shipment_Line__c>());

        DML.insertAsUser(childLinesForInsert);

        return childLinesForInsert;
    }

    public static List<sales_Order_Line__c> requeryLines(Set<id> salesOrderLinesId){
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Name','Company__c','Description__c','Discount_Percent__c','Pricebook__c','Sales_Order__r.Customer__r.Pricebook__c',
            'Sales_Order__r.Pricebook__c','Quantity_From_Stock__c','Fulfillment_Source__c','Purchase_From_Supplier__c','Pricebook__r.Currency__c',
            'Currency__c','Has_Exceptions__c','Unit_Price__c','Estimated_Ship_Date__c','Item_Specification__c','Weight__c',
            'Weight_UOM__c','Status__c','Dimension_UOM__c','Weight_UOM_Name__c','Dimension_UOM_Name__c','Dimension_UOM__r.Name','Weight_UOM__r.Name',
            'Quantity_Backordered__c','Quantity_Ordered__c','Quantity_Shipped__c','Required_Date__c','Extended_Price__c','Product__c',
            'Product__r.Item__c','Product__r.Item__r.Stocking_UOM__c','Product_Weight__c','Product__r.Item__r.Stocking_UOM__r.Name','Product__r.Weight__c',
            'Product__r.Product_Group__c','Product__r.Weight_UOM__r.Name','Product__r.Dimension_UOM__r.Name','Product__r.Item__r.Lead_Time__c',
            'Product__r.Item__r.Non_Inventory__c','Product__r.Width__c','Product__r.Height__c','Product__r.Length__c','Product__r.Sales_hierarchy__c',
            'Product__r.Sales_hierarchy__r.Path__c','Product__r.Sales_hierarchy__r.Code__c','Product__r.Product_group__r.Hierarchy__c',
            'Product__r.Product_group__r.Hierarchy__r.Path__c','Product__r.Product_group__r.Hierarchy__r.Code__c','Product__r.Item__r.Non_Shippable__c',
            'Product__r.Pricebook_Line_Required__c','Item_Source__c','Parent_Sales_Order_Line__c','Parent_Sales_Order_Line__r.Item_Source__c',
            'Product__r.Item__r.Source__c','Sales_Order__r.Ship_To__r.Preferred_Shipping_Method__c','Ordered_Date_Time__c',
            'Off_Invoice_Rate__c','Sales_Order__c','Sales_Order__r.Delivery_Method__c','Sales_Order__r.Company__c','Sales_Order__r.Bill_to__c',
            'Sales_Order__r.Bill_to__r.Customer_Group__c','Sales_Order__r.Ship_To__c','Sales_Order__r.Ship_To__r.Name','Sales_Order__r.Ship_To__r.Address__c',
            'Sales_Order__r.Ship_To__r.Business_Hours__c','Sales_Order__r.Ship_To__r.Lead_Time__c','Sales_Order__r.Ship_To__r.Earliest_Delivery_Window__c',
            'Sales_Order__r.Ship_To__r.Latest_Delivery_Window__c','Sales_Order__r.Currency__c','Sales_Order__r.Status__c',
            'Sales_Order__r.Hold__c','Sales_Order__r.Payment_Term__c','Sales_Order__r.Type__c','Sales_Order__r.Customer__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c',
            'Sales_Order__r.Ship_To__r.Aggregate_Shipments__c','Sales_Order__r.Customer__r.Customer_Group__c','Sales_Order__r.Ship_To__r.Customer_Group__c',
            'Sales_Order__r.Customer__r.Top_Parent_Customer__r.Customer_Group__c','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Credit_Hold__c',
            'Sales_Order__r.Dimensional_Weight__c','Sales_Order__r.Required_Date__c','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c',
            'Sales_Order__r.Customer__r.Status__c','Sales_Order__r.Customer__r.Parent_Customer__r.Status__c','Sales_Order__r.Ship_to__r.Status__c',
            'Sales_Order__r.Means_of_Transport__c','Sales_Order__r.Means_of_Transport__r.Name','Sales_Order__r.Exceeds_Max_Weight__c',
            'Sales_Order__r.Total_Weight__c','Sales_Order__r.Total_Order_Volume__c','Sales_Order__r.subtotal__c','Sales_Order__r.Total_Quantity_Ordered__c',
            'Sales_Order__r.Total_Product_Weight__c','Sales_Order__r.Order_Total__c','Sales_Order__r.Means_of_Transport__r.Minimum_Cube__c',
            'Sales_Order__r.Means_of_Transport__r.Minimum_Weight__c','Sales_Order__r.Weight_UOM__c','Sales_Order__r.Dimension_UOM__c',
            'Sales_Order__r.Weight_UOM__r.Name','Sales_Order__r.Dimension_UOM__r.Name','Sales_Order__r.Price_Determination_Date__c','Sales_Order__r.Pricing_Date__c',
            'Sales_Order__r.Date_Time_Ordered__c','Selling_UOM__c','Selling_UOM__r.Name','Ship_From_Location__c','Ship_From_Location__r.Facility__r.Address__c',
            'Ship_From_Location__r.Facility__c','Ship_From_Location__r.Facility__r.Name','Ship_From_Location__r.Facility__r.Lead_Time__c',
            'Sales_Order__r.Override_Credit_Hold__c','Ship_From_Location__r.Facility__r.Enable_Transit_Route_Optimization__c','Ship_From_Location__r.Facility__r.Shipping_Calendar__c',
            'Line_Type__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c'
        });
        soql.setWhereClause('id IN :salesOrderLinesId');
        
        String SHIPMENT_STATUS_CONFIRMED = ShipmentService.SHIPMENT_STATUS_CONFIRMED;
        String SHIPMENT_STATUS_DELIVERED = ShipmentService.SHIPMENT_STATUS_DELIVERED;
        
        SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
        childRel1.addFields(new set<string>{
            'Id','Shipment__c'
        });
        childRel1.setWhereClause('Shipment__r.Status__c NOT IN (:SHIPMENT_STATUS_CONFIRMED, :SHIPMENT_STATUS_DELIVERED) AND Shipment__r.Customer__r.Aggregate_Shipments__c = false');
        soql.addChildRelationship(childRel1);
        
        SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Requisition_Lines__r');
        childRel2.addFields(new set<string>{
            'Id','Requisition__c','Sales_Order_Line__c'
        });
        soql.addChildRelationship(childRel2);
        
        return Database.query(soql.getQuery());
    }
    
    /* SOL Trigger for updating parent SOLs quantities */
    public static void updateKittedChildQuantities(){
        Set<Id> parentSOLIds = new Set<Id>();

        if (Trigger.isAfter){
            if (Trigger.isUpdate){
                for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) Trigger.new) {
                    if (KSE.isFieldChanging('Quantity_Ordered__c', sol, Trigger.oldMap) && sol.Item_Source__c == 'Kit'){
                        parentSOLIds.add(sol.id);
                    }
                }
            }
        }

        if (parentSOLIds.isEmpty()){
            return;
        }
        Map<Id, List<Sales_Order_Line__c>> mParentToChildLines = new Map<Id, List<Sales_Order_Line__c>>();

        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        
        SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'Id','Parent_Sales_Order_Line__r.Product__r.Item__r.Source__c','Quantity_Ordered__c','Parent_Sales_Order_Line__r.Quantity_Ordered__c'
        });
        soql.setWhereClause('Parent_Sales_Order_Line__c IN :parentSOLIds AND Parent_Sales_Order_Line__r.Product__r.Item__r.Source__c = \'Kit\'');

        for (Sales_Order_Line__c childSol : Database.query(soql.getQuery())){
            if(!mParentToChildLines.containsKey(childSol.Parent_Sales_Order_Line__c)){
                mParentToChildLines.put(childSol.Parent_Sales_Order_Line__c, new List<Sales_Order_Line__c>());
            }
            mParentToChildLines.get(childSol.Parent_Sales_Order_Line__c).add(childSol);
        }

        if (mParentToChildLines.keySet().isEmpty()){
            return;
        }

        if (Trigger.isUpdate){
            List<Sales_Order_Line__c> solForUpdate = new List<Sales_Order_Line__c>();

            for (Id parentSol : mParentToChildLines.keySet()){
                Decimal oldQty = (Decimal) Trigger.oldMap.get(parentSol).get('Quantity_Ordered__c');
                Decimal newQty = (Decimal) Trigger.newMap.get(parentSol).get('Quantity_Ordered__c');
                Decimal multiplier =  newQty / oldQty;
                for (Sales_order_line__c childLines : mParentToChildLines.get(parentSol)){
                    childLines.Quantity_Ordered__c *= multiplier;
                    if ( ((Sales_Order_Line__c) Trigger.newMap.get(parentSol)).Quantity_Change_Reason__c != null){
                        childLines.Quantity_Change_Reason__c = ((Sales_Order_Line__c) Trigger.newMap.get(parentSol)).Quantity_Change_Reason__c;
                    }
                    solForUpdate.add(childLines);
                }
            }

            if (!solForUpdate.isEmpty()){
                DML.updateAsUser(solForUpdate);
            }
        }

    }

    public static void closeBundleParentSalesOrderLine(){
        // KNDY-9596: Close parent sales order line when children lines are closed

        Set<Id> parentSOLIds = new Set<Id>();
        // Find all the lines that change to closed
        if (Trigger.isUpdate) {
            for (Sales_Order_Line__c sol : (List<Sales_Order_Line__c>) Trigger.new) {
                if (KSE.isFieldChanging('Status__c', sol, Trigger.oldMap) 
                    && sol.Status__c == 'Closed'
                    && sol.Parent_Sales_Order_Line__c != null) {
                        parentSOLIds.add(sol.Parent_Sales_Order_Line__c);
                }
            }
        }
        if (parentSOLIds.size() > 0){
            // Map of Parent SOL, child SOLs
            Map<Id, List<Sales_Order_Line__c>> mParentToChildLines = new Map<Id, List<Sales_Order_Line__c>>();
            // The query will return the SOLs under the parent
            // The information needed for the SOL parent is within the relationship

            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            
            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Product__r.Bundle__c','Sales_Order__c','Status__c','Parent_Sales_Order_Line__c','Parent_Sales_Order_Line__r.Quantity_Ordered__c',
                'Parent_Sales_Order_Line__r.Unit_Price__c'
            });
            soql.setWhereClause('Parent_Sales_Order_Line__c IN :parentSOLIds AND Parent_Sales_Order_Line__r.Product__r.Bundle__c = true');
            
            for (Sales_Order_Line__c SOL : Database.query(soql.getQuery())){
                // put the sols in the parent to child lines map
                if(mParentToChildLines.containsKey(SOL.Parent_Sales_Order_Line__c)){
                    mParentToChildLines.get(SOL.Parent_Sales_Order_Line__c).add(SOL);
                }else{
                    mParentToChildLines.put(SOL.Parent_Sales_Order_Line__c, new List<Sales_Order_Line__c>{SOL});
                }
            }

            List<Sales_Order_Line__c> solsToUpdate = new List<Sales_Order_Line__c>();
            List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
            // loop through the parents
            for (Id parentSOLId : mParentToChildLines.keySet()){
                Boolean closeParent = true;
                Sales_Order_Line__c currentSOL;
                for (Sales_Order_Line__c  SOL : mParentToChildLines.get(parentSOLId)) {
                    currentSOL = SOL;
                    if (SOL.Status__c != SO_LINE_STATUS_CLOSED){
                        closeParent = false;
                    }
                }
                if (closeParent) {
                    solsToUpdate.add(new Sales_Order_Line__c(Id = parentSOLId, Status__c = 'Closed'));
                    // BA: What is this fulfillment?
                    fulfillments.add(new Fulfillment__c(Name='Test',
                                                        Sales_Order_Line__c = parentSOLId,
                                                        Status__c = 'Complete',
                                                        Unit_Price__c = currentSOL.Parent_Sales_Order_Line__r.Unit_Price__c,
                                                        Quantity__c = (Decimal) currentSOL.Parent_Sales_Order_Line__r.Quantity_Ordered__c,
                                                        Type__c = 'Bundle'));
                }
            }

            if (solsToUpdate.size() > 0){
                Savepoint sp = Database.setSavepoint();
                try{
                    DML.insertAsUser(fulfillments);
                    DML.updateAsUser(solsToUpdate);                    
                }catch(Exception ex){
                    Database.rollback(sp);
                }
            }
        }
    }
    public static List<Requisition_Line__c> solToReqLines(Map<Id, Sales_Order_Line__c> cancelSOLMap){
        Set<ID> solIds = cancelSOLMap.keySet();
        SOQLUtil soql = new SOQLUtil('Requisition_Line__c');
        soql.setWhereClause('Sales_Order_Line__c IN :solIds');
        soql.addFields(new Set<String>{'Id', 'Status__c', 'Quantity_Released__c', 'Requisition__c', 'Quantity_Ordered__c', 'Name', 'Sales_Order_Line__c'});                                              
        List<Requisition_Line__c> reqLinesList = Database.query(soql.getQuery());    
        return reqLinesList;
    }

    public static Map<Id, Requisition_Line__c> cancelReqLines(Map<Id, Sales_Order_Line__c> cancelSOLMap){
        Map<Id,Requisition_Line__c>cancelReqLinesMap = new Map<Id,Requisition_Line__c>();
        Map<Id,Requisition_Line__c>reqLineMap = new Map<Id,Requisition_Line__c>();
        Boolean updateOnlyReqLine = false;
           
        List<Requisition_Line__c> requisitioLinesList = solToReqLines(cancelSOLMap);
        if(requisitioLinesList.size() > 0){
            for(Requisition_Line__c reqLine : requisitioLinesList){
                if(reqLine.Status__c != 'Closed'){
                    reqLineMap.put(reqLine.id, reqLine);    
                    reqLine.Status__c = 'Cancelled';
                    reqLine.Quantity_Released__c = 0;
                    cancelReqLinesMap.put(reqLine.Id, reqLine);
                    updateOnlyReqLine = true; 
                }else {
                    reqLineMap.put(reqLine.id, reqLine);
                }
                               
            }    
        }
        
       if(updateOnlyReqLine){
          DML.updateAsUser(cancelReqLinesMap.values());
       }
      return reqLineMap;
    }

}