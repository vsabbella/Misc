public with sharing class AllowanceCalcService {

	public class AllowanceCalcServiceException extends Exception {}

	public static Allowance_Applied__c initAllowanceRecord( AllowanceRuleService.RuleContext ctx ) {

		Allowance_Applied__c allwAppd = new Allowance_Applied__c();

		Allowance_Type__c allowanceType = ctx.allowanceRule.Allowance_Type__r;
		Boolean header = allowanceType.Apply_At_Header__c;

		Boolean isInvoiced = ctx.header.getSobjectType() == Customer_Invoice__c.getSobjectType();
		Decimal allowanceTypeAmount = allowanceType.Amount__c;

		allwAppd.Allowance_Code__c = ctx.allowanceRule.Allowance_Code__c;

		/* Set related fields for Alowance Applied Record for Unique Key generation */
		if (isInvoiced) {
			if (header) {
				allwAppd.Customer_Invoice2__c = (Id) ctx.header.get('Id'); 
				allwAppd.Customer_Invoice2__r = (Customer_Invoice__c) ctx.header;
			} else {
				allwAppd.Customer_Invoice_Line__c = (Id) ctx.lines[0].get('Id');
				allwAppd.Customer_Invoice_Line__r = (Customer_Invoice_Line__c) ctx.lines[0];
			}
		} else {
			if (header) {
				allwAppd.Sales_Order__c = (Id) ctx.header.get('Id'); 
				allwAppd.Sales_Order__r = (Sales_Order__c) ctx.header;
			} else {
				allwAppd.Sales_Order_Line__c = (Id) ctx.lines[0].get('Id'); 
				allwAppd.Sales_Order_Line__r = (Sales_Order_Line__c) ctx.lines[0];
			}
		}

		allwAppd.Allowance_Rule2__c = ctx.allowanceRule.id;
		allwAppd.Allowance_Rule2__r = ctx.allowanceRule;

		allwAppd.Allowance_Type__c = allowanceType.id;
		allwAppd.Allowance_Type__r = allowanceType;

		allwAppd.Allowance_Class__c = allowanceType.Allowance_Class__c;
		allwAppd.Source__c = 'Other';

		// generate keys for automatics or One time. Manuals that aren't onetime don't do not require a key
		allwAppd.Unique_Key__c = AllowanceRuleService.genUniqueKey(ctx.fulfillments, allwAppd, allowanceType );

		return allwAppd;
	}

	public static Allowance_Applied__c calculateAllowanceAmount (AllowanceRuleService.RuleContext ctx, Allowance_Applied__c allwAppd) {


		// For autos, update on existing allowances if available.
		if (ctx.existingAA != null ) {
			allwAppd = ctx.existingAA.clone(true, true);
		}

		// for automatic allowances only. Use the exisiting override value for allowance amount calculation.
		// preserve allowance override value (for Automatic allowances) or clear override value depending on the Allowance Type.
		// BA-todo: this is weird. Fix it.
		if (ctx.allowanceType.Allow_Override__c){
			// check record first.
			if (allwAppd.Override_Value__c != null) {
				ctx.overrideValue = allwAppd.Override_Value__c;
			} else if (ctx.overrideValue != null) {
				allwAppd.Override_Value__c =  ctx.overrideValue;
			}
		}

		Decimal allowanceAmount = new AllowanceCalcService.AllowanceCalculate( ctx ).calculateAllowanceAmount();

		if (ctx.allowanceType.Type__c == AllowanceRuleService.TYPE_ACCRUAL) {
			allwAppd.BillBack_Commitment__c = allowanceAmount;
			allwAppd.Allowance_Amount__c = null;

			// if generic Accrue to all, determine the customer / End customer using SOLINE info. Else, if none, use beneficiary info
			if (ctx.allowanceRule.Accrue_To__c != null && ctx.allowanceRule.Beneficiary__c == null) {
				if (ctx.allowanceRule.Accrue_To__c == AllowanceRuleService.ACCRUE_CUSTOMER) {
					allwAppd.Beneficiary__c = (Id) ctx.header.get('Bill_To__c');
					allwAppd.Beneficiary__r = (Customer__c) ctx.header.getSObject('Bill_To__r');
				} else if (ctx.allowanceRule.Accrue_To__c == AllowanceRuleService.ACCRUE_END_CUSTOMER) {
					if (ctx.lines[0].get('End_Customer__c') != null) {
						allwAppd.Beneficiary__c = (Id) ctx.lines[0].get('End_Customer__c');
						allwAppd.Beneficiary__r = (Customer__c) ctx.lines[0].getSobject('End_Customer__r');
					}
				}
			} else if (ctx.allowanceRule.Beneficiary__c != null ) {
				allwAppd.Beneficiary__c = ctx.allowanceRule.Beneficiary__c;
				allwAppd.Beneficiary__r = ctx.allowanceRule.Beneficiary__r;
			}
		} else {
			allwAppd.Allowance_Amount__c = allowanceAmount;
			allwAppd.BillBack_Commitment__c = null;
			allwAppd.Beneficiary__c = null;
		}

		System.debug(loggingLevel.Error, '*** final allwAppd: ' + allwAppd);
		return allwAppd;
	}

	public static Integer intPrecision {
		get {
			if (intPrecision == null) {
				intPrecision = PriceBookService.getRoundingPrecision();
			}
			return intPrecision;
		}
		set;
	}


	public class AllowanceCreation {

		private AllowanceRuleService.RuleContext ctx;
		private Allowance_Applied__c allwAppd;
		private Allowance_Applied__c existingAA;

		public AllowanceCreation (AllowanceRuleService.RuleContext ctx) {
			this.ctx = ctx;
			this.allwAppd = initAllowanceRecord(ctx);
			this.allwAppd = calculateAllowanceAmount(ctx, this.allwAppd);
		}

		public Allowance_Applied__c getAllowanceRecord() {
			return allwAppd;
		}
	}

	public class AllowanceCalculate {

		private Allowance_Type__c allowanceType = null;
		private SObject[] lines = null;
		private Decimal overrideValue = null;
		private Map<Id, Decimal> qtyMap = new Map<Id, Decimal>();
		private Boolean reverseOrder;

		public AllowanceCalculate( AllowanceRuleService.RuleContext ctx) {

			this.allowanceType = ctx.allowanceType;
			
			this.overrideValue = (ctx.overrideValue != null && this.allowanceType.Allow_Override__c) ? Math.abs(ctx.overrideValue) : null;
			
			this.reverseOrder = ctx.reverseAmount;

			this.lines = ctx.lines;

			if (ctx.preferredQtyMap != null ){
				this.qtyMap = ctx.preferredQtyMap;
			}
		}

		public Decimal calculateAllowanceAmount() {

			Decimal allowanceTypeAmount = 0;

			if (overrideValue != null && allowanceType.Allow_Override__c) {
				allowanceTypeAmount = overrideValue;

			} else {
				if ( allowanceType.Percent_Of_Target_Field__c != null ) {

					allowanceTypeAmount = Math.abs( allowanceType.Percent_Of_Target_Field__c );

				}
				else if ( allowanceType.Amount__c != null ) {

					allowanceTypeAmount = Math.abs( allowanceType.Amount__c );

				}
				else if ( allowanceType.Value__c != null ){

					allowanceTypeAmount = Math.abs( allowanceType.Value__c );

				} else {
					String link = ' <a href=\'' + AllowanceRuleService.SFDCBaseURL + '/' + allowanceType.Id + '\'>' + allowanceType.name + ' </a>';
					throw new AllowanceCalcServiceException('Allowance Type is missing Percent. ' + link );
				}
			}

			Decimal allowanceAmount = 0;
			
			// create map where Allowance Basis determines the calculation Method to use
			if (allowanceType.Basis__c == AllowanceRuleService.BASIS_FLAT_AMOUNT && allowanceType.Type__c != AllowanceRuleService.TYPE_NEW_PRICE){
				allowanceAmount = allowanceTypeAmount;
			} 
			else if (allowanceType.Type__c == AllowanceRuleService.TYPE_NEW_PRICE && AllowanceRuleService.newPriceBasis.contains(allowanceType.Basis__c)){
				Sales_Order_Line__c soLine = (Sales_Order_Line__c) lines[0];
				
				if (allowanceType.Basis__c == AllowanceRuleService.BASIS_FLAT_AMOUNT){
					allowanceAmount = allowanceType.Amount__c;
				} 
				else if (allowanceType.Basis__c == AllowanceRuleService.BASIS_MARKDOWN){
					allowanceAmount = (1 - (allowanceType.Percent_Of_Target_Field__c / 100)) * soLine.List_Price__c;
				} 
				else if (allowanceType.Basis__c == AllowanceRuleService.BASIS_MARKUP){
					allowanceAmount = (1 + (allowanceType.Percent_Of_Target_Field__c / 100)) * soLine.List_Price__c;
				} 
				else if (allowanceType.Basis__c == AllowanceRuleService.BASIS_MULTIPLIER ){
					allowanceAmount = allowanceTypeAmount * soLine.List_Price__c;
				}
			} 
			else {
				String stratagyKey = '';
				if (allowanceType.Basis__c == AllowanceRuleService.BASIS_RATE_BY) {
					stratagyKey = allowanceType.Rate_Field__c;
				} 
				else if (allowanceType.Basis__c == AllowanceRuleService.BASIS_TARGET_PERCENT) {
					stratagyKey = allowanceType.Target_field__c;
				}
				
				if (calculationStrategy.containsKey(stratagyKey)){
					allowanceAmount = calculationStrategy.get(stratagyKey).getAmount(lines, qtyMap, allowanceTypeAmount);
				} else {
					throw new AllowanceCalcServiceException('Unknown allowance type with field: ' + stratagyKey);
				}
			}

			return finalAmount(allowanceAmount);
		}

		private Decimal finalAmount(Decimal allowanceAmount) {
			// if charge, allowance amt is positive, else negative (standard allowance)
			allowanceAmount = AllowanceRuleService.positiveAllowanceTypes.contains(allowanceType.Type__c) ? Math.abs(allowanceAmount) : -Math.abs(allowanceAmount);

			allowanceAmount = allowanceAmount.setScale(intPrecision, RoundingMode.HALF_UP);

			if (reverseOrder) {
				allowanceAmount = allowanceAmount * -1; // reverse the sign
			}

			System.debug(loggingLevel.Error, '*** post-finalAmount allowanceAmount: ' + allowanceAmount);
			return allowanceAmount;
		}
	}

	private interface AllowanceCalculateService {
		Decimal getAmount(List<SObject> allLines, Map<Id, Decimal> quantityMap, Decimal typeAmount);
	}

	private class CalculateNet implements AllowanceCalculateService {
		public Decimal getAmount(List<SObject> allLines, Map<Id, Decimal> quantityMap, Decimal typeAmount) {
			System.debug(loggingLevel.Error, '*** CalculateNet');

			Decimal totalExtendedPrice = 0;

			for (SObject line : allLines) {
				PricingService.RateBasis rb = PricingService.getRateBasis( (String) line.get('Rate_Basis__c'));
				Decimal qtyMult = rb == PricingService.RateBasis.FLAT ? 1 : (Decimal) quantityMap.get(line.Id);
				
				totalExtendedPrice += PricingService.returnPrice(
					qtyMult, 
					(Decimal) line.get('Unit_Price__c'), 
					(Decimal) line.get('Off_Invoice_Rate__c'), 
					0, 0, 
					(Decimal) line.get('Discount_Percent__c')
				);
			}

			return (totalExtendedPrice * typeAmount / 100 );
		}
	}

	private class CalculateGross implements AllowanceCalculateService {
		public Decimal getAmount(List<SObject> allLines, Map<Id, Decimal> quantityMap, Decimal typeAmount) {
			System.debug(loggingLevel.Error, '*** CalculateGross');

			Decimal totalGrossAmount = 0;

			for (SObject line : allLines) {
				totalGrossAmount += KSE.addQuantityToField( (Decimal) line.get('Unit_Price__c'), 0) * quantityMap.get(line.id);
			}

			return (totalGrossAmount * typeAmount / 100 );
		}
	}

	private class CalculateWeight implements AllowanceCalculateService {
		public Decimal getAmount(List<SObject> allLines, Map<Id, Decimal> quantityMap, Decimal multiplier) {
			System.debug(loggingLevel.Error, '*** CalculateWeight');
			Decimal allowanceAmount = 0;

			// Calc header weight using Quantity Shipped
			for (SObject line : allLines) {
				Sales_Order_Line__c soLine;

				if ( line.getsobjectType() == Sales_Order_line__c.getsobjectType() ) {
					soLine = (Sales_Order_Line__c) line;
				} else if ( line.getsobjectType() == Customer_Invoice_Line__c.getsobjectType() ) {
					System.debug(loggingLevel.Error, '*** line: ' + line);
					soLine = (Sales_Order_Line__c) line.getSObject('Sales_Order_Line__r');
				}

				Decimal productWght = soLine.Product_Weight__c / soLine.Quantity_Ordered__c;

				allowanceAmount += multiplier * productWght *  quantityMap.get( (Id) line.get('id'));
			}
			return allowanceAmount;
		}
	}

	private class CalculateQuantity implements AllowanceCalculateService {
		public Decimal getAmount(List<SObject> allLines, Map<Id, Decimal> quantityMap, Decimal multiplier) {
			System.debug(loggingLevel.Error, '*** CalculateQuantity');
			Decimal allowanceAmount = 0;

			for (SObject line : allLines) {
				allowanceAmount += quantityMap.get( (Id) line.get('Id') ) * multiplier;
			}

			return allowanceAmount;
		}
	}

	public static Map <String, AllowanceCalculateService> calculationStrategy = new Map <String, AllowanceCalculateService> {
		AllowanceRuleService.TARGET_FIELD_NET => (AllowanceCalculateService) new CalculateNet(),
		AllowanceRuleService.TARGET_FIELD_GROSS => (AllowanceCalculateService) new CalculateGross(),
		AllowanceRuleService.RATE_FIELD_WEIGHT => (AllowanceCalculateService) new CalculateWeight(),
		AllowanceRuleService.RATE_FIELD_QUANTITY => (AllowanceCalculateService) new CalculateQuantity()
	};

		//	AllowanceRuleService.BASIS_MARKUP => (AllowanceCalculateService) new CalculateMarkup()
		//AllowanceRuleService.BASIS_MARKDOWN => (AllowanceCalculateService) new CalculateMarkdown()
		//AllowanceRuleService.BASIS_MULTIPLIER => (AllowanceCalculateService) new CalculateMultiplier()
}