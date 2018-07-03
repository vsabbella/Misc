public with sharing class OnDemandInvoiceGenerateExt extends GridRelatedListController {
	
	public String invoiceHoldFieldList ;
	public GridRelatedListController.GridRelatedListConfig invoiceHoldGridConfig {get; set;}
	
	public String releaseHoldFieldList ;
	public GridRelatedListController.GridRelatedListConfig releaseHoldGridConfig {get; set;}
	
	private static InvoiceGroupingRuleService igrUtil = InvoiceGroupingRuleService.getInstance(); 
	public static boolean bypassDuplicateCheck = false; // flag to bypass the duplicate IGR check, for the process fulfillments
	public string nspace { get { return KSE.Namespace; }}
	public Id defaultCompany{ get; set;} 

	
	
	public String getinvoiceHoldGridConfigJson() {
        String configStr = JSON.serialize(this.invoiceHoldGridConfig);
        return configStr;
    }
    
    public String getreleaseHoldGridConfigJson() {
        String configStr = JSON.serialize(this.releaseHoldGridConfig);
        return configStr;
    }
    
    public string getRuleGroupingFieldList() {
        String RuleGroupingFieldList = '';
        Set<String> hiddenFields = new Set<String> {'id'};
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Invoice_Grouping_Rule__c', 'OndemandInvoiceGenerate');
        fieldInfoList.remove(0); 
        RuleGroupingFieldList = JSON.serialize(fieldInfoList);
        return RuleGroupingFieldList;
    }
    
	public OnDemandInvoiceGenerateExt(ApexPages.StandardSetController setController) {
	    
	    Id userId = UserInfo.getUserID();
        if(String.isBlank(userId) == false){
            SOQLUtil soql = new SOQLUtil('User_Preference__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','Default_Company__c'
            });
            soql.setWhereClause('ownerId = :userId');
            soql.setLimit(1);
    
            List<User_Preference__c> u = Database.query(soql.getQuery());
            if (u != null && u.size() > 0){
                if(u[0].Default_Company__c != null)     
                    defaultCompany = u[0].Default_Company__c;  
            }
            System.debug(logginglevel.error,'defaultCompany--->'+defaultCompany);
         }
         
	 	invoiceHoldGridConfig = new GridRelatedListController.GridRelatedListConfig();
        invoiceHoldGridConfig.uniqueId = 'invoiceHoldGrid';
        invoiceHoldGridConfig.title = 'Fulfillments';
        invoiceHoldGridConfig.objectName = 'Fulfillment__c';
        invoiceHoldGridConfig.fieldset = 'InvoicingAndHold';
        invoiceHoldGridConfig.buttons = 'search';
        invoiceHoldGridConfig.alwaysUseFullDateTimeFormat = false;
        
        releaseHoldGridConfig = new GridRelatedListController.GridRelatedListConfig();
        releaseHoldGridConfig.uniqueId = 'releaseHoldGrid';
        releaseHoldGridConfig.title = 'Fulfillments';
        releaseHoldGridConfig.objectName = 'Fulfillment__c';
        releaseHoldGridConfig.fieldset = 'ReleaseHold';
        releaseHoldGridConfig.buttons = 'search';
        releaseHoldGridConfig.alwaysUseFullDateTimeFormat = false;
	}
	 	
	public String getReturnUrl(){
		PageReference pageRef;
        Schema.DescribeSObjectResult dsr = Fulfillment__c.SObjectType.getDescribe();
        pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        
        
        return pageRef.getUrl();	
	}
	 public OnDemandInvoiceGenerateExt(ApexPages.StandardController controller) {
	 }
	 
	 public String getinvoiceHoldFieldList() {
        if (String.isBlank(invoiceHoldFieldList) && invoiceHoldGridConfig != null) {
        	
        	Set<String> hiddenFields = new Set<String> { 'Id'};
			//List<FieldInfo> fulfillmentFieldInfoList = FieldInfo.fetchJsonFieldInfos('Fulfillment__c', 'InvoicingAndHold');
        	
			List<FieldInfo> fulfillmentFieldInfoList = fetchJsonFieldInfosWithReferenceToObectTitle('Fulfillment__c', 'InvoicingAndHold');
			System.debug(logginglevel.error,'fulfillmentFieldInfoList---->'+fulfillmentFieldInfoList);
			
        	for(Integer i = 0; i < fulfillmentFieldInfoList.size(); i++){
            	fulfillmentFieldInfoList[i].editable = false;
            	fulfillmentFieldInfoList[i].filterable = true;
            }
            
        	invoiceHoldFieldList = JSON.serialize(fulfillmentFieldInfoList);
        	System.debug(logginglevel.error,'invoiceHoldFieldList---->'+invoiceHoldFieldList);
        	
        }
        
        return invoiceHoldFieldList;
    }
    
     public String getreleaseHoldFieldList() {
        if (String.isBlank(releaseHoldFieldList) && releaseHoldGridConfig != null) {
        	
        	Set<String> hiddenFields = new Set<String> { 'Id'};
        	//List<FieldInfo> fulfillmentFieldInfoList = FieldInfo.fetchJsonFieldInfos('Fulfillment__c', 'ReleaseHold');
        	
        	List<FieldInfo> fulfillmentFieldInfoList = fetchJsonFieldInfosWithReferenceToObectTitle('Fulfillment__c', 'ReleaseHold');
        	for(Integer i = 0; i < fulfillmentFieldInfoList.size(); i++){
            	fulfillmentFieldInfoList[i].editable = false;
            	fulfillmentFieldInfoList[i].filterable=true;
            }
            
        	releaseHoldFieldList = JSON.serialize(fulfillmentFieldInfoList);
        }
        
        return releaseHoldFieldList;
    }
    
    /*
        Utility code to fetch JSON structure of field infos for a given object and fieldset, with referenced objects prefixing the 
        field labels on the title of field.
    */    
    public static List<FieldInfo> fetchJsonFieldInfosWithReferenceToObectTitle(String objectName, String fieldSetName) {
    
	    List<FieldInfo> fieldInfoList = new List<FieldInfo>();
	    SchemaUtil util = SchemaUtil.getInstance();
		Schema.SObjectType objectType = util.getGlobalDescribe(objectName); //'Fulfillment__c'
		
		Map<String, sObjectField> fieldMap = objectType.getDescribe().fields.getMap(); 
		System.debug(logginglevel.error,fieldMap);
		
		List<Schema.FieldSetMember> fieldSetMemberList = util.getFieldsFromFieldSet(objectType, fieldSetName); // 'InvoicingAndHold'
		for (Schema.FieldSetMember fsm : fieldSetMemberList) {
		    string field = fsm.getFieldPath();
		    FieldInfo fi = new FieldInfo();
		    System.debug(logginglevel.error,'field--1->'+field);
		    
		    if (field.contains('__r')) {
		         
		         String[] refFieldName = field.split('\\.');
		         System.debug(logginglevel.error,refFieldName[0]);
		         Schema.DescribeFieldResult dfr = fieldMap.get(refFieldName[0].replace('__r','__c')).getDescribe();
		         System.debug(logginglevel.error,dfr.getRelationshipName());
		         
		         for(Schema.SObjectType reference : dfr.getReferenceTo()) {
				   System.debug(logginglevel.error,'Lookup reference object name: ' + reference.getDescribe().getName());
				   System.debug(logginglevel.error,'Lookup reference object label: ' + reference.getDescribe().getLabel());
                   field = fsm.getFieldPath().replace(KSE.NamespaceUU, '');
                   System.debug(logginglevel.error,'field--2-->>'+field);
                   String title = reference.getDescribe().getLabel() +' - '+ fsm.getLabel();
                   System.debug(logginglevel.error,'Type--->'+fsm.getType());
                   fi = new FieldInfo(field, title, String.valueOf(fsm.getType()).toLowerCase());
				 }
		    }
		    else if(fieldMap.containsKey(field)){
                
                Schema.DescribeFieldResult dfr = fieldMap.get(field).getDescribe();
                fi = FieldInfo.getFieldInfo(dfr);
            }
            fieldInfoList.add(fi);
		} 
	   return fieldInfoList;
    }		
    
    @RemoteAction
	public static JsonResult getFulfillments(Id companyId, list<Id> customerIds, list<Id> agreementIds, list<Id> salesOrderIds, list<Id> shipmentIds, list<Id> productIds, list<Id> categoryIds){
		DateTime timeNow = system.now();
		string immediate = FrequencyService.FREQUENCY_PERIOD_IMMEDIATE;
		string  allowanceAccrual = AllowanceRuleService.ALLOWANCE_ACCRUAL;
		list<String> queryFilters = new list<String>();
		if(companyId != null)
			queryFilters.add('Company__c = :companyId');
		if(customerIds != null && !customerIds.isEmpty())
			queryFilters.add('Customer__c in :customerIds');
		if(agreementIds != null && !agreementIds.isEmpty())
			queryFilters.add('Agreement_Line__r.Agreement__c in :agreementIds');
		if(salesOrderIds != null && !salesOrderIds.isEmpty())
			queryFilters.add('Sales_Order_Line__r.Sales_Order__c in :salesOrderIds');
		if(shipmentIds != null && !shipmentIds.isEmpty())
			queryFilters.add('Shipment_Line__r.Shipment__c in :shipmentIds');
		if(productIds != null && !productIds.isEmpty())
			queryFilters.add('Product__c in :productIds');
		if(categoryIds != null && !categoryIds.isEmpty())
			queryFilters.add('Category__c in :categoryIds');
		
		String whereClause = igrUtil.getWhereClause();
		whereClause += queryFilters.isEmpty() ? '' : ' and '+String.join(queryFilters,' AND ');
		whereClause = whereClause.replace('and Invoice_Ready__c = true','');
		
		JsonResult result = new JsonResult();
		result.success = true;
		
		SOQLUtil soql = new SOQLUtil('Fulfillment__c');
	    soql.addFields('InvoicingAndHold');
	    soql.addFields(new Set<String> {'Company__c'});
	    soql.setWhereClause(whereClause);
	    
		result.records = Database.query(soql.getQuery());
		return result;  
	}
	
	@RemoteAction
	public static JsonResult getFulfillmentsForRelease(Id companyId, list<Id> customerIds, list<Id> agreementIds, list<Id> salesOrderIds, list<Id> shipmentIds, list<Id> productIds, list<Id> categoryIds){
		DateTime timeNow = system.now();
		list<String> queryFilters = new list<String>();
		if(companyId != null)
			queryFilters.add('Company__c = :companyId');
		if(customerIds != null && !customerIds.isEmpty())
			queryFilters.add('Customer__c in :customerIds');
		if(agreementIds != null && !agreementIds.isEmpty())
			queryFilters.add('Agreement_Line__r.Agreement__c in :agreementIds');
		if(salesOrderIds != null && !salesOrderIds.isEmpty())
			queryFilters.add('Sales_Order_Line__r.Sales_Order__c in :salesOrderIds');
		if(shipmentIds != null && !shipmentIds.isEmpty())
			queryFilters.add('Shipment_Line__r.Shipment__c in :shipmentIds');
		if(productIds != null && !productIds.isEmpty())
			queryFilters.add('Product__c in :productIds');
		if(categoryIds != null && !categoryIds.isEmpty())
			queryFilters.add('Category__c in :categoryIds');
		
		String whereClause = queryFilters.isEmpty() ? 'Invoice_Hold__c = true' : 'Invoice_Hold__c = true and '+String.join(queryFilters,' AND ');
		JsonResult result = new JsonResult();
		result.success = true;
		
		SOQLUtil soql = new SOQLUtil('Fulfillment__c');
	    soql.addFields('ReleaseHold');
	    soql.addFields(new Set<String> {'Company__c'});
	    soql.setWhereClause(whereClause);
	    
		result.records = Database.query(soql.getQuery());
		return result;  
	}
	
	@RemoteAction
	public static JSONResult putOnHold(list<Fulfillment__c> fRows, String reasonCodeId, list<String> dateFields) {
		
		map<Id,Fulfillment__c> mFulfillments = new map<Id,Fulfillment__c>(fRows);
		JsonResult result = new JsonResult();
		system.debug('dateFields '+dateFields);
		for(Fulfillment__c f: fRows) {
			KendoUtils.UpdateDateFields(f, dateFields);
			
			system.debug('f after date utils '+f);
			f.Invoice_Hold__c = true;
			f.Reason_Code__c = reasonCodeId;
		}
		
		try {
			DML.updateAsUser(fRows);
			result.records = fRows;
			result.success = true;
			result.addMessage('Fulfillment(s) have been put on hold. ',ApexPages.Severity.CONFIRM);
			return result;
			
		}catch(DMLException ex) {
			for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
				String hyperlink = '<a href="/'+ex.getDmlId(idx)+'">' + mFulfillments.get(ex.getDmlId(idx)).Name + '</a>'; 
				result.addMessage( hyperlink + ': '+ex.getDmlMessage(idx), ApexPages.severity.ERROR);
                
            } 
            return result;
		}catch(Exception ex) {
			result.addMessage( ex.getMessage(), ApexPages.severity.ERROR);
			return result;
		}
		
		
		
		return result; 
	}

	@RemoteAction
	public static JSONResult releaseHold(list<Fulfillment__c> fRows,  list<String> dateFields) {
		
		map<Id,Fulfillment__c> mFulfillments = new map<Id,Fulfillment__c>(fRows);
		JsonResult result = new JsonResult();
		system.debug('dateFields '+dateFields);
		for(Fulfillment__c f: fRows) {
			KendoUtils.UpdateDateFields(f, dateFields);
			f.Invoice_Hold__c = false;
			f.Reason_Code__c = null;
		}
		
		try {
			DML.updateAsUser(fRows);
			result.records = fRows;
			result.success = true;
			result.addMessage('Fulfillment(s) have been released from hold. ',ApexPages.Severity.CONFIRM);
			return result;
			
		}catch(DMLException ex) {
			for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
				String hyperlink = '<a href="/'+ex.getDmlId(idx)+'">' + mFulfillments.get(ex.getDmlId(idx)).Name + '</a>'; 
				result.addMessage( hyperlink + ': '+ex.getDmlMessage(idx), ApexPages.severity.ERROR);
                
            } 
            return result;
		}catch(Exception ex) {
			result.success = false;
			result.addMessage( ex.getMessage(), ApexPages.severity.ERROR);
			return result;
		}
		return result;
	}
	
	@RemoteAction
	public static JSONResult createIGR() {
		JsonResult result = new JsonResult();
		Invoice_Grouping_Rule__c igr = new Invoice_Grouping_Rule__c(Start_Date__c = System.Now());
		list<Invoice_Grouping_Rule__c> lstIgr = new list<Invoice_Grouping_Rule__c>();
		lstIgr.add(igr);
		result.success = true;
		result.records = lstIgr;
		return result;
	}
	
	@RemoteAction
	public static JSONResult validateIGR(Invoice_Grouping_Rule__c igr) {
		JsonResult result = new JsonResult();
		Savepoint sp = Database.setSavepoint();
		try{
			bypassDuplicateCheck = true; 
			if(!igr.Group_By_Sales_Orders__c){
				igr.Group_By_Sales_Order_Types__c = true;
			}
			Database.SaveResult saveResult = DML.insertAsUser(igr);
			if(saveResult.isSuccess()){
				System.debug(logginglevel.error,'For roll back of IGR***');
				result.success = true;
				Database.rollback(sp);
			}
		}
		catch(DMLexception ex){
			system.debug(logginglevel.error,'Error on IGR Insertion--------->'+ex.getDmlMessage(0));
			Database.rollback(sp);
			result.addMessage(ex.getDmlMessage(0), ApexPages.severity.ERROR);
			result.success = false;
		}
		return result;
	}
	
}