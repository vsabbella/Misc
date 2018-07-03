trigger AllowanceRule on Allowance_Rule__c (before insert, after insert, before update, before delete) {

    if(DML.checkTriggerDispatch(Allowance_Rule__c.getSobjectType())){return;}

    if (trigger.isBefore) {

		Set<Id> ruleId = new Set<Id>();
		Set<Id> newPriceRule = new Set<Id>();
		if ( Trigger.isDelete ) {
			for ( Allowance_Rule__c ar : Trigger.old ) {
				ruleId.add( ar.Id );
			}
		}

		Set<Id> allowanceTypeIds = new Set<Id>();
		Map<Id, Allowance_Type__c> relatedAllowanceTypes = new Map<Id, Allowance_Type__c>();
		if ( Trigger.isUpdate || Trigger.isInsert) {
			for (Allowance_Rule__c ar : Trigger.new) {
				allowanceTypeIds.add( ar.Allowance_Type__c );
			}
		}

		if (!allowanceTypeIds.isEmpty()) {
			SOQLUtil soql = new SOQLUtil( 'Allowance_Type__c', true ); //enforceFLS=true, running in user mode
			soql.addFields( AllowanceRuleService.allowanceTypeFields );
			soql.setWhereClause( 'Id IN :allowanceTypeIds' );

			relatedAllowanceTypes = new Map<Id, Allowance_Type__c>( ( List<Allowance_Type__c> ) Database.query( soql.getQuery() ) );
		}

		if ( Trigger.isUpdate ) {
			// collect list of all end dating
			set<String> allowanceRuleCustomFields = new SchemaUtil().getAllPackagedFieldsFromSObject( null, 'Allowance_Rule__c' );
			for ( Allowance_Rule__c ar : Trigger.new ) {
				String type = relatedAllowanceTypes.get(ar.Allowance_Type__c).Type__c;
				// if we're only changing the End Date, allow the update, else block it (block includs updating End Date + other field)
				if ( KSE.isFieldChanging( 'End_Date__c', ar, trigger.oldMap ) ) {
					Allowance_Rule__c oldAr = trigger.oldMap.get( ar.Id );

					//for (String field : allowanceRuleMapFields.keySet()){
					for ( String field : allowanceRuleCustomFields ) {
						if ( field.toLowerCase() != ( 'end_date__c' ) && oldAr.get( field ) != ar.get( field ) ) {
							if (type == AllowanceRuleService.TYPE_NEW_PRICE) {
								newPriceRule.add( ar.Id);
							} else {
								ruleId.add( ar.Id );
							}
							break;
						}
					}
				}
				else {
					if (type == AllowanceRuleService.TYPE_NEW_PRICE) {
						newPriceRule.add( ar.Id);
					} else {
						ruleId.add( ar.Id );
					}
				}

			}
		}

		Set<Id> hasSOLrecords = new Set<Id>();
		Set<Id> hasAARecords = new Set<Id>();
		if ( !ruleId.isEmpty() ) {
			// get rules that don't have any AA
			for ( Allowance_Applied__c aa : [select id, Allowance_Rule2__c from Allowance_Applied__c where Allowance_Rule2__c IN :ruleId] ) {
				hasAARecords.add( aa.Allowance_Rule2__c );
			}
		}

		if (!newPriceRule.isEmpty()){
			for (Sales_Order_Line__c sol : [select id, New_Pricing_Rule__c from Sales_Order_Line__c where New_Pricing_Rule__c IN :newPriceRule]){
				hasSOLrecords.add(sol.New_Pricing_Rule__c);
			}
		}

		if (!hasAARecords.isEmpty() || !hasSOLrecords.isEmpty() ) {
			if ( Trigger.isDelete ) {
				for ( Allowance_Rule__c ar : Trigger.old ) {
					if ( hasAARecords.contains( ar.Id ) || hasSOLrecords.contains(ar.Id) ) {
						ar.addError( Label.Cannot_Delete_Allowance_Rule_With_Existing_Allowance_Applied_Record );
					}
				}
			}
			else if ( Trigger.isUpdate ) {
				for ( Allowance_Rule__c ar : Trigger.new ) {
					if ( hasAARecords.contains( ar.Id ) || hasSOLrecords.contains(ar.Id) ) {
						ar.addError( Label.Cannot_Delete_Allowance_Rule_With_Existing_Allowance_Applied_Record );
					}
				}
			}
		}

        // tracking for unique rules based on type, customer, customer group, product, product hierarhcy,
        if (Trigger.isInsert || (Trigger.isUpdate)) {

			Set<Id> customerIds = new Set<Id>{ Null };
			Set<Id> customerGroupIds = new Set<Id>{ Null };
			Set<Id> productIds = new Set<Id>{ Null };
			Set<Id> productGroupIds = new Set<Id>{ Null };
			Set<Id> productHierIds = new Set<Id>{ Null };
			Set<Id> benefis = new Set<Id>{ Null };
			Set<Id> existingIds = new Set<Id>();

			Map<String, Allowance_Rule__c[]> arMap = new Map<String, Allowance_Rule__c[]>();
			Date minDate;
			Date maxDate;
			Set<Id> existing = new Set<Id>();
			for ( Allowance_Rule__c ar : Trigger.new ) {

				if ( KSE.isFieldChanging( 'Allowance_Type__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'Customer2__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'Customer_Group__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'Product__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'Product_Group__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'Product_Hierarchy__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'Beneficiary__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'Start_Date__c', ar, trigger.oldMap ) ||
						KSE.isFieldChanging( 'End_Date__c', ar, trigger.oldMap )
						) {

					if ( minDate == null || minDate > ar.Start_Date__c ) {
						mindate = ar.Start_Date__c;
					}
					if ( maxDate == null || maxDate < ar.End_Date__c ) {
						maxDate = ar.End_Date__c;
					}

					customerIds.add( ar.Customer2__c );
					customerGroupIds.add( ar.Customer_Group__c );
					productIds.add( ar.Product__c );
					productGroupIds.add( ar.Product_Group__c );
					productHierIds.add( ar.Product_Hierarchy__c );
					benefis.add( ar.Beneficiary__c );
				}

				if ( ar.id != null ) {
					existingIds.add( ar.id );
				}
			}

			if ( !allowanceTypeIds.isEmpty() ) {

				//						+ ' AND Customer2__c IN :customerIds '
				//						+ ' AND Customer_Group__c IN :customerGroupIds '
				//						+ ' AND Product__c IN :productIds '
				//						+ ' AND Product_Group__c IN :productGroupIds '
				//						+ ' AND Product_Hierarchy__c IN :productHierIds '
				//						+ ' AND ( (Start_Date__c >= :minDate AND Start_Date__c <= :maxDate) OR '
				//						+ ' (End_Date__c >= :minDate AND End_Date__c <= :maxDate) OR '
				//						+ ' (Start_Date__c <= :minDate AND End_Date__c >= :maxDate) )'
				//				);



				//				Map<String, Allowance_Rule__c> existingMap = new Map<String, Allowance_Rule__c>();
				//				for (Allowance_Rule__c ar : existingAR){
				//					if (!existingMap.containsKey(ar.Allowance_Rule_Unique_Key__c)) {
				//						existingMap.add( ar.Allowance_Rule_Unique_Key__c, ar );
				//					} else {
				//						System.debug( logginglevel.error, '~*~ ERROR - duplicate' + ar );
				//						ar.addError('Existing Allowance');
				//					}
				//				}

				Set<String> ruleKeys = new Set<String>();
				Map<String, List<Allowance_Rule__c>> ruleKeyMap = new Map<String, List<Allowance_Rule__c>>();

				// comparing existing ARs with new/updated values Trigger (inserted and updated) and Database (excluding updated records)
				for ( Allowance_Rule__c ar : Trigger.new ) {
					String ruleType = relatedAllowanceTypes.get( ar.Allowance_Type__c ).Type__c;

					String keySerp = '-';

					String ruleKey = '';

					Set<String> accrualFields = new Set<String>{ 'Accure_To__c', 'Beneficiary__c' };
					if ( ruleType != AllowanceRuleService.TYPE_ACCRUAL ) {

						SchemaUtil.getInstance().getFieldsMap( 'Allowance_Rule__c' );
					}

					if ( ruleType == AllowanceRuleService.TYPE_NEW_PRICE ) {
						ruleKey = ar.Customer2__c + keySerp + ar.Customer_Group__c + keySerp + ar.Product__c + keySerp + ar.Product_Group__c + keySerp + ar.Product_Hierarchy__c + keySerp + ar.Pricebook__c;
					}
					else if ( ruleType == AllowanceRuleService.TYPE_ACCRUAL ) {
						ruleKey = ar.Allowance_Type__c + ar.Sales_Order_Type__c + keySerp + ar.Beneficiary__c + keySerp + ar.Accrue_To__c;
					}
					else {
						ruleKey = ar.Allowance_Type__c + keySerp + ar.Customer2__c + keySerp + ar.Customer_Group__c + keySerp + ar.Product__c + keySerp + ar.Product_Group__c + keySerp + ar.Product_Hierarchy__c + keySerp + ar.Pricebook__c;
					}

					if ( !ruleKeyMap.containskey( ruleKey ) ) {
						ar.Allowance_Rule_Unique_Key__c = ruleKey;
						ruleKeys.add( ruleKey );

						ruleKeyMap.put( ruleKey, new List<Allowance_Rule__c>() );
					}
					else {
						// check for duplicates in inser/update List
						for ( Allowance_Rule__c existingAR : ruleKeyMap.get( ruleKey ) ) {

							//							if ( ar == existingAR || ar.id == existingAR.id ) {
							//								continue;
							//							}

							if ( ( existingAR.End_Date__c < ar.Start_Date__c ) || ( existingAR.Start_Date__c > ar.End_Date__c ) ) {
								ruleKeyMap.get( ruleKey ).add( ar );
								continue;
							}
							else {

								if ( existingAR.Id != null ) {
									String link = ' <a href=\'' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + ar.id + '\'>' + ar.name + ' </a>';
									ar.addError( 'Overlapping rule exists' + link, false );
								}
								else {
									ar.addError ( 'Overlapping allowance rule exists' );
								}

								break;
							}
						}
					}
				}

				SOQLUtil arSoql = new SOQLUtil( 'Allowance_Rule__c', true );
				arSoql.addFields( AllowanceRuleService.allowanceRuleFields );

				//ba-todo: NEED to add time in this where clause query
				arSoql.setWhereClause( 'Allowance_Rule_Unique_Key__c IN :ruleKeys' );

				for ( Allowance_Rule__c existingAR : Database.query( arSoql.getQuery() ) ) {
					if ( !ruleKeyMap.containsKey( existingAR.Allowance_Rule_Unique_Key__c ) ) {
						ruleKeyMap.put( existingAR.Allowance_Rule_Unique_Key__c, new List<Allowance_Rule__c>() );
					}
					ruleKeyMap.get( existingAR.Allowance_Rule_Unique_Key__c ).add( existingAR );
				}

				//				for ( Allowance_Rule__c ar : Trigger.new ) {
				//					//check for duplicates in existing List
				//					if ( ruleKeyMap.containsKey( ar.Allowance_Rule_Unique_Key__c ) ) {
				//
				//						for ( Allowance_Rule__c arFromMap : arMap.get( ar.Allowance_Type__c ) ) {
				//							if ( ar != arFromMap || ar.id != arFromMap.id ) {
				//								continue;
				//							}
				//
				//							if ( ( arFromMap.End_Date__c < ar.Start_Date__c ) || ( arFromMap.Start_Date__c > ar.End_Date__c ) ) {
				//								continue;
				//							}
				//							else {
				//								String link = ' <a href=\'' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + ar.id + '\'>' + ar.name + ' </a>';
				//								ar.addError( 'Overlapping rule exists' + link, false );
				//								break;
				//							}
				//						}
				//					}
				//
				//					if ( ruleKeyMap.containsKey( ar.Allowance_Rule_Unique_Key__c ) ) {
				//						for ( Allowance_Rule__c existingAR : ruleKeyMap.get( ar.Allowance_Rule_Unique_Key__c ) ) {
				//
				//							if ( ar == existingAR || ar.id == existingAR.id ) {
				//								continue;
				//							}
				//
				//							if ( ( existingAR.End_Date__c < ar.Start_Date__c ) || ( existingAR.Start_Date__c > ar.End_Date__c ) ) {
				//								continue;
				//							}
				//							else {
				//
				//								if ( existingAR.Id != null ) {
				//									String link = ' <a href=\'' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + ar.id + '\'>' + ar.name + ' </a>';
				//									ar.addError( 'Overlapping rule exists' + link, false );
				//								}
				//								else {
				//									ar.addError ( 'Overlapping allowance rule exists' );
				//								}
				//
				//								break;
				//							}
				//						}
				//					}

			}
		}

	}
}