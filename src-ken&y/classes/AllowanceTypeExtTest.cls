@isTest
private class AllowanceTypeExtTest {

	static testMethod void cloneTest() {

		Allowance_Type__c at = new Allowance_Type__c();
		ApexPages.StandardController con = new ApexPages.StandardController(at);
		AllowanceTypeNewExt ext = new AllowanceTypeNewExt(con);
	}

	static Allowance_Type__c generateType(String basis, String field, Decimal amt) {
		Allowance_Type__c at = new Allowance_Type__c();
		at.Basis__c = basis;

		if (basis == AllowanceRuleService.BASIS_TARGET_PERCENT) {
			at.Target_Field__c = field;
			at.Percent_Of_Target_Field__c = amt;
		} else if (basis == AllowanceRuleService.BASIS_RATE_BY) {
			at.Rate_Field__c = field;
			at.Amount__c = amt;
		} else if (basis == AllowanceRuleService.BASIS_FLAT_AMOUNT) {
			at.Amount__c = amt;
		}

		return at;
	}

	static testMethod void createNewTest() {

		/* Test creating Flat Allowance */
		Allowance_Type__c flatAt = generateType(AllowanceRuleService.BASIS_FLAT_AMOUNT, null, 10);
		try {
			AllowanceTypeNewExt.createNewAllowance(flatAt);
		} catch (Exception e) {

		}

		/* Test creating Rate By Weight Allowance */
		Allowance_Type__c weightAt = generateType(AllowanceRuleService.BASIS_RATE_BY, AllowanceRuleService.RATE_FIELD_WEIGHT, .01);
		try {
			AllowanceTypeNewExt.createNewAllowance(weightAt);
		} catch (Exception e) {

		}

		/* Test creating Rate By Qty Allowance */
		Allowance_Type__c qtyAt = generateType(AllowanceRuleService.BASIS_RATE_BY, AllowanceRuleService.RATE_FIELD_QUANTITY, .01);
		try {
			AllowanceTypeNewExt.createNewAllowance(qtyAt);
		} catch (Exception e) {

		}

		/* Test creating Percent Net Allowance */
		Allowance_Type__c netAt = generateType(AllowanceRuleService.BASIS_TARGET_PERCENT, AllowanceRuleService.TARGET_FIELD_NET, .01);
		try {
			AllowanceTypeNewExt.createNewAllowance(netAt);
		} catch (Exception e) {

		}

		/* Test creating Percent Gross Allowance */
		Allowance_Type__c grossAt = generateType(AllowanceRuleService.BASIS_TARGET_PERCENT, AllowanceRuleService.TARGET_FIELD_GROSS, .01);
		try {
			AllowanceTypeNewExt.createNewAllowance(grossAt);
		} catch (Exception e) {

		}
	}

	static testMethod void editTest() {

	}

}