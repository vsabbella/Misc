public with sharing class FixedAssetService {
	//Constants
	public static final string TYPE_DEPRECIATION = 'Depreciation';
	public static final string TYPE_CIP = 'Capitalize';
	public static final string TYPE_RESIDUAL = 'Residual';
	public static final string TYPE_RETIRE = 'Retire';
	public static final string ASSET_TO_INVENTORY = 'Asset to Inventory';
	
	public static final string STATUS_INACTIVE = 'Inactive';
	public static final string STATUS_CIP = 'CIP';
	public static final string STATUS_ACTIVE = 'Active';
	public static final string STATUS_DEPRECIATED = 'Depreciated';
	public static final string STATUS_RETIRED = 'Retired';
	
	public static final string ASSET_ACCOUNTING = 'Accounting';
	public static final string ASSET_TAX = 'Tax';
	
	//Static boolean used for transaction control in creating new accounting fixed assets with tax books
	public static boolean isNewAsset = true;
	public static boolean isAcqCostCalculated = FALSE;
	
	//This map is used for providing Type definitions
	public static Map<string, string> interfaceProcessorMap = new Map<string, string>{ 'Straight Line' 		=> 'AccountingStraightLineDepreciation',
																						'Declining Balance' => 'AccountingDecliningBalanceDepreciation',
																						'Sum of Years' 		=> 'AccountingSumOfYearsDepreciation',
																						'MACRS' 			=> 'AccountingMACRSDepreciation'};
	public interface IDepreciation{
		List<Fixed_Asset_Depreciation__c> execute(list<sObject> sObjRecs, Date depreciateToDate, boolean commitDepreciation);
	}
	
	public static IDepreciation returnDepreciationProcessor(string depreciationProcessorName){
		//Note: If we ever let customers provide their own depreciation methods, we'll need to change the type construction to reference their namespace
 		Type t = Type.forName(depreciationProcessorName);
		return (IDepreciation)t.newInstance(); 		
	}
	/*
		Description: This method generates the Fixed Assets for the relevant tax books related to an asset class of the original Fixed Asset
	*/
	public static void createTaxBooks(Set<Id> fixedAssetIds){
		
		if(isNewAsset){
			
			isNewAsset = false;
			
			List<Fixed_Asset__c> taxBookAssets = new List<Fixed_Asset__c>();
			Set<Id> assetClassIds = new Set<Id>();
			//string fixedAssetQuery = 'SELECT ';
			//fixedAssetQuery += SchemaUtil.getInstance().getFieldsforQuery('Fixed_Asset__c');
			//fixedAssetQuery += ' FROM Fixed_Asset__c WHERE Id IN :fixedAssetIds';
            string fixedAssetFields = SchemaUtil.getInstance().getFieldsforQuery('Fixed_Asset__c');
            Set<String> queryFieldsPaths = new Set<String>(fixedAssetFields.split(','));
			String whereClause = 'Id IN :fixedAssetIds';//KNDY-8796
            SOQLUtil soql = new SOQLUtil('Fixed_Asset__c',true);
            soql.addFields(queryFieldsPaths);
            soql.setWhereClause(whereClause);
            
			
			//system.debug('fixedAssetQuery: ' + fixedAssetQuery);
			//List<Fixed_Asset__c> fixedAssets = Database.query(fixedAssetQuery);
            List<Fixed_Asset__c> fixedAssets = Database.query(soql.getQuery() );
			//system.debug('fixedAssets: ' + fixedAssets);
			
			//Collect all of the asset classes
			for(Fixed_Asset__c fa : fixedAssets){
				assetClassIds.add(fa.asset_class__c);
			}
			
			//Grab the Asset Class details in a map for later reference


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

        */
//V2
        soql = new SOQLUtil('Asset_Class__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','name','gl_account__c','expense_gl_account__c','Depreciated_GL_Account__c','life_in_months__c','depreciation_method__c',
	'declining_balance__c','depreciation_period__c','depreciation_convention__c'
});
soql.setWhereClause('Id IN :assetClassIds');
SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Asset_Class_Rules__r');
childRel.addFields(new set<string>{
	'Id','name','gl_account__c','expense_gl_account__c','disposition_gl_account__c','life_in_months__c','depreciation_method__c',
	'declining_balance__c','depreciation_period__c','depreciation_convention__c','start_date__c','end_date__c',
	'tax_book__c','tax_book__r.corporate__c','tax_book__r.active__c','tax_book__r.name' 
});
childRel.setWhereClause('tax_book__r.corporate__c = false AND tax_book__r.active__c = true');
soql.addChildRelationship(childRel);
        Map<Id, Asset_Class__c> mAssetClasses = new Map<Id, Asset_Class__c>((List<Asset_Class__c>)Database.query(soql.getQuery()));



			system.debug('mAssetClasses: ' + mAssetClasses.values());
			//Create a Tax Book Fixed Asset for each Asset Class Rule relevant to the in service date of the Fixed Asset
			for(Fixed_Asset__c fa : fixedAssets){
				if(mAssetClasses.containsKey(fa.asset_class__c)){
					for(Asset_Class_Rule__c acr : mAssetClasses.get(fa.asset_class__c).Asset_Class_Rules__r){
						if(fa.In_Service_Date__c >= acr.start_date__c 
								&& fa.In_Service_Date__c <= acr.End_Date__c
								&& fa.Tax_Book__c != acr.tax_book__c){
							Fixed_Asset__c iFA = fa.clone(false, true, false, false);
							iFA.Asset_Class_Rule__c = acr.Id;
							iFA.name = fa.name+' '+acr.tax_book__r.name; 
							iFA.Tax_Book__c = acr.tax_book__c;
							iFA.Depreciation_Method__c = acr.depreciation_method__c;
							iFA.Declining_Balance__c = acr.declining_balance__c;
							iFA.Depreciation_Period__c = acr.depreciation_period__c;
							iFA.Depreciation_Life__c = acr.life_in_months__c;
							iFA.Depreciation_Convention__c = acr.depreciation_convention__c;
							iFA.GL_Account__c = acr.gl_account__c;
							iFA.Expense_GL_Account__c = acr.expense_gl_account__c;
							iFA.Fixed_Asset__c = fa.Id;
							iFA.Fixed_Asset_Type__c = ASSET_TAX;
							taxBookAssets.add(iFA);
						}
					}
				}
			}
			DML.insertAsUser(taxBookAssets);
			system.debug('taxBookAssets: ' + taxBookAssets.size() + ' - ' + taxBookAssets);
		}
	}
	public static void checkInactiveGLs(List<Fixed_Asset__c> fixedAssets){
	    	Map<ID,Boolean> mapGlAccts = new  Map<ID,Boolean>();
   	        Set<Id> glAcctIds = new Set<Id>(); 
			 
			for(Fixed_Asset__c fa : fixedAssets){
			    glAcctIds.add(fa.Accumulated_Depreciation_GL_Account__c);
                glAcctIds.add(fa.Expense_GL_Account__c);
                glAcctIds.add(fa.GL_Account__c); 
			} 
		
		  String whereClause = 'Id IN :glAcctIds'; 
	 	  SOQLUtil soql = new SOQLUtil('GL_Account__c',true);
          soql.addFields(new set<string>{'id','name','active__c' });
          soql.setWhereClause(whereClause);
             
          List<GL_Account__c> glaccts = Database.query(soql.getQuery() ); 
          
	      for(GL_Account__c eachGL: glaccts){
	          mapGlAccts.put(eachGL.id,eachGL.active__c);
	      } 
		  for(Fixed_Asset__c fa : (List<Fixed_Asset__c>)Trigger.new){
		    if( mapGlAccts.get(fa.Accumulated_Depreciation_GL_Account__c) !=null 
		                && mapGlAccts.get(fa.Accumulated_Depreciation_GL_Account__c)==false){
		        fa.Accumulated_Depreciation_GL_Account__c.addError(Label.Accumulated_Depreciation_GL_must_be_active+fa.name);
		    }
		    if( mapGlAccts.get(fa.Expense_GL_Account__c) !=null && mapGlAccts.get(fa.Expense_GL_Account__c)==false){
		        fa.Expense_GL_Account__c.addError(Label.Expense_GL_account_must_be_active+fa.name);
		    }
		    if( mapGlAccts.get(fa.GL_Account__c) !=null && mapGlAccts.get(fa.GL_Account__c)==false){
		        fa.GL_Account__c.addError(Label.Fixed_Asset_GL_account_must_be_active+fa.name);
		    } 
		  }		 
            
	}
	public static void beforeActions(List<Fixed_Asset__c> fixedAssets){
		Set<Id> assetClassIds = new Set<Id>();
		List<DateTime> exchangeRateDates = new List<DateTime>();
		Set<Id> fromCurrencies = new Set<Id>();
		Set<Id> toCurrencies = new Set<Id>();
		for(Fixed_Asset__c fa : fixedAssets){
			assetClassIds.add(fa.asset_class__c);
			exchangeRateDates.add(fa.Date_Purchased__c);
		}
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

		        */
		//V2
		SOQLUtil soql = new SOQLUtil('Asset_Class__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','gl_account__c','depreciated_gl_account__c','expense_gl_account__c','accumulated_depreciation_gl_account__c','depreciation_method__c',
			'depreciation_period__c','depreciation_convention__c','declining_balance__c','life_in_months__c','Company__r.Comp_Currency__c'
		});
		soql.setWhereClause('Id IN :assetClassIds');
		        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Asset_Class_Rules__r');
		childRel.addFields(new set<string>{
			'Id','name','start_date__c','end_date__c','tax_book__c','gl_account__c','disposition_gl_account__c','expense_gl_account__c',
			'depreciation_method__c','depreciation_period__c','accumulated_depreciation_gl_account__c','depreciation_convention__c',
			'declining_balance__c','life_in_months__c','Tax_Book__r.Corporate__c'
		});
		childRel.setOrderByClause('CreatedDate DESC');
		soql.addChildRelationship(childRel);
        Map<Id, Asset_Class__c> mAssetClasses = new Map<Id, Asset_Class__c>((List<Asset_Class__c>)Database.query(soql.getQuery()));	
        //To load currency conversions, and calculate Acquisition cost in functional currency.
        for(Fixed_Asset__c fa : fixedAssets){
			exchangeRateDates.add(fa.Date_Purchased__c);
			if(mAssetClasses.containsKey(fa.asset_class__c)){
				fromCurrencies.add(fa.purchase_currency__c);
				toCurrencies.add(mAssetClasses.get(fa.asset_class__c).Company__r.Comp_Currency__c);
			}
		}
		ExchangeRateService.loadExchangeRates(fromCurrencies, toCurrencies, exchangeRateDates, 'Daily');
		for(Fixed_Asset__c fa : fixedAssets){			
			if(mAssetClasses.containsKey(fa.asset_class__c)){
				//Assigns the Asset class Company Currency to Functional Currency on FixedAsset.
				fa.Functional_Currency__c = mAssetClasses.get(fa.asset_class__c).Company__r.Comp_Currency__c;
				if(!isAcqCostCalculated && (fa.Acquisition_Cost__c == NULL || isSourceChanged(fa))){ 
					Decimal convertedAcqCost = ExchangeRateService.convertAmount(fa.purchase_currency__c, fa.Functional_Currency__c, fa.Date_Purchased__c, fa.Purchase_Price__c);
					fa.Acquisition_Cost__c = NULL;//Assigning Null to make sure missing conversion rate error is thrown in following steps.
					if(convertedAcqCost != NULL && convertedAcqCost != 0){
						fa.Acquisition_Cost__c = convertedAcqCost;
					}
					if(fa.Acquisition_Cost__c == NULL){
						fa.addError(Label.Missing_Conversion_Rate);
						break;
					}
				}
				//Assign the Asset Class for later reference
				Asset_Class__c assetClass = mAssetClasses.get(fa.asset_class__c);
				
				//Find ACR if available
				Asset_Class_Rule__c assetClassRule;
				Map<Id, Asset_Class_Rule__c> mACRs = new Map<Id, Asset_Class_Rule__c>(mAssetClasses.get(fa.asset_class__c).Asset_Class_Rules__r);
				if(fa.asset_class_rule__c != null && mACRs.containsKey(fa.asset_class_rule__c)){
					assetClassRule = mACRs.get(fa.asset_class_rule__c);
				}else{
					for(Asset_Class_Rule__c acr : mACRs.values()){
						if(fa.In_Service_Date__c >= acr.start_date__c 
								&& fa.In_Service_Date__c <= acr.End_Date__c){
									
							if(fa.Fixed_Asset_Type__c == ASSET_ACCOUNTING && acr.Tax_Book__r.Corporate__c){
								assetClassRule = acr;
								break;
							}else if(fa.Fixed_Asset_Type__c == ASSET_TAX && !acr.Tax_Book__r.Corporate__c && fa.Tax_Book__c == acr.tax_book__c){
								assetClassRule = acr;
								break;
							}
						}
					}
				}
				
				
				//Assign Defaults from Asset Class Rule or Asset Class Header
				if(fa.asset_class_rule__c == null && assetClassRule != null){
					
					fa.asset_class_rule__c = fa.asset_class_rule__c == null ? assetClassRule.Id : fa.asset_class_rule__c;
					
					//Default the tax book if not specified
					fa.tax_book__c = fa.tax_book__c == null ? assetClassRule.tax_book__c : fa.tax_book__c;
					
					//Default the gl account if not specified
					fa.gl_account__c = fa.gl_account__c == null ? assetClassRule.gl_account__c : fa.gl_account__c;
					
					//Default the expense gl account if not specified
					fa.expense_gl_account__c = fa.expense_gl_account__c == null ? assetClassRule.expense_gl_account__c : fa.expense_gl_account__c;
					
					//Default the expense gl account if not specified
					fa.accumulated_depreciation_gl_account__c = fa.accumulated_depreciation_gl_account__c == null ? assetClassRule.accumulated_depreciation_gl_account__c : fa.accumulated_depreciation_gl_account__c;
					
					//Default depreciation method if not specified
					fa.depreciation_method__c = fa.depreciation_method__c == null ? assetClassRule.depreciation_method__c : fa.depreciation_method__c;
					
					//Default depreciation period if not specified
					fa.depreciation_period__c = fa.depreciation_period__c == null ? assetClassRule.depreciation_period__c : fa.depreciation_period__c;
					
					//Default depreciation convention if not specified
					fa.depreciation_convention__c = fa.depreciation_convention__c == null ? assetClassRule.depreciation_convention__c : fa.depreciation_convention__c;
					
					//Default declining balance if not specified
					fa.declining_balance__c = fa.declining_balance__c == null ? assetClassRule.declining_balance__c : fa.declining_balance__c;
					
					//Default Depreciation Life if not specified
					fa.depreciation_life__c = fa.depreciation_life__c == null ? assetClassRule.Life_in_Months__c : fa.depreciation_life__c;
					
				}else{
					
					//Default the tax book if not specified
					//fa.tax_book__c = fa.tax_book__c == null ? assetClass.tax_book__c : fa.tax_book__c;
					
					//Default the gl account if not specified
					fa.gl_account__c = fa.gl_account__c == null ? assetClass.gl_account__c : fa.gl_account__c;
					
					//Default the expense gl account if not specified
					fa.expense_gl_account__c = fa.expense_gl_account__c == null ? assetClass.expense_gl_account__c : fa.expense_gl_account__c;
					
					//Default the expense gl account if not specified
					fa.accumulated_depreciation_gl_account__c = fa.accumulated_depreciation_gl_account__c == null ? assetClass.accumulated_depreciation_gl_account__c : fa.accumulated_depreciation_gl_account__c;
					
					//Default depreciation method if not specified
					fa.depreciation_method__c = fa.depreciation_method__c == null ? assetClass.depreciation_method__c : fa.depreciation_method__c;
					
					//Default depreciation period if not specified
					fa.depreciation_period__c = fa.depreciation_period__c == null ? assetClass.depreciation_period__c : fa.depreciation_period__c;
					
					//Default depreciation convention if not specified
					fa.depreciation_convention__c = fa.depreciation_convention__c == null ? assetClass.depreciation_convention__c : fa.depreciation_convention__c;
					
					//Default declining balance if not specified
					fa.declining_balance__c = fa.declining_balance__c == null ? assetClass.declining_balance__c : fa.declining_balance__c;
					
					//Default Depreciation Life if not specified
					fa.depreciation_life__c = fa.depreciation_life__c == null ? assetClass.Life_in_Months__c : fa.depreciation_life__c;
					
				}
				
			}
			
			
			//Fill in the estimated end of life if possible
			if(fa.Depreciation_Life__c != null && fa.in_service_date__c != null && fa.depreciation_life__c != null){
				fa.Estimated_End_of_Life__c = fa.in_service_date__c.addMonths((integer)fa.depreciation_life__c);
				//Increment the estimated end of life forward by a period if a mid or half convention is applied
				if(fa.depreciation_convention__c!=null && (fa.depreciation_convention__c.contains('Mid') || fa.depreciation_convention__c.contains('Half'))){
					fa.Final_Depreciation_Date__c = FixedAssetService.incrementPeriod(fa.Estimated_End_of_Life__c, fa.depreciation_period__c);
				}else{
					fa.Final_Depreciation_Date__c = fa.Estimated_End_of_Life__c;
				}
			}
			//Fill in the next depreciation date if possible
			if(fa.Date_Last_Depreciated__c != null && mAssetClasses.containsKey(fa.asset_class__c)){
				date depreciationDate;
				if(fa.Date_Last_Depreciated__c != null){
					depreciationDate = fa.Date_Last_Depreciated__c;
				}else{
					depreciationDate = fa.In_Service_Date__c;
				}
				
				if(depreciationDate != null){
					fa.Next_Depreciation_Date__c = FixedAssetService.incrementPeriod(depreciationDate, mAssetClasses.get(fa.asset_class__c).depreciation_period__c);
				}
			}
			
			
			
			// As per #KNDY-11177-KNDY-11656
			//if((fa.Residual_Value__c >= fa.book_value__c || fa.Final_Depreciation_Date__c < system.today()) && fa.status__c != FixedAssetService.STATUS_RETIRED)
			if( ( (fa.Residual_Value__c >= fa.book_value__c) 
			                            ||( fa.Final_Depreciation_Date__c < system.today() && fa.book_value__c < fa.Acquisition_Cost__c ) )
						        		//||  fa.book_value__c < 1
						        		&& fa.status__c != FixedAssetService.STATUS_RETIRED  )
			{
				fa.Status__c = FixedAssetService.STATUS_DEPRECIATED;
			}
			if(fa.status__c != FixedAssetService.STATUS_RETIRED){
				fa.disposition_date__c = null;
			}
			
			if(fa.Depreciation_Method__c == 'Straight Line'){
				fa.declining_balance__c = null;
			}
			
			 
			//---------With KNDY-10884 -Taken care  with Workflow #PopulateAssetTagNumber---------- 
			/*if(fa.asset_tag_number__c == null && trigger.isUpdate){
				fa.asset_tag_number__c = fa.Id;
			}*/
			
			if(fa.asset_tag_number__c != null && fa.asset_tag_number__c != ''){
				if(fa.Fixed_Asset_Type__c == FixedAssetService.ASSET_ACCOUNTING){
					fa.Fixed_Asset_Key__c = fa.Asset_Tag_Number__c + fa.Fixed_Asset_Type__c + fa.Company__c + fa.tax_book__c;
					//fa.Fixed_Asset_Key__c = null;
				}else{
					fa.Fixed_Asset_Key__c = fa.Asset_Tag_Number__c + fa.Fixed_Asset_Type__c + fa.Depreciation_Method__c + fa.Depreciation_Convention__c + fa.Company__c;
					//fa.Fixed_Asset_Key__c = null;
				}
			}
		}	
		// Used to find recent active standard cost from item cost on SIL. 
		Configuration__c calculateStandardCostConfig = Configuration__c.getValues('CalculateStandardCostOnFA');
		if(calculateStandardCostConfig != NULL && 
			String.isNotBlank(calculateStandardCostConfig.value__c) &&
			calculateStandardCostConfig.value__c.toLowerCase() == 'yes'){
				assignStandardCostOnFA(fixedAssets);
		}
	}

	private static void assignStandardCostOnFA(List<Fixed_Asset__c> fixedAssets){
		Set<Id> ItemIds = new Set<Id>();
		DateTime activeStandardCostDate = DateTime.now();
		List<Fixed_Asset__c> faToUpdate = new List<Fixed_Asset__c>();
		for(Fixed_Asset__c fa: fixedAssets){
			fa.Item__c = fa.SIL_Item_Id__c;
			if(String.isNotBlank(fa.SIL_Item_Id__c)){
				if(trigger.isInsert || (trigger.isUpdate && (isSilChanged(fa) || isStdCostChanged(fa))) ){
					ItemIds.add(fa.SIL_Item_Id__c);
					faToUpdate.add(fa);
				}
			}else{
                		fa.Standard_Cost__c = NULL;
            		} 
		}
		Map<Id,Item_Cost__c> itemStandardCosts = ItemService.getActiveStandardCostRecord(ItemIds,new Set<Id>(),null,null,DateTime.now());
		for(Fixed_Asset__c fa: faToUpdate){
			if(String.isNotBlank(fa.sil_item_id__c) && itemStandardCosts.containsKey(fa.sil_item_id__c) && itemStandardCosts.get(fa.sil_item_id__c) != NULL){
				fa.Standard_Cost__c = itemStandardCosts.get(fa.sil_item_id__c).Standard_Cost__c;
			}
		}
	}

	private static Boolean isSilChanged(Fixed_Asset__c fa){
		return ((fixed_asset__c)trigger.oldMap.get(fa.id)).Supplier_invoice_Line__c != fa.Supplier_invoice_Line__c;
	}

	private static Boolean isStdCostChanged(Fixed_Asset__c fa){
		return ((fixed_asset__c)trigger.oldMap.get(fa.id)).Standard_Cost__c != fa.Standard_Cost__c;
	}

	//Verifies and returns if specified FA values are changed.
	private Static Boolean isSourceChanged(Fixed_Asset__c fa){
		Boolean isPurchaseCurrChanged = Trigger.isInsert || (Trigger.isUpdate && ((Fixed_Asset__c)Trigger.oldMap.get(fa.id)).Purchase_Currency__c != fa.Purchase_Currency__c);
		Boolean isPurchasePriceChanged = Trigger.isInsert || (Trigger.isUpdate && ((Fixed_Asset__c)Trigger.oldMap.get(fa.id)).Purchase_Price__c != fa.Purchase_Price__c);
		Boolean isFuncCurrChanged = Trigger.isInsert || (Trigger.isUpdate && ((Fixed_Asset__c)Trigger.oldMap.get(fa.id)).Functional_Currency__c != fa.Functional_Currency__c);
		Boolean isPurchaseDateChanged = Trigger.isInsert || (Trigger.isUpdate && ((Fixed_Asset__c)Trigger.oldMap.get(fa.id)).Date_Purchased__c != fa.Date_Purchased__c);
		Boolean calcValuesChanged = isPurchaseCurrChanged || isPurchasePriceChanged || isFuncCurrChanged || isPurchaseDateChanged;
		return calcValuesChanged;
	}

	public static Fixed_Asset_Depreciation__c generateFixedAssetDepreciation(decimal depreciationAmount, date depreciationDate, 
	                                                                    decimal currentValue, Fixed_Asset__c fixedAsset, string subType){
		Fixed_Asset_Depreciation__c fad = new Fixed_Asset_Depreciation__c();
		if(subType == TYPE_DEPRECIATION){
			fad.depreciation_date__c = depreciationDate.toStartOfMonth().addMonths(1).addDays(-1);
			fad.gl_date__c = system.today().toStartOfMonth().addMonths(1).addDays(-1);//;depreciationDate.toStartOfMonth().addMonths(1).addDays(-1)
		}else{
			fad.depreciation_date__c = depreciationDate;
			fad.gl_date__c = depreciationDate;
		}
		fad.depreciation_type__c = fixedAsset.Depreciation_Method__c;
		fad.fixed_asset__c = fixedAsset.Id;
		fad.depreciation_key__c = generateDepreciationKey(fixedAsset, fad);
		//fad.Finalized__c = true;
		//fad.accounting_subtype__c = subType;
		fad.Subtransaction_Type__c = subType;
		fad.Transaction_Date__c = Datetime.newInstance(fad.depreciation_date__c.year(), fad.depreciation_date__c.month(), fad.depreciation_date__c.day());
		//fad.finalized_date__c = fad.Transaction_Date__c;
		fad.finalized_date__c = system.now();
		fad.company__c = fixedAsset.Company__c;
		if(String.isNotBlank(subType) && subType == TYPE_CIP){
			fad.depreciation_amount__c = fixedAsset.Purchase_Price__c.setScale(2, System.Roundingmode.HALF_UP);
			fad.currency__c = fixedAsset.Purchase_Currency__c;	
		}else{
			fad.depreciation_amount__c = depreciationAmount.setScale(2, System.Roundingmode.HALF_UP);
			fad.currency__c = fixedAsset.Company__r.Comp_Currency__c;		
		}
		fad.Value_upon_Depreciation__c = currentValue < 1 ? 0: currentValue;
		return fad;
	}
	
	public static string generateDepreciationKey(Fixed_Asset__c fixedAsset, Fixed_Asset_Depreciation__c fixedAssetDepreciation){
		Date fadDate = fixedAssetDepreciation.Depreciation_Date__c;
		string depreciationKey = fixedAsset.fixed_asset_key__c
							+ string.valueOf(fadDate.year())
							+ string.valueOf(fadDate.month());
		return depreciationKey;
	}
	
	
	
	/*
		Description: Capitalize fixed assets
	*/
	public static void capitalizeFixedAssets(Set<Id> fixedAssetIds){
		List<Fixed_Asset_Depreciation__c> insertFads = new List<Fixed_Asset_Depreciation__c>();
		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		*/
		SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','in_service_date__c','status__c','book_value__c','asset_tag_number__c','Depreciation_Method__c','company__c','Company__r.Default_Transaction_Currency__c',
			'Fixed_Asset_Key__c','depreciation_count__c', 'purchase_currency__c', 'Purchase_Price__c','Company__r.Comp_Currency__c'
		});
        date sDate = system.today();
        soql.setWhereClause('Id IN :fixedAssetIds AND status__c = :STATUS_ACTIVE AND in_service_date__c <= :sDate AND tax_book__r.corporate__c = true');
		List<Fixed_Asset__c> fas = Database.query(soql.getQuery());
		for(Fixed_Asset__c fa : fas){
			if(fa.depreciation_count__c == 0){
	 			Fixed_Asset_Depreciation__c iFad = FixedAssetService.generateFixedAssetDepreciation(fa.book_value__c, fa.in_service_date__c, fa.book_value__c, fa, TYPE_CIP);
	 			iFad.depreciation_type__c = TYPE_CIP;
	 			iFad.depreciation_key__c = fa.asset_tag_number__c + TYPE_CIP;
	 			iFad.accounting_subtype__c = TYPE_CIP;
	 			insertFads.add(iFad);
			}
		}
	    DML.upsertAsSystem(); upsert insertFads depreciation_key__c;
 	    List<Fixed_Asset_Depreciation__c> fadList = new List<Fixed_Asset_Depreciation__c>();
 		for(Fixed_Asset_Depreciation__c fad : insertFads){
 			fadList.add(new Fixed_Asset_Depreciation__c(id=fad.id,finalized__c = true));
 		}
 		DML.updateAsSystem(fadList);  
	}	
	
	
	/*
		Description: Input signature is a map of the residual gl account id and a list of corresponding fixed assets to retire against that gl account
	*/
	public static void retireFixedAssets(Map<Id, List<Fixed_Asset__c>> mFixedAssets){
	 
		List<Fixed_Asset__c> updateFixedAssets = new List<Fixed_Asset__c>();
		List<Fixed_Asset_Depreciation__c> insertFixedAssetDepreciations = new List<Fixed_Asset_Depreciation__c>();
		for(Id glAccountId : mFixedAssets.keySet()){
			for(Fixed_Asset__c fa : mFixedAssets.get(glAccountId)){
			    
			    if(fa.Retirement_Type__c=='Retire'){
    				Fixed_Asset_Depreciation__c retireFAD = FixedAssetService.generateFixedAssetDepreciation(fa.acquisition_cost__c - fa.residual_value__c, 
    				                                                                                          system.today(), 
    				                                                                                          fa.book_value__c, fa, 
    				                                                                                          FixedAssetService.TYPE_RETIRE);
    				retireFAD.depreciation_type__c = FixedAssetService.TYPE_RETIRE;
    				retireFAD.depreciation_key__c = fa.asset_tag_number__c + FixedAssetService.TYPE_RETIRE;
    		 		retireFAD.accounting_subtype__c = FixedAssetService.TYPE_RETIRE;
    		 		retireFAD.gl_account__c = fa.GL_Account__c;
    		 		insertFixedAssetDepreciations.add(retireFAD);
    		  	
				    Fixed_Asset_Depreciation__c residualFAD = FixedAssetService.generateFixedAssetDepreciation(fa.residual_value__c, 
				                                                                                                system.today(),
		 		                                                                                                fa.book_value__c, 
		 		                                                                                                fa, 
		 		                                                                                                FixedAssetService.TYPE_RESIDUAL);
    				residualFAD.depreciation_type__c = FixedAssetService.TYPE_RESIDUAL;
    				residualFAD.depreciation_key__c = fa.asset_tag_number__c + FixedAssetService.TYPE_RESIDUAL;
    		 		residualFAD.accounting_subtype__c = FixedAssetService.TYPE_RESIDUAL;
    		 		residualFAD.gl_account__c = glAccountId;
    		 		insertFixedAssetDepreciations.add(residualFAD);    
				}
				
				if(fa.Retirement_Type__c=='Return to Inventory'){
				    Fixed_Asset_Depreciation__c retireInvFAD = FixedAssetService.generateFixedAssetDepreciation(fa.Total_Depreciated_Value__c, 
				                                                                                          fa.disposition_date__c, 
				                                                                                          fa.book_value__c, fa, 
				                                                                                          FixedAssetService.TYPE_RETIRE);
    				retireInvFAD.depreciation_type__c = FixedAssetService.TYPE_RETIRE;
    				retireInvFAD.depreciation_key__c = fa.asset_tag_number__c + FixedAssetService.TYPE_RETIRE;
    		 		retireInvFAD.accounting_subtype__c = FixedAssetService.TYPE_RETIRE;
    		 		retireInvFAD.gl_account__c = fa.GL_Account__c;
    		 		insertFixedAssetDepreciations.add(retireInvFAD);
    		 		
				    Fixed_Asset_Depreciation__c assetToInvFAD = FixedAssetService.generateFixedAssetDepreciation(fa.book_value__c,
				                                                                                                 fa.disposition_date__c,
	 		                                                                                                     fa.book_value__c, fa, 
	 		                                                                                                     FixedAssetService.ASSET_TO_INVENTORY);
    				assetToInvFAD.depreciation_type__c = FixedAssetService.ASSET_TO_INVENTORY;
    				assetToInvFAD.depreciation_key__c = fa.asset_tag_number__c + FixedAssetService.ASSET_TO_INVENTORY;
    		 		assetToInvFAD.accounting_subtype__c = FixedAssetService.ASSET_TO_INVENTORY;
    		 		assetToInvFAD.gl_account__c = glAccountId;
    		 		insertFixedAssetDepreciations.add(assetToInvFAD);
				} 
		 		//fa.disposition_date__c = system.today();
	 			fa.status__c = FixedAssetService.STATUS_RETIRED;
	 			updateFixedAssets.add(fa);
			}
		}
		system.debug('updateFixedAssets: ' + updateFixedAssets);
		if(updateFixedAssets.size() > 0){
			DML.updateAsUser(updateFixedAssets);
		}
		system.debug('insertFixedAssetDepreciations: ' + insertFixedAssetDepreciations);
		if(insertFixedAssetDepreciations.size() > 0){
			DML.insertAsUser(insertFixedAssetDepreciations);
		}
	}
	
	
	/*
		Description: Sum the adjustments to the fixed asset and update the acquisition cost field
		NOTE: This must be used with a try/catch as a validation rule (Acquisition_Cost_Cannot_Be_Negative) prevents updates with a negative acquisition cost
	*/
	public static void updateFixedAssetAcquisitionCost(set<Id> fixedAssetAdjustmentIds){


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
    SOQLUtil soql = new SOQLUtil('Fixed_Asset_Adjustment__c', true,true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'fixed_asset__c fixedAssetId','SUM(amount__c) total'
});
soql.setWhereClause('Id IN :fixedAssetAdjustmentIds GROUP BY fixed_asset__c');
List<AggregateResult> arFixedAssets = Database.query(soql.getQuery());


		Map<Id, decimal> mAdjustmentAmounts = new Map<Id, decimal>();
		for(AggregateResult ar : arFixedAssets){
			mAdjustmentAmounts.put((Id)ar.get('fixedAssetId'), (decimal)ar.get('total'));
		}
		
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
     soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','acquisition_cost__c'
});
    set<id> mAdjust = mAdjustmentAmounts.keySet();        
    soql.setWhereClause('Id IN :mAdjust');
List<Fixed_Asset__c> updateFixedAssets = Database.query(soql.getQuery());
													
		for(Fixed_Asset__c fa : updateFixedAssets){
			if(mAdjustmentAmounts.containsKey(fa.Id)){
				fa.acquisition_cost__c += mAdjustmentAmounts.get(fa.Id);
				fixedAssetService.systemEditable.add(fa.Id);
				
			}
		}
		
		DML.updateAsUser(updateFixedAssets);
	}
	
	
	public static set<Id> systemEditable = new set<Id>();
	
	public static void validateSystemFields(){
	    if(trigger.isExecuting){
	        if(trigger.isUpdate){
	        	
	            for(Fixed_Asset__c fa : (List<Fixed_Asset__c>)Trigger.new){
                    if(KSE.isFieldChanging('Acquisition_cost__c', fa, trigger.oldMap) 
                    					&& fa.Total_Depreciated_Value__c > 0 
                    					&& !systemEditable.contains(fa.Id)){
                        fa.Acquisition_cost__c.addError(Label.System_Specified_Field);
	                }
	            }
	        }
	    }
	}
	
	/*
		Description: Sum the adjustments to the Receipt Invoice Line and update the total fixed asset adjustment field
		NOTE: This must be used with a try/catch as a validation rule (Adjustments_Cannot_Exceed_Extended_Cost) prevents updates with a total > extended cost
	*/
	public static void updateReceiptInvoiceLineAdjustmentTotals(set<Id> receiptInvoiceLineIds){
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
SOQLUtil soql = new SOQLUtil('Supplier_invoice_Line__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','extended_cost__c'
});
soql.setWhereClause('Id IN :receiptInvoiceLineIds');
    Map<Id, Supplier_invoice_Line__c> mRILs = new Map<Id, Supplier_invoice_Line__c>((List<Supplier_invoice_Line__c>)Database.query(soql.getQuery()));
		
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
    soql = new SOQLUtil('Fixed_Asset_Adjustment__c', true,true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Supplier_invoice_line__c rilId','SUM(amount__c) total'
});
soql.setWhereClause('Supplier_invoice_line__c IN :receiptInvoiceLineIds GROUP BY Supplier_invoice_line__c');
List<AggregateResult> arReceiptInvoiceLines = Database.query(soql.getQuery());
		List<Supplier_invoice_Line__c> updateRILs = new List<Supplier_invoice_Line__c>();
		for(AggregateResult ar : arReceiptInvoiceLines){
			Supplier_invoice_Line__c iRIL = new Supplier_invoice_Line__c(Id = (Id)ar.get('rilId'), total_fixed_asset_adjustments__c = (decimal)ar.get('total'));
			if(mRILs.containsKey(iRIL.Id)){
				if(iRIL.total_fixed_asset_adjustments__c == mRILs.get(iRIL.Id).extended_cost__c){
					iRIL.Track_as_Asset__c = 'Closed';
				}
			}  
			updateRILs.add(iRIL);
		}
		if(updateRILs.size() > 0){
			
			DML.updateAsUser(updateRILs);
		}
	}
	
	/* 
		Description: Remove the child fixed assets for tax books from the parent record, iff the tax books are not active or retired
	*/
	
	public static void deleteFixedAssetTaxBooks(set<Id> fixedAssetIds){
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'id'
});
soql.setWhereClause('fixed_asset__c IN :fixedAssetIds AND Status__c != :STATUS_ACTIVE AND Status__c != :STATUS_DEPRECIATED AND Status__c != :STATUS_RETIRED');
List<Fixed_Asset__c> deleteFixedAssets = Database.query(soql.getQuery());
		DML.deleteAsUser(deleteFixedAssets);
	}
	
	/*
		Description: Utility period and increment methods
	*/
	public static Date incrementPeriod( date depreciationDate, string periodType){
		Date incrementDate;
		if(periodType == 'Monthly'){
			incrementDate = depreciationDate.addMonths(1);
		}
		else if(periodType == 'Daily'){
			incrementDate = depreciationDate.addDays(1);
		}
		else if(periodType == 'Quarterly'){
			incrementDate = depreciationDate.addMonths(3);
		}
		else if(periodType == 'Bi-Monthly'){
			integer monthDays = Date.daysInMonth(depreciationDate.year(), depreciationDate.month());
			integer halfMonthDays = (integer)math.ceil(monthDays/2);
			incrementDate = depreciationDate.addDays(halfMonthDays);
		}
		else if(periodType == 'Semi-Annually'){
			incrementDate = depreciationDate.addMonths(6);
		}
		else if(periodType == 'Annually'){
			incrementDate = depreciationDate.addYears(1);
		}
		return incrementDate;
	}
	
	public static integer returnPeriodCount(date inServiceDate, date endOfLifeDate, string periodType){
		integer periodCount = null;
		if(periodType == 'Monthly'){
			periodCount = inServiceDate.monthsBetween(endOfLifeDate);
		}
		else if(periodType == 'Daily'){
			periodCount = inServiceDate.daysBetween(endOfLifeDate);
		}
		else if(periodType == 'Quarterly'){
			periodCount = (integer)math.floor(inServiceDate.monthsBetween(endOfLifeDate)/3);
		}
		else if(periodType == 'Bi-Monthly'){
			periodCount = inServiceDate.monthsBetween(endOfLifeDate)*2;
		}
		else if(periodType == 'Semi-Annually'){
			periodCount = (integer)math.floor(inServiceDate.monthsBetween(endOfLifeDate)/6);
		}
		else if(periodType == 'Annually'){
			periodCount = (integer)math.floor(inServiceDate.monthsBetween(endOfLifeDate)/12);
		}
		
		return periodCount;
	}
	
	//FIN-1125 Security Scanner -Bulkify Apex methods.
	
	public static Boolean checkUnretiredChildren( list<Fixed_Asset__c> faList ){
		Fixed_Asset__c fa = faList[0];
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
SOQLUtil soql = new SOQLUtil('Fixed_Asset__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'id','Status__c','Parent_Fixed_Asset__c'
});
    string faId =  fa.id;       
    soql.setWhereClause('parent_fixed_asset__c = :faId and Status__c != :STATUS_RETIRED');
List< Fixed_Asset__c > childAssets = Database.query(soql.getQuery());
		
		if( childAssets.size() > 0 )
			return true;
			
		return false;	
	}
}
