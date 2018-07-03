trigger AllowanceType on Allowance_Type__c (before delete, before update) {

	if ( DML.checkTriggerDispatch( Allowance_Type__c.getSobjectType() ) ) {
		return;
	}

	if ( trigger.isBefore ) {
		Set<Id> typeId = new Set<Id>();
		Set<Id> newPriceRule = new Set<Id>();

		if ( Trigger.isDelete ) {
			for ( Allowance_Type__c at : Trigger.old ) {
				if ( at.Type__c == AllowanceRuleService.TYPE_NEW_PRICE ) {
					newPriceRule.add( at.Id );
				}
				else {
					typeId.add( at.Id );
				}
			}
		}

		if ( Trigger.isUpdate ) {
			for ( Allowance_Type__c at : Trigger.new ) {
				if ( at.Type__c == AllowanceRuleService.TYPE_NEW_PRICE ) {
					newPriceRule.add( at.Id );
				}
				else {
					typeId.add( at.Id );
				}
			}
		}

		Set<Id> hasAARecords = new Set<Id>();
		Set<Id> hasSOLrecords = new Set<Id>();

		// get rules that don't have any AA
		if ( !typeId.isEmpty() ) {
			for ( Allowance_Applied__c aa : [select id, Allowance_Type__c from Allowance_Applied__c where Allowance_Type__c IN :typeId] ) {
				hasAARecords.add( aa.Allowance_Type__c );
			}
		}

		if ( !newPriceRule.isEmpty() ) {
			for ( Sales_Order_Line__c sol : [select id, New_Pricing_Rule__c from Sales_Order_Line__c where New_Pricing_Rule__c IN :newPriceRule] ) {
				hasSOLrecords.add( sol.New_Pricing_Rule__c );
			}
		}

		if ( !hasAARecords.isEmpty() || !hasSOLrecords.isEmpty() ) {
			if ( Trigger.isDelete ) {
				for ( Allowance_Type__c at : Trigger.old ) {
					if ( hasAARecords.contains( at.Id ) || hasSOLrecords.contains(at.Id) ) {
						at.addError( Label.Cannot_Delete_Allowance_Type_With_Existing_Allowance_Applied_Record );
					}
				}
			}
			else if ( Trigger.isUpdate ) {
				for ( Allowance_Type__c at : Trigger.new ) {
					if ( hasAARecords.contains( at.Id ) || hasSOLrecords.contains(at.Id) ) {
						at.addError( Label.Cannot_Delete_Allowance_Type_With_Existing_Allowance_Applied_Record );
					}
				}
			}
		}
	}
}