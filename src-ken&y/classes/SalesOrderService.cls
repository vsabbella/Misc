public with sharing class SalesOrderService {

	public static final String SO_STATUS_HOLD = 'On Hold';
	public static final String SO_STATUS_DRAFT = 'Draft' ;
	public static final String SO_STATUS_OPEN = 'Open' ;
	public static final String SO_STATUS_CLOSED = 'Closed' ;
	public static final String SO_STATUS_CANCEL = 'Cancelled' ;

	public static final String SO_TYPE_RMA = 'RMA-Credit';
	public static final String SO_TYPE_RMA_REPAIR = 'RMA-Customer-Repair';
	public static final String SO_TYPE_RMA_REPLACEMENT = 'RMA-Replacement';
	public static final String SO_TYPE_REPAIR = 'Repair';
	public static final String SO_TYPE_RESALE = 'Resale';

	public static final String ADJUSTMENT_PRICE_CLAIM = 'Price Adjustment - Claim';
	public static final String ADJUSTMENT_QUANTITY_CLAIM = 'Quantity Adjustment - Claim';
	public static final String ADJUSTMENT_PRICE_AR = 'Price Adjustment - AR';
	public static final String ADJUSTMENT_QUANTITY_AR = 'Quantity Adjustment - AR';
	public static final String ADJUSTMENT_QUANTITY_CLAIM_RETURN = 'Quantity Adjustment - Claim Return';
	public static final String ADJUSTMENT_QUANTITY_AR_RETURN = 'Quantity Adjustment - AR Return';
	public static final String ADJUSTMENT_QUANTITY_RECALL = 'Quantity Adjustment - Recall';

	public static final String PRICE_DET_ORDER = 'Order Date';
	public static final String PRICE_DET_SHIPMENT = 'Shipment Date';
	public static final String PRICE_DET_MANUAL = 'Manual';

	public static final Integer SO_ALLOCATION_RESULT_SIZE = 10 ;

	public static final Set<String> SO_RMA_TYPES = new Set<String>{
			SO_TYPE_RMA,
			SO_TYPE_RMA_REPAIR
	};
	public static final Set<String> SO_RMA_REPLACEMENT_TYPES = new Set<String>{
			SO_TYPE_RMA_REPLACEMENT
	};

	public static Set<String> SO_ADJUSTMENT_TYPES = new Set<String>{
			ADJUSTMENT_PRICE_CLAIM,
			ADJUSTMENT_QUANTITY_CLAIM,
			ADJUSTMENT_PRICE_AR,
			ADJUSTMENT_QUANTITY_AR,
			ADJUSTMENT_QUANTITY_CLAIM_RETURN,
			ADJUSTMENT_QUANTITY_AR_RETURN,
			ADJUSTMENT_QUANTITY_RECALL
	};

	public static Set<String> STANDARD_ORDER_TYPES = new Set<String>{
			'Standard',
			'Sample',
			'Affiliate',
			'Salvage',
			'Sundry',
			'Replacement',
			'Repair',
			'Drop Ship',
			SO_TYPE_RMA_REPLACEMENT,
			'Back To Back'
	};

	public static Set<String> SALES_ADJUSTMENT_ORDER_TYPES = new Set<String>{
			SO_TYPE_RMA,
			SO_TYPE_RMA_REPAIR,
			'Military',
			'Military Dist Credit',
			'SPIN',
			'Adjustment',
			ADJUSTMENT_PRICE_CLAIM,
			ADJUSTMENT_QUANTITY_CLAIM,
			ADJUSTMENT_PRICE_AR,
			ADJUSTMENT_QUANTITY_AR,
			ADJUSTMENT_QUANTITY_CLAIM_RETURN,
			ADJUSTMENT_QUANTITY_AR_RETURN,
			ADJUSTMENT_QUANTITY_RECALL
	};

	public static Set<String> NO_SHIP_ADJ_ORDER_TYPES = new Set<String>{'Adjustment'};

	public class SalesOrderServiceException extends Exception { }
  
  public static Map<Id, Customer__c> customersMap = new Map<Id, Customer__c>();
  
	// KNDY-4343: Calculating Total Weight on SO using Total Product Weight * Pallet Weight
	public static void calculateTotalWeight(){
	  List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
	  if(trigger.isBefore && trigger.isUpdate){

		for(Sales_Order__c so: (List<Sales_Order__c>) trigger.new){
		  if (KSE.isFieldChanging('Total_Product_Weight__c', so, trigger.oldMap) ||
					KSE.isFieldChanging('Number_of_pallets__c', so, trigger.oldMap) ) {
			salesOrders.add(so);
		  }
		}

		if(! salesOrders.isEmpty()){
		  calculateTotalWeightonSO(salesOrders);
		}
	  }

	}
	public static void validateTypeChange(){

		List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();

		if(trigger.isBefore && trigger.isUpdate){

			for(Sales_Order__c so: (List<Sales_Order__c>) trigger.new){
				if (KSE.isFieldChanging('Type__c', so, trigger.oldMap)){

					if(so.Type__c == SO_TYPE_RESALE) {
						so.addError('Cannot set the type to \'' + SO_TYPE_RESALE + '\' for existing sales orders');
					}
					if((String)trigger.oldmap.get(so.id).get('Type__c') == SO_TYPE_RESALE){
						so.addError('Cannot change the type from \'' + SO_TYPE_RESALE + '\' for existing sales orders');
					}
				}
			}
		}
	}

	public static void calculateTotalWeightonSO(List<Sales_Order__c> salesOrders){

		Map<Id,Sales_Order__c> somap = new Map<Id, Sales_Order__c>([SELECT Id, Total_Product_Weight__c, Ship_to__r.Pallet_Product__r.Weight__c, Ship_From_Location__r.Facility__r.Facility_Identifier__c,
						  Ship_to__r.Pallet_Product__r.Item__c,Ship_to__r.Pallet_Product__r.Weight_UOM__r.Name, Number_of_pallets__c, Ship_to__r.Pallet_Product__r.Item__r.Packaging_UOM__c,
					  Total_Weight__c, Weight_UOM__r.Name FROM Sales_Order__c WHERE Id IN :salesOrders]);

		if (somap == null || somap.isEmpty()){
		  return;
		}
		decimal conversionFactor;
		Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>> ();
		for(Sales_Order__c sorder : salesOrders){

		    if(somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Weight__c != null && sorder.Total_Product_Weight__c != null && somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Weight_UOM__r.Name != null && somap.get(sorder.id).Weight_UOM__r.Name != null){
		        if ( !itemPackagingUOMCache.containsKey( somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Item__c )) {
		            List<Id> lstPkgUom = (List<Id>) JSON.deserialize(somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Item__r.Packaging_UOM__c, List<Id>.class);
		            itemPackagingUOMCache.put(somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Item__c, lstPkgUom);
		        }
		        conversionFactor = KSE.getConversionFactor(somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Item__c, somap.get(sorder.id).Ship_From_Location__r.Facility__r.Facility_Identifier__c, somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Weight_UOM__c, somap.get(sorder.id).Weight_UOM__c,itemPackagingUOMCache.get(somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Item__c) );
		        sorder.Total_Weight__c = (sorder.Total_Product_Weight__c +
								(somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Weight__c * (sorder.Number_of_pallets__c).round(System.roundingmode.CEILING) * conversionFactor)).setscale(6,System.roundingmode.Half_Up);//KSE.getConversionFactor(somap.get(sorder.id).Ship_to__r.Pallet_Product__r.Weight_UOM__r.Name, somap.get(sorder.id).Weight_UOM__r.Name));
		    } else{
		        sorder.Total_Weight__c = sorder.Total_Product_Weight__c;
		    }
		}
	}


	// Proxy method: To be removed later
	public void plan(Set<Id> salesOrderIds) {

		SalesOrderReleaseService.release(salesOrderIds);
	}

	// Proxy method: To be removed later
	public void plan(Id salesOrderId) {

		SalesOrderReleaseService.release(salesOrderId);
	}

	// Proxy method: To be removed later
	public void plan(Id salesOrderId, Id shipmentId) {
		SalesOrderReleaseService.release(salesOrderId);
	}

	// Proxy method: To be removed later
	public static void plan(Map<Id, Id> mSalesOrderToShipment) {
		SalesOrderReleaseService.release(mSalesOrderToShipment.keySet());
	}

	public static void updatePricingDate(){
	  if (trigger.isBefore && (trigger.isUpdate || trigger.isInsert)){
		List<Sales_Order__c> soList = new List<Sales_Order__c>();

		Boolean hasLines = false;

		for (Sales_Order__c so : (Sales_Order__c[])  trigger.new){
		  if ( KSE.isFieldChanging('Price_Determination_Date__c', so, trigger.oldMap) || KSE.isFieldChanging('Pricing_date__c', so, trigger.oldMap)
			|| (so.Price_Determination_Date__c == PRICE_DET_ORDER && KSE.isFieldChanging('Date_Time_Ordered__c', so, trigger.oldMap) ) )
		  {
			soList.add(so);

			if (!hasLines && so.Total_Quantity_Ordered__c > 0) {
			  hasLines = True;
			}
		  }
		}

		if (!soList.isEmpty()){

		  Map <Id, Sales_Order_line__c[]> solBySo = new Map <Id, Sales_Order_line__c[]>();

		  // query lines if lines exist
		  if (hasLines){
			for (Sales_Order_line__c sol : [Select Id, Quantity_Ordered__c, Quantity_shipped__c, Estimated_Ship_Date__c,  Sales_Order__c,
							(select Id, Shipment__r.Shipment_Date_Estimated__c, Shipment__r.Date_Shipped__c
							  from Shipment_Lines__r),
							(select id, Quantity_Shipped__c, Customer_invoice__r.Status__c
							  from Customer_transaction_lines__r
							  where Customer_invoice__r.Status__c IN (:CustomerInvoiceService.STATUS_CLOSED, :CustomerInvoiceService.STATUS_OPEN))
						  from Sales_Order_Line__c
						  where Status__c != :SalesOrderService.SO_STATUS_CANCEL and Sales_order__c IN :soList]){


			  if(!solBySo.containsKey(sol.Sales_Order__c) ){
				solBySo.put(sol.sales_order__c, new List<Sales_Order_Line__c>());
			  }

			  solBySo.get(sol.Sales_Order__c).add(sol);
			}
		  }

		  updatePricingDate(soList, solBySo);
		}
	  }
	}

	public static void updatePricingDate(List<Sales_Order__c> soList, Map <Id, Sales_Order_line__c[]> solBySo){

	  for (Sales_order__c so : soList){

		// set default if null pricing date - SOs that have no lines
		if (so.Price_Determination_Date__c == PRICE_DET_ORDER){
			if (so.Date_Time_Ordered__c != null)
			  so.Pricing_Date__c = so.Date_Time_Ordered__c.date();

		}
		if (so.Pricing_Date__c == null){
		  if (so.Date_Time_Ordered__c.date() != null){
			so.Pricing_Date__c = so.Date_Time_Ordered__c.date();
		  } else {
			so.Pricing_Date__c = system.today();
		  }
		}

		// skip remaining logic if no lines present
		if (!solBySo.containsKey(so.id) ){
			system.debug(LoggingLevel.info, 'No Sols found on for Pricing Update (salesOrderService : updatePricingDate)' + so);
			continue;
		}

		// OTC-724: Prevent changing SO Pricing Date if all lines are invoiced completely
		if (so.Status__c == SalesOrderService.SO_STATUS_CLOSED) {
		  Decimal totalQuantityInvoiced = 0;
		  for (sales_order_line__c sol : solBySo.get(so.id)){
			if (sol.Customer_transaction_lines__r != null && sol.Customer_transaction_lines__r.size() > 0){
			  for (customer_invoice_line__c cil : sol.Customer_Transaction_lines__r){
				totalQuantityInvoiced += cil.Quantity_shipped__c;
			  }
			}
		  }

		  if (totalQuantityInvoiced == so.Total_Quantity_Ordered__c){
			so.addError(label.Cannot_change_pricing_date_when_all_Sales_Order_Lines_Invoiced);
			continue;
		  }
		}

		// For Shipment Determination Method: Ship Date > Est Shipment Date (Shipment Line) > Est Shipment Date (SOL)
		if (so.Price_Determination_Date__c == PRICE_DET_SHIPMENT){
		  if (solBySo.containsKey(so.id)){
			Sales_Order_Line__c sol = solBySo.get(so.id)[0];

			if (sol.shipment_lines__r != null && !sol.shipment_lines__r.isEmpty()){
			  // use date shipped
			  if (sol.shipment_lines__r[0].Shipment__r.Date_Shipped__c != null){
				so.Pricing_Date__c = sol.shipment_lines__r[0].Shipment__r.Date_Shipped__c.date();

			  }

			  else if (sol.shipment_lines__r[0].Shipment__r.Shipment_Date_Estimated__c != null)
				so.Pricing_Date__c = sol.shipment_lines__r[0].Shipment__r.Shipment_Date_Estimated__c;

			}
			// use line estimated ship date
			else if (sol.Estimated_Ship_Date__c != null)
			  so.Pricing_Date__c = sol.Estimated_Ship_Date__c;
		  }
		}
	  }
	}

	// OTC-362 - changing delivery method from pickup should remove Freight Allowances
	public static void validateChangingDeliveryMethod(){
	  //if (trigger.isAfter && trigger.isUpdate){
	  //  List<Sales_Order__c> soList = new List<Sales_Order__c>();
	  //  for (Sales_Order__c so : (Sales_Order__c[]) trigger.new){
	  //    if (KSE.isFieldChanging('Delivery_Method__c', so, trigger.oldMap) && so.Delivery_Method__c != 'Pickup') {
	  //      soList.add(so);
	  //    }
	  //  }

	  //  if (!soList.isEmpty()){
	  //    validateChangingDeliveryMethod(soList);
	  //  }
	  //}
	}

	//public static void validateChangingDeliveryMethod(Sales_Order__c[] soList){

	//  if (soList.isEmpty()) return;

	//  Allowance_Applied__c[] acs = [SELECT id, Sales_Order_Line__r.Sales_Order__c
	//    FROM Allowance_Applied__c
	//    WHERE Sales_Order_Line__r.Sales_Order__c in : soList and Allowance_Rule2__r.Is_Freight_Rule__c = true
	//    ];

	//if (!acs.isEmpty()){
	//  DML.deleteAsUser(acs);
	//}
	//}

	/*
  * @description : Check if the transit route keys are already in the map
  *            If not, collect the keys that are not in the map and requery for them.
  *            and return the latest map.
  *
  * @return : Map<String, Transit_Route__c> map of transit routes with 'Transit_Route_Unique__c' as key.
  */
  static Map<String, Transit_Route__c> getTransitRoutesMap(Set<String> transitRouteKeys){
	Map<String, Transit_Route__c> routesMap = new Map<String, Transit_Route__c>();

	if(transitRouteKeys != null && transitRouteKeys.size() > 0){
	  for(Transit_Route__c route : [SELECT Id, Transit_Time__c , Means_of_Transport__c,
						 Origin__c, Destination__c, Transit_Route_Unique__c, Shipping_Calendar__c, Delivery_Method__c
						FROM Transit_Route__c
					   WHERE Transit_Route_Unique__c IN :transitRouteKeys
					 ]){
		routesMap.put(route.Transit_Route_Unique__c, route);
		}
	}

	return routesMap;
  }

	/*
  * @description  Return the transit key that matches this shipment
  */
  static String getTransitKey(Sales_Order_Line__c sol){
	String transitKey = '' ; // KNDY-10333 + sol.Sales_Order__r.Means_of_Transport__c + sol.Ship_From_Location__r.Facility__r.Address__c+ sol.Sales_Order__r.Ship_To__r.Address__c+ sol.Sales_Order__r.Delivery_Method__c;
	return transitKey;
  }
  
	public void undoPlan(Set<Id> salesOrderIds) {
		Map<Id, Sales_Order__c> mSalesOrders = new Map<Id, Sales_Order__c>();
		Set<Id> shipmentIds = new Set<Id>();
		List<Shipment__c> deleteShipments = new List<Shipment__c>();
		set<Id> workOrdersForCancellation = new set<Id>();

		List<Sales_Order__c> sos = [SELECT Id, Name, Status__c, Type__c,
								   (SELECT Id, Status__c FROM Requisitions__r),
								   (SELECT Id, Name, Status__c, Quantity_ordered__c, Quantity_Backordered__c,
										Quantity_Allocated__c,Quantity_Shipped__c,Parent_Sales_Order_Line__r.Item_Source__c,Sales_Order__r.Type__c,
										Parent_Sales_Order_Line__r.Product__r.Item__r.Source__c, Item_Source__c, Quantity_Fulfilled__c,Work_Order__c,Work_Order__r.Status__c
										FROM Sales_Order_Lines__r
										WHERE //(Quantity_Allocated__c = 0 AND
											   (Status__c = :SO_STATUS_OPEN OR (Status__c = :SO_STATUS_CLOSED and Sales_Order__r.Type__c IN :SALES_ADJUSTMENT_ORDER_TYPES and Sales_Order__r.Type__c NOT IN ('RMA-Credit', 'RMA-Replacement', 'RMA-Customer-Repair')))
								            or work_order__c!=null
								            order by Parent_Sales_Order_Line__c nulls first)
								FROM Sales_Order__c
								WHERE Id IN :salesOrderIds ];

		List<Sales_Order_Line__c> sols = new List<Sales_Order_Line__c>();
		List<Sales_Order_Line__c> solsForDelete = new List<Sales_Order_Line__c>(); // child lines for kitting

		Set<Id> reqsIdsToDelete = new Set<Id>();
		Boolean isError = false;
		Set<id> draftParentSOL = new Set<id>();

		// create negitive fulfillments for adjustments
		Map<Id,Fulfillment__c> solFulfillMap = new Map<Id,Fulfillment__c>();
		for (Sales_order__c so : sos){
			if (SALES_ADJUSTMENT_ORDER_TYPES.contains(so.Type__c) && !SO_RMA_TYPES.contains(so.Type__c)) {
				for (Sales_Order_Line__c sol : so.Sales_Order_Lines__r){
					Fulfillment__c ful = new Fulfillment__c();
					ful.Type__c = 'Reversed ' + sol.Sales_Order__r.Type__c;
					ful.Quantity__c = -sol.Quantity_Fulfilled__c;
					solFulfillMap.put(sol.id, ful);
				}
			}
		}

		/* Used for referencing the Shipment / SHL information using the SOL */
		Map<string,List<Shipment_Line__c>> solIdToShlList = new Map<string,List<Shipment_Line__c>>();
		for (Sales_Order__c so : sos) {
			for ( Shipment_Line__c shl : so.Shipment_Lines__r ) {
				if (shl.Sales_Order_Line__c != null) {
					String key = shl.Sales_Order_Line__c;
					if ( !solIdToShlList.containsKey( key) ) {
						solIdToShlList.put( key, new List<Shipment_Line__c>() );
					}
					solIdToShlList.get( key ).add( shl );
				}
			}
		}

		for(Sales_Order__c so : sos){
			integer counter = 0;

			for (Requisition__c RQ : so.Requisitions__r){
				if (ApexPages.currentPage() != null && RQ.Status__c != RequisitionService.RQ_STATUS_CANCELLED) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please cancel the Requisition before you Undo Release.'));
					isError = true;
					break;
				} else {
					reqsIdsToDelete.add(RQ.Id);
				}
			}

			List<Sales_Order_Line__c> validSOLForDraft = new List<Sales_Order_Line__c>();

			String SFDCBaseURL = URL.getSalesforceBaseUrl().toExternalForm();

			if(ApexPages.currentPage() != null){

				for (Sales_Order_Line__c sol : so.Sales_Order_Lines__r) {
					if (sol.Quantity_Allocated__c > 0) {

						// SOL Qty allocated can be mean SHL has been: Allocated, Plan Picked, or Picked.
						if ( solIdToShlList.containsKey(sol.Id) && solIdToShlList.get(sol.Id).size() > 0){

							for (Shipment_Line__c shl : solIdToShlList.get(sol.Id)) {

								if ( shl.Quantity_Picked__c > 0) {
									ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.WARNING, sol.Name + ' have Shipment Lines with picked quantity. Cannot move to draft.' ) );
								}
								else if ( shl.Quantity_To_Pick__c> 0) {
									ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.WARNING, sol.Name + ' have Shipment Lines with planned picks. Cannot move to draft.' ) );
								}
								else if ( shl.Quantity_Allocated__c > 0) {
									ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.WARNING, sol.Name + ' have Shipment Lines with allocated quantity. Cannot move to draft.' ) );
								}
							}

							continue;

						} else {
							// If SHL cannot be fetched (unlikely), use this generic error.
							ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.WARNING, sol.Name + ' have Shipment Lines with allocated quantity. Cannot move to draft.' ) );
							continue;
						}
					}

					if (sol.Quantity_Shipped__c > 0) {
						ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.WARNING, sol.Name + ' have Shipment Lines with shipped quantity. Cannot move to draft.' ) );
						continue;
					}

					validSOLForDraft.add(sol);
				}

				if( so.Sales_Order_Lines__r.size() == 0 ||  validSOLForDraft.size() == 0) {
					ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.INFO, 'The Sales Order has no valid lines for Undo Release.' ) );
					isError = true;
					break;
				}
			}

			// sorted by Parent Sales Order lines with nulls first - this means we're looking at parents lines first
			for(Sales_Order_Line__c sol : validSOLForDraft){ //so.Sales_Order_Lines__r
			  Decimal qtyFulfilledOrAllocated = KSE.addQuantityToField(sol.Quantity_Fulfilled__c, sol.Quantity_Allocated__c);
			  Decimal remainingQty = KSE.subtractDecimals(sol.Quantity_Ordered__c, qtyFulfilledOrAllocated);

				// delete child lines if parent is changed to draft status
				if (draftParentSOL.contains(sol.Parent_Sales_Order_Line__c) && sol.Quantity_Fulfilled__c == 0){
				solsForDelete.add(sol);
				//continue;
			  }
				if(sol.Work_Order__c!=null && sol.Work_Order__r.Status__c!='Cancelled'){
					workOrdersForCancellation.add(sol.Work_Order__c);
				}

				if( (remainingQty == sol.quantity_backordered__c && sol.Status__c != SO_STATUS_CLOSED) || SALES_ADJUSTMENT_ORDER_TYPES.contains(sol.Sales_order__r.Type__c)) {

					//if (sol.Quantity_Fulfilled__c == 0){
						sol.status__c = SalesOrderService.SO_STATUS_DRAFT;

						if (sol.Item_Source__c == 'Kit'){
							draftParentSOL.add(sol.id);
						}
					//}
				//sol.Quantity_Backordered__c = sol.Quantity_Ordered__c;
				//sol.Quantity_From_Stock__c = sol.Quantity_From_Stock__c;
				//sol.Quantity_Allocated__c = 0;
				//sol.Quantity_Shipped__c = 0;
				sols.add(new Sales_Order_Line__c( Id=sol.id, Status__c=sol.Status__c));



				counter++;
				if(!mSalesOrders.containsKey(so.Id)){
					mSalesOrders.put(so.Id, so);
				}
			  }
			}
			//Mark the Sales Order as a Draft if all lines are undergoing the undo release process
			if(counter == so.Sales_Order_Lines__r.size()){
				so.Status__c = SalesOrderService.SO_STATUS_DRAFT;
			}
		}

		/*List<SKID__c> deleteDemandSkids = [SELECT Id, Sales_Order_Line__c
						  FROM SKID__c
						  WHERE Sales_Order_Line__c IN :sols
						  AND Type__c = :SKIDService.SKID_TYPE_SO_DEMAND];*/

		if(workOrdersForCancellation.size()>0){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please cancel associated work orders before sales order undo release. '));
			isError = true;

		}

		if (!isError){
			List<Shipment_Line__c> shipLines = [SELECT id, name, shipment__c
						  FROM Shipment_Line__c
						  WHERE Sales_Order_Line__c IN :sols
							AND Shipment__r.Status__c != 'Confirmed'
							AND Shipment__r.Status__c != 'Delivered'];

			for(Shipment_Line__c sl : shipLines){
				shipmentIds.add(sl.shipment__c);
			}

			if(shipLines.size() > 0){
				//KNDY-1753
				DML.deleteAsUser(shipLines);

			}

			//KNDY-1753
			DML.deleteAsUser([SELECT Id FROM Requisition__c WHERE Id IN :reqsIdsToDelete]);
			DML.updateAsUser(mSalesOrders.values());

			if (!solFulfillMap.keySet().isEmpty()){
				FulfillmentService.fulfillSalesOrders(solFulfillMap.keySet(), solFulfillMap);
			}

			DML.updateAsUser(sols);

			if (!solsForDelete.isEmpty()){
			  DML.deleteAsUser(solsForDelete); // after update to bypass status validation
			}


			ApexPages.addMessage( new ApexPages.Message( ApexPages.Severity.CONFIRM, Label.SO_Undo_Released));
			
		}
	}
  
	public void updateShipmentStatus(Set<Id> salesOrderIds){
		// OTC-134 - Change the shipping status to planned
		Boolean addSO;
		Set<Id> soIdsToAdd = new Set<Id>();
		Map<Id, Shipment__c> shipmentsMap = new Map<Id, Shipment__c>();

		for(Sales_Order__c so : [SELECT Id, Name, Status__c,
											(SELECT Id, Name, Status__c, Quantity_Ordered__c, Quantity_Backordered__c,
											Quantity_Allocated__c, Quantity_Shipped__c
											FROM Sales_Order_Lines__r)
										FROM Sales_Order__c WHERE Id IN :salesOrderIds]){
			addSO = false;

			for(Sales_Order_Line__c sol : so.Sales_Order_Lines__r){
				if (sol.Quantity_Allocated__c == 0){
					addSO = true;
				} else {
					addSO = false;
					break;
				}
			}

			if (addSO) {
				soIdsToAdd.add(so.Id);
			}
		}
		if (soIdsToAdd.size() > 0){

			for (Shipment_Line__c sl : [SELECT Id, Shipment__c, Shipment__r.Status__c FROM Shipment_Line__c
										WHERE Sales_Order__c IN :soIdsToAdd AND Shipment__r.Status__c = :ShipmentService.SHIPMENT_STATUS_RELEASED]){
				sl.Shipment__r.Status__c = ShipmentService.SHIPMENT_STATUS_PLANNED;
				shipmentsMap.put(sl.Shipment__c, sl.Shipment__r);
			}

			DML.sobjectupdate(shipmentsMap.values());
		}
	}

  //Unallocate runs off of allocated skid IDs now. Comment out the original unallocate method in this class when we stop using the old features
  public void unallocateNew( set<Id> allocatedIds){

	List<SKID__c> deleteSkids  = new List<SKID__c>();
	Map<Id, Shipment_Line__c> updateShlMap = new Map<Id, Shipment_Line__c>();
	Map<Id, Sales_Order_Line__c> updateSolMap = new Map<Id, Sales_Order_Line__c>();
	map<Id,List<SKID__c>> solIds = new map<Id,List<SKID__c>>();
	map<Id,SKID__c> demandSkidsMap = new map<Id,SKID__c>();
	String mtoItemSource = ItemService.ITEM_SOURCE_MAKE_TO_ORDER;
	String btoFfSource = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER;
	String repair = SalesOrderService.SO_TYPE_REPAIR;

	if(allocatedIds == null || allocatedIds.size() == 0){

	  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'No Records Selected.'));
			return;
	}

	List<SKID__c> allocatedSkids = [select Id, Quantity__c, Item__c, Location__c, Location__r.Facility__r.Company__c,Sales_Order_Line__r.Name,
						  Sales_Order_Line__c, Sales_Order_Line__r.Quantity_Backordered__c,Sales_Order_Line__r.Quantity_Ordered__c,
						  Sales_Order_Line__r.Quantity_Allocated__c,Sales_Order_Line__r.Quantity_From_Stock__c, Sales_Order_Line__r.Sales_Order__r.Type__c,
						  Sales_Order_Line__r.Selling_UOM__c, Sales_Order_Line__r.Selling_UOM__r.Name, Sales_Order_Line__r.Sales_Order__r.Status__c,
						  Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__c, Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__r.Name,
						  Shipment_Line__c, Shipment_Line__r.Quantity_Shipped__c, Sales_Order_Line__r.Product__r.Item__r.Source__c,
						  Sales_Order_Line__r.Fulfillment_Source__c
						  from Skid__c where Id IN :allocatedIds ];

	for( SKID__c allocSkid : allocatedSkids ){

	  if(allocSkid.Sales_Order_Line__r.Product__r.Item__r.Source__c == mtoItemSource ||
		allocSkid.Sales_Order_Line__r.Fulfillment_Source__c == btoFfSource ||
		allocSkid.Sales_Order_Line__r.Sales_Order__r.Type__c == repair ){
		  throw new SalesOrderServiceException(allocSkid.Sales_Order_Line__r.Name + ' :'+'Cannot unallocate \'build to order\' or \'repair\' sales order lines. Please uncomplete the work order');
	  }

	  list<SKID__c> lstAlloc = new list<SKID__c>();
	  if(solIds.containsKey(allocSkid.Sales_Order_Line__c))
	  {
		solIds.get(allocSkid.Sales_Order_Line__c).add(allocSkid);

	  }
	  else
	  {
		lstAlloc.Add(allocSkid);
		solIds.put( allocSkid.Sales_Order_Line__c, lstAlloc);
	  }

	}
	Map<Id, Sales_Order_Line__c> soLineMap = new map<Id, Sales_Order_Line__c>(
						  [ select id, Ship_From_Location__c, Company__c,Quantity_From_Stock__c,
							   ( select id, Quantity__c from SKIDs__r
								where type__c=:SkidService2.SKID_TYPE_SO_DEMAND),
								(Select Id, Quantity_Allocated__c
								from Shipment_Lines__r
								  where Shipment__r.Status__c != 'Confirmed' AND Shipment__r.Status__c != 'Delivered')
								   from Sales_Order_Line__c
							 where Id IN:solIds.keySet() ]);

	for( Sales_Order_Line__c sol : soLineMap.values() )
	{
	  SKID__c demandSkid;
	  Decimal unAllocatedQty = 0;

	  //Loop to run through the Skids under an Order Line
	  for( SKID__c skd : solIds.get(sol.id))
	  {
		if(demandSkidsMap.containsKey(sol.Id)){
		  demandSkid = demandSkidsMap.get(sol.Id);
		}else{
		  if( sol.SKIDs__r.size() != 0){
			demandSkid = sol.SKIDs__r[0];
		  }else{
			demandSkid = skd.clone(false, true);
			demandSkid.Quantity__c=0;
			demandSkid.Location__c = sol.Ship_From_Location__c;
			demandSkid.Company__c = sol.Company__c;
			demandSkid.type__c = SkidService2.SKID_TYPE_SO_DEMAND;
		  }
		  demandSkidsMap.put( sol.id, demandSkid);
		}

		demandSkid.Quantity__c += skd.Quantity__c;

		unAllocatedQty = KSE.addQuantityToField(unAllocatedQty, skd.Quantity__c);
	  }

		if(sol.Shipment_Lines__r.size() > 0 && unAllocatedQty != 0){
		  Shipment_Line__c shl = sol.Shipment_Lines__r[0];
		  shl.Quantity_Allocated__c = KSE.subtractDecimals(shl.Quantity_Allocated__c, unAllocatedQty);
		  updateShlMap.put(shl.Id, shl);
		}

	}


	if(demandSkidsMap.size()>0){
		DML.upsertAsSystem(); upsert demandSkidsMap.values();
	}

	for(SKID__c allocSkid : allocatedSkids ){

	  // Delete the "Allocated" skids
	  deleteSkids.add(allocSkid);

	  // Unallocated qty in Selling UOM
	  // Unallocated qty in Selling UOM
	  Decimal unallocatedQty = (allocSkid.Quantity__c / KSE.getConversionFactorFromQuantity(allocSkid.Sales_Order_Line__r.Quantity_From_Stock__c,allocSkid.Sales_Order_Line__r.Quantity_Ordered__c)).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(allocSkid.Sales_Order_Line__r);

	  if(updateSolMap.containsKey(allocSkid.Sales_Order_Line__c)){

		updateSolMap.get(allocSkid.Sales_Order_Line__c).Quantity_Allocated__c = KSE.subtractDecimals(allocSkid.Sales_Order_Line__r.Quantity_Allocated__c, unallocatedQty);
	  }
	  else{
		updateSolMap.put(allocSkid.Sales_Order_Line__c, allocSkid.Sales_Order_Line__r);
		allocSkid.Sales_Order_Line__r.Quantity_Allocated__c = KSE.subtractDecimals(allocSkid.Sales_Order_Line__r.Quantity_Allocated__c, unallocatedQty);
	  }
	}

	DML.deleteAsSystem(deleteSkids);
	DML.updateAsUser(updateSolMap.values());
	DML.updateAsSystem(updateShlMap.values());
  }
  
  public void undoConfirmPickNew( set<Id> inventoryTransactionIds ){

	SchemaUtil util = SchemaUtil.getInstance();
	list<SKID__c> putawaySkidList = new list<SKID__c>();
	list<SKID__c> allocatedSkidList = new list<SKID__c>();
	list<String> attributes = new list<String>();
	set<Id> uniqueLocations = new set<Id>();
	Map<Id,sObject> sourceDocs = new Map<Id,sObject>();
	Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
	list<Inventory_Transaction__c> reversedITs = new list<Inventory_Transaction__c>();
	set<Id> uniqueToLocations = new set<Id>();
	Map<Id, Shipment__c> shipmentsMap = new Map<Id, Shipment__c>();
	Map<Id,Shipment_Line__c> shlsToUpdate = new Map<Id,Shipment_Line__c>();

	attributes.addAll( SkidService2.attributesForPutaway( new list<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c')) ));

	list<String> attributesForAllocated = attributes.clone();
	attributesForAllocated.add('Sales_Order_Line__c'); //adding sales order line and shipment line as attributes as the allocated skids needs those references.
	attributesForAllocated.add('Shipment_Line__c');

	set<String> itFields = new set<String>{ 'Id', 'Name','Item__c','Item__r.Stocking_UOM__c','From_Location__c','From_Skid__c','From_Skid__r.Lot__c',
							  'From_SKID__r.Bin__c','From_SKID__r.Bin__r.Name','From_Skid__r.Expiration_Date__c',
							  'From_Skid__r.Shipment_Line__c','To_Location__c', 'From_Facility__r.Facility_Identifier__c','To_Facility__r.Facility_Identifier__c',
							  'Quantity__c','Standard_Cost__c','Shipment_Line__r.Quantity_Shipped__c', 'Shipment_Line__r.Sales_Order_Line__r.Ship_From_Location__r.Facility__r.Facility_Identifier__c',
							  'Shipment_Line__r.Shipment__c','Shipment_Line__r.Extended_Price__c','Shipment_Line__r.Shipment__r.Finalized__c',
							  'Shipment_Line__r.Shipment__r.Status__c', 'To_Skid__r.Location__r.Facility__c',
							  'To_Skid__c','To_Skid__r.Id','To_Skid__r.Type__c','To_Skid__r.Lot__c','To_Skid__r.Expiration_Date__c','To_Skid__r.Item__c',
							  'To_Skid__r.Quantity__c','To_Skid__r.Sales_Order_line__c','To_Skid__r.Location__c','To_Skid__r.Item__r.Packaging_UOM__c',
							  'Shipment_Line__r.Shipment__r.Date_Shipped__c','Sales_Order_Line__c','Sales_Order_Line__r.Sales_Order__c','Sales_Order_Line__r.Company__c',
							  'Shipment_Line__r.Quantity_Picked__c','Shipment_Line__r.Quantity_Allocated__c','Shipment_Line__r.Sales_Order_Line__r.Selling_UOM__c',
							  'Shipment_Line__r.Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__c','Shipment_Line__r.Sales_Order_Line__r.Product__r.Item__c',
	                          'Shipment_Line__r.Sales_Order_Line__r.Product__r.Item__r.Packaging_UOM__c','To_Skid__r.Facility2__r.Facility_Identifier__c',
							  'From_Skid__r.Facility2__r.Facility_Identifier__c'
	};

	itFields.addAll(util.getAllCustomFieldsFromObject(null, 'Inventory_Transaction__c'));
	itFields.addAll(util.getAllCustomFieldsFromObject('To_Skid__r.', 'Skid__c'));
   
	/*String loc = SKIDService2.SKID_TYPE_LOCATION;

	String query = util.generateQueryFromFieldSet( 'Inventory_Transaction__c', new set<string>{'ConfirmShipRO'},
			itFields, 'type__c IN (\'Sales Order Pick\',\'Sales Order Allocation\') and Finalized__c = true and Shipment_Line__r.Shipment__r.Status__c != \'Confirmed\' and ID IN:inventoryTransactionIds');
	*/
	String whereClause = 'Type__c IN (\'Sales Order Pick\',\'Sales Order Allocation\') and Finalized__c = true and Shipment_Line__r.Shipment__r.Status__c != \'Confirmed\' and ID IN :inventoryTransactionIds';

	SOQLUtil soql = new SOQLUtil('Inventory_Transaction__c');
	soql.addFields('ConfirmShipRO');
	soql.addFields(itFields);
	soql.setWhereClause(whereClause);

	list<Inventory_Transaction__c> selectedITs = Database.query(soql.getQuery());

	for( Inventory_Transaction__c it : selectedITs ){

		uniqueToLocations.add( it.to_Location__c );

		if(it.Shipment_Line__c != null){
				it.Shipment_Line__r.Shipment__r.Status__c = 'Released';

				shipmentsMap.put(it.Shipment_Line__r.Shipment__c, it.Shipment_Line__r.Shipment__r);

				Shipment_Line__c shl = new Shipment_Line__c(Id = it.Shipment_Line__c);
				shl.Quantity_Picked__c = KSE.subtractDecimals(it.Shipment_Line__r.Quantity_Picked__c,it.Quantity__c);
				shl.Quantity_Allocated__c = KSE.addQuantityToField(it.Shipment_Line__r.Quantity_Allocated__c,it.Quantity__c / KSE.getConversionFactor(it.Shipment_Line__r.Sales_Order_Line__r));

				shlsToUpdate.put(it.Shipment_Line__c,shl);
			}
			else{
				throw new SalesOrderServiceException('Shipment Line not found for the inventory transaction: ' + it.Name);
			}
	}

	map< String, SKID__c > existingSkidKeysMap = SkidService2.generateExistingSkidMap(attributes, uniqueToLocations, 'Location');
	Map<Id,String> icTypes = new Map<Id,String>();
	for( Inventory_Transaction__c it : selectedITs ){

		if( it.To_Skid__c == null ){

			  String key = SkidService2.generateKeyForIT( it, attributes);
			  if( existingSkidKeysMap.containsKey( key ) ){

				it.To_SKID__c = existingSkidKeysMap.get( key ).id;
				it.To_SKID__r = existingSkidKeysMap.get( key );
			  }
			  else{
				continue;
			  }
			}

	  uniqueLocations.add( it.From_Location__c );
	  SKID__c skidToPutaway = it.To_Skid__r.clone( false, true );
	  skidToPutaway.Location__c = it.From_Location__c;
	  skidToPutaway.bin__c = it.From_Bin__c;
	  skidToPutaway.Quantity__c = it.Quantity__c;
	  skidToPutaway.Type__c = SkidService2.SKID_TYPE_LOCATION;
	  if( it.to_Skid__c == it.From_Skid__c ){
		  skidToPutaway.Quantity__c = 0;
	  }
	  putawaySkidList.add(skidToPutaway);

	  SKID__c allocatedSkid = it.To_Skid__r.clone( false, true );
	  allocatedSkid.Location__c = it.From_Location__c;
	  allocatedSkid.Quantity__c = it.Quantity__c;
	  allocatedSkid.bin__c = it.From_Bin__c;
	  allocatedSkid.Sales_Order_Line__c = it.Sales_Order_Line__c;
	  allocatedSkid.Shipment_Line__c = it.Shipment_Line__c;
	  allocatedSkid.Type__c = SkidService2.SKID_TYPE_ALLOCATED;
	  allocatedSkidList.add(allocatedSkid);
	  //specifying the to skid and attributesfor allocated to copy the attributes into the IT , along with the sales order line and the shipment line for the IT
	  SKID__c fromSkid = it.To_Skid__r;

	  //Inventory_Transaction__c itForPutaway = SkidService2.createIT( it.To_Skid__r, it.Item__c,'Sales Order Undo Pick',null,null,null,it.From_Location__c, allocatedSkid , attributesForAllocated);
	  Inventory_Transaction__c itForPutaway = SkidService3.createInventoryTransaction( it.Sales_Order_Line__r, 'Sales Order Undo Pick', it.Quantity__c, fromSkid, allocatedSkid, attributesForAllocated);
	  //itForPutaway.Quantity__c = it.Quantity__c;

	  if (it.Inventory_Change__c != null)
		sourceDocs.put(it.Sales_Order_Line__r.Sales_Order__c,new Sales_Order__c(Company__c = it.Sales_Order_Line__r.Company__c));

	  if (!itMap.containsKey(it.Sales_Order_Line__r.Sales_Order__c))
		itMap.put(it.Sales_Order_Line__r.Sales_Order__c,new List<Inventory_Transaction__c>());

	  itMap.get(it.Sales_Order_Line__r.Sales_Order__c).add(itForPutaway);
	  icTypes.put(it.Sales_Order_Line__r.Sales_Order__c,'Sales Order Pick');

	  Inventory_Transaction__c itReverse = new Inventory_Transaction__c( Id = it.id, Reversed__c = true );
	  reversedITs.add( itReverse );
	}

	map< String, SKID__c > toSkidsForIT = SkidService2.putAwayService( putawaySkidList, attributes, uniqueLocations, 'Location', false); //puts back the quantity in a location skid or creates one based on attributes.
	SkidService2.putAwayService( allocatedSkidList, attributesForAllocated, uniqueLocations, 'Allocated', false); // creates/merges allocated skids

	skidService2.inventoryTransactionsForPutAway(sourceDocs,itMap,icTypes,null,attributes,toSkidsForIT,null,null); // creates inventory transactions for putaway and decrements the from skids.
	DML.updateAsSystem(reversedITs);
	DML.updateAsUser(shipmentsMap.values());
	DML.updateAsUser(shlsToUpdate.values());
  }

    public void undoShipConfirm(Set<Id> shipmentIds){
        undoShipConfirm(shipmentIds, null);
    }

    public void undoShipConfirm( Set<Id> shipmentIds, String action ){
        System.Savepoint sp = Database.setSavepoint();
        try{
            SchemaUtil util = SchemaUtil.getInstance();
            list<SKID__c> putawaySkidList = new list<SKID__c>();
            list<String> attributes = new list<String>();
            set<Id> uniqueLocations = new set<Id>();
            Map<Id,sObject> sourceDocs = new Map<Id,sObject>();
            Map<Id,List<Inventory_Transaction__c>> itMap = new Map<Id,List<Inventory_Transaction__c>>();
            list<sobject> solLines = new list<sobject>();
            list<Shipment_Line__c> shlLines = new list<Shipment_Line__c>();
            list<Shipment__c> shList = new list<Shipment__c>();
            set<Id> shipmentUniqueIds = new set<Id>();
            map<Id, SObject> OrderMap = new map<Id,SObject>();

            list<SKID__c> demandSkids = new list<SKID__c>();
            set<Id> uniqueToLocations = new set<Id>();
            Boolean nonInventoryLinesExist = false;

            string sourceDocument='';
            string sourceDocumentRelation='';
            string sourceDocumentLine='';
            string sourceDocumentLineRelation='';
            string skidType='';
            string undoShipmentMessage='';
            List<sObject> itReversedList=new list<sObject>();
            map< String, SKID__c > existingSkidKeysMap = new map<string,Skid__c>();
            list<String> attributesForInTransit = new List<string>();
            String loc = SKIDService2.SKID_TYPE_LOCATION;

            list<Accounting_Entry__c> aeList = [Select id, Name, Shipment__r.Name from accounting_entry__c where void__c = false and Status__c != 'Obsolete' and Shipment__c IN: shipmentIds ];

            if( aeList.size() > 0 ){
                throw new SalesOrderServiceException(aeList[0].Shipment__r.Name+' has already been accounted.');
            }

            //String subquery =  '(SELECT Id, Receipt_Line__c, Receipt_Line__r.Receiving_Document__r.Status__c, Receipt_Line__r.Receiving_Document__r.Name FROM Inventory_Transactions__r)';

            set<String> shlFields = new set<String>{ 'Id', 'Name','Order_Line__r.Quantity_Allocated__c','Order_Line__r.Order__r.Status__c','Sales_Order_Line__r.Quantity_Allocated__c','Shipment__r.Name', 'Sales_Order_Line__r.Sales_Order__r.Status__c',
                                      'Order_Line__r.Shipping_Item__r.Non_Inventory__c','Order_Line__r.Required_Date__c','Sales_Order_Line__r.Quantity_Ordered__c', 'Sales_Order_Line__r.Ship_From_Location__c',
                                      'Sales_Order_Line__r.Selling_UOM__r.Name', 'Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__r.Name','Sales_Order_Line__r.Product__r.Item__r.Non_Inventory__c',
                                      'Order_Line__r.Quantity_Shipped__c','Order_Line__c', 'Sales_Order_Line__r.Estimated_Ship_date__c', 'Sales_Order_Line__r.Quantity_From_Stock__c',
                                      'Sales_Order_Line__r.Product__r.Item__r.Packaging_UOM__c', 'Order_Line__r.Shipping_Item__r.Packaging_UOM__c', 'Item__r.Packaging_UOM__c',
                                      'Sales_Order_Line__r.Quantity_Shipped__c','Shipment__r.Finalized__c','Shipment__r.Status__c','Shipment__r.Date_Shipped__c','Sales_Order_Line__c', 'Shipment__r.Transaction_Type__c'
            };

            shlFields.addAll(util.getAllCustomFieldsFromObject(null, 'Shipment_Line__c'));

            //String queryString = util.generateQueryFromFieldSet( 'Shipment_Line__c', new set<string>{}, fieldStringList, 'Shipment__c IN:shipmentIds');

            SOQLUtil soql = new SOQLUtil('Shipment_Line__c');
        soql.addFields(shlFields);
        soql.setWhereClause('Shipment__c IN:shipmentIds');

        SOQLUtil.ChildRelationship invTrans = new SOQLUtil.ChildRelationship(soql, 'Inventory_Transactions__r');
        invTrans.addFields(new Set<String>{'Id', 'Receipt_Line__c', 'Receipt_Line__r.Receiving_Document__r.Status__c', 'Receipt_Line__r.Receiving_Document__r.Name'});
        soql.addChildRelationship(invTrans);

            list<Shipment_Line__c> shipmentLines = Database.query(soql.getQuery());

            Map<Id, Decimal> shlPickedQtyMap = new Map<Id, Decimal>();

            for( sObject shl : shipmentLines ){
                //Set<String> voidCancelSet = new Set<String>{VoidCancelService.VOID_STATUS, VoidCancelService.CANCELLED_STATUS};

                if ((string)shl.getSObject('Shipment__r').get('Transaction_Type__c') == ShipmentService.SHIPMENT_TRANSACTION_TYPE_LOGICAL
                    && action != 'Undo Drop Ship' ) {
                    String rdName = ((Shipment_Line__c) shl).Inventory_Transactions__r[0].Receipt_Line__r.Receiving_Document__r.Name;
                    throw new SalesOrderServiceException( 'The Shipment (' + (string)shl.getSObject('Shipment__r').get('Name')+') cannot be undo shipped. Please void/cancel the Recieiving Document (' + rdName + ').');
                }

                if( (!shipmentUniqueIds.contains((Id)shl.get('Shipment__c'))) && ((string)shl.getSObject('Shipment__r').get('Status__c') != 'Confirmed')){
                    throw new SalesOrderServiceException( (string)shl.getSObject('Shipment__r').get('Name')+' is not confirmed. Only confirmed shipments can be reversed : '+ (string)shl.getSObject('Shipment__r').get('Status__c'));
                }

                if(shl.get('Product__c') != null){
                    undoShipmentMessage = 'Sales Order Undo Shipment';
                    sourceDocument = 'Sales_Order__c';
                    sourceDocumentRelation = 'Sales_Order__r';
                    sourceDocumentLine = 'Sales_Order_Line__c';
                    sourceDocumentLineRelation = 'Sales_Order_Line__r';
                }
                else{
                    undoShipmentMessage = 'Transfer Order Undo Shipment';
                    sourceDocument = 'Order__c';
                    sourceDocumentRelation = 'Order__r';
                    sourceDocumentLine = 'Order_Line__c';
                    sourceDocumentLineRelation = 'Order_Line__r';
                }

                sObject sol;
                sol = shl.getsObject(sourceDocumentLineRelation);
                boolean nonInventory=true;

                if(sourceDocument=='Sales_Order__c')
                {
                    nonInventory = (boolean)sol.getSObject('Product__r').getSObject('Item__r').get('Non_Inventory__c');
                }
                else if(sourceDocument=='Order__c')
                {
                    nonInventory = (boolean)sol.getSObject('Shipping_Item__r').get('Non_Inventory__c');
                }

                if(nonInventory ==false)
                {
                    sol.put('Quantity_Allocated__c',KSE.addQuantityToField((decimal)sol.get('Quantity_Allocated__c') , (decimal)shl.get('Quantity_Shipped__c') ));
                }
                else{
                    nonInventoryLinesExist = true;
                    if(sourceDocument == 'Order__c'){
                        SKID__c SKIDObj = new SKID__c();
                        SKIDObj.Type__c = skidservice2.SKID_TYPE_TO_DEMAND;
                        SKIDObj.Item__c = (Id)shl.get('Item__c');
                        SKIDObj.Item__r = (Item__c)shl.getSObject('Item__r');
                        SKIDObj.Order_Line__c = sol.ID;
                        SKIDObj.Shipment_Line__c = shl.Id;
                      	SKIDObj.Quantity__c = (Decimal)shl.get('Quantity_Shipped__c');
                        SKIDObj.Order_Date__c= (Date)sol.get('Required_Date__c');
                        SKIDObj.Location__c = (Id)shl.get('Location__c');
                        SKIDObj.Company__c = (Id)shl.get('Company__c');
                        demandSkids.add(SKIDObj);
                    }
                    else{
                        SKID__c demandSkid = new SKID__c();
                        demandSkid.Type__c = skidservice2.SKID_TYPE_SO_DEMAND;
                        demandSkid.Item__c = (Id)sol.getSObject('Product__r').get('Item__c');
                        demandSkid.Item__r = (Item__c)sol.getSObject('Product__r').getSObject('Item__r');
                        demandSkid.Sales_Order_Line__c = sol.id;
                        demandSkid.Shipment_Line__c = shl.Id;
                        demandSkid.Company__c = (Id)shl.get('Company__c');

                        decimal cf = 1;
                        if((Decimal)sol.get('Quantity_From_Stock__c') ==null || (Decimal)sol.get('Quantity_From_Stock__c')==0)
                            cf =  KSE.getConversionFactor(sol);
                        else
                            cf =  KSE.getConversionFactorFromQuantity((Decimal)sol.get('Quantity_From_Stock__c'),(Decimal)sol.get('Quantity_Ordered__c'));

                        demandSkid.Quantity__c = (Decimal)shl.get('Quantity_Shipped__c') * cf; // OTC-427 - Should be UOM converted.
                        demandSkid.Order_Date__c = (Date)sol.get('Estimated_Ship_date__c');
                      	demandSkid.Location__c = (Id)shl.get('Location__c');
                        demandSkids.add(demandSkid);
                    }
                }

                sol.put('Quantity_Shipped__c',KSE.subtractDecimals((decimal)sol.get('Quantity_Shipped__c') , (decimal)shl.get('Quantity_Shipped__c')));
                if(!sourceDocumentLine.equals('Order_Line__c')){
                  sol.put('Quantity_Fulfilled__c', sol.get('Quantity_Shipped__c'));
                }
                sol.put('Status__c',SO_STATUS_OPEN);
                solLines.add( sol );

                if((string)sol.getsObject(sourceDocumentRelation).get('Status__c') == SO_STATUS_CLOSED)
                {
                    sObject ord = util.getGlobalDescribe(sourceDocument).newSObject((Id)sol.getSObject(sourceDocumentRelation).get('Id')) ;
                    ord.put('Status__c',SO_STATUS_OPEN);
                    orderMap.put( ord.id, ord);
                }

                if(!shipmentUniqueIds.contains((Id)shl.get('Shipment__c'))){
                    sObject sh = shl.getsobject('Shipment__r');
                    sh.put('Status__c','Staged');

                    //KNDY-7904 (Existing shipment flow)
                    if((Boolean)sh.get('Finalized__c')){

                        sh.put('Finalized__c',false);
                        sh.put('Finalized_Hidden__c',false);

                    }
                    //Update Locked__c field to false
                    sh.put('Locked__c', false);

                    sh.put('Date_Shipped__c',null);
                    shList.add( (shipment__c)sh );
                }

                shipmentUniqueIds.add( (Id)shl.get('Shipment__c') );

                shl.put('Extended_Cost__c',0);
                shl.put('Quantity_Shipped__c',0);
                shl.put('Quantity_From_Stock__c',0);
                shl.put('Extended_Cost__c',0);
                shlLines.add((Shipment_Line__c) shl );
            }

            attributes.addAll(SkidService3.attributesForPutaway());

            Set<String> itTypes = new Set<String>{ InventoryTransactionService.SALES_ORDER_SHIPMENT, InventoryTransactionService.TRANSFER_ORDER_SHIPMENT, InventoryTransactionService.LOGICAL_SALES_ORDER_SHIPMENT };
            SOQLUtil itQuery = new SOQLUtil('Inventory_Transaction__c');
            itQuery.addAllCustomFields();
            itQuery.addAllCustomFields(SKID__c.sObjectType,'From_SKID__r');
            itQuery.addAllCustomFields(SKID__c.sObjectType,'To_SKID__r');
            itQuery.addFields(new Set<String>{'Item__r.Packaging_UOM__c', 'Item__r.Stocking_UOM__c','From_Location__r.Facility__c','From_Location__r.Facility__r.Company__c','Order_Line__r.Quantity_Allocated__c','Order_Line__r.Quantity_Shipped__c','Shipment_Line__r.Order_Line__c',
                'Sales_Order_Line__r.Quantity_Allocated__c','Sales_Order_Line__r.Selling_UOM__r.Name','Sales_Order_Line__r.Product__r.Item__r.Stocking_UOM__r.Name','Shipment_Line__r.Quantity_Shipped__c','Sales_Order_Line__r.Quantity_Shipped__c',
                'Shipment_Line__r.Shipment__c','Shipment_Line__r.Extended_Price__c','Shipment_Line__r.Shipment__r.Finalized__c','Shipment_Line__r.Shipment__r.Status__c','To_SKID__r.Location__r.Facility__c','Shipment_Line__r.Shipment__r.Name',
                'Shipment_Line__r.Shipment__r.Date_Shipped__c','Shipment_Line__r.Sales_Order_Line__c','Shipment_Line__r.Shipment__r.Transaction_Type__c','Sales_Order_Line__r.Sales_Order__c','Sales_Order_Line__r.Company__c','Order_Line__r.Order__c',
                'Order_Line__r.Shipping_Company__c', 'To_SKID__r.Item__r.Stocking_UOM__c', 'To_SKID__r.Item__r.Packaging_UOM__c' });
            itQuery.setWhereClause('Type__c IN :itTypes and Reversed__c = false and Shipment_Line__r.Shipment__c IN :shipmentIds');

            List<sObject> selectedITs = Database.query(itQuery.getQuery());

            if( selectedITs.size() ==0 && (!nonInventoryLinesExist) ){

                throw new SalesOrderServiceException('There are no lines available to do Undo Ship');
            }
            Set<Id> shipITs = new Set<Id>();
            for( sObject it : selectedITs )
            {
                if((string)it.get('type__c')=='Sales Order Shipment' && sourceDocument == '')
                {

                	shipITs.add((Id)it.get('Id'));
                }
            }

            List<Fulfillment__c> fulfillmentsToUpdate = new List<Fulfillment__c>();
            if (shipITs.size() > 0) {
                SOQLUtil fulfillmentQuery = new SOQLUtil('Fulfillment__c');
                fulfillmentQuery.addAllCustomFields();
                fulfillmentQuery.setWhereClause('Inventory_Transaction__c IN :shipITs');

                for (Fulfillment__c fulfillment:Database.query(fulfillmentQuery.getQuery())) {
                    fulfillment.Invoice_Ready__c = false;
                    fulfillmentsToUpdate.add(fulfillment);
                }
            }
            if (fulfillmentsToUpdate.size() > 0) DML.updateAsUser(fulfillmentsToUpdate);

            for( sObject it : selectedITs )
            {
                if((string)it.get('type__c')=='Sales Order Shipment' && sourceDocument == '')
                {
                    undoShipmentMessage = 'Sales Order Undo Shipment';
                    sourceDocument = 'Sales_Order__c';
                    sourceDocumentRelation = 'Sales_Order__r';
                    sourceDocumentLine = 'Sales_Order_Line__c';
                    sourceDocumentLineRelation = 'Sales_Order_Line__r';
                    skidType = SkidService2.SKID_TYPE_SO_DEMAND;
                }
                else if((string)it.get('type__c')=='Transfer Order Shipment' && sourceDocument == '')
                {

                    undoShipmentMessage = 'Transfer Order Undo Shipment';
                    sourceDocument = 'Order__c';
                    sourceDocumentRelation = 'Order__r';
                    sourceDocumentLine = 'Order_Line__c';
                    sourceDocumentLineRelation = 'Order_Line__r';
                    skidType = SkidService2.SKID_TYPE_TO_DEMAND;
                    uniqueToLocations.add( (Id)it.get('to_Location__c') );
                }
            }

            if(sourceDocument=='Order__c'){
                attributesForInTransit = attributes.clone();
                attributesForInTransit.add('Order_Line__c');
                attributesForInTransit.add('Shipment_Line__c');
                existingSkidKeysMap = SkidService2.generateExistingSkidMap(attributesForInTransit, uniqueToLocations, 'In-Transit');
            }
          Map<Id,String> icTypes = new Map<Id,String>();
            for( sObject it : selectedITs ){

                if (!shlPickedQtyMap.containsKey((Id)  it.get('Shipment_Line__c'))){
                    shlPickedQtyMap.put( (Id) it.get('Shipment_Line__c'), (Decimal) it.get('Quantity__c'));
                } else {
                    Decimal qtyPicked = shlPickedQtyMap.get( (Id) it.get('Shipment_Line__c') ) + (Decimal) it.get('Quantity__c');
                    shlPickedQtyMap.put( (Id) it.get('Shipment_Line__c'), qtyPicked);
                }

                if( (string)it.getSObject('Shipment_Line__r').getSObject('Shipment__r').get('Status__c') != 'Confirmed'){
                    throw new SalesOrderServiceException((string)it.getSObject('Shipment_Line__r').getSObject('Shipment__r').get('Name') +' is not confirmed. Only confirmed shipments can be reversed.');
                }

                Skid__c ITFromSkid= null;

                if(sourceDocument == 'Order__c')
                {
                    if( it.get('To_Skid__c') == null )
                    {
                        String key = SkidService2.generateKeyForIT( (Inventory_Transaction__c)it, attributesForInTransit);
                        if( existingSkidKeysMap.containsKey( key ) )
                        {
                            it.put('To_SKID__c',existingSkidKeysMap.get( key ).id);
                            it.putsObject('To_SKID__r', existingSkidKeysMap.get( key ));

                        }
                        else
                        {
                            continue;
                        }
                    }

                    ITFromSkid = (skid__c)it.getsObject('To_Skid__r');
                }

                Inventory_Transaction__c itReversed = new Inventory_Transaction__c(id=it.Id,Reversed__c=true);
                itReversedList.Add(itReversed);
                uniqueLocations.add( (Id)it.get('From_Location__c'));

                SKID__c skidToPutaway = new SKID__c();
                SkidService2.copyITAttributesToSkid( skidToPutaway , (Inventory_Transaction__c)it, attributes );
                skidToPutaway.Item__r = (Item__c)it.getSObject('Item__r');
                skidToPutaway.Company__c = (Id)it.get('Company__c');
                skidToPutaway.Location__c = (Id)it.get('From_Location__c');
                skidToPutaway.Location__r = (Location__c)it.getSObject('From_Location__r');
                skidToPutaway.bin__c = (Id)it.get('From_Bin__c');

                if(it.get('Lot__c')!=null)
                    skidToPutaway.Lot_Number__c = (string)it.getsObject('Lot__r').get('Name');

                skidToPutaway.Quantity__c = (decimal)it.get('Quantity__c');
                skidToPutaway.Type__c = SkidService2.SKID_TYPE_LOCATION;
                putawaySkidList.add(skidToPutaway);

                sObject itForPutaway;
                //itForPutaway = (sObject)SkidService2.createIT(ITFromSkid, (Id)it.get('Item__c'),undoShipmentMessage,null,null,null,(Id)it.get('From_Location__c'), null , attributes);
                itForPutaway = (sObject)SkidService3.createInventoryTransaction(it.getSObject(sourceDocumentLineRelation), undoShipmentMessage, (Decimal) it.get('Quantity__c'), ITFromSkid, null , attributes);
                //itForPutaway.put(sourceDocumentLine,it.get(sourceDocumentLine));
                itForPutaway.put('Shipment_Line__c',(id)it.get('Shipment_Line__c'));

                SkidService2.copyToSkidAttributesToIT((Inventory_Transaction__c)itForPutaway, skidToPutaway, attributes); // JUSTDOIT What is this for ?
                //itForPutaway.put('Quantity__c',(decimal)it.get('Quantity__c'));
                String lineRel, headerRel, companyRel;
                if (it.get('Sales_Order_Line__c') != null) {
                    lineRel = 'Sales_Order_Line__r';
                    headerRel = 'Sales_Order__c';
                    companyRel = 'Company__c';
                } else if (it.get('Order_Line__c') != null) {
                    lineRel = 'Order_Line__r';
                    headerRel = 'Order__c';
                    companyRel = 'Shipping_Company__c';
                }
                if (it.get('Inventory_Change__c') != null)
                  sourceDocs.put((Id)it.getSObject(lineRel).get(headerRel),new Sales_Order__c(Company__c = (Id)it.getSObject(lineRel).get(companyRel)));
                if (!itMap.containsKey((Id)it.getSObject(lineRel).get(headerRel)))
                    itMap.put((Id)it.getSObject(lineRel).get(headerRel),new List<Inventory_Transaction__c>());
                itMap.get((Id)it.getSObject(lineRel).get(headerRel)).add((Inventory_Transaction__c)itForPutaway);
                if (itForPutaway.get('Type__c') == 'Sales Order Undo Shipment')
                  icTypes.put((Id)it.getSObject(lineRel).get(headerRel),'Sales Order Shipment');
                else if (itForPutaway.get('Type__c') == 'Transfer Order Undo Shipment')
                  icTypes.put((Id)it.getSObject(lineRel).get(headerRel),'Transfer Order Shipment');
            }

            for (Shipment_Line__c shl : shlLines){
                if (shlPickedQtyMap.containsKey(shl.id)){
                    shl.Quantity_Picked__c = shlPickedQtyMap.get(shl.id);
                }
            }


            map< String, SKID__c > toSkidsForIT = SkidService2.putAwayService( putawaySkidList, attributes, uniqueLocations, 'Location', false); //puts back the quantity in a location skid or creates one based on attributes.
            SkidService2.inventoryTransactionsForPutAway(sourceDocs,itMap,icTypes,null,attributes,toSkidsForIT,null,null); // creates inventory transactions for putaway and decrements the from skids.

            DML.updateAsUser(solLines);
            DML.updateAsUser(orderMap.values());
            if(demandSkids.size() > 0)
                DML.insertAsSystem(demandSkids);
            DML.updateAsUser(shList);
            DML.updateAsUser(shlLines);
            if(itReversedList.size()>0)
                DML.updateAsSystem(itReversedList);
        }
        catch(Exception e){
            Database.rollback(sp);
            throw e;
        }

    }


  // KNDY-1489: Close / Cancel all the sales order lines if the sales order is closed / cancelled
  public static void close(Set<Id> salesOrderIds){
	System.Savepoint sp = Database.setSavepoint();

	try{
	  List<Sales_Order__c> closedSalesOrders = new List<Sales_Order__c>();
	  List<Purchase_Order__c> closedPurchaseOrders = new List<Purchase_Order__c>();

	  for(Sales_Order__c so : [select Id, Type__c, Status__c, Purchase_Order__c, Purchase_Order__r.Status__c
									 from Sales_Order__c where Id IN :salesOrderIds and Status__c = :SO_STATUS_OPEN]){
		so.Status__c = SO_STATUS_CLOSED;
		closedSalesOrders.add(so);
	  }

	  if(closedSalesOrders.size() > 0){
		//KNDY-1753
		DML.updateAsUser(closedSalesOrders);
	  }

	}catch(Exception e){
	  Database.rollback(sp);
	  throw e;
	}
  }

  public List<Sales_Order_Line__c> getSalesOrderLinesToAllocate(List<Id> soIdList){

        String mtoItemSource = ItemService.ITEM_SOURCE_MAKE_TO_ORDER;
        String btoFfSource = SalesOrderLineService.SOL_FULFILLEMENT_SOURCE_BUILD_TO_ORDER;
        String repair = SalesOrderService.SO_TYPE_REPAIR;

        set<String> solFields = new set<string>{ 'id', 'name',  'line__c', 'product__r.item__c', 'product__r.item__r.description__c', 'product__r.item__r.stocking_uom__c',
                          'product__r.item__r.packaging_uom__c','product__r.item__r.non_inventory__c', 'product__r.item__r.name', 'product__r.item__r.class__c', 'quantity_allocated__c', 'Quantity_From_Stock__c',
                          'quantity_backordered__c', 'company__c', 'sales_order__r.currency__c','sales_order__r.Currency__r.ISO_Code__c','Pricebook__r.Currency__r.ISO_Code__c' ,'Pricebook__r.Currency__c','sales_order__r.company__c', 'description__c',
                          'product__c', 'product__r.name', 'quantity_ordered__c', 'quantity_shipped__c', 'quantity_to_ship__c', 'ship_from_location__c', 'ship_from_location__r.name',
                          'required_date__c', 'sales_order__c', 'sales_order__r.customer__r.top_parent_customer__c', 'status__c', 'discount_percent__c',
                          'unit_price__c', 'systemmodstamp', 'sales_order__r.customer__r.top_parent_customer__r.status__c','product__r.item__r.source__c', 'sales_order__r.type__c',
                          'product__r.item__r.stocking_uom__r.name','product__r.item__r.stocking_uom__c', 'selling_uom__c', 'selling_uom__r.name', 'ship_from_location__r.facility__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c',
                          'product__r.item__r.item_attribute__r.expiration_date__c','product__r.item__r.item_attribute__r.lot_number__c','has_exceptions__c','Sales_Order__r.Company__r.Comp_Currency__c' };

        solFields.addAll(SchemaUtil.getInstance().getAllCustomFieldsFromObject('product__r.item__r.item_attribute__r.','item_attribute__c'));

        for( Stock_Movement_Rule_Settings__c smrs : Stock_Movement_Rule_Settings__c.getAll().values() ){
            if( smrs.Source_Document__c == 'Sales Order' )
              solFields.add( (smrs.Source_Document_Path__c).toLowerCase() );
        }

        Set<String> skidFields = new Set<String>{'Id', 'Name', 'Item__c', 'Item__r.Name', 'Company__c', 'Company__r.Name', 'Item__r.Class__c', 'Item__r.Class__r.Name',
                             					'Bin__c', 'Expiration_Date__c', 'Quantity_Allocated__c', 'Location__c', 'Location__r.Facility__c', 'Lot__c',
                             					'Lot__r.Name', 'Quantity_Available__c', 'Location__r.Facility__r.Company__c', 'Sales_Order_Line__r.Id', 'Item__r.Stocking_UOM__c',
				                                'Quantity__c', 'Shipment_Line__c', 'Shipment_Line__r.Quantity_Shipped__c', 'Stocking_UOM__c', 'Packaging_UOM__c', 'Item__r.Packaging_UOM__c',
				                                'Shipment_Line__r.Shipment__c', 'Shipment_Line__r.Shipment__r.Status__c', 'Type__c','Facility2__c', 'Facility2__r.Facility_Identifier__c'};

		String whereClause = ' Sales_Order__c IN :soIdList and Quantity_Backordered__c > 0.0 and Sales_Order__r.Status__c = :SO_STATUS_OPEN ' +
							 ' and Status__c = :SO_STATUS_OPEN and Product__r.Item__r.Non_Inventory__c = false and Has_Exceptions__c = false' +
							 ' and Product__r.Item__r.Source__c !=:mtoItemSource and Sales_Order__r.Type__c !=:repair'+
							 ' and Fulfillment_Source__c !=:btoFfSource and Fulfillment_Source__c != \'Drop Ship\''+
							 ' order by Sales_Order__r.Name, Line__c, Required_Date__c, Name ASC';

		SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
		soql.addFields('Fulfillment_RO');
		soql.addFields(solFields);
		soql.setWhereClause(whereClause);
		
		SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
		skids.addFields(skidFields);
		skids.setWhereClause('Type__c = \'SO Demand\'');
		soql.addChildRelationship(skids);

		SOQLUtil.ChildRelationship shLines = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
		shLines.addFields(new Set<String>{'Id', 'Quantity_Shipped__c', 'Facility__c', 'Location__c', 'Quantity_Allocated__c', 'Shipment__r.Currency__c', 'Shipment__r.Currency__r.ISO_Code__c'});
		shLines.setWhereClause('Shipment__r.Status__c != \'Confirmed\' AND Shipment__r.Status__c != \'Delivered\'');
		soql.addChildRelationship(shLines);

		return (list<Sales_Order_Line__c>)Database.query(soql.getQuery()); 
		/*
		return (list<Sales_Order_Line__c>)Database.query( util.generateQueryFromFieldSet( 'Sales_Order_Line__c', new set<string>{'Fulfillment_RO'},
					fieldStrings,
					 ' Sales_Order__c IN :soIdList'+
					 ' and Quantity_Backordered__c > 0.0'+
					 ' and Sales_Order__r.Status__c = :SO_STATUS_OPEN '+
					 ' and Status__c = :SO_STATUS_OPEN ' +
					 ' and Product__r.Item__r.Non_Inventory__c = false'+
					 ' and Product__r.Item__r.Source__c !=:mtoItemSource'+
					 ' and Has_Exceptions__c = false'+
					 ' and Fulfillment_Source__c != \'Drop Ship\''+
					 ' order by Sales_Order__r.Name, Line__c, Required_Date__c, Name ASC' ) );
		*/
  }
  
	// KNDY 2132 - Allocation rules
	public static Boolean AllocationRuleValidationRunning = false;
	static final List<String> SOStatusValsForAllocation = new List<String>{ SO_STATUS_DRAFT, SO_STATUS_CLOSED };

	//@future
   /* public static void validateForAllocationRules(Set<Id> salesOrderIds) {
	  if (salesOrderIds == null || salesOrderIds.isEmpty()){
		  return;
		}

		AllocationRuleValidationRunning = true;
		Date smallestDate, biggestDate;

		// TO-DO: possible to optimize using a map and pass map to populateUsedAllocation to prevent SOL requery.
		Sales_Order_Line__c[] sols = [Select Allocation_Rule__c, From_Facility_Id__c, Product__c, Allocation_Rule__r.Allocation_Used__c,
					  Estimated_Ship_Date__c, Sales_Order__c, Status__c, Sales_Order__r.Customer__c
						FROM Sales_Order_Line__c
									WHERE Sales_Order__c IN :salesOrderIds
										AND Status__c IN :SOStatusValsForAllocation
										AND Estimated_Ship_Date__c != null];

		if (sols == null || sols.isEmpty())
		  return;

		system.debug(sols);
		Set<Id> productIds = new Set<Id>();
		Set<Id> allocationRuleIds = new Set<Id>();

		for (Sales_Order_Line__c sol : sols) {
			if (smallestDate == null || smallestDate < sol.Estimated_Ship_Date__c)
			  smallestDate = sol.Estimated_Ship_Date__c;
			if (biggestDate == null || biggestDate > sol.Estimated_Ship_Date__c)
			  biggestDate = sol.Estimated_Ship_Date__c;

			if (sol.Product__c != null)
			  productIds.add(sol.Product__c);
			if (sol.Allocation_Rule__c != null)
			  allocationRuleIds.add(sol.Allocation_Rule__c);
		}

		Map<Id, Allocation_Rule__c> allocRulesById = new Map<Id, Allocation_Rule__c>(
						[SELECT Id, Name, Start_Date__c,
												Product__c, Allocation_Used__c, End_Date__c,
												Company__c, Customer__c, Facility__c, Allocation__c
										   FROM Allocation_Rule__c
										  WHERE Active__c = true and (Id IN :allocationRuleIds //OTC-25
											 OR (
											  (
													(Start_Date__c <= :smallestDate AND End_Date__c  >=: smallestDate) // floating around smallest date
									  OR
										(Start_Date__c >= :smallestDate AND Start_Date__c  <=: biggestDate) // floating between smallest and biggest date
									  OR
										(Start_Date__c <= :biggestDate AND End_Date__c  >=: biggestDate) // floating around biggest date
									  )
												AND Product__c IN :productIds
											  ))

										]);

		if (allocRulesById.isEmpty()) {
			//System.debug(LoggingLevel.WARN, '### No allocation rules found for critera >   productIds :' + productIds + ' smallestDate :' + smallestDate + ' biggestDate:' + biggestDate);
			return;
		}

		List<Allocation_Rule__c> allocRulesClone = new List<Allocation_Rule__c>();
		for (Allocation_Rule__c ar : allocRulesById.values()) {
			allocRulesClone.add(ar.clone(true));
		}
		AllocationRuleService.populateUsedAllocation(allocRulesClone, salesOrderIds);

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


	}*/

	public static void validateAllowancesApplied() {
		if (trigger.isAfter && trigger.isUpdate) {
			List<Id> soForAllowanceValidation = new List<Id>();
			for (Sales_Order__c obj : (List<Sales_Order__c>) trigger.new) {
				if (( KSE.isFieldChanging('Pricing_Date__c', obj, trigger.oldMap)
					|| KSE.isFieldChanging('Price_Determination_Date__c', obj, trigger.oldMap))
				){
					soForAllowanceValidation.add(obj.id);
				}
			}
			if (!soForAllowanceValidation.isEmpty()) {
				SalesOrderService.validateAllowancesApplied(soForAllowanceValidation, null);
			}
		}
	}

	// can be Sales Order or SOL Ids
	public static void validateAllowancesApplied(List<Id> objectIds, Map<Id, Decimal> solFulQtyMap) {

        AllowanceService.validateAllowancesApplied ( objectIds, solFulQtyMap);
        }

        

   /************************ SALES ORDER DETAILS METHODS *****************************/

	public static void populateData(){
	  if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
	  populateData(trigger.new);
	}
	}

	public static void populateData(List<Sales_Order__c> salesOrders){
	  // set the company if empty and the company_identifier is not empty
	  CompanyService.setDefaultCompany(salesOrders, true);

	  // match up the customer if we are given the customer identifier
	  CompanyService.setLookupUsingField(salesOrders, true, 'Customer__c', 'Customer__c', 'Customer_Identifier__c'  );
	}

	// when a new sales order is created, copy the ship to address from the Customer into the Sales order
  public static void copyCustomerAddress(){
	  if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();

		for(Sales_Order__c salesOrder : (List<Sales_Order__c>) trigger.new){
		  if( trigger.isInsert ||
			( trigger.isUpdate &&
			  (KSE.isFieldChanging('Customer__c', salesOrder, trigger.oldMap) ||
			 KSE.isFieldChanging('Ship_to__c', salesOrder, trigger.oldMap) ||
				 KSE.isFieldChanging('Bill_to__c', salesOrder, trigger.oldMap) )
				)
			  ){
				salesOrders.add( salesOrder );
			}
		}
		copyCustomerAddress(salesOrders);
	  }
	}

	public static void copyCustomerAddress(List<Sales_Order__c> salesOrders){
	Set<id> customerSet = new Set<Id>();

	  for( Sales_Order__c salesOrder : salesOrders) {
		if(String.isBlank(salesOrder.Bill_to__c) == false){
		  customerSet.add( salesOrder.Bill_to__c );
		}

		if(String.isBlank(salesOrder.Ship_to__c) == false){
		  customerSet.add( salesOrder.Ship_to__c );
			}

		if(String.isBlank(salesOrder.Customer__c) == false){
		  customerSet.add( salesOrder.Customer__c );
			}
		}

	  if ( customerSet.size() > 0 ) {
		Map<id, Customer__c> customerMap = getCustomersMap(customerSet);
		Set<Id> companyIds = KSE.grepRelatedIdSetFromList(salesOrders, 'Company__c', true);

		SOQLUtil soql = new SOQLUtil('Company__c', true, true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id', 'Default_Sales_Order_Ship_From_Facility__r.Default_Sales_Order_Ship_From_Location__c' 
		});
		soql.setWhereClause('Id IN :companyIds');
		
		Map<Id, Company__c> companyMap = new Map<Id, Company__c>((List<Company__c>)Database.query(soql.getQuery()));         

		for( Sales_Order__c salesOrder: salesOrders) {
			Customer__c soldTo = customerMap.get(salesOrder.Customer__c);
			  if ( soldTo != null ) {
				salesOrder.Street__c = soldTo.Street__c != null ? soldTo.Street__c.replace('<br>', '\n').unescapeHTML4() : soldTo.Street__c;
				salesOrder.City__c = soldTo.City__c;
				salesOrder.State__c = soldTo.State__c;
				salesOrder.Zip_Code__c = soldTo.Zip_Code__c;
				salesOrder.Country__c = soldTo.Country__c;
			  }

			Customer__c shipTo = customerMap.get(salesOrder.Ship_to__c);
			  if ( shipTo != null ) {
				  salesOrder.Ship_to_Street__c = shipTo.Street__c != null ? shipTo.Street__c.replace('<br>', '\n').unescapeHTML4() : shipTo.Street__c;
				  salesOrder.Ship_to_City__c = shipTo.City__c;
				  salesOrder.Ship_to_State__c = shipTo.State__c;
				  salesOrder.Ship_to_Zip_Code__c = shipTo.Zip_Code__c;
				  salesOrder.Ship_to_Country__c = shipTo.Country__c;

				  // OTC-572 - use user specified ship from location if provided. Else, use the customer ship to specified ship from location, else company default SFL
				  if (salesOrder.Ship_From_Location__c == null){
					if(shipTo.Ship_From_Location__c != null ){
						salesOrder.Ship_From_Location__c = shipTo.Ship_From_Location__c;
					} else {
						salesOrder.Ship_From_Location__c = companyMap.get(salesOrder.Company__c).Default_Sales_Order_Ship_From_Facility__r.Default_Sales_Order_Ship_From_Location__c;
					}
				  }
			  }

				Customer__c billTo = customerMap.get(salesOrder.Bill_to__c);
				if ( billTo != null ) {
					salesOrder.Bill_to_Street__c = billTo.Street__c != null ? billTo.Street__c.replace('<br>', '\n').unescapeHTML4() : billTo.Street__c;
					salesOrder.Bill_to_City__c = billTo.City__c;
					salesOrder.Bill_to_State__c = billTo.State__c;
					salesOrder.Bill_to_Zip_Code__c = billTo.Zip_Code__c;
					salesOrder.Bill_to_Country__c = billTo.Country__c;
				}
		}
	}
  }
  
  public static void setPaymentTerms(){
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
	  setPaymentTerms(trigger.new);
	}
  }
  
  public static void setPaymentTerms(List<Sales_Order__c> salesOrders){
	Set<Id> idSet = new Set<Id>();

		for( Sales_Order__c salesOrder: salesOrders) {
			if ( salesOrder.Payment_Term__c == null && salesOrder.Customer__c != null ) {
				idSet.add( salesOrder.Customer__c );
			}
		}

		if ( idSet.size() > 0 ) {
		Map<Id,Customer__c> myMap = getCustomersMap(idSet);

		  for( Sales_Order__c salesOrder : salesOrders) {
			  if ( salesOrder.Payment_Term__c == null &&  salesOrder.Customer__c != null && myMap.containsKey( salesOrder.Customer__c) ) {
				// KNDY-2138 : Throw an error if payment terms are not found
				if (myMap.get( salesOrder.Customer__c ).Parent_Customer__r.Payment_Term__c == null){
				  //salesOrder.Payment_Term__c.addError(Label.Bill_to_customer_record_does_not_have_any_payment_terms_specified);
				  continue;
				}else{
				  // KNDY-1149 : Pulling payment terms from Bill-to customer who is the parent of a Sold-to customer
				  salesOrder.Payment_Term__c = myMap.get( salesOrder.Customer__c ).Parent_Customer__r.Payment_Term__c;
				}
			  }
		  }
		}
  }
  
	// KNDY-1114: Always create sales order in 'Draft' status
	// OTC-175 ( almost always)
	public static void setStatus(){
		if(trigger.isBefore && trigger.isInsert){
			for( Sales_Order__c salesOrder : (List<Sales_Order__c>) trigger.new) {
				if ( salesOrder.Status__c != SO_STATUS_CLOSED ) { // OTC-175 allow historical data loads
					salesOrder.Status__c = SalesOrderService.SO_STATUS_DRAFT;
				}
			}
		}
	}

	public static void setMeansOfTransport(){
	if(trigger.isAfter && trigger.isUpdate){
		List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
		for(Sales_Order__c salesOrder : (List<Sales_Order__c>) trigger.new){
			if( KSE.isFieldChanging('Ship_To__c', salesOrder, trigger.oldMap) ||
			  KSE.isFieldChanging('Means_Of_Transport__c', salesOrder, trigger.oldMap) ){
			  salesOrders.add(salesOrder);
			}
		}
		setMeansOfTransport(salesOrders);
	}
	}

	public static void setMeansOfTransport(List<Sales_Order__c> salesOrders){
		// After Update
	  Set<Id> salesOrderIdsWithoutMoT = new Set<Id>();

	  // Populate the means of transport.
	  for(Sales_Order__c salesOrder : salesOrders){
		salesOrderIdsWithoutMoT.add(salesOrder.Id);
	  }

	  if(salesOrderIdsWithoutMoT.size() > 0){
		SalesOrderLineService.setMeansOfTransport(salesOrderIdsWithoutMoT);
	  }
	}

	public static void setEstimatedShipDate(){
//		System.debug(loggingLevel.Error, ' KNDY-17667 ***** SalesOrderService.setEstimatedShipDate :');
//		System.debug(loggingLevel.Error, ' KNDY-17667 ***** SalesOrderLineService.isExecuting :' + SalesOrderLineService.isExecuting);
		if (trigger.isAfter && trigger.isUpdate){
			set<Id> salesOrders = new set<Id>();
			for(Sales_Order__c salesOrder : (List<Sales_Order__c>) trigger.new){
				if( KSE.isFieldChanging('Means_Of_Transport__c', salesOrder, trigger.oldMap)||
				  KSE.isFieldChanging('Ship_To__c', salesOrder, trigger.oldMap)){
					salesOrders.add(salesOrder.id);
				}
			}

//			system.debug(LoggingLevel.Error, 'KNDY-17667 ***** Est date salesOrders: ' + salesOrders);
			if ( SalesOrderLineService.isExecuting == false && salesOrders.size() > 0)
			  SalesOrderLineService.setEstimatedShipDate(salesOrders);
		}
	}



	//KNDY-3220 : Refire SO Quantity validations when customer changes
  public static void updateSalesOrderLineForQuantityFactorValidations(){
	if(trigger.isAfter && trigger.isUpdate){
	  List<Sales_Order__c> salesOrdersForQuantityValidation = new List<Sales_Order__c>();

		for (Sales_Order__c newSO : (List<Sales_Order__c>) trigger.new) {
			// Recalculations will only happen on SO's in draft stage
			if ( KSE.isFieldChanging('Customer__c', newSO, trigger.oldMap) ) {
				salesOrdersForQuantityValidation.add(newSO);
			}
		}

	  updateSalesOrderLineForQuantityFactorValidations(salesOrdersForQuantityValidation);
	}
  } 

	public static void updateSalesOrderLineForQuantityFactorValidations(List<Sales_Order__c> salesOrders){

	  Set<Id> validateQtyInLinesForSOIds = new Set<Id>();

	  for(Sales_Order__c salesOrder : salesOrders){
		if( salesOrder.Status__c == 'Draft' ){
		validateQtyInLinesForSOIds.add(salesOrder.Id);
		}
	  }

	  if (!validateQtyInLinesForSOIds.isEmpty()) {
		  SalesOrderLineService.updateSalesOrderLineForQuantityFactorValidationsForSalesOrderIds(validateQtyInLinesForSOIds);
	  }
	}



	// KNDY-1489: Close / Cancel all the sales order lines if the sales order is closed / cancelled
  public static void closeSalesOrderLines(){
	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
	  List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();

	  for(Sales_Order__c salesOrder : (List<Sales_Order__c>) trigger.new){
		if(salesOrder.Status__c == SO_STATUS_CLOSED || salesOrder.Status__c == SO_STATUS_CANCEL ){
		  if(trigger.isInsert ||
			(trigger.isUpdate && ( KSE.isFieldChanging('Status__c', salesOrder, trigger.oldMap) ))
		  ){
			salesOrders.add(salesOrder);
		  }
		}
	  }

	  SalesOrderService.closeSalesOrderLines(salesOrders);
	}
  }
  
  public static void closeSalesOrderLines(List<Sales_Order__c> closedSalesOrders){
	System.Savepoint sp = Database.setSavepoint();

	try{
	  List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();
	  List<SKID__c> soDemandSkids = new List<SKID__c>();

	  if(closedSalesOrders.size() > 0){
		for(Sales_Order_Line__c sol : [SELECT Id, Name, Quantity_Allocated__c, Quantity_Backordered__c,
							Sales_Order__c, Sales_Order__r.Status__c, Status__c,
							(SELECT Id
							   FROM SKIDs__r
							  WHERE Type__c = :SKIDService.SKID_TYPE_SO_DEMAND)
						 FROM Sales_Order_Line__c
						WHERE Sales_Order__c IN :closedSalesOrders and Status__c Not IN (:SalesOrderService.SO_STATUS_CANCEL, :SalesOrderService.SO_STATUS_CLOSED)
						]){

		  if(sol.Quantity_Allocated__c > 0.0){
			trigger.newMap.get(sol.Sales_Order__c).addError(sol.Name + ': '+ Label.Cannot_close_sales_order_line_with_quantity_allocated);
			continue;
		  }

		  sol.Status__c = sol.Sales_Order__r.Status__c;
		  solList.add(sol);
		  soDemandSkids.addAll(sol.SKIDs__r);
		}

		//KNDY-1753
		DML.updateAsUser(solList);

		DML.deleteAsSystem(soDemandSkids);
	  }
	}catch(Exception e){
	  Database.rollback(sp);
	  throw e;
	}
  }
  
	/************************ PRICING RELATED METHODS *****************************/

	public static void setPricebook(){
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
	  setPricebook(trigger.new);
	}
  }
  
  public static void setPricebook(List<Sales_Order__c> salesOrders){
	Set<Id> idSet = new Set<Id>();

		Boolean useDefaultPB = false;

		for( Sales_Order__c salesOrder : salesOrders) {
			if ( salesOrder.Pricebook__c == null && salesOrder.Customer__c != null ) {
				idSet.add( salesOrder.Customer__c );
			} else if (salesOrder.Pricebook__c == null && !useDefaultPB && salesOrder.Customer__c == null){
				useDefaultPB = true;
			}
		}

		if ( idSet.size() > 0 ) {
		  Map<Id,Customer__c>myMap = getCustomersMap(idSet);

			for( Sales_Order__c salesOrder: salesOrders) {
				if ( salesOrder.Pricebook__c == null && salesOrder.Customer__c != null && myMap.containsKey( salesOrder.Customer__c) ) {
					salesOrder.Pricebook__c = myMap.get( salesOrder.Customer__c ).Pricebook__c;
				}
			}
		}
		if (useDefaultPB){
			Set<Id> companyIds = new Set<Id>();
			Set<Id> transCurrency = new Set<Id>();
			for( Sales_Order__c salesOrder: salesOrders) {
				if ( salesOrder.Pricebook__c == null && salesOrder.Customer__c == null ) {
					companyIds.add(salesOrder.Company__c);
					transCurrency.add(salesOrder.Currency__c);
				}
			}

			Map<String, Pricebook__c> pbMap = new Map<String, Pricebook__c>();

			for (Pricebook__c pb : [ select id, Default__c, Name, Currency__c, Company__c
									from Pricebook__c
									where Company__c IN :companyIds and Currency__c IN :transCurrency
										and Default__c = true]){
				pbMap.put(pb.Company__c + '-' + pb.Currency__c, pb);
			}

			for (Sales_order__c so : salesOrders){
				if ( so.Pricebook__c == null && so.Customer__c == null ) {
					if (pbMap.containsKey(so.Company__c + '-' + so.Currency__c)){
						so.Pricebook__c = pbMap.get(so.Company__c + '-' + so.Currency__c).Id;
					}
				}
			}

		}
  }

	public static void validateSalesOrderPrices(){
	  if(trigger.isAfter && trigger.isUpdate){
		Set<Id> updatePriceFldsOnLinesOfOrderIds = new Set<Id>();
	  for (Sales_Order__c salesOrder : (List<Sales_Order__c>) trigger.new) {
		  //KNDY-19710 - Commenting the below logic and adding it as part of a validation rule
		/*if(salesOrder.Subtotal__c < 0 && SalesOrderService.SALES_ADJUSTMENT_ORDER_TYPES.contains(salesOrder.Type__c) == false && SO_RMA_REPLACEMENT_TYPES.contains(salesOrder.Type__c) == false){
		  salesOrder.addError('You cannot have a negative total from all the lines on a standard Sales Order.');
		  continue;
		}*/

		if  ( ! salesOrder.Type__c.contains('Price Adjustment') &&
		   KSE.isFieldChanging('Bracket_Price_Field_In_Use__c', salesOrder, trigger.oldMap) ||
		   KSE.isFieldChanging('Pricing_Date__c', salesOrder, Trigger.oldMap)) {
		  updatePriceFldsOnLinesOfOrderIds.add(salesOrder.Id);
		}
	  }
	  validateSalesOrderPrices(updatePriceFldsOnLinesOfOrderIds);
	  }
	}

	public static void validateSalesOrderPrices(Set<Id> updatePriceFldsOnLinesOfOrderIds){
	if (!updatePriceFldsOnLinesOfOrderIds.isEmpty()) {
			// Disable trigger for madly firing again and again
			SalesOrderLineService.IgnoreSalesOrderLineUpdate = true;
			SalesOrderFlowCache.flush();  //OTC-463
			DML.updateAsUser(SalesOrderLineService.ValidateSalesOrderPrices(updatePriceFldsOnLinesOfOrderIds));
			// restore trigger back
			SalesOrderLineService.IgnoreSalesOrderLineUpdate = false;
	  }
	}

	// KNDY-2125 : Update Price field if total weight changes on a sales order
	public static void findAndUpdateBracketPriceField(){

	  if (trigger.isBefore && trigger.isUpdate) {
		Set<Id> soIdsToUpdate = new Set<Id>();
		List<Sales_Order__c> sosToUpdate = new List<Sales_Order__c>();

		for (Sales_Order__c salesOrder : (List<Sales_Order__c>) trigger.new) {
		  if (KSE.isFieldChanging('Pricing_Bracket__c', salesOrder, trigger.oldMap)
			  || KSE.isFieldChanging('Total_Product_Weight__c', salesOrder, trigger.oldMap)) {
			sosToUpdate.add(salesOrder);
		  }
		}

		List<Sales_Order__c> soForPriceFieldUpdate = new List<Sales_Order__c>();
		if (!sosToUpdate.isEmpty()){
		  Set<Id> soIdsWithCIs = new Set<Id>();
		  Set<Id> closedSOIds = new Set<Id>();

		  for(Sales_Order__c so : sosToUpdate){
			  if(so.Status__c == SO_STATUS_CLOSED){
				  closedSOIds.add(so.Id);
			  }
		  }

		  if(closedSOIds.isEmpty() == false){
			for (Customer_Invoice__c CI : [SELECT Id, Sales_Order__c FROM Customer_Invoice__c where Status__c not in ('Void', 'Cancelled') and Sales_Order__c IN :closedSOIds]) { //OTC-680 should not pick up void cancelled CIs
			  soIdsWithCIs.add(CI.Sales_Order__c);
			}
		  }

		  for (Sales_Order__c salesOrder : sosToUpdate) {
			if (soIdsWithCIs.contains(salesOrder.Id) && salesOrder.Status__c == SO_STATUS_CLOSED && KSE.isFieldChanging('Pricing_Bracket__c', salesOrder, trigger.oldMap)){
			  salesOrder.Pricing_Bracket__c.addError(Label.An_Invoice_has_already_been_generated_for_this_Sales_Order); // OTC-699
			} else if(String.isBlank(salesOrder.Pricing_Bracket__c)){
			  soForPriceFieldUpdate.add(salesOrder);  // Figure out the bracket price from the weight of the sales order.
			} else if (salesOrder.Pricing_Bracket__c.equalsIgnoreCase('Base Price')) {
			  salesOrder.Bracket_Price_Field_In_Use__c = 'Price__c';
			} else if( salesOrder.Pricing_Bracket__c.equalsIgnoreCase('Bracket 2')) {
			  salesOrder.Bracket_Price_Field_In_Use__c = 'Price_2__c';
			} else if (salesOrder.Pricing_Bracket__c.equalsIgnoreCase('Bracket 3')) {
			  salesOrder.Bracket_Price_Field_In_Use__c = 'Price_3__c';
			} else if (salesOrder.Pricing_Bracket__c.equalsIgnoreCase('Bracket 4')) {
			  salesOrder.Bracket_Price_Field_In_Use__c = 'Price_4__c';
			} else if (salesOrder.Pricing_Bracket__c.equalsIgnoreCase('Bracket 5')) {
			  salesOrder.Bracket_Price_Field_In_Use__c = 'Price_5__c';
			} else {
			  salesOrder.Pricing_Bracket__c.addError(Label.Invalid_pricing_bracket_value);
			}
		  }
		}

		if (!soForPriceFieldUpdate.isEmpty()) {
		  SalesOrderService.findAndUpdateBracketPriceField(soForPriceFieldUpdate);
		}
	  }

	}

	// KNDY-2125
	public static void findAndUpdateBracketPriceField(Sales_Order__c[] sos) {
		Set<Id> companyIds = Kse.grepRelatedIdSetFromList(sos, 'Company__c', true);
		Map<Id, BracketPricingService.BracketPriceRange[]> bracketPricesByCompanyId = SalesOrderFlowCache.cachedBracketPriceRanges(companyIds);

		Set<Id> custIds = KSE.grepRelatedIdSetFromList(sos, 'Customer__c');
		Map<Id, Customer__c> custMap = new Map<Id, Customer__c>(SalesOrderFlowCache.cachedCustomersForIds(custIds));

		if (bracketPricesByCompanyId == null || bracketPricesByCompanyId.isEmpty()) {
			// no  brackets configured, so show ends here only
			for (Sales_Order__c so : sos) {
				// clear the price field in case its previously filled
				so.Bracket_Price_Field_In_Use__c = null;
			}
			return;
		}

		for (Sales_Order__c so : sos) {
			BracketPricingService.BracketPriceRange[] bracketPrices = bracketPricesByCompanyId.get(so.Company__c);
 
			if (bracketPrices == null || bracketPrices.isEmpty() || (custMap.containsKey(so.Customer__c) && custMap.get(so.Customer__c).Use_Fixed_Pricing__c))  {
				so.Bracket_Price_Field_In_Use__c = null;
				continue;
			}

			String oldBracketPriceFld = so.Bracket_Price_Field_In_Use__c;

			// Find pricefield from brackets
			for (BracketPricingService.BracketPriceRange bp: bracketPrices) {
				if (so.Total_Product_Weight__c >= bp.volumeRangeBottom && so.Total_Product_Weight__c <= bp.volumeRangeHigh) {
					so.Bracket_Price_Field_In_Use__c = bp.pricebookLineField;
					break;
				}
			}
		}
	}

	public static Map<Id, Customer__c> getCustomersMap(Set<Id> customerIds){
	  Set<Id> customersToQueryFor = new Set<Id>();

	  for(Id customerId : customerIds){
		if(customersMap.containsKey(customerId) == false){
		  customersToQueryFor.add(customerId);
		}
	  }

	  if(customersToQueryFor.size() > 0){
		for(Customer__c customer : [SELECT Id, Ship_From_Location__c, Parent_Customer__r.Payment_Term__c,
						 Parent_Customer__r.Payment_Term__r.Name, Pricebook__c,
							 Company__r.Default_Sales_Order_Ship_From_Facility__r.Default_Sales_Order_Ship_From_Location__c,
											 Street__c, City__c, State__c, Zip_Code__c, Country__c
										  FROM Customer__c
										 WHERE Id IN :customersToQueryFor]){
		  customersMap.put(customer.Id, customer);
		}
	  }

	  return customersMap;
	}

	/************************* INVOICE GENERATION ***************************/

	public static void generateCustomerInvoices(List<Sales_Order__c> salesOrders){
	  Set<Id> salesOrderIds = new Set<Id>();
	  for(Sales_Order__c salesOrder : salesOrders){
		if(salesOrder.Id != null){
		  salesOrderIds.add(salesOrder.Id);
		}
	  }
	  generateCustomerInvoices(salesOrderIds);
	}

	public static void generateCustomerInvoices(Set<Id> salesOrderIds){

		List<Customer_Invoice__c> custInvoiceUpsertList = new List<Customer_Invoice__c>();
		List<Customer_Invoice_Line__c> invoiceLineList = new List<Customer_Invoice_Line__c>();
		List<Sales_Order_Line__c> solUpdatedList = new List<Sales_Order_Line__c>();

		Map<Id, Customer_Invoice__c> salesOrderInvoiceMap = new Map<Id, Customer_Invoice__c>();

		List<Sales_Order__c> salesOrders =
	  [SELECT Id, Name, Customer__c, Company__c, Status__c, Customer__r.Parent_Customer__c, Ship_To__r.Customer_Group__c,
		  Customer__r.Parent_Customer__r.Parent_Customer__c, Customer__r.Top_Parent_Customer__c,
		  Customer__r.Customer_Group__c, Customer__r.Top_Parent_Customer__r.Customer_Group__c,
		  Pricing_Date__c, Payment_Term__c, Currency__c, Type__c,
		  Total_Quantity_Shipped__c, Total_Product_Weight__c, Total_Quantity_Ordered__c, Has_Exceptions__c,
		  (SELECT Id, Name, Quantity_Ordered__c, Product__r.Item__c,Product__r.Item__r.Description__c,
				Sales_Order__c, Company__c, Product__c,Description__c, Quantity_Shipped__c,
						Product_Weight__c, Product__r.Sales_hierarchy__c,
						Product__r.Sales_hierarchy__r.Path__c, Product__r.Sales_hierarchy__r.Code__c,
						Unit_Price__c, Line_Type__c, Discount_Percent__c,
						Quantity_From_Stock__c, Extended_Price__c, Allowances__c, Freight_Allowance__c,
						Off_Invoice_Rate__c, BillBack_Rate__c, List_Price__c, Expected_Price__c
		   FROM Sales_Order_Lines__r
		  WHERE Status__c = :SO_STATUS_DRAFT
			AND Has_Exceptions__c = false)
	   FROM Sales_Order__c
	  WHERE Id IN :salesOrderIds];

		for(Sales_Order__c salesOrder : salesOrders){
			if(salesOrder.Sales_Order_Lines__r.size() > 0){
		  for(Sales_Order_Line__c sol : salesOrder.Sales_Order_Lines__r){

			  // Create Invoice Header and add to insert list
			  Customer_Invoice__c invHeader = new Customer_Invoice__c();
					invHeader = new Customer_Invoice__c();
				  invHeader.Bill_to_Customer__c = salesOrder.Customer__r.Parent_Customer__c;
				  invHeader.Company__c = salesOrder.Company__c;
				  invHeader.Customer__c = salesOrder.Customer__r.Top_Parent_Customer__c;
					invHeader.Date_Invoiced__c = system.now();
					invHeader.transaction_date__c = system.now();
					invHeader.Invoice_Type__c = salesOrder.Type__c;
					invHeader.Sold_to_Customer__c = salesOrder.Customer__c;
				  invHeader.Status__c = 'Open';
		  invHeader.Currency__c = salesOrder.Currency__c;

				  salesOrderInvoiceMap.put(salesOrder.id, invHeader);

		  }
			}
		}

		Savepoint sp = Database.setSavepoint();

		try{
			DML.insertAsUser(salesOrderInvoiceMap.values());

			Set<Id> soldToOrShipToCustomerIds = new Set<Id>();
			Set<Id> topParentCustomerIds = new Set<Id>();
			Set<Id> customerGroupIds = new Set<Id>();

			// Keeping all shiplines by Id, for easy retrieval during allowance generation
		  Map<Id, Shipment_Line__c> shipLinesById = new Map<Id, Shipment_Line__c>();
			// K: Invoice Id V: Invoice lines for the header
		  Map<Id, Customer_Invoice_Line__c[]> invoiceLinesByHeader = new Map<Id, Customer_Invoice_Line__c[]>();
		  // K: Id so id V: Sales Order
		  Map<Id, Sales_Order__c> soById = new Map<Id, Sales_Order__c>();

			Map<Id, Sales_Order_line__c> solById = new Map<Id, Sales_Order_Line__c>();

			for(Sales_Order__c salesOrder : salesOrders){
				if(salesOrderInvoiceMap.containsKey(salesOrder.id)){
					Customer_Invoice__c invHeader = salesOrderInvoiceMap.get(salesOrder.id);

				  if( invHeader != null ){
					  for(Sales_Order_Line__c sol : salesOrder.Sales_Order_Lines__r){
						Customer_Invoice_Line__c invoiceLine = new Customer_Invoice_Line__c();
						invoiceLine.BillBack_Rate__c = sol.BillBack_Rate__c;
						  invoiceLine.Company__c = sol.Company__c;
						  invoiceLine.Customer_Invoice__c = invHeader.id;
			  invoiceLine.Description__c = sol.Description__c;
						  invoiceLine.Discount_Percent__c = sol.Discount_Percent__c;
						  invoiceLine.Extended_Price__c = sol.Extended_Price__c;
						  invoiceLine.Line_Type__c = sol.Line_Type__c;
						  invoiceLine.Off_Invoice_Rate__c = sol.Off_Invoice_Rate__c;
						  invoiceLine.Product__c = sol.Product__c;
			  invoiceLine.Quantity_From_Stock__c = sol.Quantity_From_Stock__c;
						  invoiceLine.Quantity_Shipped__c = sol.Quantity_Ordered__c;
						  invoiceLine.Sales_Order__c = sol.Sales_Order__c;
			  invoiceLine.Sales_Order_Line__c = sol.Id;
						  invoiceLine.Unit_Price__c = sol.Unit_Price__c;

						  invoiceLineList.add(invoiceLine);

			  invHeader.Sales_Order__c = salesOrder.Id;
			  invHeader.Payment_Term__c = salesOrder.Payment_Term__c; //OTC-461
							invHeader.Finalized__c = true;

							// Collect invoice lines by invoice header
							if (!invoiceLinesByHeader.containsKey(invHeader.Id))
							  invoiceLinesByHeader.put(invHeader.Id, new Customer_Invoice_Line__c[]{});

							invoiceLinesByHeader.get(invHeader.Id).add(invoiceLine);

							sol.Quantity_Shipped__c = sol.Quantity_Ordered__c;
							sol.Status__c = SO_STATUS_CLOSED;
							solUpdatedList.add(sol);

							// Keep sales order handy for later retrieval by id
							soById.put(sol.Sales_Order__c, salesOrder);
							solById.put(sol.Id, sol);
							soldToOrShipToCustomerIds.add(salesOrder.Ship_To__c);
			  soldToOrShipToCustomerIds.add(salesOrder.Customer__c);
							topParentCustomerIds.add(salesOrder.Customer__r.Top_Parent_Customer__c);
							customerGroupIds.add(salesOrder.Customer__r.Customer_Group__c);
							customerGroupIds.add(salesOrder.Ship_To__r.Customer_Group__c);
							customerGroupIds.add(salesOrder.Customer__r.Top_Parent_Customer__r.Customer_Group__c);

			}
					  custInvoiceUpsertList.add(invHeader);
				  }
				}
			}

			DML.insertAsUser(invoiceLineList);


			Set<Id> cilIdSet = KSE.grepIdSetFromList(invoiceLineList);

            // copy over from the sales order lines , any allowances we find so that they appear on the
            // customer invoice lines & header
            AllowanceService.copyAllowancesFromOrderToInvoice(cilIdSet, soById.keySet(), null, null);


			DML.updateAsUser(custInvoiceUpsertList);
			DML.updateAsUser(solUpdatedList);

		} catch(Exception ex){
		  system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
		Database.rollback(sp);
	  }
	}

	//KNDY 3108 Sales Order Allocation
	public void planAllocate(List<Sales_Order__c> salesOrders){
	  Set<Id> salesOrderIds = new Set<Id>();
	  try{
		   for(Sales_Order__c salesOrder : salesOrders){

		if(salesOrder.Id != null){
		  salesOrderIds.add(salesOrder.Id);
		  plan(salesOrder.Id);

		  //Allocate
		  ApexPages.Standardcontroller con = new ApexPages.Standardcontroller(salesOrder);
		  SalesOrderAllocateExt SOAExt = new SalesOrderAllocateExt(con);

		  for( SalesOrderAllocateExt.solWrapper sw : SOAExt.solWrapperList ){
			  sw.skidList[0].Quantity_Allocated__c  = sw.sol.Quantity_Ordered__c;
		  }
		  SOAExt.allocate();
		}

		 }

	  }catch(Exception e) {
			// normal flow
		}
	}

	//OTC-346 Point 3
	public static void updateAllocationRule()
	{
	  set<ID> SO_IDs = new set<ID>();
	  if(trigger.isAfter && trigger.isUpdate)
	  {
		for(Sales_Order__c SO : (list<Sales_Order__c>)trigger.new)
		{
		  if(KSE.isFieldChanging('Customer__c', SO, trigger.oldMap))
			SO_IDs.add(SO.Id);
		}

		if(!SO_IDs.isEmpty())
		{
		  list<Sales_Order_Line__c> solLines = [Select id, Estimated_Ship_Date__c, Product__c, Corporate_parent_Customer_ID__c, From_Facility_ID__c,Allocation_Rule__c from Sales_Order_Line__c where Sales_Order__c in :SO_IDs ];
		  SalesOrderLineService.validateAllocationRule(solLines, trigger.isDelete);
		}
	  }
	}
	public static void preventChangeOnPaymentTerms()
	{
	  set<id> soIds = new set<id>();
	  if(trigger.isBefore && trigger.IsUpdate)
	  {
		for(Sales_Order__c SO : (list<Sales_Order__c>)trigger.new)
		  if(KSE.isFieldChanging('Payment_Term__c',SO,trigger.oldmap))
			soIds.add(SO.ID);
	  }
	  system.debug('SO Ids: '+soIds);
	  if(!soIds.isEmpty())
	  {
		set<Id> SO_withCIs = new set<Id>();
		for(Customer_Invoice__c ci : [Select Id, Sales_Order__c from Customer_Invoice__c where Status__c!= 'Void' and Status__c!='Cancelled' and Sales_Order__c in :soIds])
		  SO_withCIs.add(ci.Sales_Order__c);
		system.debug('map SO_withCIs: '+SO_withCIs);
		if(!SO_withCIs.isEmpty())
		{
		  for(Sales_Order__c SO : (list<Sales_Order__c>)trigger.new)
			if(SO_withCIs.contains(SO.Id))
			  SO.addError(SO.Name+Label.CannotChangePaymentTermOnSO);
		}

	  }
	}

	//OTC-715
	public static void changeStatus()
	{
	  system.debug('Inside SO Service change status');
	  set<String> statusTypes = new set<String>{'Draft','Open'};
	  if(trigger.isBefore && trigger.isUpdate)
	  {
		for(Sales_Order__c SO : (list<Sales_Order__c>)trigger.new)
		{
		  system.debug('Inside SO Service, type: '+SO.Type__c);
			system.debug('Inside SO Service, old stat: '+(String)trigger.oldmap.get(SO.id).get('Status__c'));
			system.debug('Inside SO Service, new stat: '+SO.Status__c);

		  if(KSE.isFieldChanging('Status__c',SO, trigger.oldMap))
		  {
		  if(STANDARD_ORDER_TYPES.contains(SO.Type__c) || SO_RMA_TYPES.contains(so.Type__c) || SO_RMA_REPLACEMENT_TYPES.contains(so.Type__c))
		  {
			if(!statusTypes.contains((String)trigger.oldmap.get(SO.id).get('Status__c')) && !(SO.Status__c == 'Open'))
			  SO.addError(SO.Name+ ' is not open. Changes are not allowed on this order.');
		  }
		  else if(SALES_ADJUSTMENT_ORDER_TYPES.contains(SO.Type__c) && !SO_RMA_TYPES.contains(so.Type__c) && !SO_RMA_REPLACEMENT_TYPES.contains(so.Type__c))
		  {
			if(!statusTypes.contains((String)trigger.oldmap.get(SO.id).get('Status__c')) && !(SO.Status__c == 'Draft'))
			  SO.addError(SO.Name+ ' is not in draft. Changes are not allowed on this order.');
		  }
		  }



		}
	  }
	}
	public static void confirmDropShip(List<ReceivingWrapper> rWrappers) {
		SchemaUtil util = SchemaUtil.getInstance();

		Set<Id> skidIds = new Set<Id> ();
		Set<Id> solIds = new Set<Id>();
		Map<Id,Decimal> qtyShipped = new Map<Id,Decimal>();
		Set<Id> itemIds = new Set<Id>();
		Set<Id> facilityIds = new Set<Id>();
		Set<Id> itIds = new Set<Id>();
		Boolean recordSerialsAtConfirmShipment = false;
		Map<Id, List<Id>> itemPackagingUOMCache = new Map<Id, List<Id>>();
		for (ReceivingWrapper rw:rWrappers) {
			Id solId = rw.pol.Sales_Order_Line__c;
			solIds.add(solId);
			facilityIds.add(rw.pol.Delivery_Facility__c);
			itemIds.add((Id)rw.rl.get('Item__c'));
			for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
			    if (!itemPackagingUOMCache.containsKey(sw.skid.Item__c) ) {
			        List<Id> lstPkgUom = (List<Id>)JSON.deserialize(sw.skid.Item__r.Packaging_UOM__c, List<Id>.class);
			        itemPackagingUOMCache.put(sw.skid.Item__c, lstPkgUom);
			    }
				itIds.add(sw.it.Id);
				Decimal pkgUOMConversion = KSE.getConversionFactor( sw.skid.Item__c, sw.skid.Facility2__r.Facility_Identifier__c, sw.skid.Packaging_UOM__c, sw.skid.Stocking_UOM__c, itemPackagingUOMCache.get(sw.skid.Item__c)); 
				qtyShipped.put(solId,KSE.addQuantityToField(qtyShipped.get(solId),sw.skid.Quantity__c * pkgUOMConversion));
			}
			if ((String)rw.rl.getSObject('Company__r').get('Serial_Control__c') == 'At shipment only')
				recordSerialsAtConfirmShipment = true;
		}

		Set<String> skidFields = new Set<String>{ 'Id','Name', 'Item__r.Packaging_UOM__c' };
		skidFields.addAll(util.getAllCustomFieldsFromObject(null,'SKID__c'));

		//String skidSubquery = '(' + util.generateQueryFromFieldSet('SKID__c',new Set<String>(),skidFields,' Type__c = \'SO Demand\' ').replace('FROM SKID__c','FROM SKIDs__r') + ')';

		Set<String> solFields = new Set<String> { 'Id','Name','Ship_From_Location__r.Facility__c','Product__r.Item__c','Product__r.Item__r.Non_Inventory__c','Product__r.Item__r.Stocking_UOM__c', 'Product__r.Item__r.Track_Install_Base__c','Company__c', 'Unit_Price__c', 'Product__r.Item__r.Packaging_UOM__c', 'Ship_From_Location__r.Facility__r.Facility_Identifier__c' };
		solFields.addAll(util.getAllCustomFieldsFromObject(null,'Sales_Order_Line__c'));
		solFields.addAll(util.getAllCustomFieldsFromObject('Sales_Order__r.','Sales_Order__c'));

		SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
		soql.addFields(solFields);
		soql.setWhereClause(' Id IN :solIds AND Has_Exceptions__c = false AND Status__c = \'' + SalesOrderService.SO_STATUS_OPEN + '\'');

		SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
		skids.addFields(skidFields);
		skids.setWhereClause('Type__c = \'SO Demand\'');
		soql.addChildRelationship(skids);

		Set<String> shlFields = new Set<String>{ 'Id','Name', 'Item__r.Packaging_UOM__c', 'Facility__r.Facility_Identifier__c' };
		shlFields.addAll(util.getAllCustomFieldsFromObject(null,'Shipment_Line__c'));
		shlFields.addAll(util.getAllCustomFieldsFromObject('Shipment__r.','Shipment__c'));

		SOQLUtil.ChildRelationship shipmentLineQuery = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
		shipmentLineQuery.addFields(shlFields);
		shipmentLineQuery.setWhereClause(' Shipment__r.Status__c = \'Planned\' and Quantity_Shipped__c = 0 ');
		soql.addChildRelationship(shipmentLineQuery);

		/*Map<Id,Sales_Order_Line__c> soLines = new Map<Id,Sales_Order_Line__c>((List<Sales_Order_Line__c>)Database.query(util.generateQueryFromFieldSet('Sales_Order_Line__c',new Set<String>(),solFields,
			' Id IN :solIds AND Has_Exceptions__c = false AND Status__c = \'' + SalesOrderService.SO_STATUS_OPEN + '\'')));*/
		Map<Id,Sales_Order_Line__c> soLines = new Map<Id,Sales_Order_Line__c>((List<Sales_Order_Line__c>)Database.query(soql.getQuery()));

		Set<String> itFields = new Set<String>{ 'Id','Name','Item__r.Packaging_UOM__c','To_SKID__r.Item__r.Packaging_UOM__c','Receipt_Line__r.Purchase_Order_Line__r.Sales_Order_Line__c','Company__c', 'From_Facility__r.Facility_Identifier__c','To_Facility__r.Facility_Identifier__c', 'To_SKID__r.Facility2__r.Facility_Identifier__c', 'From_SKID__r.Facility2__r.Facility_Identifier__c'  };
		itFields.addAll(util.getAllCustomFieldsFromObject(null,'Inventory_Transaction__c'));
		itFields.addAll(util.getAllCustomFieldsFromObject('To_SKID__r.','SKID__c'));

		soql = new SOQLUtil('Inventory_Transaction__c');
	  	soql.addFields(itFields);
	  	soql.setWhereClause(' Id IN :itIds ');

		//Map<Id,Inventory_Transaction__c> itMap = new Map<Id,Inventory_Transaction__c>((List<Inventory_Transaction__c>)Database.query(util.generateQueryFromFieldSet('Inventory_Transaction__c',new Set<String>(),itFields,' Id IN :itIds ')));
		Map<Id,Inventory_Transaction__c> itMap = new Map<Id,Inventory_Transaction__c>((List<Inventory_Transaction__c>)Database.query(soql.getQuery()));

		List<String> attributes = new List<String>(SkidService2.attributesForPutaway(new List<String>(util.getAllCustomFieldsFromObject(null,'Item_Attribute__c'))));
		Map<Id,Shipment__c> shipments = new Map<Id,Shipment__c>();
		Map<Id,Shipment__c> existingShipments = new Map<Id,Shipment__c>();
		Map<Id,Map<Id,Shipment_Line__c>> shipmentLinesToUpsert = new Map<Id,Map<Id,Shipment_Line__c>>();

		List<SKID__c> existingSkids = new List<SKID__c>();
		for (ReceivingWrapper rw:rWrappers) {

			Sales_Order_Line__c soLine = soLines.get(rw.pol.Sales_Order_Line__c);
			Shipment_Line__c shl = new Shipment_Line__c();
			Shipment__c sh = new Shipment__c();

			if( soLine.Shipment_Lines__r.size() > 0 ){ //planned shipment line already exists
				shl = soLine.Shipment_Lines__r[0];
				sh = shl.Shipment__r;
			}

			if ((!shipments.containsKey(rw.headerRecord.Id)) && (!existingShipments.containsKey(rw.headerRecord.Id))) {
				if( sh.Id == null ){
					shipments.put(rw.headerRecord.Id,new Shipment__c(
						Company__c = soLine.Sales_Order__r.Company__c,
						Customer__c = soLine.Sales_Order__r.Ship_To__c,
						Ship_to_Street__c = soLine.Sales_Order__r.Ship_to_Street__c,
						Ship_to_City__c = soLine.Sales_Order__r.Ship_to_City__c,
						Ship_to_State__c = soLine.Sales_Order__r.Ship_to_State__c,
						Ship_to_Zip_Code__c = soLine.Sales_Order__r.Ship_to_Zip_Code__c,
						Ship_to_Country__c = soLine.Sales_Order__r.Ship_to_Country__c,
						Means_of_Transport__c = soLine.Sales_Order__r.Means_of_Transport__c,
						Planned_Delivery_Date__c = soLine.Sales_Order__r.Required_Date__c,
						Ship_From_Facility__c = soLine.Ship_From_Location__r.Facility__c,
						Ship_From_Location__c = soLine.Ship_From_Location__c,
						Status__c = 'Planned',
						Type__c = ShipmentService.SHIPMENT_TYPE_SALES_ORDER,
						Transaction_Type__c = ShipmentService.SHIPMENT_TRANSACTION_TYPE_LOGICAL,
						Currency__c = soLine.Sales_Order__r.Currency__c,
						Date_Shipped__c = (DateTime)rw.rl.getSObject('ASN__r').get('Date_Shipped__c')
					));
				}
				else{
					existingShipments.put(rw.headerRecord.Id, sh);
				}
				shipmentLinesToUpsert.put(rw.headerRecord.Id,new Map<Id,Shipment_Line__c>());
			}

			Decimal convFactor = 1;
			convFactor = KSE.getConversionFactor(soLine);
			qtyShipped.put(soLine.Id,qtyShipped.get(soLine.Id) / convFactor);

			shl.Company__c = soLine.Company__c;
			shl.Description__c = soLine.Description__c;
			shl.Discount_Percent__c = soLine.Discount_Percent__c;
			shl.Facility__c = soLine.Ship_From_Location__r.Facility__c;
			shl.Location__c = soLine.Ship_From_Location__c;
			shl.Product__c = soLine.Product__c;
			shl.Item__c = soLine.Product__r.Item__c;
			shl.Item__r = soLine.Product__r.Item__r;
			shl.Planned_Weight__c = soLine.Weight__c;
			shl.Purchase_Order_Line__c = rw.pol.Id;
			shl.Line_Type__c = soLine.Line_Type__c;
			shl.Sales_Order__c = soLine.Sales_Order__c;
			shl.Sales_Order_Line__c = soLine.Id;
			shl.Sales_Order_Line__r = soLine;
			shl.Unit_Price__c = soLine.Unit_Price__c;
			shl.Weight_UOM__c = soLine.Weight_UOM__c;
			shl.Quantity_Planned__c = qtyShipped.get(soLine.Id);
			shl.Quantity_Shipped__c = qtyShipped.get(soLine.Id);

			Decimal activeStandardCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds,soLine.Company__c,soLine.Ship_From_Location__r.Facility__c,System.now(),soLine.Product__r.Item__c);
			if (soLine.Product__r.Item__r.Non_Inventory__c && activeStandardCost != null)
				shl.Extended_Cost__c = (activeStandardCost * shl.Quantity_Shipped__c * convFactor).setscale(6,System.RoundingMode.HALF_UP);
			else
				shl.Extended_Cost__c = 0;

			shl.Quantity_From_Stock__c = (shl.Quantity_Shipped__c * convFactor).setscale(6,System.RoundingMode.HALF_UP);
			shipmentLinesToUpsert.get(rw.headerRecord.Id).put(soLine.Id,shl);

			for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
				Inventory_Transaction__c it = itMap.get(sw.it.Id);
				sw.it = it;
				if (!soLine.Product__r.Item__r.Non_Inventory__c && (it.To_SKID__c == null || !recordSerialsAtConfirmShipment)) {
					SKID__c skid = new SKID__c(Type__c = 'Location');
					SkidService3.copyITAttributesToSkid(skid,it,attributes);
					existingSkids.add(skid);
				}
				if ( sw.it.To_Skid__c != null ) {
					skidIds.add( sw.it.To_Skid__c );
				}
			}
		}
		Savepoint sp = Database.setSavepoint();
		try {
			DML.insertAsUser(shipments.values());
			shipments.putAll(existingShipments);
		} catch(Exception e) {
			Database.rollback(sp);
			throw new SalesOrderServiceException('Error inserting shipments: ' + e.getMessage());
		}
		List<Shipment_Line__c> shipmentLines = new List<Shipment_Line__c>();
		for (Id headerId:shipments.keySet()) {
			Shipment__c shipment = shipments.get(headerId);
			for (Shipment_Line__c shipmentLine:shipmentLinesToUpsert.get(headerId).values()) {
				shipmentLine.Shipment__c = shipment.Id;
				shipmentLine.Shipment__r = shipment;
				shipmentLines.add(shipmentLine);
			}
		}
		try {
			//DML.checkUpsertAsUser(shipmentLines);KNDY-13345
			upsert shipmentLines;
		} catch(Exception e) {
			Database.rollback(sp);
			throw new SalesOrderServiceException('Error inserting shipment lines: ' + e.getMessage());
		}

		Map<List<String>,SKID__c> existingSkidMap = SkidService3.generateExistingSkidMap(attributes,existingSkids,false,null);
		Map<Id,List<Serial__c>> serialMap = new Map<Id,List<Serial__c>>();
		if ( existingSkidMap != null ) {
			for ( Skid__c sk : existingSkidMap.values() ) {
				skidIds.add(sk.Id);
			}

			SOQLUtil serialQuery = new SOQLUtil('Serial__c');
			serialQuery.addAllCustomFields();
			serialQuery.setWhereClause('Skid__c in : skidIds');
			for (Serial__c serial:Database.query(serialQuery.getQuery())) {
				if (!serialMap.containsKey(serial.SKID__c)) {
					serialMap.put(serial.SKID__c,new List<Serial__c>());
				}
				serialMap.get(serial.SKID__c).add(serial);
			}
		}

		Map<Id,SkidService3.ParameterData> data = new Map<Id,SkidService3.ParameterData>();
		//List<SKID__c> skidsToUpdate = new List<SKID__c>();
		List<SkidService3.SerialWrapper> serialWrappers = new List<SkidService3.SerialWrapper>();
		List<SkidService3.SerialWrapper> negativeSwrappers = new List<SkidService3.SerialWrapper>();
		Map<String,String> configMap =  new Map<String,String>{ 'adjustFromSkidQuantity'=>'none'};
		List<Inventory_Transaction__c> itsToUpdate = new List<Inventory_Transaction__c>();
		for (ReceivingWrapper rw:rWrappers) {
			Sales_Order_Line__c soLine = soLines.get(rw.pol.Sales_Order_Line__c);
			Id shipmentLineId = shipmentLinesToUpsert.get(rw.headerRecord.Id).get(soLine.Id).Id;

			shipments.put(rw.headerRecord.Id,new Shipment__c(
				Id = shipments.get(rw.headerRecord.Id).Id,
				Status__c = 'Confirmed',
				Locked__c = true,
				Carrier__c = (String)rw.rl.getSObject('ASN__r').get('Carrier__c'),
				Tracking_Id__c = (String)rw.rl.getSObject('ASN__r').get('Tracking_Number__c'),
				Date_Shipped__c = (DateTime)rw.rl.getSObject('ASN__r').get('Date_Shipped__c')
			));

			if( shipments.get(rw.headerRecord.Id).Date_Shipped__c == null ){
				shipments.get(rw.headerRecord.Id).Date_Shipped__c = system.now();
			}

			shipments.get(rw.headerRecord.Id).Transaction_date__c = shipments.get(rw.headerRecord.Id).Date_Shipped__c;

			if (!soLine.Product__r.Item__r.Non_Inventory__c) {
				for (SkidService3.SerialWrapper sw:rw.serialWrapperList) {
					List<String> keyList =  SkidService2.generateKeyListForIT(sw.it,attributes);
					Boolean toSkidNull = false;
					SKID__c negativeShipSkid;
					if (sw.it.To_SKID__c == null) {
						toSkidNull = true;
						if (existingSkidMap.containsKey(keyList)) {
							sw.it.To_SKID__c = existingSkidMap.get(keyList).Id;
							sw.it.To_SKID__r = existingSkidMap.get(keyList);
						} else {
							continue;
						}
					} else if (!recordSerialsAtConfirmShipment) {
						if (existingSkidMap.containsKey(keyList)) {
							sw.serialList = serialMap.containsKey(existingSkidMap.get(keyList).Id) ? serialMap.get(existingSkidMap.get(keyList).Id): new List<Serial__c>();
						}

					}
					if (!recordSerialsAtConfirmShipment && (toSkidNull || (!toSkidNull && sw.serialList.size() == 0)))
						sw.serialList = serialMap.containsKey(sw.it.To_SKID__c) ? serialMap.get(sw.it.To_SKID__c): new List<Serial__c>();

				sw.it.Shipment_Line__c = shipmentLineId;
				  sw.it.Purchase_Order_Line__c = rw.pol.Id;
				  sw.it.Sales_Order_Line__c = soLine.Id;
				  itsToUpdate.add(sw.it);

					Inventory_Transaction__c shipIT = sw.it.clone(false,true);
					shipIT.To_SKID__c = null;
					shipIT.Type__c = InventoryTransactionService.LOGICAL_SALES_ORDER_SHIPMENT;
					shipIT.From_Facility__c = sw.it.To_Facility__c;
					shipIT.From_Location__c = sw.it.To_Location__c;
					shipIT.To_Facility__c = null;
					shipIT.To_Location__c = null;
					shipIT.From_SKID__c = sw.it.To_SKID__c;
					shipIT.From_SKID__r = sw.it.To_SKID__r;
					shipIT.Finalized__c = true;
					shipIT.Company__c = soLine.Company__c;
					negativeShipSkid = shipIT.From_SKID__r.clone(true,true);
					
					negativeShipSkid.Quantity__c = -sw.skid.Quantity__c;
					if (!data.containsKey(shipments.get(rw.headerRecord.Id).Id)) {
						SkidService3.ParameterData d = new SkidService3.ParameterData();
						d.sourceDoc = new Sales_Order__c(Company__c = soLine.Company__c);
						data.put(shipments.get(rw.headerRecord.Id).Id,d);
					}
					data.get(shipments.get(rw.headerRecord.Id).Id).itList.add(shipIT);
					serialWrappers.add(new SkidService3.SerialWrapper(shipIT,sw.serialList));
					negativeSwrappers.add(new SkidService3.SerialWrapper(negativeShipSkid, new list<Serial__c>()));
				}
			}

			soLine.Quantity_Shipped__c = KSE.addQuantityToField(soLine.Quantity_Shipped__c,qtyShipped.get(soLine.Id));
			soLine.Quantity_Planned__c = KSE.subtractDecimals(soLine.Quantity_ordered__c, soLine.Quantity_Shipped__c );
			/*
			for (SKID__c demandSkid:soLine.SKIDs__r) {
				demandSkid.Quantity__c -= qtyShipped.get(soLine.Id);
				skidsToUpdate.add(demandSkid);
			} */
			soLines.put(soLine.Id,new Sales_Order_Line__c(Id = soLine.Id, Quantity_Shipped__c = soLine.Quantity_Shipped__c, Quantity_Planned__c = soLine.Quantity_Planned__c ));
		}

		try {
			DML.updateAsSystem(itsToUpdate);
			//DML.sobjectUpdate(skidsToUpdate);
			Map<List<String>,SkidService3.SerialWrapper> createdSerials = SkidService3.putAwayService(serialWrappers,null,new Map<String,Boolean>{SkidService3.CREATE_SERIAL=>recordSerialsAtConfirmShipment});
			map<List<String>, SkidService3.SerialWrapper > negShipSkidMap;
			if(negativeSwrappers.size()>0){
				negShipSkidMap = SkidService3.putAwayService(negativeSwrappers,null,new map<String,Boolean>{SkidService3.CREATE_SERIAL=>false});
				map<Id,SKID__c> shipSkidsByIdMap = new map<Id,SKID__c>();
            	for(SkidService3.SerialWrapper sw : negShipSkidMap.values()){
	            	shipSkidsByIdMap.put(sw.skid.Id, sw.skid);
	            }
	            
	           
		        for (Id sourceDocId:data.keySet()) {
            	
		            for( Inventory_Transaction__c it : data.get(sourceDocId).itList ){
				            if(it.From_SKID__c != null && shipSkidsByIdMap.containsKey(it.From_SKID__c) ){        
			                                       
			                     it.From_Skid__r = shipSkidsByIdMap.get(it.From_SKID__c);         	                    	              
				        	}        	
			        } 
		            
				}
				
			}
			
			SkidService3.inventoryTransactionsForPutAway(data,null,createdSerials,configMap);
			DML.updateAsUser(shipments.values());
			DML.updateAsUser(soLines.values());
		} catch(Exception e) {
			Database.rollback(sp);
			throw new SalesOrderServiceException(e.getMessage());
		}
	}
	public static void confirmDropShip(List<ReceivingDocumentService.receivingWrapper> rlWrapperList) {

		SchemaUtil util = SchemaUtil.getInstance();

		Map<Id, Shipment_Line__c> solshlMap = new Map<Id, Shipment_Line__c>();
		Map<Id, Shipment__c> shipmentMap = new Map<Id, Shipment__c>();
		Set<Id> itemIds = new Set<Id>();
		Set<Id> facilityIds = new Set<Id>();
		Set<Id> solIds = new Set<Id>();
		List<String> attributesForDisplay = new List<String>();
		Set<Id> uniqueToLocations = new Set<Id>();
		List<Skid__c> existingSkidList = new List<Skid__c>();
		Map<Id, List<SKID__c>> quantitySkidsByHeader = new Map<Id, List<SKID__c>>();
		Map<Id,Decimal> qtyShipped = new Map<Id,Decimal>();
		List<Inventory_Transaction__c> inventoryTransactionList = new List<Inventory_Transaction__c>();
		Map<Id, List<Inventory_Transaction__c>> itMap = new Map<Id, List<Inventory_Transaction__c>>(); //SOL, IT[]
		List<Inventory_Transaction__c> itsToUpdate = new List<Inventory_Transaction__c>();

		for (ReceivingDocumentService.receivingWrapper rw : rlWrapperList){
		  Id solId = (Id)rw.rl.get('Sales_Order_Line__c');
			solIds.add(solId);
			itemIds.add(((Purchase_Order_Line__c) rw.rl).Item__c);
			facilityIds.add(((Purchase_Order_Line__c) rw.rl).Delivery_Facility__c);
			for (SKID__c skid:rw.skidList)
			  qtyShipped.put(solId,KSE.addQuantityToField(qtyShipped.get(solId),skid.Quantity__c));
		}

		Id rdId = rlWrapperList[0].receipt.Receiving_Document__c;
		Receipt_Line__c RCL = [SELECT Id, (SELECT Id, Sales_Order_Line__c FROM Inventory_Transactions__r)
								 FROM Receipt_Line__c
								WHERE Receiving_Document__c = :rdId LIMIT 1];
		itMap.put(RCL.Inventory_Transactions__r[0].Sales_Order_Line__c, RCL.Inventory_Transactions__r);

		Id polId = ((Purchase_Order_Line__c) rlWrapperList[0].rl).Id;

		/*Set<String> itFields = new Set<String>{ 'Id', 'Name', 'Item__c', 'Item__r.Stocking_UOM__c', 'From_Location__c', 'From_Skid__c', 'From_Skid__r.Lot__c',
							'From_SKID__r.Bin__c', 'From_SKID__r.Bin__r.Name', 'From_Skid__r.Expiration_Date__c', 'From_Skid__r.Shipment_Line__c', 'To_Location__c',
							'Quantity__c', 'Standard_Cost__c', 'Shipment_Line__r.Quantity_Shipped__c', 'Shipment_Line__r.Shipment__c', 'Shipment_Line__r.Extended_Price__c',
							'Shipment_Line__r.Shipment__r.Finalized__c', 'Shipment_Line__r.Shipment__r.Status__c', 'To_Skid__c','To_Skid__r.Id','To_Skid__r.Type__c','To_Skid__r.Lot__c',
							'To_Skid__r.Expiration_Date__c', 'To_Skid__r.Item__c', 'To_Skid__r.Quantity__c', 'To_Skid__r.Sales_Order_line__c', 'To_Skid__r.Location__c',
							'Shipment_Line__r.Shipment__r.Date_Shipped__c','Sales_Order_Line__c', 'Shipment_Line__r.Shipment__r.Name'};
		itFields.addAll(util.getAllCustomFieldsFromObject(null, 'Inventory_Transaction__c'));
		itFields.addAll(util.getAllCustomFieldsFromObject('To_Skid__r.', 'Skid__c'));

		//String subquery = util.generateQueryFromFieldSet( 'Inventory_Transaction__c', new set<string>{'ConfirmShipRO'},
		//                    fieldList, 'type__c = \'Sales Order Pick\' and Finalized__c = true and Shipment_Line__r.Shipment__r.Status__c != \'Confirmed\' and Reversed__c= false');
		//subquery = '('+subquery.replace('FROM Inventory_Transaction__c','FROM Inventory_Transactions__r')+')';

		/*String subquery2 =  '( SELECT id, type__c, Quantity__c, Shipment_Line__r.Quantity_Shipped__c,'+
							'Shipment_Line__r.Shipment__c,Shipment_Line__r.Extended_Price__c,Shipment_Line__r.Shipment__r.Finalized__c, Shipment_Line__r.Shipment__r.Locked__c,'+
							'Shipment_Line__r.Shipment__r.Status__c, Shipment_Line__c,Shipment_Line__r.Shipment__r.Date_Shipped__c FROM SKIDs__r where type__c = \'SO Demand\')';
		*/
		Set<String> skidFields = new Set<String>{'id', 'type__c', 'Quantity__c', 'Shipment_Line__r.Quantity_Shipped__c',
									   'Shipment_Line__r.Shipment__c', 'Shipment_Line__r.Extended_Price__c', 'Shipment_Line__r.Shipment__r.Finalized__c',
									   'Shipment_Line__r.Shipment__r.Locked__c', 'Shipment_Line__r.Shipment__r.Status__c', 'Shipment_Line__c', 'Shipment_Line__r.Shipment__r.Date_Shipped__c'};

		/*String subquery3 =  '(SELECT Id FROM Shipment_Lines__r WHERE Sales_Order_Line__c IN :solIds)';*/

		Set<String> solFields = new Set<String>{ 'ID','Name','Line__c','Product__r.Item__c','Product__r.Item__r.Description__c','Product__r.Item__r.Name','Product__r.Item__r.Class__c',
						  'Product__r.Product_Group__c', 'Quantity_Available_to_Ship__c','Quantity_Backordered__c','Company__c', 'Selling_UOM__r.Name','Product__r.Item__r.Stocking_UOM__r.Name',
						  'Quantity_From_Stock__c','Selling_UOM__c','Product__r.Item__r.Stocking_UOM__c', 'Weight__c', 'Line_Type__c', 'Weight_UOM__c',
						  'Product__c','Product__r.Name','Quantity_Ordered__c','Quantity_Shipped__c','Quantity_to_Ship__c','Ship_From_Location__c', 'Ship_From_Location__r.Facility__c',
						  'Required_Date__c','Sales_Order__c','Sales_Order__r.Customer__r.Top_Parent_Customer__c','Status__c','Discount_Percent__c',
						  'Unit_Price__c','SystemModStamp','Sales_Order__r.Customer__r.Top_Parent_Customer__r.Status__c','Product__r.Item__r.Non_Inventory__c',
						  'Sales_Order__r.Currency__c','Sales_Order__r.Company__c','Description__c','Selling_UOM__c','Quantity_Allocated__c', 'Pricebook__c',
						  'Sales_Order__r.Ship_To__c', 'Sales_Order__r.Means_of_Transport__c', 'Sales_Order__r.Required_Date__c',
						  'Product__r.Pricebook_Line_Required__c', 'Sales_Order__r.Ship_to_Street__c', 'Sales_Order__r.Ship_to_City__c', 'Sales_Order__r.Ship_to_State__c',
						  'Sales_Order__r.Ship_to_Zip_Code__c', 'Sales_Order__r.Ship_to_Country__c'};

		String whereClause = 'Id IN :solIds and Has_Exceptions__c = false AND Status__c = \'' + SalesOrderService.SO_STATUS_OPEN + '\'';

	  SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c');
	  soql.addFields('Fulfillment_RO');
	  soql.addFields(solFields);
	  soql.setWhereClause(whereClause);

	  SOQLUtil.ChildRelationship skids = new SOQLUtil.ChildRelationship(soql, 'SKIDs__r');
	  skids.addFields(skidFields);
	  skids.setWhereClause('Type__c = \'SO Demand\'');
	  soql.addChildRelationship(skids);

	  SOQLUtil.ChildRelationship shLines = new SOQLUtil.ChildRelationship(soql, 'Shipment_Lines__r');
	  shLines.addFields(new Set<String>{'Id'});
	  shLines.setWhereClause('Sales_Order_Line__c IN :solIds');
	  soql.addChildRelationship(shLines);

	  String query = soql.getQuery();

		List<Sales_Order_Line__c> tmpSOLines  = Database.query(query);

	/*List<Sales_Order_Line__c> tmpSOLines  = Database.query(util.generateQueryFromFieldSet( 'Sales_Order_Line__c', new Set<String>{'Fulfillment_RO'},
						  fieldStrings, 'Id IN :solIds and Has_Exceptions__c = false AND Status__c = \'' + SalesOrderService.SO_STATUS_OPEN + '\''));
	*/

		Sales_Order_Line__c salesOrderLine1 = tmpSOLines[0];    // used to find the Sales Order Information for the Shipment

		System.Savepoint sp = Database.setSavepoint();

		Shipment__c shipment = new Shipment__c();
		shipment.Company__c = salesOrderLine1.Sales_Order__r.Company__c;
		shipment.Customer__c = salesOrderLine1.Sales_Order__r.Ship_To__c;
		shipment.Ship_to_Street__c = salesOrderLine1.Sales_Order__r.Ship_to_Street__c;
		shipment.Ship_to_City__c = salesOrderLine1.Sales_Order__r.Ship_to_City__c;
		shipment.Ship_to_State__c = salesOrderLine1.Sales_Order__r.Ship_to_State__c;
		shipment.Ship_to_Zip_Code__c = salesOrderLine1.Sales_Order__r.Ship_to_Zip_Code__c;
		shipment.Ship_to_Country__c = salesOrderLine1.Sales_Order__r.Ship_to_Country__c;
		shipment.Means_of_Transport__c = salesOrderLine1.Sales_Order__r.Means_of_Transport__c; // KNDY-1504
		shipment.Planned_Delivery_Date__c = salesOrderLine1.Sales_Order__r.Required_Date__c; // KNDY-1981
		shipment.Ship_From_Facility__c = salesOrderLine1.Ship_From_Location__r.Facility__c;
		shipment.Ship_From_Location__c = salesOrderLine1.Ship_From_Location__c;
		shipment.Status__c = 'Planned';
		shipment.Type__c = ShipmentService.SHIPMENT_TYPE_SALES_ORDER;
		shipment.Transaction_Type__c = ShipmentService.SHIPMENT_TRANSACTION_TYPE_LOGICAL;
		shipment.Currency__c = salesOrderLine1.Sales_Order__r.Currency__c;

		try {
			DML.insertAsUser(shipment);
		} catch(Exception e) {
			Database.rollback(sp);
			throw new SalesOrderServiceException('Error inserting the Shipment. ' + e.getMessage());
		}

		//List<Shipment_Line__c> shlList = new List<Shipment_Line__c>();
		Map<Sales_Order_Line__c, Shipment_Line__c> salesOrderShlMap = new Map<Sales_Order_Line__c, Shipment_Line__c>();
		for (Sales_Order_Line__c salesOrderLine : tmpSOLines) {

			Shipment_Line__c shlObj = new Shipment_Line__c();

			shlObj.Company__c = salesOrderLine.Company__c;
			shlObj.Description__c = salesOrderLine.Description__c;
			shlObj.Discount_Percent__c = salesOrderLine.Discount_Percent__c;

			shlObj.Company__c = salesOrderLine.Company__c;
			shlObj.Description__c = salesOrderLine.Description__c;
			shlObj.Discount_Percent__c = salesOrderLine.Discount_Percent__c;

			//Decimal activeStandardCost = ItemService.getActiveStandardCost(itemIds, salesOrderLine.Company__c, salesOrderLine.Ship_From_Location__r.Facility__c, System.Today()).get(salesOrderLine.Product__r.Item__c);
			Decimal activeStandardCost = ItemService.getActiveStandardCostDecimal(itemIds, facilityIds, salesOrderLine.Company__c, salesOrderLine.Ship_From_Location__r.Facility__c, System.Now(),salesOrderLine.Product__r.Item__c);

			decimal cf = 1;
			if(salesOrderLine.Quantity_From_Stock__c==null || salesOrderLine.Quantity_From_Stock__c==0)
				cf =  KSE.getConversionFactor(salesOrderLine);
			else
				cf =  KSE.getConversionFactorFromQuantity(salesOrderLine.Quantity_From_Stock__c,salesOrderLine.Quantity_Ordered__c);

			if (salesOrderLine.Product__r.Item__r.Non_Inventory__c && activeStandardCost != null) {
					shlObj.Extended_Cost__c = (activeStandardCost
											* KSE.addQuantityToField(shlObj.Quantity_Shipped__c, 0)
												* cf).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(salesOrderLine);
			} else {
				shlObj.Extended_Cost__c = 0;
			}

			shlObj.Facility__c = salesOrderLine.Ship_From_Location__r.Facility__c;
			shlObj.Location__c = salesOrderLine.Ship_From_Location__c;
			shlObj.Product__c = salesOrderLine.Product__c;

			// Quantity planned is remaining quantity to be shipped. (This might change in future.)
			shlObj.Quantity_Planned__c = KSE.addQuantityToField(qtyShipped.get(salesOrderLine.Id) / cf, 0); //
			shlObj.Quantity_Shipped__c = shlObj.Quantity_Planned__c; //OTC-351
			//KSE.subtractDecimals(salesOrderLine.Quantity_Ordered__c, salesOrderLine.Quantity_Shipped__c);

			// Copy Total Weight from Sales Order Line : KNDY-2634
			shlObj.Planned_Weight__c = salesOrderLine.Weight__c;  //KNDY 3621 UOM Conversion.Changed the field from total_weight__c to weight__c.
			shlObj.Purchase_Order_Line__c = polId;

			shlObj.Line_Type__c = salesOrderLine.Line_Type__c; //OTC-688
			shlObj.Quantity_From_Stock__c = (KSE.addQuantityToField(shlObj.Quantity_Shipped__c, 0) * (cf)).setscale(6,System.RoundingMode.HALF_UP);//KSE.getConversionFactor(salesOrderLine);
			shlObj.Sales_Order__c = salesOrderLine.Sales_Order__r.Id;
			shlObj.Sales_Order_Line__c = salesOrderLine.Id;
			shlObj.Shipment__c  = shipment.Id;
			shlObj.Shipment__r = shipment;
			shlObj.Unit_Price__c = salesOrderLine.Unit_Price__c;
			shlObj.Weight_UOM__c = salesOrderLine.Weight_UOM__c;
			salesOrderShlMap.put(salesOrderLine, shlObj);
		}

		// Update the IT with the newly created SHL
		Database.SaveResult[] solshlResult = DML.insertAsUser(salesOrderShlMap.values());
		Set<Id> shlSavedIds = new Set<Id>();
		for (Database.SaveResult sr : solshlResult) {
			shlSavedIds.add(sr.getId());
		}

		for (Shipment_Line__c SHL : [SELECT Id, Sales_Order_Line__c,  Sales_Order_Line__r.Unit_Price__c
									   FROM Shipment_Line__c
									  WHERE Id IN :shlSavedIds]){
			if (itMap.containsKey(SHL.Sales_Order_Line__c)) {
				for (Inventory_Transaction__c IT : itMap.get(SHL.Sales_Order_Line__c)){
					IT.Shipment_Line__c = SHL.Id;
					itsToUpdate.add(IT);
				}
			}
		}

		try {
			FulfillmentService.fulfillNonInventoryItems(shlSavedIds);
			DML.updateAsSystem(itsToUpdate);
		} catch(Exception e) {
			Database.rollback(sp);
			throw new SalesOrderServiceException('Error updating inventory transactions. ' + e.getMessage());
		}

		attributesForDisplay.addAll(SkidService2.attributesForPutaway(new List<String>(Schemautil.getInstance().getAllCustomFieldsFromObject(null,'Item_Attribute__c'))));
		Map<List<String>, SKID__c> existingSkidKeyListMap = SkidService2.generateExistingSkidKeyListMap(attributesForDisplay, uniqueToLocations, existingSkidList);


		Map<Id, SKID__c> skidsToUpdate = new Map<Id,SKID__c>();
		Map<Id, SKID__c> skidsToDelete = new Map<Id,SKID__c>();
		List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();    //do we need this?
		for (Sales_Order_Line__c salesOrderLine : tmpSOLines) {
			for (Inventory_Transaction__c it : salesOrderLine.Inventory_Transactions__r){
				if (it.To_Skid__c == null){
					List<String> keyList =  SkidService2.generateKeyListForIT(it, attributesForDisplay);
					if (existingSkidKeyListMap.containsKey(keyList)){
						it.To_SKID__c = existingSkidKeyListMap.get( keyList ).id;
						it.To_SKID__r = existingSkidKeyListMap.get( keyList );
					} else {
						continue;
					}
				}

				if (!quantitySkidsByHeader.containsKey(salesOrderLine.id))
					quantitySkidsByHeader.put(salesOrderLine.id, new List<SKID__c>());

				if (it.To_Skid__r.Quantity_Allocated__c == null){
					it.To_Skid__r.Quantity_Allocated__c  = 0;
				}
				it.To_Skid__r.Quantity_Allocated__c = it.Quantity__c/KSE.getConversionFactor(salesOrderLine);
				it.To_Skid__r.Sales_Order_Line__c = it.Sales_Order_Line__c;

				if (salesOrderShlMap.get(salesOrderLine) != null){
					it.To_Skid__r.Shipment_Line__c = salesOrderShlMap.get(salesOrderLine).Id;
				}

				quantitySkidsByHeader.get(salesOrderLine.Id).add(it.To_Skid__r.clone(true,true));
			}
			decimal cf = 1;
			if(salesOrderLine.Quantity_From_Stock__c==null || salesOrderLine.Quantity_From_Stock__c==0)
				cf =  KSE.getConversionFactor(salesOrderLine);
			else
				cf =  KSE.getConversionFactorFromQuantity(salesOrderLine.Quantity_From_Stock__c,salesOrderLine.Quantity_Ordered__c);

			for (SKID__c dsk : salesOrderLine.SKIDs__r) {
				if (salesOrderShlMap.get(salesOrderLine) == null){
					continue;
				}
				updateShipments(salesOrderShlMap.get(salesOrderLine), salesOrderLine, qtyShipped.get(salesOrderLine.Id), itemIds,facilityIds, null, solshlMap, shipmentMap );
				salesOrderLine.Quantity_Shipped__c = KSE.addQuantityToField(qtyShipped.get(salesOrderLine.Id) / cf, salesOrderLine.Quantity_Shipped__c);
				solList.add(salesOrderLine);
				dsk.Quantity__c = dsk.Quantity__c - qtyShipped.get(salesOrderLine.Id);
				if (dsk.Quantity__c == 0){
					skidsToDelete.put(dsk.id, dsk);
				} else {
					skidsToUpdate.put(dsk.id, dsk);
				}
			}
		}

		try{
			DML.updateAsSystem(skidsToUpdate.values());
			DML.deleteAsSystem(skidsToDelete.values());
			SkidService2.inventoryTransactionForPullFrom(tmpSOLines, quantitySkidsByHeader, 'Sales Order Shipment', attributesForDisplay, null, 'Quantity_Allocated__c', null, true, null);
			DML.updateAsUser(solshlMap.values());
			DML.updateAsUser(shipmentMap.values());
			DML.updateAsUser(solList);

		} catch(Exception e) {
			Database.rollback(sp);
			throw new SalesOrderServiceException(e.getMessage());
		}

	}

	public static void updateShipments(Shipment_Line__c shl , Sales_Order_Line__c sol, Decimal quantityShipped, Set<Id> itemIds,Set<Id> facilityIds, Date dateShipped,
							  Map<Id, Shipment_Line__c> solshlMap, Map<Id, Shipment__c> shipmentMap){

		shl.Quantity_Shipped__c = quantityShipped;
		Double stdCost = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds, sol.Company__c, sol.Ship_From_Location__r.Facility__c, System.Now(), sol.Product__r.Item__c);
		if (stdCost != null) {
			shl.Extended_Cost__c = stdCost * KSE.addQuantityToField(shl.Quantity_Shipped__c, 0) * KSE.getConversionFactor(sol);
			if( sol.product__r.Item__r.Non_Inventory__c == false)
				shl.Quantity_From_Stock__c = KSE.addQuantityToField(shl.Quantity_Shipped__c, 0) * KSE.getConversionFactor(sol);
		} else {
			shl.Extended_Cost__c = 0;
		}

		solshlMap.put(sol.id,shl); //Created Map to pass for Reprice logic.
		shl.Shipment__r.Date_Shipped__c = (dateShipped == null)  ? System.now() : dateShipped; // OTC-502
		shl.Shipment__r.Status__c = 'Confirmed';
		shl.Shipment__r.Transaction_date__c = (shl.Shipment__r.Transaction_date__c == null) ? system.now() : shl.Shipment__r.Transaction_Date__c;
		//shl.Shipment__r.Finalized__c = true;
		shl.Shipment__r.Locked__c = true;
		shipmentMap.put(shl.Shipment__c, shl.Shipment__r);
	}

	// OTC-927
	public static void validateCustomer(){
		if(trigger.isBefore && trigger.isUpdate){
			for (Sales_Order__c SO : (List<Sales_Order__c>) Trigger.new) {
				if (SO.Status__c != 'Draft'){
					if (Trigger.oldMap.get(SO.Id).get('Ship_to__c') != SO.Ship_to__c){
						SO.Ship_to__c.addError(Label.Cannot_update_ship_to_customer_if_Sales_Order_is_not_in_Draft);
					}
					if (Trigger.oldMap.get(SO.Id).get('Customer__c') != SO.Customer__c){
						SO.Customer__c.addError(Label.Cannot_update_customer_if_Sales_Order_is_not_in_Draft);
					}
					if (Trigger.oldMap.get(SO.Id).get('Bill_to__c') != SO.Bill_to__c){
						SO.Bill_to__c.addError(Label.Cannot_update_bill_to_customer_if_Sales_Order_is_not_in_Draft);
					}
				}
			}
		}
	}

	public static void updateWeightUOM(){

		if(trigger.isAfter && trigger.isUpdate){

			Set<String> salesOrderIds = new Set<String>();

			for(Sales_Order__c salesOrder: (List<Sales_Order__c>)Trigger.new) {

				if(KSE.isFieldChanging('Weight_UOM__c', salesOrder, trigger.oldMap)){

					salesOrderIds.add(salesOrder.Id);

				}
			}

			if(salesOrderIds.size() > 0){

				List<Sales_Order_Line__c> soLines = fetchSalesOrderLines(salesOrderIds);

				for(Sales_Order_Line__c soLine : soLines) {

					soLine.Weight_UOM__c = soLine.Sales_Order__r.Weight_UOM__c;
				}

				List<Sales_Order_Line__c> updatedSOLines = SalesOrderLineService.setWeightAndUOM(soLines, null);

				if(updatedSOLines.size() > 0){
					DML.updateAsUser(updatedSOLines);
				}
			}
		}
	}

	public static List<Sales_Order_Line__c> fetchSalesOrderLines(Set<String> salesOrderIds){

		List<Sales_Order_Line__c> soLines = new List<Sales_Order_Line__c>();

		soLines = [Select Id,
						  Name,
						  Product__c,
						  Quantity_Ordered__c,
						  Selling_Uom__c,
						  Quantity_From_Stock__c,
						  Weight__c,
						  Weight_UOM__c,
						  Product_Weight__c,
						  Volume__c,
						  Sales_Order__r.Weight_UOM__c
					 from Sales_Order_Line__c
					where Sales_Order__c
					   in :salesOrderIds];

		return  soLines;
	}

	public static void setRecurrenceStartDate(set<Id> solIds, list<Fulfillment__c> lFulfillments) {
		map<Id, Sales_Order__c> mSOs = new map<Id,Sales_Order__c>();
		system.debug('inside SO.setRecurrenceStartDate');
		if(!lFulfillments.isEmpty() && !solids.isEmpty()) {
			SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Sales_Order__c','Sales_Order__r.Billing_UOM__c','Sales_Order__r.Recurrence_Start_Date__c','Price_Type__c'
			});
			soql.setWhereClause('Id in :solIds and Sales_Order__r.Billing_UOM__c != null and Sales_Order__r.Recurrence_Start_Date__c = null');
			
			for(Sales_Order_Line__c sol : Database.query(soql.getQuery())) {
				system.debug('sol '+sol);

				for(Fulfillment__c f : lFulfillments) {
					system.debug('f '+ f);
					if(f.Sales_Order_Line__c == sol.Id &&  sol.Sales_Order__r.Recurrence_Start_Date__c == null && sol.Sales_Order__r.Billing_UOM__c != null) {
						DateTime recStartDateSO = sol.Price_Type__c == 'Recurring' ? f.Start_Date__c : f.Fulfillment_Date__c;
						if(!mSOs.containsKey(sol.Sales_Order__c)) {

							mSOs.put(sol.Sales_Order__c, new Sales_Order__c(Id = sol.Sales_Order__c, Recurrence_Start_Date__c = recStartDateSO));
						} else {
							DateTime recStartDateOnSO = mSOs.get(sol.Sales_Order__c).Recurrence_Start_Date__c;
							if(recStartDateOnSO > recStartDateSO)
								mSOs.put(sol.Sales_Order__c, new Sales_Order__c(Id = sol.Sales_Order__c, Recurrence_Start_Date__c = recStartDateSO));
						}



					}
				}
				system.debug('mSOs '+mSOs);
				if(!mSOs.isEmpty())
					DML.updateAsUser(mSOs.values());

			}
		}


	}

	//Function returns true if an active approval process is defined for Sales Order object
	public static boolean checkifApprovalProcessDefined(){

	  boolean isApprovalProcessDefined = false;
	  Set<String> objectName = new Set<String>();

	  if (KSE.NamespaceUU != ''){
		  objectName.add(KSE.NamespaceUU+'Sales_Order__c');
	  }
	  else{
		  objectName.add('Sales_Order__c');
	  }

	  /*
	  //Dont check for Admin profile
	  Boolean isAdmin = false;
	  Id profileId=userinfo.getProfileId();
	  String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
	  if(profileName != null && profileName.equalsIgnoreCase('System Administrator')){
		  isAdmin = true;
	  }
	  */
	  List<ProcessDefinition> ProcessDefinitionList = [SELECT TableEnumOrId FROM ProcessDefinition WHERE State = 'Active' and TableEnumOrId in :objectName] ;
	  //if(!isAdmin && ProcessDefinitionList.size() > 0) { //dont check if it is admin and bypass for admins. Lets check for this condition case by case on individual processes
	  if(ProcessDefinitionList.size() > 0) {
		isApprovalProcessDefined = true;
	  }
	  return isApprovalProcessDefined;

	}

	private static set<String> cachedContext{
		get {
			if (cachedContext == null){
				cachedContext = new set<String>();
			}
			return cachedContext;
		}
		set;
	}


	public static Integer controlSize = 1;
	public static boolean ignoreInsert = true;

	// Created for the purpose of debugging record transition in trigger context during apex tests and sometimes not.
	// Restrictions exist to avoid cluttering logs
	public static void debugTriggerContext( Set<string> checkChangingFields ){

		String bodyString = '';
		String titleString = '';

		// by default, will ignore inserts. Turn on on demand. If fields provided, always show for insert as well
		if ( Trigger.isUpdate || ((checkChangingFields != null && !checkChangingFields.isEmpty()) || (Trigger.isInsert && !ignoreInsert))) {

			titleString = '\n\n-~+~- Trigger Context: ';

			if ( Trigger.isAfter ) titleString += 'After ';
			if ( Trigger.isBefore ) titleString += 'Before ';

			if ( Trigger.isInsert ) titleString += 'Insert ';
			if ( Trigger.isUpdate ) titleString += 'Update ';
			if ( Trigger.isDelete ) titleString += 'Delete ';

			try {

				// controlSize limits the max number of trigger records to derive context from. Fixed at 1, increase on-demand. Loop will take the min between set value at trigger list size.
				// If no positive value defined, set to trigger.new
				// if checkChangingFields specified, show all trigger values.
				List<sobject> sobjList = new List<sobject>();
				if ( controlSize > 0 ) { // && (checkChangingFields == null || checkChangingFields.isEmpty())
					for ( Integer i = 0; i < Math.min( controlSize, Trigger.size ); i++ ) {
						sobjList.add( trigger.new[ i ] );
					}
				}
				else {
					sobjList = trigger.new;
				}

				System.debug( logginglevel.error, '~*~ sobjList.size() :' + sobjList.size() );

				if ( checkChangingFields == null ) checkChangingFields = new Set<String>();

				if ( checkChangingFields.isEmpty() ) {
					sObject s = Trigger.new[ 0 ];
					s.getSObjectType().getDescribe().getName();
					checkChangingFields.addAll( new SchemaUtil().getAllCustomFieldsFromObject( null, Trigger.new[ 0 ].getSObjectType().getDescribe().getName() ) );
				}

				System.debug( logginglevel.error, '~*~ checkChangingFields.size() :' + checkChangingFields.size() );
				for ( sobject record : sobjList ) {

					if ( Trigger.isInsert ) {
						bodyString += '\nRecord trigger Context - New' + record.getSObjectType().getDescribe().getName();
					}
					else {
						bodyString += '\nRecord trigger Context - ' + record.get( 'name' );
					}

					String newValues = '';
					String oldValues = '';

					for ( String field : checkChangingFields ) {

						String value = record.getSObjectType() + ((String) record.get( 'Id' )) + field + record.get( field );

						if ( !cachedContext.contains( value ) ) {
							if ( KSE.isFieldChanging( field, record, Trigger.oldMap ) ) {
								if ( Trigger.isUpdate ) {
									oldValues += '\n\t\t  [' + field + '] ' + Trigger.oldMap.get( record.Id ).get( field ) + ' ==> ' + record.get( field );
								}
								else if ( Trigger.isInsert ) {
									if ( record.get( field ) != null ) {
										newValues += '\n\t\t  [' + field + '] null ==> ' + record.get( field );
									}
								}
							}

							cachedContext.add( value );
						}
					}

					// clear bodyString if no content since it's clutter
					Integer strValuesLength = newValues.length() + oldValues.length();
					if ( strValuesLength > 0) {
						bodyString += newValues + oldValues;
						bodyString += '\n';
					} else {
						bodyString = '';
					}
				}
			} catch (exception ex ){
				System.debug( logginglevel.error, '~*~ :' + ex.getMessage() + '\n' + ex.getStackTraceString() );
			}
		}

		if (bodyString.length() > 0){
			System.debug( logginglevel.error, titleString + bodyString  );
		}
	}

}