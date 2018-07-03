public class BankTransactionMatchingRulesExt extends BaseController {  
    
    public Apexpages.Standardcontroller con {get;set;}
    public class BTMRException extends Exception{}
    public String NewRuleMainFieldList = null;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    private static SchemaUtil util = SchemaUtil.getInstance();
    
    public Transaction_Matching_Rule__c tmrule{get
        { if(tmrule.Company__c==null){
            tmrule = new Transaction_Matching_Rule__c();
            user_preference__C up;
            try{
                //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                SOQLUtil soql = new SOQLUtil('user_preference__C', true); //enforceFLS=true, running in user mode
                soql.addFields(new set<string>{
                    'default_company__c','id'
                });
                soql.setWhereClause('');
                soql.setLimit(1);    
                up = Database.query(soql.getQuery());
    
                tmrule.Company__c =up != null ? up.default_company__c : null;
            }Catch(Exception e){
                
            }
        }
        return tmrule;} set;}
    
    public  class BankTransactionMatchingRule{ 
        public Transaction_Matching_Rule__c  banktransactionmatchingrule {get;set;}
        public  Integer rank {get;set;}
        public  Integer sortorder {get;set;}
        BankTransactionMatchingRule(Transaction_Matching_Rule__c tmr,Integer intValue){
            this.banktransactionmatchingrule = tmr;
            rank = intValue;
            if(intValue <> null){
                sortorder = rank;
            }else{
                sortorder = 99999;// set sort order to be maximum value for inactive rules
            }   
        }
        BankTransactionMatchingRule(){}
    }
    
    public GridRelatedListController.GridRelatedListConfig KendoSampleGridConfig {get; set;}
    public String btmrFieldList;
    
    
    public String selectedOption {get;set;}
    public BankTransactionMatchingRulesExt() 
    {
        //EMPTY CONSTRUCTOR
    }
    public BankTransactionMatchingRulesExt(ApexPages.standardController controller)
    {
        tmrule = new Transaction_Matching_Rule__c();
        user_preference__C up;
        try{
        	
			SOQLUtil soql = new SOQLUtil('User_Preference__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'default_company__c','id'
			});
			soql.setWhereClause('');
			soql.setLimit(1);    
			up = Database.query(soql.getQuery());        	

            tmrule.Company__c = up != null ? up.default_company__c : null;
        }Catch(Exception e){
            
        }
        
        con = controller;
        selectedOption = 'R';
        KendoSampleGridConfig = new GridRelatedListController.GridRelatedListConfig();
        KendoSampleGridConfig.uniqueId = 'kendoSampleGrid1';
        KendoSampleGridConfig.title = Label.Bank_Transaction_Match_Rules;
        KendoSampleGridConfig.objectName = 'Transaction_Matching_Rule__c';
        KendoSampleGridConfig.fieldset = 'BT_Matching_Rules';
        KendoSampleGridConfig.buttons = 'search';
        KendoSampleGridConfig.alwaysUseFullDateTimeFormat = false;
    }
    
    
    public String getbtmrFieldList() {
        if (String.isBlank(btmrFieldList) && KendoSampleGridConfig != null) {
            // get the credit memo field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            // get the Payment line details field info list
            FieldInfo selectFieldInfoItem = new FieldInfo();
            selectFieldInfoItem.field = 'rank';
            selectFieldInfoItem.title = 'Rank';
            selectFieldInfoItem.fieldtype = 'integer';
            selectFieldInfoItem.filterable=true;
            //selectFieldInfoItem.editable = true;
            selectFieldInfoItem.width = 80;
            fieldInfoList.add(selectFieldInfoItem);
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos(KendoSampleGridConfig.objectName, KendoSampleGridConfig.fieldset));

            FieldInfo selectFieldInfoItem1 = new FieldInfo();
            selectFieldInfoItem1.field = 'sortorder';
            selectFieldInfoItem1.title = 'sortorder';
            selectFieldInfoItem1.fieldtype = 'integer';
            selectFieldInfoItem.editable = true;
            selectFieldInfoItem1.hidden=true;
            fieldInfoList.add(selectFieldInfoItem1);
            for(Integer i = 1; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].editable = false;
            }
            
            for(Integer i = 1; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                if(!(fieldName == 'rank' || fieldName == 'sortorder') ){
                    fieldInfoList[i].field = 'banktransactionmatchingrule.' + fieldName;
                    fieldInfoList[i].filterable=true;
                }
                if (fieldInfoList[i].field == 'banktransactionmatchingrule.rank__c'  || fieldInfoList[i].field == 'banktransactionmatchingrule.company__c' ){
                    fieldInfoList[i].hidden = true;
                }  	
                if (fieldInfoList[i].field == 'banktransactionmatchingrule.company__r.Name'){
                    fieldInfoList[i].hidden = true;
                }
                if(fieldName.equalsIgnoreCase('Is_Active__c' )){
                    fieldInfoList[i].width = 100;    
                }
                if(fieldname.contains('Description__c')){
                    fieldInfoList[i].width = 500;
                } 
                if(fieldname.contains('Date')){
                    fieldInfoList[i].width = 125;
                }
                if(fieldname.contains('Name')){
	              	fieldInfoList[i].width = 120;
                	fieldInfoList[i].title = 'Rule Name';
                }
            }
            system.debug('****fieldInfoList*****'+fieldInfoList);
            btmrFieldList = JSON.serialize(fieldInfoList);
        }
        
        return btmrFieldList;
    }
    
    public String getBTMrGridConfigJson() {
        String configStr = JSON.serialize(this.KendoSampleGridConfig);
        return configStr;
    }
    
    @RemoteAction
    public static JsonResult getBTMRs(){
        SchemaUtil shUtil = new SchemaUtil();
        List<BankTransactionMatchingRule> btmrList = new List<BankTransactionMatchingRule> ();
        Integer ct = 1;
		//string bid = bankId;
        //string cId = companyId;
		//Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Transaction_Matching_Rule__c', true); //enforceFLS=true, running in user mode
		soql.addFields('BT_Matching_Rules');
        soql.addFields(new Set<String>{'Name'});
		//soql.setWhereClause('(company__c = :cid or Company__c = null) and (Bank_Account__c = :bid or Bank_Account__c = null)');
		//soql.setWhereClause('(company__c = :cid)');
		soql.setOrderByClause('Rank__c asc NULLS LAST');
        System.debug(logginglevel.info,'Query-->>'+soql.getQuery());
                              
		for(Transaction_Matching_Rule__c btmrule: Database.query(soql.getQuery())){
			
		    if (btmrule.Is_Active__c==true) {
		        if (btmrule.rank__C==null) {
		            btmrList.add(new BankTransactionMatchingRule(btmrule,ct));
		            ct = ct+1;
		        } else {        
					btmrList.add(new BankTransactionMatchingRule(btmrule,Integer.valueOf(ct)));
					ct = ct+1;
		        }
		    } else {
		        btmrList.add(new BankTransactionMatchingRule(btmrule,null));
		    } 
		}

		JsonResult result = new JsonResult();
		result.records = btmrList;
		result.total = btmrList.size();
		return result;   
    }
   
    @RemoteAction
    public static DataSourceResult saveBTMRs(List<BankTransactionMatchingRule>  btMRList, List<String> dateFields) {
        
        DataSourceResult result = new DataSourceResult();
        try{
            if (btMRList.size() > 0) {
                for (BankTransactionMatchingRule line : btMRList) {
                    KendoUtils.UpdateDateFields(line.banktransactionmatchingrule, dateFields); //Kendo passes empty dates with the a default value. This method will truly store it as a null.
                }
            }
            List<Transaction_Matching_Rule__c > btmrListToSave = new List<Transaction_Matching_Rule__c > ();
            set<integer> checkDuplicates = new  set<integer> ();
            for(BankTransactionMatchingRule btm :  btMRList ){
                if(btm.banktransactionmatchingrule.Is_Active__c==true ){
                    if( checkDuplicates.contains(btm.rank)){
                        result.success =false;
                        throw new BTMRException('Found Duplicate Rank.');
                    }else{
                        btm.banktransactionmatchingrule.rank__c= btm.rank;
                        btmrListToSave.add(btm.banktransactionmatchingrule);
                        checkDuplicates.add(btm.rank);
                    }
               }
            }
			BankTransactionMatchingRuleService.requestFromUI = true;	 //KNDY-15794
            DML.updateSobjectList(btmrListToSave);
            result.success=true;
            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
        }catch(Exception ex){
            String errorMessage = ex.getMessage();
            Integer occurence;
            if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                occurence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                errorMessage = errorMessage.mid(occurence, errorMessage.length());
                occurence = errorMessage.lastIndexOf(':');
                errorMessage = errorMessage.mid(0, occurence);
            }
            else {
                errorMessage = ex.getMessage();
            }
            result.addMessage(errorMessage, ApexPages.Severity.ERROR);
            result.success =false;
            return result;
        }
        return result; 
    }
       
    @RemoteAction
    public static JsonResult getRule(Id ruleId) {
        
        String objectName = 'Transaction_Matching_Rule__c';
        Set<String> addlFields = null;
        string whereClause = 'id = :ruleId FOR UPDATE';

        SOQLUtil soql = new SOQLUtil(objectName);
	    soql.addFields('Header_FieldSet');
	    soql.addFields('Matching_Fieldset');
	    soql.addFields('Additional_FieldSet');
        soql.addFields(new Set<String>{'Name'}); 
	    soql.setWhereClause(whereClause);
	    
        List<Transaction_Matching_Rule__c> rules = ruleId == null ? new list<Transaction_Matching_Rule__c>() : Database.query(soql.getQuery());   
        
        JsonResult result = new JsonResult();
        result.records = rules;
        result.total = rules.size();
        return result;  
        
    }
    
    @RemoteAction
    public static JSONResult upsertRule( List<Transaction_Matching_Rule__c> lBTMRs, List<String> dateFields) {
        
        JSONResult result = new JSONResult();
        
        try {
            KendoUtils.UpdateDateFields(lBTMRs.get(0), dateFields); //Kendo passes empty dates with the a default value. This method will truly store it as a null. 
            system.debug('lBTMRs '+lBTMRs);
            for(Transaction_Matching_Rule__c tmr : lBTMRs ){
                tmr.Date_Threshold__c = (tmr.Date_Threshold__c != null ? tmr.Date_Threshold__c.round(System.RoundingMode.HALF_UP):0) ;
            }
            BankTransactionMatchingRuleService.requestFromUI = true;	 //KNDY-15794
            DML.checkUpsertAsUser(lBTMRs); upsert lBTMRs;
            result.success = true;
            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
            
        }catch(Exception ex) {
            
            String errorMessage = ex.getMessage();
            Integer occurence;
            if (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                occurence = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 34;
                errorMessage = errorMessage.mid(occurence, errorMessage.length());
                occurence = errorMessage.lastIndexOf(':');
                errorMessage = errorMessage.mid(0, occurence);
            }
            else {
                errorMessage = ex.getMessage();
            }
            result.addMessage(errorMessage, ApexPages.Severity.ERROR);
            result.success =false;
            return result;
        }
        return result;
    }
    
    public string getRuleHeaderFieldList() {
        String RuleHeaderFieldList = '';
        
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Transaction_Matching_Rule__c', 'Header_FieldSet');
        fieldInfoList.remove(0); //remove ID
        List<FieldInfo> hfieldinfolist = new List<FieldInfo>();
        for(FieldInfo f:fieldInfoList){
            if(f.field.contains('Start') || f.field.contains('Documents') ){
                f.required = true;
            }
            hfieldinfolist.add(f);
        }
        RuleHeaderFieldList = JSON.serialize(fieldInfoList);
        return RuleHeaderFieldList;
    }
    
    public string getRuleMatchingFieldList() {
        String RuleMatchingFieldList = '';
        
        
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Transaction_Matching_Rule__c', 'Matching_Fieldset');
        fieldInfoList.remove(0); //remove ID
        RuleMatchingFieldList = JSON.serialize(fieldInfoList);
        return RuleMatchingFieldList;
    }
    
    public string getRuleAdditionalFieldList() {
        String RuleAdditionalFieldList = '';
        try {
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Transaction_Matching_Rule__c', 'Additional_FieldSet');
            fieldInfoList.remove(0); //remove ID
            RuleAdditionalFieldList = JSON.serialize(fieldInfoList);
        }catch (FieldInfo.EmptyFieldSetMemberException e) {
            RuleAdditionalFieldList = '';
        }
        return RuleAdditionalFieldList;
    }
    //KNDY-16113
    @RemoteAction
    public static JSONResult getCompanyInfoFromBank(id selectedBankId) { 
		JSONResult result = new JSONResult();
		List<Bank_Account__c> bankAccountList = new List<Bank_Account__c>();
		try{
			system.debug('selectedBankId='+selectedBankId + '=' + String.isEmpty(selectedBankId));
			if (!String.isEmpty(selectedBankId)) {
				SOQLUtil soql = new SOQLUtil('Bank_Account__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Company__c','Company__r.Name'
				});		
				soql.setWhereClause('id = :selectedBankId');
				soql.setLimit(1);
				bankAccountList = Database.query(soql.getQuery());	
				
				if (!bankAccountList.isEmpty() ){					
					result.success = true;
					result.records = bankAccountList;
				}				
			}else{
				result.success = false;
				result.addMessage(Label.No_records_found, ApexPages.Severity.ERROR);
			}
		}catch (Exception ex) {
            String errorMessage = ex.getMessage();
            result.success = false;
            result.addMessage(errorMessage, ApexPages.Severity.ERROR);
        }
        return result;
    }
    
	//KNDY-15794
	@RemoteAction
    public static JsonResult IsBTMRuleUsedForAutoMatch(Id ruleId) {
    	JsonResult result = new JsonResult();
     	try{
 	    	if(ruleId != null){
 	    		list<Bank_Transaction_Match__c> lstBTM = new list<Bank_Transaction_Match__c>();
 		        SOQLUtil soql = new SOQLUtil('Bank_Transaction_Match__c',true);
 			    soql.addFields(new set<string>{'Id'});
 			    soql.setWhereClause('Transaction_Mathching_Rule__c = :ruleId');
 			    soql.setLimit(1);  
 		    	lstBTM = Database.query(soql.getQuery());
 	        	result.total = lstBTM.size();
 	        	result.success = true;
 	    	}else{
 	    		result.success = false;
 	    	}
     	}catch(exception ex){
     		result.success = false;
     		result.message = ex.getMessage();
     	}
         return result;    
	}
}