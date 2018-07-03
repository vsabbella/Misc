public with sharing class PaymentLinesManageExt extends GridRelatedListController{
    
    public GridRelatedListConfig paymentLinesConfig {get; set;}
    public GridRelatedListConfig invoiceOptionsConfig {get; set;}
    public static SchemaUtil util = SchemaUtil.getInstance();
    Apexpages.StandardController controller;
    public string paymentLineFieldList = null;
    public string invoiceFieldList = null;
    public Payment__c payment {get; set;} //controller record
    public class PaymentException extends Exception{}
    
    private static map<string, string> mFieldLabels = new map<string, string>{
    	'from_company__c' 	=> 'Payor Company',
    	'from_street__c' 	=> 'Payor Street',
    	'from_city__c' 		=> 'Payor City',
    	'from_state__c' 	=> 'Payor State',
    	'from_zip_code__c' 	=> 'Payor Zip Code',
    	'from_country__c' 	=> 'Payor Country',
    	'from_bank_account__c' =>	'Payor Bank Account',
    	'to_company__c' 	=> 'Payee Company',
    	'to_street__c' 		=> 'Payee Street',
    	'to_city__c' 		=> 'Payee City',
    	'to_state__c' 		=> 'Payee State',
    	'to_zip_code__c' 	=> 'Payee Zip Code',
    	'to_country__c' 	=> 'Payee Country',
    	'to_bank_account__c'=> 'Payee Bank Account'
    };
    
    public PaymentLinesManageExt(Apexpages.StandardController controller){
        
        try{
            this.controller = controller;
            //pgError = false;
            payment = (Payment__c) controller.getRecord();
            if(payment != null && payment.Id != null){
                payment = [select Id, Name, Finalized__c, From_Company__c, From_Company__r.Name, To_Company__c, To_Company__r.Name
                            from Payment__c where id=:payment.Id limit 1];
            }
         
            paymentLinesConfig = new GridRelatedListConfig();
	        paymentLinesConfig.uniqueId = 'GridAddManagePaymentLines';
	        paymentLinesConfig.parentRecord = payment;
	        paymentLinesConfig.objectName = 'Payment_Line__c';  
	        paymentLinesConfig.parentField = 'Payment__c';
	        paymentLinesConfig.fieldset = 'Payment_Line_Edit';
	        paymentLinesConfig.additionalFields = 'Has_Exceptions__c';
	        if(payment.Finalized__c){
	        	paymentLinesConfig.buttons = 'search';
	            paymentLinesConfig.readOnlyFields = string.join(SchemaUtil.getInstance().getFieldsFromFieldSetString(Payment_Line__c.getSobjectType(), 'Payment_Line_Edit'), ',');
	        }else{
		        paymentLinesConfig.buttons = 'cancel, delete, search';
	            paymentLinesConfig.readOnlyFields = 'Name';
	        }
            
            invoiceOptionsConfig = new GridRelatedListConfig();
	        invoiceOptionsConfig.uniqueId = 'GridInvoiceOptions';
	        //invoiceOptionsConfig.parentRecord = payment;
	        invoiceOptionsConfig.objectName = 'Invoice__c';  
	        //invoiceOptionsConfig.parentField = 'Payment__c';
	        invoiceOptionsConfig.fieldset = 'Invoice_Options';
	        if(!payment.Finalized__c){
	        	invoiceOptionsConfig.buttons = 'Add to Payment, search';
	        }
	        //invoiceOptionsConfig.additionalFields = 'Name';
	        invoiceOptionsConfig.sortField = 'Name';
	        invoiceOptionsConfig.sortOrder = 'asc';
            invoiceOptionsConfig.readOnlyFields = string.join(SchemaUtil.getInstance().getFieldsFromFieldSetString(Invoice__c.getSobjectType(), 'Invoice_Options'), ',');
            
        }catch(Exception e){
            //System.debug(LoggingLevel.ERROR, e);
            ApexPages.addMessages(e);
        }

    }
    
    public String ReturnUrl{
    	get{
			PageReference pageRef;
	        
	        if (payment != null && payment.id != null ){
	            pageRef =  new PageReference('/' + payment.Id);
	        }
	        else{
	            Schema.DescribeSObjectResult dsr = Payment__c.SObjectType.getDescribe();
	            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
	        }
	        return pageRef.getUrl();
		}
	}
    
    public String getPaymentLinesConfigJson() {
        String configStr = JSON.serialize(this.paymentLinesConfig);
          
        return configStr;
    }
    
     public String getInvoiceOptionsConfigJson() {
        String configStr = JSON.serialize(this.invoiceOptionsConfig);
          
        return configStr;
    }
    
    public List<Integer> selected_indexes {
        get {
            String selected_indexes = Apexpages.currentPage().getParameters().get('selected_indexes');
            return ArrayUtils.getIntegerList( selected_indexes );
        }
    }
    
    public static Map<id, List<Task>> getPaymentLineTaskDetails(set<Id> pmtLineIds){
    	Map <id, List<Task>> mPmtLineTask = new Map<id, List<Task>>();
    	List<Task> TaskList= [Select Id, createdDate, what.Name, Subject, ActivityDate, priority, Status, Exception_Code__c, Description, WhatId
                FROM Task 
    			where whatId in :pmtLineIds
    			AND isClosed = false];
    	for(Task thisTask: TaskList){
    		if(mPmtLineTask.containsKey(thisTask.whatId)){
    			List<Task> oldList = (List<Task>) mPmtLineTask.get(thisTask.whatId);
    			oldList.add(thisTask);
    			mPmtLineTask.put(thisTask.whatId,oldList);
    		}else{
    			List<Task> newList = new List<Task>();
    			newList.add(thisTask);
    			mPmtLineTask.put(thisTask.whatId, newList);
    		}
    	}		
    	return mPmtLineTask;
    }
    
    public static Map<id, List<Payment_Match__c>> getPaymentMatchDetails(set<Id> pmtLineIds){
    	Map <id, List<Payment_Match__c>> mPaymentMatches = new Map<id, List<Payment_Match__c>>();
    	SOQLUtil soql = new SOQLUtil('Payment_Match__c');
    	soql.addFields('Manage');
    	soql.addField('Payment_Line__c');
    	string pmtLineRefs = '(\'' + string.join(new List<Id>(pmtLineIds), '\',\'') + '\')';
    	soql.setWhereClause('Payment_Line__c IN ' + pmtLineRefs);
    	for(Payment_Match__c pm : (List<Payment_Match__c>)soql.returnQueryResult()){
    		if(mPaymentMatches.containsKey(pm.Payment_Line__c)){
    			mPaymentMatches.get(pm.Payment_Line__c).add(pm);
    		}else{
    			mPaymentMatches.put(pm.Payment_Line__c, new List<Payment_Match__c>{pm});
    		}
    	}
    	return mPaymentMatches;
    }
    
    public String getExceptionFieldList() {
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Task', new String[] {'Subject', 'Exception_Code__c', 'Description'});
        
        for (Integer i = 0; i < fieldInfoList.size(); i++){  
        	fieldInfoList[i].editable = false;
        }
        
        return JSON.serialize(fieldInfoList);
    }
    
    public String getPaymentMatchFieldList() {
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Payment_Match__c', SchemaUtil.getInstance().getFieldsFromFieldSetString(Payment_Match__c.getSobjectType(), 'Manage'));
        
        for (Integer i = 0; i < fieldInfoList.size(); i++){  
        	fieldInfoList[i].editable = false;
        }
        
        return JSON.serialize(fieldInfoList);
    }
    
    public string getPaymentLineFieldList() {
        if (paymentLineFieldList == null && paymentLinesConfig != null) {
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(paymentLinesConfig.objectName, paymentLinesConfig.fieldset);
            // set the wrapper class prefix
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                fieldInfoList[i].field = 'pmtLine.' + fieldInfoList[i].field;
                if(payment.Finalized__c ){
                	fieldInfoList[i].editable = false;
                }                
            }
            
            paymentLineFieldList = JSON.serialize(fieldInfoList);
        }
        system.debug(LoggingLevel.Info, 'Payment Line FIELDS:' + paymentLineFieldList);
        return paymentLineFieldList;
    }
    
    public string getInvoiceFieldList() {
        if (invoiceFieldList == null && invoiceOptionsConfig != null) {
            // get the supplier invoice lines field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(invoiceOptionsConfig.objectName, invoiceOptionsConfig.fieldset);
            
            // set the wrapper class prefix
            for(Integer i = 0; i < fieldInfoList.size(); i++){
                fieldInfoList[i].field = fieldInfoList[i].field;   
                fieldInfoList[i].editable = false;             
            }
            
            invoiceFieldList = JSON.serialize(fieldInfoList);
        }
        system.debug(LoggingLevel.Info, 'Invoice FIELDS:' + invoiceFieldList);
        return invoiceFieldList;
    }
    
    @RemoteAction
    public static JsonResult getPaymentDetails(string paymentId){
    	
    	JsonResult result = new JsonResult();
    	List<Payment__c> pmts = new List<Payment__c>();
    	if(paymentId instanceOf Id){
	    	SoqlUtil soql = new SoqlUtil('Payment__c');
	    	soql.addFields('Manage');
	    	soql.addFields('Additional_Detail');
	    	soql.addField('To_Company__r.Name');
	    	soql.addField('From_Company__r.Name');
	    	soql.setWhereClause('Id = \'' +paymentId + '\'');
	    	pmts =  soql.returnQueryResult();
    	}
    	result.success = true;
		result.records = pmts;
        result.total = pmts.size();
        //TODO: Exceptions...
		return result;
    }
    
    @RemoteAction
    public static JsonResult savePaymentDetails(Object rec){
    	system.debug('rec: ' + rec);
    	JSONResult result;
    	Savepoint sp = Database.setSavepoint();
    	try{
	    	Payment__c pmt = (Payment__c)JSON.deserialize(string.valueOf(rec), Payment__c.class);
	    	if(pmt.Type__c == null){
	    		pmt.Type__c = 'Intercompany Payment';
	    	}
	    	pmt.Transaction_Type__c = pmt.Type__c;
	    	if(pmt.From_Company__c != null 
	    			&& string.isBlank(pmt.From_Street__c) 
	    			&& string.isBlank(pmt.From_City__c)
	    			&& string.isBlank(pmt.From_State__c)
	    			&& string.isBlank(pmt.From_Zip_Code__c)
	    			&& string.isBlank(pmt.From_Country__c)){
	    		Company__c fromCompany = [SELECT Id, name, street__c, city__c, state__c, zip_code__c, country__c from Company__c WHERE Id = :pmt.From_Company__c];
	    		pmt.From_Street__c = fromCompany.Street__c;
	    		pmt.From_City__c = fromCompany.City__c;
	    		pmt.From_State__c = fromCompany.State__c;
	    		pmt.From_Zip_Code__c = fromCompany.Zip_Code__c;
	    		pmt.From_Country__c = fromCompany.Country__c;
	    	}
	    	if(pmt.To_Company__c != null
	    			&& string.isBlank(pmt.To_Street__c) 
	    			&& string.isBlank(pmt.To_City__c)
	    			&& string.isBlank(pmt.To_State__c)
	    			&& string.isBlank(pmt.To_Zip_Code__c)
	    			&& string.isBlank(pmt.To_Country__c)){
	    		Company__c fromCompany = [SELECT Id, name, street__c, city__c, state__c, zip_code__c, country__c from Company__c WHERE Id = :pmt.To_Company__c];
	    		pmt.To_Street__c = fromCompany.Street__c;
	    		pmt.To_City__c = fromCompany.City__c;
	    		pmt.To_State__c = fromCompany.State__c;
	    		pmt.To_Zip_Code__c = fromCompany.Zip_Code__c;
	    		pmt.To_Country__c = fromCompany.Country__c;
	    	}
	    	
	    	
	    	
	    	system.debug('pmt: ' + pmt);
	    	
	    	if(pmt.Finalized__c){
	    		List<Payment_Match__c> pms = [SELECT Id, Amount__c, Invoice__r.Balance__c, Invoice__r.Name, Payment_Line__r.Name
	    										FROM Payment_Match__c
	    										WHERE Payment_Line__r.Payment__c = :pmt.Id];
				for(Payment_Match__c pm : pms){
					if(pm.Amount__c > pm.Invoice__r.Balance__c){
						throw new PaymentException(pm.Payment_Line__r.Name + ' will overpay Invoice ' + pm.Invoice__r.Name);
					}
				}
	    	}
	    	
	    	//system.assert(false);
	    	upsert pmt;
	    	
	    	result = new JSONResult(new list<Payment__c>{pmt}, 1);
    	}catch(Exception ex){
    		system.debug('EXCEPTION: ' + ex.getMessage() +ex.getStackTraceString());
    		database.rollback(sp);
    		result = new JSONResult();
    		result.addMessage(ex, Apexpages.Severity.ERROR);
    	}
    	return result;
    }
    
     @RemoteAction
    public static DataSourceResult savePaymentLines(List<SObject> updatedList, List<SObject> newList, List<Sobject> deletedList, List<String> dateFields) {
    	for (SObject row: updatedList) { 
        	KendoUtils.UpdateDateFields(row, dateFields);
		}
		
		for (SObject row: newList) { 
        	KendoUtils.UpdateDateFields(row, dateFields);
		}
		
        DataSourceResult result = new DataSourceResult();
        Savepoint sp = Database.setSavepoint();

        try {
            if (updatedList.size() > 0) {
            	
                DML.updateAsUser(updatedList); 
                
                map<Id, sObject> mRecs = new map<Id, sObject>(updatedList);
                List<Payment_Match__c> paymentMatches = [SELECT Id, Amount__c, Payment_Line__r.Amount__c, Invoice__r.From_Company__c, Invoice__r.To_Company__c,
                											Payment_Line__r.Payment__r.From_Company__c, Payment_Line__r.Payment__r.To_Company__c, Invoice__r.Balance__c, Invoice__r.Name
	                									FROM Payment_Match__c 
	                									WHERE Payment_Line__c IN :mRecs.keySet()];
                for(Payment_Match__c pm : paymentMatches){
                	if(mRecs.containsKey(pm.Payment_Line__c)){
                		
                		Payment_Line__c iPML = (Payment_Line__c)mRecs.get(pm.Payment_Line__c);
                		//TODO: This is really really really extremely brittle and only supports this one particular use case
                		pm.Amount__c = math.abs(iPML.Amount__c);
                		
                		//Check if we're trying to credit an amount on a balance due between the entities
                		if(pm.Payment_Line__r.Payment__r.From_Company__c == pm.Invoice__r.From_Company__c
                				&& pm.Payment_Line__r.Amount__c > 0){
        					//TODO: Better error text?
                			throw new PaymentException('You cannot apply credit to invoices from the Payor to the Payee');
                		}
                		
                		//Check if we're trying to overpay between the entities
                		if(pm.Amount__c > pm.Invoice__r.Balance__c){
        					//TODO: Better error text?
                			throw new PaymentException('You cannot pay more than the balance due on Invoice ' + pm.Invoice__r.Name);
                		}
                	}
                }
                
                update paymentMatches;
                result.records = updatedList;
                result.total = updatedList.size();
            }
            
            if (newList.size() > 0) {
                DML.insertAsUser(newList);
            }
            
            if (deletedList.size() > 0) {
                // OTC-439 users with Del perm on object can delete any row (even owned by others)
                new DML.WithoutSharing().sobjectDel( deletedList );
            }
            // Leave it from here and let JS handle !
            result.addMessage('Your changes have been saved successfully', ApexPages.Severity.CONFIRM);

        } catch (Exception ex) {
        	system.debug('EXCEPTION: ' + ex.getMessage() + ex.getStackTraceString());
            Database.rollback(sp);
            result.success = false;
            result.addMessage(ex, ApexPages.Severity.ERROR);
        }

        return result;
    }
    
    @RemoteAction 
    public static JsonResult getPaymentLines(GridRelatedListConfig config) {
        list<PaymentLineWrapper> result = new list<PaymentLineWrapper>();
        string parentId;
        if(config.parentRecord != null){
        	parentId = config.parentRecord.Id;	
        }
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        //addlFields.add('(SELECT)')
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        string whereClause = parentfield + ' = :parentId';
        
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
        
        if (String.isNotBlank(config.namespace)) {
                util.namespace = config.namespace;
        }
        set<Id> pmtLineIds = new set<Id>();
        String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        system.debug(Logginglevel.info, queryString);
        List<Payment_Line__c> pmtLinesList = database.query(queryString);   
        system.debug(Logginglevel.info, result);
 
        for (Integer i = 0; i< pmtLinesList.size() ; i++) {
            pmtLineIds.add(pmtLinesList[i].id);
        }
        map<id,List<Task>> pmtLineTask = getPaymentLineTaskDetails(pmtLineIds);
        map<id,list<Payment_Match__c>> mPmtMatches = getPaymentMatchDetails(pmtLineIds);
        for (Integer i = 0; i< pmtLinesList.size() ; i++) {
            result.add(new PaymentLineWrapper(pmtLinesList[i], pmtLineTask.get(pmtLinesList[i].id), mPmtMatches.get(pmtLinesList[i].Id)));
        }
        
        return new JsonResult(result, result.size());
    }
    
    @RemoteAction 
    public static JsonResult getInvoiceOptions(GridRelatedListConfig config) {
    	system.debug('invoiceGridConfig: ' + config);
        string parentId;// = (config.parentRecord != null ) ? config.parentRecord.Id : '';
        if(config.parentRecord != null){
        	parentId = config.parentRecord.Id;	
        }
        
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        string whereClause = '';
        Payment__c pmt;
        
        if(parentId != null){
        	pmt = [SELECT Id, From_Company__c, To_Company__c, Currency__c FROM Payment__c WHERE Id = :parentId];
        
        
	        string companyList = '(\'' + string.join(new List<Id>{pmt.From_Company__c, pmt.To_Company__c}, '\',\'') + '\')';
	        whereClause += 'From_Company__c IN ' + companyList 
        						+ ' AND To_Company__c IN ' + companyList 
        						+ ' AND Balance__c > 0 ' 
        						+ ' AND Currency__c = \'' + pmt.Currency__c + '\' '
        						+ ' AND Currency__c != null'
        						+ ' AND Finalized__c = true '
        						+ ' AND Id NOT IN (SELECT Invoice__c FROM Payment_Match__c WHERE Payment_Line__r.Payment__c = \'' + parentId + '\')';
        }else{
        	whereClause += 'Id = null';
        }
        /*
        string whereClause = parentfield + ' = :parentId';
         */
         
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
       
        
        if (String.isNotBlank(config.namespace)) {
                util.namespace = config.namespace;
        }
        
        set<Id> pmtLineIds = new set<Id>();
        String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        system.debug(Logginglevel.info, queryString);
        List<Invoice__c> invoiceOptionsList = database.query(queryString);   
        system.debug(Logginglevel.info, invoiceOptionsList);
 
        
        return new JsonResult(invoiceOptionsList, invoiceOptionsList.size());
    }
    
    @RemoteAction 
    public static JsonResult addInvoicesToPayment(string paymentId, list<string> invoiceIds) {
    	Payment__c pmt = [SELECT Id, From_Company__c, To_Company__c FROM Payment__c WHERE Id = :paymentId];
    	List<Invoice__c> invoices = [SELECT Id, Balance__c, From_Company__c, To_Company__c
    									FROM Invoice__c
    									WHERE Id IN :invoiceIds
    									AND Id NOT IN (SELECT Invoice__c FROM Payment_Match__c WHERE Payment_Line__r.Payment__c = :paymentId)];
    	map<Id, Payment_Line__c> mPmtLines = new map<Id, Payment_Line__c>();
		List<Payment_Match__c> pmtMatches = new List<Payment_Match__c>();
		for(Invoice__c inv : invoices){
			Payment_Line__c iPML = new Payment_Line__c(Payment__c = paymentId);
			//Check Payor/Payee and assign sign convention
			if(inv.From_Company__c == pmt.To_Company__c){
				iPML.amount__c = inv.Balance__c;
				iPML.Type__c = 'Intercompany Payment';
			}else{
				iPML.amount__c = (-1)*inv.Balance__c;
				iPML.Type__c = 'Intercompany Netting';
			}
			iPML.Subtransaction_Type__c = iPML.Type__c;
			mPmtLines.put(inv.Id, iPML);
		}
		insert mPmtLines.values();
		for(Invoice__c inv : invoices){
			Payment_Match__c iPM = new Payment_Match__c(Invoice__c = inv.Id, amount__c = inv.Balance__c, Payment_Line__c = mPmtLines.get(inv.Id).Id, Type__c = 'Intercompany Payment');
			//Check Payor/Payee and assign sign convention
			//if(inv.From_Company__c == pmt.To_Company__c){
				iPM.amount__c = inv.Balance__c;
			//}
			//else{
			//	iPM.amount__c = (-1)*inv.Balance__c;
			//}
			pmtMatches.add(iPM);
		}
		insert pmtMatches;
		
        return new JsonResult(mPmtLines.values(), mPmtLines.values().size());
    }
    
    
    public class PaymentLineWrapper {
        public Payment_Line__c pmtLine { get; set; }
        public boolean hasExceptions { get; set; } { hasExceptions = false; }
        public List<Payment_Match__c> paymentMatches {get; set;}
        public List<Task> exceptions { get; set; }
        public String rowGUID{get;set;}
        
        public PaymentLineWrapper(boolean hasExceptions, List<Task> exceptions) {
            this.hasExceptions = hasExceptions;
            this.exceptions = exceptions;   
    }
    
        public PaymentLineWrapper(Payment_Line__c pmtLine, List<Task> exceptions, List<Payment_Match__c> paymentMatches) {
            this.pmtLine = pmtLine;
            this.paymentMatches = paymentMatches;
            this.hasExceptions = pmtLine.Has_Exceptions__c;
            this.exceptions = exceptions;
        }
     }
     
     public string getPaymentHeaderManageFieldList() {
        String PaymentHeaderManageFieldList = '';
        try {
        	List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Payment__c', 'Manage');
        	fieldInfoList.remove(0);
        	for(FieldInfo fi : fieldInfoList){
        		string fieldName = fi.field.replace(NamespaceUU, '');
        		//fi.field = fieldName;
                //system.debug('header field: ' + fi);
        		if(payment.Finalized__c || paymentReadOnlyFields.contains(fieldName.toLowerCase())){
        			fi.editable = false;
        		}
        		if(mFieldLabels.containsKey(fieldName.toLowerCase())){
        			fi.title = mFieldLabels.get(fieldName.toLowerCase());
        		}
                fi.field = NamespaceUU + fi.field;
        		//system.debug('fi.field: ' + fi.field);
        	}
       		PaymentHeaderManageFieldList = JSON.serialize(fieldInfoList);
        }catch (FieldInfo.EmptyFieldSetMemberException e) {
            PaymentHeaderManageFieldList = '';

        }
        return PaymentHeaderManageFieldList;
    }
    
    public string getPaymentHeaderAdditionalFieldList() {
        String PaymentHeaderAdditionalFieldList = '';
        try {
        	List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Payment__c', 'Additional_Detail');
        	fieldInfoList.remove(0);
        	for(FieldInfo fi : fieldInfoList){
        		string fieldName = fi.field.replace(NamespaceUU, '');
        		//fi.field = fieldName;
                //system.debug('header field: ' + fi);
        		if(payment.Finalized__c || paymentReadOnlyFields.contains(fieldName.toLowerCase())){
        			fi.editable = false;
        		}
        		if(mFieldLabels.containsKey(fieldName.toLowerCase())){
        			fi.title = mFieldLabels.get(fieldName.toLowerCase());
        		}
                fi.field = NamespaceUU + fi.field;
                //system.debug('fi.field: ' + fi.field);
        	}
       		PaymentHeaderAdditionalFieldList = JSON.serialize(fieldInfoList);
        }catch (FieldInfo.EmptyFieldSetMemberException e) {
            PaymentHeaderAdditionalFieldList = '';

        }
        
        return PaymentHeaderAdditionalFieldList;
    }
    
    private set<string> paymentReadOnlyFields = new set<string>{'payment_amount__c', 'to_street__c', 'to_city__c', 'to_state__c', 'to_zip_code__c', 'to_country__c', 'from_street__c', 'from_city__c', 'from_state__c', 'from_zip_code__c', 'from_country__c'};
        
        
        
}