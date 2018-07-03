public with sharing class AllowanceApplicator {

	public class AllowanceApplicatorException extends Exception {}

	// used to prevent recursive loop through Allowances when updating SOL in SOL Trigger
	public static Set<Id> skipSOLTrigger = new Set<Id>();

	private AllowanceRuleService.RuleContext[] rulesContext = new AllowanceRuleService.RuleContext[] {};

	// Mapped SO/SOL/SOLs info for easy calling
	private Map<String, Sales_Order__c> soMap = new Map<String, Sales_Order__c>();
	private Map<String, Sales_Order_Line__c[]> solBySoIdMap = new Map<String, Sales_Order_Line__c[]>();
	private Map<String, sales_Order_Line__c> solMap = new Map<String, sales_Order_Line__c>();

	private Map <String, Allowance_Applied__c> existingAutoAllowanceKeys = new Map <String, Allowance_Applied__c>();
	private Map <String, List<Allowance_Applied__c>> existingManualAllowancesByKey = new Map <String, List<Allowance_Applied__c>>();
	private List <Allowance_Applied__c> existingAllowances;

	// Used for validating existing allowances using: Key: SO/SOL - AR - AT
	private Set<String> validAllowancesKey = new Set<String>();

	//  Used for populating Accrual Fulfillments
	public Map<Id, Decimal> solFulQtyMap;
	// list of accrual Allowances on SO. Populated post validate.
	public Map<Id, Allowance_Applied__c> accrualAllowances = new Map<Id, Allowance_Applied__c>();

	public List<Allowance_Applied__c> allowancesForUpsert = new List<Allowance_Applied__c>();

	public List<Sales_order_line__c> newPricedLines = new List<Sales_order_line__c>();

	private String soConstruct = 'soStub1';

	// default blocks auto allowances from applying on SO_BLOCKED_SO_TYPES_FOR_AUTO_ALLOWANCE
	public Boolean overrideAutoBlock {
		get { return false; }
		set;
	}

	// Preview allowance / inquiry page
	public AllowanceApplicator ( Sales_Order__c so, Sales_Order_Line__c[] solList){

		String key = so.Id == null ? soConstruct : so.Id;
		this.soMap = new Map<String, Sales_Order__c>{ key => so};
		this.solBySoIdMap = new Map<String, Sales_Order_Line__c[]> {key => solList};

		this.existingAllowances = new List <Allowance_Applied__c>();
		this.solFulQtyMap = new Map<Id, Decimal>();

		for (Sales_Order_Line__c sol : solList){
			sol.Sales_Order__r = so;
			solMap.put( sol.Line__c.format(), sol);
		}

		System.debug( logginglevel.error, '~*~ soMap :' + soMap );
		System.debug( logginglevel.error, '~*~ solMap :' + solMap );

	}

	/* Actual Allowance */
	public AllowanceApplicator( Map<Id, Sales_Order__c> soIdMap,
	                            Map<id, Sales_Order_Line__c[]> solBySoIdMap,
	                            List<Allowance_Applied__c> existingAllowances,
	                            Map<Id, Decimal> solFulQtyMap) {

		for (Id id : soIdMap.keySet()){
			this.soMap.put(String.valueOf(id), soIdMap.get(id));
		}

		for (Id id : solBySoIdMap.keySet()){
			this.solBySoIdMap.put(String.valueOf(id), solBySoIdMap.get(id));
		}

		this.existingAllowances = existingAllowances != null ? existingAllowances : new List <Allowance_Applied__c>();
		this.solFulQtyMap = solFulQtyMap != null ? solFulQtyMap : new Map<Id, Decimal>();

		for (List<Sales_Order_Line__c> solList : solBySoIdMap.values()) {
			for (Sales_Order_Line__c sol : solList) {
				solMap.put(String.valueOf(sol.id), sol);

				if (sol.New_Pricing_Rule__c != null) {
					newPricedLines.add( sol );
				}
			}
		}

		// take existing Allowances and split them into automatic allowances
		for (Allowance_Applied__c aa : this.existingAllowances) {
			if (!aa.Allowance_Type__r.Manual__c) {
				this.existingAutoAllowanceKeys.put(aa.Unique_Key__c, aa);
			} else {
				String key = AllowanceRuleService.getValidationKey(aa);

				if (!this.existingManualAllowancesByKey.containsKey(key)) {
					this.existingManualAllowancesByKey.put(key, new List<Allowance_Applied__c>());
				}

				this.existingManualAllowancesByKey.get(key).add(aa);
			}
		}
	}

	public List<Allowance_Rule__c> fetchManualAllowances() {
		System.debug(loggingLevel.Error, '*** fetchManualAllowances: ');
		matchAllowanceRules(true);

		List<Allowance_Rule__c> arList = new List<Allowance_Rule__c>();

		for (AllowanceRuleService.RuleContext ctx : rulesContext) {
			if (ctx.allowanceType.Manual__c) {
				arList.add(ctx.allowanceRule);
			}
		}

		return arList;
	}

	public void previewNewPrice() {
		if (soMap.values().isEmpty() || solMap.values().isEmpty()){
			return;
		}

		// Matches Allowance Rules to SO/SOL
		matchAllowanceRules(false);

		prioritizeAndSortRules();

		applyNewPriceAllowances(false);

		System.debug( logginglevel.error, '~*~ solMap :' + solMap );
	}

	public void validateAndApply() {
		System.debug(loggingLevel.Error, '*** ValidateAndApply START: ');

		if (soMap.values().isEmpty() || solMap.values().isEmpty()){
			return;
		}

		// Matches Allowance Rules to SO/SOL
		matchAllowanceRules(false);

		prioritizeAndSortRules();

		applyNewPriceAllowances(true);

		// used for validation and creates auto allowances depending on SO Type
		constructAllowances();

		// Deletes invalid allowances
		validateExistingAllowances();

		// Inserts new allowances and Updates existing ones (including manual)
		apply();

		// Inserts fulfillments
		accrualFulfillments();

		System.debug(loggingLevel.Error, '*** Validate FINISH: ');
	}

	/*
	* Match Allowance Rules from allowancesRulesByKeys with the Object records (so, sol)
	* and create Allowance Applied records using applicator.allowancAapplied
	* used to be generateAllowances, mapAllowanceRules
	*/
	private void matchAllowanceRules(Boolean manualOnly) {

		AllowanceRuleMatcher matchMaker = new AllowanceRuleMatcher(soMap.values(), solBySoIdMap.values(), manualOnly);

		for (Sales_order__c so : soMap.values()) {
			// All Invoice lines for this header

			Sales_order_line__c[] soLines = new Sales_order_Line__c[] {};

			if (so.Id == null && soMap.values().size() == 1){
				if (solBySoIdMap.containsKey(soConstruct)) {
					soLines = solBySoIdMap.get(soConstruct);
				}
			}
			else if (solBySoIdMap.containsKey(so.id)) {
				soLines = solBySoIdMap.get(so.id);
			}

			System.debug( logginglevel.error, '~*~ soConstruct :' + soConstruct );
			System.debug( logginglevel.error, '~*~ solBySoIdMap :' + solBySoIdMap );
			System.debug( logginglevel.error, '~*~ soLines :' + soLines );
			List<String> customerIds = new List<String> {so.Bill_to__c, so.Customer__c, so.Ship_to__c, so.Customer__r.Top_Parent_Customer__c, Null};
			List<String> custGroupIds = new List<String> {so.Bill_to__r.Customer_Group__c, so.Customer__r.Customer_Group__c, so.Ship_to__r.Customer_Group__c, so.Customer__r.Top_Parent_Customer__r.Customer_Group__c, Null};
			List<Id> products = new List<id>();
			List<Id> productGroups = new List<id>();

			String soType = so.Type__c;

			// now look at each line and see if there is a rule for that line
			for (Sales_Order_Line__c line : soLines) {

				Date dt = AllowanceRuleService.getPricingDate(so, line); // pricing date
				System.debug(loggingLevel.Error, '*** dt: ' + dt);
				Id endCustomer = line.End_Customer__c;

				if (line.Type__c == SalesOrderLineService.SO_LINE_TYPE_KIT_CHILD) {
					continue; // Do not apply allowances for Kit child lines
				}

				products.add(line.product__c);
				productGroups.add(line.product__r.product_group__c);

				// TODO: Use rule context to store parameters for meeting matching criteria on an SO/SOL? new class MatchingContext in AllowanceRuleService
				Allowance_Rule__c[] allowanceRulesForLine = matchMaker.fetchMatchingRules(
			            dt, soType, line.Pricebook__c,
				            endCustomer,
				            customerIds, custGroupIds,
				            new List<Id> {line.Product__c}, new List<Id> {line.Product__r.Product_Group__c},
				            false
				        );

				System.debug(loggingLevel.Error, '*** allowanceRulesForLine: ' + allowanceRulesForLine.size() + ' ~~ ' +  allowanceRulesForLine);

				for (Allowance_Rule__c ar : allowanceRulesForLine) {
					rulesContext.add(new AllowanceRuleService.RuleContext( ar, new List<Sales_Order_Line__c> {line}, null));
				}
			}

			Date dt = AllowanceRuleService.getPricingDate(so, null); // pricing date

			// find available manual rules to apply at header level
			Allowance_Rule__c[] allowanceRulesForHeader = matchMaker.fetchMatchingRules(
			            dt, soType, null,
			            null,
			            customerIds, custGroupIds,
			            products, productGroups,
			            true
			        );

			System.debug(loggingLevel.Error, '*** allowanceRulesForHeader: ' + allowanceRulesForHeader.size() + ' ~~ ' + allowanceRulesForHeader);
			// first apply any rules that match the header
			for (Allowance_Rule__c ar : allowanceRulesForHeader) {
				if ( ar.Allowance_Type__r.Apply_At_Header__c == true) {
					rulesContext.add(new AllowanceRuleService.RuleContext( ar, soLines, null));
				}
			}
		}
	}

	// iterate the determine highest/lowest priority for each line. Key: solineId, Value: list of Ctx
	private Map<String, List<AllowanceRuleService.RuleContext>> newPriceCtxMap = new Map<String, List<AllowanceRuleService.RuleContext>>();
	private void prioritizeAndSortRules() {

		for (AllowanceRuleService.RuleContext ctx : rulesContext) {
			Allowance_Rule__c rule = ctx.allowanceRule;
			Sales_Order_Line__c sol = (Sales_Order_Line__c) ctx.lines[0];
			Sales_Order__c so = (Sales_Order__c) ctx.header;

			// Valid New Price SOLs have to flow through
			if (ctx.allowanceType.Type__c == AllowanceRuleService.TYPE_NEW_PRICE && sol.Agreement_Line__c == null ){


				String newPriceKey = sol.Id;

				// ba-todo set class varible: preview mode
				if (sol.Id == null){
					newPriceKey = sol.Line__c.format();
				}
				//System.debug( logginglevel.error, '~*~ newPriceKey :' + newPriceKey );

				if (!newPriceCtxMap.containsKey(newPriceKey)) {
					newPriceCtxMap.put( newPriceKey, new List<AllowanceRuleService.RuleContext>());
				}
				newPriceCtxMap.get(newPriceKey).add(ctx);
			}
		}

	}

	//Priority map for New Price allowances. Larger the value, the higher the priority, the highest priority will be applied to the SoLine
	private Map<String, Decimal> priorityValueMap = new Map<String, Decimal> {
		'Pricebook__c' 		=> MATH.pow(2, -4),	// .0625
		'Product_Group__c' 	=> MATH.pow(2, -3),	// .125
		'Product__c' 		=> MATH.pow(2, -2),	// .25
		'Customer_Group__c' => MATH.pow(2, -1),	// .5
		'Customer2__c' 		=> MATH.pow(2, 0) 	// 	1
	};

	private void applyNewPriceAllowances(Boolean commitNewPrice) {
		System.debug(loggingLevel.Error, '*** applyNewPriceAllowances START *** ');

		Map<Id, Id> validPrices = new Map<Id, Id>();
		Map<Id, Sales_Order_Line__c> soLineForUpdate = new Map<Id, Sales_Order_Line__c>();

		System.debug( logginglevel.error, '~*~ newPriceCtxMap :' + newPriceCtxMap );
		// iterate through each key which is an SOL Id and the values are the ctx that apply to it.
		for (String key : newPriceCtxMap.keySet()) {
//			AllowanceRuleService.RuleContext priorityCtx;
			List<AllowanceRuleService.RuleContext> priorityList = new List<AllowanceRuleService.RuleContext>();
			Decimal maxPriority = 0;
			for (AllowanceRuleService.RuleContext ctx : newPriceCtxMap.get(key)) {

				// conditions required for entering/validating Pricing Rules on SOL.
				if ( ctx.allowanceType.Type__c != AllowanceRuleService.TYPE_NEW_PRICE || ctx.lines[ 0 ].get( 'List_Price__c' ) == null ) {
					System.debug( logginglevel.error, '~*~ SKIPPING :' + ( ctx.allowanceType.Type__c != AllowanceRuleService.TYPE_NEW_PRICE ) + ' || ' + ( ctx.lines[ 0 ].get( 'List_Price__c' ) == null ) );
					continue;
				}

				Allowance_Rule__c rule = ctx.allowanceRule;

				// ba-todo: create forloop with priorityValueMap keyset. Cleaner approach

				/* Internal priority calculation for detmining most approciate by most specific */
				Decimal ctxPriority = 0;
				if ( rule.Customer2__c != null ) {
					ctxPriority += priorityValueMap.get( 'Customer2__c' );
				}
				else if ( rule.Customer_Group__c != null ) {
					ctxPriority += priorityValueMap.get( 'Customer_Group__c' );
				}

				if ( rule.Product__c != null ) {
					ctxPriority += priorityValueMap.get( 'Product__c' );
				}
				else if ( rule.Product_Group__c != null ) {
					ctxPriority += priorityValueMap.get( 'Product_Group__c' );
				}

				if ( rule.Pricebook__c != null ) {
					ctxPriority += priorityValueMap.get( 'Pricebook__c' );
				}

				// max initalized at 0. 1st pass, ctxPriority should be greater than max.
				if ( ctxPriority >= maxPriority ) {

					// empty list because there's a higher priority found
					if (priorityList == null || ctxPriority > maxPriority) {
						priorityList = new List<AllowanceRuleService.RuleContext>();
					}

					priorityList.add( ctx );
					maxPriority = ctxPriority;
				}
			}

			System.debug( logginglevel.error, '~*~ priorityList.size() :' + priorityList.size() );
			if (priorityList == null || priorityList.isEmpty()){
				System.debug( logginglevel.error, '~*~ SKIPPING ~-x-~ ');
				continue;
			}

			Sales_Order_Line__c tmpSol = (Sales_Order_Line__c) priorityList[0].lines[0];
			String soLineKey = '';
			if (tmpSol.Id == null){
				soLineKey = tmpSol.Line__c.format();
			} else {
				soLineKey = tmpSol.Id;
			}

			Sales_Order_Line__c soLine = solMap.get(soLineKey);

			Decimal allowanceAmount;
			Decimal bestPriceAmt;
			AllowanceRuleService.RuleContext priorityCtx;

			for (AllowanceRuleService.RuleContext ctx : priorityList){
				allowanceAmount = new AllowanceCalcService.AllowanceCalculate(ctx).calculateAllowanceAmount();
				if (allowanceAmount < bestPriceAmt || bestPriceAmt == null){
					bestPriceAmt = allowanceAmount;
					priorityCtx = ctx;
				}
			}

			// BA-TODO: move to below if condition for proper validation.
			if (commitNewPrice) {
				validPrices.put(soLine.id, priorityCtx.allowanceRule.Id);
				skipSOLTrigger.add(soLine.id);
			}


			// if Line is not in draft, SKIP applying new price
			// if we're not commiting the line, then we're doing a manual reprice
			// If it has a related SOL, then it's a SOL (eg. adjustment) with reference so block reprice
			// If it's a nonStandard SOL (eg. Adjustment, RMA) allow for replace

			Set<String> nonStdSoTypes = new Set<String>();
			nonStdSoTypes.addAll(SalesOrderService.SO_RMA_REPLACEMENT_TYPES);
			nonStdSoTypes.addAll(SalesOrderService.SO_ADJUSTMENT_TYPES);
			nonStdSoTypes.addAll(SalesOrderService.SO_RMA_TYPES);

			/*
			Basic Scenarios:
				Null unit price (rare since PBL will populate it. Normally true from UI call.
				"!commitNewPrice" comes from preview price logic.
				Do not reprice if not a standard SO unless there's no reference. No reference means it was created on the fly.
				If no lock price, reprice only if the Unit Price == List Price.
			*/

			Boolean standardSO = soLine.Related_Sales_Order_Line__c == null || !nonStdSoTypes.contains(soLine.Sales_Order__r.Type__c);

			// if sol unit price = bestPrice, allow it to go through to get the AR reference
			Boolean ediCondition = soline.Unit_Price__c == bestPriceAmt || soLine.Unit_Price__c == soLine.List_Price__c;
			System.debug( logginglevel.error, '~*~ ediCondition :' + ediCondition );

			// ba-todo: is it possible to recognize UE List Price value on save? Would need to introduce a flag for that.
			Boolean repriceCondition =  soLine.Unit_Price__c == null || ( ( ediCondition || soLine.Product__r.Pricebook_Line_Required__c || !commitNewPrice) && standardSO);
			System.debug( logginglevel.error, '~*~ repriceCondition:' + repriceCondition );

			// null status from manage lines's new lines.
			if ( (tmpSol.Status__c == null || tmpSol.Status__c == 'Draft') && repriceCondition ) {

				if (soLine.Unit_Price__c != bestPriceAmt || soline.New_Pricing_Rule__c != priorityCtx.allowanceRule.Id) {

					soline.New_Pricing_Rule__c = priorityCtx.allowanceRule.Id;
					soline.New_Pricing_Rule__r = priorityCtx.allowanceRule;
					soLine.Unit_Price__c = bestPriceAmt;

					if ( commitNewPrice ) {
						soLineForUpdate.put( soLine.id, soLine );
						skipSOLTrigger.add( soLine.id );
					}
				}
			}
		}



		// validation to clean up New Prices that don't belong
		for (Sales_Order_Line__c sol : newPricedLines) {
			if (!validPrices.containsKey(sol.Id) && (sol.Status__c == null || sol.Status__c == 'Draft')) {
				System.debug( logginglevel.error, '~*~ Invalid Price. Resetting: ' + sol.Id);
				//System.debug( logginglevel.error, '~*~ validPrices :' + validPrices );
				// soLineForUpdate doesn't have the sol with new price. if it does, it'll update it will the new/correct one
				sol.New_Pricing_Rule__c = null;
				sol.Unit_Price__c = sol.List_Price__c;

				soLineForUpdate.put(sol.id, sol);
			}
		}

		if (commitNewPrice) {
			commitNewPriceLines( soLineForUpdate );
		}
	}

	public void commitNewPriceLines(Map<Id, Sales_Order_Line__c> soLineForUpdate){
		System.debug(loggingLevel.Error, '*** soLineForUpdate: ' + soLineForUpdate);
		if (!soLineForUpdate.values().isEmpty()) {
			//DML.checkUpsertAsUser(soLineForUpdate.values()); upsert soLineForUpdate.values();
			DML.updateAsSystem(soLineForUpdate.values());
		}

		skipSOLTrigger = new Set<Id>(); // clear set

	}
	public void constructAllowances() {


		for (AllowanceRuleService.RuleContext ctx : rulesContext) {
			if (ctx.allowanceType.Type__c == AllowanceRuleService.TYPE_NEW_PRICE) {
				continue;
			}

			Allowance_Applied__c allwAppd = AllowanceCalcService.initAllowanceRecord(ctx);

			// All valid Allowances are stored here. Used for validation
			String key = AllowanceRuleService.getValidationKey(allwAppd);
			validAllowancesKey.add(key);

			if (!ctx.allowanceType.Manual__c) {
				// for Automatics
				Allowance_Applied__c existingAA = (existingAutoAllowanceKeys != null && existingAutoAllowanceKeys.containsKey(allwAppd.Unique_Key__c)) ? existingAutoAllowanceKeys.get(allwAppd.Unique_Key__c) : null;
				ctx.existingAA = existingAA;

				// RENAME to updateAllowanceAmount. Uses existing allowances values where necessary
				allwAppd = AllowanceCalcService.calculateAllowanceAmount(ctx, allwAppd);

				// only allow Auto AA, and SO Types that allow Auto applied allowances unless Blocked Auto is overriden
				// Allow manual allowances to be calculated to capture correct amount during allowance priority grouping
				if ((AllowanceRuleService.SO_TYPES_FOR_AUTO.contains( (String) ctx.header.get('Type__c')) || overrideAutoBlock) ) {

					// IMPACT if manual allowance?!? Skip manual allowances since they can have multiple.
					if (existingAA != null) {
						if (existingAA.Beneficiary__c == allwAppd.Beneficiary__c && existingAA.BillBack_Commitment__c == allwAppd.BillBack_Commitment__c && existingAA.Allowance_Amount__c == allwAppd.Allowance_Amount__c) {
							System.debug(loggingLevel.Error, '*** SKIP adding to upsert: ');
							continue;
						}
					}

					allowancesForUpsert.add(allwAppd);
				}

			}
			// for Manuals: iterate through existing manual allowances to calculate the allowance amounts.
			else if (existingManualAllowancesByKey.containsKey(key)) {
				for (Allowance_Applied__c existingManualAllowance : existingManualAllowancesByKey.get(key)) {

					// clone CTX so override value doesn't get captured
					AllowanceRuleService.RuleContext clonedCTX = ctx.clone();

					clonedCTX.existingAA = existingManualAllowance;

					// clone because we want to verify if there are changes on the allowance amount to avoid inserting. If different, then upsert. Cloned with preserving the ID.
					Allowance_Applied__c manAllwAppd = existingManualAllowance.clone(true);

					manAllwAppd = AllowanceCalcService.calculateAllowanceAmount(clonedCTX, manAllwAppd);

					if (existingManualAllowance.Beneficiary__c == manAllwAppd.Beneficiary__c && existingManualAllowance.BillBack_Commitment__c == manAllwAppd.BillBack_Commitment__c && existingManualAllowance.Allowance_Amount__c == allwAppd.Allowance_Amount__c) {
						System.debug(loggingLevel.Error, '*** SKIP adding to upsert: ');
						continue;
					}

					allowancesForUpsert.add(manAllwAppd);
				}
			}
		}
	}

	// TO-DO: Redesign the validate method to use the allowance Rules by keys which isn't in the Applicator core but should be. More effcient.
	/*
	*   Deletes Allowances that don't belong here.
	*   Achieved By building a key for acceptible allowances where K: {SO + SOL + Allowances Rules + Allowance Type} and building the same key with existing allowances.
	*/
	public void validateExistingAllowances() {

		Map<Id, Allowance_Applied__c> aaToDelete = new Map<Id, Allowance_Applied__c>();
		List<Allowance_Applied__c> manualAllowancesForRecalc = new List<Allowance_Applied__c>();

		for (Allowance_Applied__c existingAA : existingAllowances) {

			String existingAAKey = AllowanceRuleService.getValidationKey(existingAA);

			if (!validAllowancesKey.contains(existingAAKey)) {
				aaToDelete.put(existingAA.Id, existingAA);
				continue;
			}

			if (existingAA.Allowance_Type__r.Manual__c) {
				manualAllowancesForRecalc.add(existingAA);
			}

			if (existingAA.Allowance_Type__r.Type__c == AllowanceRuleService.TYPE_ACCRUAL) {
				this.accrualAllowances.put(existingAA.id, existingAA);
			}
		}

		DML.deleteAsSystem(aaToDelete.values());

		if (!manualAllowancesForRecalc.isEmpty()) {
			//recalculateAllowances(manualAllowancesForRecalc);
		}
	}

	public void apply() {

		if (!allowancesForUpsert.isEmpty()) {
			System.debug(loggingLevel.Error, '*** allowancesForUpsert: ' + allowancesForUpsert);
			DML.checkUpsertAsUser(allowancesForUpsert); upsert allowancesForUpsert;
		}

		// collect updated Accrual AA
		for (Allowance_Applied__c updatedAA : allowancesForUpsert) {
			if (updatedAA.Allowance_Type__r.Type__c == AllowanceRuleService.TYPE_ACCRUAL) {
				this.accrualAllowances.put(updatedAA.id, updatedAA);
			}
		}
	}

	public void recalculateAllowances (List<Allowance_Applied__c> allowancesForRecalc) {

		for (Allowance_Applied__c sourceAA : allowancesForRecalc) {
			//Allowance_Applied__c clonedAA = aa.clone(false, true);

			Sales_Order__c salesOrder;
			List<Sales_Order_Line__c> allSOLines;

			if (sourceAA.Sales_Order__c != null) {
				salesOrder = soMap.get(sourceAA.Sales_Order__c);
				allSOLines = solBySoIdMap.get(sourceAA.Sales_Order__c);
			}

			else if (sourceAA.Sales_Order_Line__c != null) {
				allSOLines = new List<Sales_Order_Line__c> {solMap.get(sourceAA.Sales_Order_Line__c)};
				salesOrder = soMap.get(allSOLines[0].Sales_Order__c);
			}

			if (salesOrder == null || allSOLines == null) {
				throw new AllowanceApplicatorException('Cannot find Id type passed when copying Allowance.');
			}

			Decimal allowanceAmount = new AllowanceCalcService.AllowanceCalculate(
			    new AllowanceRuleService.RuleContext(
			        sourceAA.Allowance_Rule2__r,
			        allSOLines,
			        sourceAA.Override_Value__c
			    )
			).calculateAllowanceAmount();

			if (sourceAA.Allowance_Type__r.Type__c == AllowanceRuleService.TYPE_ACCRUAL) {
				sourceAA.Allowance_Amount__c = null;
				sourceAA.BillBack_Commitment__c = allowanceAmount;
				allowancesForUpsert.add(sourceAA);
			} else if (sourceAA.Allowance_Amount__c != allowanceAmount) {
				sourceAA.Allowance_Amount__c = allowanceAmount;
				sourceAA.BillBack_Commitment__c = null;
				sourceAA.Beneficiary__c = null;
				allowancesForUpsert.add(sourceAA);
			}
		}
	}

	// must be called after persistChanges to fetch allowance Ids
	public void accrualFulfillments() {

		System.debug(loggingLevel.Error, '*** solFulQtyMap: ' + solFulQtyMap);

		if (solFulQtyMap == null || solFulQtyMap.values().isEmpty()) return;

		List<Allowance_Applied__c> accrualAAForCM = new List<Allowance_Applied__c>();
		System.debug(loggingLevel.Error, '*** this.accrualAllowances: ' + this.accrualAllowances);
		// iterate through existing accrual allowances, reprice using fulfillment qty for credit memo creation
		for (Allowance_Applied__c accrualAA : this.accrualAllowances.values()) {

			// Only creating fulfillments where new qty fulfillments are created
			if (!solFulQtyMap.containsKey(accrualAA.Sales_Order_Line__c)) {
				System.debug(loggingLevel.Error, '*** no sol Fulfillment Qty: ' + solFulQtyMap);
				continue;
			}

			Decimal fulfilledQty = solFulQtyMap.get(accrualAA.Sales_Order_Line__c);

			Sales_Order_Line__c sol = solMap.get(accrualAA.Sales_Order_Line__c);

			// this allowance is generated using the new qty fulfilled. It's different from the soline which has the running total of qty fulfilled. BA: Not sure if this will have rounding issues.
			accrualAA.BillBack_Commitment__c = new AllowanceCalcService.AllowanceCalculate(
			    new AllowanceRuleService.RuleContext(
			        accrualAA.Allowance_Rule2__r,
			        new List<Sales_Order_Line__c> {sol},
			        accrualAA.Override_Value__c,
			        solFulQtyMap
			    )
			).calculateAllowanceAmount();

			accrualAAForCM.add(accrualAA);
		}

		if (!accrualAAForCM.isEmpty()) {
			Map<Id, Sales_Order_Line__c> solIdMap = new Map<Id, Sales_Order_Line__c>();
			for (String stringId : solMap.keySet()){
				solIdMap.put(Id.valueOf(stringId), solMap.get(stringId));
			}
			FulfillmentService.fulfillAccrualAllowances(accrualAAForCM, solIdMap);
		}
	}
}
