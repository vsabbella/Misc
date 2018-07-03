public with sharing class AllowanceService {

	public class AllowanceServiceException extends Exception {}

	/*
	*   Called from SOL/SO Trigger on field change.
	*   Only SOL Trigger call with have solFulQtyMap populated.
	*/
	public static void validateAllowancesApplied(List<Id> soIds, Map<Id, Decimal> solFulQtyMap) {
		//System.debug(loggingLevel.Error, '*** AllowanceService.validateAllowancesApplied: ');

		// Skip Allowance logic for normal testing because of test limits.
		if (Test.isRunningTest() && !AllowanceRuleService.testAllowances) {
			return;
		}

		Map<Id, Sales_Order__c> soMap = new Map<Id, Sales_Order__c>();
		Map<id, List<Sales_Order_Line__c>> solListBySoMap = new Map<id, List<Sales_Order_Line__c>>();
		List<Allowance_Applied__c> existingAllowance = new List<Allowance_Applied__c>();

		if ( soIds[0].getSObjectType() == Sales_Order__c.getSObjectType() ) {

			// Get Header Level details + related AA records
			SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
			soql.addFields(AllowanceRuleService.salesOrderFields);
			soql.setWhereClause('Id IN :soIds and Status__c != \'Cancelled\'');

			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Allowances_Applied__r');
			childRel.addFields(AllowanceRuleService.allowanceAppliedFields);
			soql.addChildRelationship(childRel);
			List<Sales_Order__c> soList = Database.query(soql.getQuery());

			for (Sales_Order__c so : soList) {
				soMap.put(so.id, so);

				// populate existing allowances for validation/recalc
				existingAllowance.addAll(so.Allowances_Applied__r);
			}

			// Get Line Level details + related AA records
			SOQLUtil solSoql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
			solSoql.addFields(AllowanceRuleService.salesOrderLineFields);
			solSoql.setWhereClause('Sales_Order__c IN :soIds and Status__c != \'Cancelled\''); // SO IN : Ids (sales order ids)

			SOQLUtil.ChildRelationship solChildRel = new SOQLUtil.ChildRelationship(solSoql, 'Allowances_Applied__r');
			solChildRel.addFields(AllowanceRuleService.allowanceAppliedFields);
			solSoql.addChildRelationship(solChildRel);
			List<Sales_Order_Line__c> soLineList = Database.query(solSoql.getQuery());

			for (Sales_Order_Line__c sol : soLineList) {

				if (!solListBySoMap.containskey(sol.Sales_Order__c)) {
					solListBySoMap.put(sol.Sales_order__c, new List<Sales_Order_Line__c>() );
				}
				solListBySoMap.get(sol.Sales_Order__c).add(sol);

				// populate existing allowances for validation/recalc
				existingAllowance.addAll(sol.Allowances_Applied__r);
			}
		}

		if (!soMap.values().isEmpty() && !solListBySoMap.values().isEmpty()) {
			validateAndApplyAllowances(soMap, solListBySoMap, existingAllowance, solFulQtyMap);
		}
	}


	public static void previewNewPrice(Sales_Order__c so, List<Sales_Order_Line__c> solList){
		AllowanceApplicator applicator = new AllowanceApplicator(so, solList);
		applicator.previewNewPrice();
	}

	public static void validateAndApplyAllowances(Map<Id, Sales_Order__c> soMap, Map<Id, List<Sales_Order_Line__c>> solListBySoMap, List<Allowance_Applied__c> existingAllowance, Map<Id, Decimal> solFulQtyMap) {
		AllowanceApplicator applicator = new AllowanceApplicator(soMap, solListBySoMap, existingAllowance, solFulQtyMap);
		applicator.validateAndApply();
	}

	// called from Visualforce page to get all the manual rules for an order, could be header or line so we need to perform different queries.
	// This code is a bit messy since the matching algorythim is broken up into several methods and deserves to be re-factored
	public static List<Allowance_Rule__c> loadManualRules( Id soid ) {
		List<Allowance_Rule__c> ret = new list<Allowance_Rule__c>();

		if ( soid.getSObjectType() == Sales_Order__c.getSObjectType() ) {

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
			soql.addFields(AllowanceRuleService.salesOrderFields);
			soql.setWhereClause('id = :soid');
			soql.setLimit(1);
			SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Sales_Order_Lines__r');
			childRel.addFields(AllowanceRuleService.salesOrderLineFields);
			soql.addChildRelationship(childRel);
			Sales_Order__c so = Database.query(soql.getQuery());

			AllowanceApplicator applicator = new AllowanceApplicator(
			    new Map<Id, Sales_Order__c>( new List<Sales_Order__c> {so} ),
			    new Map<id, Sales_Order_Line__c[]> { so.id => so.Sales_Order_Lines__r },
			    null, null
			);

			for (Allowance_Rule__c ar : applicator.fetchManualAllowances() ) {
				if (ar.Allowance_Type__r.Apply_At_Header__c == true) {
					ret.add(ar);
				}
			}
		} else if ( soid.getSObjectType() == Sales_Order_Line__c.getSObjectType() ) {

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(AllowanceRuleService.salesOrderLineFields);
			soql.setWhereClause('id = :soid');
			soql.setLimit(1);

			List<Sales_Order_Line__c> solList = (List<Sales_Order_Line__c>) Database.query(soql.getQuery());
			Sales_Order__c so = solList[0].Sales_Order__r;

			AllowanceApplicator applicator = new AllowanceApplicator(
			    new Map<Id, Sales_Order__c>(new List<Sales_Order__c> {so} ),
			    new Map<id, Sales_Order_Line__c[]> { so.Id => solList },
			    null, null
			);

			for (Allowance_Rule__c ar : applicator.fetchManualAllowances() ) {
				if (ar.Allowance_Type__r.Apply_At_Header__c == false) {
					ret.add(ar);
				}
			}
		}
		return ret;
	}

	public static set<String> nonInvoiceableSOTypes = new Set<String> {SalesOrderService.SO_TYPE_RESALE};

	/*
	* AA Trigger logic to prevent CRUD if it has SO/SOL is completed Invoiced.
	*/
	public static void validateInvoicedStatus(List<Allowance_Applied__c> aaList, Set<Id> aaSoIds, Set<Id> aaSolIds) {


		// Filter out AAs that don't have closed lines
		Set<Id> closedSOSOL = new Set<Id>();

		Map<Id, String> referenceNameMap = new Map<Id, String>();

		// necessary to run two queries to captures all scenarios. Only references retrieved from Allowance Applied records. Considering only SO refs, only SOL refs, both sol and so refs, both sol and so refs where the sol's so aren't in the so ref list. Need to query both...


		Boolean secondQuery = true;
		set<Id> captured = new set<id>();

		if (!aaSolIds.isEmpty()) {
			SOQLUtil solQuery = new SOQLUtil('Sales_Order_Line__c', true);
			solQuery.setWhereClause('Id IN: aaSolIds');
			solQuery.addFields(AllowanceRuleService.salesOrderLineFields);

			List<Sales_Order_Line__c> solList = Database.query(solQuery.getQuery());
			for (Sales_Order_Line__c sol : solList) {

				if (!referenceNameMap.containsKey(sol.Id)) {
					referenceNameMap.put(sol.Id, sol.Name);
				}
				if (!referenceNameMap.containsKey(sol.Sales_Order__c)) {
					referenceNameMap.put(sol.Sales_Order__c, sol.Sales_Order__r.Name);
				}

				// Ignore Resale for Winter. Support this for Spring 17.
				if (nonInvoiceableSOTypes.contains(sol.Sales_Order__r.Type__c)) {
					aaSolIds.remove(sol.Id);
					aaSoIds.remove(sol.Sales_Order__c);
				}

				if (sol.Status__c == 'Closed') {
					closedSOSOL.add(sol.id);
				}

				captured.add( sol.Sales_Order__c );
				if ( !closedSOSOL.contains(sol.Sales_Order__c) && sol.Sales_Order__r.Status__c == 'Closed') {
					closedSOSOL.add(sol.id);
				}
			}
		}

		// clone so Ids and remove all from captured (so id & status captured from SOLs)
		Set<Id> soDiffSet = aaSoIds.clone();
		soDiffSet.removeAll(captured);

		if (!soDiffSet.isEmpty()) {
			SOQLUtil soQuery = new SOQLUtil('Sales_Order__c', true);
			soQuery.setWhereClause('Id IN: soDiffSet');
			soQuery.addFields(AllowanceRuleService.salesOrderFields);

			SOQLUtil.ChildRelationship childSolQuery = new SOQLUtil.ChildRelationship(soQuery, 'Sales_Order_Lines__r');
			childSolQuery.addFields(AllowanceRuleService.salesOrderLineFields);
			soQuery.addChildRelationship(childSolQuery);

			List<Sales_Order__c> soList =  Database.query(soQuery.getQuery());
			for (Sales_Order__c so : soList) {
				//System.debug(loggingLevel.Error, '*** so: ' + so);

				if (!referenceNameMap.containsKey(so.Id)) {
					referenceNameMap.put(so.Id, so.Name);
				}

				if (nonInvoiceableSOTypes.contains(so.Type__c)) {
					aaSoIds.remove(so.Id);
				}

				if (so.Status__c == 'Closed') {
					closedSOSOL.add(so.id);
				}

				for (Sales_Order_Line__c sol : so.Sales_order_Lines__r) {
					//System.debug(loggingLevel.Error, '*** sol: ' + sol);
					if (!referenceNameMap.containsKey(sol.Id)) {
						referenceNameMap.put(sol.Id, sol.Name);
					}
					if (sol.Status__c == 'Closed') {
						closedSOSOL.add(sol.id);
					}
				}
			}
		}


		// collect all the closed SO ids and SOL ids. If lines or headers are closed, we can then check to see if the fulfillments have been invoiced completely

		Boolean checkFulfillments = false;
		for (Allowance_Applied__c aa : aaList) {
			if (closedSOSOL.contains(aa.Sales_Order__c) || closedSOSOL.contains(aa.Sales_Order_Line__c)) {
				checkFulfillments = true;
				break;
			}
		}

		if (!checkFulfillments) {
			return;
		}

		// using (IGR) invoice group rules service to fetch fulfillments that are ready for invoicing. If no fulfillments found - assume invoiced.
		InvoiceGroupingRuleService igrs = new InvoiceGroupingRuleService();
		DateTime timeNow = system.now();
		string  allowanceAccrual = AllowanceRuleService.ALLOWANCE_ACCRUAL;

		String query = SchemaUtil.getInstance().generateQueryFromFieldSet('Fulfillment__c', new set<String> {}, igrs.getFieldsForFulfillment(), igrs.getWhereClause());
		query += 'and (Sales_Order_Line__c IN: aaSolIds or Sales_Order__c IN: aaSoIds)';

		// KNDY-20174 - In the scenario where SH is confirmed and the fulfilment is set to onhold to prevent being invoiced, we cannot update the AA override amt.
		// 				To Fix this, we move omit the invoice on hold condition. In the future, more conditions might be placed to allow updating allowances where
		//				the invoicing is "paused"
		Set<String> conditionsToRemove = new Set<String>{
				'and Invoice_Hold__c = false'
		};

		for (String condition : conditionsToRemove) {
			query = query.replace( condition, '' );
		}


		// populate sets of SO and SOL that are invoiceable - meaning, we can modify allowances on them
		Set<Id> solIds = new Set<Id>();
		Set<Id> soIds = new Set<Id>();

		for (Fulfillment__c ful : (List<Fulfillment__c>) Database.query(query)) {
			solIds.add(ful.Sales_Order_Line__c);
			soIds.add(ful.Sales_Order_Line__r.Sales_Order__c);
		}

		for (Allowance_Applied__c aa : aaList) {
			// IF so/SOL is closed AND if we CANNOT no fulfillments are found for invoicing, then the SO or SOL is completely invoiced.
			// SO or SOL, relative to AA, must be closed. Checks that all lines are fulfilled before checking if they're avialable for invoicing
			if (closedSOSOL.contains(aa.Sales_Order__c) && !soIds.contains(aa.Sales_Order__c) ) {
				aa.addError('Cannot create/update allowance. Sales Order is completely invoiced. ' + referenceNameMap.get(aa.Sales_Order__c));
			}
			if (closedSOSOL.contains(aa.Sales_Order_Line__c) && !solIds.contains(aa.Sales_Order_line__c)) {
				aa.addError('Cannot create/update allowance. Sales Order Line is completely invoiced. ' + referenceNameMap.get(aa.Sales_Order_Line__c));
			}
		}
	}

	/*
	* copies existing SO allowances to another SO Order. Used in Adjustments, RMA Orders.
	*/
	public static void copyAllowancesFromDocument(Map<Id, Id> fromToMap) {

		Map<Id, Id> salesOrders = new Map<Id, Id>();
		Map<Id, Id> solines = new Map<Id, Id>();

		for (Id oldId : fromToMap.keyset()) { // keyset is the original Order
			Id newId = fromToMap.get(oldId);

			if (oldId == null || newId == null) continue;

			if (oldId.getSObjectType() == Sales_Order__c.getSObjectType() && newId.getSObjectType() == Sales_Order__c.getSObjectType()) {
				salesOrders.put(oldId, newId);
			} else if (oldId.getSObjectType() == Sales_Order_Line__c.getSObjectType() && newId.getSObjectType() == Sales_Order_Line__c.getSObjectType()) {
				solines.put(oldId, newId);
			} else {
				throw new AllowanceServiceException('Unknown Id type passed when copying Allowance.');
			}
		}


		Set<Id> oldSOIds = salesOrders.keySet(); // old order Ids
		if (oldSOIds.isEmpty()) return; // Return - No related Ids

		// query fromDoc allowances mapped to source doc Id.
		SOQLUtil soql = new SOQLUtil('Allowance_Applied__c', true); //enforceFLS=true, running in user mode
		soql.addFields(AllowanceRuleService.allowanceAppliedFields);

		soql.setWhereClause('Sales_Order__c in :oldSOIds OR Sales_Order_Line__r.Sales_Order__c in :oldSOIds');
		List<Allowance_Applied__c> existingAA = Database.query(soql.getQuery());

		if (existingAA.isEmpty()) return; // Return - No Allowances

		List<Allowance_Applied__c> aaForInsert = new List<Allowance_Applied__c>();

		Set<Id> rmaSOIds = new Set<Id>(salesOrders.values());
		Set<id> rmaSOLineIds = new Set<Id>(solines.values());

		SOQLUtil soSoql = new SOQLUtil('Sales_Order__c', true); //enforceFLS=true, running in user mode
		soSoql.addFields(AllowanceRuleService.salesOrderFields);
		soSoql.setWhereClause('id = :rmaSOIds');
		soSoql.setLimit(1);
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soSoql, 'Sales_Order_Lines__r');
		childRel.addFields(AllowanceRuleService.salesOrderLineFields);
		soSoql.addChildRelationship(childRel);
		Map<Id, Sales_Order__c> rmaSalesOrderMap = new Map<Id, Sales_Order__c>( (List<Sales_Order__c>) Database.query(soSoql.getQuery()));

		SOQLUtil solSoql = new SOQLUtil('Sales_Order_Line__c', true); //enforceFLS=true, running in user mode
		solSoql.addFields(AllowanceRuleService.salesOrderLineFields);
		solSoql.setWhereClause('id = :rmaSOLineIds');
		Map<Id, Sales_Order_Line__c> rmaSOLineMap = new Map<Id, Sales_Order_Line__c>( (List<Sales_Order_Line__c>) Database.query(solSoql.getQuery()));

		// Construct AA using original SO Id ATs and RMA order info
		for (Allowance_Applied__c sourceAA : existingAA) {
			//Allowance_Applied__c clonedAA = aa.clone(false, true);

			if (!AllowanceRuleService.typesForInvoicing.contains(sourceAA.Allowance_Type__r.Type__c)) continue;

			Sales_Order__c salesOrder;
			//Sales_Order_Line__c soLine;
			List<Sales_Order_Line__c> allSOLines;

			if (sourceAA.Sales_Order__c != null) {
				Id rmaSOID = fromToMap.get(sourceAA.Sales_Order__c);
				salesOrder = rmaSalesOrderMap.get(rmaSOID);
				allSOLines = salesOrder.Sales_Order_Lines__r;
			}

			if (sourceAA.Sales_Order_Line__c != null) {
				Id rmaSOLineId = fromToMap.get(sourceAA.Sales_Order_Line__c);
				if (!rmaSOLineMap.containsKey(rmaSOLineId)) {
					continue; // skip b/c no rma qty specified for this line. So the rmaSOLineId wont be in the rmaSOLineMap
				}
				allSOLines = new List<Sales_Order_Line__c> { rmaSOLineMap.get(rmaSOLineId) };
				salesOrder = allSOLines[0].Sales_Order__r;
			}

			if (allSOLines == null ) {
				throw new AllowanceServiceException('Cannot find Id type passed when copying Allowance.');
			}

			Allowance_Applied__c tmpAA = new AllowanceCalcService.AllowanceCreation(
			    new AllowanceRuleService.RuleContext(
			        sourceAA.Allowance_Rule2__r,
			        allSOLines,
			        sourceAA.Override_Value__c
			    )
			).getAllowanceRecord();

			aaForInsert.add(tmpAA);
		}

		if (!aaForInsert.isEmpty()) {
			insert aaForInsert;
		}
	}

	/*
	* Copy allowances from SO/SOL to CI/CIL and recalculate the amounts.
	* CustomerInvoiceBatch when new invoices are created
	*/
	public static void copyAllowancesFromOrderToInvoice ( Set<Id> cilIdSet, Set<Id> soIdSet, Set<Id> ciSubLineId, Map<Id, Fulfillment__c> oldFulfillmentMap) {

		/* QUERY SO and SOL and collect the Manual Allowance Types.
		Check if there is a Non-standard allowance and if there is, check for one-time.
		When appling the allowance type to the allowance applied, recalculate based on the CI and CIL
		*/

		Map<id, List<Allowance_Applied__c>> soLinesAllowances = new Map<id, List<Allowance_Applied__c>>();
		Map<id, List<Allowance_Applied__c>> soAllowances = new Map<id, List<Allowance_Applied__c>>();
		// get all AA records on SO included nested AA on AA record
		SOQLUtil aaSoql = new SOQLUtil('Allowance_Applied__c', true); //enforceFLS=true, running in user mode
		aaSoql.addFields(AllowanceRuleService.allowanceAppliedFields);
		aaSoql.addFields(new set<string> {'id'});
		aaSoql.setWhereClause('Sales_Order__c in :soIdSet OR Sales_Order_Line__r.Sales_Order__c in :soIdSet');

		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(aaSoql, 'Allowances_Applied__r');
		childRel.addFields(AllowanceRuleService.allowanceAppliedFields);
		childRel.setWhereClause('Source__c!=\'Trade\' and Customer_Invoice_Line__r.Customer_Invoice__r.Status__c NOT IN  (\'Void\',\'Cancelled\')' ); //KNDY-6032 //Allowance_Type__r.Manual__c = true AND
		aaSoql.addChildRelationship(childRel);

		for (Allowance_Applied__c aa : (List<Allowance_Applied__c>) Database.query( aaSoql.getQuery() )) {
			if (aa.Sales_Order_Line__c != null) {
				if (!soLinesAllowances.containsKey(aa.Sales_Order_Line__c)) {
					soLinesAllowances.put(aa.Sales_Order_Line__c, new List<Allowance_Applied__c>());
				}
				soLinesAllowances.get(aa.Sales_Order_Line__c).add(aa);

			} else if (aa.Sales_Order__c != null) {
				if (!soAllowances.containsKey(aa.Sales_Order__c)) {
					soAllowances.put(aa.Sales_Order__c, new List<Allowance_Applied__c>());
				}
				soAllowances.get(aa.Sales_Order__c).add(aa);
			}
		}

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil cilSoql = new SOQLUtil('Customer_Invoice_line__c', true); //enforceFLS=true, running in user mode
		cilSoql.addFields(AllowanceRuleService.customerInvoiceLineFields);
		cilSoql.setWhereClause('Id IN:cilIdSet and Customer_Invoice__r.Invoice_Type__c != \'' + AllowanceRuleService.ALLOWANCE_ACCRUAL + '\'');
		cilSoQl.setOrderByClause('Name ASC');
		Customer_Invoice_Line__c[] ciLines = Database.query(cilSoql.getQuery());

		/* general maps for data mapping */
		Map<Id, List<Customer_invoice_Line__c>> ciLinesByHeaderMap = new Map<Id, List<Customer_invoice_Line__c>>();
		Map<Id, List<Sales_Order_Line__c>> solListMap = new Map<Id, List<Sales_Order_Line__c>>();

		/* For inserting */
		// upsert list using unique_key includes one-time manual and automatic allowances
		Map<String, Allowance_Applied__c> uniqueKeyAllowances = new Map<String, Allowance_Applied__c>();
		// no key; for non manual excluding one-time
		List<Allowance_Applied__c> manualAAForInsert = new List<Allowance_Applied__c>();


		/* variables for determining One-Tme allowance type */
		Map<Id, List<Allowance_Applied__c>> oneTimeAA = new Map<Id, List<Allowance_Applied__c>>();

		/* variables for allowance splitting */
		// tmp allowances list by CIL header. Allowances aren't inserted. Stored to split into CILs
		Map<Id, List<Allowance_Applied__c>> newHdrAllowancesToSplit = new Map<Id, List<Allowance_Applied__c>>();
		Map<Allowance_Applied__c, Allowance_Applied__c> soAAToTmpAA = new Map<Allowance_Applied__c, Allowance_Applied__c>();

		// use this map to track current allowances during partials pre-invoicing to track consumations
		Map<Id, List<Allowance_Applied__c>> currentRelatedAllowances = new Map<Id, List<Allowance_Applied__c>>();


		for (Customer_Invoice_Line__c cil : ciLines) {

			if (!solListMap.containsKey(cil.Sales_Order__c)) {
				solListMap.put(cil.Sales_Order__c, new List<Sales_Order_Line__c>());
			}
			solListMap.get(cil.Sales_Order__c).add(cil.Sales_Order_Line__r);

			// useing Map: CI to CILs to track total lines
			if (!ciLinesByHeaderMap.containsKey(cil.Customer_Invoice__c)) {
				ciLinesByHeaderMap.put(cil.Customer_Invoice__c, new List<Customer_Invoice_Line__c>());
			}
			ciLinesByHeaderMap.get(cil.Customer_Invoice__c).add(cil);
		}

		// used to avoid adding header allowances multiple times
		Set<Id> capturedCIs = new Set<Id>();

		Map <Id, List<Allowance_Applied__c>> soHdrRelatedAllowances = new Map <Id, List<Allowance_Applied__c>>();

		for ( Customer_Invoice_Line__c cil :  ciLines) {

			if (!capturedCIs.contains(cil.Customer_invoice__c) && soAllowances.containsKey(cil.Sales_Order__c)) {
				capturedCIs.add(cil.Customer_invoice__c);

				for (Allowance_Applied__c soAA : soAllowances.get(cil.Sales_order__c)) {

					if (!AllowanceRuleService.typesForInvoicing.contains(soAA.Allowance_Type__r.Type__c)) continue;

					Allowance_Applied__c tmpAA = new AllowanceCalcService.AllowanceCreation(
					    new AllowanceRuleService.RuleContext(
					        soAA.Allowance_Rule2__r,
					        ciLinesByHeaderMap.get(cil.Customer_invoice__c),
					        soAA.Override_Value__c
					    )
					).getAllowanceRecord();
					// collect for use later to retrieve fulfillments for creating one-time key

					tmpAA.Allowance_Applied__c = soAA.Id;
					// populate header allowances by CI header ID to split to the lines
					if (!newHdrAllowancesToSplit.containsKey(cil.Customer_Invoice__c)) {
						newHdrAllowancesToSplit.put(cil.Customer_Invoice__c, new List<Allowance_Applied__c>());
					}

					soHdrRelatedAllowances.put(soAA.Id, soAA.Allowances_Applied__r);

					newHdrAllowancesToSplit.get(cil.Customer_Invoice__c).add(soAA);
					soAAToTmpAA.put(soAA, tmpAA);
				}
			}

			if (soLinesAllowances.containsKey(cil.Sales_Order_Line__c)) {

				for (Allowance_Applied__c solAA : soLinesAllowances.get(cil.Sales_Order_Line__c)) {

					if (!AllowanceRuleService.typesForInvoicing.contains(solAA.Allowance_Type__r.Type__c)) continue;

					Allowance_Applied__c tmpAA = new AllowanceCalcService.AllowanceCreation(
					    new AllowanceRuleService.RuleContext(
					        solAA.Allowance_Rule2__r,
					        new List<Customer_Invoice_Line__c> {cil},
					        solAA.Override_Value__c
					    )
					).getAllowanceRecord();

					tmpAA.Allowance_Applied__c = solAA.Id;
					tmpAA.Unique_Key__c = AllowanceRuleService.genUniqueKey(null, tmpAA, solAA, tmpAA.Allowance_Type__r);

					// collect for use later to retrieve fulfillments for creating one-time key
					if (tmpAA.Allowance_Type__r.One_Time__c) {
						if (!oneTimeAA.containsKey(cil.id)) {
							oneTimeAA.put(cil.id, new List<Allowance_Applied__c>());
						}
						oneTimeAA.get(cil.id).add(tmpAA);

					} else if (!tmpAA.Allowance_Type__r.Manual__c) {
						if (!uniqueKeyAllowances.containsKey(tmpAA.Unique_Key__c)) {
							uniqueKeyAllowances.put( tmpAA.Unique_Key__c, tmpAA);
						}
					} else {
						manualAAForInsert.add(tmpAA);
					}
				}
			}
		}

		// trickle header allowances down to lines for accounting
		for (Id ciId : ciLinesByHeaderMap.keyset()) {
			List<Customer_Invoice_Line__c> cilList = ciLinesByHeaderMap.get(ciId);
			Decimal headerTotalAmount = cilList[0].Customer_invoice__r.Total_Line_Amount__c;

			if (newHdrAllowancesToSplit.containskey(ciId)) {

				for (Allowance_Applied__c soAA : newHdrAllowancesToSplit.get(ciId)) {

					Allowance_Applied__c tmpCiAllowane = soAAToTmpAA.get(soAA);

					if (!AllowanceRuleService.typesForInvoicing.contains(soAA.Allowance_Type__r.Type__c)) continue;


					List<Allowance_Applied__c> currentRelatedList = new List<Allowance_Applied__c>();

					// used to ensure the whole header amount is distributed on the lines to avoid unconsumed amts due to rounding
					Decimal remainingHeaderAmt = tmpCiAllowane.Allowance_Amount__c;
					Decimal count = 1; // used to determine the last CIL. Consider using a different loop: indexed for loop

					Boolean consumedFlatAllowance = false;

					// if we see that one-time allowances are already applied on a different CI, skip this AA. Else we'll end up overwritting the original AA on the CILs through the unique key upsert
					if (soHdrRelatedAllowances.containsKey(tmpCiAllowane.Allowance_Applied__c)){
						if (tmpCiAllowane.Allowance_Type__r.One_Time__c && soHdrRelatedAllowances.get(tmpCiAllowane.Allowance_Applied__c).size() > 0){
							continue;
						}
					}

					if (tmpCiAllowane.Allowance_Type__r.Basis__c == AllowanceRuleService.BASIS_FLAT_AMOUNT
					        && soHdrRelatedAllowances.containsKey(tmpCiAllowane.Allowance_Applied__c)
					        &&  soHdrRelatedAllowances.get(tmpCiAllowane.Allowance_Applied__c).size() > 0
					   ) {
						consumedFlatAllowance = true;
					}

					if (currentRelatedAllowances.containsKey(tmpCiAllowane.Allowance_Applied__c) && !currentRelatedAllowances.get(tmpCiAllowane.Allowance_Applied__c).isEmpty()) {
						consumedFlatAllowance = true;
					}

					Integer intPrecision = PriceBookService.getRoundingPrecision();

					// apply AA for each CIL
					for (Customer_Invoice_Line__c cil : cilList) {

						// determine the SPLIT ratio for the CIL. If header Line Total Amount is 0, set multiplier to 1
						Decimal multiplier = headerTotalAmount != 0 ? (cil.Extended_Price__c / headerTotalAmount) : 1; // round multiplier to 4 decimal places

						Allowance_Applied__c lineAA = tmpCiAllowane.clone(false, true);

						// if allowances already created for flat basis, amt on new allowance will be 0.

						if ( consumedFlatAllowance || remainingHeaderAmt == 0) {
							lineAA.Allowance_Amount__c = 0;
						} else {

							// on the last CIL, apply the remaining header allowance amount to offset loss from rounding if any
							Decimal lineAllowanceAmount = (count == cilList.size()) ? remainingHeaderAmt : (tmpCiAllowane.Allowance_Amount__c * multiplier).setScale(intPrecision,
									RoundingMode.HALF_UP);

							lineAA.Allowance_Amount__c = lineAllowanceAmount;

							// to prevent loss of amount during rounding.
							remainingHeaderAmt -= lineAA.Allowance_Amount__c;
						}

						// update with CIL reference
						lineAA.Customer_Invoice2__c = null;
						lineAA.Customer_Invoice_Line__c = cil.Id;
						lineAA.Customer_Invoice_Line__r = cil; // this is necessary for One-time header allowanecs so the unique key generation will have reference to the SOL

						if (lineAA.Unique_Key__c != null) {
							// update unique key with new references


							lineAA.Unique_Key__c = AllowanceRuleService.genUniqueKey(null, lineAA, soAA, lineAA.Allowance_Type__r);

							uniqueKeyAllowances.put(lineAA.Unique_Key__c, lineAA);
						} else {
							manualAAForInsert.add(lineAA);
						}

						currentRelatedList.add(lineAA);
						count ++;

					}
					currentRelatedAllowances.put(tmpCiAllowane.Allowance_Applied__c, currentRelatedList);
				}
			}
		}

		// RETRIEVE CIL -> Fulfillment if Reacurring (or non-standard) Allowances found
		Map<Id, List<Fulfillment__c>> cilToFulfillments = new Map<Id, List<Fulfillment__c>>();

		if (!oneTimeAA.keySet().isEmpty()) {
			// CIL to Fulfillment Map

			// if these are null, the no fulfillments can be matched to Unique key. This is for One Time by fulfillment.
			if (ciSubLineId != null && !ciSubLineId.isEmpty()) {
				SOQLUtil ciSubLineList = new SOQLUtil('Customer_invoice_Sub_line__c', true); //enforceFLS=true, running in user mode
				ciSubLineList.addFields(new set<string> {
					'id', 'fulfillment__r.Sales_order__c', 'fulfillment__r.Parent_Fulfillment__c',
					'fulfillment__r.Sales_order_Line__c', 'Fulfillment__c', 'Customer_Invoice_Line__c'
				});
				ciSubLineList.setWhereClause('id in :ciSubLineId');

				for (Customer_invoice_Sub_line__c ciSubLine : Database.query(ciSubLineList.getQuery())) {
					if (!cilToFulfillments.containsKey(ciSubLine.Customer_Invoice_Line__c)) {
						cilToFulfillments.put(ciSubLine.Customer_Invoice_Line__c, new List<Fulfillment__c>());
					}

					cilToFulfillments.get(ciSubLine.Customer_Invoice_Line__c).add( ciSubLine.Fulfillment__r);
				}
			}

			// HEADER AA Logic
			for (Id cilId : oneTimeAA.keySet()) {
				for ( Allowance_Applied__c tmp : oneTimeAA.get(cilId) ) {

					if (!uniqueKeyAllowances.containsKey(tmp.Unique_Key__c)) {
						uniqueKeyAllowances.put( tmp.Unique_Key__c, tmp);
					}
				}
			}
		}

		if (manualAAForInsert.size() > 0) {
			DML.insertAsSystem(manualAAForInsert);
		}


		// upsert using Unique_Key__c
		if (uniqueKeyAllowances.values().size() > 0) {
			DML.checkUpsertAsUser(uniqueKeyAllowances.values()); upsert uniqueKeyAllowances.values() Unique_Key__c;
		}
	}

	/*
	*   Roll-up summary for SO/SOL/CI/CIL object with Allowance Applied records are inserted / updated
	*/
	public static void updateAllowanceAmmount(list<Allowance_Applied__c> aaList) {
		list<RollUpSummaryUtility.fieldDefinition> fieldDefinitionsNonTrade = new list<RollUpSummaryUtility.fieldDefinition> {
			new RollUpSummaryUtility.fieldDefinition('SUM', 'Allowance_Amount__c ', 'Allowances__c')
		};

		list<RollUpSummaryUtility.fieldDefinition> soLineFieldDefinition = new list<RollUpSummaryUtility.fieldDefinition> {
			new RollUpSummaryUtility.fieldDefinition('SUM', 'Allowance_Amount__c ', 'Allowances__c'),
			new RollUpSummaryUtility.fieldDefinition('SUM', 'BillBack_Commitment__c ', 'BillBack_Commitment__c')
		};


		boolean has_sales_order_line = false, has_sales_order = false, has_invoice_line = false, has_invoice = false;
		for (Allowance_Applied__c aa : aaList ) {
			if ( aa.Sales_Order__c != null) has_sales_order = true;
			if ( aa.Sales_Order_Line__c != null) has_sales_order_line = true;
			if ( aa.Customer_Invoice_Line__c != null) has_invoice_line = true;
			if ( aa.Customer_Invoice2__c != null) has_invoice = true;
		}

		String ALLOWANCE_NOT_APPLIED = Label.Allowance_not_applied;

		list <SObject> sobjectList = new list <SObject>();

		if (has_sales_order_line ) {

			list<Sales_Order_Line__c> soLines = new list<Sales_Order_Line__c>();

			list<Sales_Order_Line__c> nonTradeSolines = RollUpSummaryUtility.rollUpTrigger(soLineFieldDefinition,
			        aaList,
			        'Allowance_Applied__c',
			        'Sales_Order_Line__c',
			        'Sales_Order_Line__c',
			        'AND Source__c != \'Trade\'', //KNDY-6032
			        false
			                                                                              );
			soLines.addAll(nonTradeSolines);
			sobjectList.addAll(getLine(soLines));
		}

		if ( has_sales_order) {
			list <SObject> soList = RollUpSummaryUtility.rollUpTrigger(fieldDefinitionsNonTrade,
			                        aaList,
			                        'Allowance_Applied__c',
			                        'Sales_Order__c',
			                        'Sales_Order__c',
			                        'AND Source__c != \'Trade\' ' //KNDY-6032
			                        , false
			                                                          );

			sobjectList.addAll(soList);

		}

		//if ( has_invoice ) {
		//	list <SObject> ciList =
		//	    RollUpSummaryUtility.rollUpTrigger(fieldDefinitionsNonTrade,
		//	                                       aaList,
		//	                                       'Allowance_Applied__c',
		//	                                       'Customer_Invoice2__c',
		//	                                       'Customer_Invoice__c',
		//	                                       'AND Source__c != \'Trade\' ' //KNDY-6032
		//	                                       , false
		//	                                      );
		//	sobjectList.addAll(ciList);
		//}

		if (has_invoice_line) {

			list<Customer_Invoice_Line__c> ciLines = new list<Customer_Invoice_Line__c>();

			list<Customer_Invoice_Line__c> nonTradeCiLines =  RollUpSummaryUtility.rollUpTrigger(fieldDefinitionsNonTrade,
			        aaList,
			        'Allowance_Applied__c',
			        'Customer_Invoice_Line__c',
			        'Customer_Invoice_Line__c',
			        'AND Source__c != \'Trade\' ', //KNDY-6032
			        false);

			ciLines.addAll(nonTradeCiLines);

			sobjectList.addAll(getLine(ciLines));

		}

		list <Database.SaveResult> dbResultsList = DML.updateAsUser(sobjectList, false);

		for (Database.SaveResult dbResult : dbResultsList) {
			if (!dbResult.isSuccess()) {
				for (Database.Error dbError : dbResult.getErrors()) {
					throw new AllowanceServiceException( ALLOWANCE_NOT_APPLIED + dbError.getMessage() );
				}
			}
		}

//		Boolean hasErrors = ExceptionService.hasErrors;
//
//		if (hasErrors) {
//			JSONResult jsonResult = new JSONResult();
//			jsonResult.messages.addAll(ExceptionService.messages);
//			for (Map<String, String> msg : jsonResult.messages) {
//				system.debug(logginglevel.error, 'Errors found: ' + msg);
//				if (msg.containsKey('message')) {
//					System.debug( logginglevel.error, '~*~  message:' +  msg.get('message'));
//					throw new AllowanceServiceException( msg.get( 'message' ) );
//				}
//			}
//		}
	}

	/*
	*   Combines Allowance amounts from lines with the same Id. Helper method of updateAllowanceAmmount method
	*/
	public static list<SObject> getLine(list<SObject> objLines) {
		Map<id, SObject> objectAllowanceMap = new Map<id, SObject>();

		SObject tmpLine = null;

		for (SObject line : objLines) {
			if (!objectAllowanceMap.containsKey(line.id))
				objectAllowanceMap.put(line.id, line);
			else {
				tmpLine = objectAllowanceMap.get(line.id);

				if (line.id.getSobjectType() == Sales_Order_Line__C.getSobjectType() || line.id.getSobjectType() == Customer_Invoice_Line__c.getSobjectType()) {

					if (line.get('Allowances__c') != null) {
						Decimal allowances = Decimal.valueOf(String.valueOf(line.get('Allowances__c')));
						tmpLine.put('Allowances__c', allowances);
					}
				}
				objectAllowanceMap.put(line.id, tmpLine);
			}
		}
		return objectAllowanceMap.values();
	}
}