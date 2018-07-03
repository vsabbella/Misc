public with sharing class InvoiceManageExt extends BaseController {

	private static final String INVESTOR = 'Investor Company';
	private static final String INVESTEE = 'Investee Company';
	private static final String PAYOR = 'Payor Company';
	private static final String PAYEE = 'Payee Company';


	ApexPages.StandardController con;

	private static SchemaUtil util = SchemaUtil.getInstance();

	public Invoice__c invoice{get;set;}

	public String NamespaceUU { get { return KSE.NamespaceUU; }}
	public String pageTitle{get;set;}
	public Boolean displayExceptions{get;set;}
	public GridRelatedListController.GridRelatedListConfig invoiceLinesConfig {get; set;}  
	public ExceptionTasksExtNew exceptionTasksExtNew = null;
	public String exceptionsFieldList = null;

	public Boolean invalidType{get;set;}


	public String ReturnUrl{get{
		PageReference pageRef;
        
        if (invoice != null && !String.isBlank(invoice.id)){
            pageRef =  new PageReference('/' + invoice.Id);
        }
        else{
            Schema.DescribeSObjectResult dsr = Invoice__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        return pageRef.getUrl();
	}}

	public InvoiceManageExt(ApexPages.StandardController controller) {
		con = controller;
		//con.addFields(new List<String>{'Name', 'Type__c', 'Finalized__c', 'Has_Exceptions__c'});
		if(controller.getRecord().id != null ){
			invoice = (Invoice__c)controller.getRecord();

			invoice = [Select Id, Name, Type__c, Finalized__c, Has_Exceptions__c, To_Company__c, To_Company__r.Name, 
							From_Company__c, From_Company__r.Name, Currency__c, Transaction_Date__c 
						From Invoice__c Where Id=:invoice.Id];

			pageTitle = invoice.Type__c + ': ' + invoice.Name;

			if (invoice.Has_Exceptions__c){
                displayExceptions = true;
            }
            else{
                displayExceptions = false;
            }

            String invType = NamespaceUU + invoice.Type__c.replace(' ', '_');

            if(util.generateFieldSetsFromObjectName('Invoice__c').containsKey(invType) == false){
            	invalidType = true;

            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invoice type is invalid.  Please select valid type.'));
            }

		}else{
			pageTitle = 'Invoice';
			//invoice = (Invoice__c)controller.getRecord();
			invoice = new Invoice__c();
		}

		exceptionTasksExtNew = new ExceptionTasksExtNew();
        exceptionTasksExtNew.parent = invoice;
        exceptionsConfig = exceptionTasksExtNew.config;
		
	}

	public String InvoiceJson{
		get{return JSON.serialize(invoice);} 
		set{}
	}

	public String InvoiceLineFieldList{
		get{
			List<FieldInfo> fi;
			try{
				fi = FieldInfo.fetchJsonFieldInfos('Invoice_Line__c', invoice.Type__c.replace(' ', '_'));
				configFieldInfo(fi);


				// Supplier Invoice Lines Grid config
		        invoiceLinesConfig = new GridRelatedListController.GridRelatedListConfig();
		        if(invoice.Type__c != null && invoice.Type__c != ''){
		        	invoiceLinesConfig.uniqueId = 'InvoiceLinesGrid';
			        invoiceLinesConfig.title = invoice.Type__c + ' Lines';
			        invoiceLinesConfig.parentRecord = invoice;
			        invoiceLinesConfig.objectName = 'Invoice_Line__c';  
			        invoiceLinesConfig.parentField = 'Invoice__c';
			        invoiceLinesConfig.fieldset = invoice.Type__c.replace(' ', '_');

			        if(invoice.Finalized__c == true){
			        	invoiceLinesConfig.buttons = 'columnmenu, search';
			        }else{
			        	invoiceLinesConfig.buttons = 'create, delete, clone, columnmenu, search';
			        }
			        invoiceLinesConfig.additionalFields = String.join(new List<String>{'id', 'Has_Exceptions__c'}, ',');  

			        System.debug(LoggingLevel.INFO, '#### Field Info: ' + fi.size());

			        for(Integer i=0; i<fi.size();i++){
			        	System.debug(LoggingLevel.INFO, '#### Field 2: ' + fi[i].field);

			        	if(fi[i].field == 'Accounting_Default__c'){
			        		FieldInfo f = new FieldInfo('glaccountid', 'GL Account', 'reference');
					        f.referenceTo = 'GL_Account__c';
					        f.editable = true;
					        f.nullable = true;
					        f.required = true;
					        fi[i] = f;
			        	}else{
			        		fi[i].field = 'invoiceLine.' + fi[i].field;
			        	}
			        }

			        //FieldInfo f = new FieldInfo('errors', 'Errors', 'string');
		            //fi.add(0, f);

		        }
			}catch(Exception ex){
				fi = new List<FieldInfo>();
				System.debug(Logginglevel.INFO, 'No field set');
			}
			return JSON.serialize(fi);
		} 
		set{}
	}

	public String InvoiceLinesConfigJson{
		get{return JSON.serialize(invoiceLinesConfig);}
		set{}
	}

	public String InvoiceHeaderFieldList{
		get{
			List<FieldInfo> fi;
			try{
				fi = FieldInfo.fetchJsonFieldInfos('Invoice__c', invoice.Type__c.replace(' ', '_'));
				if(fi.size() > 1){
					fi.remove(0); // Remove Id field from the list
				}

				configFieldInfo(fi);
			}catch(Exception ex){
				System.debug(Logginglevel.INFO, 'No field set');
				fi = FieldInfo.fetchJsonFieldInfos('Invoice__c', new List<String>{'Type__c'});
			}
			

			return JSON.serialize(fi);
		}
		set{}
	}

	public String InvoiceHeaderAddlFieldList{
		get{
			List<FieldInfo> fieldInfoList;

			try{
					if(invoice.Type__c.startsWith('Interco') == true){
						fieldInfoList = FieldInfo.fetchJsonFieldInfos('Invoice__c', 'Interco_Additional_Fields');
						if(fieldInfoList.size() > 1){
							fieldInfoList.remove(0); // Remove Id field from the list
						}

						for(FieldInfo fi : fieldInfoList){
							fi.editable = false;
							if(fi.field == 'Status__c'|| (fi.field == 'Type__c' && String.isNotEmpty(invoice.Id))){
								fi.editable = false;
							}else if(fi.title.startsWith('To ')){
								fi.title = fi.title.replace('To ', Invoice.Type__c == InvoiceService.INTERCO_INVEST ? INVESTOR + ' ' : PAYOR + ' ');
							}else if(fi.title.startsWith('From ')){
								fi.title = fi.title.replace('From ', Invoice.Type__c == InvoiceService.INTERCO_INVEST ? INVESTEE + ' ' : PAYEE + ' ');
							}
						}
					}else{
						fieldInfoList = new List<FieldInfo>();	
					}
				}catch(Exception ex){
					fieldInfoList = new List<FieldInfo>();
				}

			return JSON.serialize(fieldInfoList);
		}
		set{}
	}

	public GridRelatedListController.GridRelatedListConfig exceptionsConfig {get; set;}  
	public string ExceptionsConfigJson{
		get{ // KNDY-7636
	        String configStr = JSON.serialize(this.exceptionsConfig);          
	        return configStr;
	    } set {}
	}

	public string getExceptionsFieldList() {
        if (!String.isBlank(invoice.Id) &&  exceptionsFieldList == null && exceptionsConfig != null) {
            exceptionsFieldList = exceptionTasksExtNew.getFieldList();
            List<FieldInfo> fieldInfoList = (List<FieldInfo>) JSON.deserialize(exceptionsFieldList, List<FieldInfo>.class);

            FieldInfo fi = new FieldInfo('name', 'Name', 'string');
            fieldInfoList.add(0, fi);
            exceptionsFieldList = JSON.serialize(fieldInfoList);
        }       
        return exceptionsFieldList;
    }

    // called on page load
    public String getWhatIdNameMapJson() {  	
        return exceptionTasksExtNew.getWhatIdNameMapJson();    
    }   

    @RemoteAction    
    public static JSONResult massOverrideTasks(list<Task> selectedTasks){
        JSONResult result = TasksMassOverride.massOverrideTasks(selectedTasks);
        return result;
    }

	private void configFieldInfo(List<FieldInfo> fieldInfoList){
		if(invoice.Type__c != null){
			for(FieldInfo fi : fieldInfoList){
				if(invoice.Finalized__c == true){
					fi.editable = false;
				}

				if(fi.field == 'Name' || fi.field == 'Has_Exceptions__c' || fi.field == 'Status__c'|| (fi.field == 'Type__c' && String.isNotEmpty(invoice.Id))){
					fi.editable = false;
				}else if(fi.field == 'To_Company__c'){
					fi.title = Invoice.Type__c == InvoiceService.INTERCO_INVEST ?  INVESTOR + ' ' : PAYOR + ' ';
				}else if(fi.field == 'From_Company__c'){
					fi.title = Invoice.Type__c == InvoiceService.INTERCO_INVEST ? INVESTEE + ' ' : PAYEE + ' ';
				}
			}
		}
	}

	public PageReference onInvoiceTypeChange(){
		//empty action method to update the page when the Invoice type is changed.
		if(invalidType == true){
			invalidType = false;
			update invoice;
		}

		return null;
	}

	@RemoteAction
	public static JsonResult getInvoiceDetails(Id id, String inType){

		String objectName = 'Invoice__c';
        String headerFieldset = inType.replace(' ', '_');  
        String addlHeaderFieldset = 'Interco_Additional_Fields';  
        //Set<String> addlFields = new Set<String> { 'Company__c', 'Finalized__c', 'Currency__c' };
        string whereClause = 'Id  = :id LIMIT 1';
        
        String queryString = util.generateQueryFromFieldSet(objectName, new Set<string>{ headerFieldset,addlHeaderFieldset }, null, whereClause);

        List<Invoice__c> si = database.query(queryString);   
 
        return new JsonResult(si, si.size());
	}

	@RemoteAction
	public static JsonResult getInvoiceLines(GridRelatedListController.GridRelatedListConfig config){
		list<InvoiceLineWrapper> result = new list<InvoiceLineWrapper>();
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
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

        addlFields.add('Accounting_Default__r.GL_Account__c');
        addlFields.add('Accounting_Default__r.GL_Account__r.Id');
        addlFields.add('Accounting_Default__r.GL_Account__r.Name');
        addlFields.add('Accounting_Default__r.Company__c');
        addlFields.add('Accounting_Default__r.Intercompany__c');
        
        String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        system.debug(Logginglevel.info, queryString);
        List<Invoice_Line__c> invoiceLinesList = database.query(queryString);   
        system.debug(Logginglevel.info, result);

        for (Integer i = 0; i< invoiceLinesList.size() ; i++) {
 
            result.add(new InvoiceLineWrapper(invoiceLinesList[i]));
        }
        return new JsonResult(result, result.size());
	}

	private static void setAccountingDefault(Invoice__c iv, InvoiceLineWrapper il){

		System.debug(Logginglevel.INFO, '#### Setting Accounting Default');
		Accounting_Default__c ad = new Accounting_Default__c();
		ad.Company__c = iv.From_Company__c;
		ad.Intercompany__c = iv.To_Company__c;
		ad.GL_Account__c = il.glaccountid;

		Accounting_Default__c oldAd = il.invoiceLine.Accounting_Default__r;

		System.debug(Logginglevel.INFO, '#### New Accounting Default: ' + ad);
		System.debug(Logginglevel.INFO, '#### Old Accounting Default: ' + oldAd);

		if(oldAd == null || oldAd.GL_Account__c != ad.GL_Account__c || oldAd.Company__c != ad.Company__c || oldAd.Intercompany__c != ad.Intercompany__c){
			il.invoiceLine.Accounting_Default__c = null;
			il.invoiceLine.Accounting_Default__r = ad;
		}

	}

	@RemoteAction
	public static JsonResult saveAction(Invoice__c inv, List<String> headerDateFields, List<InvoiceLineWrapper> updatedList, List<InvoiceLineWrapper> newList, List<InvoiceLineWrapper> deletedList, List<String> dateFields){

		List<Invoice_Line__c> lineRecords = new List<Invoice_Line__c>();
		if (updatedList.size() > 0) {
            for (InvoiceLineWrapper line : updatedList) {
                KendoUtils.UpdateDateFields(line.invoiceLine, dateFields);

                setAccountingDefault(inv, line);
                lineRecords.add(line.invoiceLine);
            }
        }
        
        if (newList.size() > 0) {
            for (InvoiceLineWrapper line : newList) {
                KendoUtils.UpdateDateFields(line.invoiceLine, dateFields);
                setAccountingDefault(inv, line);
                lineRecords.add(line.invoiceLine);
            }    
        }

		JsonResult jr = new JsonResult();

		Savepoint sp = Database.setSavepoint();
        List<Invoice__c> records = new List<Invoice__c>();

        try{
        	if(InvoiceService.validateAndUpsert(new List<Invoice__c>{inv}, lineRecords,jr, false) == false){
        		Database.rollback(sp);
                jr.success = false;
                return jr;
        	}


        	DML.checkUpsertAsUser(inv);

        	Boolean newAndFinalize = false;

    		if(String.isEmpty(inv.Id)){
    			//The Id is coming in as an empty string and not null. This breaks upsert
    			inv.Id = null;
    			if(inv.Finalized__c == true){
    				inv.Finalized__c = false;
    				newAndFinalize = true;
    			}
    		}
        	upsert inv;

        	// save invoice lines
        	Set<String> invalidRowGUIDs = saveInvoiceLines(inv, updatedList, newList, deletedList, jr);

        	if(newAndFinalize == true){
        		inv.Finalized__c = true;
        		upsert inv;
        	}

    		records.add(inv);
			jr.records = records;
			jr.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);

		}catch(DMLException ex) { //KNDY-10984
			Database.rollback(sp);
            jr.success = false;
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug('errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getMessage() +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');

                    if(!msgArray.isEmpty()){
                        errorMessage = msgArray.get(msgArray.size()-1);

                        if(errorMessage.contains(': []: []')){
                            location = errorMessage.lastIndexOf(': []: []');
                            errorMessage = errorMessage.mid(0, location);
                        }
                        if(errorMessage.contains(': []')){
                            location = errorMessage.lastIndexOf(': []');
                            errorMessage = errorMessage.mid(0, location);
                        }
                    }
                } 
                    
                jr.addMessage( errorMessage, ApexPages.severity.ERROR);
        	}
            //System.debug(logginglevel.info,result);
		}
		catch(Exception ex){

			System.debug(Logginglevel.INFO, '#### Error');
			System.debug(LoggingLevel.INFO, ex.getStackTraceString());

			Database.rollback(sp);
            jr.success = false;
            jr.addMessage('An Error occured : ' + ex.getMessage() , ApexPages.Severity.ERROR);
		}

		return jr;
	}

	@RemoteAction
    public static DataSourceResult getTaskRelatedList(GridRelatedListController.GridRelatedListConfig config) {
        DataSourceResult dsr = GridRelatedListController.getTaskRelatedList(config);
        return dsr;        
    }

	private static Set<String> saveInvoiceLines(Invoice__c inv, List<InvoiceLineWrapper> updatedList, List<InvoiceLineWrapper> newList, List<InvoiceLineWrapper> deletedList, JSONResult result){
		Set<String> invalidRowGuids = new Set<String>();

		List<InvoiceLineWrapper> invoiceLines = new List<InvoiceLineWrapper>();
        
        invoiceLines.addAll(updatedList);
        invoiceLines.addAll(newList);

        if (invoiceLines.size() > 0) {
        	invalidRowGuids = saveLines(inv, invoiceLines);
        }

        if (deletedList.size() > 0) {
            // delete lines
            invalidRowGuids = deleteLines(inv, deletedList);
        }

		return invalidRowGuids;
	}

	public static Set<String> saveLines(Invoice__c inv, List<InvoiceLineWrapper> invoiceLines) {

		List<Invoice_Line__c> lines = new List<Invoice_Line__c>();
		List<Accounting_Default__c> accD = new List<Accounting_Default__c>();

		for(InvoiceLineWrapper il : invoiceLines){
			Invoice_Line__c item = il.invoiceLine;

			System.debug(Logginglevel.INFO, '#### GL Account ' + item.Accounting_Default__r.GL_Account__c + '\tNew: ' + il.glaccountid);
			System.debug(Logginglevel.INFO, '#### Company ' + item.Accounting_Default__r.Company__c + '\tNew' + inv.From_Company__c);
			System.debug(Logginglevel.INFO, '#### Intercompany ' + item.Accounting_Default__r.Intercompany__c + '\tNew' + inv.To_Company__c);

			if(item.Accounting_Default__c == null || item.Accounting_Default__r.GL_Account__c != il.glaccountid || 
						item.Accounting_Default__r.Company__c != inv.From_Company__c || 
						item.Accounting_Default__r.Intercompany__c != inv.To_Company__c){

				System.debug(Logginglevel.INFO, '#### Is new default');

				Accounting_Default__c d = new Accounting_Default__c(GL_Account__c=il.glaccountid, Company__c=inv.From_Company__c, Intercompany__c=inv.To_Company__c);
				item.Accounting_Default__r = d;
				accD.add(d);
			}else{
				System.debug(Logginglevel.INFO, '#### Already exists');
			}

			if(String.isEmpty(item.Invoice__c)){
				item.Invoice__c = inv.Id;
			}
			lines.add(item);
		}

		DML.checkUpsertAsUser(accD);
		
		upsert accd;

		for(Invoice_Line__c l : lines){
			System.debug(Logginglevel.INFO, '#### Lines: ' + l.Id);
			if(l.Accounting_Default__r != null){
				l.Accounting_Default__c = l.Accounting_Default__r.Id;
			}
		}

		DML.checkUpsertAsUser(lines);
		upsert lines;

		return null;
	}

	private static Set<String> deleteLines(Invoice__c inv, List<InvoiceLineWrapper> invoiceLines){
		List<Invoice_Line__c> iLines = new List<Invoice_Line__c>();
        List<InvoiceLineWrapper> invoiceLinesToDelete = new List<InvoiceLineWrapper>();

        for (InvoiceLineWrapper item: invoiceLines) {
            if (item.invoiceLine.id != null){

            	 Invoice_Line__c line = item.invoiceLine;
            	 //line.Invoice__c = inv.Id;

            	 iLines.add(line); 
            }
        }

        if (iLines.size() > 0) {
        	//delete supplier invoice lines;
        	DML.deleteAsUser(iLines);
        }

        return null;

	}

	public class InvoiceLineWrapper {
		public Invoice_Line__c invoiceLine { get; set; }
		public String glaccountid{get;set;}
		public GL_Account__c glaccount{get;set;}
		public String rowGUID{get;set;}

		//String errors { get; set; }

		public InvoiceLineWrapper(){

		}

		public InvoiceLineWrapper(Invoice_Line__c il){
			invoiceLine = il;

			if(il.Accounting_Default__c != null){
				glaccountid = il.Accounting_Default__r.GL_Account__c;
				glaccount = il.Accounting_Default__r.GL_Account__r;
			}
		}
	}
}