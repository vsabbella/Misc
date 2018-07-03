public with sharing class AllowanceTypeNewExt extends GridRelatedListController {

	//public Allowance_Type__c allowanceType { get; set; }
	public Id allowanceTypeId {get; set;}

	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	public static SchemaUtil util = SchemaUtil.getInstance();

	public Boolean isClone {get; set;}

	public class AllowanceTypeNewException extends Exception {}


	public AllowanceTypeNewExt (ApexPages.StandardController controller) {
		allowanceTypeId = controller.getRecord().id;
		//allowanceType = new Allowance_Type__c();
		isClone = apexPages.currentPage().getParameters().get('clone') == '1' ? true : false;
		System.debug(loggingLevel.Error, '*** PageParameters: ' + ApexPages.currentPage().getParameters());
		System.debug(loggingLevel.Error, '*** isClone: ' + isClone);
	}

	public String getHeaderFieldList() {
		List <FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Allowance_Type__c', 'New_Allowance');

		for (FieldInfo field : fieldInfoList) {
			field.editable = true;
			if (field.fieldType == 'currency') {
				field.fieldType = 'integer';
			}
		}

		return JSON.serialize(fieldInfoList);
	}

	@RemoteAction
	public static JsonResult getAllowanceType(Id atId, Boolean cloneRecord) {
		JsonResult  jsResult = new JsonResult();
		Allowance_Type__c allowanceType;
		try {
			// for EDIT
			if (atId != null && String.valueOf(atId).length() > 0) {
				SOQLUtil soql = new SOQLUtil('Allowance_Type__c', true); //enforceFLS=true, running in user mode
				soql.addFields(AllowanceRuleService.allowanceTypeFields);
				soql.addFields(new set<String>(SchemaUtil.getInstance().getFieldsFromFieldSetString(Allowance_Type__c.sObjectType, 'New_Allowance')));
				soql.setWhereClause('Id = :atId');

				allowanceType = (Allowance_Type__c) Database.query(soql.getQuery())[0];
			}
			// for NEW
			else {
				allowanceType = new Allowance_Type__c();
				allowanceType.Basis__c = AllowanceRuleService.BASIS_RATE_BY;
				allowanceType.Rate_Field__c = AllowanceRuleService.RATE_FIELD_QUANTITY;
				allowanceType.Type__c = AllowanceRuleService.TYPE_DISCOUNT;
				allowanceType.Allowance_Class__c = 'Standard';
			}

			// determines whether to clone or edit
			List<Allowance_Type__c> atList = new List<Allowance_Type__c> {allowanceType.clone(!cloneRecord, true)};
			return new JsonResult(atList, 1);

		} catch (Exception e) {

			System.debug(logginglevel.error, 'Exception: ' + e.getMessage() + ' - ' +  e.getStackTraceString());

			jsResult.success = false;
			jsResult.addMessage(e.getMessage(), ApexPages.Severity.ERROR );

		}

		return jsResult;
	}

	@RemoteAction
	public static JsonResult createNewAllowance(Allowance_Type__c at) {
		JsonResult  jsResult = new JsonResult();
		try {
			
			if (at.Type__c == AllowanceRuleService.TYPE_ACCRUAL){
				if (at.Basis__c == AllowanceRuleService.BASIS_FLAT_AMOUNT){
					throw new AllowanceTypeNewException ('Invalid Basis entered for Accrual Type Allowance. Only Percentage and Rate By are supported for Accrual Type Allowance.');
				}
				if (at.Apply_At_Header__c){
					throw new AllowanceTypeNewException('Invalid setting for Accrual Type Allowane. Apply at Header is not supported for Accruals.');
				}
			}

			if (at.Basis__c == AllowanceRuleService.BASIS_TARGET_PERCENT) {
				at.Amount__c = null;
				at.Rate_Field__c = null;

				if (!AllowanceRuleService.TARGET_FIELDS.contains(at.Target_Field__c)) {
					throw new AllowanceTypeNewException ('Invalid "Target Field" entered for selected basis.');
				}

				if (!at.Allow_Override__c && at.Percent_Of_Target_Field__c == null) {
					throw new AllowanceTypeNewException ('Invalid value in "% of Target Field" for selected basis.');
				} else if (at.Allow_Override__c && at.Percent_Of_Target_Field__c == null) {
					at.Percent_Of_Target_Field__c = 0;
				}
			} else if (at.Basis__c == AllowanceRuleService.BASIS_RATE_BY) {
				at.Target_Field__c = null;
				at.Percent_Of_Target_Field__c = null;

				if (!AllowanceRuleService.RATE_FIELDS.contains(at.Rate_Field__c)) {
					throw new AllowanceTypeNewException ('Invalid "Rate Field" entered for selected basis.');
				}

				if (!at.Allow_Override__c && at.Amount__c == null) {
					throw new AllowanceTypeNewException ('Invalid value in "Amount" for selected basis.');
				} else if (at.Allow_Override__c && at.Amount__c == null) {
					at.Amount__c = 0;
				}

			} else if (at.Basis__c == AllowanceRuleService.BASIS_FLAT_AMOUNT) {
				at.Target_Field__c = null;
				at.Percent_Of_Target_Field__c = null;
				at.Rate_Field__c = null;

				if (at.Amount__c == null && !at.Allow_Override__c) {
					throw new AllowanceTypeNewException ('Invalid value in "Amount" for selected basis.');
				} else if (at.Allow_Override__c && at.Amount__c == null) {
					at.Amount__c = 0;
				}
			}

			if (at.Type__c == AllowanceRuleService.TYPE_NEW_PRICE) {
				at.Rate_Field__c = null;
				at.Target_Field__c = null;

				at.Manual__c = false;
				at.One_Time__c = false;
				at.Allow_Override__c = false;
				at.Apply_At_Header__c = false;
				at.Allowance_Class__c = null;

				if (at.Basis__c == AllowanceRuleService.BASIS_MARKDOWN || at.Basis__c == AllowanceRuleService.BASIS_MARKUP){
					at.Value__c = null;
					at.Amount__c = null;
				} else if (at.Basis__c == AllowanceRuleService.BASIS_MULTIPLIER){
					at.Percent_Of_Target_Field__c = null;
					at.Amount__c = null;
				} else if (at.Basis__c == AllowanceRuleService.BASIS_FLAT_AMOUNT) {
					at.Percent_Of_Target_Field__c = null;
					at.Value__c = null;
				}
			}


			DML.checkUpsertAsUser(at); upsert at;

			jsResult.records = new List<Allowance_Type__c> {at};
			jsResult.total = 1;
		} catch (Exception e) {

			System.debug(logginglevel.error, 'Exception: ' + e.getMessage() + ' - ' +  e.getStackTraceString());

			jsResult.success = false;
			jsResult.addMessage(e.getMessage(), ApexPages.Severity.ERROR );

		}
		return jsResult;

	}
}