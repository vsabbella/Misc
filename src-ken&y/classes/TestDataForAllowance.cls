public with sharing class TestDataForAllowance {
	public TestDataForAllowance() {

		TestFuel fuel = new TestFuel();
		
		// the asserts cause TestFuel to insert the data
		System.assert(
		    fuel.periodList != null &&
		    fuel.uomList != null &&
		    fuel.company != null &&
		    fuel.terms != null &&
		    fuel.CALENDAR_MONTH != null
		);

		Company__c company = fuel.company;

		Pricebook__c pricebook = new Pricebook__c();
		pricebook.name = company.Name +  'Orange Pricebook';
		pricebook.company__c = company.id;
		pricebook.Primary_Key__c = 'NATBOOK';
		pricebook.Currency__c = TestFuel.currencyUSD.id;
		pricebook.Default__c = true;
		insert pricebook;

		List<Customer_Group__c> cgList = new List<Customer_Group__c>();
		Customer_Group__c customerGroup1 = new Customer_Group__c(Name = 'Customer Group1', Company__c = fuel.company.id);
		cgList.add(customerGroup1);

		Customer_Group__c customerGroup2 = new Customer_Group__c(Name = 'Customer Group2', Company__c = fuel.company.id);
		cgList.add(customerGroup2);

		Customer_Group__c customerGroup3 = new Customer_Group__c(Name = 'Customer Group3', Company__c = fuel.company.id);
		cgList.add(customerGroup3);

		Customer_Group__c customerGroup4 = new Customer_Group__c(Name = 'Customer Group4', Company__c = fuel.company.id);
		cgList.add(customerGroup4);
		insert cgList;

		/* create customer data */

		Customer__c customerParent = new Customer__c();
		customerParent.name = company.Name + ' Customer Corp Parent 1';
		customerParent.recordTypeId = fuel.CustomerRecordTypes.get('Corporate_Parent');
		customerParent.Company__c = company.id;
		customerParent.Payment_Term__c = fuel.terms.ID;
		customerParent.Credit_Limit__c = 100000.0;
		customerParent.Customer_Identifier__c = 'CPTEST123';
		customerParent.Record_Type_Name__c = 'Corporate_Parent';
		customerParent.Status__c = 'Approved';
		customerParent.Currency__c = TestFuel.currencyUSD.ID;
		customerParent.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
		customerParent.Customer_City__c = 'Redwood City';
		customerParent.Customer_State__c = 'CA';
		customerParent.Customer_Zip_Code__c = '94065';
		customerParent.Customer_Country__c = 'USA';
		customerParent.Customer_Group__c = cgList[0].id;
		insert customerParent;

		Customer__c customerBillTo = new Customer__c();
		customerBillTo.name = 'Customer Bill To 1';
		customerBillTo.recordTypeId = fuel.CustomerRecordTypes.get('Bill_To');
		customerBillTo.Company__c = company.id;
		customerBillTo.Payment_Term__c = fuel.terms.ID;
		//ustomerBillTo.Address__c = this.account.ID;
		customerBillTo.Credit_Limit__c = 100000.0;
		customerBillTo.Parent_Customer__c = customerParent.id;
		customerBillTo.Top_Parent_Customer__c = customerParent.id;
		customerBillTo.Customer_Identifier__c = 'BDTEST123';
		customerBillTo.Status__c = 'Approved';
		customerBillTo.Currency__c = TestFuel.currencyUSD.ID;
		customerBillTo.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
		customerBillTo.Customer_City__c = 'Redwood City';
		customerBillTo.Customer_State__c = 'CA';
		customerBillTo.Customer_Zip_Code__c = '94065';
		customerBillTo.Customer_Country__c = 'USA';
		customerBillTo.Customer_Group__c = cgList[1].id;
		insert customerBillTo;

		Customer__c customerSoldTo = new Customer__c();
		customerSoldTo.name = 'Customer Sold To 1';
		customerSoldTo.recordTypeId = fuel.CustomerRecordTypes.get('Sold_To');
		customerSoldTo.Company__c = company.id;
		customerSoldTo.Payment_Term__c = fuel.terms.ID;
		//customerSoldTo.Address__c = this.account.ID;
		customerSoldTo.Credit_Limit__c = 100000.0;
		customerSoldTo.Parent_Customer__c = customerBillTo.id;
		customerSoldTo.Customer_Identifier__c = 'SDTEST123';
		customerSoldTo.Record_type_name__c = 'Sold_To';
		customerSoldTo.pricebook__c = pricebook.id;
		customerSoldTo.Top_Parent_Customer__c = customerParent.id;
		customerSoldTo.Status__c = 'Approved';
		customerSoldTo.Currency__c = TestFuel.currencyUSD.ID;
		customerSoldTo.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
		customerSoldTo.Customer_City__c = 'Redwood City';
		customerSoldTo.Customer_State__c = 'CA';
		customerSoldTo.Customer_Zip_Code__c = '94065';
		customerSoldTo.Customer_Country__c = 'USA';
		customerSoldTo.Customer_Group__c = cgList[2].id;
		insert customerSoldTo;

		Customer__c customerShipTo = new Customer__c();
		customerShipTo.name = 'Customer Ship To 1';
		customerShipTo.recordTypeId = fuel.CustomerRecordTypes.get('Ship_To');
		customerShipTo.Company__c = company.id;
		customerShipTo.Payment_Term__c = fuel.terms.ID;
		customerShipTo.Currency__c = TestFuel.currencyUSD.ID;
		//customerShipTo.Address__c = this.account.ID;
		customerShipTo.Credit_Limit__c = 100000.0;
		customerShipTo.Parent_Customer__c = customerSoldTo.id;
		customerShipTo.Customer_Identifier__c = 'SHTEST123';
		customerShipTo.Top_Parent_Customer__c = customerParent.id;
		customerShipTo.Status__c = 'Approved';
		customerShipTo.Business_Hours__c = [select Id from BusinessHours where isDefault = true limit 1].Id;
		customerShipTo.Customer_Street__c = '303 Twin Dolphin Drive, Suite 500';
		customerShipTo.Customer_City__c = 'Redwood City';
		customerShipTo.Customer_State__c = 'CA';
		customerShipTo.Customer_Zip_Code__c = '94065';
		customerShipTo.Customer_Country__c = 'USA';
		customerShipTo.Customer_Group__c = cgList[3].id;
		insert customerShipTo;

		// Setup hierarchies
		Hierarchy__c l2Hierarchy1;
		Hierarchy__c promoGroupHierarchy1;
		Hierarchy__c caseUPChierarchy1;

		l2Hierarchy1 = new Hierarchy__c(
		    Code__c = 'H1110' ,
		    Primary_Key__c = 'H1110' ,
		    Type__c = 'Product Hierarchy',
		    // top needs to be null
		    // since L2 is top in this test set it null
		    Parent_Code__c = null,
		    Level__c = 'L2'
		);
		insert l2Hierarchy1;

		promoGroupHierarchy1 = new Hierarchy__c(
		    Code__c = 'H1111' ,
		    Primary_Key__c = 'H1111' ,
		    Type__c = 'Product Hierarchy',
		    Parent_Code__c = 'H1110',
		    Level__c = 'PromoGroup',
		    Parent__c = l2Hierarchy1.Id
		);
		insert promoGroupHierarchy1;

		caseUPChierarchy1 = new Hierarchy__c(
		    Code__c = 'H1113' ,
		    Primary_Key__c = 'H1113' ,
		    Type__c = 'Product Hierarchy',
		    Parent_Code__c = 'H1111',
		    Level__c = 'Case UPC',
		    Parent__c = promoGroupHierarchy1.Id
		);
		insert caseUPChierarchy1;

		// using Non-inventory Item to Fulfill Order faster & with less queries by skipping shipment processes
		List<Item__c> nonInventoryItems = new List<Item__c>();
		for (Integer i = 0; i < 2; i ++) {
			Item__c item = new Item__c();
			item.name = company.Name + ' Item-' + i;
			item.Description__c = 'Item-' + i;
			item.Source__c = 'Miscellaneous';
			item.company__c = company.id;
			item.Active__c = true;
			item.Stocking_UOM__c = fuel.uomList[8].Id;
			item.Packaging_UOM__c = JSON.serialize(new List<Id>{ fuel.uomList[8].Id });
			item.item_attribute__c = fuel.itemAttrObj.ID;
			item.Non_Inventory__c = true;
			nonInventoryItems.add(item);
		}
		insert nonInventoryItems;

		Product__c product = fuel.newProduct();
		product.item__c = nonInventoryItems[0].id;
		product.product_group__c = fuel.productgroup.id;
		product.sales_hierarchy__c = caseUPChierarchy1.id;
		product.name = 'Product-10';
		product.Weight_UOM__c = fuel.uomList[3].ID;
		product.Dimension_UOM__c = fuel.uomList[6].ID;

		Product__c product2 = fuel.newProduct2();
		product2.item__c = nonInventoryItems[1].id;
		product2.name = 'Product-15';
		product2.Weight_UOM__c = fuel.uomList[3].ID;
		product2.Dimension_UOM__c = fuel.uomList[6].ID;

		insert new List<Product__c> {product, product2};

		Pricebook_Line__c pl = new Pricebook_Line__c();
		pl.product__c = product.id;
		pl.pricebook__c = pricebook.id;
		pl.price__c = 100;
		pl.start_date__c = system.today();
		pl.end_date__c = system.today().addDays(100);	// 			pl.End_Date__c = system.today() + 10;

		Pricebook_Line__c pl2 = new Pricebook_Line__c();
		pl2.product__c = product2.id;
		pl2.pricebook__c = pricebook.id;
		pl2.price__c = 1000;
		pl2.start_date__c = system.today();
		pl2.end_date__c = system.today().addDays(100);	// 			pl2.End_Date__c = system.today() + 10;
		insert new List<Pricebook_Line__c> {pl, pl2};

		// Run up Hierarchy Path which populates Hierarchy Path on all hierarchies
		HierarchyController hieCon = new HierarchyController( new Apexpages.standardController( l2Hierarchy1 ) );
		hieCon.setHierarchyPath();
		update hieCon.allRecords.values();// updates the fuelbase

		// Create SO and SOLs using new products
		Sales_Order__c salesOrder = new Sales_Order__c();
		salesOrder.Company__c = company.id;
		salesOrder.Customer__c = customerSoldTo.Id;
		salesOrder.Ship_To__c = customerShipTo.Id;
		salesOrder.Bill_To__c = customerBillTo.Id;
		salesOrder.Payment_Term__c = fuel.terms.id;
		salesOrder.Currency__c = TestFuel.currencyUSD.id ;
		salesOrder.Status__c = 'Draft';
		salesOrder.Type__c = 'Standard';
		salesOrder.Weight_UOM__c = fuel.uomList[3].ID;
		salesOrder.Dimension_UOM__c = fuel.uomList[6].ID;
		salesOrder.Original_Sales_Order__c = 'salesOrder';
		salesOrder.Price_determination_date__c = SalesOrderService.PRICE_DET_ORDER;
		insert salesOrder;

		List<Sales_Order_Line__c> solList = new List<Sales_Order_Line__c>();

		Sales_Order_Line__c salesOrderLine = new Sales_Order_Line__c();
		salesOrderLine.Company__c = company.Id;
		salesOrderLine.Description__c = product.Description__c;
		salesOrderLine.Discount_Percent__c = 2;
		salesOrderLine.Product__c = product.Id;
		salesOrderLine.Weight_UOM__c = product.Weight_UOM__c;
		salesOrderLine.Selling_UOM__c = product.Selling_UOM__c;
		salesOrderLine.Dimension_UOM__c = product.Dimension_UOM__c;
		salesOrderLine.Quantity_Ordered__c = 100;
		salesOrderLine.Required_Date__c = System.today() + 5;
		salesOrderLine.Sales_Order__c = salesOrder.Id;
		salesOrderLine.Ship_From_Location__c = fuel.location2.Id;
		salesOrderLine.Unit_Price__c = 100;
		salesOrderLine.Memo__c = 'salesOrderLine';
		salesOrderLine.Ordered_Date_Time__c = System.now();
		salesOrderLine.Pricebook__c = pricebook.id;
		solList.add(salesOrderLine);

		Sales_Order_Line__c salesOrderLine2 = new Sales_Order_Line__c();
		salesOrderLine2.Company__c = company.id;
		salesOrderLine2.Description__c = product2.Description__c;
		salesOrderLine2.Discount_Percent__c = 2;
		salesOrderLine2.Product__c = product2.Id;
		salesOrderLine2.Weight_UOM__c = product2.Weight_UOM__c;
		salesOrderLine2.Selling_UOM__c = product2.Selling_UOM__c;
		salesOrderLine2.Dimension_UOM__c = product2.Dimension_UOM__c;
		salesOrderLine2.Quantity_Ordered__c = 15;
		salesOrderLine2.Required_Date__c = System.today() + 15;
		salesOrderLine2.Sales_Order__c = salesOrder.Id;
		salesOrderLine2.Ship_From_Location__c = fuel.location2.Id;
		salesOrderLine2.Unit_Price__c = 1000;
		salesOrderLine2.Memo__c = 'salesOrderLine2';
		salesOrderLine.Ordered_Date_Time__c = System.now();
		salesOrderLine.Pricebook__c = pricebook.id;
		solList.add(salesOrderLine2);

		insert solList;

		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(
		    Start_Date__c = DateTime.newInstance(2015, 5, 30, 0, 0, 0),
		    rank__c = 1,
		    Group_By_Customer_Hierarchy__c = 'Bill To',
		    Group_By_Sales_Orders__c = true,
		    Company__c = company.Id
		);

		insert igr;
		igr = [select id, is_Valid__c from Invoice_Grouping_Rule__c where id = :igr.Id limit 1];
		system.assertEquals(true, igr.is_Valid__c);
	}

	/*
		How to calculate Number of Allowance Types created
			> If only all false values, 5 allowances created where 5 is the number of basis.
			> By default, each attribute should have 1 attribute. Usually false.
			> If an attibute has 2 values, then 10 allowances will be created
			> If 2 attibutes have 2 values, then 20 allowances will be created
			> If Override and manual have 2 values, then 10 will be created.
			> From this we can say that the formula is: 5(2^r)+( [2^r] 5/2)*(Over). Where 5 are the basis, and r is the number of non-override attributes. If overrde is false, Over will be 0. The fomula could be expanded to be more logical, but this is simple enough.
			> Specials-
						If only man override:         	2^1 * 5/2 = 5.
			        	If only auto/man override:    	5(2^1) + (2^1)5/2 = 10 + 5 = 15
						Only Manual 					5(2^3) + (2^3)5/2 = 40 + 20 = 60
						Only Manual, Lines 				5(2^2) + (2^2)5/2 = 20 + 20 = 40
						Exclude Manuals, Discount 		5(2^2) + 0 = 20
			> CURRENT MAX POTENIAL = 5(2^4) + 5/2(2^4) = 5(16) + 5/2(16) = 80 + 40 = 120
	*/


	public class AllowanceTypeCreator {
		// Default Allowance Types to create for testing: Flat, Rate By and Percents that are CHARGES. Overridable For line and header.
		public Set<String> basises  = new Set<String> {AllowanceRuleService.BASIS_FLAT_AMOUNT, AllowanceRuleService.BASIS_RATE_BY, AllowanceRuleService.BASIS_TARGET_PERCENT};
		public Set<String> allowanceTypes = new Set<String> {AllowanceRuleService.TYPE_CHARGE};
		public Set<String> rateTypes = AllowanceRuleService.RATE_FIELDS;
		public Set<String> targetTypes = AllowanceRuleService.TARGET_FIELDS;

		public Set<Boolean> applyToHeader = new Set<Boolean>{TRUE,FALSE};
		public Set<Boolean> manual = new Set<Boolean>{FALSE};
		public Set<Boolean> oneTime = new Set<Boolean>{FALSE};
		public Set<Boolean> allowOverride = new Set<Boolean>{TRUE};

		public AllowanceTypeCreator(){}
	}

	public static List<Allowance_Type__c> createAllowanceTypes(AllowanceTypeCreator details ){
		return TestDataForAllowance.createAllowanceTypes(
			details.basises,
			details.allowanceTypes,
			details.rateTypes,
			details.targetTypes,
			details.applyToHeader,
			details.manual,
			details.oneTime,
			details.allowOverride,
			false
		);
	}

	public static List<Allowance_Type__c> createAllowanceTypes(
	    Set<String> basises, Set<String> allowanceTypes, Set<String> rateTypes, Set<String> targetTypes,
	    Set<Boolean> athBool, Set<Boolean> manBool, Set<Boolean> otBool, Set<Boolean> allowOverride,
	    Boolean manualOverridesOnly
	) {

		system.assert(basises.size() > 0);
		for (String basis : basises) {
			if (basis == AllowanceRuleService.BASIS_RATE_BY) {
				system.assert(rateTypes.size() > 0);
			}
			if (basis == AllowanceRuleService.BASIS_TARGET_PERCENT) {
				system.assert(targetTypes.size() > 0);
			}
		}
		// only 2 values. preferabily true or false.
		//system.assert(athBool.size() < 3 && manBool.size() < 3 && chrgBool.size() < 3 && otBool.size() < 3);

		List<Allowance_Type__c> ats = new List<Allowance_Type__c>();

		for (Boolean ath : athBool) {
			for (Boolean man : manBool) {
				for (String type : allowanceTypes) {
					for (Boolean ot : otBool) {
						for (Boolean ao : allowOverride) {
							for (String basis : basises ) {

								// can't have automatic allowances which allow overrides
								if (manualOverridesOnly && !man && ao) {
									continue;
								}

								if (basis == AllowanceRuleService.BASIS_FLAT_AMOUNT) {
									Allowance_Type__c at = constructAllowanceType(ath, man, type, ot, ao, basis);
									at.amount__c = 1.5;
									at.Percent_Of_Target_Field__c = null;
									at.name += '($ ' + at.amount__c + ')';
									ats.add(at);
									//system.debug(logginglevel.error, at);
								} else if (basis == AllowanceRuleService.BASIS_RATE_BY) {
									for (String rt : rateTypes) {
										Allowance_Type__c at = constructAllowanceType(ath, man, type, ot, ao, basis);
										at.Rate_field__c = rt;
										at.amount__c = .035;
										at.Percent_Of_Target_Field__c = null;
										at.name += '(' + rt + ' - ' + at.amount__c + '%)';
										ats.add(at);
										//system.debug(logginglevel.error, at);
									}
								} else if (basis == AllowanceRuleService.BASIS_TARGET_PERCENT) {
									for (String tt : targetTypes) {
										Allowance_Type__c at = constructAllowanceType(ath, man, type, ot, ao, basis);
										at.Target_Field__c = tt;
										at.Percent_Of_Target_Field__c = .045;
										at.amount__c = null;
										at.name += '(' + tt + ' - ' + at.Percent_Of_Target_Field__c + '%)';
										ats.add(at);
										//system.debug(logginglevel.error, at);
									}
								}
							}
						}
					}
				}
			}
		}

		//insert ats;
		return ats;
	}

	public static Allowance_Type__c constructAllowanceType(
	    Boolean ath,
	    Boolean man,
	    String type,
	    Boolean ot,
	    Boolean ao,
	    String basis) {

		Allowance_Type__c at = new Allowance_type__c(
		    Basis__c = basis,
		    name = '',
		    Manual__c = man,
		    Allow_Override__c = ao,
		    Apply_At_Header__c = ath,
		    Type__c = type,
		    One_Time__c = ot
		);

		at.name += man ? 'Manual' : 'Auto';
		at.name += ao ? '-Override-' : '-';
		at.name += ath ? ' Header-' : ' Line-';
		at.name += ' ' + type + '-'; //charge ? ' Charge-' : ' Allowance-';
		at.name += ot ? ' -One-Time- ' : '';

		return at;
	}

	public static List<Allowance_Rule__c> createRepriceRules(List<Allowance_Type__c> ats, Id customerId) {
		// Add all rules for the first 10 days
		List<Allowance_Rule__c> arList = new List<Allowance_Rule__c>();
		for (Allowance_Type__c at : ats) {


			if (at.Type__c == AllowanceRuleService.TYPE_ACCRUAL) {
				//for (String accrualOpt : AllowanceRuleService.ACRRUAL_RULES_OPTIONS) {
				String accrualOpt = AllowanceRuleService.ACCRUE_CUSTOMER;
					Allowance_Rule__c ar = new Allowance_Rule__c();
					ar.Allowance_Type__c = at.id;
					ar.Start_Date__c = system.today();
					ar.End_date__c = system.today() + 6;
					ar.Customer2__c = customerId;
					ar.Name = '1-' + at.Name;
					ar.Accrue_To__c = accrualOpt;
					arList.add(ar);
				//}
			} else {
				Allowance_Rule__c ar = new Allowance_Rule__c();
				ar.Allowance_Type__c = at.id;
				ar.Start_Date__c = system.today();
				ar.End_date__c = system.today() + 6;
				ar.Customer2__c = customerId;
				ar.Name = '1-' + at.Name;
				arList.add(ar);
			}
		}

		// Only charges from 11-20 days from today
		// Only discounts from 21-30 days from today
		for (Allowance_Type__c at : ats) {
			if (at.Type__c == 'Charge') {
				Allowance_Rule__c ar = new Allowance_Rule__c();
				ar.Allowance_Type__c = at.id;
				ar.Start_Date__c = system.today() + 7;
				ar.End_date__c = system.today() + 13;
				ar.Customer2__c = customerId;
				ar.Name = '2-' + at.Name;
				arList.add(ar);
			} else if (at.Type__c == 'Discount') {
				Allowance_Rule__c ar = new Allowance_Rule__c();
				ar.Allowance_Type__c = at.id;
				ar.Start_Date__c = system.today() + 14;
				ar.End_date__c = system.today() + 20;
				ar.Customer2__c = customerId;
				ar.Name = '3-' + at.Name;
				arList.add(ar);
			}
		}
		return arList;
	}

	public static void applyManualAllowances(Id soId) {
		applyManualAllowances(soId, true);
	}

	public static void applyManualAllowances(Id soId, Boolean applyOneTime) {
		Map<id, Sales_Order_Line__c> solines = AllowancesAppliedNewExt.getAllLines(soId);
		Sales_Order__c sorder = solines.values()[0].Sales_order__r;
		Set<Id> recordIds = new Set<Id> {sorder.id};

		List<Allowance_Applied__c> aaList = new List<Allowance_Applied__c>();
		for (Sales_Order_Line__c sol : solines.values()) {
			recordIds.add(sol.id);
		}

		for (Id recordId : recordIds) {
			// will return Rules for LINE or HEADER depending on Id object type
			for (Allowance_Rule__c rule : AllowanceService.loadManualRules( recordId )) { // 2 queris
				if (!rule.Allowance_Type__r.Manual__c) continue;

				if (!rule.Allowance_Type__r.One_Time__c || applyOneTime) {
					// already vetted during rules retreval when passing Id
					Sales_Order_Line__c soLine = (!rule.Allowance_Type__r.Apply_At_Header__c) ? solines.get(recordId) : null;

					Allowance_Applied__c aa = new AllowanceCalcService.AllowanceCreation(
					    new AllowanceRuleService.RuleContext(
					        rule,
					        soLines.values(),
					        .05
					    )
					).getAllowanceRecord();

					Sales_Order_Line__c sol = ( aa.Sales_Order_Line__c != null ) ? aa.Sales_Order_Line__r : null;
					Sales_Order__c so = ( aa.Sales_Order__c != null ) ? aa.Sales_Order__r : aa.Sales_Order_Line__r.Sales_Order__r;

					Date docDate = so.Price_Determination_Date__c == SalesOrderService.PRICE_DET_ORDER && sol != null ? sol.Ordered_Date_Time__c.date() : so.Pricing_Date__c;
					System.debug( logginglevel.error, '~*~ pricingDate :' + docDate );

					if (aa.Allowance_Rule2__r.Start_Date__c <= docDate && docDate <= aa.Allowance_Rule2__r.End_Date__c) {
						aaList.add( aa );
					}
				}
			}
		}

		system.debug(loggingLevel.Error, 'Manual aaList for upsert ' + aaList.size());

		insert aaList;

	}
}