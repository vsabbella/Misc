public with sharing class PaymentBatchExt extends BaseController{

	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	private static SchemaUtil util = SchemaUtil.getInstance();
	public GridRelatedListController.GridRelatedListConfig supplierInvoicePreviewConfig {get; set;}
    public String supplierInvoicesFieldList = null;
    //KNDY-17712 -grid config properties
    public string SupplierPaymentMasterFieldList = null;    
    public GridRelatedListController.GridRelatedListConfig supplierPaymentMasterPreviewConfig {get; set;}
    //child grid config
    public string SupplierPaymentChildFieldList = null;
    public GridRelatedListController.GridRelatedListConfig supplierPaymentChildPreviewConfig {get; set;}
    public Id defaultCompanyId {get; private set;} //KNDY-8222
    public Bank_Account__c defaultDisbursementBankAcct {get; private set;} //KNDY-14286
	public String previousPage { get; set; }
	public string selectedPaymentRuleMethod {get;set;}
	public List<SelectOption> paymentRuleOptions {get;set;} { paymentRuleOptions = new List<SelectOption>();}
	//KNDY-17714- Defualt variables for pay invoice from supplier invoice record
	public Id defaultSupplier{ get; set;}
	public Id defaultSICurrencyId{ get; set;}
	public Date defaultPaymentDueDate{ get; set;}
	public String defaultPaymentMethod{ get; set;}
	public String defaultStandardPaymentMethod{ get; set;}	//KNDY-16750 default value with first active Payment method
	public Company__c defaultCompany{ get; private set;}	
    public Id supplierInvoiceId{get;set;}
    public Id supplierId{get;set;}
    public decimal defaultImmediateModeScope {get;set;} //KNDY-18789 set default scope of immediate mode from CMDT and send it to page
    private static final decimal DEFAULT_IMMEDIATEMODE_SCOPE = 50;
    public class CustomException extends Exception{}  
    
    public static Map<Id,SupplierPaymentService.InvoiceWrapper> initialScopeInvoiceRecordsFromUI {
    		
    	get{
    		if (initialScopeInvoiceRecordsFromUI == null){
    			initialScopeInvoiceRecordsFromUI = new Map<Id,SupplierPaymentService.InvoiceWrapper>();
    		}
    		return initialScopeInvoiceRecordsFromUI;
    	}
    	private set;
    }  
        
    public PaymentBatchExt() {
        previousPage = ApexPages.currentPage().getHeaders().get('Referer');
        //KNDY-17732 - Set immediately or Batch job radio button depending on the page opened from
        if (ApexPages.currentPage().getParameters().containsKey('action')) {
            selectedPaymentRuleMethod = ApexPages.currentPage().getParameters().get('action');
        }else{
        	selectedPaymentRuleMethod = 'Batch Job';
        }
        //KNDY-16750 get first active default value of picklist
        defaultStandardPaymentMethod = getFirstActiveRemitMethodPicklistValue('Supplier__c','Payment_Method_G__c');
        system.debug(LoggingLevel.Error,  ' selectedPaymentRuleMethod=='+selectedPaymentRuleMethod);
        supplierInvoiceId = String.isNotBlank(ApexPages.currentPage().getParameters().get('supplierInvoiceId')) ? ApexPages.currentPage().getParameters().get('supplierInvoiceId') : null;
        List<Supplier_Invoice__c> supplierInvoiceList;
        if (string.isNotBlank(supplierInvoiceId)){
        	SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Supplier__c','Invoice_Type__c','Company__c','Currency__c','Payment_Method_G__c','Payment_Due_Date__c'
            });
            soql.setWhereClause('Id = :supplierInvoiceId');
            soql.setLimit(1);
            
            supplierInvoiceList = Database.query(soql.getQuery());
          	system.debug(LoggingLevel.Error,'Supplier Invoice list : ' + supplierInvoiceList);
            if (supplierInvoiceList.size() > 0  && supplierInvoiceList[0].Id != null){
                if (supplierInvoiceList[0].Supplier__c != null)
                    defaultSupplier = supplierInvoiceList[0].Supplier__c;                
            
	            defaultCompanyId = supplierInvoiceList[0].Company__c;
	            defaultSICurrencyId = supplierInvoiceList[0].Currency__c;
	            defaultPaymentMethod = supplierInvoiceList[0].Payment_Method_G__c != null ? supplierInvoiceList[0].Payment_Method_G__c :defaultStandardPaymentMethod;
	            defaultPaymentDueDate = supplierInvoiceList[0].Payment_Due_Date__c;
            }
            system.debug(LoggingLevel.Error,  ' defaultSupplier=='+defaultSupplier + ' = defaultCompanyId='+defaultCompanyId + ' = defaultPaymentMethod=' +defaultPaymentMethod + '=defaultPaymentDueDate= ' +defaultPaymentDueDate + '= defaultSICurrencyId=' +defaultSICurrencyId);           
        }else{
        	UserPreference defaults = UserPreference.getInstance(); //KNDY-8222
        	defaultCompanyId = defaults.preference.Default_Company__c;
        }
        Id defaultDisbursementBankAcctId = CompanyService.getBankAccount(defaultCompanyId);
        if (defaultDisbursementBankAcctId != null){ //KNDY-14286
            JSONResult res = getBankAccount(defaultDisbursementBankAcctId);
            defaultDisbursementBankAcct = (Bank_Account__c)res.records[0];
            //KNDY-18029 - fetch default disbursement payment method for bank account selected in case it is not open from SI
            if (string.isBlank(supplierInvoiceId)) defaultPaymentMethod = defaultDisbursementBankAcct.Primary_Disbursement_Payment_Method__c != null ? defaultDisbursementBankAcct.Primary_Disbursement_Payment_Method__c : defaultStandardPaymentMethod;
        }
        //KNDY-17714 - Fetch company and currency in case no default bank account assigned at company level
    	defaultCompany = CompanyService.getCompanyInfo(defaultCompanyId);       
    	system.debug(LoggingLevel.Info,'defaultCompany : ' +defaultCompany); 	
        
        //Supplier Invoices Preview Grid config
        supplierInvoicePreviewConfig = new GridRelatedListController.GridRelatedListConfig();
        supplierInvoicePreviewConfig.uniqueId = 'SupplierInvoicesPreviewGrid';
        supplierInvoicePreviewConfig.title = 'Supplier Invoices';
        supplierInvoicePreviewConfig.objectName = 'Supplier_Invoice__c';
        supplierInvoicePreviewConfig.fieldset = 'Payment_Batch_Preview_List';
        supplierInvoicePreviewConfig.buttons = 'columnmenu, excel, search';
        supplierInvoicePreviewConfig.alwaysUseFullDateTimeFormat = false;
        //KNDY-17276: supplier name is used for sort

        supplierInvoicePreviewConfig.additionalFields ='Supplier__r.Name,Supplier__r.Id, Currency__c, Company__c, Status__c ,Supplier__r.Parent_Supplier__c,Supplier__r.Top_Parent_Supplier__c' +
        											',Supplier__r.Parent_Hold_Payment__c,Supplier__r.Top_Parent_Hold_Payment__c,Discount_Override_Date__c,Payment_term__r.Discount_Days__c' +
        											' ,Always_Take_Discount__c,Early_Payment_Rate__c,Invoice_Amount__c,Amount_Paid__c,Discount_Taken__c'+
        											//add  mandatory fields in case not included in the fieldset or removed 
        											//KNDY-16758 - add invoice type in additional field set so it won't break even if fieldset doesn't contain field
        											',Date_Invoiced__c,invoice_type__c,Balance_Due__c,Credit_Memo_Balance__c,Credit_Memo_Applied__c,Supplier__c';//,Discount_to_Take__c' KNDY-18011 - DEPRECATED ;
    	
    	//KNDY-17712 - grid config for preview payment master grid
    	//Supplier payment master Preview Grid config
        supplierPaymentMasterPreviewConfig = new GridRelatedListController.GridRelatedListConfig();
        supplierPaymentMasterPreviewConfig.uniqueId = 'supplierPaymentMasterPreviewConfig';
        supplierPaymentMasterPreviewConfig.title = 'Supplier Payment';
        supplierPaymentMasterPreviewConfig.objectName = 'Supplier_Payment__c';
        supplierPaymentMasterPreviewConfig.buttons = 'columnmenu, search';
        supplierPaymentMasterPreviewConfig.fieldset = 'Payment_Preview';
		supplierPaymentMasterPreviewConfig.pageSize = 10;
        supplierPaymentMasterPreviewConfig.alwaysUseFullDateTimeFormat = false;
        //KNDY-17923 - deperecated 'payment_number__c' 	
        supplierPaymentMasterPreviewConfig.additionalFields ='Reference__c,Payment_Amount__c, Currency__c, Payment_Method_G__c, Date_Paid__c ,Supplier__c,Name,Status__c,Status_Reason__c,Bank_Account__c,Total_Number_of_Lines__c,Source_Key__c,Batch_Job_ID__c ';
        //KNDY-17712 - grid config for preview payment child grid
    	//Supplier payment child Preview Grid config
        supplierPaymentChildPreviewConfig = new GridRelatedListController.GridRelatedListConfig();
        supplierPaymentChildPreviewConfig.uniqueId = 'supplierPaymentChildPreviewConfig';
        supplierPaymentChildPreviewConfig.title = 'Supplier Payment Line';
        supplierPaymentChildPreviewConfig.objectName = 'Supplier_Payment_Line__c';
        supplierPaymentChildPreviewConfig.fieldset = 'Payment_Lines_Preview';
        supplierPaymentChildPreviewConfig.alwaysUseFullDateTimeFormat = false;
        
 		paymentRuleOptions.clear();
 		paymentRuleOptions.add(new SelectOption('Batch Job', 'Batch Job'));
 		paymentRuleOptions.add(new SelectOption('Immediately', 'Immediately'));
 		
 		//KNDY-18789 - Fetch immediate mode scope from CMDT and if it doesnt exists set default batchsize =1
		List<ConfigurationMDT__mdt> mdtRecords = [SELECT developerName, Value__c, namespacePrefix
                                        FROM ConfigurationMDT__mdt
                                        WHERE developerName = 'Supplier_Payment_Immediate_Mode_Scope'
                                        LIMIT 1];
        defaultImmediateModeScope = DEFAULT_IMMEDIATEMODE_SCOPE;
        if (mdtRecords.size() > 0){
            defaultImmediateModeScope = mdtRecords[0].Value__c != null ? Integer.ValueOf(mdtRecords[0].Value__c) : DEFAULT_IMMEDIATEMODE_SCOPE;
        }
		system.debug(LoggingLevel.Error,'Immediate mode payment size from MDT : ' +mdtRecords + ' and Actual Batch Size : ' + defaultImmediateModeScope );
    }

	public String getSupplierInvoicePreviewConfigJson() {
        String configStr = JSON.serialize(this.supplierInvoicePreviewConfig);
          
        return configStr;
    }
    //KNDY-17712 - grid config for preview payment master grid
    public String getSupplierPaymentMasterPreviewConfigJson() {
        String configStr = JSON.serialize(this.supplierPaymentMasterPreviewConfig);
          
        return configStr;
    }
    //KNDY-17712 - grid config for preview payment child grid
    public String getSupplierPaymentChildPreviewConfigJson() {
        String configStr = JSON.serialize(this.supplierPaymentChildPreviewConfig);
          
        return configStr;
    }
    public string getSupplierInvoicesFieldList() {
        if (supplierInvoicesFieldList == null && supplierInvoicePreviewConfig != null) {
        	FieldInfo fieldInfoItem;
        	// get the supplier invoice field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            //KNDY-16751 - Ability to select the amount to pay out or apply per invoice
            FieldInfo fld = new FieldInfo();
            fld.title =  Label.Amount_to_Apply;
            fld.field = 'Amount_To_Apply';
            fld.fieldtype = 'double';
            fld.scale = 2;
            fld.editable = true;
            fld.sortable = true; 
            fld.filterable = true;                        
            fieldInfoList.add(fld);
            //KNDY-17276 - Ability to verify discount amount while paying out invoices            
            fld = new FieldInfo();
            fld.title = Label.Earned_Discount;
            fld.field = 'Discount_Earned';
            fld.fieldtype = 'double';
            fld.scale = 2;
            fld.editable = true;
            fld.sortable = true; 
            fld.filterable = true;      
            fieldInfoList.add(fld); 
            
            List<FieldInfo> fieldInfoListfldSet  = FieldInfo.fetchJsonFieldInfos(supplierInvoicePreviewConfig.objectName, supplierInvoicePreviewConfig.fieldset);
            
            Set<String> hiddenFields = new Set<String> { 'Id' ,'Currency__c', 'Company__c'};
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoListfldSet.size(); i++){ 
            	
            	String fieldName = fieldInfoListfldSet[i].field;            	
            	if(fieldName != 'selected' ){
            		fieldInfoListfldSet[i].field = 'invoiceRecord.' + fieldName;
            	}
            	
                if(fieldName =='Name'){
                  fieldInfoListfldSet[i].referenceTo = 'invoiceRecord.Id';
                  fieldInfoListfldSet[i].fieldtype ='Name';
                }else if(fieldName == 'Date_Invoiced__c') {
                    fieldInfoListfldSet[i].fieldtype = 'date';
                }
                
            	fieldInfoListfldSet[i].editable = false;
            	fieldInfoListfldSet[i].filterable = true;            	
            	
            	
            	fieldInfoListfldSet[i].hidden = hiddenFields.contains(fieldName);
            	system.debug('fieldInfoList[i] =='+fieldName + ' = '+fieldInfoListfldSet[i].editable);
            }
			fieldInfoList.addAll(fieldInfoListfldSet);
            system.debug('fieldInfoList=='+fieldInfoList);
            supplierInvoicesFieldList = JSON.serialize(fieldInfoList);
        }
        
        return supplierInvoicesFieldList;
    }
    //KNDY-17712 - sp master field list
	public string getSupplierPaymentMasterFieldList() {
        if (SupplierPaymentMasterFieldList == null && supplierPaymentMasterPreviewConfig != null) {
        	FieldInfo fieldInfoItem;
        	// get the supplier invoice field info list
            List<FieldInfo> fieldInfoListfldSet  = FieldInfo.fetchJsonFieldInfos(supplierPaymentMasterPreviewConfig.objectName, supplierPaymentMasterPreviewConfig.fieldset,supplierPaymentMasterPreviewConfig.additionalFields);
            set<string> readonlyFields = new set<string>{'Payment_Amount__c', 'Currency__c', 'Payment_Method_G__c', 'Date_Paid__c' ,'Supplier__c','Remittance_Address__c'};
            Set<String> hiddenFields = new Set<String> { 'Id' , 'Company__c'};
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();

            FieldInfo fld = new FieldInfo();
            fld.title =  Supplier_Payment__c.Name.getDescribe().getLabel();
            fld.field = 'supplierPayment.Name';
            fld.referenceTo = 'supplierPayment.Id';
            fld.fieldtype = 'Name';            
            fld.editable = false;
            fld.sortable = true; 
            fld.filterable = false;                        
            fieldInfoList.add(fld);       
            fld = new FieldInfo();
            fld.title = Supplier_Payment__c.Status__c.getDescribe().getLabel();
            fld.field = 'supplierPayment.Status__c';
            fld.fieldtype = 'string';
            fld.editable = false;
            fld.sortable = true; 
            fld.filterable = false;      
            fieldInfoList.add(fld); 
            fld = new FieldInfo();
            fld.title = Supplier_Payment__c.Status_Reason__c.getDescribe().getLabel();
            fld.field = 'supplierPayment.Status_Reason__c';
            fld.fieldtype = 'string';
            fld.editable = false;
            fld.sortable = true; 
            fld.filterable = false;      
            fieldInfoList.add(fld); 
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoListfldSet.size(); i++){ 
            	
            	String fieldName = fieldInfoListfldSet[i].field;            	
            	if(fieldName != 'selected' ){
            		fieldInfoListfldSet[i].field =  'supplierPayment.' + fieldName;
            	}
            	
                if(fieldName =='Name'){
                  fieldInfoListfldSet[i].referenceTo = 'supplierPayment.Id';
                  fieldInfoListfldSet[i].fieldtype ='Name';
                }else if(fieldName == 'Date_Paid__c') {
                    fieldInfoListfldSet[i].fieldtype = 'date';
                }
                fieldInfoListfldSet[i].editable = (!readonlyFields.contains(fieldName));                            	
            	fieldInfoListfldSet[i].hidden = hiddenFields.contains(fieldName);
            	system.debug('fieldInfoList[i] =='+fieldName + ' = '+fieldInfoListfldSet[i].editable);
            }
            system.debug('fieldInfoList=='+fieldInfoListfldSet);
            fieldInfoList.addAll(fieldInfoListfldSet);
            SupplierPaymentMasterFieldList = JSON.serialize(fieldInfoList);
        }

        return SupplierPaymentMasterFieldList;
    }
    //KNDY-17712 - sp child field list
	public string getSupplierPaymentChildFieldList() {
        if (SupplierPaymentChildFieldList == null && supplierPaymentChildPreviewConfig != null) {
        	FieldInfo fieldInfoItem;
        	// get the supplier invoice field info list
            List<FieldInfo> fieldInfoListfldSet  = FieldInfo.fetchJsonFieldInfos(supplierPaymentChildPreviewConfig.objectName, supplierPaymentChildPreviewConfig.fieldset);
            set<string> readonlyFields = new set<string>{'Supplier_Invoice__c', 'Type__c', 'Amount__c'};
            Set<String> hiddenFields = new Set<String> { 'Id' ,'Currency__c', 'Company__c'};
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoListfldSet.size(); i++){ 
            	
            	String fieldName = fieldInfoListfldSet[i].field;            	
            	if(fieldName != 'selected' ){
            		fieldInfoListfldSet[i].field =  fieldName;
            	}
            	
                if(fieldName =='Name'){
                  fieldInfoListfldSet[i].referenceTo = 'Id';
                  fieldInfoListfldSet[i].fieldtype ='Name';
                }
                
            	fieldInfoListfldSet[i].editable = (!readonlyFields.contains(fieldName));      
            	fieldInfoListfldSet[i].filterable = true;            	
            	
            	
            	fieldInfoListfldSet[i].hidden = hiddenFields.contains(fieldName);
            	system.debug('fieldInfoList[i] =='+fieldName + ' = '+fieldInfoListfldSet[i].editable);
            }
            system.debug('fieldInfoList=='+fieldInfoListfldSet);
            SupplierPaymentChildFieldList = JSON.serialize(fieldInfoListfldSet);
        }
        
        return SupplierPaymentChildFieldList;
    }
    
    @remoteAction
    public static JSONResult getBankAccount(string baId){ //KNDY-14332 to prevent throwing vf remoting error changed arg to string
        JSONResult jr = new JSONResult();
        try{
        	id bankId =  (Id) baId;
        	//KNDY-18029 method moved to payment service
	        Bank_Account__c ba = PaymentService.getBankAccount(baId);
	        jr.success = true;
	        jr.records = new List<Bank_Account__c>{ba};
	        jr.total = 1;
        }
        catch (Exception ex){
            jr.success = false;
            jr.message = ex.getMessage();
        }
        return jr;
    }
    
    @RemoteAction 
	public static List<SelectListItem> getRemitMethodPicklistValues(string objectName, string fieldName)
	{
		//SchemaUtil schemautil = SchemaUtil.getInstance();
		List<SelectListItem> selectList = new List<SelectListItem>();
		       	
		if (String.isBlank(objectName) || String.isBlank(fieldName))
		{
			return selectList;
		}
		
		Map<String, sObjectField> fieldmap = util.getFieldsMap(objectName);
		Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

		if (dfr.getType() == Schema.DisplayType.Picklist) {
            //KNDY-16750 - valid payment method should be selected to fetch SIs 
            //selectList.add(new SelectListItem(' ', '--None--'));
            
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.isActive()) {
                    selectList.add(new SelectListItem(pe.getValue(), pe.getLabel()));
                }                
            }
        }
        
		return selectList; 
   	}   
   	//KNDY-16750 - First default value to set from payment method picklist	
    private string getFirstActiveRemitMethodPicklistValue(string objectName, string fieldName)
	{
				
		Map<String, sObjectField> fieldmap = util.getFieldsMap(objectName);
		Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();
		if (dfr.getType() == Schema.DisplayType.Picklist) {
           
            for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
                if (pe.isActive()) {
                    return pe.getValue();
                }
            }
        }
        
		return null; 
   	}  
   	 	
    @RemoteAction @ReadOnly 
    public static JsonResult getSupplierInvoices(List<KendoUtils.FilterDescriptor> filters, GridRelatedListController.GridRelatedListConfig config) {
        JsonResult result = new JsonResult();
        List<SupplierPaymentService.InvoiceWrapper> spInvoiceList = null;
        spInvoiceList =SupplierPaymentService.getSupplierInvoices(filters, config);
        system.debug(LoggingLevel.Error,'spInvoiceList=='+spInvoiceList);
        result.success = true;
        result.records = spInvoiceList; 
        Integer total = (spInvoiceList != null) ? spInvoiceList.size() : 0;
        result.total = total;
        return result;
    }
   
    //KNDY-16750 - refactor payment batch call to accommodate single SI per batch
    @RemoteAction 
    public static JsonResult createSPaymentBatch(List<KendoUtils.FilterDescriptor> filters, List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsFromUI) {
        system.debug(LoggingLevel.ERROR,'invoiceRecordsFromUI: ' + invoiceRecordsFromUI);
        JsonResult dsResult = new JsonResult();
        Set<Id> supplierIds = new Set<Id>();
        boolean invprepaymentfoundflg = false;
        //Set<Id> scopeSupInvIdsToPay = new Set<Id>();
        Map<id,SupplierPaymentService.InvoiceWrapper> scopeSupInvIdsToPay = new Map<id,SupplierPaymentService.InvoiceWrapper>();
        for (SupplierPaymentService.InvoiceWrapper siWrapper: invoiceRecordsFromUI){
        	supplierIds.add(siWrapper.invoiceRecord.Supplier__c);        	
        	//KNDY-17276 Update amount to apply after deducting discount.
        	if (siWrapper.Discount_Earned != null ) siWrapper.Amount_To_Apply = siWrapper.Amount_To_Apply - siWrapper.Discount_Earned;   	
        	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
        	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;   	
        	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
        	ID sID = siWrapper.invoiceRecord.id;
        	if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
        	if (siWrapper.Invoice_Type != PaymentService.TYPE_CREDITMEMO && siWrapper.Invoice_Status == PaymentService.STATUS_APPROVED)
        		invprepaymentfoundflg = true;
        	scopeSupInvIdsToPay.put(sID,siWrapper);
        } 
        system.debug('filters: ' + filters);
        system.debug(LoggingLevel.Error,'supplierIds: ' + supplierIds + 'invprepaymentfoundflg='+invprepaymentfoundflg);
        system.debug(LoggingLevel.Error,'scopeSupInvIdsToPay: ' + scopeSupInvIdsToPay);
        try{           
        	if (!invprepaymentfoundflg){
        		throw new CustomException(Label.Only_invoices_with_credit_balances_selected_negative_payment_cannot_be_issued);
        	}
            PaymentBatch batch = new PaymentBatch(filters, scopeSupInvIdsToPay, supplierIds);
	        batch.runBatch(null);
	        SOQLUtil soql = new SOQLUtil('AsyncApexJob', false); //enforceFLS=false, running in system mode
			soql.addFields(new set<string>{
				'Id'
			});
			soql.setWhereClause('ApexClass.Name =\'PaymentBatch\' AND JobType = \'BatchApex\' AND Status IN (\'Holding\', \'Queued\', \'Preparing\', \'Processing\')');
			List<AsyncApexJob> runningJobs = Database.query(soql.getQuery());

	        system.debug('runningJobs=='+runningJobs);
	        dsResult.success = true;
            dsResult.addMessage( Label.Successfully_Created_Payment_Batch + runningJobs[0].id,ApexPages.Severity.INFO);
        }catch(CustomException ex){
        	dsResult.success = false;
            dsResult.addMessage(ex.getMessage(),ApexPages.Severity.ERROR);
            dsResult.reason = ex.getMessage();
            system.debug(LoggingLevel.ERROR,dsResult);
        }catch(DMLException ex) { 
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug(LoggingLevel.ERROR,'errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getDmlMessage(idx) +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
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
                    system.debug(LoggingLevel.Error,'inside dml exception errorMessage : ' + errorMessage);
                } 
                    
                dsResult.success = false;
	        	dsResult.reason = ex.getDmlMessage(idx)  + '=' + ex.getStackTraceString();
	            dsResult.addMessage(Label.Error_Occurred_While_Processing_Payment_Batch + ':' + ex.getDmlStatusCode(idx) + '-' + errorMessage +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
	            system.debug(LoggingLevel.ERROR,dsResult.reason);
        	}
		}
        catch ( DML.InsuffientAccessException ex ) { 
 			dsResult.success = false;
        	dsResult.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            dsResult.addMessage(Label.Error_Occurred_While_Processing_Payment_Batch + ':' + ex.getMessage() +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,dsResult.reason);
 		}
        catch (Exception ex){
        	dsResult.success = false;
            dsResult.addMessage(Label.Error_Occurred_While_Processing_Payment_Batch+'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);
            dsResult.reason = ex.getMessage();
            system.debug(LoggingLevel.ERROR,ex.getMessage());
        }
        system.debug('dsResult ='+dsResult);
        return dsResult;   
    }
    //KNDY-17712 - verify selected invoices if they are still valid
	@RemoteAction
	public static JsonResult verifySelectedSupplierInvoices(SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI){
		JsonResult dsResult = new JsonResult();
		integer screenInvCount = 0;
		Map<String,string> originalInvIdNameMap = new map<String,string>();
		List<String> SINamesForMsg = new List<String>();
		set<String> InvoiceSelectedSet = new Set<String>();
		Set<Id> SISet = new Set<Id>();
    	if (originalSISPRecordsFromUI != null){
    		 screenInvCount = originalSISPRecordsFromUI.invWrapperList.size();
	        for (SupplierPaymentService.InvoiceWrapper siWrapper: originalSISPRecordsFromUI.invWrapperList){	
	        	SISet.add(siWrapper.invoiceRecord.id);
	        	originalInvIdNameMap.put(siWrapper.invoiceRecord.id + '_' +siWrapper.invoiceRecord.Status__c  ,siWrapper.invoiceRecord.Name);  	  
	        }   
        }
        
        
        system.debug(LoggingLevel.Debug,'originalInvIdNameMap=='+originalInvIdNameMap);
        string whereClause = ' Id IN :SISet '; 
        string balanceFilters ='';
    	balanceFilters += ' AND ((Invoice_Type__c = \'Invoice\' and Balance_Due__c > 0 and Status__c = \'Approved\')';
        balanceFilters += 'or';
        balanceFilters += '(Invoice_Type__c = \'Prepayment\' and Credit_Memo_Balance__c != 0  and '+
            '(Status__c = \'Approved\' or Status__c = \'Closed\'))'; //KNDY-13561
        balanceFilters += 'or';
        balanceFilters += '(Invoice_Type__c = \'Credit Memo\' and Credit_Memo_Balance__c != 0 and Status__c = \'Approved\'))';
        whereClause += balanceFilters;
        
    	SOQLUtil suppInvSoql = new SOQLUtil ( 'Supplier_Invoice__c') ;
    	Set<String> queryInvStrBaseFields = new Set<String> { 'Id','Status__c'};
    	suppInvSoql.addFields ( queryInvStrBaseFields ) ;
    	suppInvSoql.setWhereClause ( whereClause );
    	suppInvSoql.setOrderByClause ( 'Invoice_Amount__c DESC' ) ;
    	system.debug(LoggingLevel.INFO,'query string to verify invoices : ' + suppInvSoql.getQuery());
    	
    	
    	List<Supplier_Invoice__c> supplierInvoiceList = Database.query(suppInvSoql.getQuery() );
    	
    	for (Supplier_Invoice__c inv :supplierInvoiceList ){
    		InvoiceSelectedSet.add(inv.id + '_' + inv.Status__c);
    	}
    	if (supplierInvoiceList.size() <> screenInvCount ){
    		system.debug(LoggingLevel.Error,'supplierInvoiceList size= ' + supplierInvoiceList.size() + ' supplierInvoiceList.size() <> screenInvCount =' +(supplierInvoiceList.size() <> screenInvCount));
    		if (supplierInvoiceList.size() < screenInvCount && supplierInvoiceList.size() != 0){
    			system.debug(LoggingLevel.Error,(supplierInvoiceList.size() < screenInvCount && supplierInvoiceList.size() != 0));
    			for (String invId : originalInvIdNameMap.keyset()){
    				if (!InvoiceSelectedSet.contains(invId)){
    					SINamesForMsg.add(originalInvIdNameMap.get(invId));
    				}
    			}
    			dsResult.success = false;
    			if (SINamesForMsg.size() <> screenInvCount){
    				system.debug(LoggingLevel.Info,'size of si messages : ' + SINamesForMsg.size() + ' size of inv selected on screen: ' +screenInvCount);
    				dsResult.success = true;
    			}
    		}
    		if (supplierInvoiceList.size() == 0 ){
				SINamesForMsg.add(Label.All);    			
    			dsResult.success = false;
    		}

	        dsResult.addMessage(Label.Supplier_Payment_Preview_Validation_Message + ' ' + String.Join(SINamesForMsg,', '),ApexPages.Severity.Info);	        
    	}else if (supplierInvoiceList.size() == screenInvCount ){
    		dsResult.success = true; 
    	}
    	
    	system.debug(LoggingLevel.Error,'Get SIs which are not fetched = ' + SINamesForMsg);
    	system.debug(LoggingLevel.Error,'Get SIs which are not fetched with json result = ' + dsResult);
    	return dsResult;
	}
    @RemoteAction 
    public static JsonResult createSPaymentRealTime(List<KendoUtils.FilterDescriptor> filters, List<SupplierPaymentService.InvoiceWrapper> invoiceRecordsToBeProcessedFromUI,SupplierPaymentService.invoicePaymentWrapper originalSISPRecordsFromUI) {
    	JsonResult dsResult = new JsonResult();
        Set<Id> supplierIds = new Set<Id>();
        set<id> SIset = new set<Id>();        
        List<Supplier__c> supplierList = new List<Supplier__c>();
        SupplierPaymentService spService = new SupplierPaymentService();
        string paymentMethod;
        List<SupplierPaymentService.invoicePaymentWrapper> SISPWrapperList = new List<SupplierPaymentService.invoicePaymentWrapper>();
        system.debug(LoggingLevel.ERROR,'invoiceRecordsToBeProcessedFromUI: ' + invoiceRecordsToBeProcessedFromUI);
        List<SupplierPaymentService.invoicePaymentWrapper> invPaymentWrapperList = new List<SupplierPaymentService.invoicePaymentWrapper>();
        SupplierPaymentService.invoicePaymentWrapper invPaymentWrapper = new SupplierPaymentService.invoicePaymentWrapper ();
        system.debug(LoggingLevel.ERROR,'originalSIRecordsFromUI: ' + originalSISPRecordsFromUI);
        try{
	        if (originalSISPRecordsFromUI != null){
		        for (SupplierPaymentService.InvoiceWrapper siWrapper: originalSISPRecordsFromUI.invWrapperList){
		        	
			    	siWrapper.Invoice_Type = siWrapper.invoiceRecord.Invoice_Type__c;
			    	siWrapper.Invoice_Status = siWrapper.invoiceRecord.Status__c;	    	
			    	siWrapper.SupplierId = siWrapper.invoiceRecord.Supplier__c;
			    	supplierIds.add(siWrapper.invoiceRecord.Supplier__c);
			    	ID sID = siWrapper.invoiceRecord.id;
			    	//if (siWrapper.invoiceRecord.Invoice_Type__c == PaymentService.TYPE_INVOICE) siWrapper.invoiceRecord = null;
			    	siWrapper.newInvoiceRecord = null;
			    	initialScopeInvoiceRecordsFromUI.put(sID,siWrapper);		   
		        }   
	        }else{
	        	dsResult.success = false;
	            dsResult.addMessage(Label.Payments_Cannot_Be_Previewed  +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);
	            return dsResult;
	        }
	        system.debug(LoggingLevel.ERROR,'initialScopeInvoiceRecordsFromUI: ' + initialScopeInvoiceRecordsFromUI);
	        
	        for(KendoUtils.FilterDescriptor fd: filters){
	            system.debug(LoggingLevel.info,'Filter: ' + fd);            
	            if (fd.field == 'Payment_Method_G__c'){                
	                paymentMethod = String.valueOf(fd.value);  
	            }               
	        }             
	       
        	for (SupplierPaymentService.InvoiceWrapper invWrapper :invoiceRecordsToBeProcessedFromUI){
	        	SIset.add(invWrapper.invoiceRecord.id );
        	}
	        system.debug(LoggingLevel.Debug,'SIset=='+SIset);
	        string whereClause = ' Status__c = \'Approved\'  AND Hold__c = false and  Invoice_Type__c NOT IN (\'Credit Memo\') AND Payment_Method_G__c = : paymentMethod AND Supplier__r.Hold_Payment__c = false ' +
	            			' AND Supplier__c= : supplierIds  And  Id IN :SIset ';
	    
	    	SOQLUtil suppInvSoql = new SOQLUtil ( 'Supplier_Invoice__c',true) ;
	    	Set<String> queryInvStrBaseFields = new Set<String> { 'Id', 'Name','Supplier__c'};
	    	suppInvSoql.addFields ( queryInvStrBaseFields ) ;
	    	suppInvSoql.setWhereClause ( whereClause );
        	suppInvSoql.setOrderByClause ( 'Date_Invoiced__c ASC' ) ;
        	
	    	List<Supplier_Invoice__c> supplierInvoiceList = Database.query(suppInvSoql.getQuery() );
	    	
	    	
    		system.debug(LoggingLevel.Debug,'supplierInvoiceList=='+supplierInvoiceList);
    		set<Id> suppIdSet = new set<id>();
    		for (Supplier_Invoice__c SInv :supplierInvoiceList){
    			suppIdSet.add(sInv.Supplier__c);
    		}
    		//no check in active since we allow to select inactive supplier on screen
    		//string status ='Active';
    		SOQLUtil supplierSoql = new SOQLUtil ( 'Supplier__c',true) ;
	    	supplierSoql.addFields ( new Set<String> { 'Id', 'Name','Pay_Per_Invoice__c'} ) ;
	    	supplierSoql.setWhereClause ( 'Hold_Payment__c = false and Id IN :suppIdSet' );
        	supplierSoql.setOrderByClause ( 'Name ASC' ) ;
        	List<Supplier__C> suppliersList = database.query(supplierSoql.getQuery());
        	Map<Id,Supplier__C> supplierMap = new Map<Id,Supplier__C> ();
        	for (Supplier__C supplier :suppliersList){
        		supplierMap.put(supplier.id,supplier);
        	}    		
    		if (invPaymentWrapperList.size () ==0 ) 
    			invPaymentWrapperList.add(invPaymentWrapper);
    		SupplierPaymentService.timeNow = originalSISPRecordsFromUI.dateTimeNow;
	    	for (Supplier_Invoice__c proccessSI :supplierInvoiceList){
	    		string suppId = proccessSI.Supplier__c;	            	 			
	 			supplierList.add(supplierMap.get(suppId));
	 			//process payments
	        	SISPWrapperList = spService.processPayments( filters, initialScopeInvoiceRecordsFromUI,new List<Supplier_Invoice__c>{proccessSI}, supplierList, null);
	        	system.debug(LoggingLevel.ERROR,'after processing each payment SISPWrapperList: ' + SISPWrapperList[0].paymentWrapperList);
	        	supplierList.clear();
	        	
	        	invPaymentWrapperList[0].invWrapperList = SISPWrapperList[0].invWrapperList;
	        	if (invPaymentWrapperList[0].paymentWrapperList == null)
	        		invPaymentWrapperList[0].paymentWrapperList =  SISPWrapperList[0].paymentWrapperList;
	        	else	 
	        		invPaymentWrapperList[0].paymentWrapperList.addAll( SISPWrapperList[0].paymentWrapperList);	        	
	    	}
	    	system.debug(LoggingLevel.Error,'invPaymentWrapperList='+invPaymentWrapperList[0].paymentWrapperList);
	    	dsResult.records = invPaymentWrapperList;
	    	dsResult.success = true;	        
    	}catch(CustomException ex){
        	dsResult.success = false;
            dsResult.addMessage(ex.getMessage(),ApexPages.Severity.ERROR);
            dsResult.reason = ex.getMessage();
            system.debug(LoggingLevel.ERROR,ex.getMessage());
        }catch(DMLException ex) { 
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug(LoggingLevel.ERROR,'errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getDmlMessage(idx) +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
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
                    system.debug(LoggingLevel.Error,'inside dml exception errorMessage : ' + errorMessage);
                } 
                    
                dsResult.success = false;
	        	dsResult.reason = ex.getDmlMessage(idx)  + '=' + ex.getStackTraceString();
	            dsResult.addMessage(Label.Payments_Cannot_Be_Previewed + ':' + ex.getDmlStatusCode(idx) + '-' + errorMessage +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
	            system.debug(LoggingLevel.ERROR,dsResult.reason);
        	}
		}
        catch ( DML.InsuffientAccessException ex ) { 
 			dsResult.success = false;
        	dsResult.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            dsResult.addMessage(Label.Payments_Cannot_Be_Previewed + ':' + ex.getMessage() +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,dsResult.reason);
 		}catch (Exception ex) { //AR-15 JSONResult addMessage handles DML Exception
        	dsResult.success = false;
        	dsResult.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            dsResult.addMessage(Label.Payments_Cannot_Be_Previewed  +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,dsResult.reason);
        } 
        
        system.debug('dsResult ='+dsResult);
        return dsResult;
    }
    //create payment from immediate mode  
    @RemoteAction  
    public static JsonResult CreateFinalizePaymentsForImmediate(List<KendoUtils.FilterDescriptor> filters, GridRelatedListController.GridRelatedListConfig config,List<SupplierPaymentService.paymentWithLinesWrapper> paymentWrapperList) {
        JsonResult result = new JsonResult();
        SupplierPaymentService spPaymentServiceCls = new SupplierPaymentService();
        boolean totalCreditsExceedsDebits = false;
        try{
	        
	        system.debug(LoggingLevel.Error,'paymentWrapperList=='+paymentWrapperList);       
		    for(KendoUtils.FilterDescriptor fd: filters){
	            system.debug(LoggingLevel.info,'Filter: ' + fd);            
	            if (fd.field == 'totalCreditsExceedsDebits'){                
	                totalCreditsExceedsDebits = String.valueOf(fd.value).toLowerCase() == 'true' ? True : False;
	            }               
	        }         
	        SupplierPaymentService spService = new SupplierPaymentService();
	        List<Supplier_Payment__c> spList = new List<Supplier_Payment__c>();
	        List<Supplier_Payment_Line__c> spLinesList = new List<Supplier_Payment_Line__c>();
	        for (SupplierPaymentService.paymentWithLinesWrapper paymentWrapper :paymentWrapperList){
	        	spList.add(paymentWrapper.supplierPayment);
	        	for (Supplier_Payment_Line__c spLine:paymentWrapper.lstPaymentLines){
	        		spLine.Supplier_Payment__r = new Supplier_Payment__c (Source_Key__c = paymentWrapper.supplierPayment.Source_Key__c);
	        		spLinesList.add(spLine);
	        	}
	        }
	        paymentWrapperList = spService.CreateFinalizePaymentsForImmediate(totalCreditsExceedsDebits,config,spList,spLinesList);  
	        	        
	        
	        result.records = paymentWrapperList;
	        if (paymentWrapperList[0].messages.size() == 0){
	        	//result.addMessage(Label.Payment_Created_Successfully,ApexPages.Severity.CONFIRM);
	        	result.success = true;
	        }else
	        	result.success = false; 
	        for (string msg : paymentWrapperList[0].messages) 
	        	result.addMessage(Label.Payments_Cannot_Be_Created + ': ' + msg + Label.Contact_Kenandy_administrator_for_help ,ApexPages.Severity.ERROR);        
        }catch(CustomException ex){
        	result.success = false;
        	system.debug(LoggingLevel.ERROR,'custom exception errorMessage=='+ ex.getMessage());
        	string errorMessage = ex.getMessage();
        	Integer location;   
        	if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')|| errorMessage.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,') : new List<string>();
 					msgArray = errorMessage.contains('REQUIRED_FIELD_MISSING') ? errorMessage.split('REQUIRED_FIELD_MISSING,') : new List<string>();

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
            result.addMessage(errorMessage,ApexPages.Severity.ERROR);
            result.reason = ex.getMessage();
            system.debug(LoggingLevel.ERROR,ex.getMessage());
        }catch(DMLException ex) { 
        	set<string> errMsgSet = new set<string>();
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug(LoggingLevel.ERROR,'errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getDmlMessage(idx) +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
 					msgArray = errorMessage.split('REQUIRED_FIELD_MISSING,');

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
                errMsgSet.add(ex.getDmlStatusCode(idx)+ '-'+errorMessage);
                system.debug(LoggingLevel.Error,'inside dml exception errorMessage : ' + errMsgSet);                    
        	}
        	result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
        	
        	for (string strMsg: errMsgSet){
        		integer strIndex = strMsg.indexOf('.');
            	result.addMessage(Label.Payments_Cannot_Be_Created + ': ' + (strIndex > 0 ? strMsg + ' '  : strMsg +'. ') + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);  
        	}          
            system.debug(LoggingLevel.ERROR,result.reason);
		}
        catch ( DML.InsuffientAccessException ex ) { 
 			result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            result.addMessage(Label.Payments_Cannot_Be_Created + ': ' + ex.getMessage() +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,result.reason);
 		}catch (Exception ex) { //AR-15 JSONResult addMessage handles DML Exception
        	result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            result.addMessage(Label.Payments_Cannot_Be_Created   + ': ' + ex.getMessage() +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,result.reason);
        }  
        return result; 
    }  
    //KNDY-19040 - Separate remoting method to update SI back after payments are finalized
    @RemoteAction
    public static JsonResult updateSupplierInoiceForFinalizedPayments(List<String> supplierInvoiceIdList,List<String> supplierPaymentIdList){
    	JsonResult result = new JsonResult();
    	try{    		
    		SupplierPaymentService spService = new SupplierPaymentService();
    		
	        Set<String>  supplierInvoiceIdSet;
	        if (supplierInvoiceIdList != null) supplierInvoiceIdSet = new Set<String>(supplierInvoiceIdList);
	        else supplierInvoiceIdSet = new set<String>();
	        
	        Set<String>  supplierPaymentIdSet;
	        if (supplierPaymentIdList != null) supplierPaymentIdSet = new Set<String>(supplierPaymentIdList);
	        else supplierPaymentIdSet = new set<String>();
	        system.debug(LoggingLevel.Error,'supplierInvoiceIdSet == ' + supplierInvoiceIdSet.size() +  ' supplierPaymentIdSet Size : ' + supplierPaymentIdSet.size());
	        spService.updateSupplierInoiceForFinalizedPayments(supplierInvoiceIdSet,supplierPaymentIdSet);
	        
        	result.addMessage(Label.Payment_Created_Successfully,ApexPages.Severity.CONFIRM);
        	result.success = true;
    	}catch(CustomException ex){
        	result.success = false;
        	system.debug(LoggingLevel.ERROR,'custom exception errorMessage=='+ ex.getMessage());
        	string errorMessage = ex.getMessage();
        	Integer location;   
        	if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')|| errorMessage.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,') : new List<string>();
 					msgArray = errorMessage.contains('REQUIRED_FIELD_MISSING') ? errorMessage.split('REQUIRED_FIELD_MISSING,') : new List<string>();

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
            result.addMessage(errorMessage,ApexPages.Severity.ERROR);
            result.reason = ex.getMessage();
            system.debug(LoggingLevel.ERROR,ex.getMessage());
        }catch(DMLException ex) { 
        	set<string> errMsgSet = new set<string>();
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug(LoggingLevel.ERROR,'errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getDmlMessage(idx) +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
 					msgArray = errorMessage.split('REQUIRED_FIELD_MISSING,');

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
                errMsgSet.add(ex.getDmlStatusCode(idx)+ '-'+errorMessage);
                system.debug(LoggingLevel.Error,'inside dml exception errorMessage : ' + errMsgSet);                    
        	}
        	result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
        	for (string strMsg: errMsgSet)
            	result.addMessage(Label.Payments_Cannot_Be_Created + ': ' + strMsg +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,result.reason);
		}
        catch ( DML.InsuffientAccessException ex ) { 
 			result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            result.addMessage(Label.Payments_Cannot_Be_Created + ': ' + ex.getMessage() +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,result.reason);
 		}catch (Exception ex) { //AR-15 JSONResult addMessage handles DML Exception
        	result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            result.addMessage(Label.Payments_Cannot_Be_Created  +':' + ex.getMessage() +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,result.reason);
        }  
        return result; 
    }
    //KNDY-19040 - in case of "Apex CPU timeout" error while updating invoices back , cancel all SPs which are created and finalized and previous call
    @RemoteAction
    public static JsonResult cancelSPs(List<String> supplierPaymentIdList){
    	JsonResult result = new JsonResult();
    	SupplierPaymentService spService = new SupplierPaymentService();
    	try{
    		Set<String>  supplierPaymentIdSet = new Set<String>(supplierPaymentIdList);
    		system.debug(LoggingLevel.Error,'Cancel SPs' + supplierPaymentIdSet.size());
    		List<Supplier_Payment__c> SPToCancel = [select Id,Status__c, Finalized__c,Finalized_Hidden__c from Supplier_Payment__c where Id IN :supplierPaymentIdSet];
    		system.debug(LoggingLevel.Error,'Cancel SPs' + SPToCancel.size());
    		spService.CancelSPs(SPToCancel);
    	}catch(CustomException ex){ 
        	result.success = false;
        	system.debug(LoggingLevel.ERROR,'custom exception errorMessage=='+ ex.getMessage());
        	string errorMessage = ex.getMessage();
        	Integer location;   
        	if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')|| errorMessage.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,') : new List<string>();
 					msgArray = errorMessage.contains('REQUIRED_FIELD_MISSING') ? errorMessage.split('REQUIRED_FIELD_MISSING,') : new List<string>();

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
            result.addMessage(errorMessage,ApexPages.Severity.ERROR);
            result.reason = ex.getMessage();
            system.debug(LoggingLevel.ERROR,ex.getMessage());
        }catch(DMLException ex) { 
        	set<string> errMsgSet = new set<string>();
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {                
                    string errorMessage = ex.getDmlMessage(idx);
                    string statusCode = ex.getDmlStatusCode(idx);
                    Integer location;    
                    system.debug(LoggingLevel.ERROR,'errorMessage=='+ ex.getStackTraceString() + '-message = ' + ex.getDmlMessage(idx) +'getDmlStatusCode' + ex.getDmlStatusCode(idx));
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') || statusCode.contains('REQUIRED_FIELD_MISSING')){
                    list<string> msgArray = errorMessage.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
 					msgArray = errorMessage.split('REQUIRED_FIELD_MISSING,');

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
                errMsgSet.add(ex.getDmlStatusCode(idx)+ '-'+errorMessage);
                system.debug(LoggingLevel.Error,'inside dml exception errorMessage : ' + errMsgSet);                    
        	}
        	result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
        	for (string strMsg: errMsgSet)
            	result.addMessage(Label.Payments_Cannot_Be_Created + ': ' + strMsg +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,result.reason);
		}
        catch (Exception ex) { //AR-15 JSONResult addMessage handles DML Exception
        	result.success = false;
        	result.reason = ex.getMessage()  + '=' + ex.getStackTraceString();
            result.addMessage(Label.Payments_Cannot_Be_Created  +'.' + Label.Contact_Kenandy_administrator_for_help,ApexPages.Severity.ERROR);            
            system.debug(LoggingLevel.ERROR,result.reason);
        }  
        return result; 
    }  
}