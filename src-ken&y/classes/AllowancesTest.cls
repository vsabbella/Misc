@isTest
private class AllowancesTest {
	/*
		ba-todo:
			> Code fixes
				> on SOL trigger: validateAllowancesApplied. Consider splitting into Recalc and Validate to reduce actions, eg: Why Validate allowances on qty change? But in the future this might be necessary
			> Tests for flow Coverage
				Page Tests
					AllowanceAppliedNewExt
						> test for no rules found
						> test Allowance Code
						> updating override value
						> editing existing allowance
					SalesOrderAllowanceExt
						> test deleting manual
						>
					AllowanceTypeNewExt
						> Creating
						> Editing
						> Cloning
				Feature Test
					> allowances with SO Kit Lines
					> Non-Standard SO: RMA and Adjustment.
						+ Allowance treatment
						+ Creating Invoices from them
					> Deleting AA on Resale Orders. Check validateInvoice flow for Resale. What about other non-standard orders
				BackEnd
					> need a fast effecient way to create mutiple invoices.
					> Test Overriding and generating CIs. For percentage, Flat, and Rate By (For Header and Lines)
						> recommend using 1 So and 1 SOL for this.
					> Test generating all Manual combos. Test on both pages, SalesOrderManageLines & AllowanceAppliedNewExt.
					> Test manual allowance recalcable Allowance types and copy over to CI for partial recalcs allowances
					> Accruals
						> Create Accruals where Accrue To is End Customer.
						> Create Accruals w/ Beneficiary on the Rule

			> (check w/ Jerome)
				> Add ManageLines Allowance tests here. Test multiple combinations here. Check for recalc and override.

		On Next Test Fixing Iteration:
			Create TestMethod to support services separately. (necessary?)
			Update testData
				> need flexible Type & Rule creation.
	*/

	@testSetup
	private static void setupfuel() {
		TestDataForAllowance setupData = new TestDataForAllowance();
		// 58 queries (All trigger based?)
	}

	static TestDataForAllowanceQuery fuel = new TestDataForAllowanceQuery();
	static {
		//AllowanceRuleService.testAllowances = true;
	}

	public static final String BASIS_FLAT_AMOUNT = AllowanceRuleService.BASIS_FLAT_AMOUNT;
	public static final String BASIS_RATE_BY = AllowanceRuleService.BASIS_RATE_BY;
	public static final String BASIS_TARGET_PERCENT = AllowanceRuleService.BASIS_TARGET_PERCENT;
	public static final Set <String> RATES = AllowanceRuleService.RATE_FIELDS;
	public static final Set <String> TARGETS = AllowanceRuleService.TARGET_FIELDS;
	public static final String TYPE_ACCRUAL = AllowanceRuleService.TYPE_ACCRUAL;
	public static final String ALLOWANCE_ACCRUAL = AllowanceRuleService.ALLOWANCE_ACCRUAL;

	public static final String TARGET_FIELD_GROSS = AllowanceRuleService.TARGET_FIELD_GROSS;
	public static final String TARGET_FIELD_NET = AllowanceRuleService.TARGET_FIELD_NET;


	/* NEW PRICE ALLOWANCE DETAILS */
	public static final String NEW_PRICE = AllowanceRuleService.TYPE_NEW_PRICE;
	public static final String BASIS_MARKUP = AllowanceRuleService.BASIS_MARKUP;
	public static final String BASIS_MARKDOWN = AllowanceRuleService.BASIS_MARKDOWN;
	public static final String BASIS_MULTIPLIER = AllowanceRuleService.BASIS_MULTIPLIER;

	// params to pass to create Allowance Types dynamically
	public static final Set <String> ALL_BASIS = new Set<String>{ BASIS_FLAT_AMOUNT, BASIS_RATE_BY, BASIS_TARGET_PERCENT };
	public static final String FLAT = 'Flat';
	public static final String CHARGE = 'Charge';
	public static final String DISCOUNT = 'Discount';
	public static final String ACCRUAL = 'Accrual';
	public static final Set <String> ALL_TYPES = new Set<String>{ CHARGE, DISCOUNT };
	public static final Set <Boolean> TF_SET = new Set<Boolean>{ true, false };
	public static final Set <Boolean> T_SET = new Set<Boolean>{ true };
	public static final Set <Boolean> F_SET = new Set<Boolean>{ false };

	public static List<Allowance_Applied__c> getAppliedRecords( String whereClause, Boolean checkAsserts, String process ) {
		SOQLUtil soSoql = new SOQLUtil( 'Allowance_Applied__c', true ); //enforceFLS=true, running in user mode
		Set<String> queryFields = new Set<String>(); // creating new set to query to avoid updating fieldset.

		queryFields.addAll( AllowanceRuleService.allowanceAppliedFields );
		queryFields.addAll( AllowanceRuleService.getFieldsFromRelatedFieldList( 'Sales_Order_Line__r', AllowanceRuleService.salesOrderLineFields ) );
		queryFields.addAll( AllowanceRuleService.getFieldsFromRelatedFieldList( 'Sales_Order__r', AllowanceRuleService.salesOrderFields ) ); // necessary for SO header allowances

		// too many levels depth: Customer_Invoice_Line__r.Sales_Order_Line__r.product__r.product_group__r.hierarchy__r.path__c
		// TO-DO (BA): allow option to not retrieve nested results
		// queryFields.addAll(AllowanceRuleService.getFieldsFromRelatedFieldList('Sales_Order__r', AllowanceRuleService.customerInvoiceLineFields));

		Set<String> cilFields = new set<string>{
				'id',
				'Product__r.Sales_Hierarchy__c', 'Product__r.Sales_Hierarchy__r.Path__c',
				'Product__c', 'Product__r.Product_Group__c',
				'Total_Weight__c', 'Weight__c', 'Off_Invoice_Rate__c', 'Quantity_Shipped__c', 'Unit_Price__c',
				'Sales_Order__c', 'Sales_Order_Line__c', 'Customer_Invoice__c', 'Shipment_Line__c',
				'Customer_Invoice__r.Currency__c', 'Customer_Invoice__r.Sales_Order__c'
		};

		Set<String> solFields = new Set<String>{
				'allowances__c', 'freight_allowance__c', 'id', 'name',
				'extended_price__c', 'expected_price__c', 'discount_percent__c', 'ordered_date_time__c', 'off_invoice_rate__c',
				'unit_price__c', 'type__c', 'status__c', 'sales_order__c', 'company__c', 'product__r.id', 'product__r.name', 'product__c',
				'product__r.product_group__c', 'product__r.product_group__r.hierarchy__c',
				'product__r.sales_hierarchy__c', 'product__r.sales_hierarchy__r.code__c', 'product__r.sales_hierarchy__r.path__c',
				'quantity_fulfilled__c', 'quantity_shipped__c', 'quantity_ordered__c', 'weight__c', 'product_weight__c', 'non_shippable__c'
		};

		// 'product__r.product_group__r.hierarchy__r.code__c', // removed b/c depth is too long
		// 'product__r.product_group__r.hierarchy__r.path__c', // removed b/c depth is too long
		cilFields.addAll( AllowanceRuleService.getFieldsFromRelatedFieldList( 'Sales_Order_Line__r', solFields ) );
		cilFields.addAll( AllowanceRuleService.getFieldsFromRelatedFieldList( 'Sales_Order__r', AllowanceRuleService.salesOrderFields ) );

		queryFields.addAll( AllowanceRuleService.getFieldsFromRelatedFieldList( 'Customer_Invoice_Line__r', cilFields ) );
		queryFields.addAll( AllowanceRuleService.getFieldsFromRelatedFieldList( 'Customer_Invoice2__r', AllowanceRuleService.customerInvoiceFields ) );

		soSoql.addFields( queryFields );
		if ( whereClause != null && whereClause.length() > 0 ) {
			soSoql.setWhereClause( whereClause );
		}
		soSoql.setOrderByClause( 'ID DESC' ); // most recent first
		List<Allowance_Applied__c> aaList = Database.query( soSoql.getQuery() );

		System.debug( loggingLevel.Error, '~*~ aaList.size(): ' + aaList.size() );
		// assert record integrity here.
		if ( checkAsserts == null || checkAsserts ) {
			for ( Allowance_Applied__c aa : aaList ) {

				String assertString = 'Failure at ' + process + ' - ';

				Sales_order__c so;
				Sales_Order_Line__c sol;
				Customer_Invoice_Line__c cil;

				if ( aa.Sales_order__c != null || aa.Sales_Order_Line__c != null ) {
					sol = ( aa.Sales_Order_Line__c != null ) ? aa.Sales_Order_Line__r : null;
					so = ( aa.Sales_Order__c != null ) ? aa.Sales_Order__r : aa.Sales_Order_Line__r.Sales_Order__r;

				}
				else if ( aa.Customer_Invoice_Line__c != null ) {
					cil = aa.Customer_Invoice_Line__r;
					sol = cil.Sales_Order_Line__r;
					so = cil.Sales_Order__r;

				}
				else if ( aa.Customer_Invoice2__c != null ) {
					so = aa.Customer_Invoice2__r.Sales_Order__r;
				}

				Date docDate = so.Price_Determination_Date__c == SalesOrderService.PRICE_DET_ORDER && sol != null ? sol.Ordered_Date_Time__c.date() : so.Pricing_Date__c;
				Allowance_Rule__c rule = aa.Allowance_rule2__r;

				// check validity of AA retrieved. Match aa Date with source doc date
				system.assert( rule.Start_Date__c <= docDate && docDate <= rule.End_Date__c, assertString + rule.Name + ': ' + rule.Start_Date__c + ' <= ' + docDate + ' <= ' + rule.End_Date__c );
				system.assert( aa.Allowance_Class__c != null, 'Expecting Allowance Class to be populated: ' + aa );

				Boolean oneTimeInvoice = aa.Allowance_Type__r.One_Time__c && ( aa.Customer_invoice2__r != null || aa.Customer_Invoice_Line__c != null );
				// Manual CI OT will need a unique key

				if ( aa.Allowance_Type__r.Type__c == TYPE_ACCRUAL ) {
					system.assert( aa.Beneficiary__c != null, 'Missing beneficiary field' + aa );
					system.assert( aa.BillBack_Commitment__c > 0, 'expecting positive value: ' + aa.BillBack_Commitment__c );
					if ( aa.Sales_Order_Line__c != null ) {
						system.assert( aa.Sales_Order_Line__r.BillBack_Commitment__c > 0, 'Expecting SOL billback commitment to be positive: ' + aa.Sales_Order_Line__r.BillBack_Commitment__c + ' ' + aa + ' ' );
					}
					system.assert( aa.Allowance_Amount__c == null, 'Expecting Allowance AMount to be null: ' + aa.Allowance_Amount__c );
				}

				//if (!aa.Allowance_Type__r.Manual__c || oneTimeInvoice) {
				//	system.assert(aa.Unique_Key__c != null, 'Missing unique Key' + aa + '\n' + aa.Allowance_Type__r);
				//}
			}
		}

		return aaList;
	}

	/************************************************************************************************************************
	*
	*  		New TESTS
	*
	*************************************************************************************************************************/

	static testMethod void testAllowanceRulePricebookMatching(){
		AllowanceRuleService.testAllowances = true;

		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];

		Allowance_Type__c at1 = new Allowance_Type__c(
				Name = '$20 Flat',
				Type__c = NEW_PRICE,
				Amount__c = 20,
				Basis__c = BASIS_FLAT_AMOUNT
		);

		Allowance_Type__c at2 = new Allowance_Type__c(
				Name = '$10 Flat',
				Type__c = NEW_PRICE,
				Amount__c = 10,
				Basis__c = BASIS_FLAT_AMOUNT
		);

		Allowance_Type__c at3 = new Allowance_Type__c(
				Name = '$30 Flat',
				Type__c = NEW_PRICE,
				Amount__c = 30,
				Basis__c = BASIS_FLAT_AMOUNT
		);

		insert new List<Allowance_Type__c>{at1, at2, at3};

		Allowance_Rule__c ar1 = new Allowance_Rule__c(
				Name = at1.Name + ' | Cust + Prod + PB',
				Allowance_Type__c = at1.id,
				Customer2__c = fuel.customerBillTo.Id,
				Product__c = soLine.Product__c,
				Pricebook__c = soLine.Pricebook__c,
				Start_Date__c = system.today().addDays(0 ),
				End_Date__c = system.today().addDays( 3 )
		);

		Allowance_Rule__c ar2 = new Allowance_Rule__c(
				Name = at2.Name + ' | CG + PB',
				Allowance_Type__c = at2.id,
				Customer_Group__c = fuel.customerGroupList[1].Id,
				Pricebook__c = soLine.Pricebook__c,
				Start_Date__c = system.today().addDays( 4 ),
				End_Date__c = system.today().addDays( 6 )
		);

		Allowance_Rule__c ar3 = new Allowance_Rule__c(
				Name = at3.Name + ' | PB',
				Allowance_Type__c = at3.id,
				Pricebook__c = soLine.Pricebook__c,
				Start_Date__c = system.today().addDays( 7 ),
				End_Date__c = system.today().addDays( 9 )
		);
		insert new List<Allowance_Rule__c>{ar1, ar2, ar3};

		Test.startTest();

		System.debug( loggingLevel.Error, '~*~ TEST START: ' );
		List<Sales_Order_Line__c> soList;

		salesOrder.Price_determination_date__c = SalesOrderService.PRICE_DET_MANUAL;

		salesOrder.Pricing_date__c = system.Today() + 8;
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( ar3.id, sol.New_Pricing_Rule__c);
				system.assertEquals( 30, sol.Unit_price__c);
			}
		}

		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		salesOrder.Pricing_date__c = system.Today() + 4;
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( ar2.id, sol.New_Pricing_Rule__c, 'Expecting 5th rule to apply.' );
				system.assertEquals( 10, sol.Unit_price__c, '$100 (.8 multiplier) -> $80. Expecting 5th rule to apply.' );
			}
		}

		salesOrder.Pricing_date__c = system.Today();
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( ar1.id, sol.New_Pricing_Rule__c, 'Expecting 5th rule to apply.' );
				system.assertEquals( 20, sol.Unit_price__c, '$100 (.8 multiplier) -> $80. Expecting 5th rule to apply.' );
			}
		}

	}

	static testMethod void testNewPriceWithPriority2() {
		AllowanceRuleService.testAllowances = true;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() ); // 62 if run in class static. Else 58.
		// Create multiple Rules to test different priorities. SO pricing Date is manual. Increase PD to get next rule with highest priority
		/*
			1 - $20 Flat		Cust + prod (today only)
			2 - 20% markup		Cust + PG 	(today + 1)
			3 - 20% markdown	Cust 		(today + 2)
			4 - 1.2 multiplier	CG + Prod 	(today + 3)
			5 - .8 multiplier	CG + PG 	(today + 4)
			6 - 100% markdown	CG 			(today + 5)

		*/

		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];

		Allowance_Type__c at1 = new Allowance_Type__c(
				Name = '$20 Flat',
				Type__c = NEW_PRICE,
				Amount__c = 20,
				Basis__c = BASIS_FLAT_AMOUNT

		);

		Allowance_Type__c at2 = new Allowance_Type__c(
				Name = '20% markup',
				Type__c = NEW_PRICE,
				Percent_Of_Target_Field__c = 20,
				Basis__c = BASIS_MARKUP
		);

		Allowance_Type__c at3 = new Allowance_Type__c(
				Name = '20% markdown',
				Type__c = NEW_PRICE,
				Percent_Of_Target_Field__c = 20,
				Basis__c = BASIS_MARKDOWN
		);

		Allowance_Type__c at4 = new Allowance_Type__c(
				Name = '1.2 multiplier',
				Type__c = NEW_PRICE,
				Amount__c = 1.2,
				Basis__c = BASIS_MULTIPLIER
		);

		Allowance_Type__c at5 = new Allowance_Type__c(
				Name = '.8 multiplier',
				Type__c = NEW_PRICE,
				Amount__c = .8,
				Basis__c = BASIS_MULTIPLIER
		);

		Allowance_Type__c at6 = new Allowance_Type__c(
				Name = '100% markdown',
				Type__c = NEW_PRICE,
				Percent_Of_Target_Field__c = 100,
				Basis__c = BASIS_MARKDOWN
		);

		insert new List<Allowance_Type__c>{ at1, at2, at3, at4, at5, at6 };

		Allowance_Rule__c ar1 = new Allowance_Rule__c(
				Name = at1.Name + ' | Cust + Prod',
				Allowance_Type__c = at1.id,
				Customer2__c = fuel.customerBillTo.Id,
				Product__c = soLine.Product__c,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 0 )
		);

		Allowance_Rule__c ar2 = new Allowance_Rule__c(
				Name = at2.Name + ' | Cust + PG',
				Allowance_Type__c = at2.id,
				Customer2__c = fuel.customerBillTo.Id,
				Product_Group__c = fuel.productgroup.id, //fuel.productgroup.id
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 1 )
		);

		Allowance_Rule__c ar3 = new Allowance_Rule__c(
				Name = at3.Name + ' | Cust',
				Allowance_Type__c = at3.id,
				Customer2__c = fuel.customerBillTo.Id,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 2 )
		);

		Allowance_Rule__c ar4 = new Allowance_Rule__c(
				Name = at4.Name + ' | CG + Prod',
				Allowance_Type__c = at4.id,
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Product__c = soLine.Product__c,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 3 )
		);

		Allowance_Rule__c ar5 = new Allowance_Rule__c(
				Name = at5.Name + ' | CG + PG',
				Allowance_Type__c = at5.id,
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Product_Group__c = fuel.productgroup.id,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 4 )
		);

		Allowance_Rule__c ar6 = new Allowance_Rule__c(
				Name = at6.Name + ' | CG',
				Allowance_Type__c = at6.id,
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 5 )
		);

		insert new List<Allowance_Rule__c>{ ar1, ar2, ar3, ar4, ar5, ar6 };

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		Test.startTest();

		System.debug( loggingLevel.Error, '~*~ TEST START: ' );
		List<Sales_Order_Line__c> soList;

		salesOrder.Price_determination_date__c = SalesOrderService.PRICE_DET_MANUAL;
		salesOrder.Pricing_date__c = system.Today().addDays( 4 );
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( sol.New_Pricing_Rule__c, ar5.id, 'Expecting 5th rule to apply.' );
				system.assertEquals( 80, sol.Unit_price__c, '$100 (.8 multiplier) -> $80. Expecting 5th rule to apply.' );
			}
			else {
				system.assertEquals( sol.New_Pricing_Rule__c, ar6.id, 'Expecting 6th rule to apply.' );
				system.assertEquals( 0, sol.Unit_price__c, '$1000 (100% markdown) -> $0. Expecting 6th rule to apply.' );
			}
		}

		salesOrder.Pricing_date__c = system.Today().addDays( 5 );
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( sol.New_Pricing_Rule__c, ar6.id, 'Expecting 6th rule to apply.' );
				system.assertEquals( 0, sol.Unit_price__c, '$100 (100% markdown) -> $0. Expecting 6th rule to apply.' );
			}
			else {
				system.assertEquals( sol.New_Pricing_Rule__c, ar6.id, 'Expecting 6th rule to apply.' );
				system.assertEquals( 0, sol.Unit_price__c, '$1000 (100% markdown) -> $0. Expecting 6th rule to apply.' );
			}
		}

		salesOrder.Pricing_date__c = system.Today().addDays( 6 );
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( sol.New_Pricing_Rule__c, null, 'Expecting no rule to apply.' );
				system.assertEquals( 100, sol.Unit_price__c, 'Expecting no rule to apply.' );
			}
			else {
				system.assertEquals( sol.New_Pricing_Rule__c, null, 'Expecting no rule to apply.' );
				system.assertEquals( 1000, sol.Unit_price__c, 'Expecting no rule to apply.' );
			}
		}
	}

	static testMethod void testNewPriceWithPriority() {
		AllowanceRuleService.testAllowances = true;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() ); // 62 if run in class static. Else 58.
		// Create multiple Rules to test different priorities. SO pricing Date is manual. Increase PD to get next rule with highest priority
		/*
			1 - $20 Flat		Cust + prod (today only)
			2 - 20% markup		Cust + PG 	(today + 1)
			3 - 20% markdown	Cust 		(today + 2)
			4 - 1.2 multiplier	CG + Prod 	(today + 3)
			5 - .8 multiplier	CG + PG 	(today + 4)
			6 - 100% markdown	CG 			(today + 5)

		*/

		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];

		Allowance_Type__c at1 = new Allowance_Type__c(
				Name = '$20 Flat',
				Type__c = NEW_PRICE,
				Amount__c = 20,
				Basis__c = BASIS_FLAT_AMOUNT

		);

		Allowance_Type__c at2 = new Allowance_Type__c(
				Name = '20% markup',
				Type__c = NEW_PRICE,
				Percent_Of_Target_Field__c = 20,
				Basis__c = BASIS_MARKUP
		);

		Allowance_Type__c at3 = new Allowance_Type__c(
				Name = '20% markdown',
				Type__c = NEW_PRICE,
				Percent_Of_Target_Field__c = 20,
				Basis__c = BASIS_MARKDOWN
		);

		Allowance_Type__c at4 = new Allowance_Type__c(
				Name = '1.2 multiplier',
				Type__c = NEW_PRICE,
				Amount__c = 1.2,
				Basis__c = BASIS_MULTIPLIER
		);

		Allowance_Type__c at5 = new Allowance_Type__c(
				Name = '.8 multiplier',
				Type__c = NEW_PRICE,
				Amount__c = .8,
				Basis__c = BASIS_MULTIPLIER
		);

		Allowance_Type__c at6 = new Allowance_Type__c(
				Name = '100% markdown',
				Type__c = NEW_PRICE,
				Percent_Of_Target_Field__c = 100,
				Basis__c = BASIS_MARKDOWN
		);

		insert new List<Allowance_Type__c>{
				at1, at2, at3, at4, at5, at6
		};

		Allowance_Rule__c ar1 = new Allowance_Rule__c(
				Name = at1.Name + ' | Cust + Prod',
				Allowance_Type__c = at1.id,
				Customer2__c = fuel.customerBillTo.Id,
				Product__c = soLine.Product__c,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 0 )
		);

		Allowance_Rule__c ar2 = new Allowance_Rule__c(
				Name = at2.Name + ' | Cust + PG',
				Allowance_Type__c = at2.id,
				Customer2__c = fuel.customerBillTo.Id,
				Product_Group__c = fuel.productgroup.id, //fuel.productgroup.id
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 1 )
		);

		Allowance_Rule__c ar3 = new Allowance_Rule__c(
				Name = at3.Name + ' | Cust',
				Allowance_Type__c = at3.id,
				Customer2__c = fuel.customerBillTo.Id,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 2 )
		);

		Allowance_Rule__c ar4 = new Allowance_Rule__c(
				Name = at4.Name + ' | CG + Prod',
				Allowance_Type__c = at4.id,
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Product__c = soLine.Product__c,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 3 )
		);

		Allowance_Rule__c ar5 = new Allowance_Rule__c(
				Name = at5.Name + ' | CG + PG',
				Allowance_Type__c = at5.id,
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Product_Group__c = fuel.productgroup.id,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 4 )
		);

		Allowance_Rule__c ar6 = new Allowance_Rule__c(
				Name = at6.Name + ' | CG',
				Allowance_Type__c = at6.id,
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Start_Date__c = system.today().addDays( 0 ),
				End_Date__c = system.today().addDays( 5 )
		);

		insert new List<Allowance_Rule__c>{
				ar1, ar2, ar3, ar4, ar5, ar6
		};

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		Test.startTest();

		System.debug( loggingLevel.Error, '~*~ TEST START: ' );
		List<Sales_Order_Line__c> soList;

		salesOrder.Price_determination_date__c = SalesOrderService.PRICE_DET_MANUAL;
		salesOrder.Pricing_date__c = system.Today();
		update salesOrder;
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];

		System.debug( loggingLevel.Error, '~*~ system.Today(): ' + system.Today() );

		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( sol.New_Pricing_Rule__c, ar1.id, 'Expecting 1st rule to apply.' );
				system.assertEquals( 20, sol.Unit_price__c, '$100 ($20 flat) -> $20. Expecting 1st rule to apply.' );
			}
			else {
				system.assertEquals( sol.New_Pricing_Rule__c, ar3.id, 'Expecting 3rd rule to apply.' );
				system.assertEquals( 800, sol.Unit_price__c, '$1000 (20% markdown) -> $800. Expecting 3rd rule to apply.' );
			}
		}
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		salesOrder.Pricing_date__c = system.Today().addDays( 1 );
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, Product__r.Product_Group__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( sol.New_Pricing_Rule__c, ar2.id, 'Expecting 2nd rule to apply. ' + ar2 + ' ' + sol + ', PG: ' + sol.Product__r.Product_Group__c );
				system.assertEquals( 120, sol.Unit_price__c, '$100 (20% markup) -> $120. Expecting 2nd rule to apply.' );
			}
			else {
				system.assertEquals( sol.New_Pricing_Rule__c, ar3.id, 'Expecting 3rd rule to apply.' + ar3.Name );
				system.assertEquals( 800, sol.Unit_price__c, '$1000 (20% markdown) -> $800. Expecting 3rd rule to apply.' );
			}
		}

		salesOrder.Pricing_date__c = system.Today().addDays( 2 );
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( sol.New_Pricing_Rule__c, ar3.id, 'Expecting 3rd rule to apply.' );
				system.assertEquals( 80, sol.Unit_price__c, '$100 (20% markdown) -> $80. Expecting 3rd rule to apply.' );
			}
			else {
				system.assertEquals( sol.New_Pricing_Rule__c, ar3.id, 'Expecting 3rd rule to apply.' );
				system.assertEquals( 800, sol.Unit_price__c, '$1000 (20% markdown) -> $800. Expecting 3rd rule to apply.' );
			}
		}

		salesOrder.Pricing_date__c = system.Today().addDays( 3 );
		update salesOrder;
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		soList = [select id, Unit_Price__c, Product__c, New_Pricing_Rule__c, List_Price__c from Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : soList ) {
			if ( soLine.Product__c == sol.Product__c ) {
				system.assertEquals( sol.New_Pricing_Rule__c, ar4.id, 'Expecting 4th rule to apply.' );
				system.assertEquals( 120, sol.Unit_price__c, '$100 (1.2 multiplier) -> $120. Expecting 6th rule to apply.' );
			}
			else {
				system.assertEquals( sol.New_Pricing_Rule__c, ar6.id, 'Expecting 6th rule to apply.' );
				system.assertEquals( 0, sol.Unit_price__c, '$1000 (100% markdown) -> $0. Expecting 6th rule to apply.' );
			}
		}

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		Test.stopTest();
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

	}

	static testMethod void updateInvoicedSOAllowance() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		//Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[0];

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				TF_SET, TF_SET, TF_SET, TF_SET,
				true );

		insert atTypes;

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		insert arTypes;

		TestDataForAllowance.applyManualAllowances( salesOrder.id );

		Test.startTest();

		Allowance_Applied__c[] soAAList = getAppliedRecords( 'Sales_Order__c != null OR Sales_Order_Line__c != null', true, null );

		system.assertEquals( soAAList.size(), 60 );
		
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Invoice_Grouping_Rule__c-'+Invoice_Grouping_Rule__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		insert lConfigs;
		delete [select id from Invoice_Grouping_Rule__c];
		delete lConfigs;
		
		Date dtNow = system.now().date();
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
				Start_Date__c = DateTime.newInstance( dtNow.addMonths( -2 ), Time.newInstance( 0, 0, 0, 0 ) ),
				rank__c = 1,
				Group_By_Customer_Hierarchy__c = 'Bill To',
				Group_By_Sales_Orders__c = true,
				Company__c = fuel.company.Id,
				Use_Billing_Frequency_on_Fulfillment__c = true
		);

		insert igr;
		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
		system.assertEquals( true, igr.is_Valid__c );

		system.assertNotEquals( null, fuel.salesOrder.Id );

		List<Fulfillment__c> fulfill = new List<Fulfillment__c>();
		for ( Sales_Order_Line__c soLine : salesOrder.Sales_Order_Lines__r ) {
			Fulfillment__c f = new Fulfillment__c(
					Customer__c = fuel.customerBillTo.Id,
					Currency__c = fuel.currencyUSD.id,
					Payment_Term__c = fuel.terms.ID,
					Sales_Order_Line__c = soLine.Id,
					Occurrence__c = 'Immediate',
					Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
					Name = 'F1',
					Invoice_Ready__c = true,
					Unit_Price__c = soLine.Unit_Price__c,
					Quantity__c = soLine.Quantity_Ordered__c,
					Fulfillment_Date__c = system.now(),
					Product__c = soLine.Product__c,
					Price_Type__c = 'Sales',
					Status__c = 'Complete' );

			fulfill.add( f );
		}

		insert fulfill;

		//aaList = getAppliedRecords(null, true, null);
		//system.assertEquals(aaList.size(), 1, aaList);

		soAAList = getAppliedRecords( 'Sales_Order__c != null OR Sales_Order_Line__c != null', true, null );

		system.assertEquals( soAAList.size(), 90 );

		// Execute CI Batch
		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Test.stopTest();

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		for ( Allowance_Applied__c aa : soAAList ) {
			aa.Allowance_Amount__c = .123;
		}

		System.debug( loggingLevel.Error, '~*~ soAAList: ' + soAAList );

		try {
			update soAAList;
			system.assert( false, 'Expecting exception to be thrown. Should not be able to update allowance on invoiced SO.' );
		}
		catch ( Exception e ) {

		}

		try {
			delete soAAList;
			system.assert( false, 'Expecting exception to be thrown. Should not be able to delete allowance on invoiced SO.' );
		}
		catch ( Exception e ) {

		}

		try {
			TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries
			system.assert( false, 'Expecting exception to be thrown. Should not be able to create allowance on invoiced SO.' );
		}
		catch ( Exception e ) {

		}
	}

	static testMethod void updateSOAllowanceWhenFulfillmentOnHold() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				F_SET, T_SET, F_SET, T_SET,
				true );

		insert atTypes;

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		insert arTypes;

		TestDataForAllowance.applyManualAllowances( salesOrder.id );

		Reason_Code__c holdCode = new Reason_Code__c();
		holdCode.Company__c = fuel.company.Id;
		holdCode.Type__c = 'Invoice Hold';
		holdCode.Code__c = 'D001';
		insert holdCode;

		Test.startTest();

		Allowance_Applied__c[] soAAList = getAppliedRecords( 'Sales_Order__c != null OR Sales_Order_Line__c != null', true, null );

//		system.assertEquals( soAAList.size(), 10 );

		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
		list<Configuration__c> lConfigs = new list<Configuration__c>();
		lConfigs.add(new Configuration__c(Name = 'Invoice_Grouping_Rule__c-'+Invoice_Grouping_Rule__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
		insert lConfigs;
		delete [select id from Invoice_Grouping_Rule__c];
		delete lConfigs;

		Date dtNow = system.now().date();
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
				Start_Date__c = DateTime.newInstance( dtNow.addMonths( -2 ), Time.newInstance( 0, 0, 0, 0 ) ),
				rank__c = 1,
				Group_By_Customer_Hierarchy__c = 'Bill To',
				Group_By_Sales_Orders__c = true,
				Company__c = fuel.company.Id,
				Use_Billing_Frequency_on_Fulfillment__c = true
		);

		insert igr;
		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
		system.assertEquals( true, igr.is_Valid__c );

		system.assertNotEquals( null, fuel.salesOrder.Id );


		List<Fulfillment__c> fulfill = new List<Fulfillment__c>();
		for ( Sales_Order_Line__c soLine : salesOrder.Sales_Order_Lines__r ) {
			Fulfillment__c f = new Fulfillment__c(
					Customer__c = fuel.customerBillTo.Id,
					Currency__c = fuel.currencyUSD.id,
					Payment_Term__c = fuel.terms.ID,
					Sales_Order_Line__c = soLine.Id,
					Occurrence__c = 'Immediate',
					Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
					Name = 'F1',
					Invoice_Ready__c = true,
					Invoice_Hold__c = true,
					Unit_Price__c = soLine.Unit_Price__c,
					Quantity__c = soLine.Quantity_Ordered__c,
					Fulfillment_Date__c = system.now(),
					Product__c = soLine.Product__c,
					Price_Type__c = 'Sales',
					Reason_Code__c = holdCode.id,
					Status__c = 'Complete' );

			fulfill.add( f );
		}

		insert fulfill;

		soAAList = getAppliedRecords( 'Sales_Order__c != null OR Sales_Order_Line__c != null', true, null );


		Test.stopTest();

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		for ( Allowance_Applied__c aa : soAAList ) {
			aa.Allowance_Amount__c = .123;
		}

		System.debug( loggingLevel.Error, '~*~ soAAList: ' + soAAList );

		try {
			update soAAList;
		}
		catch ( Exception e ) {
			system.assert( false, 'Expecting no exception to be thrown.' );
		}


		soAAList = getAppliedRecords( 'Sales_Order__c != null OR Sales_Order_Line__c != null', true, null );
		for (Allowance_Applied__c aa : soAAList){
			system.assertEquals(aa.Allowance_Amount__c, .123, aa);
		}

	}

	//// expecting errors when trying to update SO allowance that is invoiced
	static testMethod void updateSOAllowancePartiallyInvoiced() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		//Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[0];

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				new Set <String>{
						BASIS_FLAT_AMOUNT
				}, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				T_SET, TF_SET, F_SET, F_SET,
				true );

		insert atTypes;
		system.debug( logginglevel.info, 'test' );
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		insert arTypes;

		Test.startTest();

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries
		Allowance_Applied__c[] soAAList = getAppliedRecords( null, true, null );
		
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Invoice_Grouping_Rule__c-'+Invoice_Grouping_Rule__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
		delete [select id from Invoice_Grouping_Rule__c];
		delete lConfigs;
		
		Date dtNow = system.now().date();
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
				Start_Date__c = DateTime.newInstance( dtNow.addMonths( -2 ), Time.newInstance( 0, 0, 0, 0 ) ),
				rank__c = 1,
				Group_By_Customer_Hierarchy__c = 'Bill To',
				Group_By_Sales_Orders__c = true,
				Company__c = fuel.company.Id,
				Use_Billing_Frequency_on_Fulfillment__c = true
		);

		insert igr;
		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
		system.assertEquals( true, igr.is_Valid__c );

		system.assertNotEquals( null, fuel.salesOrder.Id );

		List<Fulfillment__c> fulfill = new List<Fulfillment__c>();
		for ( Sales_Order_Line__c soLine : salesOrder.Sales_Order_Lines__r ) {
			Fulfillment__c f = new Fulfillment__c(
					Customer__c = fuel.customerBillTo.Id,
					Currency__c = fuel.currencyUSD.id,
					Payment_Term__c = fuel.terms.ID,
					Sales_Order_Line__c = soLine.Id,
					Occurrence__c = 'Immediate',
					Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
					Name = 'F1',
					Invoice_Ready__c = true,
					Unit_Price__c = soLine.Unit_Price__c,
					Quantity__c = soLine.Quantity_Ordered__c - 1,
					Fulfillment_Date__c = system.now(),
					Product__c = soLine.Product__c,
					Price_Type__c = 'Sales',
					Status__c = 'Complete' );

			fulfill.add( f );
		}

		insert fulfill;

		aaList = getAppliedRecords( null, true, null );
		system.assertEquals( aaList.size(), 2, aaList );

		// Execute CI Batch
		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Test.stopTest();

		for ( Allowance_Applied__c aa : soAAList ) {
			System.debug( loggingLevel.Error, '~*~ aa: ' + aa );
			aa.Override_Value__c = .1;
		}

		try {
			update soAAList;
		}
		catch ( Exception e ) {
			system.assert( false, 'Expecting exception to not be thrown.' );
		}
	}

	static testMethod void testDeleteAllowanceTypeRule() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				new Set <String>{
						BASIS_FLAT_AMOUNT
				}, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				TF_SET, TF_SET, TF_SET, TF_SET,
				true );

		insert atTypes;

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		insert arTypes;

		Test.startTest();

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries
		Allowance_Applied__c[] soAAList = getAppliedRecords( null, true, null );

		List<Fulfillment__c> fulfill = new List<Fulfillment__c>();
		for ( Sales_Order_Line__c soLine : salesOrder.Sales_Order_Lines__r ) {
			Fulfillment__c f = new Fulfillment__c(
					Customer__c = fuel.customerBillTo.Id,
					Currency__c = fuel.currencyUSD.id,
					Payment_Term__c = fuel.terms.ID,
					Sales_Order_Line__c = soLine.Id,
					Occurrence__c = 'Immediate',
					Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
					Name = 'F1',
					Invoice_Ready__c = true,
					Unit_Price__c = soLine.Unit_Price__c,
					Quantity__c = soLine.Quantity_Ordered__c,
					Fulfillment_Date__c = system.now(),
					Product__c = soLine.Product__c,
					Price_Type__c = 'Sales',
					Status__c = 'Complete' );

			fulfill.add( f );
		}

		insert fulfill;

		aaList = getAppliedRecords( null, true, null );
		//system.assertEquals(aaList.size(), 18, aaList);

		try {
			delete atTypes;
			system.assert( false, 'Expecting delete to fail.' );
		}
		catch ( Exception e ) {

		}

		try {
			delete arTypes;
			system.assert( false, 'Expecting delete to fail.' );
		}
		catch ( Exception e ) {

		}

		for ( Allowance_Type__c at : atTypes ) {
			at.Amount__c = .08;
		}

		try {
			update atTypes;
			system.assert( false, 'Expecting update to fail.' );
		}
		catch ( Exception e ) {

		}

		for ( Allowance_Rule__c ar : arTypes ) {
			ar.End_Date__c = ar.End_Date__c.addDays( 10 );
		}

		update arTypes;

		for ( Allowance_Rule__c ar : arTypes ) {
			ar.Start_Date__c = ar.Start_Date__c.addDays( 10 );
		}

		try {
			update arTypes;
			system.assert( false, 'Expecting update to fail.' );
		}
		catch ( Exception e ) {
		}

		delete aaList;
		delete atTypes;
		delete arTypes;

	}

	static testMethod void testZeroSOInvocie() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		for ( Sales_Order_Line__c soLine : salesOrder.Sales_Order_Lines__r ) {
			soLine.Unit_Price__c = 0;
		}

		Allowance_Applied__c[] aaList;

		// basis, rates, targets,
		// header, man, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				T_SET, TF_SET, T_SET, F_SET,
				true );

		insert atTypes;

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		insert arTypes;

		TestDataForAllowance.applyManualAllowances( salesOrder.id );

		Test.startTest();

		system.assertNotEquals( null, fuel.salesOrder.Id );

		List<Fulfillment__c> fulfill = new List<Fulfillment__c>();
		for ( Sales_Order_Line__c soLine : salesOrder.Sales_Order_Lines__r ) {
			Fulfillment__c f = new Fulfillment__c(
					Customer__c = fuel.customerBillTo.Id,
					Currency__c = fuel.currencyUSD.id,
					Payment_Term__c = fuel.terms.ID,
					Sales_Order_Line__c = soLine.Id,
					Occurrence__c = 'Immediate',
					Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
					Name = 'F1',
					Invoice_Ready__c = true,
					Unit_Price__c = soLine.Unit_Price__c,
					Quantity__c = soLine.Quantity_Ordered__c,
					Fulfillment_Date__c = system.now(),
					Product__c = soLine.Product__c,
					Price_Type__c = 'Sales',
					Status__c = 'Complete' );

			fulfill.add( f );
		}

		insert fulfill;

		aaList = getAppliedRecords( 'Sales_Order__c != null OR Sales_Order_Line__c != null', true, null );

		system.assertEquals( aaList.size(), 10 );

		// Execute CI Batch
		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Test.stopTest();

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Customer_Invoice__c ci = [select id, (select id, Extended_price__c, Allowances__c from Customer_Invoice_Lines__r) from Customer_Invoice__c LIMIT 1];

		System.debug( loggingLevel.Error, '~*~ cis: ' + ci.Customer_Invoice_Lines__r[ 0 ] );
		system.assertEquals( ci.Customer_Invoice_Lines__r[ 0 ].extended_price__c, ci.Customer_Invoice_Lines__r[ 0 ].Allowances__c );
		system.assertEquals( ci.Customer_Invoice_Lines__r[ 1 ].extended_price__c, ci.Customer_Invoice_Lines__r[ 1 ].Allowances__c );
		system.assertEquals( ci.Customer_Invoice_Lines__r[ 1 ].extended_price__c, 0 );

		//System.debug(loggingLevel.Error, '~*~ cis: ' + ci.);

	}

	static testMethod void testAccrualOnSalesOrderAllowancePage() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		Allowance_Applied__c[] aaList;

		// basis, rates, targets,
		// header, man, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						ACCRUAL
				}, RATES, TARGETS,
				F_SET, TF_SET, F_SET, F_SET,
				true );

		insert atTypes;
		for ( Allowance_Type__c at : atTypes ) {
			System.debug( loggingLevel.Error, '~*~ at: ' + at );
		}

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		insert arTypes;

		TestDataForAllowance.applyManualAllowances( salesOrder.id );

		//aaList =  getAppliedRecords(null, null, null);

		//for (Allowance_Applied__c aa : aaList){
		//	//System.debug(loggingLevel.Error, '~*~ aa.Manual__c: ' + aa.Allowance_Type__r.Manual__c + ' ' + aa.BillBack_Commitment__c  +  ' ' + aa.Allowance_Amount__c);
		//	System.assert(aa.BillBack_Commitment__c != null && aa.Allowance_Amount__c == null, 'Allowance Accrual check: ' + aa);
		//}

		//system.assertEquals(10, aaList.size() , ' Epxected  nonfreight allowance');

		ApexPages.StandardController con = new ApexPages.StandardController( salesOrder );
		SalesOrderAllowancesExt ext = new SalesOrderAllowancesExt( con );
		ext.setAllowances();
		Test.setCurrentPage( Page.SalesOrderAllowances );

		system.assertEquals( 2, ext.allLines.size(), ' should have 2 salesOrder lines' );

		test.startTest();

		aaList = getAppliedRecords( null, null, null );

		for ( Allowance_Applied__c aa : aaList ) {
			System.debug( loggingLevel.Error, '~*~ aa.Manual__c: ' + aa.Allowance_Type__r.Manual__c + ' ' + aa.BillBack_Commitment__c + ' ' + aa.Allowance_Amount__c );
			System.assert( aa.BillBack_Commitment__c != null && aa.Allowance_Amount__c == null, 'Allowance Accrual check: ' + aa );
		}

		system.assertEquals( 20, aaList.size(), ' Epxected  nonfreight allowance' );
	}

	static testmethod void testDiscountPercentWithAllowanceCalculation() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order_Line__c sol = new Sales_order_Line__c();
		sol.Company__c = fuel.company.Id;
		sol.Sales_order__c = fuel.salesOrder.Id;
		sol.Quantity_Ordered__c = 1;
		sol.Unit_Price__c = 100;
		sol.Off_Invoice_Rate__c = 5;
		sol.Discount_Percent__c = 10;
		sol.Allowances__c = 9;
		sol.Freight_Allowance__c = 3;
		sol.product__c = fuel.product.Id;
		insert sol;

		Test.StartTest();

		sol = [select id, Line_Total__c from Sales_Order_line__c where Id = :sol.Id];

		// qtyMult * (unitPrice - offInvoiceRate) * (1 - (discountPercent / 100)) + allowances - freightAllowances);
		// 1 * (100 - 5) * (1 - (10 / 100)) + 9 - 3) = 95 * .9 + 6 = 91.5
		system.assertEquals( 91.5, sol.Line_Total__c, 'Problem with the SOL Line Total forumla.' );

		sol.Quantity_Fulfilled__c = 1;
		sol.Unit_Price__c = 200;
		update sol;
		sol = [select id, Line_Total__c from Sales_Order_line__c where Id = :sol.Id];
		system.assertEquals( 91.5, sol.Line_Total__c, 'Expecting total to remain the same since line has fulfillment qty' );

		Customer_Invoice__c ci = new Customer_Invoice__c( Date_Invoiced__c = system.now(), Status__c = 'new', transaction_date__c = system.now() );
		insert ci;

		Customer_Invoice_Line__c cil = new Customer_Invoice_Line__c();
		cil.Company__c = fuel.company.Id;
		cil.Sales_order__c = fuel.salesOrder.Id;
		cil.Sales_Order_Line__c = sol.Id;
		cil.Customer_Invoice__c = ci.Id;
		cil.Quantity_Shipped__c = 1;
		cil.Unit_Price__c = 100;
		cil.Off_Invoice_Rate__c = 5;
		cil.Discount_Percent__c = 10;
		cil.Allowances__c = 9;
		cil.Freight_Allowance__c = 3;
		cil.product__c = fuel.product.Id;
		insert cil;

		cil = [select id, Extended_price__c from Customer_Invoice_Line__c where Id = :cil.Id];

		system.assertEquals( 91.5, cil.Extended_price__c );

	}

	static testMethod void testAllowanceCreationOnSOCreate() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		Test.startTest();
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						ACCRUAL, CHARGE, DISCOUNT
				}, RATES, TARGETS,
				TF_SET, TF_SET, TF_SET, TF_SET,
				true );

		insert atTypes;
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );

		insert arTypes;

		Sales_Order__c newSalesOrder = salesOrder.clone( false, true );
		insert newSalesOrder;

		Sales_Order_Line__c newSOL = soLine.clone( false, true );
		newSOL.Sales_Order__c = newSalesOrder.Id;
		insert newSOL;

		Test.stopTest();

		System.assert( ApexPages.getMessages().size() == 0, ApexPages.getMessages() );
	}

	static testmethod void ciVoidCancelOneTimeAllowance() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		delete salesOrder.Sales_Order_Lines__r[ 1 ]; // deleting to keep counting e

		List<Allowance_Applied__c> aaList;

		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				F_SET, TF_SET, T_SET, F_SET,
				true );
		insert atTypes;

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );

		insert arTypes;

		Test.startTest();

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries
		aaList = getAppliedRecords( null, true, null );
		
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Invoice_Grouping_Rule__c-'+Invoice_Grouping_Rule__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
		// manually create the IGR
		delete [select id from Invoice_Grouping_Rule__c];
		delete lConfigs;
		
		Date dtNow = system.now().date();
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
				Start_Date__c = DateTime.newInstance( dtNow.addMonths( -2 ), Time.newInstance( 0, 0, 0, 0 ) ),
				rank__c = 1,
				Group_By_Customer_Hierarchy__c = 'Bill To',
				Group_By_Sales_Orders__c = true,
				Company__c = fuel.company.Id,
				Use_Billing_Frequency_on_Fulfillment__c = true
		);

		insert igr;

		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];

		system.assertEquals( true, igr.is_Valid__c );
		system.assertNotEquals( null, fuel.salesOrder.Id );

		Fulfillment__c f = new Fulfillment__c(
				Customer__c = fuel.customerBillTo.Id,
				Currency__c = fuel.currencyUSD.id,
				Payment_Term__c = fuel.terms.ID,
				Sales_Order_Line__c = soLine.Id,
				Occurrence__c = 'Immediate',
				Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
				Name = 'F1',
				Invoice_Ready__c = true,
				Unit_Price__c = 100,
				Quantity__c = 2,
				Fulfillment_Date__c = system.now(),
				Product__c = soline.Product__c, Price_Type__c = 'Sales',
				Status__c = 'Complete' );

		insert f;

		aaList = getAppliedRecords( null, true, null );

		// Execute CI Batch
		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		Test.stopTest();

		//Customer_Invoice__c customerInvoice = [select id from Customer_Invoice__c];
		aaList = getAppliedRecords( 'Customer_Invoice2__c != null OR Customer_Invoice_Line__c != null', true, null );

		system.assertEquals( aaList.size(), 10 );

		for ( Allowance_Applied__c aa : aaList ) {
			system.assert( aa.Unique_Key__c != null, aa );
		}

		Customer_invoice__C CustomerInvoice = [
				Select Id, Name, Status__c, shipment__C, Invoice_Type__c, company__c,Void_Date__c,Finalized__c, Balance__c, Void__c, Sales_Order__c, Total_Amount__c, Transaction_Date__c, Finalized_Date__c, Posting_Date__c, Historical__c, Currency__c, (Select id, Shipment__c, Sales_Order_Line__c from Customer_Invoice_Lines__r), (Select id from Customer_Receipt_Lines__r where Finalized__c = true), (select id, name from Accounting_Entries__r where status__c = 'Active' and Has_Exceptions__c != true)
				From Customer_Invoice__c
		];


		CustomerInvoiceVoidCancelExt ext = new CustomerInvoiceVoidCancelExt( new ApexPages.standardController( customerInvoice ) );
		ext.cancelDocs();
		aaList = getAppliedRecords( 'Customer_Invoice2__c != null OR Customer_Invoice_Line__c != null', true, null );
		system.assertEquals( aaList.size(), 10 );

		for ( Allowance_Applied__c aa : aaList ) {
			system.assert( aa.Unique_Key__c == null, aa );
		}
	}

	static testMethod void accrualsAllowanceTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		delete salesOrder.Sales_Order_Lines__r[ 1 ]; // deleting to keep counting e

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, types, rates, targets,
		// header, man, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						ACCRUAL
				}, RATES, TARGETS,
				F_SET, TF_SET, F_SET, F_SET,
				true );

		//system.assertEquals(60, atTypes.size()); // 60 header, 60 lines.
		insert atTypes;
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		system.assertEquals( 10, arTypes.size() );

		insert arTypes;

		Test.startTest();

		TestDataForAllowance.applyManualAllowances( salesOrder.id, true ); // 12 queries

		// trigger allowances to run
		soLine.Quantity_Ordered__c += 1;
		update soLine;

		new SalesOrderService().plan( salesOrder.id );
		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		aaList = getAppliedRecords( null, true, null );
		system.assertEquals( 10, aaList.size() );
		//System.debug(loggingLevel.Error, '~*~ soLine: ' + soLine);
		//for (Allowance_Applied__c aa : aaList){
		//	System.debug(loggingLevel.Error, '~*~ aa: ' + aa);
		//	System.debug(loggingLevel.Error, '~*~ aa.Allowance_rule2__r: ' + aa.Allowance_rule2__r);
		//	System.debug(loggingLevel.Error, '~*~ aa.Allowance_Type__r: ' + aa.Allowance_Type__r + '\n');
		//}

		List<Fulfillment__c> accrualFul = [
				select id, Type__c, Allowance_Applied__c, Unit_Price__c, Extended_price__c, Quantity__c, Customer__c
				from Fulfillment__c
				where Allowance_Applied__c != null
		];

		system.assertEquals( 0, accrualFul.size(), accrualFul );

		Fulfillment__c f = new Fulfillment__c( Customer__c = fuel.customerBillTo.Id,
				Currency__c = fuel.currencyUSD.id,
				Payment_Term__c = fuel.terms.ID,
				Sales_Order_Line__c = soLine.Id,
				Occurrence__c = 'Immediate',
				Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
				Name = 'F1',
				Invoice_Ready__c = true,
				Unit_Price__c = 100,
				Quantity__c = 2,
				Fulfillment_Date__c = system.now(),
				Product__c = soline.Product__c, Price_Type__c = 'Sales',
				Status__c = 'Complete' );

		insert f;

		List<Fulfillment__c> accrualF = [
				select id, Type__c, Allowance_Applied__c, Unit_Price__c, Extended_price__c, Quantity__c, Customer__c
				from Fulfillment__c
				where Allowance_Applied__c != null
		];

		//for (Fulfillment__c ful : accrualF){
		//	System.debug(loggingLevel.Error, '~*~ accrualF: ' + ful.Allowance_Applied__c + ' ' + ful);
		//}
		system.assertEquals( 10, accrualF.size(), accrualF );

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ) );

		Test.stopTest();

		for ( Fulfillment__c ful : accrualF ) {
			system.assertEquals( ful.Type__c, ALLOWANCE_ACCRUAL );
			system.assert( ful.Extended_Price__c < 0, f.Extended_Price__c );
			//system.assertEquals(ful.Quantity__c, 1);
			system.assert( ful.Customer__c != null );
		}

		aaList = getAppliedRecords( null, true, null );
		System.assertequals( 10, aaList.size() );

		System.assert( ApexPages.getMessages().size() == 0, ApexPages.getMessages() );
	}

	static testMethod void applyMultipleManualAllowances() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		delete salesOrder.Sales_Order_Lines__r[ 1 ]; // deleting to keep counting easier. Costs 9 queries
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, types, rates, targets,
		// header, man, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				TF_SET, T_SET, TF_SET, TF_SET,
				true );

		//for (Allowance_TYpe__c at : atTypes) {
		//	System.debug(loggingLevel.Error, '~*~ at.Name: ' + at.Name);
		//}
		system.assertEquals( 40, atTypes.size() ); // 60 header, 60 lines.
		insert atTypes;

		// Create 3 sets of rules.
		// 1st set: Contains all types with date range today to day 6. (week 1) - count 60
		// 2nd set: contains all types that are charges. Date Range day 7 to day 13. (week 2) - count 30
		// 3rd set: contains all types that are discount. Date Range day 14 to day 20. (week 3) - count 30
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		system.assertEquals( 40 + 20 + 20, arTypes.size() );
		insert arTypes;

		Test.startTest();

		TestDataForAllowance.applyManualAllowances( salesOrder.id, true ); // 12 queries
		aaList = getAppliedRecords( null, true, null );
		system.assertEquals( 40, aaList.size(), 'expecting lose 80 auto discount.' );

		TestDataForAllowance.applyManualAllowances( salesOrder.id, false ); // 12 queries
		aaList = getAppliedRecords( null, true, null );
		system.assertEquals( 60, aaList.size(), 'expecting 80 + 80 on manual reapply.' );

		TestDataForAllowance.applyManualAllowances( salesOrder.id, false ); // 12 queries
		aaList = getAppliedRecords( null, true, null );
		system.assertEquals( 80, aaList.size(), 'expecting 160 + 80 on manual reapply.' );
	}

	static testMethod void ciHeaderSplitLinesTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		//Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[0];

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				new Set <String>{
						BASIS_FLAT_AMOUNT
				}, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				T_SET, TF_SET, F_SET, F_SET,
				true );

		insert atTypes;

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		insert arTypes;

		Test.startTest();

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries
		aaList = getAppliedRecords( null, true, null );
		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Invoice_Grouping_Rule__c-'+Invoice_Grouping_Rule__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
		delete [select id from Invoice_Grouping_Rule__c];
		delete lConfigs;
		
		Date dtNow = system.now().date();
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
				Start_Date__c = DateTime.newInstance( dtNow.addMonths( -2 ), Time.newInstance( 0, 0, 0, 0 ) ),
				rank__c = 1,
				Group_By_Customer_Hierarchy__c = 'Bill To',
				Group_By_Sales_Orders__c = true,
				Company__c = fuel.company.Id,
				Use_Billing_Frequency_on_Fulfillment__c = true
		);

		insert igr;
		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
		system.assertEquals( true, igr.is_Valid__c );

		system.assertNotEquals( null, fuel.salesOrder.Id );

		List<Fulfillment__c> fulfill = new List<Fulfillment__c>();
		for ( Sales_Order_Line__c soLine : salesOrder.Sales_Order_Lines__r ) {
			Fulfillment__c f = new Fulfillment__c(
					Customer__c = fuel.customerBillTo.Id,
					Currency__c = fuel.currencyUSD.id,
					Payment_Term__c = fuel.terms.ID,
					Sales_Order_Line__c = soLine.Id,
					Occurrence__c = 'Immediate',
					Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
					Name = 'F1',
					Invoice_Ready__c = true,
					Unit_Price__c = soLine.Unit_Price__c,
					Quantity__c = soLine.Quantity_Ordered__c,
					Fulfillment_Date__c = system.now(),
					Product__c = soLine.Product__c,
					Price_Type__c = 'Sales',
					Status__c = 'Complete' );

			fulfill.add( f );
		}

		insert fulfill;

		aaList = getAppliedRecords( null, true, null );
		system.assertEquals( aaList.size(), 2, aaList );

		// Execute CI Batch
		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Test.stopTest();

		aaList = getAppliedRecords( 'Customer_Invoice2__c != null OR Customer_Invoice_Line__c != null', true, null );
		system.assert( aaList.size() == 4, 'Expecting 2 header allowances to be split onto each line.' + aaList );

		for ( Allowance_Applied__c aa : aaList ) {
			system.assert( aa.Customer_invoice2__c == null, 'Expecting no AA on CI:' + aa );
			system.assert( aa.Allowance_Applied__c != null, 'Expecting reference to SO Header allowance' );
		}
	}

	static testMethod void copyRMAFromSOWithAllowanceTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		//delete salesOrder.Sales_Order_Lines__r[1];
		List<Allowance_Applied__c> aaList;

		// Create Allowances
		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, new Set<String>{
						CHARGE
				}, RATES, TARGETS,
				TF_SET, TF_SET, TF_SET, TF_SET,
				true );

		system.assertEquals( 60, atTypes.size() ); // 0 header, 30 lines where 15 are One-Time
		insert atTypes;

		System.debug( loggingLevel.Error, '~*~ Limits.getQueries(): ' + Limits.getQueries() );
		test.StartTest();

		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		system.assertEquals( 120, arTypes.size() );
		insert arTypes;

		// 14 queries!
		TestDataForAllowance.applyManualAllowances( salesOrder.id );

		Fulfillment__c f = new Fulfillment__c(
				Customer__c = fuel.customerBillTo.Id,
				Currency__c = fuel.currencyUSD.id,
				Payment_Term__c = fuel.terms.ID,
				Sales_Order_Line__c = soLine.Id,
				Occurrence__c = 'Immediate',
				Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
				Name = 'F1',
				Invoice_Ready__c = true,
				Unit_Price__c = soLine.Unit_Price__c,
				Quantity__c = soLine.Quantity_Ordered__c,
				Fulfillment_Date__c = system.now(),
				Product__c = soLine.Product__c, Price_Type__c = 'Sales', Status__c = 'Complete' );

		// 44 queries!
		insert f;

		System.debug( loggingLevel.Error, '~*~ Limits.getQueries(): ' + Limits.getQueries() );
		aaList = getAppliedRecords( 'Sales_Order__c = \'' + salesOrder.id + '\' OR Sales_Order_line__r.Sales_Order__c = \'' + salesOrder.id + '\'', null, null );

		System.assertEquals( aaList.size(), 90 );

		salesOrder = [select id, Allowances__c, (select id, Allowances__c from Sales_order_Lines__r) from Sales_Order__c where Id = :salesOrder.id];
		system.assert( salesOrder.Allowances__c > 0, 'Expecting negative charges because this is a regular order. ' + salesOrder.Allowances__c );
		system.assert( salesOrder.Sales_order_Lines__r[ 0 ].Allowances__c > 0, 'Expecting positive charges because this is a regular order. ' + salesOrder.Sales_order_Lines__r[ 0 ].Allowances__c );

		System.debug( loggingLevel.Error, '~*~ Limits.getQueries(): ' + Limits.getQueries() );
		JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines( salesOrder.id );
		List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

		for ( SalesOrderRMAExt.SalesOrderLineWrapper obj : ( List<SalesOrderRMAExt.SalesOrderLineWrapper> ) rmaLinesResult.records ) {
			if ( obj.soLine.quantity_fulfilled__c > 0 ) {
				obj.soLine.Quantity_Ordered__c = 10;
				solList.add( obj.soLine );
			}
		}

		Sales_order__c header = ( Sales_Order__c ) SalesOrderRMAExt.getSODetails( salesOrder.id ).records[ 0 ];

		System.debug( loggingLevel.Error, '~*~ Limits.getQueries(): ' + Limits.getQueries() );
		JsonResult rma = SalesOrderRMAExt.createRMA( solList, header, new List<String>() );
		system.assert( rma.messages.size() == 0, rma.messages );

		Sales_Order__c rmaOrder = ( Sales_Order__c ) rma.records[ 0 ];

		System.debug( loggingLevel.Error, '~*~ Limits.getQueries(): ' + Limits.getQueries() );

		test.stopTest();

		aaList = getAppliedRecords( 'Sales_Order__c = \'' + rmaOrder.id + '\' OR Sales_Order_line__r.Sales_Order__c = \'' + rmaOrder.id + '\'', null, null );
		System.assertequals( aaList.size(), 80 );

		rmaOrder = [select id, Allowances__c, (select id, Allowances__c, Quantity_Ordered__c, Quantity_Shipped__c, Quantity_Fulfilled__c from Sales_order_Lines__r) from Sales_Order__c where Id = :rmaOrder.id];

		System.debug( loggingLevel.Error, '~*~ Limits.getQueries(): ' + Limits.getQueries() );

		system.assert( rmaOrder.Allowances__c < 0, 'Expecting negative charges because this is RMA. ' + rmaOrder.Allowances__c );
		Sales_Order_Line__c rmaLine = rmaOrder.Sales_order_Lines__r[ 0 ];
		system.assert( rmaLine.Allowances__c < 0, 'Expecting negative charges because this is RMA. ' + rmaLine.Allowances__c );

		aaList = getAppliedRecords( 'Sales_Order_Line__c = \'' + rmaLine.id + '\'', null, null );
		system.assert( aaList.size() == 50, aaList.size() );

		Decimal oldRMALineAllowances = rmaLine.Allowances__c;
		system.assert( rmaLine.Quantity_Ordered__c < 0, rmaLine.Quantity_Ordered__c + ' should be negative.' );
		rmaLine.Quantity_Ordered__c = rmaLine.Quantity_Ordered__c + 1;

		update rmaLine;

		System.debug( loggingLevel.Error, '~*~ Limits.getQueries(): ' + Limits.getQueries() );
		rmaLine = [select id, Allowances__c from Sales_Order_Line__c where id = :rmaLine.id];

		System.debug( loggingLevel.Error, '~*~ oldRMALineAllowances: ' + oldRMALineAllowances );
		System.debug( loggingLevel.Error, '~*~ rmaLine: ' + rmaLine );

		system.assert( rmaLine.Allowances__c != oldRMALineAllowances, oldRMALineAllowances + ' should not equal ' + rmaLine.Allowances__c );

		aaList = getAppliedRecords( 'Sales_Order_Line__c = \'' + rmaLine.id + '\'', null, null );
		system.assert( aaList.size() == 50, aaList.size() );
		//for (Allowance_Applied__c aa : aaList){
		//System.debug(loggingLevel.Error, '~*~ aa: ' + aa.Allowance_Amount__c + ' ' + aa.Allowance_rule2__r.Name);
		//}
		system.assert( rmaLine.Allowances__c < 0, 'Expecting negative charges because this is a RMA. ' + rmaLine.Allowances__c );
	}

	static testMethod void pricingDateUpdateWithRMATest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		delete salesOrder.Sales_Order_Lines__r[ 1 ];

		test.StartTest();

		Fulfillment__c f = new Fulfillment__c(
				Customer__c = fuel.customerBillTo.Id,
				Currency__c = fuel.currencyUSD.id,
				Payment_Term__c = fuel.terms.ID,
				Sales_Order_Line__c = soLine.Id,
				Occurrence__c = 'Immediate',
				Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
				Name = 'F1',
				Invoice_Ready__c = true,
				Unit_Price__c = soLine.Unit_Price__c,
				Quantity__c = soLine.Quantity_Ordered__c,
				Fulfillment_Date__c = system.now(),
				Product__c = soLine.Product__c, Price_Type__c = 'Sales', Status__c = 'Complete' );

		insert f;

		JsonResult rmaLinesResult = SalesOrderRMAExt.getSalesOrderLines( salesOrder.id );
		List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

		for ( SalesOrderRMAExt.SalesOrderLineWrapper obj : ( List<SalesOrderRMAExt.SalesOrderLineWrapper> ) rmaLinesResult.records ) {
			obj.soLine.Quantity_Ordered__c = 10;
			solList.add( obj.soLine );
		}

		Sales_order__c header = ( Sales_Order__c ) SalesOrderRMAExt.getSODetails( salesOrder.id ).records[ 0 ];

		JsonResult rma = SalesOrderRMAExt.createRMA( solList, header, new List<String>() );

		system.assert( rma.messages.size() == 0, rma.messages );
		System.debug( loggingLevel.Error, '~*~ rma: ' + rma );

		Sales_Order__c rmaOrder = ( Sales_Order__c ) rma.records[ 0 ];

		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, ALL_TYPES, RATES, TARGETS,
				TF_SET, TF_SET, TF_SET, TF_SET,
				true );

		system.assertEquals( 120, atTypes.size() ); // 0 header, 30 lines where 15 are One-Time
		insert atTypes;

		//System.debug(loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries());

		// Create 3 sets of rules.
		// 1st set: Contains all types with date range today to day 6. (week 1) - count 60
		// 2nd set: contains all types that are charges. Date Range day 7 to day 13. (week 2) - count 30
		// 3rd set: contains all types that are discount. Date Range day 14 to day 20. (week 3) - count 30
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		system.assertEquals( 240, arTypes.size() );
		insert arTypes;

		rmaOrder.Price_Determination_Date__c = SalesOrderService.PRICE_DET_ORDER;
		rmaOrder.Date_Time_Ordered__c = system.today() + 1;
		update rmaOrder;

		Sales_Order_Line__c rmaLine = [select id from Sales_Order_Line__c where sales_order__c = :rmaOrder.id];
		rmaLine.Ordered_Date_Time__c = system.today() + 1;
		update rmaLine;

		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );
		System.assertequals( aaList.size(), 0 );
	}

	static testMethod void oneTimeAllowanceTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Id soId = salesOrder.Id;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		delete salesOrder.Sales_Order_Lines__r[ 1 ]; // deleting to keep counting easier. Costs 9 queries

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, types, rates, targets,
		// header, man, oneTime, override
		// manualOverridesOnly

		// 0 header, 30 lines where 15 are One-Time. 20 Manuals
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, ALL_TYPES, RATES, TARGETS,
				F_SET, TF_SET, T_SET, TF_SET,
				true );

		system.assertEquals( 30, atTypes.size() );
		insert atTypes;
		//for (Allowance_Type__c at : atTypes){
		//	System.debug(loggingLevel.Error, '~*~ at: ' + at.Name);
		//}

		//System.debug(loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries());

		// Create 3 sets of rules.
		// 1st set: Contains all types with date range today to day 6. (week 1) - count 60
		// 2nd set: contains all types that are charges. Date Range day 7 to day 13. (week 2) - count 30
		// 3rd set: contains all types that are discount. Date Range day 14 to day 20. (week 3) - count 30
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		system.assertEquals( 30 + 30, arTypes.size() );
		insert arTypes;

		Test.startTest();

		new SalesOrderService().plan( salesOrder.id );
		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		// upserted 20
		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries
		aaList = getAppliedRecords( null, true, 'After shipping AA - Using 3rd set of rules' );
		//for (Allowance_Applied__c aa : aaList){
		//	System.debug(loggingLevel.Error, '~*~ aa: ' + aa.Allowance_Type__r.Name + '\n' + aa.Allowance_rule2__r.Name + '\n');
		//}
		system.assertEquals( 20, aaList.size(), 'Maintaining the same amount of AA as before.' );

		User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
	    list<Configuration__c> lConfigs = new list<Configuration__c>();
	    lConfigs.add(new Configuration__c(Name = 'Invoice_Grouping_Rule__c-'+Invoice_Grouping_Rule__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
	    insert lConfigs;
		delete [select id from Invoice_Grouping_Rule__c];
		delete lConfigs;
		
		Date dtNow = system.now().date();
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
				Start_Date__c = DateTime.newInstance( dtNow.addMonths( -2 ),
						Time.newInstance( 0, 0, 0, 0 ) ),
				rank__c = 1,
				Group_By_Customer_Hierarchy__c = 'Bill To',
				Group_By_Sales_Orders__c = true,
				Company__c = fuel.company.Id,
				Use_Billing_Frequency_on_Fulfillment__c = true
		);

		insert igr;
		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
		system.assertEquals( true, igr.is_Valid__c );

		system.assertNotEquals( null, fuel.salesOrder.Id );
		list<Sales_Order_Line__c> lSOLs = [Select Id, Product__c from Sales_Order_Line__c where Sales_Order__c = :fuel.salesOrder.Id];

		soLine.Start_Date__c = DateTime.newInstance( Date.newInstance( 2015, 4, 1 ), Time.newInstance( 0, 0, 0, 0 ) );
		soLine.End_Date__c = DateTime.newInstance( Date.newInstance( 2015, 6, 1 ), Time.newInstance( 0, 0, 0, 0 ) );
		soLine.Rate_Basis__c = 'Quantity';

		update soLine;

		Fulfillment__c f = new Fulfillment__c(
				Customer__c = fuel.customerBillTo.Id,
				//Start_Date__c = DateTime.newInstance(dtNow.addMonths(-2), Time.newInstance(0,0,0,0)),
				Currency__c = fuel.currencyUSD.id,
				Payment_Term__c = fuel.terms.ID,
				Sales_Order_Line__c = soLine.Id,
				Occurrence__c = 'Monthly',
				Name = 'F1',
				Invoice_Ready__c = true,
				Unit_Price__c = 100,
				Quantity__c = 1,
				Product__c = soLine.Product__c,
				Price_Type__c = 'Recurring',
				Pricing_UOM__c = fuel.CALENDAR_MONTH.Id,
				Billing_UOM__c = fuel.CALENDAR_MONTH.Id,
				Recurrence_Start_Date__c = DateTime.newInstance( Date.newInstance( 2015, 3, 24 ),
						Time.newInstance( 0, 0, 0, 0 ) ),
				Status__c = 'Complete'
		);

		insert f;

		// Expecting SOLINE qty fulfilled to increase
		aaList = getAppliedRecords( null, true, 'After shipping AA - Using 3rd set of rules' );
		//for (Allowance_Applied__c aa : aaList){
		//	System.debug(loggingLevel.Error, '~*~ aa: ' + aa.Allowance_Type__r.Name + '\n' + aa.Allowance_rule2__r.Name + '\n');
		//}
		system.assertEquals( 30, aaList.size(), 'Maintaining the same amount of AA as before.' );

		// Execute CI Batch
		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Test.stopTest();

		List <Customer_Invoice__c> custInvList = [
				Select id, Name, Sales_Order__c, Bill_To_Customer__c, Company__c, Subtotal__c, Payment_Term__c, Finalized__c, (
						Select id, Name, Line_Type__c, Customer_Invoice__c, Off_Invoice_Rate__c, BillBack_Rate__c, List_Price__c
						from Customer_Invoice_Lines__r
						Order By Id
				)
				from Customer_Invoice__c
				Order By Id
		];

		SOQLUtil soql = new SOQLUtil( 'Customer_Invoice_Line__c', true ); //enforceFLS=true, running in user mode
		soql.addFields( new set<string>{
				'Id', 'Name', 'Line_Type__c', 'Customer_Invoice__c', 'Off_Invoice_Rate__c', 'BillBack_Rate__c', 'List_Price__c'
		} );
		soql.setWhereClause( 'Sales_Order__c = :soId' );
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship( soql, 'Allowances_Applied__r' );
		childRel.addFields( AllowanceRuleService.allowanceAppliedFields );
		childRel.setWhereClause( 'Source__c!=\'Trade\'' );
		soql.addChildRelationship( childRel );
		Map<id, Customer_Invoice_Line__c> ciLines = new map<id, Customer_Invoice_Line__c>( ( List<Customer_Invoice_Line__c> ) Database.query( soql.getQuery() ) );

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil( 'Customer_Invoice__c', true ); //enforceFLS=true, running in user mode
		soql.addFields( new set<string>{
				'Id', 'Name', 'Sales_Order__c', 'Bill_To_Customer__c', 'Company__c', 'Subtotal__c', 'Payment_Term__c', 'Finalized__c'
		} );
		soql.setWhereClause( 'Sales_Order__c = :soId' );
		SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship( soql, 'Allowances_Applied1__r' );
		childRel2.addFields( AllowanceRuleService.allowanceAppliedFields );
		childRel2.setWhereClause( 'Source__c!=\'Trade\'' ); //KNDY-6032
		soql.addChildRelationship( childRel2 );
		Map<id, Customer_Invoice__c> ciHdrs = new map<id, Customer_Invoice__c>( ( List<Customer_Invoice__c> ) Database.query( soql.getQuery() ) );

		system.assertEquals( 3, ciHdrs.keySet().size() );
		system.assertEquals( 3, ciLines.keySet().size() );

		//for (Customer_invoice__c ci : ciHdrs.values()) {
		//	System.debug(loggingLevel.Error, '~*~ ci aa size: ' + ci.Allowances_Applied1__r.size());
		//}

		//for (Customer_Invoice_Line__c cil : ciLines.values()) {
		//	System.debug(loggingLevel.Error, '~*~ cil aa size: ' + cil.Allowances_Applied__r.size());
		//}
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		aaList = getAppliedRecords( 'Customer_Invoice_Line__c != null OR customer_invoice2__c != null', true, 'Firing CI batch for CIL AA - Using 3rd set of rules' );
		//for (Allowance_Applied__c aa : aaList){
		//	System.debug(loggingLevel.Error, '~*~ aa: ' + aa.Allowance_Type__r + '\n' + aa.Allowance_rule2__r + '\n');
		//}
		system.assertEquals( 30, aaList.size(), 'Expecting same amount because all allowances are one-time.' );

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
	}

	static testMethod void CILManualAllowanceTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
//		delete salesOrder.Sales_Order_Lines__r[ 1 ]; // deleting to keep counting easier. Costs 9 queries
//		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, rates, targets,
		// header, man, chrg, oneTime, override
		// manualOverridesOnly
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, ALL_TYPES, RATES, TARGETS,
				F_SET, TF_SET, TF_SET, TF_SET,
				true );
		System.debug( loggingLevel.Error, '~*~ atTypes: ' + atTypes );
		system.assertEquals( 60, atTypes.size() ); // 60 header, 60 lines.
		insert atTypes;

		Integer manualLineCount = 0;
		for ( Allowance_Type__c at : atTypes ) {
			if ( at.Manual__c && !at.Apply_At_Header__c ) {
				manualLineCount++;
			}
		}
		system.assertEquals( manualLineCount, 40 );
		//System.debug(loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries());

		// Create 3 sets of rules.
		// 1st set: Contains all types with date range today to day 6. (week 1) - count 60
		// 2nd set: contains all types that are charges. Date Range day 7 to day 13. (week 2) - count 30
		// 3rd set: contains all types that are discount. Date Range day 14 to day 20. (week 3) - count 30
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		system.assertEquals( 60 + 30 + 30, arTypes.size() );
		insert arTypes;

		solDT = System.now() + 14;
		soLine.Ordered_Date_Time__c = solDT;
		update soLine;
		Test.startTest();

		System.debug( loggingLevel.Error, '~*~ Limits Query CT: ' + Limits.getQueries() );
		System.debug( loggingLevel.Error, '~*~ Limits CPU Time: ' + Limits.getCPUTime() );

		aaList = getAppliedRecords( 'Sales_order_Line__c = \'' + soLine.Id + '\'', true, 'Repricing - 3rd set of rules' );
		system.assertEquals( 10, aaList.size(), 'expecting lose 10 auto discount.' );
		Sales_Order_line__c sol = aaList[ 0 ].Sales_order_line__r;

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries
		aaList = getAppliedRecords( 'Sales_order_Line__c = \'' + soLine.Id + '\'', true, 'Repricing - 3rd set of rules' );
		system.assertEquals( 30, aaList.size(), 'expecting to gain 20 manuals including 10 overrides.' );

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		new SalesOrderService().plan( salesOrder.id );
		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller( salesOrder );
		SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
		System.debug( loggingLevel.Error, '~*~ CONFIRMING TO SHIP: ' );
		socsExt.confirmShip();

		aaList = getAppliedRecords( 'Sales_order_Line__c = \'' + soLine.Id + '\'', true, 'After shipping AA - Using 3rd set of rules' );
		//for (Allowance_Applied__c aa : aaList) {
		//System.debug(loggingLevel.Error, '~*~ aa: ' + aa.Allowance_Type__r + '\n' + aa.Allowance_rule2__r + '\n');
		//}
		system.assertEquals( 30, aaList.size(), 'Maintaining the same amount of AA as before.' );

		shipment_line__c[] shls = [
				Select Id, Quantity_Shipped__c, Quantity_Planned__c, Sales_order__r.Status__c, Sales_order_Line__c, Shipment__r.Status__c, Shipment__r.Date_Shipped__c, Sales_order__r.Date_Time_Ordered__c, Sales_order__r.Pricing_Date__c
				from Shipment_Line__c
		];

		for ( shipment_line__c shl : shls ) {
			system.assertEquals( 'Confirmed', shl.shipment__r.Status__c );
		}

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Test.stopTest();

		List<Customer_Invoice__c> ci = [select id from Customer_Invoice__c];
		system.assert( ci != null );

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		aaList = getAppliedRecords( 'Customer_Invoice_Line__r.Sales_order_Line__c = \'' + soLine.Id + '\'', true, 'Firing CI batch for CIL AA - Using 3rd set of rules' );
		//for (Allowance_Applied__c aa : aaList){
		//	System.debug(loggingLevel.Error, '~*~ aa: ' + aa.Allowance_Type__r + '\n' + aa.Allowance_rule2__r + '\n');
		//}
		system.assertEquals( 30, aaList.size(), 'Maintaining the same amount of AA as before.' );

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
	}

	// CPU Timeout issue
	static testMethod void manualLineAllowanceRepriceTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder; //asdasdasdj
		Sales_Order_Line__c soLine = salesOrder.Sales_Order_Lines__r[ 0 ];
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );
		delete salesOrder.Sales_Order_Lines__r[ 1 ]; // deleting to keep counting easier. Costs 9 queries
		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Allowance_Applied__c[] aaList;
		DateTime solDT;

		// basis, rates, targets, asdas
		// header, man, chrg, oneTime, override
		// manualOverridesOnly asd
		List<Allowance_Type__c> atTypes = TestDataForAllowance.createAllowanceTypes(
				ALL_BASIS, ALL_TYPES, RATES, TARGETS,
				F_SET, TF_SET, TF_SET, TF_SET,
				true );

		system.assertEquals( 60, atTypes.size() ); // 60 lines. 30 Auto, 30 Manual
		insert atTypes;

		Integer manualLineCount = 0;
		for ( Allowance_Type__c at : atTypes ) {
			if ( at.Manual__c && !at.Apply_At_Header__c ) {
				manualLineCount++;
			}
		}
		system.assertEquals( manualLineCount, 40 );
		//System.debug(loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries());

		/* Create 3 sets of rules.
			1st set: Contains all types with date range today to day 6. (week 1) - count 60
				Manual:	40
				Auto:	20
			2nd set: contains all types that are charges. Date Range day 7 to day 13. (week 2) - count 30
				Manual:	20
				Auto:	10
			3rd set: contains all types that are discount. Date Range day 14 to day 20. (week 3) - count 30
				Manual:	20
				Auto:	10
		*/
		List<Allowance_Rule__c> arTypes = TestDataForAllowance.createRepriceRules( atTypes, salesOrder.Customer__c );
		system.assertEquals( 60 + 30 + 30, arTypes.size() );
		insert arTypes;

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		// Asserting only SOL for this test seq. Keeping it simple at the cost of an extra testMethod
		aaList = getAppliedRecords( 'Sales_order_Line__c != null', true, null );
		system.assertEquals( 40, aaList.size(), 'Expecting only manual line allowances' );
		for ( Allowance_Applied__c aa : aaList ) {
			system.assert( aa.Allowance_Type__r.Manual__c, aa.Allowance_Type__r );
		}

		System.debug( loggingLevel.Error, '~*~ Query CT: ' + Limits.getQueries() );

		Test.startTest();
		// this will apply the first set of auto allowance rules. No deletions should occur
		solDT = System.now() + 6;
		soLine.Ordered_Date_Time__c = solDT;
		update soLine; // 12 queries, 3 seconds
		System.debug( loggingLevel.Error, '~*~ Limits Query CT: ' + Limits.getQueries() );
		system.debug( LoggingLevel.Error, '~*~ Limits CPU TIME: ' + Limits.getcputime() );

		aaList = getAppliedRecords( 'Sales_order_Line__c != null', true, null );
		//for (Allowance_Applied__c aa : aaList) {
		//	System.debug(loggingLevel.Error, '~*~ aa.Allowance_rule2__r.Name: ' + aa.Allowance_rule2__r.Name);
		//}
		system.assertEquals( 60, aaList.size(), 'expecting size to incease by 20 with automatic line allowances since 20 manuals are overrides which are manual only.' );

		// this will move the order to apply the 2nd set of rules and delete the 1st set
		// Expecting All excluding discount and manuals.
		solDT = System.now() + 7;
		soLine.Ordered_Date_Time__c = solDT;
		update soLine;
		aaList = getAppliedRecords( 'Sales_order_Line__c != null', true, 'Repricing - 2nd set of rules' );
		system.assertEquals( 10, aaList.size(), 'expecting 10 Auto Allowances.' );
		//for (Allowance_Applied__c aa : aaList) {
		//System.debug(loggingLevel.Error, '~*~ aa.Allowance_rule2__r.Name: ' + aa.Allowance_rule2__r.Name);
		//}

		// this will move the order to apply the 2nd set of rules and delete the 1st set
		// Expecting All excluding discount and manuals.
		solDT = System.now() + 14;
		soLine.Ordered_Date_Time__c = solDT;
		update soLine;
		aaList = getAppliedRecords( 'Sales_order_Line__c != null', true, 'Repricing - 3rd set of rules' );
		//for (Allowance_Applied__c aa : aaList) {
		//System.debug(loggingLevel.Error, '~*~ aa.Allowance_rule2__r.Name: ' + aa.Allowance_rule2__r.Name);
		//}

		system.assertEquals( 10, aaList.size(), 'expecting 10 different Auto Allowances.' );
		Sales_Order_line__c sol = aaList[ 0 ].Sales_order_line__r;

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries

		Test.stopTest();

		System.debug( loggingLevel.Error, '~*~ Limits Query CT: ' + Limits.getQueries() );
		system.debug( LoggingLevel.Error, '~*~ Limits CPU TIME: ' + Limits.getcputime() );

		aaList = getAppliedRecords( 'Sales_order_Line__c != null', true, 'Repricing - 3rd set of rules' );
		system.assertEquals( 30, aaList.size(), 'expecting to gain 20 manuals including 10 overrides.' );
	}

	/************************************************************
	*  	SalesOrderAdjustmentExtTest TESTS
	*************************************************************/

	// Test that an adjustment order can be created from a "standard" sales order.
	testMethod static void testSalesOrderAdjustmentExt() {
		AllowanceRuleService.testAllowances = true;
		SchemaUtil util = new SchemaUtil();
		//List<Allowance_Applied__c> aaList;
		List<Allowance_Applied__c> aaList;

		// build one rule for this test
		Allowance_Type__c allowanceType = new Allowance_Type__c( Name = '10 $ Flat off',
				Manual__c = false,
				Type__c = CHARGE,
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Apply_At_Header__c = true,
				Allowance_Class__c = 'Standard',
				Currency__c = fuel.currencyUSD.ID );
		insert allowanceType;

		Allowance_Rule__c ar = new Allowance_Rule__c( Name = '10$ off on header ',
				Allowance_Type__c = allowanceType.Id,
				Start_Date__c = System.today().addDays( -30 ),
				End_Date__c = System.today().addDays( 30 ),
				Customer2__c = fuel.customerParent.id );
		insert ar;

		Test.startTest();

		system.assert( fuel.salesOrder.Id != null );

		//fuel.salesOrder.Type__c = 'Adjustment';
		//update fuel.salesOrder;

		ApexPages.StandardController ctlr = new ApexPages.StandardController( fuel.salesOrder );
		//SalesOrderAdjustmentExt adjExt = new SalesOrderAdjustmentExt(ctlr);

		//fuel.salesOrder.Type__c = 'Standard';
		//update fuel.salesOrder;

		SalesOrderAllowancesExt allowanceExt = new SalesOrderAllowancesExt( ctlr );
		allowanceExt.createAutomaticAllowance();

		fuel.salesOrder = Database.query( util.generateQueryFromFieldSet( 'Sales_Order__c', new Set<String>{
				'Adjustment_Order'
		}, new Set<String>{ 'Bracket_Price_Field_In_Use__c', '(Select Id from Allowances_Applied__r)' }, ' Id = \'' + fuel.salesOrder.Id + '\' LIMIT 1' ) );

		system.assertNotEquals( 'Price_2__c', fuel.salesOrder.Bracket_Price_Field_In_Use__c );
		system.assertNotEquals( system.today() - 30, fuel.salesOrder.Pricing_Date__c );
		system.assertNotEquals( 0, fuel.salesOrder.Allowances_Applied__r.size() );

		ctlr = new ApexPages.StandardController( fuel.salesOrder );
		SalesOrderAdjustmentExt adjExt = new SalesOrderAdjustmentExt( ctlr );

		system.assertEquals( 7, adjExt.getAdjustmentTypes().size() );
		adjExt.adjustmentSO.Type__c = 'Adjustment';

		system.assertNotEquals( null, adjExt.adjustmentSO );
		system.assertEquals( null, adjExt.adjustmentSO.Id );
		system.assertEquals( 'Manual', adjExt.adjustmentSO.Price_Determination_Date__c );
		system.assertEquals( fuel.salesOrder.Id, adjExt.adjustmentSO.Related_Sales_Order__c );
		system.assert( fuel.salesOrder.Type__c != adjExt.adjustmentSO.Type__c, fuel.salesOrder.Type__c + ' ' + adjExt.adjustmentSO.Type__c );

		Sales_Order__c adjustmentSO = ( Sales_Order__c ) adjExt.controller.getRecord();
		adjustmentSO.Bracket_Price_Field_In_Use__c = 'Price_2__c';
		adjustmentSO.Pricing_Date__c = system.today() - 30;
		adjExt.save();

		system.assert( ApexPages.getMessages().size() == 0, ApexPages.getMessages() );
		system.assert( [select id from Sales_Order__c].size() == 2 );
		system.assert( adjExt.adjustmentSO.id != null, adjExt.adjustmentSO.id );

		system.assert( adjExt.disableSave != true, ApexPages.getMessages() );
		system.assert( adjExt.adjustmentSO.Id != null, 'Expected the adjustment sales order to get saved.' );

		ApexPages.StandardController ctlr2 = new ApexPages.StandardController( adjExt.adjustmentSO );
		SalesOrderAllowancesExt allowanceExt2 = new SalesOrderAllowancesExt( ctlr2 );

		aaList = [select Id from Allowance_Applied__c where Sales_Order__c = :adjustmentSO.Id];
		system.assertEquals( 1, aaList.size() );

		delete aaList;

		allowanceExt2.createAutomaticAllowance();

		aaList = [select Id from Allowance_Applied__c where Sales_Order__c = :adjustmentSO.Id];
		system.assertEquals( 0, aaList.size() );

		allowanceExt2.reset();
		//TODO
		//appliedAllowances = [select Id from Allowance_Applied__c where Sales_Order__c = :adjustmentSO.Id];
		//system.assertEquals(1, appliedAllowances.size());

	}

	/************************************************************
	*  	AllowanceInvoiceGroupingRulesTests TESTS
	*************************************************************/

	static testMethod void AllowanceInvoiceGroupingRulesTest_manualDateMethodTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		List<Sales_Order_Line__c> solList = salesOrder.Sales_Order_Lines__r;
		Allowance_Applied__c[] aaList;

		Date soManualPricingDate = system.today() + 5;
		salesOrder.Price_determination_date__c = 'Manual';
		salesOrder.Pricing_date__c = soManualPricingDate;
		update salesOrder;

		salesOrder = [
				Select Id, Date_Time_Ordered__c, Customer__c, Ship_To__c, Price_determination_date__c, Pricing_Date__c
				from Sales_order__c
				where Id = :salesOrder.id
		];
		system.assertEquals( system.today() + 5, salesOrder.Pricing_Date__c );

		Test.startTest();
		List<Allowance_Type__c> atList = new List<Allowance_Type__c>();

		Allowance_Type__c autoFlat = new Allowance_Type__c(
				Name = 'Flat Amt',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Manual__c = true,
				Amount__c = 12,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlat );

		Allowance_Type__c autoFlat2 = new Allowance_Type__c(
				Name = 'Flat Amt',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				//Apply_At_Header__c = true,
				Manual__c = true,
				Amount__c = 12,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlat2 );

		Allowance_Type__c man = new Allowance_Type__c(
				Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Amount__c = 10.00,
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( man );

		Allowance_Type__c man2 = new Allowance_Type__c(
				Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Amount__c = 10.00,
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( man2 );

		insert atList;

		// 	2 auto, 2 man
		List<Allowance_Rule__c> allTheRules = new List<Allowance_Rule__c>();

		Allowance_Rule__c head1 = new Allowance_Rule__c(
				Name = 'Header1: ' + autoFlat.Name,
				Allowance_Type__c = autoFlat.Id,
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = System.today(),
				End_Date__c = System.today() );
		allTheRules.add( head1 );

		Allowance_Rule__c head2 = new Allowance_Rule__c(
				Name = 'LINE: ' + autoFlat2.Name,
				Allowance_Type__c = autoFlat2.Id,
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = system.today() + 5,
				End_Date__c = system.today() + 5 );
		allTheRules.add( head2 );

		// invalid date range
		Allowance_Rule__c ruleHead = new Allowance_Rule__c(
				Name = 'manual test hdr',
				Allowance_Type__c = man.Id,
				End_Date__c = System.today().addDays( -1 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		allTheRules.add( ruleHead ); // actually expired rule...

		// valid date range
		Allowance_Rule__c ruleHead2 = new Allowance_Rule__c(
				Name = 'manual test hdr',
				Allowance_Type__c = man2.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		allTheRules.add( ruleHead2 );

		// SO Manual pricing date is set for today + 5. Expecting 2 rules to apply. 1 header, 2 lines. 3 total

		insert allTheRules;

		system.assertEquals( fuel.customerShipTo.id, salesOrder.Ship_To__c, 'Sales order customer does not match' );

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries

		new SalesOrderService().plan( salesOrder.id );
		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		aaList = getAppliedRecords( null, true, 'SO Release with manuals applied' );
		//aaList =  [select id, Sales_Order__c, Sales_Order_Line__c, Allowance_Type__r.Manual__c, Source__c from Allowance_Applied__c];

		system.assertEquals( 3, aaList.size(), 'Expecting automatic allowance added on salesOrder release' + aaList );
		//system.assert(null != aaList[0].Sales_Order__c);
		//system.assert(null == aaList[0].Sales_Order_Line__c); // invalid, added line allowance

		// all should be manual
		for ( Allowance_Applied__c aa : aaList ) {
			System.debug( loggingLevel.Error, '~*~ SOR aa: ' + aa.Allowance_rule2__r + '\n' + aa.Allowance_Type__r );
			system.assert( true == aa.Allowance_Type__r.Manual__c, aa.Allowance_rule2__r + '\n' + aa.Allowance_Type__r );
		}

		system.assertNotEquals( null, salesOrder.Id );

		system.assertEquals( 2, solList.size() );

		Fulfillment__c f = new Fulfillment__c( Customer__c = fuel.customerBillTo.Id,
				Currency__c = fuel.currencyUSD.id,
				Payment_Term__c = fuel.terms.ID,
				Sales_Order_Line__c = solList[ 0 ].Id,
				Occurrence__c = 'Immediate',
				Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
				Name = 'F1',
				Invoice_Ready__c = true,
				Unit_Price__c = 100, Quantity__c = 1,
				Fulfillment_Date__c = system.now(),
				Product__c = solList[ 0 ].Product__c, Price_Type__c = 'Sales',
				Status__c = 'Complete' );

		insert f;

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		Test.stopTest();

		// invoice grouping rules CI

		datetime myDateTime = system.now();
		List<Shipment__c> shipmentList = [
				Select id, Name, Company__c, Customer__c
				from Shipment__c
				where Date_Shipped__c <= :myDateTime
				and Status__c = 'Confirmed'
		];

		List <Customer_Invoice__c> custInvList = [
				Select id, Name, Sales_Order__c, Bill_To_Customer__c, Company__c, Allowances__c, Subtotal__c, Payment_Term__c, Finalized__c, Total_Amount__c, (
						Select id, Name, Line_Type__c, Customer_Invoice__c, Off_Invoice_Rate__c, BillBack_Rate__c, List_Price__c
						from Customer_Invoice_Lines__r
				)
				from Customer_Invoice__c
		];

		system.assertequals( 1, custInvList.size(), ' expected custInvList list > 0 ' ); // SIZE = 3
		//system.assertequals( 10, custInvList[0].Allowances__c , ' expected custInvList list > 0 ');
		//system.assertEquals(119.76,custInvList[0].Total_Amount__c);
		system.assertequals( 1, custInvList[ 0 ].Customer_Invoice_Lines__r.size() );

	}

	static testMethod void AllowanceInvoiceGroupingRulesTest_manualDates_Discounts() {
		AllowanceRuleService.testAllowances = true;Sales_Order__c salesOrder = fuel.salesOrder;
		List<Sales_Order_Line__c> solList = salesOrder.Sales_Order_Lines__r;
		Allowance_Applied__c[] aaList;

		Date soManualPricingDate = system.today() + 5;
		salesOrder.Price_determination_date__c = 'Manual';
		salesOrder.Pricing_date__c = soManualPricingDate;
		update salesOrder;

		salesOrder = [
				Select Id, Date_Time_Ordered__c, Customer__c, Ship_To__c, Price_determination_date__c, Pricing_Date__c
				from Sales_order__c
				where Id = :salesOrder.id
		];
		system.assertEquals( system.today() + 5, salesOrder.Pricing_Date__c );

		Test.startTest();
		List<Allowance_Type__c> atList = new List<Allowance_Type__c>();

		Allowance_Type__c autoFlat = new Allowance_Type__c(
				Name = 'Flat Amt',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Discount',
				Apply_At_Header__c = true,
				Manual__c = true,
				Amount__c = 12,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlat );

		Allowance_Type__c autoFlat2 = new Allowance_Type__c(
				Name = 'Flat Amt',
				Basis__c = BASIS_FLAT_AMOUNT,
				//Apply_At_Header__c = true,
				Type__c = 'Discount',
				Manual__c = true,
				Amount__c = 12,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlat2 );

		Allowance_Type__c man = new Allowance_Type__c(
				Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Discount',
				Apply_At_Header__c = true,
				Amount__c = 10.00,
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( man );

		Allowance_Type__c man2 = new Allowance_Type__c(
				Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Discount',
				Apply_At_Header__c = true,
				Amount__c = 10.00,
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( man2 );

		insert atList;

		// 	2 auto, 2 man
		List<Allowance_Rule__c> allTheRules = new List<Allowance_Rule__c>();

		Allowance_Rule__c head1 = new Allowance_Rule__c(
				Name = 'Header1: ' + autoFlat.Name,
				Allowance_Type__c = autoFlat.Id,
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = System.today(),
				End_Date__c = System.today() );
		allTheRules.add( head1 );

		Allowance_Rule__c head2 = new Allowance_Rule__c(
				Name = 'LINE: ' + autoFlat2.Name,
				Allowance_Type__c = autoFlat2.Id,
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = system.today() + 5,
				End_Date__c = system.today() + 5 );
		allTheRules.add( head2 );

		// invalid date range
		Allowance_Rule__c ruleHead = new Allowance_Rule__c(
				Name = 'manual test hdr',
				Allowance_Type__c = man.Id,
				End_Date__c = System.today().addDays( -1 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		allTheRules.add( ruleHead ); // actually expired rule...

		// valid date range
		Allowance_Rule__c ruleHead2 = new Allowance_Rule__c(
				Name = 'manual test hdr',
				Allowance_Type__c = man2.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		allTheRules.add( ruleHead2 );

		// SO Manual pricing date is set for today + 5. Expecting 2 rules to apply. 1 header, 2 lines. 3 total

		insert allTheRules;

		system.assertEquals( fuel.customerShipTo.id, salesOrder.Ship_To__c, 'Sales order customer does not match' );

		TestDataForAllowance.applyManualAllowances( salesOrder.id ); // 12 queries

		new SalesOrderService().plan( salesOrder.id );
		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		aaList = getAppliedRecords( null, true, 'SO Release with manuals applied' );
		//aaList =  [select id, Sales_Order__c, Sales_Order_Line__c, Allowance_Type__r.Manual__c, Source__c from Allowance_Applied__c];

		system.assertEquals( 3, aaList.size(), 'Expecting automatic allowance added on salesOrder release' + aaList );
		//system.assert(null != aaList[0].Sales_Order__c);
		//system.assert(null == aaList[0].Sales_Order_Line__c); // invalid, added line allowance

		// all should be manual
		for ( Allowance_Applied__c aa : aaList ) {
			System.debug( loggingLevel.Error, '~*~ SOR aa: ' + aa.Allowance_rule2__r + '\n' + aa.Allowance_Type__r );
			system.assert( true == aa.Allowance_Type__r.Manual__c, aa.Allowance_rule2__r + '\n' + aa.Allowance_Type__r );
		}

		system.assertNotEquals( null, salesOrder.Id );

		system.assertEquals( 2, solList.size() );

		Fulfillment__c f = new Fulfillment__c( Customer__c = fuel.customerBillTo.Id,
				Currency__c = fuel.currencyUSD.id,
				Payment_Term__c = fuel.terms.ID,
				Sales_Order_Line__c = solList[ 0 ].Id,
				Occurrence__c = 'Immediate',
				Start_Date__c = DateTime.newInstance( 2015, 5, 30, 0, 0, 0 ),
				Name = 'F1',
				Invoice_Ready__c = true,
				Unit_Price__c = 100, Quantity__c = 1,
				Fulfillment_Date__c = system.now(),
				Product__c = solList[ 0 ].Product__c, Price_Type__c = 'Sales', Status__c = 'Complete' );

		insert f;

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		Test.stopTest();

		// invoice grouping rules CI

		datetime myDateTime = system.now();
		List<Shipment__c> shipmentList = [
				Select id, Name, Company__c, Customer__c
				from Shipment__c
				where Date_Shipped__c <= :myDateTime
				and Status__c = 'Confirmed'
		];

		List <Customer_Invoice__c> custInvList = [
				Select id, Name, Sales_Order__c, Bill_To_Customer__c, Company__c, Allowances__c, Subtotal__c, Payment_Term__c, Finalized__c, Total_Amount__c, (
						Select id, Name, Line_Type__c, Customer_Invoice__c, Off_Invoice_Rate__c, BillBack_Rate__c, List_Price__c
						from Customer_Invoice_Lines__r
				)
				from Customer_Invoice__c
		];

		system.assertequals( 1, custInvList.size(), ' expected custInvList list > 0 ' ); // SIZE = 3
		//system.assertequals( -10, custInvList[0].Allowances__c , ' expected custInvList list > 0 ');
		// 		system.assertEquals(76.24,custInvList[0].Total_Amount__c);

	}

	static testMethod void AllowanceInvoiceGroupingRulesTest_orderDateMethodTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Allowance_Applied__c[] aaList;

		salesOrder.Price_determination_date__c = 'Order Date';
		update salesOrder;

		salesOrder = [Select Id, Date_Time_Ordered__c, Pricing_Date__c from Sales_order__c where Id = :salesOrder.id];
		system.assertEquals( salesOrder.Date_Time_Ordered__c.date(), salesOrder.Pricing_Date__c );
		system.debug( LoggingLevel.info, 'Pricing date pre-release: ' + salesOrder.Pricing_Date__c );

		Test.startTest();
		List<Allowance_Type__c> atList = new List<Allowance_Type__c>();
		List<Allowance_Rule__c> allTheRules = new List<Allowance_Rule__c>();

		Allowance_Type__c autoFlat = new Allowance_Type__c(
				Name = 'Flat Amt',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Amount__c = 12,
				Apply_At_Header__c = true,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlat );

		insert atList;

		Allowance_Rule__c head1 = new Allowance_Rule__c(
				Name = 'Header1: ' + autoFlat.Name,
				Allowance_Type__c = autoFlat.Id,
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = System.today() + 1,
				End_Date__c = null );
		allTheRules.add( head1 );

		Allowance_Rule__c head2 = new Allowance_Rule__c(
				Name = 'Header2: ' + autoFlat.Name,
				Allowance_Type__c = autoFlat.Id,
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = salesOrder.Pricing_Date__c,
				End_Date__c = salesOrder.Pricing_Date__c );
		allTheRules.add( head2 );

		insert allTheRules;

		system.debug( LoggingLevel.info, 'Rules: ' + allTheRules );

		new SalesOrderService().plan( salesOrder.id );

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller( salesOrder );
		SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
		socsExt.confirmShip();

		aaList = getAppliedRecords( null, null, null ); //[select id from Allowance_Applied__c];

		system.assertEquals( 1, aaList.size(), ' Epxected  nonfreight allowance' );

		Shipment_Line__c[] shls = [
				Select Id, Quantity_Shipped__c, Quantity_Planned__c, Sales_order__r.Status__c, Sales_order_Line__c, Sales_order__r.Date_Time_Ordered__c, Sales_order__r.Pricing_Date__c, Shipment__r.Status__c, Shipment__r.Date_Shipped__c
				from Shipment_Line__c
				where Sales_Order__c = :salesOrder.id
		];

		system.assertEquals( 'Confirmed', shls[ 0 ].shipment__r.Status__c );

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );
		test.stopTest();

		// verify that a customer invoice batch was created

		Customer_Invoice__c[] ciList = [select Finalized__c, Allowances__c, Id, Sales_order__c, (select id, allowance_amount__c from Allowances_Applied1__r) from Customer_Invoice__c];
		System.assertEquals( ciList.size(), 1, 'Customer Inovice Batch failed to create' );

		Decimal headerAllowance = 0;
		for ( customer_invoice__c ci : ciList ) {
			for ( Allowance_Applied__c aa : ci.Allowances_Applied1__r ) {
				system.debug( LoggingLevel.info, 'aaList: ' + aa );
				headerAllowance += aa.Allowance_Amount__c;
			}
		}
	}

	// TO DO: Merge test with noCustomerComboAllowanceRuleInvoice
	//  Test method to check CI batch picks up the appropriate Rules per customer on each SO
	static testMethod void AllowanceInvoiceGroupingRulesTest_allowanceRuleCustomerInvoiceBatchTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		// create separate shipTo customer for 2nd salesOrder to be assigned to 2nd set of Allowance rules
		Customer__c customerShipTo = new Customer__c();
		customerShipTo.name = 'Customer Ship To 2';
		customerShipTo.recordTypeId = fuel.CustomerRecordTypes.get( 'Ship_To' );
		customerShipTo.Company__c = fuel.customerShipTo.Company__c;
		customerShipTo.Address__c = fuel.customerShipTo.Address__c;
		customerShipTo.Credit_Limit__c = 100000.0;
		customerShipTo.Parent_Customer__c = fuel.customerSoldTo.id;
		customerShipTo.Customer_Identifier__c = fuel.customerShipTo.Customer_Identifier__c + '-2';
		insert customerShipTo;

		system.assertNotEquals( customerShipTo, fuel.customerShipTo );

		List<Sales_order__c> soList = new List<Sales_order__c>();
		Sales_Order__c so1 = new Sales_order__c();
		so1.Company__c = fuel.salesOrder.Company__c; // 	company.id;
		so1.Customer__c = fuel.salesOrder.Customer__c; // 	customerSoldTo.id;    // must be a sold to
		so1.Bill_To__c = fuel.salesOrder.Bill_To__c; // 	customerBillTo.id;
		so1.Ship_To__c = fuel.salesOrder.Ship_To__c; // 	customerShipTo.Id;
		so1.Payment_Term__c = fuel.salesOrder.Payment_Term__c; // 	terms.id;
		so1.Required_Date__c = system.today().adddays( 2 );
		so1.Delivery_Method__c = 'Pickup';
		soList.add( so1 );

		Sales_Order__c so2 = new Sales_order__c();
		so2.Company__c = fuel.salesOrder.Company__c; // 	company.id;
		so2.Customer__c = fuel.salesOrder.Customer__c; // 	customerSoldTo.id;    // must be a sold to
		so2.Bill_To__c = fuel.salesOrder.Bill_To__c; // 	customerBillTo.id;
		so2.Ship_To__c = fuel.salesOrder.Ship_To__c; // 	customerShipTo.Id;
		so2.Payment_Term__c = fuel.salesOrder.Payment_Term__c; // 	terms.id;
		so2.Required_Date__c = system.today().adddays( 2 );
		so2.Delivery_Method__c = 'Pickup';
		soList.add( so2 );

		insert soList;

		Test.startTest();
		List<Sales_Order_Line__c> SalesOrderLines = new List <Sales_Order_Line__c>();

		Sales_Order_Line__c soLine1 = salesOrder.Sales_Order_Lines__r[ 0 ];
		Sales_Order_Line__c soLine2 = salesOrder.Sales_Order_Lines__r[ 1 ];

		// SOL for So1
		Sales_Order_Line__c SalesOrderLine1 = new Sales_Order_Line__c();
		SalesOrderLine1.Sales_Order__c = so1.Id;
		SalesOrderLine1.Product__c = soLine1.Product__c; // 	product.Id;
		SalesOrderLine1.Description__c = soLine1.Description__c; // 	product.Description__c;
		SalesOrderLine1.Discount_Percent__c = 2;
		SalesOrderLine1.Company__c = soLine1.Company__c; // 	company.id;
		SalesOrderLine1.Quantity_Ordered__c = 100;
		SalesOrderLine1.Required_Date__c = System.today() + 15;
		SalesOrderLine1.Ship_From_Location__c = soLine1.Ship_From_Location__c; // 	location2.ID;
		SalesOrderLines.add( SalesOrderLine1 );

		// SOL for So2
		Sales_Order_Line__c SalesOrderLine2 = new Sales_Order_Line__c();
		SalesOrderLine2.Sales_Order__c = so2.Id;
		SalesOrderLine2.Product__c = soLine2.Product__c; //product.Id;
		SalesOrderLine2.Description__c = soLine2.Description__c; //product2.Description__c;
		SalesOrderLine2.Discount_Percent__c = 2;
		SalesOrderLine2.Company__c = soLine2.Company__c; //company.id;
		SalesOrderLine2.Quantity_Ordered__c = 14;
		SalesOrderLine2.Required_Date__c = System.today() + 15;
		SalesOrderLine2.Ship_From_Location__c = soLine2.Ship_From_Location__c; //location2.ID;
		SalesOrderLines.add( SalesOrderLine2 );

		insert SalesOrderLines;

		List<Allowance_Type__c> atList = new List <Allowance_Type__c>();

		Allowance_Type__c autoFlatHeader = new Allowance_Type__c(
				Name = '$1 off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Amount__c = 1,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlatHeader );

		Allowance_Type__c autoFlatLines = new Allowance_Type__c(
				Name = '$1 off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Amount__c = 1,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlatLines );

		Allowance_Type__c autoFlatFreight = new Allowance_Type__c(
				Name = '$1 off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Amount__c = 1,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoFlatFreight );

		insert atList;

		List<Allowance_Rule__c> allTheRules = new List<Allowance_Rule__c>();

		// * * Rules for so1 * *

		// header rule for so1
		Allowance_Rule__c rule1 = new Allowance_Rule__c(
				Name = 'Auto test hdr - cust 1',
				Allowance_Type__c = autoFlatHeader.Id,
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule1 );

		// invoice line rule for so1
		Allowance_Rule__c rule1b = new Allowance_Rule__c(
				Name = 'Auto test line - cust 1 (inovice)',
				Allowance_Type__c = autoFlatLines.Id,
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule1b );

		// freight rule for so1
		Allowance_Rule__c rule1c = new Allowance_Rule__c(
				Name = 'Auto test line - cust 1 (freight)',
				Allowance_Type__c = autoFlatFreight.Id,
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerShipTo.id,
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule1c );

		// * * Rules for so2 * * *

		// invoice header rule
		Allowance_Rule__c rule2 = new Allowance_Rule__c(
				Name = 'Auto test hdr - cust 2',
				Allowance_Type__c = autoFlatHeader.Id,
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = customerShipTo.id,
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule2 );

		// invoice rule
		Allowance_Rule__c rule2b = new Allowance_Rule__c(
				Name = 'Auto test line - cust 2 (inovice)',
				Allowance_Type__c = autoFlatLines.Id,
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = customerShipTo.id,
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule2b );

		// Freight rule
		Allowance_Rule__c rule2c = new Allowance_Rule__c(
				Name = 'Auto test line - cust 2 (freight)',
				Allowance_Type__c = autoFlatFreight.Id,
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = customerShipTo.id,
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule2c );

		// GENERIC rules
		Allowance_Rule__c rule3 = new Allowance_Rule__c(
				Name = 'GENERIC freight rule',
				Allowance_Type__c = autoFlatFreight.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule3 );

		Allowance_Rule__c rule4 = new Allowance_Rule__c(
				Name = 'Auto test hdr - GENERIC',
				Allowance_Type__c = autoFlatheader.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule4 );

		// freight rule for so1 & so2
		Allowance_Rule__c rule1d = new Allowance_Rule__c(
				Name = 'Auto test line - cust 1 / 2 (freight) - bill To',
				Allowance_Type__c = autoFlatFreight.Id,
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerBillTo.id,
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule1d );

		insert allTheRules;

		system.debug( LoggingLevel.INFO, 'Queries plan()' + Limits.getQueries() ); // at 98 queries

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		for ( Sales_Order__c so : soList ) {
			ApexPages.Standardcontroller con = new ApexPages.Standardcontroller( salesOrder );
			SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
			socsExt.confirmShip();
		}

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		system.debug( LoggingLevel.INFO, 'Queries plan()' + Limits.getQueries() );

		Test.stopTest();

		//Test.stopTest();

		Allowance_Applied__c[] soAAList = new Allowance_Applied__c[]{
		};
		Allowance_Applied__c[] solAAList = new Allowance_Applied__c[]{
		};
		Allowance_Applied__c[] ciAAList = new Allowance_Applied__c[]{
		};
		Allowance_Applied__c[] cilAAList = new Allowance_Applied__c[]{
		};

		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );
		for ( Allowance_Applied__c aa : aaList ) {
			//[select id, Allowance_Type__r.Name, Customer_Invoice2__c, Customer_Invoice_Line__c, Sales_Order__c, Sales_Order_Line__c from Allowance_Applied__c]) {

			if ( aa.Customer_invoice2__c != null ) {
				ciAAList.add( aa );
			}
			if ( aa.customer_invoice_Line__c != null ) {
				cilAAList.add( aa );
			}
			if ( aa.Sales_Order__c != null ) {
				soAAList.add( aa );
			}
			if ( aa.Sales_Order_Line__c != null ) {
				solAAList.add( aa );
			}
		}

		system.assertequals( soAAList.size(), ciAAList.size() );
		system.assertequals( solAAList.size(), cilAAList.size() );
	}

	/* TO DO: Introduce 2 more SOs:
		1 - Same Top Customer Parent and in the same customer group: expect the CG ARs and the Null AR to be applied
		2 - completely customer hierarchy: Expected only the null AR applied
		3 - Check CI Allowances are applied correctly. Expecting 3 CIs.
	*/
	// 	Test Rules combinations: All customers, Product, PG, Product hierarchy, all Null, Customer Group
	static testMethod void AllowanceInvoiceGroupingRulesTest_noCustomerComboAllowanceRuleInvoice() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		List<Allowance_Type__c> atList = new List<Allowance_Type__c>();

		// creates 12 allowances types
		for ( Integer i = 0; i <= 17; i++ ) {
			Allowance_Type__c autoFlat = new Allowance_Type__c(
					Name = '$' + i + ' - Flat Charge',
					Basis__c = BASIS_FLAT_AMOUNT,
					Type__c = 'Charge',
					Amount__c = i + 1,
					Currency__c = fuel.currencyUSD.ID );
			atList.add( autoFlat );
		}
		insert atList;

		List<Allowance_Rule__c> allTheRules = new List<Allowance_Rule__c>();

		//	create 12 Allowance Rules with different combinations 9 Uniques, 9 doubles. Expected AA: 27

		Decimal expectedAllowanceApplied = 27;

		//	Create Double applied Allowance RulesL 7

		// all blanks - 2 aa
		Allowance_Rule__c rule9 = new Allowance_Rule__c(
				Name = 'Auto test ln - All Null',
				Allowance_Type__c = atList[ 5 ].Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ) );
		allTheRules.add( rule9 );

		// Customer Group (different customer association) - expect 2 AA created
		Allowance_Rule__c rule8 = new Allowance_Rule__c(
				Name = 'Auto test ln - CG 0',
				Allowance_Type__c = atList[ 14 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				Customer_Group__c = fuel.customerGroupList[ 3 ].Id
		);
		allTheRules.add( rule8 );

		// Customer Group (different customer association) - expect 2 AA created
		Allowance_Rule__c rule7 = new Allowance_Rule__c(
				Name = 'Auto test ln - CG 0',
				Allowance_Type__c = atList[ 13 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				Customer_Group__c = fuel.customerGroupList[ 2 ].Id
		);
		allTheRules.add( rule7 );

		// Customer Group (different customer association) - expect 2 AA created
		Allowance_Rule__c rule6 = new Allowance_Rule__c(
				Name = 'Auto test ln - CG 0',
				Allowance_Type__c = atList[ 11 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id
		);
		allTheRules.add( rule6 );

		// Customer Group (different customer association) - expect 2 AA created
		Allowance_Rule__c rule5 = new Allowance_Rule__c(
				Name = 'Auto test ln - CG 1',
				Allowance_Type__c = atList[ 12 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				Customer_Group__c = fuel.customerGroupList[ 0 ].Id
		);
		allTheRules.add( rule5 );

		// customer Top parent customer - expect 2 AA created
		Allowance_Rule__c rule4 = new Allowance_Rule__c(
				Name = 'Auto test ln - Top Parent',
				Allowance_Type__c = atList[ 10 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerParent.id
		);
		allTheRules.add( rule4 );

		// customer bill-to - expect 2 AA created
		Allowance_Rule__c rule3 = new Allowance_Rule__c(
				Name = 'Auto test ln - billto',
				Allowance_Type__c = atList[ 9 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerBillTo.id
		);
		allTheRules.add( rule3 );

		// customer sold-to - 2 aa
		Allowance_Rule__c rule2 = new Allowance_Rule__c(
				Name = 'Auto test ln - soldTo',
				Allowance_Type__c = atList[ 0 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerSoldTo.id
		);
		allTheRules.add( rule2 );

		// customer ship-to - 2 aa
		Allowance_Rule__c rule1 = new Allowance_Rule__c(
				Name = 'Auto test ln -w/ shipTo',
				Allowance_Type__c = atList[ 1 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerShipTo.id
		);
		allTheRules.add( rule1 );

		//	Create Single applied Allowance Rules (ct: 9)

		// Only PG - 1 aa
		Allowance_Rule__c ruleS9 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ PG & CG',
				Allowance_Type__c = atList[ 17 ].Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				Product_group__c = fuel.productgroup.id,
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id
		);
		allTheRules.add( ruleS9 );

		// CG & hierarchy - 1 aa
		Allowance_Rule__c ruleS8 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ hierarchy + CG',
				Allowance_Type__c = atList[ 16 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Product_Hierarchy__c = fuel.l2Hierarchy1.id
		);
		allTheRules.add( ruleS8 );

		// customer sold-to & hierarchy - 1 aa
		Allowance_Rule__c ruleS7 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ PG + CG',
				Allowance_Type__c = atList[ 15 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				Customer_Group__c = fuel.customerGroupList[ 1 ].Id,
				Product_group__c = fuel.productgroup.id
		);
		allTheRules.add( ruleS7 );

		// customer sold-to & hierarchy - 1 aa
		Allowance_Rule__c ruleS6 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ hierarchy + soldTo cust',
				Allowance_Type__c = atList[ 2 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerSoldTo.id,
				Product_Hierarchy__c = fuel.l2Hierarchy1.id
		);
		allTheRules.add( ruleS6 );

		// customer sold-to & product - 1 aa
		Allowance_Rule__c ruleS5 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ Product + soldTo cust',
				Allowance_Type__c = atList[ 3 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerSoldTo.id,
				Product__c = fuel.product.id
		);
		allTheRules.add( ruleS5 );

		// customer sold-to & PG - 1 aa
		Allowance_Rule__c ruleS4 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ PG + soldTo cust',
				Allowance_Type__c = atList[ 4 ].Id,
				Start_Date__c = System.today().addDays( -10 ),
				End_Date__c = System.today().addDays( 10 ),
				customer2__c = fuel.customerSoldTo.id,
				Product_group__c = fuel.productgroup.id
		);
		allTheRules.add( ruleS4 );

		// Only Product - 1 aa
		Allowance_Rule__c ruleS3 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ Only Product',
				Allowance_Type__c = atList[ 6 ].Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				Product__c = fuel.product.id );
		allTheRules.add( ruleS3 );

		// Only PG - 1 aa
		Allowance_Rule__c ruleS2 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ only PG',
				Allowance_Type__c = atList[ 7 ].Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				Product_group__c = fuel.productgroup.id );
		allTheRules.add( ruleS2 );

		// Only Hierarchy - 1 aa
		Allowance_Rule__c ruleS1 = new Allowance_Rule__c(
				Name = 'Auto test ln - w/ only Product hierarchy',
				Allowance_Type__c = atList[ 8 ].Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				//customer2__c = fuel.customerSoldTo.id,
				Product_Hierarchy__c = fuel.l2Hierarchy1.id );
		allTheRules.add( ruleS1 );

		insert allTheRules;

		Set<String> allowanceRuleNames = new Set<String>();
		for ( Allowance_Rule__c ars : allTheRules ) {
			allowanceRuleNames.add( ars.Name );
		}

		Test.startTest();

		system.debug( LoggingLevel.info, 'hierarchy id: ' + fuel.l2Hierarchy1 );
		system.debug( LoggingLevel.info, 'Product group: ' + fuel.productgroup );

		new SalesOrderService().plan( salesOrder.id ); // actual plan

		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		Sales_Order_Line__c[] sols = [select id, product__c, Product__r.Product_group__c, Product__r.Sales_Hierarchy__c, Product__r.Sales_Hierarchy__r.Code__c, Product__r.Sales_Hierarchy__r.Path__c, sales_order__r.Customer__c from sales_order_line__c];

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller( salesOrder );
		SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
		socsExt.confirmShip();

		List<Allowance_Applied__c> aaList = getAppliedRecords( 'sales_order__c != null or sales_order_Line__c != null', null, null );
		//[select id , sales_order__c, Sales_Order_Line__c, Allowance_Type__r.Amount__c,
		//                                  Allowance_Type__r.Name, Allowance_Amount__c, Allowance_rule2__r.Name,
		//                                  Allowance_Type__c from Allowance_Applied__c
		//                                  where sales_order__c != null or sales_order_Line__c != null];

		system.debug( LoggingLevel.info, 'Allowances App: ' + aaList );
		List<String> collection = new List<String>();
		for ( Allowance_Applied__c aa : aaList ) {
			String allowanceOn = aa.sales_order__c != null ? '- H' : '- Ln';
			//system.debug(LoggingLevel.Error, aa.Allowance_Type__r.Amount__c + '-' + aa.Allowance_rule2__r.Name + ' - ' + allowanceOn);
			collection.add( aa.Allowance_Type__r.Amount__c + '-' + aa.Allowance_rule2__r.Name + ' - ' + allowanceOn );
		}

		Set<String> allowanceAppliedRules = new Set<String>();
		for ( Allowance_Applied__c aa : aaList ) {
			//system.debug(LoggingLevel.info, aa.Allowance_Type__r.Name);
			allowanceAppliedRules.add( aa.Allowance_Rule2__r.Name );
		}

		for ( String arName : allowanceRuleNames ) {
			system.assert( allowanceAppliedRules.contains( arName ), 'Missing rule: ' + arName );
		}

		system.assertequals( expectedAllowanceApplied, aaList.size(), 'incorrect number of allowance applied lines created ' );

		Shipment_Line__c[] shls = [
				Select Id, Quantity_Shipped__c, Quantity_Planned__c, Sales_order__r.Status__c, Sales_order_Line__c, Sales_order__r.Date_Time_Ordered__c, Sales_order__r.Pricing_Date__c, Shipment__r.Status__c, Shipment__r.Date_Shipped__c
				from Shipment_Line__c
				where Sales_Order__c = :salesOrder.id
		];

		system.assertEquals( 'Confirmed', shls[ 0 ].shipment__r.Status__c );

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		Test.stopTest();

		aaList = getAppliedRecords( 'customer_invoice_line__c != null or customer_invoice2__c != null', null, null );

		system.assertequals( expectedAllowanceApplied, aaList.size(), 'incorrect number of allowance applied lines created ' );
	}

	// TO DO: Test All basis together? Assert qty Allowance Amt on CI. Test for partial - separate test or use 2nd SO?
	// 	Rate By Quantity Tests
	static testMethod void AllowanceInvoiceGroupingRulesTest_rateByQuantityInvoiceTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		List<Allowance_Type__c> atList = new List<Allowance_Type__c>();

		Allowance_Type__c autoOrdQtyRtHeader = new Allowance_Type__c(
				Name = '$.5 off per qty',
				Basis__c = BASIS_RATE_BY,
				Type__c = 'Charge',
				Rate_Field__c = 'Quantity',
				Amount__c = .5,
				Ordered_Quantity__c = true,
				Apply_At_Header__c = true,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoOrdQtyRtHeader );

		Allowance_Type__c autoOrdQtyRt = new Allowance_Type__c(
				Name = '$.5 off per qty',
				Basis__c = BASIS_RATE_BY,
				Type__c = 'Charge',
				Rate_Field__c = 'Quantity',
				Amount__c = .5,
				Ordered_Quantity__c = true,
				Apply_At_Header__c = false,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoOrdQtyRt );

		Allowance_Type__c autoShpQtyRt = new Allowance_Type__c(
				Name = '$.5 off per qty',
				Basis__c = BASIS_RATE_BY,
				Type__c = 'Charge',
				Rate_Field__c = 'Quantity',
				Amount__c = .5,
				Ordered_Quantity__c = false,
				Apply_At_Header__c = false,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoShpQtyRt );

		Allowance_Type__c autoShpQtyRtHeader = new Allowance_Type__c(
				Name = '$.5 off per qty',
				Basis__c = BASIS_RATE_BY,
				Type__c = 'Charge',
				Rate_Field__c = 'Quantity',
				Amount__c = .5,
				Ordered_Quantity__c = false,
				Apply_At_Header__c = true,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		atList.add( autoShpQtyRtHeader );

		insert atList;

		List<Allowance_Rule__c> arList = new List<Allowance_Rule__c>();

		Allowance_Rule__c aLineRuleOrdered = new Allowance_Rule__c(
				Name = 'Auto  test ln',
				Allowance_Type__c = autoOrdQtyRt.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		arList.add( aLineRuleOrdered );

		Allowance_Rule__c aLineRuleShipped = new Allowance_Rule__c(
				Name = 'Auto  test ln',
				Allowance_Type__c = autoShpQtyRt.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		arList.add( aLineRuleShipped );

		Allowance_Rule__c aHeadRuleOrder = new Allowance_Rule__c(
				Name = 'Auto  test hdr',
				Allowance_Type__c = autoOrdQtyRtHeader.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		arList.add( aHeadRuleOrder );

		Allowance_Rule__c aHeadRuleShipped = new Allowance_Rule__c(
				Name = 'Auto  test hdr',
				Allowance_Type__c = autoShpQtyRtHeader.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		arList.add( aHeadRuleShipped );

		insert arList;

		ApexPages.StandardController con = new ApexPages.StandardController( salesOrder );
		SalesOrderAllowancesExt ext = new SalesOrderAllowancesExt( con );
		Test.setCurrentPage( Page.SalesOrderAllowances );

		system.assertEquals( 2, ext.allLines.size(), ' should have 2 salesOrder lines' );

		test.startTest();

		// release salesOrder and assert that Allowances were applied
		new SalesOrderService().plan( salesOrder.id );

		//Allowance_Applied__c[] aa =  [select id from Allowance_Applied__c];
		//system.assertEquals(6, aa.size() , ' Epxected  nonfreight allowance');

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		con = new ApexPages.Standardcontroller( salesOrder );
		SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
		socsExt.confirmShip();

		Allowance_Applied__c[] aaList = getAppliedRecords( null, null, null );

		system.assertEquals( 6, aaList.size(), ' Epxected  nonfreight allowance' );

		for ( Allowance_Applied__c aa : aaList ) {
			if ( aa.Sales_Order__c != null ) {
				if ( aa.Allowance_Type__c == aHeadRuleShipped.Allowance_Type__c ) {
					system.assertEquals( autoOrdQtyRt.Amount__c * aa.Sales_Order__r.Total_Quantity_Ordered__c, aa.Allowance_Amount__c, 'Incorrect allowance value on salesOrder ' + aa );
				}
				else if ( aa.Allowance_Type__c == aHeadRuleOrder.Allowance_Type__c ) {
					system.assertEquals( autoShpQtyRt.Amount__c * aa.Sales_Order__r.Total_Quantity_Ordered__c, aa.Allowance_Amount__c, 'Incorrect allowance value on salesOrder ' + aa );
				}
			}
			else if ( aa.Sales_Order_Line__c != null ) {
				if ( aa.Allowance_Type__c == aLineRuleShipped.Allowance_Type__c ) {
					system.assertEquals( autoShpQtyRt.Amount__c * aa.Sales_Order_Line__r.Quantity_Ordered__c, aa.Allowance_Amount__c, 'Incorrect allowance value on SOL ' + aa + ' ' + aa.Sales_Order_Line__r );
				}
				else if ( aa.Allowance_Type__c == aLineRuleOrdered.Allowance_Type__c ) {
					system.assertEquals( autoOrdQtyRt.Amount__c * aa.Sales_Order_Line__r.Quantity_Ordered__c, aa.Allowance_Amount__c, 'Incorrect allowance value on SOL ' + aa + ' ' + aa.Sales_Order_Line__r );
				}
			}
			else {
				System.assert( false, 'unknown allowance applied: ' + aa );
			}
		}

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		Test.stopTest();

		// verify that a customer invoice batch was created
		Customer_Invoice_Line__c[] cilList = [select Id, Sales_order__c, Sales_order__r.Total_Quantity_Ordered__c, Sales_order__r.Total_Quantity_Shipped__c from Customer_Invoice_Line__c];
		System.assert( cilList.size() > 0, cilList.size() + ' - Customer Inovice Batch failed to create' );

		// query allowance applied on customer invoice and verify shipping qty and ordered qty allowances are correct
		aaList = getAppliedRecords( 'customer_invoice_line__c != null or customer_invoice2__c != null', null, null );
		system.assertEquals( 8, aaList.size(), ' Epxected  nonfreight allowance' );

	}

	// TO DO: Test All basis together? Assert weight Allowance Amt on CI. Test for partial - separate test or use 2nd SO?
	// 	Rate By Weight Tests
	static testMethod void AllowanceInvoiceGroupingRulesTest_rateByWeightInoviceTest() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		Allowance_Type__c autoWghtRtHeader = new Allowance_Type__c(
				Name = '$.5 off per qty',
				Basis__c = BASIS_RATE_BY,
				Type__c = 'Charge',
				Rate_Field__c = 'Weight',
				Apply_At_Header__c = true,
				Amount__c = .5,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		insert autoWghtRtHeader;

		Allowance_Type__c autoWghtRt = new Allowance_Type__c(
				Name = '$.5 off per qty',
				Basis__c = BASIS_RATE_BY,
				Type__c = 'Charge',
				Rate_Field__c = 'Weight',
				Apply_At_Header__c = false,
				Amount__c = .5,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		insert autoWghtRt;

		Allowance_Rule__c ruleLine = new Allowance_Rule__c(
				Name = 'Auto  test ln',
				Allowance_Type__c = autoWghtRt.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		insert ruleLine;

		Allowance_Rule__c ruleHead = new Allowance_Rule__c(
				Name = 'Auto  test hdr',
				Allowance_Type__c = autoWghtRtHeader.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		insert ruleHead;

		ApexPages.StandardController con = new ApexPages.StandardController( salesOrder );
		SalesOrderAllowancesExt ext = new SalesOrderAllowancesExt( con );
		Test.setCurrentPage( Page.SalesOrderAllowances );

		system.assertEquals( 2, ext.allLines.size(), ' should have 2 salesOrder lines' );

		test.startTest();

		// release salesOrder and assert that Allowances were applied
		new SalesOrderService().plan( salesOrder.id );

		SalesOrderService.validateAllowancesApplied( new List<Id>{
				fuel.salesOrder.id
		}, null );
		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );
		system.assertEquals( 3, aaList.size(), ' Epxected  nonfreight allowance' );

		salesOrder = [select id, Allowances__c, Total_Weight__c FROM sales_order__c LIMIT 1];
		system.assertEquals( autoWghtRtHeader.Amount__c * salesOrder.Total_Weight__c, salesOrder.Allowances__c, 'Incorrect allowance value on SO' );

		Sales_Order_Line__c[] solLineList = [SELECT Id, Allowances__c, Product_Weight__c FROM Sales_Order_Line__c];
		for ( Sales_Order_Line__c sol : solLineList ) {
			system.assertEquals( sol.Allowances__c, autoWghtRt.Amount__c * sol.Product_Weight__c, 'Incorrect allowance value on SOL' );
		}

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		con = new ApexPages.Standardcontroller( salesOrder );
		SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
		socsExt.confirmShip();

		Shipment_Line__c[] shls = [
				Select Id, Quantity_Shipped__c, Quantity_Planned__c, Sales_order__r.Status__c, Sales_order_Line__c, Sales_order__r.Date_Time_Ordered__c, Sales_order__r.Pricing_Date__c, Shipment__r.Status__c, Shipment__r.Date_Shipped__c
				from Shipment_Line__c
				where Sales_Order__c = :salesOrder.id
		];

		system.assertEquals( 'Confirmed', shls[ 0 ].shipment__r.Status__c );

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		test.stopTest();

		// verify that a customer invoice batch was created
		System.assert( [select Id, status__c FROM Sales_order__c where Status__c = 'Closed'].size() == 1 );
		Customer_Invoice_Line__c[] cilList = [select Id, Sales_order__c, Sales_order__r.Total_Quantity_Ordered__c, Sales_order__r.Total_Quantity_Shipped__c from Customer_Invoice_Line__c];
		System.assert( cilList.size() > 0, cilList.size() + ' - Customer__cr Inovice Batch failed to create' );

		aaList = getAppliedRecords( 'customer_invoice_line__c != null or customer_invoice2__c != null', null, null );

		system.assertEquals( 4, aaList.size(), ' Epxected  nonfreight allowance' );
	}

	// TO DO: Merge assertion into another test class.
	// Test that Allowance Class is copied from the Allowance Type
	static testMethod void AllowanceInvoiceGroupingRulesTest_test_AppliedAllowanceClass() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		List<Allowance_Type__c> types = new List<Allowance_Type__c>();

		Allowance_Type__c autoHeader = new Allowance_Type__c(
				Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Amount__c = 10.00,
				Apply_At_Header__c = true,
				Allowance_Class__c = 'Spoilage',
				Currency__c = fuel.currencyUSD.ID );
		types.add( autoHeader );

		Allowance_Type__c auto = new Allowance_Type__c(
				Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Amount__c = 10.00,
				Allowance_Class__c = 'Spoilage',
				Currency__c = fuel.currencyUSD.ID );
		types.add( auto );

		insert types;

		List<Allowance_Rule__c> rules = new List<Allowance_rule__c>();

		Allowance_Rule__c ruleHead = new Allowance_Rule__c(
				Name = 'Auto  test hdr',
				Allowance_Type__c = autoHeader.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		rules.add( ruleHead );

		Allowance_Rule__c ruleLine = new Allowance_Rule__c(
				Name = 'Auto test line',
				Allowance_Type__c = auto.Id,
				End_Date__c = System.today().addDays( 10 ),
				Start_Date__c = System.today().addDays( -10 ),
				customer2__c = fuel.customerSoldTo.id );
		rules.add( ruleLine );

		insert rules;

		// Test Allowance Page to see the records displayed
		ApexPages.StandardController con = new ApexPages.StandardController( salesOrder );
		SalesOrderAllowancesExt ext = new SalesOrderAllowancesExt( con );
		Test.setCurrentPage( Page.SalesOrderAllowances );

		test.startTest();

		system.assertEquals( 2, ext.allLines.size(), ' should have 2 SOL lines' );

		new SalesOrderService().plan( salesOrder.id );
		SalesOrderService.validateAllowancesApplied( new List<Id>{
				fuel.salesOrder.id
		}, null );

		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );

		// 2 lines and 1 header
		system.assert( aaList.size() == 3, aaList.size() );
		for ( Allowance_Applied__c aa : aaList ) {
			system.assertNotEquals( aa.Allowance_Class__c, null, 'Allowance Class should be populated' );
		}
	}

	// TO DO: Add more manual types here.  Assert the amounts.
	//	Copy Manual allowances to Invoice
	static testMethod void AllowanceInvoiceGroupingRulesTest_test_manual_coppied_to_inv() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		List<Sales_Order_Line__c> solList = salesOrder.Sales_Order_Lines__r;

		List<Allowance_Type__c> atList = new List<Allowance_Type__c>();
		Allowance_Type__c manLine = new Allowance_Type__c(
				Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Amount__c = 10.00,
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID
		);
		atList.add( manLine );

		Allowance_Type__c manheader = new Allowance_Type__c( Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT,
				Type__c = 'Charge',
				Amount__c = 10.00,
				Apply_At_Header__c = true,
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID
		);
		atList.add( manheader );

		insert atList;

		List<Allowance_Rule__c> arList = new List<Allowance_Rule__c>();
		Allowance_Rule__c ruleLine = new Allowance_Rule__c(
				Name = 'manual  test Line ',
				Allowance_Type__c = manLine.Id,
				customer2__c = fuel.customerSoldTo.id,
				Start_date__c = system.today(),
				End_Date__c = system.today() + 360
		);
		arList.add( ruleLine );

		Allowance_Rule__c ruleHead = new Allowance_Rule__c(
				Name = 'manual  test hdr',
				Allowance_Type__c = manheader.Id,
				customer2__c = fuel.customerSoldTo.id,
				Start_date__c = system.today(),
				End_Date__c = system.today() + 360
		);
		arList.add( ruleHead );

		insert arList;

		TestDataForAllowance.applyManualAllowances( salesOrder.id );
		List<Allowance_Applied__c> aaList = getAppliedRecords( null, true, null );
		system.assertEquals( 3, aaList.size() );

		Test.startTest();

		// release & ship
		new SalesOrderService().plan( salesOrder.id );
		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller( salesOrder );
		SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
		socsExt.confirmShip();

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		Test.stopTest();

		// check that there are manual allowances applied to the invoice line

		aaList = getAppliedRecords( null, true, null );

		boolean saw_invoice = false, saw_invoice_line = false, saw_so = false, saw_sol = false;
		system.assertEquals( 7, aaList.size(), aaList );

		for ( Allowance_Applied__c aaa : aaList ) {
			system.debug( LoggingLevel.error, aaa );
			if ( aaa.customer_invoice2__c != null ) saw_invoice = true;
			if ( aaa.customer_invoice_line__c != null ) saw_invoice_line = true;
			if ( aaa.sales_order__c != null ) saw_so = true;
			if ( aaa.sales_order_Line__c != null ) saw_sol = true;
		}

		// only one manual allowance is coppied
		system.assertEquals( true, saw_so, ' expected salesOrder header to have a manual allowance' );
		system.assertEquals( true, saw_sol, ' expected salesOrder Line to have a manual allowance' );
		system.assertEquals( true, saw_invoice_line, ' expected invoice line to have a manual allowance' );
		system.assertEquals( false, saw_invoice, ' expected invoice header  have a manual allowance' );
	}

	static testMethod void AllowanceInvoiceGroupingRulesTest_All_net_gross() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		// separate customer hierarchy created to test matching key
		Customer__c customerParent2 = new Customer__c();
		Customer__c customerBillTo2 = new Customer__c();
		Customer__c customerSoldTo2 = new Customer__c();
		Customer__c customerShipTo2 = new Customer__c();

		customerParent2.name = fuel.company.Name + ' Customer Corp Parent 2';
		customerParent2.recordTypeId = fuel.CustomerRecordTypes.get( 'Corporate_Parent' );
		customerParent2.Company__c = fuel.company.id;
		customerParent2.Address__c = fuel.account.ID;
		customerParent2.Customer_Identifier__c = fuel.company.Name + ' CP2TEST123';
		customerParent2.Open_Sales_Orders__c = 0;
		customerParent2.Uninvoiced_Shipments__c = 0;
		customerParent2.Status__c = 'Approved';
		insert customerParent2;

		customerBillTo2.name = 'Customer Bill To 2';
		customerBillTo2.recordTypeId = fuel.CustomerRecordTypes.get( 'Bill_To' );
		customerBillTo2.Company__c = fuel.company.id;
		customerBillTo2.Payment_Term__c = fuel.terms.ID;
		customerBillTo2.Address__c = fuel.account.ID;
		customerBillTo2.Parent_Customer__c = customerParent2.id;
		customerBillTo2.Customer_Identifier__c = fuel.company.Name + ' BD2TEST123';
		customerBillTo2.Status__c = 'Approved';
		insert customerBillTo2;

		customerSoldTo2.name = 'Customer Sold To 2';
		customerSoldTo2.recordTypeId = fuel.CustomerRecordTypes.get( 'Sold_To' );
		customerSoldTo2.Company__c = fuel.company.id;
		customerSoldTo2.Address__c = fuel.account.ID;
		customerSoldTo2.Parent_Customer__c = customerBillTo2.id;
		customerSoldTo2.Customer_Identifier__c = fuel.company.Name + ' SD2TEST123';
		customerSoldTo2.Status__c = 'Approved';
		insert customerSoldTo2;

		customerShipTo2.name = 'Customer Ship To 2';
		customerShipTo2.recordTypeId = fuel.CustomerRecordTypes.get( 'Ship_To' );
		customerShipTo2.Company__c = fuel.company.id;
		customerShipTo2.Address__c = fuel.account.ID;
		customerShipTo2.Parent_Customer__c = customerSoldTo2.id;
		customerShipTo2.Customer_Identifier__c = fuel.company.Name + ' SH2TEST123';
		customerShipTo2.Status__c = 'Approved';
		insert customerShipTo2;

		// 4 types of Allowance Types: Net, Gross AND Freight, Invoice

		List<Allowance_Type__c> types = new List<Allowance_Type__c>();
		Allowance_Type__c atNetHeader = new Allowance_Type__c( Name = 'Net 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Target_Field__c = TARGET_FIELD_NET,
				Percent_Of_Target_Field__c = 2,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atNetHeader );

		Allowance_Type__c atGrossHeader = new Allowance_Type__c( Name = 'Gross 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Target_Field__c = TARGET_FIELD_GROSS,
				Percent_Of_Target_Field__c = 2,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atGrossHeader );

		Allowance_Type__c atNetFHeader = new Allowance_Type__c( Name = 'Net 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Target_Field__c = TARGET_FIELD_NET,
				Percent_Of_Target_Field__c = 2,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atNetFHeader );

		Allowance_Type__c atGrossFHeader = new Allowance_Type__c( Name = 'Gross 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Apply_At_Header__c = true,
				Target_Field__c = TARGET_FIELD_GROSS,
				Percent_Of_Target_Field__c = 2,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atGrossFHeader );

		// LINES
		Allowance_Type__c atNet = new Allowance_Type__c( Name = 'Net 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Target_Field__c = TARGET_FIELD_NET,
				Percent_Of_Target_Field__c = 2,
				Apply_At_Header__c = false,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atNet );

		Allowance_Type__c atGross = new Allowance_Type__c( Name = 'Gross 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Target_Field__c = TARGET_FIELD_GROSS,
				Percent_Of_Target_Field__c = 2,
				Apply_At_Header__c = false,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atGross );

		Allowance_Type__c atNetF = new Allowance_Type__c( Name = 'Net 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Target_Field__c = TARGET_FIELD_NET,
				Percent_Of_Target_Field__c = 2,
				Apply_At_Header__c = false,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atNetF );

		Allowance_Type__c atGrossF = new Allowance_Type__c( Name = 'Gross 20% off',
				Basis__c = BASIS_TARGET_PERCENT,
				Type__c = 'Charge',
				Target_Field__c = TARGET_FIELD_GROSS,
				Percent_Of_Target_Field__c = 2,
				Apply_At_Header__c = false,
				Manual__c = false,
				Currency__c = fuel.currencyUSD.ID );
		types.add( atGrossF );

		insert types;

		// INVOICE RULES for the correct customer
		Allowance_Rule__c ar1 = new Allowance_Rule__c( Name = '20% off Net - header ',
				Allowance_Type__c = atNetHeader.Id,
				Customer2__c = fuel.customerParent.Id );
		Allowance_Rule__c ar2 = new Allowance_Rule__c( Name = '20% off Net - line ',
				Allowance_Type__c = atNet.Id,
				Customer2__c = fuel.customerParent.Id );

		Allowance_Rule__c ar3 = new Allowance_Rule__c( Name = '20% off Gross - header ',
				Allowance_Type__c = atGrossHeader.Id,
				Customer2__c = fuel.customerParent.Id );
		Allowance_Rule__c ar4 = new Allowance_Rule__c( Name = '20% off Gross - Line',
				Allowance_Type__c = atGross.Id,
				Customer2__c = fuel.customerParent.Id );

		// INVOICE RULES for the wrong customer
		Allowance_Rule__c ar1b = new Allowance_Rule__c( Name = '20% off Net - header ',
				Allowance_Type__c = atNetHeader.Id,
				Customer2__c = customerParent2.id );
		Allowance_Rule__c ar2b = new Allowance_Rule__c( Name = '20% off Net - line ',
				Allowance_Type__c = atNet.Id,
				Customer2__c = customerParent2.id );

		Allowance_Rule__c ar3b = new Allowance_Rule__c( Name = '20% off Gross - header ',
				Allowance_Type__c = atGrossHeader.Id,
				Customer2__c = customerParent2.id );
		Allowance_Rule__c ar4b = new Allowance_Rule__c( Name = '20% off Gross - Line',
				Allowance_Type__c = atGross.Id,
				Customer2__c = customerParent2.id );

		// FREIGHT RULES for the correct customer
		Allowance_Rule__c ar2F = new Allowance_Rule__c( Name = '20% off Net - line ',
				Allowance_Type__c = atNetF.Id,
				Customer2__c = salesOrder.Customer__r.Top_Parent_Customer__c );

		Allowance_Rule__c ar4F = new Allowance_Rule__c( Name = '20% off Gross - Line',
				Allowance_Type__c = atGrossF.Id,
				Customer2__c = salesOrder.Customer__r.Top_Parent_Customer__c );

		// FREIGHT RULES for another customer
		Allowance_Rule__c ar2bF = new Allowance_Rule__c( Name = '20% off Net - line ',
				Allowance_Type__c = atNetF.Id,
				Customer2__c = customerParent2.id );

		Allowance_Rule__c ar4bF = new Allowance_Rule__c( Name = '20% off Gross - Line',
				Allowance_Type__c = atGrossF.Id,
				Customer2__c = customerParent2.id );
		insert new list<Allowance_Rule__c>{
				ar1, ar2, ar3, ar4, ar1b, ar2b, ar3b, ar4b
		};
		insert new list<Allowance_Rule__c>{
				ar2F, ar4F, ar2bF, ar4bF
		};

		Test.startTest();
		decimal expectedOrderTotal = 24500.000000; // subtotal 1348.97 + tax
		salesOrder = [select id, order_total__c, customer__r.Top_Parent_Customer__c, Allowances__c, (select id, Allowances__c, Extended_price__c, Quantity_Ordered__c, Unit_Price__c from Sales_order_lines__r) from sales_order__c where id = :salesOrder.id LIMIT 1];

		system.debug( logginglevel.error, salesOrder );
		for ( Sales_Order_Line__c sol : salesOrder.Sales_Order_Lines__r ) {
			system.debug( logginglevel.error, 'sol: ' + sol );
		}
		system.assertEquals( (expectedOrderTotal).setScale(2, System.RoundingMode.HALF_UP), salesOrder.Order_Total__c, 'incorrect Order_Total__c on fuel.salesorder' );

		new SalesOrderService().plan( salesOrder.id );
		System.assertEquals( false, ExceptionService.hasErrors, ExceptionService.messages );

		FulfillmentService.processedShipmentLineIds = new set<Id>();
		ApexPages.Standardcontroller con = new ApexPages.Standardcontroller( salesOrder );
		SalesOrderConfirmShipExtension socsExt = new SalesOrderConfirmShipExtension( con );
		socsExt.confirmShip();

		Shipment_Line__c[] shls = [
				Select Id, Quantity_Shipped__c, Quantity_Planned__c, Sales_order__r.Status__c, Sales_order_Line__c, Sales_order__r.Date_Time_Ordered__c, Sales_order__r.Pricing_Date__c, Shipment__r.Status__c, Shipment__r.Date_Shipped__c
				from Shipment_Line__c
				where Sales_Order__c = :salesOrder.id
		];

		system.assertEquals( 'Confirmed', shls[ 0 ].shipment__r.Status__c );

		Database.executebatch( new CustomerInvoiceBatch( new set<ID>{
				fuel.company.Id
		} ), 10 );

		Test.stopTest();

		Map <id, Sales_Order__c> allSOs = new Map<id, Sales_order__c>( [
				select id, Allowances__c, Order_Total__c, Subtotal__c, (
						select id, Discount_Percent__c, Off_Invoice_Rate__c, Allowances__c, Freight_Allowance__c, Extended_price__c, Quantity_Ordered__c, Quantity_Shipped__c, Unit_price__c
						from Sales_Order_Lines__r
				)
				from Sales_order__c
				where id = :salesOrder.id
		] );

		Customer_Invoice_Line__c[] cilList = [
				select Id, Discount_Percent__c, Off_Invoice_Rate__c, Allowances__c, Freight_Allowance__c, Extended_price__c, Quantity_Shipped__c, Unit_price__c, Sales_order__c, Sales_order__r.Total_Quantity_Ordered__c, Sales_order__r.Total_Quantity_Shipped__c, Sales_Order_Line__c, Sales_Order_Line__r.Quantity_Ordered__c, Sales_Order_Line__r.Allowances__c, Sales_Order_Line__r.Freight_Allowance__c, Sales_Order_Line__r.Off_Invoice_Rate__c, Sales_Order_Line__r.Discount_Percent__c
				from Customer_Invoice_Line__c
		];

		System.assert( cilList.size() > 0, cilList.size() + ' - Inovice Batch failed to create' );

		for ( Customer_Invoice_Line__c cil : cilList ) {

			Sales_Order_Line__c sol = cil.Sales_Order_Line__r;

			// commented out because header allowance distribution to lines is difficult to calculate dynamically
			//System.assert(cil.Allowances__c == sol.Allowances__c, 'Line Allowances - CI: ' + cil.Allowances__c + ', SO: ' +  sol.Allowances__c);
			System.assert( cil.Freight_Allowance__c == sol.Freight_Allowance__c, 'Line Freight - CI: ' + cil.Freight_Allowance__c + ', SO: ' + sol.Freight_Allowance__c );

			System.assert( cil.Off_Invoice_Rate__c == sol.Off_Invoice_Rate__c, 'Line Off invoice rate - CI: ' + cil.Off_Invoice_Rate__c + ', SO: ' + sol.Off_Invoice_Rate__c );
			System.assert( cil.Discount_Percent__c == sol.Discount_Percent__c, 'Line discount percent - CI: ' + cil.Discount_Percent__c + ', SO: ' + sol.Discount_Percent__c );

		}

		//system.debug(LoggingLevel.INFO,'Queries invoice()'+Limits.getQueries() );

		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );

		List<Allowance_Applied__c> aaSOHeader = new List<Allowance_Applied__c>();
		List<Allowance_Applied__c> aaSOLList = new List<Allowance_Applied__c>();
		List<Allowance_Applied__c> aaCIHeader = new List<Allowance_Applied__c>();
		List<Allowance_Applied__c> aaCILList = new List<Allowance_Applied__c>();

		for ( Allowance_Applied__c aa : aaList ) {
			if ( aa.sales_order__c != null ) {
				aaSOHeader.add( aa );
			}
			if ( aa.sales_order_Line__c != null ) {
				aaSOLList.add( aa );
			}
			if ( aa.customer_invoice2__c != null ) {
				aaCIHeader.add( aa );
			}
			if ( aa.customer_invoice_line__c != null ) {
				aaCILList.add( aa );
			}
		}

		system.assertEquals( 0, aaCIHeader.size(), 'expected allowance applied record created on salesOrder header' );
		system.assertEquals( aaSOLList.size() + aaSOHeader.size() * 2, aaCILList.size(), 'expected allowance applied record created on salesOrder Lines' );
	}

	/************************************************************
	*  	AllowanceAppliedNewTest TESTS
	*************************************************************/

	static testmethod void AllowanceAppliedNewTest_editingAutomaticOverrideAllowance() {
		// Pass in automatic allowance w/o Allow override. Expect Error.
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = fuel.salesOrder.Sales_Order_Lines__r[ 0 ];

		Allowance_Type__c header = new Allowance_Type__c( Name = '10 $ Flat off header',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Type__c = 'Charge',
				Apply_At_Header__c = false,
				Manual__c = false,
				Allow_Override__c = false,
				Currency__c = fuel.currencyUSD.ID
		);

		Allowance_Type__c line = new Allowance_Type__c( Name = '10 $ Flat off line',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Type__c = 'Charge',
				Apply_At_Header__c = false,
				Manual__c = false,
				Allow_Override__c = true,
				Currency__c = fuel.currencyUSD.ID
		);
		insert new list<Allowance_Type__c>{
				line, header
		};

		Allowance_Rule__c ar1 = new Allowance_Rule__c( Name = '10$ off on Line ',
				Allowance_Type__c = line.Id,
				Product__c = soLine.product__c,
				Start_Date__c = System.today().addDays( -1 ),
				End_Date__c = System.today().addDays( 100 ),
				Allowance_Code__c = 'ABC1'
		);

		Allowance_Rule__c ar2 = new Allowance_Rule__c( Name = '10$ off on header ',
				Allowance_Type__c = header.Id,
				Product__c = soLine.product__c,
				Start_Date__c = System.today().addDays( -1 ),
				End_Date__c = System.today().addDays( 100 ),
				Allowance_Code__c = 'ABC2'
		);
		insert new list<Allowance_rule__c>{
				ar1, ar2
		};

		AllowanceService.validateAllowancesApplied( new List<Id>{
				salesOrder.id
		}, null );

		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );
		system.assertEquals( 2, aaList.size(), 'Expecting allowance to get applied' );

		// Pass in automatic allowance w/ Allow override. Expect no error. Update successfully. Validate Allowance Amount
		Allowance_Applied__c aa = aaList[ 1 ];
		ApexPages.StandardController con2 = new ApexPages.StandardController( aa );
		ApexPages.currentPage().getParameters().put( 'rid', salesOrder.id );
		AllowancesAppliedNewExt ext2 = new AllowancesAppliedNewExt( con2 );

		system.debug( logginglevel.error, ext2 );
		// error should be Cannot edit this type of message
		PageReference pageRef = ApexPages.currentPage();
		pageRef.setRedirect( true );
		System.assertEquals( ApexPages.getMessages().size(), 0, 'Not expecting any messages' + ApexPages.getMessages() );

		system.assert( ext2.allowance != null );
		system.assert( ext2.soLine != null );
		system.assert( ext2.sorder != null );
	}

	static testmethod void AllowanceAppliedNewTest_editingAutomaticAllowance() {
		// Pass in automatic allowance w/o Allow override. Expect Error.
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = fuel.salesOrder.Sales_Order_Lines__r[ 0 ];

		Allowance_Type__c header = new Allowance_Type__c(
				Name = '10 $ Flat off header',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Type__c = 'Charge',
				Apply_At_Header__c = false,
				Manual__c = false,
				Allow_Override__c = false,
				Currency__c = fuel.currencyUSD.ID
		);

		Allowance_Type__c line = new Allowance_Type__c(
				Name = '10 $ Flat off line',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Type__c = 'Charge',
				Apply_At_Header__c = false,
				Manual__c = false,
				Allow_Override__c = true,
				Currency__c = fuel.currencyUSD.ID
		);
		insert new list<Allowance_Type__c>{
				line, header
		};

		Allowance_Rule__c ar1 = new Allowance_Rule__c(
				Name = '10$ off on Line ',
				Allowance_Type__c = line.Id,
				Product__c = soLine.product__c,
				Start_Date__c = System.today().addDays( -1 ),
				End_Date__c = System.today().addDays( 100 ),
				Allowance_Code__c = 'ABC1'
		);

		Allowance_Rule__c ar2 = new Allowance_Rule__c(
				Name = '10$ off on header ',
				Allowance_Type__c = header.Id,
				Product__c = soLine.product__c,
				Start_Date__c = System.today().addDays( -1 ),
				End_Date__c = System.today().addDays( 100 ),
				Allowance_Code__c = 'ABC2'
		);
		insert new list<Allowance_rule__c>{
				ar1, ar2
		};

		AllowanceService.validateAllowancesApplied( new List<Id>{
				salesOrder.id
		}, null );

		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );
		system.assertEquals( 2, aaList.size(), 'Expecting allowance to get applied' );

		Allowance_Applied__c aa = aaList[ 0 ];

		ApexPages.StandardController con = new ApexPages.StandardController( aa );
		ApexPages.currentPage().getParameters().put( 'rid', salesOrder.id );
		AllowancesAppliedNewExt ext = new AllowancesAppliedNewExt( con );

		// error should be Cannot edit this type of message
		System.assertEquals( ApexPages.getMessages().size(), 1 );
		System.assertEquals( ApexPages.getMessages()[ 0 ].getDetail(), 'Cannot edit this type of allowance.' );

		system.debug( logginglevel.error, ext );
		system.assert( ext.allowance != null );
		system.assert( ext.soLine == null );
		system.assert( ext.sorder == null );

	}

	static testmethod void AllowanceAppliedNewTest_editingManualAllowances() {
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;
		Sales_Order_Line__c soLine = fuel.salesOrder.Sales_Order_Lines__r[ 0 ];

		Allowance_Type__c line1 = new Allowance_Type__c( Name = '10 $ Flat off header',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Type__c = 'Charge',
				Apply_At_Header__c = false,
				Manual__c = true,
				Allow_Override__c = true,
				Currency__c = fuel.currencyUSD.ID
		);

		Allowance_Type__c line2 = new Allowance_Type__c( Name = '10 $ Flat off line',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 20.00,
				Type__c = 'Charge',
				Apply_At_Header__c = false,
				Manual__c = true,
				Allow_Override__c = true,
				Currency__c = fuel.currencyUSD.ID
		);
		insert new list<Allowance_Type__c>{
				line1, line2
		};

		Allowance_Rule__c ar1 = new Allowance_Rule__c( Name = '10$ off on Line ',
				Allowance_Type__c = line1.Id,
				Start_Date__c = System.today().addDays( -1 ),
				Customer2__c = salesOrder.Customer__c,
				Product__c = soLine.product__c,
				Allowance_Code__c = 'ABC1'
		);

		Allowance_Rule__c ar2 = new Allowance_Rule__c( Name = '10$ off on header ',
				Allowance_Type__c = line2.Id,
				Start_Date__c = System.today().addDays( -1 ),
				Customer2__c = salesOrder.Customer__c,
				Product__c = soLine.product__c,
				Allowance_Code__c = 'ABC2'
		);
		insert new list<Allowance_rule__c>{
				ar1, ar2
		};

		TestDataForAllowance.applyManualAllowances( salesOrder.id, true );
		List<Allowance_Applied__c> aaList = getAppliedRecords( null, null, null );
		system.assertEquals( 2, aaList.size(), 'Expecting allowance to get applied' );

		Allowance_Applied__c aa = aaList[ 0 ];

		ApexPages.StandardController con = new ApexPages.StandardController( aa );
		// set the rid parameter, see that the allowance knows who it's related to
		ApexPages.currentPage().getParameters().put( 'rid', salesOrder.id );
		AllowancesAppliedNewExt ext = new AllowancesAppliedNewExt( con );

		system.debug( logginglevel.error, ext );
		system.assert( ext.soLine != null );
		system.assert( ext.sorder != null );
		system.assert( ext.hasError == false );
		system.assert( ext.disableOverride == false );
		system.assertEquals( ext.selectedRule, aa.Allowance_Rule2__c );

		system.assertEquals( 2, ext.validRulesMap.size() );
		system.assertEquals( 2, ext.validCodeMap.size() );
		system.assert( ext.Rules.size() > 0 );

		// text override value and then clear it
		system.assertEquals( ext.allowance.Override_Value__c, 0.05 );
		system.assertEquals( ext.allowance.Allowance_Amount__c, 0.05 );
		ext.allowance.Override_Value__c = Null;
		ext.overrideValueChange();
		system.assertEquals( ext.allowance.Allowance_Rule2__c, ar2.id );
		system.assertEquals( ext.allowance.Override_Value__c, Null, 'Override value should be cleared out' );
		system.assertEquals( 20, ext.allowance.Allowance_Amount__c, 'expecting allowance amt to get updated' );

		//		change code
		//		ext.selectedRule = ar1.id;
		ext.selectedCode = ar1.Allowance_Code__c;
		ext.allowanceCodeChange();
		system.assertEquals( ar1.Allowance_Code__c, ext.selectedCode );
		system.assertEquals( ext.allowance.Allowance_Rule2__c, ar1.Id );
		system.assertEquals( 10, ext.allowance.Allowance_Amount__c, 'expecting allowance amt to get updated' );

		//		ext.saveAllowance();
		//		aaList =  getAppliedRecords(null, null, null);

		system.assertEquals( 2, aaList.size(), 'Expecting allowance to get applied.' );

		// Test Editing AA record
		// Test overriding - changing value
		// Test Allowance Rule Code - changing value
		system.assertEquals( ext.Codes.size(), 2, ' expected 2 rules & codes' );
	}
	/* TO DO: Create more Rules & Type combinations */
	static testMethod void AllowanceAppliedNewTest_test_rules() {
		// build one rule for this test
		AllowanceRuleService.testAllowances = true;
		Sales_Order__c salesOrder = fuel.salesOrder;

		Allowance_Type__c man = new Allowance_Type__c( Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Type__c = 'Charge',
				Apply_At_Header__c = false,
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID );
		insert man;

		Allowance_Type__c manHeader = new Allowance_Type__c( Name = '10 $ Flat off',
				Basis__c = BASIS_FLAT_AMOUNT, // 'Flat Amount',
				Amount__c = 10.00,
				Apply_At_Header__c = true,
				Type__c = 'Charge',
				Manual__c = true,
				Currency__c = fuel.currencyUSD.ID );
		insert manHeader;

		Allowance_Rule__c ar = new Allowance_Rule__c( Name = '10$ off on header ',
				Allowance_Type__c = manHeader.Id,
				Start_Date__c = System.today().addDays( -1 ),
				Customer2__c = salesOrder.Customer__c );
		insert ar;
		Allowance_Rule__c arLine = new Allowance_Rule__c( Name = '10$ off on header ',
				Allowance_Type__c = man.Id,
				Start_Date__c = System.today().addDays( -1 ),
				Customer2__c = salesOrder.Customer__c,
				Product__c = fuel.product.id );
		insert arLine;
		Allowance_Rule__c arLine2 = new Allowance_Rule__c(
				Name = '10$ off on header old',
				Allowance_Type__c = man.Id,
				Start_Date__c = System.today().addDays( -100 ),
				End_Date__c = System.today().addDays( -10 ),
				Customer2__c = salesOrder.Customer__c,
				Product__c = fuel.product.id );
		// this is an expired rule, should not show up in the valid rules map !
		insert arLine2;

		Test.startTest();
		Allowance_Applied__c aa = new Allowance_Applied__c( Sales_Order__c = salesOrder.Id );
		ApexPages.StandardController con = new ApexPages.StandardController( aa );
		// set the rid parameter, see that the allowance knows who it's related to
		ApexPages.currentPage().getParameters().put( 'rid', salesOrder.id );
		AllowancesAppliedNewExt ext = new AllowancesAppliedNewExt( con );

		system.assert( ext.allowance != null, ' expected allowance to be set' );
		system.assertEquals( 1, ext.validRulesMap.size(), ' expected a manual rule header...' );
		//
		//
		// set the rid parameter, see that the allowance knows who it's related to
		ApexPages.currentPage().getParameters().put( 'rid', salesOrder.Sales_Order_Lines__r[ 0 ].id );
		AllowancesAppliedNewExt ext2 = new AllowancesAppliedNewExt( con );
		system.assert( ext2.allowance != null, ' expected allowance to be set' );
		system.assertEquals( 1, ext2.validRulesMap.size(), ' expected a manual rule lines...' );

		// test the AllowanceAppliedNew vf page
		Test.setCurrentPage( Page.AllowanceAppliedNew );
		ApexPages.currentPage().getParameters().put( 'rid', salesOrder.id );
		AllowancesAppliedNewExt ext3 = new AllowancesAppliedNewExt( con );
		system.assert( ext3.allowance != null, ' epxected allowance to be set' );
		system.assert( ext3.Rules.size() > 0, ' expected some rules' );
		system.assert( ext3.allowance.Sales_Order__c != null, ' expected order to be set' );
		// select the rule, fill in the amount, test saveAllowance
		ext3.allowance.Allowance_Type__c = ar.Allowance_Type__c;
		PageReference afterSave = ext3.saveAllowance();
		system.assert( afterSave != null, 'expected a page ref after a save' );
		system.debug( LoggingLevel.INFO, afterSave );
	}

	/************************************************************
	*  	AllowanceTypeNewExt page & controller TESTS
	*************************************************************/
	static testMethod void testAllowanceTypeNewExt() {
		AllowanceRuleService.testAllowances = true;

		// test cloning, creating new, and editing.
		Allowance_Type__c newAt = new Allowance_Type__c();
		ApexPages.StandardController con = new ApexPages.StandardController( newAt );
		AllowanceTypeNewExt newATNE = new AllowanceTypeNewExt( con );
		system.assert( newATNE.isClone == false );

		// create new Allowance
		System.debug( loggingLevel.Error, '~*~ newATNE.getHeaderFieldList(): ' + newATNE.getHeaderFieldList() );
		JsonResult jsonResult = AllowanceTypeNewExt.getAllowanceType( null, false );
		newAt = ( Allowance_Type__c ) jsonResult.records[ 0 ];
		system.assert( newAt != null );
		AllowanceTypeNewExt.createNewAllowance( newAt );

		//edit exisitng allowance

		// clone existing allowance

	}

}