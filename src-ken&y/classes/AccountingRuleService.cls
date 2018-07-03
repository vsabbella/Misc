public with sharing class AccountingRuleService {
		
    public class AccountingRuleException extends Exception{}
	public static final integer TOTAL_NUM_KEYS_WITHOUTALLOCATION = 8;
	public static final integer TOTAL_NUM_KEYS_WITHALLOCATION = 9;
	public static final integer NUM_KEYS_BEFORE_RULETYPE =6;
    
	public static void SetUniqueKeyField(List<Accounting_Rule__c> objs){

			string strAccountingStandardId='';
			string strObjectName = '';
			string strTransaction = '';
			string strSubTransaction = '';
			string strLineType = '';
			string strRuleType = ''; 
			string strRole = ''; 
			string strAmtReference = '';
			string strEffDateFrom='';
		   	//Fix for KNDY-3824
		   	
		   	
		   	for(Accounting_Rule__c acctRule: objs){
		   		strAccountingStandardId='';
				strObjectName = '';
				strTransaction = '';
				strSubTransaction = '';
				strLineType = '';
				strRuleType = '';
				strRole = ''; 
				strAmtReference = '';
				strEffDateFrom='';
		   		if(acctRule.Accounting_Standard__c!=null)
		   			strAccountingStandardId = acctRule.Accounting_Standard__c;
		   		if(acctRule.Object_Name__c!=null)
		   			strObjectName = acctRule.Object_Name__c;
			 	if(acctRule.Transaction__c!=null)
		   			strTransaction = acctRule.Transaction__c;
			 	if(acctRule.SubTransaction_Type__c!=null)
		   			strSubTransaction = acctRule.SubTransaction_Type__c;
			 	if(acctRule.Line_Type__c!=null)
		   			strLineType = acctRule.Line_Type__c;
			 	if(acctRule.Role__c!=null)
		   			strRole = acctRule.Role__c;
			 	if(acctRule.Rule_Type__c!=null)
		   			strRuleType = acctRule.Rule_Type__c;
			 	if(acctRule.Amount_Reference__c!=null)
		   			strAmtReference = string.valueof(HashCodeGenerator.getHashCode(acctRule.Amount_Reference__c));
			 	if(acctRule.Effective_Start_Date__c!=null)
		   			strEffDateFrom = String.valueof(acctRule.Effective_Start_Date__c);
		   					   	   
		   	     acctRule.Unique_Key__c = strAccountingStandardId + '|' + strObjectName + '|' + strRole + '|' + strTransaction + '|' + strSubTransaction + '|' + strLineType + '|' + strRuleType + '|' + strAmtReference;
		   	     
		   	     if(acctRule.allocation_type__c != null){
		   	     	acctRule.Unique_Key__c += '|' + acctRule.Allocation_Type__c + '|' + acctRule.Allocation__c;
		   	     }
		   	     
		   	     acctRule.Unique_Key__c+='|'+strEffDateFrom;
		    }
			
		}
	
    // To get all segments defined in the Segment Definition custom setting to put in dynamic query
    public String getSegmentList(){

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Segment_Definition__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Accounting_Entry_Field__c'
		});
		soql.setWhereClause('Accounting_Entry_Field__c != null and Segment_Number__c not in (1)');
		List<Segment_Definition__c> fieldQueryList = Database.query(soql.getQuery());

        Set<String> QueryFieldsSet = new Set<String>();         
        for(Segment_Definition__c thisSegment: fieldQueryList){
            	if(thisSegment.Accounting_Entry_Field__c!=null) {
            		QueryFieldsSet.add(thisSegment.Accounting_Entry_Field__c.toLowerCase() );
            	}
		}
		return  (QueryFieldsSet.size()>0 
						? String.join( new List<string>(QueryFieldsSet) , ',' )
						: null);
    }
    
    public Boolean isRuleDefined(List<String> TransactionTypeList){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id'
		});
		soql.setWhereClause('Transaction__c in :TransactionTypeList');
		List<Accounting_Rule__c> fieldQueryList = Database.query(soql.getQuery());

        return ( fieldQueryList!=null && fieldQueryList.size() > 0);
    }
    
    public Boolean isRuleDefined(list<String> ObjectName, list<string> transactionTypeList){
    	list<Accounting_Rule__c> fieldQueryList = new List<Accounting_Rule__c>();
        SOQLUtil soql = new SOQLUtil('Accounting_Rule__c');
        string whereClause = '';
        if(transactionTypeList != null && transactionTypeList.size() > 0){
			whereClause += 'Transaction__c in: transactionTypeList' ;                
        }
        else if(ObjectName != null && ObjectName.size() > 0){
			whereClause = 'Object_Name__c in: ObjectName';
        }
	    soql.addField('Id');
		soql.setWhereClause(whereClause);
		system.debug('soql.getQuery():  '+ soql.getQuery());
		fieldQueryList = Database.query(soql.getQuery());
        return ( fieldQueryList!=null && fieldQueryList.size() > 0);
    }
    
    public Boolean objectHasRules(string objectName){
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('object_name__c = :objectName');
		List<Accounting_Rule__c> ars = Database.query(soql.getQuery());

        return ars.size() > 0;
    }
    
    /** 
	  * @description pull a value from an object, given the sobject relation path 
	  */
	 static public String getValue(String refString, sObject inputObject){
	 	
		if ( refString == null || String.isBlank(refString) == true ) {
			return null;		
		}

		String[] RefStringArray = refString.split('\\.');
		String lastField = RefStringArray.get(RefStringArray.size()-1);

		for(Integer i=0;i<RefStringArray.size()-1; ++i) {
			if ( inputObject != null )
				inputObject = inputObject.getSObject(RefStringArray[i]);	
		}
				
		return (inputObject != null) ?  String.valueOf(inputObject.get(lastField)) : null ; 
	}
	
	//KNDY-10268 - deprecating bank file and bank file line objects - commented references
	public static Map< String, String > getTranscationTypeToObjectMap(){
		
		map<String, String> transcationTypeToObjectMap = new map<String, String>();
		set<string> objSet = new set<string>(AccountingService.mHeaderToLines.keyset());
		/* Remove this hardcoding if all SDs migrate to transaction type model.*/
		//transcationTypeToObjectMap.put( 'Bank_File__c--Bank File', 'Bank_File_Line__c');
		transcationTypeToObjectMap.put( 'Shipment__c--Shipment', 'Shipment_Line__c');
		transcationTypeToObjectMap.put( 'Shipment__c--Sales Order Shipment', 'Shipment_Line__c');		
		transcationTypeToObjectMap.put( 'Shipment__c--Logical Sales Order Shipment', 'Shipment_Line__c');				
		transcationTypeToObjectMap.put( 'Shipment__c--Transfer Order Shipment', 'Shipment_Line__c');		
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Customer Invoice', 'Customer_Invoice_Line__c');
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Ship Invoice', 'Customer_Invoice_Line__c');
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Manual', 'Customer_Invoice_Line__c');
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Standard', 'Customer_Invoice_Line__c');
		transcationTypeToObjectMap.put( 'Customer_Receipt__c--Customer Receipt', 'Customer_Receipt_Line__c');
		//FIN-566 fix ASN Accounting
		transcationTypeToObjectMap.put( 'Receiving_Document__c--Purchase Order Receipt', 'Receipt_Line__c');
		transcationTypeToObjectMap.put( 'Receiving_Document__c--Logical Purchase Order Receipt', 'Receipt_Line__c');		
		transcationTypeToObjectMap.put( 'Receiving_Document__c--Transfer Order Receipt', 'Receipt_Line__c');
		transcationTypeToObjectMap.put( 'Receiving_Document__c--Advanced Shipment Notice', 'Receipt_Line__c');	
		transcationTypeToObjectMap.put( 'Supplier_Invoice__c--Supplier Invoice', 'Supplier_Invoice_Line__c');
		transcationTypeToObjectMap.put( 'Supplier_Invoice__c--Invoice', 'Supplier_Invoice_Line__c');
		transcationTypeToObjectMap.put( 'Supplier_Payment__c--Supplier Payment', 'Supplier_Payment_Line__c');
		transcationTypeToObjectMap.put( 'Supplier_Invoice__c--Supplier Credit Memo', 'Supplier_Invoice_Line__c'); // Changed this lines for Credit Memos - KNDY 2731
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Customer Credit Memo', 'Customer_Invoice_Line__c'); // Changed this to lines for Credit Memos
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Credit Memo', 'Customer_Invoice_Line__c'); // Changed this to add Credit Memo as transaction type TODO: Revisit while testing Supplier Credit Memo and this map might need redesign
		transcationTypeToObjectMap.put( 'Supplier_Invoice__c--Credit Memo', 'Supplier_Invoice_Line__c'); // Changed this to add Credit Memo as transaction type
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Invoice Credit', 'Customer_Invoice_Line__c'); 			//DP: added this, seemed to be missing
        transcationTypeToObjectMap.put( 'Customer_Invoice__c--Miscellaneous Credit', 'Customer_Invoice_Line__c'); 	//DP: added this, seemed to be missing	
        transcationTypeToObjectMap.put( 'Customer_Invoice__c--Prepayment', 'Customer_Invoice_Line__c'); 				//DP: added this, seemed to be missing	
        transcationTypeToObjectMap.put( 'Customer_Invoice__c--Settlement', 'Customer_Invoice_Line__c');
		transcationTypeToObjectMap.put( 'Inventory_Change__c--Inventory Change', 'Inventory_Transaction__c');
		transcationTypeToObjectMap.put( 'Inventory_Change__c--Adjustment', 'Inventory_Transaction__c');
		transcationTypeToObjectMap.put( 'Inventory_Change__c--Cycle Count', 'Inventory_Transaction__c');
		transcationTypeToObjectMap.put( 'Inventory_Change__c--Transfer', 'Inventory_Transaction__c');
		transcationTypeToObjectMap.put( 'Work_Order__c--Work Order', 'Inventory_Transaction__c');
		transcationTypeToObjectMap.put( 'Fixed_Asset_Depreciation__c--Fixed Asset Depreciation', 'Fixed_Asset_Depreciation__c');
		transcationTypeToObjectMap.put( 'Fixed_Asset_Adjustment__c--Fixed Asset Adjustment', 'Fixed_Asset_Adjustment__c');
		transcationTypeToObjectMap.put( 'Customer_Invoice__c--Adjustment', 'Customer_Invoice_Line__c');
//		transcationTypeToObjectMap.put( 'Purchase_Order__c--Standard', 'Purchase_Order_Line__c');
		transcationTypeToObjectMap.put( 'Journal_Entry__c--Accrual - Manual', 'Journal_Entry_Line__c');
		transcationTypeToObjectMap.put( 'Journal_Entry__c--Manual', 'Journal_Entry_Line__c');
		transcationTypeToObjectMap.put( 'Journal_Entry__c--Recurring Journal', 'Journal_Entry_Line__c');
		transcationTypeToObjectMap.put( 'Journal_Entry__c--Year End', 'Journal_Entry_Line__c');
		transcationTypeToObjectMap.put( 'Journal_Entry__c--Year End Adjustment', 'Journal_Entry_Line__c');
		 
		//FIN-495 generate the transcationTypeToObjectMap dynamicly based on Transaction_Type__c picklistvalues in respective Source Docs.
		//TODO:Think of options to sanitize input and make it case insensitive.
		schemaUtil util =SchemaUtil.getInstance();
		for(string SD:AccountingService.mHeaderToLines.keyset())
		{					
					list<Schema.PicklistEntry> pickListEntries =util.getPickListEntriesFromField(SD,'Transaction_Type__c');
					for(Schema.PicklistEntry pickListEntry:pickListEntries)
					{
						string transcationTypeKey = SD+'--'+pickListEntry.getValue();
						if(transcationTypeKey!=SD+'----None--' && !transcationTypeToObjectMap.containsKey(transcationTypeKey))
						{
						  if(SD=='Fixed_Asset_Adjustment__c'|| SD=='Fixed_Asset_Depreciation__c')
						  {
  			               transcationTypeToObjectMap.put( transcationTypeKey, SD);																			  	
						  }
						  else
						  {
  			               transcationTypeToObjectMap.put( transcationTypeKey, AccountingService.mHeaderToLines.get(SD));																			  	
						  }
						}
					}		
		}
		
		return transcationTypeToObjectMap;
	}
	//KNDY-10268 - deprecating bank file and bank file line objects - commented references
	public static map<string,string> mSDLowerToSDAPICase= new map<string,string>
	{
        'journal_entry__c'     				=> 'Journal_Entry__c',
        'customer_invoice__c'   			=> 'Customer_Invoice__c',
        'customer_receipt__c' 			    => 'Customer_Receipt__c',
        'invoice__c'         		        => 'Invoice__c',
        'payment__c'                        => 'Payment__c',
        'supplier_invoice__c'               => 'Supplier_Invoice__c',
        'supplier_payment__c'               => 'Supplier_Payment__c',
        //'bank_file__c'	                    => 'Bank_File__c',
        'bank_transaction_group__c'         => 'Bank_Transaction_Group__c',
        'inventory_change__c'               => 'Inventory_Change__c',
        'work_order__c'                     => 'Work_Order__c',
        'fixed_asset_depreciation__c'       => 'Fixed_Asset_Depreciation__c',   
        'fixed_asset_adjustment__c'         => 'Fixed_Asset_Adjustment__c',
//        'purchase_order__c'                 => 'Purchase_Order__c',
        'receiving_document__c'             => 'Receiving_Document__c',
        'shipment__c'                       => 'Shipment__c'
        
	};
	/* ---------------------- */
	/* RS Refactor to support */
	/* ---- KNDY-2975 ------- */ 
	/* ---------------------- */
	
	public static set<string> getRuleFields(){
		
        Set<string> queryFieldsSet = new Set<string>();
                 
        for(Segment_Definition__c thisSegment : Segment_Definition__c.getAll().values()){
			queryFieldsSet.add(thisSegment.Accounting_Rule_Segment__c.toLowerCase() );
			queryFieldsSet.add(thisSegment.Accounting_Rule_Reference_Value__c.toLowerCase() );
			queryFieldsSet.add(thisSegment.Accounting_Rule_Default__c.toLowerCase() );
		}
		queryFieldsSet.remove('');
		queryFieldsSet.remove(null);
		return queryFieldsSet;
    }
	
	public static set<string> getSegmentFields(){
		
        Set<string> queryFieldsSet = new Set<string>();
                 
        for(Segment_Definition__c thisSegment : Segment_Definition__c.getAll().values()){
        	if(thisSegment.Accounting_Rule_Segment__c != null 
        			&& thisSegment.Segment_Number__c != 1) {
        		queryFieldsSet.add(thisSegment.Accounting_Rule_Segment__c.toLowerCase() );
        		queryFieldsSet.add(thisSegment.Accounting_Rule_Reference_Value__c.toLowerCase() );
        		queryFieldsSet.add(thisSegment.Accounting_Rule_Default__c.toLowerCase() );
        	}
		}
		queryFieldsSet.remove('');
		queryFieldsSet.remove(null);
		return queryFieldsSet;
    }
    
    public static set<string> getSegmentReferenceFields(string sObjectName){
        
        Set<string> queryFieldsSet = new Set<string>();
        
        for(Accounting_Rule__c thisRule: getAccountingRulesByObject(sObjectName)) {
        	//system.debug('thisRule: ' + thisRule);
        	//system.debug('thisRule FX_Date_Path__c: ' + thisRule.FX_Date_Path__c);
        	
        	if(thisRule.FX_Date_Path__c != null){
        		queryFieldsSet.add(thisRule.FX_Date_Path__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),''));
        	}
            
        	for(Segment_Definition__c thisSegment : Segment_Definition__c.getAll().values()){
        		//system.debug('thisSegment: ' + thisSegment);
				if( thisSegment.Accounting_Rule_Reference_Value__c != null && thisSegment.Accounting_Rule_Reference_Value__c != '') {
					string refField = (string)thisRule.get(thisSegment.Accounting_Rule_Reference_Value__c.toLowerCase());
					//system.debug('refField: ' + refField);
					if(refField != null){
						//system.debug('comes inside refField: ');
						//system.debug('KSE.NamespaceUU: '+KSE.NamespaceUU);
						String localRefField = refField.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),'');
						//system.debug('localRefField: '+localRefField);
						queryFieldsSet.add(localRefField);
					}
				}
				if(thisRule.Amount_Reference__c != null && thisRule.Amount_Reference__c != '') {
					//system.debug('comes inside Amount_Reference__c: ');
					//system.debug('thisRule.Amount_Reference__c: ' + thisRule.Amount_Reference__c);
					queryFieldsSet.add(thisRule.Amount_Reference__c.toLowerCase().replace(KSE.NamespaceUU.toLowerCase(),''));
				}
        	}
		}
		queryFieldsSet.remove('');
		queryFieldsSet.remove(null);
    	return queryFieldsSet;
    }
    
    public static string getUniqueKeyExtract(string uniqueKey,integer numberOfKeys){
        string UniqueKeySubStr ='';
        //System.debug('uniqueKey --before extract'+uniqueKey);
		list<string> uniqueKeyCombos = uniquekey.split('\\|');
		if(numberOfKeys== -1){//Just strip off eff date
			UniqueKeySubStr = uniqueKey.substringbeforeLast('|')+'%';//Assuming there are no old data without eff date.
		}
		else{
			for(integer i=0;i<numberOfKeys;i++)
			{
							UniqueKeySubStr = UniqueKeySubStr+uniqueKeyCombos[i] +'|';
			}
			UniqueKeySubStr = UniqueKeySubStr.removeEnd('|')+'%'; 
		}
       // System.debug('uniqueKey --after	 extract'+UniqueKeySubStr);
		
		return UniqueKeySubStr;
    }
	
	@TestVisible
	private static list<accounting_rule__c> ExistingRulesForUniqueKey = new list<Accounting_Rule__c>();
	@TestVisible
	private static set<string> uniqueKeysubstrQueried = new set<string>();
	@TestVisible
	private static set<Id> RuleIdsToBeSkipped = new set<Id>();
	@TestVisible
	public static void getExistingRulesForUniqueKeySubstr(list<Accounting_Rule__c> newRules){
		
		
		set<string> uniqueKeysWithoutEffDate = new set<string>();
	    for(Accounting_Rule__c newRule:newRules){
			uniqueKeysWithoutEffDate.add(getUniqueKeyExtract(newRule.unique_key__c,NUM_KEYS_BEFORE_RULETYPE));//We are querying the  records for  maximum inclusive substr pattern and organize it in respective maps later.
			RuleIdsToBeSkipped.add(newRule.Id);
	    }
	    system.debug(LOGGINGLEVEL.INFO,'uniqueKeysWithoutEffDate -- before Query'+uniqueKeysWithoutEffDate);
	    
		uniqueKeysWithoutEffDate.removeAll(uniqueKeysubstrQueried);
		
		if(uniqueKeysWithoutEffDate.size()>0){//This flow will happen on first invocation and/or when some other method is trying to invoke this method with diff-uniquekeys in same Triggercontext.
			
			system.debug(LOGGINGLEVEL.INFO,'inside existing rule query ');

			/*ExistingRulesForUniqueKey.addAll([select id,name,Effective_End_Date__c,Effective_Start_Date__c,unique_key__c,rule_type__c
											  from accounting_rule__c 
											  where unique_key__c LIKE :uniqueKeysWithoutEffDate 
											  and Id not in :RuleIdsToBeSkipped // For update action.
											  order by unique_key__c ASC]);	*/
			
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('accounting_rule__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','Effective_End_Date__c','Effective_Start_Date__c','unique_key__c','rule_type__c','Role__c'
			});
			soql.setWhereClause('unique_key__c LIKE :uniqueKeysWithoutEffDate and Id not in :RuleIdsToBeSkipped'); // For update action.
			soql.setOrderByClause('unique_key__c ASC');
			ExistingRulesForUniqueKey.addAll((list<Accounting_Rule__c>)Database.query(soql.getQuery()));
						
			map<Id,Accounting_Rule__c> mExistingRules = new map<Id,Accounting_Rule__c>(ExistingRulesForUniqueKey);
			
			//Excluding the false-positive Existing rules which were included due to multiple trigger invocations in same trigger context.
			for(Id ExistingRuleId:mExistingRules.keyset())	{
				if(RuleIdsToBeSkipped.contains(ExistingRuleId)){
					mExistingRules.remove(ExistingRuleId);
									
				}
			}
			uniqueKeysubstrQueried.addAll(uniqueKeysWithoutEffDate);	
			
			ExistingRulesForUniqueKey.clear();
			ExistingRulesForUniqueKey=mExistingRules.values();
			
		}
			system.debug(LOGGINGLEVEL.INFO,'ExistingRulesForUniqueKey '+ExistingRulesForUniqueKey);
			system.debug(LOGGINGLEVEL.INFO,'uniqueKeysubstrQueried '+uniqueKeysubstrQueried);
		
	}
	//This method is used to build a map of rules with uniquekeysubstr -Dictated by number of Keys
	//Given a list of Rules and Number of Keys to form the uniqueKeysubstr,Build a map grouping the rules by uniquekeysubstr.
	//Number of Keys can be specified until amountoverride key.After that seperators are variable based on Allocation.So using -1 for Eff dating stripping.
	public static map<string,set<Accounting_Rule__c>> buildCustUniqueKeySubstrToRulesMap(list<Accounting_Rule__c> newRules,integer numberofKeys,Boolean IsBuildMapForExistingRules){
		
		map<string,set<Accounting_Rule__c>> mUniqueKeySubstrToRules = new map<string,set<Accounting_Rule__c>>();
		list<Accounting_Rule__c> rulesList= new list<Accounting_Rule__c>();
		
		if(IsBuildMapForExistingRules){
        	getExistingRulesForUniqueKeySubstr(newRules);
        	rulesList = ExistingRulesForUniqueKey;
		}
		else{
			rulesList = newRules;
		}
		for(Accounting_Rule__c rule:rulesList){
			string uniqueKeySubstr = getUniqueKeyExtract(rule.unique_key__c,numberofKeys);
			if(mUniqueKeySubstrToRules.containskey(uniqueKeySubstr)){
				mUniqueKeySubstrToRules.get(uniqueKeySubstr).add(rule);
			}
			else{
				mUniqueKeySubstrToRules.put(uniqueKeySubstr,new set<Accounting_Rule__c>{rule});					
			}
		}
		system.debug('mUniqueKeySubstrToRules :' +mUniqueKeySubstrToRules);
	
		return mUniqueKeySubstrToRules;
	}
	

	@TestVisible
	private static Map<string, List<Accounting_Rule__c>> mAccountingRules = new Map<string, List<Accounting_Rule__c>>();
	public static List<Accounting_Rule__c> getAccountingRulesByObject(string sObjectName){
		
		if(!mAccountingRules.containsKey(sObjectName)){
			
			set<string> queryFields = new set<string>{'id','name',  'rule_type__c', 'transaction__c', 'subtransaction_type__c', 'line_type__c', 'object_name__c', 'Expected_Sign__c', 'Role__c',
														'accounting_standard__c', 'amount_reference__c','Company_Ledger__c','Consolidation_Ledger__c','Statutory_Ledger__c','Subsidiary_Ledger__c',
														'Effective_End_Date__c','Effective_Start_Date__c', 'FX_Date_Path__c', 'FX_Flow__c',
														'GL_Account_Reference_Value__c', 'gl_account__c', 'Default_GL_Account__c', 
														'Intercompany__c', 'Intercompany_Reference_Value__c', 'Default_Intercompany__c','Suppress_Zero_Amount_Lines__c','Raise_Exceptions_for_Blank_Amounts__c'
														//'Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c', 'fx_flow__c', 'fx_date_path__c',
														//'Company__r.Default_Transaction_Currency__c','Company__r.Default_Transaction_Currency__r.ISO_Code__c','Company__r.Comp_Currency__c','Company__r.Comp_Currency__r.ISO_Code__c',
														//'Company__r.Consol_Currency__c','Company__r.Consol_Currency__r.ISO_Code__c',
														};
			queryFields.addAll(getSegmentFields());

			SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', FALSE);
			soql.addFields(queryFields);
			soql.setWhereClause('Object_Name__c = :sObjectName'
			+ ' AND (Allocation__c = null OR Allocation__c = \'\')'
			+ ' AND Allocation_Type__c = null');

			List<Accounting_Rule__c> rules = Database.query(soql.getQuery());
			mAccountingRules.put(sObjectName, rules);
			
		}
		return mAccountingRules.get(sObjectName);
		//return getEffectiveAccountingRulesByObject(sObjectName,null,null);
	}
    //KNDY-9545
	@TestVisible
	public static List<Accounting_Rule__c> getEffectiveAccountingRulesByObject(string sObjectName,list<datetime> TDList){
			
			if(TDList.size()>0)
			{
				set<string> queryFields = new set<string>{'id','name',  'rule_type__c', 'transaction__c', 'subtransaction_type__c', 'line_type__c', 'object_name__c', 'Expected_Sign__c', 'Role__c',
														'accounting_standard__c', 'amount_reference__c','Company_Ledger__c','Consolidation_Ledger__c','Statutory_Ledger__c','Subsidiary_Ledger__c',
														'Effective_End_Date__c','Effective_Start_Date__c', 'FX_Date_Path__c', 'FX_Flow__c',
														'GL_Account_Reference_Value__c', 'gl_account__c', 'Default_GL_Account__c', 
														'Intercompany__c', 'Intercompany_Reference_Value__c', 'Default_Intercompany__c','Suppress_Zero_Amount_Lines__c','Raise_Exceptions_for_Blank_Amounts__c'
														//'Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c', 'fx_flow__c', 'fx_date_path__c',
														//'Company__r.Default_Transaction_Currency__c','Company__r.Default_Transaction_Currency__r.ISO_Code__c','Company__r.Comp_Currency__c','Company__r.Comp_Currency__r.ISO_Code__c',
														//'Company__r.Consol_Currency__c','Company__r.Consol_Currency__r.ISO_Code__c',
														};
				queryFields.addAll(getSegmentFields());
				System.debug('getEffectiveAccountingRulesByObject-queryFields: '+ queryFields);				
				String whereClause = 'Object_Name__c = :sObjectName'
				+ ' AND (Allocation__c = null OR Allocation__c = \'\')'
				+ ' AND Allocation_Type__c = null';

				DateTime startTxnDate = AccountingService.getStartTxnDate(TDList); //getTrxnStartDate();
				DateTime endTxnDate   = AccountingService.getEndTxnDate(TDList);

	            //Get all rules which have started before the latest Txn date and which are ended only after the earliest txn date
	            //Inclusive of both dates to make sure we dont miss any edge cases.	Exact boundary exclusion will be taken care in accounting workers.		
				if(endTxnDate!=null)
				{
					whereClause += ' AND Effective_Start_Date__c <=:endTxnDate ';
				}	

				if(startTxnDate!=null)
				{
					whereClause += ' AND (Effective_End_Date__c >=:startTxnDate OR Effective_End_Date__c=NULL )';
				}						
				
				SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', FALSE);
				soql.addFields(queryFields);
				soql.setWhereClause(whereClause);

	            system.debug(LOGGINGLEVEL.INFO,'eff date query'+ soql.getQuery());
				
				List<Accounting_Rule__c> rules = Database.query(soql.getQuery());
				return rules;
				
							
			}
			else
			{
				throw new AccountingRuleException('Transaction Date is missing in the source document ');
			}

		
	}	
	//KNDY-16543 
	@TestVisible
	public static List<Accounting_Rule__c> getEffectiveAccountingRulesByObjectAndTransaction(string sObjectName,string transType,list<datetime> TDList){
			
			if(TDList.size()>0)
			{
				set<string> queryFields = new set<string>{'id','name',  'rule_type__c', 'transaction__c', 'subtransaction_type__c', 'line_type__c', 'object_name__c', 'Expected_Sign__c', 'Role__c',
														'accounting_standard__c', 'amount_reference__c','Company_Ledger__c','Consolidation_Ledger__c','Statutory_Ledger__c','Subsidiary_Ledger__c',
														'Effective_End_Date__c','Effective_Start_Date__c', 'FX_Date_Path__c', 'FX_Flow__c',
														'GL_Account_Reference_Value__c', 'gl_account__c', 'Default_GL_Account__c', 
														'Intercompany__c', 'Intercompany_Reference_Value__c', 'Default_Intercompany__c','Suppress_Zero_Amount_Lines__c','Raise_Exceptions_for_Blank_Amounts__c'
														//'Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c', 'fx_flow__c', 'fx_date_path__c',
														//'Company__r.Default_Transaction_Currency__c','Company__r.Default_Transaction_Currency__r.ISO_Code__c','Company__r.Comp_Currency__c','Company__r.Comp_Currency__r.ISO_Code__c',
														//'Company__r.Consol_Currency__c','Company__r.Consol_Currency__r.ISO_Code__c',
														};
				queryFields.addAll(getSegmentFields());
				System.debug('getEffectiveAccountingRulesByObject-queryFields: '+ queryFields);				
				String whereClause = 'Object_Name__c = :sObjectName'
				+ ' AND Transaction__c =:transType'
				+ ' AND (Allocation__c = null OR Allocation__c = \'\')'
				+ ' AND Allocation_Type__c = null';

				DateTime startTxnDate = AccountingService.getStartTxnDate(TDList); //getTrxnStartDate();
				DateTime endTxnDate   = AccountingService.getEndTxnDate(TDList);

	            //Get all rules which have started before the latest Txn date and which are ended only after the earliest txn date
	            //Inclusive of both dates to make sure we dont miss any edge cases.	Exact boundary exclusion will be taken care in accounting workers.		
				if(endTxnDate!=null)
				{
					whereClause += ' AND Effective_Start_Date__c <=:endTxnDate ';
				}	

				if(startTxnDate!=null)
				{
					whereClause += ' AND (Effective_End_Date__c >=:startTxnDate OR Effective_End_Date__c=NULL )';
				}						
				
				SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', FALSE);
				soql.addFields(queryFields);
				soql.setWhereClause(whereClause);

	            system.debug(LOGGINGLEVEL.INFO,'Object Trans wise eff date query'+ soql.getQuery());
				
				List<Accounting_Rule__c> rules = Database.query(soql.getQuery());
				return rules;
				
							
			}
			else
			{
				throw new AccountingRuleException('Transaction Date is missing in the source document ');
			}

		
	}
	public static List<Accounting_Rule__c> getAccountingRules(set<Id> accountingRuleIds){
		
		set<Id> ruleIds = accountingRuleIds;
		set<string> queryFields = new set<string>{'id','name',  'rule_type__c', 'transaction__c', 'subtransaction_type__c', 'line_type__c', 'object_name__c', 'Expected_Sign__c', 'Role__c',
														'accounting_standard__c', 'amount_reference__c','Company_Ledger__c','Consolidation_Ledger__c','Statutory_Ledger__c','Subsidiary_Ledger__c',
														'Effective_End_Date__c','Effective_Start_Date__c', 'FX_Date_Path__c', 'FX_Flow__c',
														'GL_Account_Reference_Value__c', 'gl_account__c', 'Default_GL_Account__c', 
														'Intercompany__c', 'Intercompany_Reference_Value__c', 'Default_Intercompany__c'
														//'Company__r.Stat_Currency__c','Company__r.Stat_Currency__r.ISO_Code__c', 'Company__r.Subs_Currency__c','Company__r.Subs_Currency__r.ISO_Code__c', 'fx_flow__c', 'fx_date_path__c',
														//'Company__r.Default_Transaction_Currency__c','Company__r.Default_Transaction_Currency__r.ISO_Code__c','Company__r.Comp_Currency__c','Company__r.Comp_Currency__r.ISO_Code__c',
														//'Company__r.Consol_Currency__c','Company__r.Consol_Currency__r.ISO_Code__c',
														};
		queryFields.addAll(getSegmentFields());

		SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', FALSE);
		soql.addFields(queryFields);
		soql.setWhereClause(' Id IN :ruleIds');

		return Database.query(soql.getQuery());
	}
	
	public static Map<string, List<Accounting_Rule__c>> getAccountingRulesByTransaction(string sObjectName, List<string> transactionTypes){
		Map<string, List<Accounting_Rule__c>> mRulesByTrxn = new Map<string, List<Accounting_Rule__c>>();
		List<Accounting_Rule__c> accountingRules = getAccountingRulesByObject(sObjectName);
		for(string trxnType : transactionTypes){
			mRulesByTrxn.put(trxnType, KSE.grep(accountingRules, 'Transaction__c', trxnType ));
		}
		return mRulesByTrxn;
	}
	
	//cache the constructed rules if requested again during the transaction
	@TestVisible
	private static Map<string, Map<RuleDefinition, List<Accounting_Rule__c>>> mObjectRuleDefs = new Map<string, Map<RuleDefinition, List<Accounting_Rule__c>>>();
	public static Map<RuleDefinition, List<Accounting_Rule__c>> getRuleDefsForObject(string sObjectName){
		
		Map<RuleDefinition, List<Accounting_Rule__c>> mRuleDefs;
		if(mObjectRuleDefs.containsKey(sObjectName)){
			mRuleDefs = mObjectRuleDefs.get(sObjectName);
		}else{
			mRuleDefs = new Map<RuleDefinition, List<Accounting_Rule__c>>();
			for(Accounting_Rule__c ar : getAccountingRulesByObject(sObjectName)){
				RuleDefinition iRD = new RuleDefinition(ar);
				//system.debug('iRD: ' + iRD);
				//system.debug('ar: ' + ar);
				//system.debug('mRuleDefs contains: ' + mRuleDefs.containsKey(iRD));
				if(mRuleDefs.containsKey(iRD)){
					mRuleDefs.get(iRD).add(ar);
				}else{
					mRuleDefs.put(iRD, new List<Accounting_Rule__c>{ar});
				}
			}
			mObjectRuleDefs.put(sObjectName, mRuleDefs);
		}
		//system.debug('mRuleDefs: ' + mRuleDefs);
		return mRuleDefs;
	}

    //KNDY-9545 Build the ruleDef for given list of Effective accounting rules.
	public static Map<RuleDefinition, List<Accounting_Rule__c>> getEffectiveRuleDefs(map<id, Accounting_Rule__c> mEffRules){
		
		Map<RuleDefinition, List<Accounting_Rule__c>> mRuleDefs;

			mRuleDefs = new Map<RuleDefinition, List<Accounting_Rule__c>>();
			for(Accounting_Rule__c ar : mEffRules.values()){
				RuleDefinition iRD = new RuleDefinition(ar);
				//system.debug('iRD: ' + iRD);
				//system.debug('ar: ' + ar);
				//system.debug('mRuleDefs contains: ' + mRuleDefs.containsKey(iRD));
				if(mRuleDefs.containsKey(iRD)){
					mRuleDefs.get(iRD).add(ar);
				}else{
					mRuleDefs.put(iRD, new List<Accounting_Rule__c>{ar});
				}
			}
		
		//system.debug('mRuleDefs: ' + mRuleDefs);
		return mRuleDefs;
	}	
	
	
	
	public static List<Accounting_Rule__c> getAccountingRules(RuleDefinition ruleDef){
		return getRuleDefsForObject(ruleDef.objectName).get(ruleDef);
	}
	
	
	public enum RuleType { CR, DR, NA }
	
	/*
	* @description: RuleDefinition serves as a matching key between the accounting rules and the accounting entry lines that are being submitted for segment assignments
	* 				The RuleDefinition is then used in turn to identify and populate segments on the relevant records
	*/
	public class RuleDefinition{
		
		public final RuleType rt;
		public final string objectName;
		public final string transType;
		public final string subTransType;
		public final string lineType;
		public final Id accountingStandardId;
		public final string Role;
		private integer hash;
		
		public RuleDefinition(RuleType rt, Id accountingStandardId, string objectName, string transType, string subTransType, string lineType){
			this.rt = rt;
			this.accountingStandardId = accountingStandardId;
			this.objectName = objectName;
			this.transType = transType;
			this.subTransType = subTransType;
			this.lineType = lineType;
			hashCode();
		}
		
		public RuleDefinition(Accounting_Rule__c ar){
			if(ar.Rule_Type__c == 'CR'){
				this.rt = RuleType.CR;
			}else if(ar.Rule_Type__c == 'DR'){
				this.rt = RuleType.DR;
			}else{
				this.rt = RuleType.NA;
			}
			this.accountingStandardId = ar.Accounting_Standard__c;
			this.objectName = ar.Object_Name__c;
			this.transType = ar.Transaction__c;
			this.subTransType = ar.SubTransaction_Type__c;
			this.lineType = ar.Line_Type__c;
			this.Role = ar.Role__c;
			hashCode();
		}
		
		//Defines uniqueness when comparing an apex class as key in sets or maps
		//http://www.salesforce.com/us/developer/docs/apexcode/Content/langCon_apex_collections_maps_keys_userdefined.htm
		public boolean equals(object obj){
			RuleDefinition rd = (RuleDefinition)obj;
			if(rt == rd.rt
					&& accountingStandardId == rd.accountingStandardId
					&& objectName == rd.objectName
					&& transType == rd.transType
					&& subTransType == rd.subTransType
					&& Role == rd.Role
					&& lineType == rd.lineType){
				return true;			
			}else{
				return false;
			}
		}
		
		public RuleDefinition(RuleType rt, Id accountingStandardId, string objectName, string transType, string subTransType, string lineType, string Role){
			this.rt = rt;
			this.accountingStandardId = accountingStandardId;
			this.objectName = objectName;
			this.transType = transType;
			this.subTransType = subTransType;
			this.lineType = lineType;
			this.Role = Role;
			hashCode();
		}
		
				
		public integer hashCode(){
			if(hash == null){
				hash = HashCodeGenerator.getHashCode(this);  
			}
			return hash;
		}
		
		
	}
	
	public enum DistributionType {HEADER, LINE}
	public class DistributionDefinition{
		
		public final RuleDefinition ruleDef;
		public final string distro;
		public final DistributionType distroType;
		private integer hash;
		
		public DistributionDefinition(RuleDefinition ruleDef, Accounting_Rule__c ar){
			this.ruleDef = ruleDef;
			this.distro = ar.Allocation__c;
			if(ar.Allocation_Type__c == 'Header'){
				this.distroType = DistributionType.HEADER;
			}else if(ar.Allocation_Type__c == 'Line'){
				this.distroType = DistributionType.LINE;
			} 
		}
		
		public DistributionDefinition(RuleDefinition ruleDef, DistributionType distroType, string distro){
			this.ruleDef = ruleDef;
			this.distro = distro;
			this.distroType = distroType;
		}
		
		
		public boolean equals(object compareTo){
			DistributionDefinition compare = (DistributionDefinition)compareTo;
			if(this.ruleDef.equals(compare.ruleDef)
					&& this.distro == compare.distro
					&& this.distroType == compare.distroType){
				return true;	
			}else{
				return false;
			}
		}
		
		public integer hashCode(){
			if (hash == null){
				hash = HashCodeGenerator.getHashCode(this);  
			}
			return hash;
		}
	}
	//KNDY-10268 - deprecating bank file and bank file line objects - commented references
	public static void getObjectAPIName(list<Accounting_Rule__c> newList){
	
		map<string,string> objectNamemap = new map<string,string>{		
		//'Bank File' => 'Bank_File__c',
        'Bank Transaction Group' => 'Bank_Transaction_Group__c',		
		'Customer Invoice' => 'Customer_Invoice__c',
		'Customer Receipt' => 'Customer_Receipt__c',
		'Fixed Asset Adjustment' => 'Fixed_Asset_Adjustment__c',
		'Fixed Asset Depreciation' => 'Fixed_Asset_Depreciation__c',
		'Inventory Change' => 'Inventory_Change__c',
		'Journal Entry' => 'Journal_Entry__c',
		'Receiving Document' => 'Receiving_Document__c',
		'Shipment' => 'Shipment__c',
		'Invoice' => 'Invoice__c',
		'Payment' => 'Payment__c',
		'Supplier Invoice' => 'Supplier_Invoice__c',
		'Supplier Payment' => 'Supplier_Payment__c'
		}; 
	
		for(Accounting_Rule__c ar:newList){
			if(ar.Object__c != null){
				if(objectNamemap.containskey(ar.Object__c)){
				ar.Object_Name__c = objectNamemap.get(ar.Object__c);
				
				}
			
			}
		
		}
	
	}
	
	public static void validateEffectiveDates(list<accounting_rule__c> newRules,map<id,accounting_rule__C> oldRulesMap)
	{
		map<id,accounting_rule__c> mRulesWithEffDateChanging = new map<id,accounting_rule__c>();
		map<string,set<accounting_rule__c>> mUniqueKeySubStrToNewRules = new map<string,set<accounting_rule__c>>();//mUniqueKeyWithoutEffDateToRules
		string SFDCBaseURL = URL.getSalesforceBaseUrl().toExternalForm();	
	    map<string,set<accounting_rule__c>> mUniqueKeySubStrToExistingRules = new map<string,set<accounting_rule__c>>();		
	    
		//system.debug('inside eff dates method for RuleIds'+newRulesMap.keyset());
		for(accounting_rule__c rule:newRules)
		{
			if(rule.Effective_Start_Date__c==null)
			{
				rule.Effective_Start_Date__c.addError(Label.Please_enter_effective_start_date);
			}
			if(rule.Effective_Start_Date__c> rule.Effective_End_Date__c)
			{
				rule.Effective_Start_Date__c.addError(Label.Effective_start_date_cannot_be_greater_than_effective_end_date);				
			}
			if(trigger.isUpdate)
			{
				if((KSE.isFieldChanging('Effective_Start_Date__c',rule,oldRulesMap) && oldRulesMap.get(rule.Id).Effective_Start_Date__c!=null)  //During first time update of eff date to created date it will be null
				  ||(KSE.isFieldChanging('Effective_End_Date__c',rule,oldRulesMap) && oldRulesMap.get(rule.Id).Effective_End_Date__c!=null)) //During end dating a rule and creating new rule.
				{
				   mRulesWithEffDateChanging.put(rule.Id,rule);
				}	
			
			}          

										
		}
		

	    //Build map grouping the rules by uniqueKeysubstr - Stripping off the Eff Date.
		 mUniqueKeySubStrToNewRules     = buildCustUniqueKeySubstrToRulesMap(newRules,-1,false);
		 mUniqueKeySubStrToExistingRules= buildCustUniqueKeySubstrToRulesMap(newRules,-1,true);
		 
			//Iterate over each unique key combination.
			//Get the new rules for that combination and respective existing rule if they exist.
			//Validate the new rule if it conflicts with existing rule date ranges.
                for(string uniquekeysubstr :mUniqueKeySubStrToNewRules.keyset())
                {
                	if(!mUniqueKeySubStrToExistingRules.containskey(uniquekeysubstr)){
                		continue;
                	}
                	list<Accounting_Rule__c> existingRules = new list<Accounting_Rule__c>(mUniqueKeySubStrToExistingRules.get(uniquekeysubstr));
                	list<Accounting_Rule__c> newRulesForUniqueKey      = new list<Accounting_Rule__c>(mUniqueKeySubStrToNewRules.get(uniquekeysubstr));
                	
                	
                	for(Accounting_Rule__c newRule :newRulesForUniqueKey)
                	{
                           list<string> errorMessages = new list<string>();
                           set<Accounting_Rule__c> ExistingRulesToBeEndDated = new set<Accounting_Rule__c>();
                           set<Accounting_Rule__c> FutureExistingRules = new set<Accounting_Rule__c>();
                           set<Accounting_Rule__c> overLappingExistingRules = new set<Accounting_Rule__c>();
                           
					       system.debug('inside Eff Dating validation--uniqueKeySubstr --'+uniqueKeySubstr);	   	  
					       system.debug('inside Eff Dating  validation--ExistingRules --'+ExistingRules);
					       system.debug('inside Eff Dating  validation--newRules --'+newRules);
                        
	                		for(Accounting_Rule__c existingRule :existingRules)
	                		{
	                			//Starting Eff Dating Validations.
		   			    	    system.debug('Existing Rule Name '+existingRule.name +'--Id--'+existingRule.Id);	
		   			    	    
						    	//At a time you can have one rule without end date.
						    	if(existingRule.Effective_End_Date__c == null && newRule.Effective_End_Date__c == null)
						    	{
						    		if(existingRule.Effective_Start_Date__c > newRule.Effective_Start_Date__c){
						    		   FutureExistingRules.add(existingRule);
                                       //errorMessages.add('Please enter end date as rule  <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a>  exists with future effectivity date. ');
								      // newRule.addError('Please enter end date as rule  <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a>  exists with future effectivity date',false);			    		
						    		}
						    		else{
                                       ExistingRulesToBeEndDated.add(existingRule) ;
                                       //errorMessages.add('Rule already exists: <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a> .Need to effective end date existing rule before creating new rule. ');
								      // newRule.addError('Rule already exists: <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a> .Need to effective end date existing rule before creating new rule. ',false);			    						    			
						    		}
 							    	system.debug('Inside Existing rule without endate and new rule WITHOUT Enddate' );				    				
                                   
						    	}
						    	//If new rule end date is not null, check  the new rule date range.
							    else if(existingRule.Effective_End_Date__c == null && newRule.Effective_End_Date__c != null && !(newRule.Effective_Start_Date__c < existingRule.Effective_Start_Date__c && newRule.Effective_End_Date__c <= existingRule.Effective_Start_Date__c))	
							    {
                                    ExistingRulesToBeEndDated.add(existingRule);
                                    //errorMessages.add('Rule already exists: <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a> .Need to effective end date existing rule before creating new rule. ');                                  
							    	//newRule.addError('Rule already exists: <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a> .Need to effective end date existing rule before creating new rule. ',false);
							    	system.debug('Inside Existing rule without endate and new rule WITH Enddate' );				    				
							    	
							    }
							    //If new rule end date is null,check the existing eff date range	
							    else if(newRule.Effective_End_Date__c==null && (newRule.Effective_Start_Date__c!=null) && !(newRule.Effective_Start_Date__c>existingRule.Effective_Start_Date__c && newRule.Effective_Start_Date__c>=existingRule.Effective_End_Date__c) )
							    {
                                    FutureExistingRules.add(existingRule);
                                    //errorMessages.add('Please enter end date as rule  <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a>  exists with future effectivity date.');                                  
								    //newRule.addError('Please enter end date as rule  <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a>  exists with future effectivity date',false);	
                                    system.debug('Inside Existing rule WITH endate and new rule WITHOUT Enddate' );				    				

							    }  
							    //If both existing and new rule have start and end date ,check if new rule range is either before or after existing rule range.Allow End and start date to be same.
							    else if(  !(newRule.Effective_End_Date__c==null) && (newRule.Effective_Start_Date__c!=null)
							       && !(newRule.Effective_End_Date__c<=existingRule.Effective_Start_Date__c && newRule.Effective_Start_Date__c<existingRule.Effective_Start_Date__c) 
								   && !(newRule.Effective_End_Date__c>existingRule.Effective_End_Date__c && newRule.Effective_Start_Date__c>=existingRule.Effective_End_Date__c))
								{	
									overLappingExistingRules.add(existingRule);
	                                //errorMessages.add(Label.Overlapping_Effective_Date_Range+' <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a>'+'.');                                  										
									//newRule.addError(Label.Overlapping_Effective_Date_Range+' <a href=\''+SFDCBaseURL+'/'+existingRule.Id+'\'>' + existingRule.name +' </a>'+'.',false);
									system.debug('Inside Overlap' );				    				
																		
								}  
								else
								{
									system.debug('No Validation Error' );				    												
								}   
   
                		}
                        
                        if(FutureExistingRules.size()>0)
                        {
                            String ErrorMsg = 'Please enter end date as rule(s) ';
                            list<string> ErrorRuleLinks = new list<string>();
                            for(Accounting_Rule__c FutureExistingRule :FutureExistingRules)
                            {
                                ErrorRuleLinks.add(' <a href=\''+SFDCBaseURL+'/'+FutureExistingRule.Id+'\'>' + FutureExistingRule.name +' </a>');
                            }
                            ErrorMsg = ErrorMsg+String.join(ErrorRuleLinks,',')+ ' exists with future effectivity date. ';
                            errorMessages.add(ErrorMsg);    
                        }
                        if(ExistingRulesToBeEndDated.size()>0)
                        {
                            String ErrorMsg = 'Rule(s) already exists: ';
                            list<string> ErrorRuleLinks = new list<string>();
                            for(Accounting_Rule__c ExistingRule1 :ExistingRulesToBeEndDated)
                            {
                                ErrorRuleLinks.add(' <a href=\''+SFDCBaseURL+'/'+ExistingRule1.Id+'\'>' + ExistingRule1.name +' </a>');
                            }
                            ErrorMsg = ErrorMsg+String.join(ErrorRuleLinks,',')+ ' Need to effective end date existing rule before creating new rule.  ';
                            errorMessages.add(ErrorMsg);    
                        }
                        if(overLappingExistingRules.size()>0)
                        {
                            String ErrorMsg = Label.Overlapping_Effective_Date_Range;
                            list<string> ErrorRuleLinks = new list<string>();
                            for(Accounting_Rule__c overLappingRule :overLappingExistingRules)
                            {
                                ErrorRuleLinks.add(' <a href=\''+SFDCBaseURL+'/'+overLappingRule.Id+'\'>' + overLappingRule.name +' </a>');
                            }
                            ErrorMsg = ErrorMsg+String.join(ErrorRuleLinks,',')+ '.';
                            errorMessages.add(ErrorMsg);    
                        }
                        if(errorMessages.size()>0)
                        {
                            String ErrorMsgCombined = String.join(errorMessages,'</br>');
                            newRule.addError(ErrorMsgCombined,false);                                
                        }

                		
                    }

                }
			
		
        if(mRulesWithEffDateChanging.size()>0)
	    {
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('accounting_entry_line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','accounting_rule__c', 'Company__r.Comp_Currency__c', 'Company__r.Comp_Currency__r.ISO_Code__c'
			});
			Set<Id> ruleIds = mRulesWithEffDateChanging.keyset();
			soql.setWhereClause('accounting_rule__c in :ruleIds');
			soql.setLimit(1);
			list<accounting_entry_line__c> AELsForRules = Database.query(soql.getQuery());

			if(AELsForRules.size()>0)
			{
			  for(accounting_entry_line__c AELRule :AELsForRules)
			  {
			  	  mRulesWithEffDateChanging.get(AELRule.accounting_rule__c).addError(Label.Cannot_change_effective_dates_once_transactions_have_been_recorded);		  		
			  }
			}	         	
	    }


		
	}
	 public static void validateNARules(list<Accounting_Rule__c> rulesInScope){	 	

	 	//Building the maps again and Not persisting the same as they have different grouping.
	 		 	
	   map<string,set<Accounting_Rule__c>> mUniqueKeySubstrToNewRules = new map<string,set<Accounting_Rule__c>>();
	   map<string,set<Accounting_Rule__c>> mUniqueKeySubStrToExistingRules = new map<string,set<Accounting_Rule__c>>();
	 	
	   system.debug('Current CPU time used in validateNARules before Map build--'+LIMITS.getCpuTime() + ' --Total Limt CPU Time-- '+LIMITS.getLimitCpuTime());
	   mUniqueKeySubstrToNewRules      = buildCustUniqueKeySubstrToRulesMap(rulesInScope,NUM_KEYS_BEFORE_RULETYPE,false);
	   mUniqueKeySubStrToExistingRules = buildCustUniqueKeySubstrToRulesMap(rulesInScope,NUM_KEYS_BEFORE_RULETYPE,true);
	   
	   system.debug('Current CPU time used in validateNARules after Map build--'+LIMITS.getCpuTime() + ' --Total Limt CPU Time-- '+LIMITS.getLimitCpuTime());
	   
	   
	   for(string uniqueKeySubstr :mUniqueKeySubstrToNewRules.keyset()){
	   	
	   	  if(!mUniqueKeySubStrToExistingRules.containskey(uniqueKeySubstr)){
	   	  	continue;
	   	  }
	   	
	   	  list<Accounting_Rule__c> ExistingRules = new list<Accounting_Rule__c>(mUniqueKeySubStrToExistingRules.get(uniqueKeySubstr));
	   	  list<Accounting_Rule__c> newRules      = new list<Accounting_Rule__c>(mUniqueKeySubstrToNewRules.get(uniqueKeySubstr));
	      
	      system.debug('inside NA validation--uniqueKeySubstr --'+uniqueKeySubstr);	   	  
	      system.debug('inside NA validation--ExistingRules --'+ExistingRules);
	      system.debug('inside NA validation--newRules --'+newRules);
	   	  
	     system.debug('Current CPU time used in validateNARules before nested for validation--'+LIMITS.getCpuTime() + ' --Total Limt CPU Time-- '+LIMITS.getLimitCpuTime());
	   	  
	   	  for(Accounting_Rule__c newRule:NewRules){
	   	  	 for(Accounting_Rule__c existingRule:ExistingRules){
			   			    	    
			    system.debug('Existing Rule Name '+existingRule.name +'--Id'+existingRule.Id);	
	   	  	    system.debug('Existing Rule Eff dates '+existingRule.effective_start_date__c+' '+existingRule.effective_end_date__c +' New Rule Dates '+ newRule.effective_start_date__c+' ' +newRule.effective_end_date__c);
	   	  	 	
	   	  	 	//Validate the RuleType
	   	  	 	if(existingRule.Rule_Type__c == 'NA' && newRule.Rule_Type__c != 'NA'){
	   	  	 		checkEffectiverange(existingRule,newRule,Label.DR_CR_Rule_overlapping_with_existing_NA_Rule);
	   	  	 	}
	   	  	 	else if(existingRule.Rule_Type__c != 'NA' && newRule.Rule_Type__c == 'NA'){
	   	  	 		checkEffectiverange(existingRule,newRule,Label.NA_Rule_overlapping_with_Existing_DR_CR_Rule);
	   	  	 	}
	   	  	 	
	   	  	 }
	     system.debug('Current CPU time used in validateNARules after nested for validation---'+LIMITS.getCpuTime() + ' --Total Limt CPU Time-- '+LIMITS.getLimitCpuTime());
	    	  	 
	   	  }
	   	
	   }

	 }
	 
	 public static void checkEffectiverange(Accounting_Rule__c ExistingRule,Accounting_Rule__c newRule,string ErrorMessage){
	 	
 		   	  	if(existingRule.effective_end_date__c == null && newRule.effective_end_date__c == null){//Both Rules withno end date
   	  	 		  	 newRule.addError(ErrorMessage);  	  	 				   	  	 			
   	  	 		}
   	  	 		else if(existingRule.effective_end_date__c == null && 
   	  	 		 !((existingRule.effective_start_date__c >  newRule.effective_start_date__c ) && (existingRule.effective_start_date__c >=  newRule.effective_end_date__c ))){//Check if not Future Existing Rule
   	  	 		  	 newRule.addError(ErrorMessage);  	  	 			
   	  	 		}
   	  	 		else if(newRule.effective_end_date__c == null && 
   	  	 		!((existingRule.effective_start_date__c <  newRule.effective_start_date__c ) && (existingRule.effective_end_date__c <=  newRule.effective_start_date__c ))){//Check if not Future New RUle
   	  	 		  	 newRule.addError(ErrorMessage );   	  	 			
   	  	 			
   	  	 		}
   	  	 		//Check if Existing rule is either past or future effective.
   	  	 		else if(existingRule.effective_end_date__c != null && newRule.effective_end_date__c != null&& !(existingRule.effective_start_date__c <  newRule.effective_start_date__c && existingRule.effective_end_date__c < = newRule.effective_start_date__c)
   	  	 		  && !(existingRule.effective_start_date__c >=  newRule.effective_end_date__c && existingRule.effective_end_date__c > newRule.effective_end_date__c)){
   	  	 		  	 newRule.addError(ErrorMessage);
   	  	 		 }
   	  	 	
	 }

	 //Validates the accounting rules reference in any AEL before deleting the rule.
     public static void checkAccountingRulesReference(Map<Id,Accounting_Rule__c> accRules){
     	Set<id> rulesIds = accRules.keySet();
        SOQLUtil soql = new SOQLUtil('Accounting_Rule__c', false); //enforceFLS=false
        soql.addFields(new set<string>{
            'Id'
        });
        soql.setWhereClause('Id in: rulesIds');
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entry_Lines__r');
        childRel.addFields(new set<string>{
            'Id'
        });
        childRel.setLimit(1);
        soql.addChildRelationship(childRel);
        List<Accounting_Rule__c> queriedaccRules = Database.query(soql.getQuery());
        for(Accounting_Rule__c ar: queriedaccRules){
            if(ar.Accounting_Entry_Lines__r != NULL && ar.Accounting_Entry_Lines__r.size() > 0){
                accRules.get(ar.Id).addError(Label.Cannot_delete_Accounting_Rule);
            }
        }
 
    }


	
}