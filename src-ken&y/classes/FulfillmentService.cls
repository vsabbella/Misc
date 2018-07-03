public without sharing class FulfillmentService {

    public class FulfillmentException extends Exception{}
    
    private static set<Id> processedInvTrxnIds = new set<Id>();

    public static boolean activateFulfillments(){
        Configuration__c c = Configuration__c.getValues('ActivateFulfillments');
        if (c != null)
            return true;
        else
            return false;
    }

    public static void fulfillSalesOrders(Set<Id> soIds) {
         fulfillSalesOrders(soIds, new Map<Id, List<Fulfillment__c>>());
    }

    /* Ids can be of Sales Order or Sales Order Line */
    public static void fulfillSalesOrders(Set<Id> idSet, Map<Id, Fulfillment__c> fulfillments) {
        Map<Id, List<Fulfillment__c>> fulfillmentMap = new Map<Id, List<Fulfillment__c>>();
        for (Id recId:fulfillments.keySet()) {
            fulfillmentMap.put(recId, new List<Fulfillment__c>{ fulfillments.get(recId) });
        }
        fulfillSalesOrders(idSet, fulfillmentMap);
    }
    public static void fulfillSalesOrders(set<Id> ids,Map<Id, List<Fulfillment__c>> solFulfillMap){
        
        Savepoint sp = Database.setSavepoint();
        try {
 
            Set<String> solQueryFields = new Set<String>{ 'Id','Unit_Price__c', 'Product__c', 'Selling_UOM__c', 'Customer_Site__c', 'Quantity_Fulfilled__c', 
                                                        'Agreement_Line__r.Agreement__c', 'Quantity_Ordered__c', 'Quantity_Shipped__c',
                                                        'Invoiceable__c', 'Product__r.Item__c', 'Extended_Price__c', 'Ship_From_Location__r.Facility__c','Company__c', 
                                                        'Sales_Order__r.Customer__c', 'Sales_Order__c', 'Usage_Based__c',
                                                        'Sales_Order__r.Currency__c','Sales_Order__r.Type__c', 
                                                        'Sales_Order__r.Payment_Term__c', 
                                                        'Rate_Basis__c', 'Unit_Price__c', 'Off_Invoice_Rate__c', 'Allowances__c', 'Freight_Allowance__c', 'Discount_Percent__c', 
                                                        'Sales_Order__r.Billing_UOM__c','Sales_Order__r.Recurrence_Start_Date__c','Agreement_Line__c'
                                                        };

            String whereClause; 
            if (new list<Id>(ids)[0].getSObjectType() == Sales_Order_Line__c.getSObjectType()){
                // used to create fulfillments on non-shippable products
                // creating fulfillments for Parent SOLs in Kitting
                whereClause = 'Id IN :ids';
            } else if (new list<Id>(ids)[0].getSObjectType() == Sales_Order__c.getSObjectType()) {
                // create fulfillments for non standard type SOs
                whereClause = 'Sales_Order__c IN :ids and Sales_Order__r.Type__c != \'Standard\'';
            } else {
                System.debug(loggingLevel.Error, '*** Unexpected Id type: ');
                throw new FulfillmentException('Invalid ID passed to fulfillment services.');
                return;
            }
            //KNDY-8796
            SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c',true);
            soql.addFields(solQueryFields);
            soql.setWhereClause(whereClause);
            
            SOQLUtil.ChildRelationship fulfills = new SOQLUtil.ChildRelationship(soql, 'Fulfillments__r');
		    fulfills.addFields(new Set<String>{'Id', 'Quantity__c', 'Sales_Order_Line__c'});
		    soql.addChildRelationship(fulfills);
		    
            List<Sales_Order_Line__c> solList = Database.query(soql.getQuery());
          
            if (solList.isEmpty()){
                return;
            }

            List<Fulfillment__c> fulfillments = new List<Fulfillment__c>();
            Set<Id> itemIds = new Set<Id>();
            Set<id> facilityIds = new Set<id>();
            
            for(Sales_Order_Line__c sol : solList){
                itemIds.add(sol.Product__r.Item__c);
                facilityIds.add(sol.Ship_From_Location__r.Facility__c); 
            }

            for (Sales_Order_Line__c sol:solList) {
                if (solFulfillMap != null && solFulfillMap.containsKey(sol.Id)) {
                    for (Fulfillment__c fulfillment:solFulfillMap.get(sol.Id)) {
                        if (fulfillment.Type__c == null) throw new FulfillmentException('Fulfillment is missing Type');
                        if (fulfillment.Quantity__c == null) throw new FulfillmentException('Fulfillment is missing Quantity');

                        Fulfillment__c iX = generateFulfillmentFromSOL(sol, fulfillment, itemIds, facilityIds);
                        if (iX != null) fulfillments.add(iX);
                    }
                } else {
                    Fulfillment__c iX = generateFulfillmentFromSOL(sol, new Fulfillment__c(Quantity__c = sol.Quantity_Ordered__c, Type__c = sol.Sales_Order__r.Type__c), itemIds, facilityIds);
                    if (iX != null) fulfillments.add(iX);
                }
            }

            if (fulfillments.size() > 0) DML.insertAsSystem(fulfillments);
        } catch(Exception ex){
            Database.rollback(sp);
            system.debug('ex: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
            throw new FulfillmentException(ex.getMessage());
        }
    }

    public static Fulfillment__c generateFulfillmentFromSOL(Sales_Order_Line__c sol, Fulfillment__c fulfillment, Set<Id> itemIds, Set<Id> facilityIds) {
        Decimal newQtyFulfilled = sol.Quantity_Fulfilled__c + fulfillment.Quantity__c;

        if (Math.abs(sol.Quantity_Ordered__c) >= Math.abs(newQtyFulfilled) || sol.Usage_Based__c) {
            fulfillment.Company__c = sol.Company__c;
            fulfillment.Currency__c = sol.Sales_Order__r.Currency__c;
            fulfillment.Customer__c =  sol.Customer_Site__c != null ?  sol.Customer_Site__c : sol.Sales_Order__r.Customer__c;
            fulfillment.Agreement_Line__c = sol.Agreement_Line__c;
            fulfillment.Agreement__c = sol.Agreement_Line__r.Agreement__c;
            fulfillment.Sales_Order_Line__c = sol.Id;
            fulfillment.Sales_Order__c = sol.Sales_Order__c;
            fulfillment.Product__c = sol.Product__c;
            fulfillment.Billing_UOM__c = sol.Sales_Order__r.Billing_UOM__c;
            fulfillment.Recurrence_Start_Date__c = sol.Sales_Order__r.Recurrence_Start_Date__c;
            if (fulfillment.Fulfillment_Date__c == null) fulfillment.Fulfillment_Date__c = System.now();
            if (fulfillment.Type__c == 'Reverse Kit' || fulfillment.Type__c == 'Reverse Warranty' || SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(sol.Sales_Order__r.Type__c) || (sol.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPAIR && !sol.Invoiceable__c && sol.Quantity_Ordered__c >0) || (sol.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_REPAIR && !sol.Invoiceable__c) || fulfillment.Type__c == SalesOrderService.SO_TYPE_RESALE) {
                fulfillment.Invoice_Ready__c = false;//Negative and Positive fulfillment for RMA Replacement && Repair should not be marked INV Ready.
            } else {
                fulfillment.Invoice_Ready__c = true;
            }
            fulfillment.Status__c = 'Complete';
            fulfillment.UOM__c = sol.Selling_UOM__c;
            fulfillment.Unit_Cost__c = ItemService.getActiveStandardCostDecimal(itemIds, facilityIds, sol.Company__c, sol.Ship_From_Location__r.Facility__c, System.now(), sol.Product__r.Item__c);
            fulfillment.Unit_Price__c = sol.Unit_Price__c;
            fulfillment.Payment_Term__c = sol.Sales_Order__r.Payment_Term__c;

            return fulfillment;
        }

        return null;
    }

    public static void fulfillAccrualAllowances(List<Allowance_Applied__c> accrualAAList, Map<Id, Sales_Order_Line__c> solMap) {
        Savepoint sp = Database.setSavepoint();
        try {
            Map<Allowance_Applied__c, Fulfillment__c> accuralTofulfillmentMap = new Map<Allowance_Applied__c, Fulfillment__c>();
            for (Allowance_Applied__c sourceAA : accrualAAList) {

                Sales_Order_Line__c sol = solMap.get(sourceAA.Sales_Order_Line__c);

                Fulfillment__c iX = new Fulfillment__c();

                iX.Customer__c = sourceAA.Beneficiary__c;

                iX.Type__c = AllowanceRuleService.ALLOWANCE_ACCRUAL; // KNDY-14480

                iX.Company__c = sol.Company__c;
                iX.Currency__c = sol.Sales_Order__r.Currency__c;

                iX.Sales_Order_Line__c = sol.id;
                iX.Sales_Order__c = sol.Sales_Order__c;
                iX.Product__c = sol.Product__c;

                iX.Fulfillment_Date__c = system.now();

                iX.Invoice_Ready__c = true;
                iX.Status__c = 'Complete';

                iX.UOM__c = sol.Selling_UOM__c;
                ix.Allowance_Applied__c = sourceAA.id;

                iX.Quantity__c = 1;
                iX.Unit_Price__c = sourceAA.BillBack_Commitment__c * -1; // not using Abs value to support reversal fulfillments
                iX.Extended_Price__c = iX.Quantity__c * iX.Unit_Price__c;

                iX.Payment_term__C = sol.Sales_Order__r.Payment_Term__c;
                accuralTofulfillmentMap.put(sourceAA, iX);
            }

            DML.insertAsSystem(accuralTofulfillmentMap.values());

        } catch(Exception ex){
            Database.rollback(sp);
            system.debug('ex: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
            throw new FulfillmentException(ex.getMessage());
        }

    }

    public static void updateInventoryTransactionMappings(set<Id> invTrxnIds){
        if(processedInvTrxnIds.containsAll(invTrxnIds)){
        	return;
        }
        processedInvTrxnIds.addAll(invTrxnIds);
        Savepoint sp = Database.setSavepoint();
        try{
            //Find stubs and attach details 1:1
            Map<Id, Fulfillment__c> mFulfillments = new Map<Id, Fulfillment__c>();

            SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
            itQuery.addFields(new Set<String>{ 'Id', 'Name', 'From_Facility__c', 'From_SKID__c', 'Item__c', 'Quantity_Stocking_UOM__c',
                'Sales_Order_Line__c', 'Shipment_Line__c', 'To_Facility__c', 'To_SKID__c', 'To_Standard_Cost__c', 'Transaction_Date__c',
                'Type__c',

                'From_Facility__r.Facility_Identifier__c',

                'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c',

                'Sales_Order_Line__r.Agreement_Line__c', 'Sales_Order_Line__r.Agreement_Line__r.Agreement__c', 'Sales_Order_Line__r.Agreement_Line__r.Billing_Category__c',
                'Sales_Order_Line__r.Company__c', 'Sales_Order_Line__r.Customer_Site__c', 'Sales_Order_Line__r.Invoiceable__c', 'Sales_Order_Line__r.Parent_Sales_Order_Line__c',
                'Sales_Order_Line__r.Parent_Sales_Order_Line__r.Item_Source__c', 'Sales_Order_Line__r.Product__c', 'Sales_Order_Line__r.Rental__c',
                'Sales_Order_Line__r.Sales_Order__c', 'Sales_Order_Line__r.Sales_Order__r.Billing_UOM__c', 'Sales_Order_Line__r.Sales_Order__r.Currency__c',
                'Sales_Order_Line__r.Sales_Order__r.Customer__c', 'Sales_Order_Line__r.Sales_Order__r.Payment_Term__c', 'Sales_Order_Line__r.Sales_Order__r.Recurrence_Start_Date__c',
                'Sales_Order_Line__r.Sales_Order__r.Type__c', 'Sales_Order_Line__r.Selling_UOM__c', 'Sales_Order_Line__r.Start_Date__c',
                'Sales_Order_Line__r.Unit_Price__c',

                'To_Facility__r.Facility_Identifier__c',

                'Work_Order__r.Field_Service__c' });
            itQuery.setWhereClause('Id IN :invTrxnIds');
            
            SOQLUtil.ChildRelationship fulfillmentSubquery = new SOQLUtil.ChildRelationship(itQuery, 'Fulfillments__r');
            fulfillmentSubquery.addFields(new Set<String>{ 'Id', 'Name' });
            itQuery.addChildRelationship(fulfillmentSubquery);
            
            List<Inventory_Transaction__c> invTrxns = Database.query(itQuery.getQuery());

            /* populate fulfillment parent id if fulfillment SOL has a parent */
            Map<Id, Fulfillment__c> parentSolToParentFul = new Map<Id, Fulfillment__c>();
            // populate parent SOL for map key
            String itType;
            for(Inventory_Transaction__c it : invTrxns){
                if (it.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null && it.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Item_Source__c == 'Kit'){
                    parentSolToParentFul.put(it.Sales_Order_Line__r.Parent_Sales_Order_Line__c, null);
                }

                itType = it.Type__c; //'Sales Order Undo Shipment';
            }
            // populate fulfillment value for map. Used for fulfilling Non-shippable parent SOL when child lines are shipped.
            if (!parentSolToParentFul.keySet().isEmpty()){
                // used in Ship confirm and undo ship confirm. Retrieves the most recently created fulfillment to match to Fulfillment Lines. Qty will be posisitive for Confirm Ship and negative for Undo ship
                for (Fulfillment__c ful : [select id, Type__c, Shipment_Line__c,Sales_order_Line__c, Sales_order_Line__r.Parent_Sales_Order_Line__c,Quantity__c,Invoice_Ready__c
                                            from Fulfillment__c
                                            where Sales_Order_Line__c IN : parentSolToParentFul.keySet() ORDER BY Id DESC])
                {
                    if (parentSolToParentFul.get(ful.Sales_Order_Line__c) == null){
                        parentSolToParentFul.put(ful.Sales_Order_Line__c, ful);
                    } 
                }
            }
            Map<Id,Fulfillment__c> parentReverseKit = new Map<Id,Fulfillment__c>();
            
            if (itType == 'Sales Order Undo Shipment'){
                if (!parentSolToParentFul.isEmpty()){
                    SalesOrderLineService.createNegativeFulfillments(parentSolToParentFul);
                    for(Fulfillment__c ff:parentSolToParentFul.values()){
                    	parentReverseKit.put(ff.Sales_order_Line__c,ff);
                    }
                    
                }
            }

            // potential parent SOL for creating non-shippable child
            Set<Id> solForNSChildFul = new Set<Id>();
            Set<Id> solineNSIds = new Set<Id>();
            List<Fulfillment__c> fulfilList = new List<Fulfillment__c>();
            for(Inventory_Transaction__c it : invTrxns){
            	if (it.Fulfillments__r.isEmpty() && (it.Type__c.equalsIgnoreCase('Sales Order Shipment') || it.Type__c.equalsIgnoreCase('Sales Order Undo Shipment') ||
                it.Type__c.equalsIgnoreCase('RMA Repair Shipment') || it.Type__c.equalsIgnoreCase('RMA Repair Undo Shipment') 
                || ((it.Type__c.equalsIgnoreCase('Work Order Repair Assembly Completion') || it.Type__c.equalsIgnoreCase('Work Order Repair Assembly Uncompletion')) && it.Work_Order__r.Field_Service__c == true))) {
                 	
                    Fulfillment__c iX;
                    if(mFulfillments.containsKey(it.Id)){
                    	iX = mFulfillments.get(it.Id);
                    }else{
                    	iX = new Fulfillment__c();
                    }
					
					List<Id> lstPkgUom = (List<Id>) JSON.deserialize( it.Item__r.Packaging_UOM__c, List<Id>.class );
                    // returns 1 if UOMs are null

                    iX.Company__c = it.Sales_Order_Line__r.Company__c;
                    iX.Currency__c = it.Sales_Order_Line__r.Sales_Order__r.Currency__c;
                    //Set fulfillment type as 'Rental' if the Sales Order Line is Rental.
                    iX.Type__c = it.Sales_Order_Line__r.Rental__c ? 'Rental' : it.Type__c;
                    iX.Customer__c =  it.Sales_Order_Line__r.Customer_Site__c != null ?  it.Sales_Order_Line__r.Customer_Site__c : it.Sales_Order_Line__r.Sales_Order__r.Customer__c;
                    iX.Inventory_Transaction__c  = it.Id;
                    iX.Agreement__c = it.Sales_Order_Line__r.Agreement_Line__r.Agreement__c;
                    iX.Agreement_Line__c = it.Sales_Order_Line__r.Agreement_Line__c;
                    iX.Sales_Order_Line__c = it.Sales_Order_Line__c;
                    iX.Sales_Order__c = it.Sales_Order_Line__r.Sales_Order__c;
                    iX.Billing_UOM__c = it.Sales_Order_Line__r.Sales_Order__r.Billing_UOM__c;
                    iX.Recurrence_Start_Date__c = it.Sales_Order_Line__r.Sales_Order__r.Recurrence_Start_Date__c;
                    iX.Shipment_Line__c = it.Shipment_Line__c;
                    iX.Product__c = it.Sales_Order_Line__r.Product__c;
                    iX.Category__c = it.Sales_Order_Line__r.Agreement_Line__r.Billing_Category__c;
                    if (it.Type__c.equalsIgnoreCase('Sales Order Shipment') || it.Type__c.equalsIgnoreCase('RMA Repair Shipment') || it.Type__c.equalsIgnoreCase('Work Order Repair Assembly Completion')) {
                        Decimal cf = KSE.GetConversionFactor(it.Item__c,it.From_Facility__r.Facility_Identifier__c, it.Sales_Order_Line__r.Selling_UOM__c, it.Item__r.Stocking_UOM__c, lstPkgUom );
                        iX.Quantity__c = it.Quantity_Stocking_UOM__c / cf;
                    	iX.Skid__c = it.To_Skid__c; //Install base already created
                    			//(it.Sales_Order_Line__r.Quantity_Ordered__c - it.Sales_Order_Line__r.Quantity_Shipped__c) < it.Quantity__c 
                                //            ? it.Quantity__c
                                //            : it.Sales_Order_Line__r.Quantity_Ordered__c - (it.Sales_Order_Line__r.Quantity_Ordered__c - it.Sales_Order_Line__r.Quantity_Shipped__c);
                     }else if(it.Type__c.equalsIgnoreCase('Sales Order Undo Shipment') || it.Type__c.equalsIgnoreCase('RMA Repair Undo Shipment') || it.Type__c.equalsIgnoreCase('Work Order Repair Assembly Uncompletion') ){
                        Decimal cf = KSE.GetConversionFactor(it.Item__c,it.To_Facility__r.Facility_Identifier__c, it.Sales_Order_Line__r.Selling_UOM__c, it.Item__r.Stocking_UOM__c, lstPkgUom );
                        iX.Quantity__c = (-1)*it.Quantity_Stocking_UOM__c / cf;
                    	iX.Skid__c = it.From_Skid__c; //Install base already created
                    		//(-1)*((it.Sales_Order_Line__r.Quantity_Ordered__c - it.Sales_Order_Line__r.Quantity_Shipped__c) < it.Quantity__c 
                            //                ? it.Quantity__c
                            //                : it.Sales_Order_Line__r.Quantity_Ordered__c - (it.Sales_Order_Line__r.Quantity_Ordered__c - it.Sales_Order_Line__r.Quantity_Shipped__c));
                    }

                    iX.Fulfillment_Date__c = it.Transaction_Date__c != null ? it.Transaction_Date__c : system.now(); 
                    
                    //KNDY-12754 
 					
 					if(it.Sales_Order_Line__r.Start_Date__c != null){
 						if(ix.Fulfillment_Date__c > it.Sales_Order_Line__r.Start_Date__c){
 							iX.Start_Date__c = iX.Fulfillment_Date__c;
 						}
 						else{
 							iX.Start_Date__c = it.Sales_Order_Line__r.Start_Date__c;
 						}
 					}
 					else if(it.Sales_Order_Line__r.Start_Date__c == null){
 						iX.Start_Date__c = iX.Fulfillment_Date__c;
 					}

                    if (it.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null && it.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Item_Source__c == 'Kit'){
                        if (parentSolToParentFul.containsKey(it.Sales_order_Line__r.Parent_Sales_Order_Line__c) && parentSolToParentFul.get(it.Sales_order_Line__r.Parent_Sales_Order_Line__c) != null) {
                            ix.Parent_Fulfillment__c = parentSolToParentFul.get(it.Sales_order_Line__r.Parent_Sales_Order_Line__c).id;
                            fulfilList.add(parentSolToParentFul.get(it.Sales_order_Line__r.Parent_Sales_Order_Line__c));
                            solineNSIds.add(it.Sales_order_Line__r.Parent_Sales_Order_Line__c);
                            ix.Invoice_Ready__c = false;
                        } else {
                            //throw new FulfillmentException('Cannot find parent fulfillment.');
                            System.debug(loggingLevel.Error, 'Could not find sales order line parent Fulfillment: ' + it.Sales_Order_Line__r);
                        }
                    } else if (it.Type__c.equalsIgnoreCase('Sales Order Undo Shipment') || it.Type__c.equalsIgnoreCase('RMA Repair Undo Shipment') || (it.Sales_Order_Line__r.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_RMA_REPAIR && it.Sales_Order_Line__r.Invoiceable__c != true) || (it.Sales_Order_Line__r.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_REPAIR && it.Sales_Order_Line__r.Invoiceable__c != true)) {
                        iX.Invoice_Ready__c = false;
                    } else if (SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(it.Sales_Order_Line__r.Sales_Order__r.Type__c)) {
                        ix.Invoice_Ready__c = it.Sales_Order_Line__r.Invoiceable__c;
                    } else if (activateFulfillments() && iX.Type__c == 'Rental'){
                        iX.Invoice_Ready__c = false;
                    } else {
                        iX.Invoice_Ready__c = true;
                    }

                    iX.Status__c = 'Complete';
                    iX.UOM__c = it.Sales_Order_Line__r.Selling_UOM__c;
                    iX.Unit_Cost__c = it.To_Standard_Cost__c == null ? 0 : it.To_Standard_Cost__c;
                    iX.Extended_Cost__c = iX.Unit_Cost__c * iX.Quantity__c;
                    iX.Unit_Price__c = it.Sales_Order_Line__r.Unit_Price__c; //KNDY-7535
                    //iX.Extended_Price__c = iX.Unit_Price__c * iX.Quantity__c;
                    //fulfillments.add(iX);
                    iX.Payment_Term__c=it.Sales_Order_Line__r.Sales_Order__r.payment_term__c; //KNDY-8750
                    mFulfillments.put(it.Id, iX);

                    solForNSChildFul.add(iX.Sales_Order_Line__c);

                }else{
                    //TODO: Mismatch or changes to the ITs?
                }
            }
            
            if(mFulfillments.keySet().size() > 0){
            	system.debug('mFulfillments: ' + mFulfillments);
                DML.upsertAsSystem(); upsert mFulfillments.values();
            }

            // create fulfillment for Warranty Child lines and SO Repair orders
            if (!solForNSChildFul.isEmpty()) {
                createChildFulfillments(solForNSChildFul, mFulfillments.values());
            }
            
            if(fulfilList.size() >0){
            	createChildFulfillments(solineNSIds, fulfilList);
            }
            List<Fulfillment__c> updateFulfillList = new List<Fulfillment__c>();
            Set <Id> sobjKeySet = parentReverseKit.keySet();
            if(sobjKeySet.size() >0){
            	
            	Set<String> fulfillFields = new Set<String>{ 'Id', 'Name','Invoice_Ready__c', 'Sales_Order__c', 'Sales_Order_Line__r.Parent_Sales_Order_Line__c', 'Type__c','Parent_Fulfillment__c','Sales_Order_Line__c', 'Sales_Order__c' };
            	SOQLUtil fulfilQuery = new SOQLUtil('Fulfillment__c');
           
            	fulfilQuery.addFields(fulfillFields);
            	fulfilQuery.setWhereClause('Parent_Fulfillment__c = null and Type__c = \'Sales Order Undo Shipment\'  and Sales_Order_Line__r.Product__r.Item__r.Non_Inventory__c = true  and Sales_Order_Line__r.Parent_Sales_Order_Line__c IN :sobjKeySet ORDER BY Id DESC');
            	
            	List<Fulfillment__c> fulfillmentlist = Database.query(fulfilQuery.getQuery());
            	
            	for(Fulfillment__c ful:fulfillmentlist){
            	
            		if(parentReverseKit.containskey(ful.Sales_Order_Line__r.Parent_Sales_Order_Line__c)){
            			ful.Parent_Fulfillment__c = parentReverseKit.get(ful.Sales_Order_Line__r.Parent_Sales_Order_Line__c).Id; //Updating Parent Fulfillment on Non Inventory Item
            			updateFulfillList.add(ful);
            		}
            	}
            	
            }
            
            if(updateFulfillList.size()>0){
	        	DML.updateAsSystem(updateFulfillList);
	        }

        }
        catch(Exception ex){
        	Database.rollback(sp);
            system.debug('ex: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
            throw new FulfillmentException(ex.getMessage());
        }
    
    }
    
    public static void createChildFulfillments(set<id> parentSolIds, List<Fulfillment__c> fulList){

        // used for populating Parent Fulfillment field when creating child fulfillments
        Map<Id, List<Fulfillment__c>> solIdToFulTo = new Map<Id, List<Fulfillment__c>>();
        for (Fulfillment__c ful:fulList){
            if (parentSolIds.contains(ful.Sales_Order_Line__c)) {
                if (!solIdToFulTo.containsKey(ful.Sales_Order_Line__c)) solIdToFulTo.put(ful.Sales_Order_Line__c, new List<Fulfillment__c>());
                solIdToFulTo.get(ful.Sales_Order_Line__c).add(ful);
            }
        }

        Map<Id, List<Fulfillment__c>> solFulMap = new Map<Id, List<Fulfillment__c>>();
        Set<Id> childSolIds = new Set<Id>();

        // pick up closed lines for reverse fulfillments
        List<Sales_Order_Line__c> childLines = [select Id, Invoiceable__c,Parent_Sales_Order_Line__c, Product__r.Product_Type__c,
                                                    Quantity_Fulfilled__c, Sales_Order__r.Type__c,Ship_From_Location__r.Facility__r.Facility_Identifier__c,
                                                    Parent_Sales_Order_Line__r.Quantity_Ordered__c,
                                                Quantity_Ordered__c, Status__c, Product__r.Name,
                                                Selling_UOM__c,
                                                Parent_Sales_Order_Line__r.Selling_UOM__c,
                                                Product__r.Item__c,Product__r.Item__r.Packaging_UOM__c,
                                                (Select Id, Name, Invoice_Ready__c,Quantity__c, Parent_Fulfillment__c, Parent_Fulfillment__r.Invoice_Ready__c from Fulfillments__r where Invoice_Ready__c = true)
                                                    from Sales_Order_Line__c
                                                    where Parent_Sales_Order_Line__c IN: parentSolIds
                                                    and Non_Shippable__c = true
                                                    and (Sales_Order__r.Type__c = 'Repair' OR Product__r.Product_Type__c = 'Warranty')
                                                    and Status__c IN (:SalesOrderService.SO_STATUS_OPEN, :SalesOrderService.SO_STATUS_CLOSED)];

		Map<Id, Fulfillment__c> updateparentfulfillments = new Map<Id, Fulfillment__c>();
        // for 'Warranty' product type SOL child lines OR 'Repair' SO type
        for (Sales_order_Line__c childSol : childLines){
            if (!solIdToFulTo.containsKey(childSol.Parent_Sales_Order_Line__c)) continue;

            for (Fulfillment__c parentFul:solIdToFulTo.get(childSol.Parent_Sales_Order_Line__c)) {
                // skip closed child SOL lines since they're already fulfilled
                if (parentFul.Quantity__c > 0 && childSol.Status__c == SalesOrderService.SO_STATUS_CLOSED){
                    continue;
                }

                Fulfillment__c ix = new Fulfillment__c();
				
				List<Id> lstPkgUom = (List<Id>) JSON.deserialize( childSol.Product__r.Item__r.Packaging_UOM__c, List<Id>.class );
                // convert parent prod to child prod
                Decimal cf = KSE.GetConversionFactor(childSol.Product__r.Item__c, childSol.Ship_From_Location__r.Facility__r.Facility_Identifier__c, childSol.Selling_UOM__c, childSol.Parent_Sales_Order_Line__r.Selling_UOM__c, lstPkgUom);

                Decimal childSOLQty = (childSol.Quantity_Ordered__c - childSol.Quantity_Fulfilled__c);

                // Set quantity on child fulfillment
                Decimal qtyToFulfill = 0;
                if ((childSOLQty * cf) >= parentFul.Quantity__c) {
                    qtyToFulfill = parentFul.Quantity__c / cf;
                } else {
                    qtyToFulfill = childSOLQty;
                }

                // set type on child fulfillment
                String childFullfilmentType = '';
                if (childSol.Product__r.Product_Type__c == null){
                    childFullfilmentType = 'Non-shippable Product';
                } else {
                    childFullfilmentType = childSol.Product__r.Product_Type__c;
                }

                if (parentFul.Quantity__c > 0){
                    ix.Type__c = childFullfilmentType;
                    ix.Quantity__c = qtyToFulfill;
                } else {
                    ix.Type__c = 'Reverse ' + childFullfilmentType;
                    if (qtyToFulfill > 0){
                        ix.Quantity__c = -qtyToFulfill; // for non-partials
                    } else {
                        ix.Quantity__c = qtyToFulfill; // for partials orders
                        if( Math.abs(ix.Quantity__c) > childSol.Quantity_Ordered__c ){
                        	ix.Quantity__c = -(childSol.Quantity_Ordered__c);
                        }
                        
                      
                    }
                    if(childSol.Product__r.Product_Type__c == 'Warranty' && childSol.Fulfillments__r !=null){
                    	for(Fulfillment__c fulfil:childSol.Fulfillments__r){
                    		
                    		if(fulfil.Quantity__c == Math.abs(ix.Quantity__c) && fulfil.Parent_Fulfillment__r.Invoice_Ready__c == false){
                    			fulfil.Invoice_Ready__c = false;//Marking Original Warranty positive fulfillment as Invoice Ready false.
                    			updateparentfulfillments.put(fulfil.Id, fulfil);
                    		}
                    	}
                    	
                    	
                    }
                }

                ix.Parent_Fulfillment__c = parentFul.id;

                if (!solFulMap.containsKey(childSol.Id)) solFulMap.put(childSol.Id, new List<Fulfillment__c>());
                solFulMap.get(childSol.Id).add(ix);
                childSolIds.add(childSol.id);
            }
        }

        if (!childSolIds.isEmpty()){
            fulfillSalesOrders(childSolIds, solFulMap);
        }
        
        if(updateparentfulfillments.size()>0){
        	DML.updateAsSystem(updateparentfulfillments.values());
        }
    }

    @TestVisible
    private static set<Id> processedShipmentLineIds = new set<Id>();
    public static void fulfillNonInventoryItems(set<Id> shipmentLineIds){
    	if(processedShipmentLineIds.containsAll(shipmentLineIds)){
        	return;
        }
        processedShipmentLineIds.addAll(shipmentLineIds);
    	Savepoint sp = Database.setSavepoint();
        try{
            //Find stubs and attach details 1:1
            Map<Id, Fulfillment__c> mFulfillments = new Map<Id, Fulfillment__c>();


	        Map<Id, Fulfillment__c> updateFulfillments = new Map<Id, Fulfillment__c>();	
            SOQLUtil soql = new SOQLUtil('Shipment_Line__c', false); //enforceFLS=false, running in system mode
			soql.addFields(new set<string>{
				'Id','Shipment__r.Date_Shipped__c','Unit_Price__c','Quantity_Shipped__c','Sales_Order_Line__c','Sales_Order_Line__r.Agreement_Line__r.Agreement__c',
				'Sales_Order_Line__r.Agreement_Line__r.Billing_Category__c', 
				'Sales_Order_Line__r.Quantity_Ordered__c','Sales_Order_Line__r.Quantity_Shipped__c',
				'Sales_Order_Line__r.Parent_Sales_Order_Line__r.Item_Source__c', 'Sales_Order_Line__r.Returned_To_Vendor__c','Sales_Order_Line__r.Invoiceable__c',
				'Sales_Order_Line__r.Start_Date__c',
				'Sales_Order_Line__r.Unit_Price__c','Sales_Order_Line__r.Product__c','Sales_Order_Line__r.Selling_UOM__c',
				'Sales_Order_Line__r.Fulfillment_Source__c','Sales_Order_Line__r.Sales_Order__r.Customer__c','Shipment__r.Type__c',
				'Extended_Cost__c','Sales_Order_Line__r.Customer_Site__c','Quantity_Planned__c','Sales_Order_Line__r.Company__c',
				'Sales_Order_Line__r.Sales_Order__r.Currency__c','Sales_Order_Line__r.Sales_Order__c','Product__r.Item__r.Non_Inventory__c','Sales_Order_Line__r.Quantity_Fulfilled__c','Sales_Order_Line__r.Quantity_Planned__c',
				'Sales_Order_Line__r.Sales_Order__r.payment_term__c','Sales_Order_Line__r.Agreement_Line__c','Sales_Order_Line__r.Sales_Order__r.Billing_UOM__c','Sales_Order_Line__r.Sales_Order__r.Recurrence_Start_Date__c',
				'Sales_Order_Line__r.Start_Date__c', 'Sales_Order_Line__r.Sales_Order__r.Type__c' 
			});
			soql.setWhereClause('Id IN :shipmentLineIds AND (Product__r.Item__r.Non_Inventory__c = true OR Sales_Order_Line__r.Fulfillment_Source__c = \'Drop Ship\')');
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Fulfillments__r');
			childRel.addFields(new set<string>{
				'Id','Quantity__c','Invoice_Ready__c','Unit_Price__c','Extended_Price__c', 'Extended_Cost__c','Sales_Order_Line__c','Sales_Order_Line__r.Quantity_Shipped__c','Sales_Order_Line__r.Quantity_Ordered__c'
			});
			soql.addChildRelationship(childRel);
			
            List<Shipment_Line__c> shipmentLines = Database.query(soql.getQuery());

            
            /* populate fulfillment parent id if fulfillment SOL has a parent */
            Map<Id, Fulfillment__c> parentSolToParentFul = new Map<Id, Fulfillment__c>();
            for(Shipment_Line__c shl : shipmentLines){
                if(shl.Quantity_Shipped__c != null){
                	Fulfillment__c iX;
                    if(mFulfillments.containsKey(shl.Sales_Order_Line__c)){
                    	iX = mFulfillments.get(shl.Sales_Order_Line__c);
                    }else{
                    	iX = new Fulfillment__c();
                    }
                    iX.Company__c = shl.Sales_Order_Line__r.Company__c;
                    iX.Currency__c = shl.Sales_Order_Line__r.Sales_Order__r.Currency__c;
                    iX.Type__c = shl.Shipment__r.Type__c;
                    iX.Customer__c = shl.Sales_Order_Line__r.Customer_Site__c != null ?  shl.Sales_Order_Line__r.Customer_Site__c : shl.Sales_Order_Line__r.Sales_Order__r.Customer__c;
                    iX.Agreement__c = shl.Sales_Order_Line__r.Agreement_Line__r.Agreement__c;
                    iX.Agreement_Line__c = shl.Sales_Order_Line__r.Agreement_Line__c;
                    iX.Billing_UOM__c = shl.Sales_Order_Line__r.Sales_Order__r.Billing_UOM__c;
                    iX.Recurrence_Start_Date__c = shl.Sales_Order_Line__r.Sales_Order__r.Recurrence_Start_Date__c;
                    iX.Sales_Order_Line__c = shl.Sales_Order_Line__c;
                    iX.Sales_Order__c = shl.Sales_Order_Line__r.Sales_Order__c;
                    iX.Shipment_Line__c = shl.Id;
                    iX.Product__c = shl.Sales_Order_Line__r.Product__c;
                    iX.Category__c = shl.Sales_Order_Line__r.Agreement_Line__r.Billing_Category__c;
                    iX.Quantity__c = shl.Quantity_Shipped__c;

                    if( iX.Quantity__c == 0 ){
                        Shipment_Line__c oldSHL ;
                  	if( Trigger.oldMap != null && (!Trigger.oldMap.isEmpty()) ){
                    	 oldSHL = (Shipment_Line__c) Trigger.oldMap.get(shl.Id);	
                   	}
                        
                     if(shl.Product__r.Item__r.Non_Inventory__c == true || shl.Sales_Order_Line__r.Fulfillment_Source__c == 'Drop Ship'){
                            if(oldSHL != null){
                              iX.Quantity__c -= oldSHL.Quantity_Shipped__c;   
                            }
                     }
                       //iX.Quantity__c -= shl.Quantity_Planned__c; 
                        iX.Type__c = 'Sales Order Undo Shipment';
                        
                        for(Fulfillment__c ff:shl.Fulfillments__r){
                        	if(ff.Invoice_Ready__c == true){
                        		
                        		ff.Invoice_Ready__c = false;
                        		updateFulfillments.put(shl.Id,ff);
                        	}
                        	
                        }
                        
                    }
					if(ShipmentInventoryService.confirmShipMap !=null && ShipmentInventoryService.confirmShipMap.containskey(shl.Shipment__c)){
						Shipment__c shipObj = ShipmentInventoryService.confirmShipMap.get(shl.Shipment__c);
						iX.Fulfillment_Date__c = shipObj.Date_Shipped__c;
					}
					else
						iX.Fulfillment_Date__c = system.now();
						
                    
                    //KNDY-12754
                    if(shl.Sales_Order_Line__r.Start_Date__c != null){
                    	
 						if(ix.Fulfillment_Date__c > shl.Sales_Order_Line__r.Start_Date__c){
 							iX.Start_Date__c = iX.Fulfillment_Date__c;
 						}
 						else{
 							iX.Start_Date__c = shl.Sales_Order_Line__r.Start_Date__c;
 						}
 					}
 					else if(shl.Sales_Order_Line__r.Start_Date__c == null){
 						iX.Start_Date__c = iX.Fulfillment_Date__c;
 					}
 					
 					if (shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null && shl.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Item_Source__c == 'Kit'){
                    	parentSolToParentFul.put(shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c, null);
                	}
                	
                	
                	// populate fulfillment value for map. Used for fulfilling Non-shippable parent SOL when child lines are shipped.
		            if (!parentSolToParentFul.keySet().isEmpty()){
		                // used in Ship confirm and undo ship confirm. Retrieves the most recently created fulfillment to match to Fulfillment Lines. Qty will be posisitive for Confirm Ship and negative for Undo ship
		                for (Fulfillment__c ful : [select id, Sales_order_Line__c, Quantity__c,Invoice_Ready__c
		                                            from Fulfillment__c
		                                            where Sales_Order_Line__c IN : parentSolToParentFul.keySet() ORDER BY Id DESC])
		                {
		                    if (parentSolToParentFul.get(ful.Sales_Order_Line__c) == null){
		                        parentSolToParentFul.put(ful.Sales_Order_Line__c, ful);
		                    } 
		                }
		            }
 					
                    if(iX.Type__c == 'Sales Order Undo Shipment' || SalesOrderService.SO_RMA_REPLACEMENT_TYPES.contains(shl.Sales_Order_Line__r.Sales_Order__r.Type__c) == true || (shl.Sales_Order_Line__r.Sales_Order__r.Type__c == SalesOrderService.SO_TYPE_REPAIR && shl.Sales_Order_Line__r.Invoiceable__c != true)){
                    	iX.Invoice_Ready__c = false;//Negative and Positive fulfillment for RMA Replacement should not be marked INV Ready.
                    }
                    else
                    	iX.Invoice_Ready__c = true;
					
					if (shl.Sales_Order_Line__r.Parent_Sales_Order_Line__c != null && shl.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Item_Source__c == 'Kit'){
                        ix.Invoice_Ready__c = false;
                        if (iX.Type__c == 'Sales Order Shipment' && parentSolToParentFul.containsKey(shl.Sales_order_Line__r.Parent_Sales_Order_Line__c) && parentSolToParentFul.get(shl.Sales_order_Line__r.Parent_Sales_Order_Line__c) != null) {
                            ix.Parent_Fulfillment__c = parentSolToParentFul.get(shl.Sales_order_Line__r.Parent_Sales_Order_Line__c).id;
                        }
                    }
					
                    iX.Status__c = 'Complete';
                    iX.UOM__c = shl.Sales_Order_Line__r.Selling_UOM__c;
                    iX.Unit_Cost__c = shl.Extended_Cost__c/iX.Quantity__c;
                    iX.Extended_Cost__c = shl.Extended_Cost__c;
                    iX.Unit_Price__c = shl.Sales_Order_Line__r.Unit_Price__c; //KNDY-7535
                    //iX.Extended_Price__c = iX.Unit_Price__c * iX.Quantity__c;
                    iX.Payment_Term__c = shl.Sales_Order_Line__r.Sales_Order__r.payment_term__c; //KNDY-8750
                    //fulfillments.add(iX);
                    mFulfillments.put(shl.Id, iX);
                }
            }
            if(mFulfillments.keySet().size() > 0){
            	system.debug('nonInventory mFulfillments: ' + mFulfillments);
                DML.upsertAsSystem(); upsert mFulfillments.values();
            }
            if(updateFulfillments.values().size()>0){
            	DML.upsertAsSystem(); upsert updateFulfillments.values();
            }
        }catch(Exception ex){
        	Database.rollback(sp);
        	throw ex;
        }
    
    }
    
    private static set<Id> processedFulfillmentIds = new set<Id>();
    private static set<Id> updatedFulfillmentIds = new set<Id>();
    public static void generateInstallBaseSKIDs(List<Fulfillment__c> fulfillments){
    	map<Id, Fulfillment__c> mProcessedFulfillments = new map<Id, Fulfillment__c>(fulfillments);
    	if(processedFulfillmentIds.containsAll(mProcessedFulfillments.keySet())){
    		return;
    	}
    	
    	processedFulfillmentIds.addAll(mProcessedFulfillments.keySet());
    	map<string, SKID__c> mSKIDs = new Map<string, SKID__c>();
    	map<string, set<Id>> mInvTrxnSkids = new map<string, set<Id>>();
    	map<string, set<Id>> mFulfillmentSkids = new map<string, set<Id>>();
    	set<Id> siteIds = new set<Id>();
    	set<Id> itemIds = new set<Id>();
    	set<Id> skidIds = new set<Id>();
    	set<Id> customerIds = new set<Id>();
    	
    	//Idempotency
    	List<Fulfillment__c> openFulfillments = [SELECT Id, Type__c, Company__c, Status__c, Inventory_Transaction__c, Quantity__c, UOM__c, Sales_Order_Line__c, Sales_Order_Line__r.Customer_Site__c,
    												Inventory_Transaction__r.Item__c, Inventory_Transaction__r.Item__r.Track_Install_Base__c, 
    												Inventory_Transaction__r.Item__r.Stocking_UOM__c, Inventory_Transaction__r.Item__r.Packaging_UOM__c,
    												Sales_Order_Line__r.Sales_Order__r.Ship_To__r.Track_Install_Base__c, Sales_Order_Line__r.Product__c,
    												Sales_Order_Line__r.Parent_Sales_Order_Line__c, Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__c,
    												Sales_Order_Line__r.Parent_Sales_Order_Line__r.Quantity_Shipped__c, Sales_Order_Line__r.Quantity_Shipped__c,
    												Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__r.Item__c, Sales_Order_Line__r.Product__r.Item__c,
                                                    Customer__c, Customer__r.Top_Parent_Customer__c, Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c,
                                                    Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c, Sales_Order_Line__r.Parent_Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c
    												FROM Fulfillment__c 
    												WHERE Id IN :fulfillments 
    												AND Sales_Order_Line__r.Sales_Order__r.Ship_To__r.Track_Install_Base__c = true
    												AND Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c = true
    												AND ( SKID__c = null OR Type__c = 'Deinstall')
    												AND Type__c NOT IN('RMA') 
    												AND ID NOT IN :updatedFulfillmentIds]; 
    												
		system.debug('openFulfillments: ' + openFulfillments);
    	if(!openFulfillments.isEmpty()){
	    	for(Fulfillment__c f : openFulfillments){
	    		siteIds.add(f.Sales_Order_Line__r.Customer_Site__c);
	    		itemIds.add(f.Inventory_Transaction__r.Item__c);
	    		customerIds.add(f.Customer__c);
	    		if(f.Customer__r.Top_Parent_Customer__c != null){
    				customerIds.add(f.Customer__r.Top_Parent_Customer__c);
	    		}
	    	}
	    	List<SKID__c> existingInstallSKIDs = [SELECT Id, Customer__c, Product__c, Item__c, Quantity__c, Item_UOM__c, Sales_Order_Line__c, Facility2__r.Facility_Identifier__c
	    													FROM SKID__c 
	    													WHERE Type__c = 'Install Base'
	    													AND (Customer__c IN :customerIds OR Customer__r.Top_Parent_Customer__c IN :customerIds)]; 
	    	
	    	
	    	for(SKID__c skid : existingInstallSKIDs){
	    		string installSKIDKey = skid.Customer__c + '|' + skid.Product__c + '|' + skid.Sales_Order_Line__c;
	    		mSKIDs.put(installSKIDKey, skid);
	    		skidIds.add(skid.Id);
	    	}											
			
			for(Fulfillment__c f : openFulfillments){
				system.debug('f: ' + f);
				if(f.Type__c == 'Deinstall' || f.Status__c != 'Complete') continue;
				SKID__c iSKID;
				//Generate Install SKID Key
				string installSKIDKey;
				id solId;
				id productId;
				id itemId;
				Decimal facilityId;
				decimal qty;
				Id custId = f.Sales_Order_Line__r.Customer_Site__c != null ? f.Sales_Order_Line__r.Customer_Site__c : f.Sales_Order_Line__r.Sales_Order__r.Ship_To__c;
                if(f.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__c != null && f.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__r.Item__r.Track_Install_Base__c){
					system.debug('found parent line: ' + f.Sales_Order_Line__r.Parent_Sales_Order_Line__c);
					solId = f.Sales_Order_Line__r.Parent_Sales_Order_Line__c;
					productId = f.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__c;
					itemId = f.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__r.Item__c;
					qty = f.Quantity__c == null ? 0 : f.Quantity__c; //f.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Quantity_Shipped__c;
					installSKIDKey = custId + '|' + f.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Product__c + '|' + f.Sales_Order_Line__r.Parent_Sales_Order_Line__c;
					facilityId = f.Sales_Order_Line__r.Parent_Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c;
				}else{
					system.debug('no parent line: ' + f.Sales_Order_Line__c);
					solId = f.Sales_Order_Line__c;
					productId = f.Sales_Order_Line__r.Product__c;
					itemId = f.Sales_Order_Line__r.Product__r.Item__c;
					qty = f.Quantity__c == null ? 0 : f.Quantity__c;//f.Sales_Order_Line__r.Quantity_Shipped__c;
					installSKIDKey = custId + '|' + f.Sales_Order_Line__r.Product__c + '|' + f.Sales_Order_Line__c;
					facilityId = f.Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c;
				}
				
				//Find or generate SKID based on Key
				if(mSKIDs.containsKey(installSKIDKey)){
					system.debug('existing skid found: ' + installSKIDKey);
					iSKID = mSKIDs.get(installSKIDKey);
					iSKID.Quantity__c = iSKID.Quantity__c == null ? 0 : iSKID.Quantity__c;
				}else{
					system.debug('no existing skid found: ' + installSKIDKey);
					iSKID = new SKID__c();
					iSKID.Sales_Order_Line__c = solId;
					iSKID.Product__c = productId;
					iSKID.Type__c = 'Install Base';
					iSKID.Item__c = itemId;
					iSKID.Customer__c = custId; //f.Sales_Order_Line__r.Sales_Order__r.Ship_To__c;
					iSKID.Quantity__c = 0;
					iSKID.Company__c = f.Company__c;
                    
                    //String Message= string.join(SkidService3.generateKey(iSKID,null), ',');                
                    //iSKID.unique_Key__c = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-1', Blob.valueOf(Message))); 

				}
				//Check UOM, convert qty as necessary
				if(f.UOM__c != null && f.Inventory_Transaction__r.Item__r.Stocking_UOM__c != null && f.Inventory_Transaction__r.Item__r.Packaging_UOM__c != null ){
					List<Id> lstPkgUom = (List<Id>) JSON.deserialize( f.Inventory_Transaction__r.Item__r.Packaging_UOM__c, List<Id>.class );
					iSKID.Quantity__c += qty * KSE.getConversionFactor(iSKID.Item__c, iSKID.Facility2__r.Facility_Identifier__c, f.UOM__c, f.Inventory_Transaction__r.Item__r.Stocking_UOM__c, lstPkgUom);
				}else{
					iSKID.Quantity__c += qty;
				}
				system.debug('qty iSKID: ' + qty + ' - ' + iSKID);
				
				mSKIDs.put(installSKIDKey, iSKID);
				if(mInvTrxnSkids.containsKey(installSKIDKey)){
					mInvTrxnSkids.get(installSKIDKey).add(f.Inventory_Transaction__c);
				}else{
					mInvTrxnSkids.put(installSKIDKey, new set<Id>{f.Inventory_Transaction__c});
				}
				if(mFulfillmentSkids.containsKey(installSKIDKey)){
					mFulfillmentSkids.get(installSKIDKey).add(f.Id);
				}else{
					mFulfillmentSkids.put(installSKIDKey, new set<Id>{f.Id});
				}
			}
			
			
			if(!mSKIDs.isEmpty()){
				Savepoint sp = Database.setSavepoint();
				try{
					DML.upsertAsSystem(); upsert mSKIDs.values();
					for(SKID__c skid : mSKIDs.values()){
						system.debug('skid: ' + skid);
						skidIds.add(skid.Id);
					}
					
					//update ITs
					Map<Id, Inventory_Transaction__c> mInvTrxns = new Map<Id, Inventory_Transaction__c>();
					for(string key : mInvTrxnSkids.keySet()){
						system.debug('key: ' + key + ' - ' + mInvTrxnSkids.get(key));
						if(mSKIDs.containsKey(key)){
							for(Id itId : mInvTrxnSkids.get(key)){
								if(itId == null)	 continue;
								system.debug('found key');
								Inventory_Transaction__c it = new Inventory_Transaction__c(Id = itId);
								it.To_SKID__c = mSKIDs.get(key).Id;
								mInvTrxns.put(it.Id, it);
							}
						}
					}
					if(mInvTrxns.keySet().size() > 0){
						system.debug('mInvTrxns.values(): ' + mInvTrxns.values());
						DML.upsertAsSystem(); upsert mInvTrxns.values();						
					}
					
					//update ITs
					Map<Id, Fulfillment__c> mFulfillments = new Map<Id, Fulfillment__c>();
					for(string key : mFulfillmentSkids.keySet()){
						system.debug('key: ' + key + ' - ' + mFulfillmentSkids.get(key));
						if(mSKIDs.containsKey(key)){
							for(Id fId : mFulfillmentSkids.get(key)){
								system.debug('found key');
								Fulfillment__c f = new Fulfillment__c(Id = fId);
								f.SKID__c = mSKIDs.get(key).Id;
								mFulfillments.put(f.Id, f);
							}
						}
					}
					if(mFulfillments.keySet().size() > 0){
						system.debug('mFulfillments.values(): ' + mFulfillments.values());
						updatedFulfillmentIds.addAll(mFulfillments.KeySet());
						DML.updateAsSystem(mFulfillments.values());
					}
					
					if(skidIds.size() > 0){
						updateInstallBaseSKIDQuantity(skidIds);
					}
				}catch(Exception ex){
					Database.rollback(sp);
					throw ex;
				}
			}
    	}
    
    }
    
    public static void updateInstallBaseSKIDQuantity(set<Id> skidIds){
    	
    	if(skidIds == null || skidIds.size() == 0) return;
    	
    	List<AggregateResult> arSKIDQty = [SELECT sum(quantity__c) qty, SKID__c skidId, 
    										SKID__r.Item__c skidItemId, Product__r.Item__c fulfItemId
    										FROM Fulfillment__c
    										WHERE SKID__c IN :skidIds
    										AND SKID__c != null
    										AND Quantity__c != null
    										AND Status__c = 'Complete'
    										GROUP BY SKID__c, SKID__r.Item__c, Product__r.Item__c];
    	
    	map<Id, SKID__c> mSKIDs = new map<Id, SKID__c>();
    	
    	for(Id skidId : skidIds){
    		SKID__c iSKID = new SKID__c(Id = skidId, Quantity__c = 0);
    		mSKIDs.put(iSKID.Id, iSKID);
    	}
    	
    	for(AggregateResult ar : arSKIDQTY){
    		
    		Id iSKIDId = (Id)ar.get('skidId');
    		Id iSkidItemId = (Id)ar.get('skidItemId');
    		Id iFulfItemId = (Id)ar.get('fulfItemId');
    		decimal iQty = (Decimal)ar.get('qty');
    		
    		if(iSkidItemId == iFulfItemId){
    			SKID__c iSKID;
    			if(mSKIDs.containsKey(iSKIDId)){
    				iSKID = mSKIDs.get(iSKIDId);
    			}else{
    				iSKID = new SKID__c(Id = iSKIDId, Quantity__c = 0);
    			}
    			iSKID.Quantity__c += iQty;
    			system.debug('iSKID: ' + iSKID);
				mSKIDs.put(iSKID.Id, iSKID);
    		}
    		
    	}
    	
    	if(mSKIDs.keySet().size() > 0){
    		DML.updateAsSystem(mSKIDs.values());
    	}									
    }
    
    
	public static void setFulfillmentDetails(List<Fulfillment__c> fulfillments){
		system.debug('set fulfillment details');
		set<id> solIds = new set<Id>();
        map<id,id> Faglids = new map<id,id>();
        map<id,id> mFlcustIds = new map<id,id>();
		set<string> fromCurrs = new set<string>();
		set<string> toCurrs = new set<string>();
		list<DateTime> dts = new list<DateTime>();
		for(Fulfillment__c f : fulfillments)
		{
			if(f.currency__c != null)
				fromCurrs.add(f.currency__r.ISO_code__c);
			if(f.fulfillment_date__c != null){
				dts.add(DateTime.newInstance(f.fulfillment_date__c.year(), f.fulfillment_date__c.month(), f.fulfillment_date__c.day()));
			}else{
				dts.add(system.now());	
			}
			
			if(f.Sales_Order_Line__c != null)
				solIds.add(f.Sales_Order_Line__c);
            
            if(f.payment_term__C == null){//KNDY-8750
                if(f.agreement_line__c!=null) Faglids.put(f.id,f.agreement_line__c);
                if(f.Customer__c!=null) mFlcustIds.put(f.id,f.Customer__c);
            }
                
		}
		
        if(!Faglids.isEmpty()){    
         	map<Id,Agreement_line__c> mAGLs = new map<Id,agreement_line__c> ([SELECT Id,agreement__r.Payment_Terms__c FROM agreement_line__c 
																	WHERE id in :Faglids.values()]); 
            if(!mAGLs.isEmpty()){
                for(Fulfillment__c f : fulfillments){
                    if(Faglids.containsKey(f.id)){
                        if(mAGLs.containsKey(Faglids.get(f.id))){
                          f.Payment_Term__c=  mAGLs.get(Faglids.get(f.id)).agreement__r.Payment_Terms__c;
                        }
                    }
                    
                }
            }
        }
        
         if(!mFlcustIds.isEmpty()){ 
             	map<Id,customer__C> mCusts = new map<Id,customer__C> ([SELECT Id,Payment_Term__c FROM customer__C 
																	WHERE id in :mFlcustIds.values()]); 
             for(Fulfillment__c f : fulfillments){
              if(mFlcustIds.containsKey(f.id) && f.Payment_Term__c==null){
                  if(mCusts.containsKey(mFlcustIds.get(f.id))){
                          f.Payment_Term__c=  mCusts.get(mFlcustIds.get(f.id)).Payment_Term__c;
                  }
              }
             
             }
             
         }
        
        
        
		dts.sort();
		if(!solids.isEmpty())
		{
			map<Id,Sales_Order_Line__c> mSOLs = new map<Id,Sales_Order_Line__c> ([
		SELECT Id, Description__c,Pricing_UOM__c,Price_Type__c, Agreement_Line__c, Agreement_Line__r.Agreement__c, Product__c, Selling_UOM__c,
		Sales_Order__r.Currency__c, Parent_Sales_Order_Line__c, Sales_Order__r.Customer__c,
		Product__r.Item__c, Company__c,Quantity_Ordered__c,Unit_Price__c,Billing_Category__c,Currency__c,
		Ship_From_Location__r.Facility__c, Start_Date__c, End_Date__c, Rate_Basis__c, Occurrence__c,
		Off_Invoice_Rate__c, Allowances__c, Discount_Percent__c, Freight_Allowance__c,
        Product__r.Product_Type__c, Product__r.Warranty_Period_Type__c, Product__r.Warranty_Period_Term__c,
        Sales_Order__r.Recurrence_Start_date__c, Sales_Order__r.Billing_UOM__c 
			FROM Sales_Order_Line__c
			WHERE id in :solIds]); 
			//AND Agreement_Line__c != null]);
														
            set<id> alId = new set<id>();
            
			if(!mSOLs.isEmpty())
			{
				system.debug('mSOLs: ' + mSOLs);
				for(Fulfillment__c f : fulfillments)
	    		{
	    			if(mSOLs.containsKey(f.Sales_Order_Line__c)){
	    				Sales_Order_Line__c iSOL = mSOLs.get(f.Sales_Order_Line__c);
	    				system.debug('iSOL '+iSOL.Sales_Order__r.Billing_UOM__c);
	    				system.debug('iSOL '+iSOL.Sales_Order__r.Recurrence_Start_date__c);
	    				f.Agreement__c = f.Agreement__c == null ? iSOL.Agreement_Line__r.Agreement__c : f.Agreement__c;
	    				f.Agreement_Line__c = f.Agreement_Line__c == null ? iSOL.Agreement_Line__c : f.Agreement_Line__c;
	    				f.Product__c = iSOL.Product__c;
	    				f.UOM__c = f.UOM__c == null ? iSOL.Selling_UOM__c : f.UOM__c;
	    				f.Currency__c = f.Currency__c == null ? iSOL.Sales_Order__r.Currency__c : f.Currency__c;
	    				f.Company__c = iSOL.Company__c;
	                    f.Customer__c = f.Customer__c == null? iSOL.Sales_Order__r.Customer__c : f.Customer__c;
	    				f.Sales_Order__c = iSOL.Sales_Order__c;
                        f.Fulfillment_Date__c = f.Fulfillment_Date__c == null ? system.now() : f.Fulfillment_Date__c;
                        f.Description__c = f.Description__c == null ? iSOL.Description__c : f.Description__c;
                        f.Quantity__c = f.Quantity__c == null ? iSOL.Quantity_Ordered__c : f.Quantity__c;
                        f.Category__c = f.Category__c == null ? iSOL.Billing_Category__c : f.Category__c;
                        f.Pricing_UOM__c  = f.Pricing_UOM__c  == null ? iSOL.Pricing_UOM__c  : f.Pricing_UOM__c ;
                        f.Price_Type__c    = f.Price_Type__c    == null ? iSOL.Price_Type__c    : f.Price_Type__c   ;
                        if (iSOL.Product__r != null && iSOL.Product__r.Warranty_Period_Type__c != null && iSOL.Product__r.Warranty_Period_Term__c != null && iSOL.Product__r.Product_Type__c == 'Warranty'){
                            f.Start_Date__c = system.now();

                            if (iSOL.Product__r.Warranty_Period_Type__c == 'Days'){
                                f.End_Date__c = System.now().addDays((Integer) iSOL.Product__r.Warranty_Period_Term__c);

                            } else if(iSOL.Product__r.Warranty_Period_Type__c == 'Weeks'){
                                Integer weeks = 7 * (Integer) iSOL.Product__r.Warranty_Period_Term__c;
                                f.End_Date__c = System.now().addDays(weeks);

                            } else if(iSOL.Product__r.Warranty_Period_Type__c == 'Months'){
                                f.End_Date__c = System.now().addMonths((Integer) iSOL.Product__r.Warranty_Period_Term__c);

                            } else if(iSOL.Product__r.Warranty_Period_Type__c == 'Years'){
                                f.End_Date__c = System.now().addYears((Integer) iSOL.Product__r.Warranty_Period_Term__c);
                            }

                        } else {
                            f.Start_Date__c = f.Start_Date__c == null ? iSOL.Start_Date__c : f.Start_Date__c ;
                            f.End_Date__c = f.End_Date__c == null ? iSOL.End_Date__c : f.End_Date__c;
                        }

                        f.Occurrence__c = f.Occurrence__c == null ? iSOL.Occurrence__c : f.Occurrence__c;
                        f.Rate_Basis__c = f.Rate_Basis__c == null ? iSOL.Rate_Basis__c : f.Rate_Basis__c;
                        f.Recurrence_Start_Date__c = f.Recurrence_Start_Date__c == null? iSOL.Sales_Order__r.Recurrence_Start_Date__c : f.Recurrence_Start_Date__c;
                        f.Billing_UOM__c = f.Billing_UOM__c  == null ? iSOL.Sales_Order__r.Billing_UOM__c : f.Billing_UOM__c ;
                        iSOL.Off_Invoice_Rate__c = iSOL.Off_Invoice_Rate__c == null ? 0 : iSOL.Off_Invoice_Rate__c;
			    		iSOL.Allowances__c = iSOL.Allowances__c == null ? 0 : iSOL.Allowances__c;
			    		iSOL.Freight_Allowance__c = iSOL.Freight_Allowance__c == null ? 0 : iSOL.Freight_Allowance__c;
			    		iSOL.Discount_Percent__c = iSOL.Discount_Percent__c == null ? 0 : iSOL.Discount_Percent__c;
						
						PricingService.RateBasis rb = PricingService.getRateBasis(f.Rate_Basis__c);
						decimal qtyMult = rb == PricingService.RateBasis.FLAT ? 1 : f.Quantity__c;
						
						//Simple solution:
						f.Unit_Price__c = f.Unit_Price__c == null ? iSOL.Unit_Price__c : f.Unit_Price__c;
						f.Extended_Price__c = f.Extended_Price__c == null
                        						? PricingService.returnPrice(qtyMult, f.Unit_Price__c, iSOL.Off_Invoice_Rate__c, iSOL.Allowances__c, iSOL.Freight_Allowance__c, iSOL.Discount_Percent__c)
                        						: f.Extended_Price__c;
                         
                        alId.add(f.Agreement_Line__c);
	    				if(f.Status__c == 'Complete'){
	    					if(f.Unit_Cost__c == null){
	    						//TODO: The itemservice call is not properly bulkified inside the ERP, this will hurt us on large integrations and we will have to rewrite
								f.Unit_Cost__c = ItemService.getActiveStandardCost( iSOL.Product__r.Item__c, 
                                                                                    iSOL.Company__c, 
                																	iSOL.Ship_From_Location__r.Facility__c, 
                                                                                    f.Fulfillment_Date__c == null ? system.now() : f.Fulfillment_Date__c);
								
							}
	    				}
	    				
	    				f.Extended_Cost__c = (f.Quantity__c == null ? 1 : f.Quantity__c) * (f.Unit_Cost__c == null ? 0 : f.Unit_Cost__c);
	    				//TODO: More default attributes??
	    				
	    			}
	    		}
                //KNDY-9651
                if(!alId.isEmpty()){
                  
                  map<Id, Agreement_Line__c> mAGl = new map<Id, Agreement_Line__c>([SELECT Id,Start_Date__c,End_Date__c,Occurrence__c,Rate_Basis__c FROM Agreement_Line__c
                                                    WHERE Id IN :alId]);
                    if(!mAGl.isEmpty()){
                          for(Fulfillment__c f : fulfillments){
                              if(f.Sales_Order_Line__r.agreement_line__c != f.Agreement_Line__c){
                                f.Rate_Basis__c = f.Rate_Basis__c == null ? mAGl.get(f.Agreement_Line__c).Rate_Basis__c : f.Rate_Basis__c; 
                                if(mAGl.get(f.Agreement_Line__c).Occurrence__c != null){
                                  f.Occurrence__c = f.Occurrence__c == null ? mAGl.get(f.Agreement_Line__c).Occurrence__c : f.Occurrence__c;  
                                }
                                if(mAGl.get(f.Agreement_Line__c).Occurrence__c != 'Immediate'){
                                  f.Start_Date__c = f.Start_Date__c == null ? mAGl.get(f.Agreement_Line__c).Start_Date__c : f.Start_Date__c;
                                  f.End_Date__c = f.End_Date__c == null ? mAGl.get(f.Agreement_Line__c).End_Date__c : f.End_Date__c ;
                                }
                                if(mAGl.get(f.Agreement_Line__c).Rate_Basis__c == 'Flat'){
                                  f.Extended_Price__c = f.Extended_Price__c == null ? f.Unit_Price__c : f.Extended_Price__c;  
                                }
						}
                    }
                } 
	    	}
		}
		}
	
	}
	
	private static set<Id> processedFulfillmentDetailIds = new set<Id>();
	private static set<Id> updatedOrderIds = new set<Id>();
	public static void updateOrderFulfillmentDetails(List<Fulfillment__c> fulfillments){
		map<Id, Fulfillment__c> mProcessedFulfillments = new map<Id, Fulfillment__c>(fulfillments);
		if(processedFulfillmentDetailIds.containsAll(mProcessedFulfillments.keySet())){
    		return;
    	}
    	
    	processedFulfillmentDetailIds.addAll(mProcessedFulfillments.keySet());
    	
		set<Id> solIds = new set<Id>();
		for(Fulfillment__c f : fulfillments){
			solIds.add(f.Sales_Order_Line__c);
		}
		List<Sales_Order_Line__c> sols = [SELECT Id, name, Quantity_Ordered__c, Quantity_Shipped__c, Quantity_Backordered__c, 
													(SELECT Id, Status__c, name, Sales_Order_Line__c, Quantity__c, Agreement__c, Type__c, Parent_Fulfillment__c
													FROM Fulfillments__r)
													FROM Sales_Order_Line__c
													WHERE Id IN :solIds];
													//AND Id NOT IN :updatedOrderIds];
		for(Sales_Order_Line__c sol : sols){
			updatedOrderIds.add(sol.Id);
			decimal qtyFulf = 0;
			for(Fulfillment__c f : sol.Fulfillments__r){
				if(f.Status__c == 'Complete'){

                    if(f.Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL || (f.Type__c == 'Rental' && f.Parent_Fulfillment__c != null)){
                        //Ignore partial rental returns.
                        // Ignore accruals
                        continue;
                    }
					qtyFulf += f.Quantity__c == null ? 0 : f.Quantity__c;
				}
			}
			sol.Quantity_Fulfilled__c = qtyFulf;
			//sol.Quantity_Shipped__c = qtyFulf;
			sol.Quantity_Backordered__c = sol.Quantity_Ordered__c - qtyFulf;
			if(sol.Quantity_Fulfilled__c == sol.Quantity_Ordered__c){
				sol.Status__c = 'Closed';
			}else if(sol.Quantity_Fulfilled__c != null 
					&& Math.abs(sol.Quantity_Fulfilled__c) < Math.abs(sol.Quantity_Ordered__c)){
				sol.Status__c = 'Open';
			}else{
				system.debug((sol.Quantity_Fulfilled__c != null ) + ' ' + (sol.Quantity_Fulfilled__c < sol.Quantity_Ordered__c));
			}			
			system.debug('qty fulf sol: ' + sol);
		}
		
		if(sols.size() > 0){
			Savepoint sp = Database.setSavepoint();
			try{
				DML.updateAsSystem(sols);
			}catch(Exception ex){
				Database.rollback(sp);
				throw new FulfillmentException(ex.getMessage());
			}	
		}
		
	
	}

	public static void holdManagement() {
		if(trigger.isUpdate && trigger.isBefore) {
			set<Id> onHoldIds = new set<id>();
			set<Id> releaseHoldIds = new set<id>();
			for(Fulfillment__c f : (list<Fulfillment__c>) trigger.new) {
				if(KSE.isFieldChanging('Invoice_Hold__c',f, trigger.oldMap) && f.Invoice_Hold__c)
					onHoldIds.add(f.Id);
				else if(KSE.isFieldChanging('Invoice_Hold__c',f, trigger.oldMap) && !f.Invoice_Hold__c)
					releaseHoldIds.add(f.Id);
			}
			
			if(!onHoldIds.isEmpty() || !releaseHoldIds.isEmpty()) {
				map<Id,string> errorResponses = holdManagement(onHoldIds, releaseHoldIds);
				for(Fulfillment__c f : (list<Fulfillment__c>) trigger.new) {
					if(errorResponses.containsKey(f.Id)) {
						f.addError(errorResponses.get(f.Id));
					}else if(onHoldIds.contains(f.Id)) {
						f.Invoice_Hold__c = true;
					}else if(releaseHoldIds.contains(f.Id)) {
						f.Invoice_Hold__c = false;
						f.Reason_Code__c = null;
					}else
						continue;
				}
				
			}
		}
	}
        
	
	public static map<Id,String> holdManagement(set<Id> onHoldIds, set<Id> releaseHoldIds) {
		map<Id,string> errorResponses = new map<Id,string>();
		for(Fulfillment__c f : [Select Id, Name, Reason_Code__c, Start_Date__c, Fulfillment_Date__c, Invoice_Hold__c, Fulfillment_Fully_Invoiced_2__c,Invoice_Ready__c,  
						    	(Select Id, Customer_Invoice_Line__c from Customer_Invoice_Sub_Lines__r where Customer_Invoice_Line__r.Finalized__c = true) from Fulfillment__c where id in :onHoldIds or Id in :releaseHoldIds ]) {
				
				if(onHoldIds != null && onHoldIds.contains(f.Id)) {
					if((f.Fulfillment_Fully_Invoiced_2__c && f.Start_Date__c != null) || (f.Start_Date__c == null && f.Customer_Invoice_Sub_Lines__r.size() >0)) {
							errorResponses.put(f.Id,' Fulfillment is already invoiced.');
						}
						else if(f.Invoice_Hold__c) {
							errorResponses.put(f.Id,'Fulfillment is already on hold.');
						}
						else
							continue;
				}else if(releaseHoldIds!= null && releaseHoldIds.contains(f.Id)) {
					if(!f.Invoice_Hold__c) {
							errorResponses.put(f.Id, 'Fulfillment is not on hold.');
						}else
							continue;
				}else
					continue;
							    		
		
        }
		return errorResponses;
	}
	public static void setAgreementQuantities(){
        if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {

      
            Set<Id> aglIds = new Set<Id>();

            if (Trigger.isInsert) {
                for (Fulfillment__c f : (List<Fulfillment__c>) Trigger.new) {
                    if (f.Status__c == 'Complete' && f.Agreement_line__c != null && f.Type__c != 'Deinstall') {
                        aglIds.add(f.Agreement_Line__c);
                    }
                }
            } 

            if (Trigger.isUpdate) {
                for (Fulfillment__c f : (List<Fulfillment__c>) Trigger.new) {
                   if (KSE.isFieldChanging('Status__c', f, Trigger.oldMap) && (f.Status__c == 'Complete')&& f.Agreement_line__c != null && f.Type__c != 'Deinstall') 
                    {
                        aglIds.add(f.Agreement_Line__c);
                    }
                }
            }

            if (!aglIds.isEmpty()) {
                AgreementLineService.setQuantities(aglIds, Trigger.new);
                
            }
        }
    }
    
    public static void setAgreementAcceptanceDate(){
        if (Trigger.isBefore && (Trigger.isInsert || trigger.isUpdate) ) {

      
            Set<Id> aglineIds = new Set<Id>();
			set<Id> solIds = new set<Id>();
            if (Trigger.isInsert) {
                for (Fulfillment__c f : (List<Fulfillment__c>) Trigger.new) {
                    if (f.Status__c == 'Complete' && f.Type__c != 'Deinstall') {
                       if (f.Agreement_line__c != null ) {
                           aglineIds.add(f.Agreement_line__c);
                        }
                        if(f.Sales_Order_Line__c != null)
                        	solIds.add(f.Sales_Order_Line__c);  
                    }
                    
                }
            } 
            if(Trigger.isUpdate) {
                for (Fulfillment__c f : (List<Fulfillment__c>) Trigger.new) {
                   if (KSE.isFieldChanging('Status__c', f, Trigger.oldMap) && (f.Status__c == 'Complete') &&  f.Type__c != 'Deinstall') 
                    {
                         if(f.Agreement_line__c != null) {
	                         aglineIds.add(f.Agreement_line__c);
	                     }
                         if(f.Sales_Order_Line__c != null)
                        	solIds.add(f.Sales_Order_Line__c); 
                	}
           		 }
            }
            
			system.debug('solIds '+solIds);
			system.debug('aglineIds '+aglineIds);
            if (!aglineIds.isEmpty()) {
                AgreementLineService.setAcceptanceDate(aglineIds, Trigger.new);
            }
            if(!solIds.isEmpty()) {
            	SalesOrderService.setRecurrenceStartDate(solIds, (list<Fulfillment__c> )trigger.new);
        	}
    	}
    }
    
	
	public static void setFulfillmentFullyInvoiced(list<Fulfillment__c> lFulfillments) {
		
		set<Id> sFulfillmentsINvoicedAhead = new set<Id>();
		for(Fulfillment__c f : lFulfillments) {
			if(f.Last_Bill_Date__c == null)
				f.Fulfillment_Fully_Invoiced_2__c = false;
			else {
				if(KSE.isFieldChanging('Last_Bill_Date__c',  f, trigger.oldMap) || KSE.isFieldChanging('Start_Date__c',  f, trigger.oldMap) || KSE.isFieldChanging('End_Date__c',  f, trigger.oldMap) ) {
					if(!f.Invoice_Ahead__c) 
						f.Fulfillment_Fully_Invoiced_2__c = f.End_Date__c != null && f.Last_Bill_Date__c != null && (f.Last_Bill_Date__c.date() >= f.End_Date__c.date());
					else
						sFulfillmentsINvoicedAhead.add(f.Id);
				}
			}
			    
		}
		if(!sFulfillmentsINvoicedAhead.isEmpty()) {
			map<Id,Fulfillment__c> mFulfillments = new map<Id, Fulfillment__c>([Select Id, Pricing_UOM__r.Recurrence__c, Pricing_UOM__r.Every__c from Fulfillment__c where Id in :sFulfillmentsINvoicedAhead and Price_Type__c = 'Recurring']);
					
			for(Fulfillment__c f : lFulfillments) {
				if(sFulfillmentsINvoicedAhead.contains(f.Id) && mFulfillments.containsKey(f.id)) {
					Fulfillment__c mF = mFulfillments.get(f.Id);
					f.Fulfillment_Fully_Invoiced_2__c = f.End_Date__c != null && f.Last_Bill_Date__c != null && (f.Last_Bill_Date__c.date() >= FrequencyService.previousBillingDate(mF.Pricing_UOM__r.Recurrence__c, f.End_Date__c.date(), Integer.valueOf(f.Last_Bill_Date__c.day()), Integer.valueOf(mF.Pricing_UOM__r.Every__c)));
				}
			}
			    
		}
	}
	
    
}