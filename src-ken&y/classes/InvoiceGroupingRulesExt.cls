public with sharing class InvoiceGroupingRulesExt extends BaseController{
    public class IGRException extends Exception{}
    public String NewRuleMainFieldList = null;
    public string NamespaceUU { get { return KSE.NamespaceUU; }}
    public boolean isValid {get;set;}
    
    public String invGrpRule {get;set;}
    
    private static SchemaUtil util = SchemaUtil.getInstance();
    public Invoice_Grouping_Rule__c igrC{get
    { 
        if(igrC.Company__c==null){
        igrC = new Invoice_Grouping_Rule__c();
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

            igrC.Company__c =up != null ? up.default_company__c : null;
        }Catch(Exception e){
            
        }
    }
     return igrC;}
                                         set;}
    public  class InvoiceGroupingRule{
        public Invoice_Grouping_Rule__c  invoicegroupingrule{get;set;}
        public  integer rank{get;set;}
        public  integer sortorder{get;set;}
        public InvoiceGroupingRule(Invoice_Grouping_Rule__c b,integer r){
            this.invoicegroupingrule = b;
            rank = r;
            if(r<>null){
                sortorder =rank;
            }else{
                sortorder =99999;// set sort order to be maximum value for inactive rules
            }   
        }
        InvoiceGroupingRule(){}
    }
    public String getGroupBySOIf() {
    	list<SelectListItem> items = new list<SelectListItem>{new SelectListItem(null, '--None--')};
    	items.addAll(getPickListEntriesFromField('Group_By_Sales_Order_If__c'));
    	return JSON.serialize(items);
    	
    }
    public String getCustomerHierarchyDropDown() {
    	list<SelectListItem> items = new list<SelectListItem>{new SelectListItem(null, '--None--')};
    	items.addAll(getPickListEntriesFromField('Group_By_Customer_Hierarchy__c'));
    	return JSON.serialize(items);
    }
    
    private list<SelectListItem> getPickListEntriesFromField(string pickListField) {
    	list<SelectListItem> selectList = new list<SelectListItem>();
    	for(Schema.PicklistEntry pe : SchemaUtil.getInstance().getPickListEntriesFromField('Invoice_Grouping_Rule__c', pickListField)) {
    		if (pe.isActive()) {
                    selectList.add(new SelectListItem(pe));
             }
    	}
    	
    	return selectList;
    }
    
    public GridRelatedListController.GridRelatedListConfig KendoSampleGridConfig {get; set;}
    public String igrFieldList ;
    
    
    public String selectedOption {get;set;}
    public InvoiceGroupingRulesExt()
    {
        invGrpRule = JSON.Serialize(new Invoice_Grouping_Rule__c());
        igrC = new Invoice_Grouping_Rule__c();
        user_preference__C up;
        try{
        	
			SOQLUtil soql = new SOQLUtil('user_preference__C', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'default_company__c','id'
			});
			soql.setWhereClause('');
			soql.setLimit(1);    
			up = Database.query(soql.getQuery());        	

            igrC.Company__c =up != null ? up.default_company__c : null;
        }Catch(Exception e){
            
        }
        
        selectedOption = 'R';
        KendoSampleGridConfig = new GridRelatedListController.GridRelatedListConfig();
        KendoSampleGridConfig.uniqueId = 'kendoSampleGrid1';
        KendoSampleGridConfig.title = 'Invoice Grouping Rule';
        KendoSampleGridConfig.objectName = 'Invoice_Grouping_Rule__c';
        KendoSampleGridConfig.fieldset = 'Invoice_Grouping_Rule_fieldSet';
        //KendoSampleGridConfig.buttons = 'cancel, delete';
        KendoSampleGridConfig.alwaysUseFullDateTimeFormat = false;
        
        
        
    }
    
    
    public String getigrFieldList() {
        if (String.isBlank(igrFieldList) && KendoSampleGridConfig != null) {
            // get the credit memo field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            // get the Payment line details field info list
            FieldInfo selectFieldInfoItem = new FieldInfo();
            selectFieldInfoItem.field = 'rank';
            selectFieldInfoItem.title = 'Rank';
            selectFieldInfoItem.fieldtype = 'integer';
            selectFieldInfoItem.filterable=true;
            //       selectFieldInfoItem.editable = true;
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
                    fieldInfoList[i].field = 'invoicegroupingrule.' + fieldName;
                    fieldInfoList[i].filterable=true;
                }
                if (fieldInfoList[i].field == 'invoicegroupingrule.rank__c'  || fieldInfoList[i].field == 'invoicegroupingrule.company__C' ){
                    fieldInfoList[i].hidden = true;
                }  	
                if(fieldName.equalsIgnoreCase('is_active__c' )){
                    fieldInfoList[i].width = 100;    
                }
                if(fieldname.contains('Rule_Description__c')){
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
            
            igrFieldList = JSON.serialize(fieldInfoList);
        }
        
        return igrFieldList;
    }
    
    public String getIgrGridConfigJson() {
        String configStr = JSON.serialize(this.KendoSampleGridConfig);
        return configStr;
    }
    
    @RemoteAction
    public static JsonResult getIGRs(String company){
        SchemaUtil shUtil = new SchemaUtil();
        List<InvoiceGroupingRule > igrList= new List<InvoiceGroupingRule > ();
        integer ct=1;
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Invoice_Grouping_Rule__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','rank__C','name','End_Date__c','start_Date__c','company__C','is_active__C','Rule_Description__c'
		});
		soql.setWhereClause('company__c =:company');
		soql.setOrderByClause('rank__C asc NULLS LAST');
		for(Invoice_Grouping_Rule__c igrule: Database.query(soql.getQuery())){
			
		    if (igrule.Is_Active__c==true) {
		        if (igrule.rank__C==null) {
		            igrList.add(new InvoiceGroupingRule(igrule,ct));
		            ct= ct+1;
		        } else {        
		            // igrList.add(new InvoiceGroupingRule(igrule,Integer.valueOf(igrule.rank__C)));
		            igrList.add(new InvoiceGroupingRule(igrule,Integer.valueOf(ct)));
		            // ct = Integer.valueOf(igrule.rank__C) +1;
		            ct= ct+1;
		        }
		    } else {
		        igrList.add(new InvoiceGroupingRule(igrule,null));
		    }
		}

		JsonResult result = new JsonResult();
		result.records = igrList;
		result.total = igrList.size();
		return result;   
    }

    @RemoteAction
    public static DataSourceResult saveIgrs(List<InvoiceGroupingRule>  igrList, List<String> dateFields) {
        
        DataSourceResult result = new DataSourceResult();
        try{
            if (igrList.size() > 0) {
                for (InvoiceGroupingRule line : igrList) {
                    KendoUtils.UpdateDateFields(line.invoicegroupingrule, dateFields); //Kendo passes empty dates with the a default value. This method will truly store it as a null.
                }
            }
            List<Invoice_Grouping_Rule__c > igrListToSave= new List<Invoice_Grouping_Rule__c > ();
            set<integer> checkDuplicates = new  set<integer> ();
            for(InvoiceGroupingRule ig :  igrList ){
                if(ig.invoicegroupingrule.is_active__c==true ){
                    if( checkDuplicates.contains(ig.rank)){
                        result.success =false;
                        throw new IGRException('Found Duplicate Rank.');
                    }else{
                        ig.InvoiceGroupingRule.rank__C= ig.rank;
                        igrListToSave.add(ig.InvoiceGroupingRule);
                        checkDuplicates.add(ig.rank);
                    }
                }
            }
		  InvoiceGroupingRuleService.requestFromUI = true;	 //KNDY-15790
          DML.updateSobjectList(igrListToSave);
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
    public static DataSourceResult deleteIgrs(List<InvoiceGroupingRule>  igrList, List<String> dateFields) {
        
        DataSourceResult result = new DataSourceResult();
        try{
            
            List<Invoice_Grouping_Rule__c > igrListTodelete= new List<Invoice_Grouping_Rule__c > ();
            set<integer> checkDuplicates = new  set<integer> ();
            for(InvoiceGroupingRule ig :  igrList ){
                igrListTodelete.add(ig.InvoiceGroupingRule);
            } 
         
           DML.deleteAsUser(igrListTodelete);
            result.success=true;
            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
        }catch(Exception ex){
            result.addMessage('Cannot Delete Records.'+ex.getMessage(), ApexPages.Severity.ERROR);
            result.success =false;
            return result;
        }
        return result;
    }
    
    
    @RemoteAction
    public static JsonResult getRule(Id ruleId) {
        
        String objectName = 'Invoice_Grouping_Rule__c';
        Set<String> addlFields = new set<String> {'For_Customers__c', 'For_Agreements__c','For_Categories__c','For_Products__c','Billing_UOM__c','Recurrence_Start_Date__c','Use_Billing_Frequency_on_Fulfillment__c'};
        string whereClause = 'id = :ruleId';
        
        SOQLUtil soql = new SOQLUtil(objectName,true);
	    soql.addFields('Header_FieldSet');
	    soql.addFields('Grouping_FieldSet');
	    soql.addFields('Additional_FieldSet');
	    soql.addFields(addlFields);
	    soql.setWhereClause(whereClause);
	    
        List<Invoice_Grouping_Rule__c> rules = (ruleId == null) ? new List<Invoice_Grouping_Rule__c>() : Database.query(soql.getQuery());   
        JsonResult result = new JsonResult();
        result.records = rules;
        result.total = rules.size();
        return result;  
        
    }
    
    @RemoteAction
    public static JSONResult upsertRule(List<Invoice_Grouping_Rule__c> groupingObjList) { 
        
        System.debug(logginglevel.info,'Inside the Upsert Rule... Action');
        List<Invoice_Grouping_Rule__c> processedgGrpObjList = new List<Invoice_Grouping_Rule__c>();
        JSONResult result = new JSONResult();
        List<String>  dateFields= new  List<String>{'Start_Date__c' ,'End_Date__c','Recurrence_Start_Date__c'};
        
        try {
            
             KendoUtils.UpdateDateFields(groupingObjList.get(0), dateFields); //one IGR would be there anytime
             processedgGrpObjList = InvoiceGroupingRuleService.generateRuleDescription(groupingObjList);
             system.debug(LoggingLevel.ERROR, 'processedgGrpObjList '+processedgGrpObjList);
     		 InvoiceGroupingRuleService.requestFromUI = true;	 //KNDY-15790
             DML.checkUpsertAsUser(processedgGrpObjList); upsert processedgGrpObjList;
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
        
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Invoice_Grouping_Rule__c', 'Header_FieldSet');
        fieldInfoList.remove(0); //remove ID
        List<FieldInfo> hfieldinfolist = new List<FieldInfo>();
        for(FieldInfo f:fieldInfoList){
            if(f.field.contains('start')||f.field.contains('interval')||f.field.contains('Company') ){
                f.required = true;
            }
            hfieldinfolist.add(f);
        }
        RuleHeaderFieldList = JSON.serialize(fieldInfoList);
        return RuleHeaderFieldList;
    }
    
    public string getRuleGroupingFieldList() {
        String RuleGroupingFieldList = '';
        
        
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Invoice_Grouping_Rule__c', 'Grouping_FieldSet');
        fieldInfoList.remove(0); //remove ID
        RuleGroupingFieldList = JSON.serialize(fieldInfoList);
        return RuleGroupingFieldList;
    }
    
    public string getRuleAdditionalFieldList() {
        String RuleAdditionalFieldList = '';
        try {
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Invoice_Grouping_Rule__c', 'Additional_FieldSet');
            fieldInfoList.remove(0); //remove ID
            RuleAdditionalFieldList = JSON.serialize(fieldInfoList);
        }catch (FieldInfo.EmptyFieldSetMemberException e) {
            RuleAdditionalFieldList = '';
        }
        
        return RuleAdditionalFieldList;
    }
    
    @remoteAction 
    public static JSONResult fetchHelpText(String f){ //KNDY-8594
        f= KSE.NamespaceUU+f;
        JSONResult result = new JSONResult();
        result.success=false;
        if(f.length() >0){
            string[] s=f.split('\\.');
            f= s[0];
            f=   f.replace('__r','__c');
             Schema.SObjectType igrschema=       Invoice_Grouping_rule__C.sObjectType;
            Map<String, Schema.SObjectField> fieldMap = igrschema.getDescribe().fields.getMap();
            result.message= fieldMap.get(f).getDescribe().getInlineHelpText();
            if(result.message=='' ||result.message==null ){
                result.message = fieldMap.get(f).getDescribe().Label ;
            }
            result.success=true;
        }else     {    
            result.success=false;
        }
        return result;
    }
    
    //KNDY-15790
     @RemoteAction
    public static JsonResult IsIGRUsedForInvoicing(Id ruleId) {
    	JsonResult result = new JsonResult();
    	try{
	    	if(ruleId != null){
	    		list<Customer_Invoice__c> lstCI = new list<Customer_Invoice__c>();
		        SOQLUtil soql = new SOQLUtil('Customer_Invoice__c',true);
			    soql.addFields(new set<string>{'Id'});
			    soql.setWhereClause('Matches_To_Grouping_Rule__c = :ruleId');
			    soql.setLimit(1);  
		    	lstCI = Database.query(soql.getQuery());
	        	result.total = lstCI.size();
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