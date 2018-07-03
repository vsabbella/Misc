public with sharing class CustomerReceiptManageExt extends GridRelatedListController {
	ApexPages.StandardController con;
	
	public class CustomerReceiptManageExtException extends Exception{
	    
	}
	public class CreditMemoWrapper {
	    boolean selected = false;
	   @TestVisible Customer_Invoice__c creditMemo = new Customer_Invoice__c();
	    Customer_Receipt_Line__c paymentLine = new Customer_Receipt_Line__c();
        Customer_Receipt_Line__c writeOffLine = new Customer_Receipt_Line__c();
        
	}
	
	public class DeductionWrapper {
	    @TestVisible Customer_Receipt_Line__c deduction = new Customer_Receipt_Line__c();
	    Customer_Invoice__c creditMemo = new Customer_Invoice__c();
	}
	
	public class CustomerInvoiceWrapper { 
	     @TestVisible Customer_Invoice__c customerInvoice = new Customer_Invoice__c();
	     @TestVisible Decimal ciEarnedDiscountAmount = 0;//KNDY-17349
	     @TestVisible Decimal ciUnearnedDiscountAmount = 0;//KNDY-17349
		Customer_Receipt_Line__c paymentLine = new Customer_Receipt_Line__c();
		Customer_Receipt_Line__c writeOffLine = new Customer_Receipt_Line__c();
		Customer_Receipt_Line__c earnedDiscountLine = new Customer_Receipt_Line__c();
		Customer_Receipt_Line__c unearnedDiscountLine = new Customer_Receipt_Line__c();
		List<Customer_Receipt_Line__c> invoiceDeductions = new List<Customer_Receipt_Line__c>();
		 @TestVisible boolean selected = false;
	}
	
	public class ClaimWrapper {
		boolean selected = false;
		Decimal amountApplied;
		Claim__c claim = new Claim__c();
		Customer_Receipt_Line__c claimLine = new Customer_Receipt_Line__c();
	}
	
	public class AdditionalPaymentWrapper {
	    Customer_Invoice__c creditMemo = new Customer_Invoice__c();
		@TestVisible Customer_Receipt_Line__c additionalPayment = new Customer_Receipt_Line__c();
	}
	
	public static final String TYPE_GENERAL_DEDUCTION = 'General Deduction';
	public static List<String> paymentLineTypes = new List<String>{'Credit Memo', 'Earned Terms Discount', 'Invoice Deduction', 'Payment', 'Unearned Terms Discount', 'Writeoff'};
	public static List<String> additionalPaymentTypes = new List<String>{PaymentService.TYPE_OVERPAYMENT, PaymentService.TYPE_PREPAYMENT};
	public static String NspaceUU { get { return KSE.NamespaceUU; }}
	
	public String creditMemoFieldList ;
	public String deductionFieldList ;
	public String customerInvoiceFieldList ;
	public String customerInvoiceDetailFieldList ;
	public String claimFieldList ;
	public String additionalPaymentFieldList ;
	
	public GridRelatedListController.GridRelatedListConfig creditMemosGridConfig {get; set;}
	public GridRelatedListController.GridRelatedListConfig deductionsGridConfig {get; set;}
	public GridRelatedListController.GridRelatedListConfig customerInvoicesGridConfig {get; set;}
	public GridRelatedListController.GridRelatedListConfig customerInvoiceDetailsGridConfig {get; set;}
	public GridRelatedListController.GridRelatedListConfig claimsGridConfig {get; set;}
	public GridRelatedListController.GridRelatedListConfig additionalPaymentsGridConfig {get; set;}
	
   public String getCreditMemosGridConfigJson() {
        String configStr = JSON.serialize(this.creditMemosGridConfig);
        return configStr;
    }
    
    public String getDeductionsGridConfigJson() {
        String configStr = JSON.serialize(this.deductionsGridConfig);
        return configStr;
    }
    
	public String getCustomerInvoicesGridConfigJson() {
        String configStr = JSON.serialize(this.customerInvoicesGridConfig);
        return configStr;
    }
    
    public String getCustomerInvoiceDetailsGridConfigJson() {
        String configStr = JSON.serialize(this.customerInvoiceDetailsGridConfig);
        return configStr;
    }
    
    public String getClaimsGridConfigJson() {
        String configStr = JSON.serialize(claimsGridConfig);
        return configStr;
    }
    
    public String getAdditionalPaymentsGridConfigJson() {
        String configStr = JSON.serialize(additionalPaymentsGridConfig);
        return configStr;
    }
   
    private  static Decimal getEarnedDiscountAmount(Customer_Invoice__c ci, DateTime dateReceived){ //KNDY-17349
        Decimal discount = (ci.Payment_Term__c == null || ci.Payment_Term__r.discount_Percent__c == null)? 0 : (ci.Payment_Term__r.discount_Percent__c/100) * ci.Balance__c;
        Date discountDate = getDateFromDateTime(ci.Early_Payment_Discount_Date__c); //DateTime field conversion
        Date dateToday = getDateFromDateTime(dateReceived);
        if( discountDate < dateReceived){
            discount = 0.0;
        }
        else if ( ci.Total_Amount__c != ci.Balance__c){
            discount = 0.0;
        }
        return discount;
    }
    
    public static Date getDateFromDateTime( DateTime dateTimeVar){
        Date ret = date.newinstance(dateTimeVar.year(), dateTimeVar.month(), dateTimeVar.day());
        return ret;
    }

    public string getKeyPrefix() {
    	return Customer_Receipt__c.SObjectType.getDescribe().getKeyPrefix();
    }
    public String getReturnUrl(){
		PageReference pageRef;
        
        if (con != null && con.getId() != null ){
            pageRef =  new PageReference('/' + con.getId());
        }
        else{
            Schema.DescribeSObjectResult dsr = Customer_Receipt__c.SObjectType.getDescribe();
            pageRef = new PageReference('/' + dsr.getKeyPrefix());    
        }
        
        return pageRef.getUrl();	
	}
	
	public boolean renderGrid {get;set;}
	
	public static boolean isRenderGrid (String crId) {
		
		system.debug('crId '+ crId);
		if(crId == '' || crId == null)
			return true;
		SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Void__c','Status__c'
		});
		soql.setWhereClause('id = :crId');
		soql.setLimit(1);
		Customer_Receipt__c cr = Database.query(soql.getQuery());
		
		if(cr.Void__c || cr.Status__c == 'Closed' || cr.Status__c == 'Cancelled') 
			return false;
		else 
			return true;
	}
	
	public CustomerReceiptManageExt(ApexPages.StandardController scon){
		
		con = scon;
		Id customerReceiptId = con.getId();
		
		if(String.isBlank(customerReceiptId) == false){
			List<Customer_Receipt__c> customerReceipts = new List<Customer_Receipt__c>();
			SchemaUtil shUtil = new SchemaUtil();
			JsonResult result = new JsonResult();
		
			String whereClause = ' Id = :customerReceiptId';
			SOQLUtil soql = new SOQLUtil('Customer_Receipt__c',true);
            soql.addFields('Apply_Payment');
            soql.addFields(new Set<String>{'Finalized__c','Status__c','Void__c','Customer__r.RecordType.Name','Total_Number_Of_Lines__c'});
            soql.setWhereClause(whereClause);
			//String queryString = shUtil.generateQueryFromFieldSet('Customer_Receipt__c', new Set<String>{'Apply_Payment'}, new Set<String>{'Finalized__c','Status__c','Void__c','Customer__r.RecordType.Name','Total_Number_Of_Lines__c'}, whereClause);
			//customerReceipts = (List<Customer_Receipt__c>) Database.query(queryString);	
            customerReceipts = (List<Customer_Receipt__c>) Database.query( soql.getQuery());
			
			
			renderGrid = true;
			system.debug('customerReceipts[0].Customer__r.RecordType.Name: '+customerReceipts[0].Customer__r.RecordType.Name);
			if(customerReceipts[0].Void__c)
				renderGrid = false;
			else if(customerReceipts[0].Status__c =='Closed' || customerReceipts[0].Status__c =='Cancelled' || customerReceipts[0].Status__c == CustomerReceiptService.STATUS_HELD_FOR_REVIEW)
				renderGrid = false;
			
			con = new ApexPages.StandardController(customerReceipts[0]);
		}
		else
			renderGrid = true;
		
		
        // Credit Memos Grid Config
        creditMemosGridConfig = new GridRelatedListController.GridRelatedListConfig();
        creditMemosGridConfig.uniqueId = 'creditMemosGrid';
        creditMemosGridConfig.title = 'Credit Memos';
        creditMemosGridConfig.objectName = 'Customer_Invoice__c';
        creditMemosGridConfig.fieldset = 'New_Customer_Credit_Memo';
        creditMemosGridConfig.buttons = renderGrid == true ? 'cancel, search' : '';
        creditMemosGridConfig.alwaysUseFullDateTimeFormat = false;
        
        // Deductions Grid Config
        deductionsGridConfig = new GridRelatedListController.GridRelatedListConfig();
        deductionsGridConfig.uniqueId = 'deductionsGrid';
        deductionsGridConfig.title = 'General Deductions';
        deductionsGridConfig.objectName = 'Customer_Receipt_Line__c';
        deductionsGridConfig.fieldset = 'Deduction_fields';
        deductionsGridConfig.buttons = renderGrid == true ? 'create, cancel, search, delete' : '';
        deductionsGridConfig.alwaysUseFullDateTimeFormat = false;
        
        // Customer Invoices Grid Config
        customerInvoicesGridConfig = new GridRelatedListController.GridRelatedListConfig();
        customerInvoicesGridConfig.uniqueId = 'customerInvoicesGrid';
        customerInvoicesGridConfig.title = 'Customer Invoices';
        customerInvoicesGridConfig.objectName = 'Customer_Invoice__c'; //TODO: Change to fieldset on Customer_Receipt_Line__c 
        customerInvoicesGridConfig.fieldset = 'Customer_Receipt_RO'; //'Payment_Line_RO';
        customerInvoicesGridConfig.buttons = renderGrid == true ? 'cancel, search' : '';//, create, delete';
        customerInvoicesGridConfig.alwaysUseFullDateTimeFormat = false;
        
        // Customer Invoice Details Grid Config
        customerInvoiceDetailsGridConfig = new GridRelatedListController.GridRelatedListConfig();
        customerInvoiceDetailsGridConfig.uniqueId = 'customerInvoiceDetailsGrid';
        customerInvoiceDetailsGridConfig.title = 'Customer Invoice Details';
        customerInvoiceDetailsGridConfig.objectName = 'Customer_Receipt_Line__c'; 
        customerInvoiceDetailsGridConfig.fieldset = 'Deduction_fields';
        customerInvoiceDetailsGridConfig.buttons = renderGrid == true ?  'cancel, search, create, delete' : '';
        customerInvoiceDetailsGridConfig.alwaysUseFullDateTimeFormat = false;
		
		// Claims Grid Config
        claimsGridConfig = new GridRelatedListController.GridRelatedListConfig();
        claimsGridConfig.uniqueId = 'claimsGrid';
        claimsGridConfig.title = 'Claims';
        claimsGridConfig.objectName = 'Claim__c'; 
        claimsGridConfig.fieldset = 'Customer_Receipt_RO';
        claimsGridConfig.buttons = renderGrid == true ?  'cancel, search' :''; //'create, cancel, search, delete';
        claimsGridConfig.alwaysUseFullDateTimeFormat = false;
        
        // Additional payments Grid Config
        additionalPaymentsGridConfig = new GridRelatedListController.GridRelatedListConfig();
        additionalPaymentsGridConfig.uniqueId = 'additionalPaymentsGrid';
        additionalPaymentsGridConfig.title = 'Additional Payments';
        additionalPaymentsGridConfig.objectName = 'Customer_Receipt_Line__c'; 
        additionalPaymentsGridConfig.fieldset = 'Overpayment';
        additionalPaymentsGridConfig.buttons = renderGrid == true ?  'create, cancel, search, delete' : '';
        additionalPaymentsGridConfig.alwaysUseFullDateTimeFormat = false;
	}
	public string getCustomerReceiptHeaderFieldList() {
        String CustomerReceiptHeaderFieldList = '';
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Customer_Receipt__c', 'Cash_App_Header');
        fieldInfoList.remove(0); //remove ID
        for(FieldInfo f : fieldInfoList) 
        	f.editable = renderGrid;
        CustomerReceiptHeaderFieldList = JSON.serialize(fieldInfoList);
        return CustomerReceiptHeaderFieldList;
    }
    
    public string getCustomerReceiptPaymentFieldList() {
        String CustomerReceiptPaymentFieldList = '';
        
        
        List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Customer_Receipt__c', 'Apply_Payment');
        fieldInfoList.remove(0); //remove ID
        for(FieldInfo f : fieldInfoList) 
        	f.editable = renderGrid; 
        CustomerReceiptPaymentFieldList = JSON.serialize(fieldInfoList);
        
        return CustomerReceiptPaymentFieldList;
    }
    
    public string getCustomerReceiptHeaderAdditionalFieldList() {
        String CustomerReceiptHeaderAdditionalFieldList = '';
        try {
        	List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos('Customer_Receipt__c', 'Cash_App_Additional');
        	fieldInfoList.remove(0); //remove ID
	        for(FieldInfo f : fieldInfoList) 
	        	f.editable = true;
       		CustomerReceiptHeaderAdditionalFieldList = JSON.serialize(fieldInfoList);
        }catch (FieldInfo.EmptyFieldSetMemberException e) {
            CustomerReceiptHeaderAdditionalFieldList = '';

        }
        
        return CustomerReceiptHeaderAdditionalFieldList;
    }
    
    public string getCustomerReceiptPaymentTotalFieldList() {
        String CustomerReceiptPaymentTotalFieldList = '';
        
        List<FieldInfo> fieldList = new List<FieldInfo>();
        
        FieldInfo amountToApply = new FieldInfo();
    	amountToApply.field = 'amountToApply';
    	amountToApply.title = 'Amount To Apply';
    	amountToApply.fieldtype = 'double';
    	amountToApply.editable = false;
    	fieldList.add(amountToApply);
    	
    	
    	
    	FieldInfo amountUnapplied = new FieldInfo();
    	amountUnapplied.field = 'amountUnapplied';
    	amountUnapplied.title = 'Amount Unapplied';
    	amountUnapplied.fieldtype = 'double';
    	amountUnapplied.editable = false;
    	fieldList.add(amountUnapplied);
    	
    	FieldInfo totalPayment = new FieldInfo();
    	totalPayment.field = 'totalPayment';
    	totalPayment.title = 'Total Payment';
    	totalPayment.fieldtype = 'double';
    	totalPayment.editable = false;
    	fieldList.add(totalPayment);
    	
       CustomerReceiptPaymentTotalFieldList = JSON.serialize(fieldList);
        return CustomerReceiptPaymentTotalFieldList;
    }
	
    public String getCreditMemoFieldList() {
        if (String.isBlank(creditMemoFieldList) && creditMemosGridConfig != null) {
        	
        	// get the credit memo field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        	
        	// get the Payment line details field info list
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos(creditMemosGridConfig.objectName, creditMemosGridConfig.fieldset));
            
            Set<String> hiddenFields = new Set<String> { 'Id'};
            set<String> editableFields = new set<String>{'Amount_To_Apply__c' ,'Write_Off_Amount__c','Resolution_Code__c','Memo__c'};
            // set all the fields as readonly
            for(Integer i = 1; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = 'creditMemo.' + fieldName;
                fieldInfoList[i].editable = false;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);

                if(editableFields.contains(fieldName)){
            	    fieldInfoList[i].editable = true;    
            	}
                if(fieldName == 'Resolution_Code__c'){
            	    fieldInfoList[i].title = 'Reason Code';
                    fieldInfoList[i].referenceTo = 'Reason_Code__c';
                    fieldInfoList[i].required = true;
            }
          		 if(fieldInfoList[i].field =='creditMemo.Name'){
                  fieldInfoList[i].referenceTo = 'creditMemo.Id';
                  fieldInfoList[i].fieldtype ='Name';
             	}
            }
            
            creditMemoFieldList = JSON.serialize(fieldInfoList);
        }
        
        return creditMemoFieldList;
    }
    
    public String getDeductionFieldList() {
        if (String.isBlank(deductionFieldList) && deductionsGridConfig != null) {
        	
        	FieldInfo fieldInfoItem;
        	
        	// get the Substitutions field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(deductionsGridConfig.objectName, deductionsGridConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id'};
            
            // set all the fields as readonly
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = 'deduction.'+fieldName;
                fieldInfoList[i].editable = true;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
                if(fieldInfoList[i].field =='deduction.Name'){
                  fieldInfoList[i].referenceTo = 'deduction.Id';
                  fieldInfoList[i].fieldtype ='Name';
             }
            }
            
            deductionFieldList = JSON.serialize(fieldInfoList);
        }
        
        return deductionFieldList;
    }
    
    public String getCustomerInvoiceFieldList() {
        if (String.isBlank(customerInvoiceFieldList) && customerInvoicesGridConfig != null) {
        	
        	FieldInfo fieldInfoItem;
        	
        	// get the Payment lines field info list
            List<FieldInfo> fieldInfoList = new List<FieldInfo>();
            Set<String> hiddenFields = new Set<String> { 'Id','Debit_Applied__c','Credit_Applied__c', 'Discount_Taken__c'};
            set<String> editableFields = new set<String>{'Write_Off_Amount__c','Amount_Applied__c', 'selected','Resolution_Code__c','Memo__c'};
            FieldInfo selectFieldInfoItem = new FieldInfo();
        	selectFieldInfoItem.field = 'selected';
        	selectFieldInfoItem.title = 'Select';
        	selectFieldInfoItem.fieldtype = 'boolean';
        	selectFieldInfoItem.editable = renderGrid;
        	fieldInfoList.add(selectFieldInfoItem);
            
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos(customerInvoicesGridConfig.objectName, customerInvoicesGridConfig.fieldset));
            
            Integer indexOfTotalAmt = -1; //KNDY-17349
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            if ( fieldName == 'Total_Amount__c'){
                indexOfTotalAmt = i;//KNDY-17349
            }
            	if(editableFields.contains(fieldName)){
                	fieldInfoList[i].editable = true;
            	}else{
            		fieldInfoList[i].editable = false;
            	}
            	if(fieldName != 'selected')
            		fieldInfoList[i].field = 'customerInvoice.' + fieldName;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            
            if(fieldInfoList[i].field =='customerInvoice.Name'){
                  fieldInfoList[i].referenceTo = 'customerInvoice.Id';
                  fieldInfoList[i].fieldtype ='Name';
             }
                if(fieldName =='Resolution_Code__c'){
                  fieldInfoList[i].title = 'Reason Code';
                  fieldInfoList[i].referenceTo ='Reason_Code__c';
                  fieldInfoList[i].required = true;
                }
            }
            
            FieldInfo earnedDiscountAmountField = new FieldInfo();
            earnedDiscountAmountField.field = 'earnedDiscountAmount';
            earnedDiscountAmountField.title = 'Earned Discount Amount';
            earnedDiscountAmountField.fieldtype = 'double';
            earnedDiscountAmountField.scale = 2;  
            earnedDiscountAmountField.editable = true;
            
            FieldInfo unearnedDiscountAmountField = new FieldInfo();
            unearnedDiscountAmountField.field = 'unearnedDiscountAmount';
            unearnedDiscountAmountField.title = 'Unearned Discount Amount';
            unearnedDiscountAmountField.fieldtype = 'double';
            unearnedDiscountAmountField.scale = 2;  
            unearnedDiscountAmountField.editable = true;
            
            fieldInfoList.add(indexOfTotalAmt+1, earnedDiscountAmountField);
            fieldInfoList.add(indexOfTotalAmt+2, unearnedDiscountAmountField);

            customerInvoiceFieldList = JSON.serialize(fieldInfoList);
        }
        
        return customerInvoiceFieldList;
    }
    
    public String getCustomerInvoiceDetailFieldList() {
        if (String.isBlank(customerInvoiceDetailFieldList) && customerInvoiceDetailsGridConfig != null) {
        	
        	FieldInfo fieldInfoItem;
        	
        	// get the Payment line details field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(customerInvoiceDetailsGridConfig.objectName, customerInvoiceDetailsGridConfig.fieldset);
            Set<String> hiddenFields = new Set<String> {'Id'};
            
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	system.debug('Field Name: '+fieldName);
            	fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = true;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            	
            	if(fieldName == 'Type__c'){
            		fieldInfoList[i].selectList.clear();
            		fieldInfoList[i].selectList.add(new SelectListItem('--None--', '--'+Label.None+'--'));
            		fieldInfoList[i].selectList.add(new SelectListItem('Payment', Label.Payment));
            		fieldInfoList[i].selectList.add(new SelectListItem('Invoice Deduction', Label.Invoice_Deduction));
            		fieldInfoList[i].selectList.add(new SelectListItem('WriteOff', Label.WriteOff));
            	}
            	if(fieldInfoList[i].field =='claim.Name'){
                  fieldInfoList[i].referenceTo = 'claim.Id';
                  fieldInfoList[i].fieldtype ='Name';
            }
            }
            
            customerInvoiceDetailFieldList = JSON.serialize(fieldInfoList);
        }
        
        return customerInvoiceDetailFieldList;
    }
    
    public String getClaimFieldList() {
        if (String.isBlank(claimFieldList) && claimsGridConfig != null) {
        	
        	List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        
        	FieldInfo selectFieldInfoItem = new FieldInfo();
        	selectFieldInfoItem.field = 'selected';
        	selectFieldInfoItem.title = 'Select';
        	selectFieldInfoItem.fieldtype = 'boolean';
        	selectFieldInfoItem.editable = renderGrid;
        	
        	// Add selected column to the field info list.
        	fieldInfoList.add(selectFieldInfoItem);
        	
        	FieldInfo amountField = new FieldInfo();
        	amountField.field = 'amountApplied';
        	amountField.title = 'Amount Applied';
        	amountField.fieldtype = 'double';
        	amountField.scale = 2;  
        	amountField.editable = renderGrid;
        	fieldInfoList.add(amountField);
        	// get the Payment line details field info list
            fieldInfoList.addAll(FieldInfo.fetchJsonFieldInfos(claimsGridConfig.objectName, claimsGridConfig.fieldset));
            
            Set<String> hiddenFields = new Set<String> {'Id'};
            
            for(Integer i = 2; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = 'claim.' + fieldName;
            	fieldInfoList[i].editable = false;	
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            	if(fieldName == 'Resolution_Code__c'){
            		fieldInfoList[i].referenceTo = 'Reason_Code__c';
            	}
            	//OTC-333
                if(fieldName.contains('Resolution_Code__c')){                    
                    fieldInfoList[i].editable = true;
                }
                
                  if(fieldInfoList[i].field =='claim.Name'){
                  fieldInfoList[i].referenceTo = 'claim.Id';
                  fieldInfoList[i].fieldtype ='Name';
             }
                
            }
            
            claimFieldList = JSON.serialize(fieldInfoList);
        }
        
        return claimFieldList;
    }
    
    public String getAdditionalPaymentFieldList() {
        if (String.isBlank(additionalPaymentFieldList) && additionalPaymentsGridConfig != null) {
        	
        	FieldInfo fieldInfoItem;
        	
        	// get the Payment line details field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(additionalPaymentsGridConfig.objectName, additionalPaymentsGridConfig.fieldset);
            Set<String> hiddenFields = new Set<String> {'Id'};
            
            for(Integer i = 0; i < fieldInfoList.size(); i++){
            	String fieldName = fieldInfoList[i].field;
            	fieldInfoList[i].field = 'additionalPayment.' + fieldName;
                fieldInfoList[i].editable = true;
            	fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            	
            	if(fieldName == 'Type__c'){
            		fieldInfoList[i].selectList.clear();
            		//fieldInfoList[i].selectList.add(new SelectListItem('--None--', '--'+Label.None+'--'));  AR-98 commenting out this picklist value. 
            		fieldInfoList[i].selectList.add(new SelectListItem(PaymentService.TYPE_PREPAYMENT, PaymentService.TYPE_PREPAYMENT));
            		fieldInfoList[i].selectList.add(new SelectListItem(PaymentService.TYPE_OVERPAYMENT, PaymentService.TYPE_OVERPAYMENT));
            	}
            	
            	
	        }
            
            additionalPaymentFieldList = JSON.serialize(fieldInfoList);
        }
        
        return additionalPaymentFieldList;
    }
    
	
	
	@RemoteAction
	public static JsonResult getCreditMemos(String companyId, String customerId, Id currencyId, String customerReceiptId){
		if(customerId.trim() == '' || customerId == null) {
			JsonResult result = new JsonResult();
			result.records = new List<CreditMemoWrapper>();
	        return result;
		}else {
			List<CreditMemoWrapper> creditMemosList = new List<CreditMemoWrapper>();
			SchemaUtil shUtil = new SchemaUtil();
			
			Map<Id, Customer_Receipt_Line__c> creditMemoPaymentsMap = new Map<Id, Customer_Receipt_Line__c>();
			Map<Id, Customer_Receipt_Line__c> creditMemoWriteOffMap = new Map<Id, Customer_Receipt_Line__c>();
			Set<Id> generalDeductions = new Set<Id>();
			Decimal writeOff_Amount_onCRL = 0.0;
			
			Set<String> crlTypes = new Set<String>{PaymentService.TYPE_GEN_DED, PaymentService.TYPE_CREDIT_MEMO, PaymentService.TYPE_PREPAYMENT_CREDIT, PaymentService.TYPE_OVERPAYMENT_CREDIT, PaymentService.TYPE_OVERPAYMENT, PaymentService.TYPE_PREPAYMENT,  PaymentService.TYPE_WRITEOFF_CREDIT};
			SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{ //kndy-13995
				'Id','Customer_Invoice__r.Invoice_Type__c','Customer_Invoice__r.Total_Amount__c','Customer_Invoice__c','Amount__c','Type__c','Reason_Code__c','Reason_Code__r.Name','Memo__c'
			});
			soql.setWhereClause('Customer_Receipt__c = :customerReceiptId AND Type__c IN :crlTypes');
			
			for(Customer_Receipt_Line__c crl : Database.query(soql.getQuery())){

			    if(crl.Type__c == PaymentService.TYPE_CREDIT_MEMO || crl.Type__c == PaymentService.TYPE_PREPAYMENT_CREDIT || crl.Type__c == PaymentService.TYPE_OVERPAYMENT_CREDIT){
			        if(! String.isBlank(crl.Customer_Invoice__c) && crl.Customer_Invoice__r.Invoice_Type__c != AllowanceRuleService.ALLOWANCE_ACCRUAL){ //KNDY-15037,KNDY-13995
			            creditMemoPaymentsMap.put(crl.Customer_Invoice__c, crl); //KNDY-13995
			        }
			    }
			    else
			    if(crl.Type__c == PaymentService.TYPE_PREPAYMENT || crl.Type__c == PaymentService.TYPE_OVERPAYMENT || crl.Type__c == PaymentService.TYPE_GEN_DED){
			        if(! String.isBlank(crl.Customer_Invoice__c)){ //KNDY-13995
			            generalDeductions.add(crl.Customer_Invoice__c); //KNDY-13995
			        }
			    }
			    else if( crl.Type__c == PaymentService.TYPE_WRITEOFF_CREDIT){
			        system.debug(logginglevel.error,'! String.isBlank(crl.Customer_Invoice__c)---->'+! String.isBlank(crl.Customer_Invoice__c)); //KNDY-13995
			        if(! String.isBlank(crl.Customer_Invoice__c)){ //KNDY=13995
			            if(crl.Amount__c > 0){
                            writeOff_Amount_onCRL = crl.Amount__c;
			            }
                        creditMemoWriteOffMap.put(crl.Customer_Invoice__c, crl); //KNDY-13995
                    }
                    
			    }
			}
			
			Set<Id> appliedCreditMemos = creditMemoPaymentsMap.keySet();
			Set<Id> appliedWriteOffs = creditMemoWriteOffMap.keySet();
			System.debug(logginglevel.error,'appliedWriteOffs-->'+appliedWriteOffs);
			System.debug(logginglevel.error,'appliedCreditMemos-->'+appliedCreditMemos);
			System.debug(logginglevel.error,'isRenderGrid(customerReceiptId)-->'+isRenderGrid(customerReceiptId));
			String whereClause = isRenderGrid(customerReceiptId) == true ? ' ( Sold_To_Customer__c = :customerId' +
	        	   			     '   OR Bill_To_Customer__c = :customerId' +
	        					 '   OR Customer__c =  :customerId' +
	                    		 ' )' +
	                    		 ' AND Id NOT IN :generalDeductions' +
	                    		 ' AND (Id IN :appliedCreditMemos OR Id IN :appliedWriteOffs OR Balance__c < 0.0)'// JIRA OTC-319 //KK: Include the write off map here in the query
	                    		 +' and Finalized__c = true'
                				 +' AND Currency__c = :currencyId'
                                 +' AND Company__c = :companyId'
                                 +' AND Invoice_Type__c != \'' + AllowanceRuleService.ALLOWANCE_ACCRUAL + '\'' //KNDY-15037
	                    		 +' and Status__c not in (\'Closed\',\'Cancelled\',\'Void\')' : 'Id IN :appliedCreditMemos OR Id IN :appliedWriteOffs'; //OTC-816

	                    		 
	        SOQLUtil soqlCI = new SOQLUtil('Customer_Invoice__c',true);//KNDY-10473
	        soqlCI.addFields('New_Customer_Credit_Memo');
	        soqlCI.addFields(new Set<String>{'Invoice_Type__c', 'Credit_Applied__c'});
	        soqlCI.setWhereClause(whereClause);            		 

	        
	                		 
			for(Customer_Invoice__c creditMemo : (List<Customer_Invoice__c>) Database.query(soqlCI.getQuery())){    
				System.debug(logginglevel.error,'result--Customer_Invoice__c->'+creditMemo);   
			    if(String.isBlank(String.valueOf(creditMemo.Credit_Applied__c))){
			        creditMemo.Credit_Applied__c = 0;
			    }
			    
			    if(String.isBlank(String.valueOf(creditMemo.Amount_To_Apply__c))){
			        creditMemo.Amount_To_Apply__c = 0;
			    }
			    
			    creditMemo.Write_Off_Amount__c = 0;
			   
			    CreditMemoWrapper cmWrapper = new CreditMemoWrapper();
			    cmWrapper.creditMemo = creditMemo;
			    
			    if(creditMemoPaymentsMap.containsKey(creditMemo.Id)){
			        cmWrapper.paymentLine = creditMemoPaymentsMap.get(creditMemo.Id);
			        cmWrapper.creditMemo.Amount_To_Apply__c = cmWrapper.paymentLine.Amount__c;
			        cmwrapper.creditMemo.Memo__c = cmWrapper.paymentLine.Memo__c;
			    }
			    
			    if(creditMemoWriteOffMap.containsKey(creditMemo.Id)){
                    cmWrapper.writeOffLine = creditMemoWriteOffMap.get(creditMemo.Id);
                    if(appliedWriteOffs.contains(creditMemo.Id)){
                    cmWrapper.creditMemo.Write_Off_Amount__c = cmWrapper.writeoffLine.Amount__c;
                    cmWrapper.creditMemo.Resolution_Code__c = cmWrapper.writeoffLine.Reason_Code__c; 
                    cmWrapper.creditMemo.Memo__c = cmWrapper.writeoffLine.Memo__c; 
                    }else{
                        cmWrapper.creditMemo.Write_Off_Amount__c = 0.00;
                    }   
			    }
				creditMemosList.add(cmWrapper);
			}
				
			JsonResult result = new JsonResult();
			result.records = creditMemosList;
	        result.total = creditMemosList.size();
	        return result;   
		}
	
	}
	
	@RemoteAction
	public static JsonResult getDeductions(String customerReceiptId){
		List<DeductionWrapper> deductionsList = new List<DeductionWrapper>();
		SchemaUtil shUtil = new SchemaUtil();
		
		String whereClause = ' Type__c = :TYPE_GENERAL_DEDUCTION' +
							 ' AND Customer_Receipt__c = :customerReceiptId';
        					 
		SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c',true);//KNDY-10473
        soql.addFields('Deduction_fields');
        soql.setWhereClause(whereClause); 					 
		//String queryString = shUtil.generateQueryFromFieldSet('Customer_Receipt_Line__c', new Set<String>{'Deduction_fields'}, null, whereClause);
							 
		//for(Customer_Receipt_Line__c deduction : (List<Customer_Receipt_Line__c>) Database.query(queryString)){
        for(Customer_Receipt_Line__c deduction : (List<Customer_Receipt_Line__c>) Database.query(soql.getQuery())){    
		    DeductionWrapper dedWrapper = new DeductionWrapper();
		    dedWrapper.deduction = deduction;
			deductionsList.add(dedWrapper);
		}
			
		JsonResult result = new JsonResult();
		result.records = deductionsList;
        result.total = deductionsList.size();
        return result;   
	}
	
	@RemoteAction
	public static JsonResult getCustomerInvoices(String companyId, String customerId, String currencyId, String customerReceiptId, Date dateReceived){
		List<CustomerInvoiceWrapper> customerInvoiceWrappers = new List<CustomerInvoiceWrapper>();  
		SchemaUtil shUtil = new SchemaUtil();
		Decimal invoiceDeductionTotal = 0.0;
		
		if(customerId.trim() == '' || customerId == null) {
			JsonResult result = new JsonResult();
			result.records = new List<CreditMemoWrapper>();
	        return result;
		}else {
			// Get existing payment lines for customer invoices on the customer receipt.
			Set<String> crlTypes = new Set<String>{PaymentService.TYPE_GEN_DED, PaymentService.TYPE_CREDIT_MEMO, PaymentService.TYPE_PREPAYMENT_CREDIT, PaymentService.TYPE_OVERPAYMENT_CREDIT, PaymentService.TYPE_OVERPAYMENT, PaymentService.TYPE_PREPAYMENT};//, PaymentService.TYPE_WRITEOFF
			Map<Id, List<Customer_Receipt_Line__c>> crlMap = new Map<Id, List<Customer_Receipt_Line__c>>();
			Set<Id> customerInvoiceIds = new Set<Id>();
			SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Customer_Invoice__c','Customer_Invoice__r.Total_Amount__c','Amount__c','Type__c','Notes__c','Reason_Code__c','Reason_Code__r.Name','Reference__c','Memo__c'
			});
			soql.setWhereClause('Customer_Receipt__c = :customerReceiptId AND Type__c NOT IN :crlTypes');
			
			System.debug(logginglevel.error,soql.getQuery());
			
			for(Customer_Receipt_Line__c crl : Database.query(soql.getQuery())){
			    system.debug(logginglevel.error,'inside CRManage, crl map contains key: '+crlMap.containsKey(crl.Customer_Invoice__c) +'=='+crl.Customer_Invoice__c + '=='+crl.Type__c + '=' + crl.Customer_Invoice__r.Total_Amount__c);
			    if (string.isNotBlank(crl.Customer_Invoice__c) && crl.Customer_Invoice__r.Total_Amount__c > 0){ //KNDY-13995
			    	if(crlMap.containsKey(crl.Customer_Invoice__c) == false){                                         
			        	crlMap.put(crl.Customer_Invoice__c, new List<Customer_Receipt_Line__c>());
			    	}
					if (crlMap.get(crl.Customer_Invoice__c) != null){ 
			    		crlMap.get(crl.Customer_Invoice__c).add(crl);
			    		customerInvoiceIds.add(crl.Customer_Invoice__c);
			    	}
			    }
			    
			}
			System.debug(logginglevel.error,'customerInvoiceIds--->'+customerInvoiceIds);
			
			
			// Get all customer invoices that needs to be paid (balance > 0)
			String masterWhereClause = isRenderGrid(customerReceiptId) == true ? ' ( Sold_To_Customer__c = :customerId' +
	        						    '   OR Bill_To_Customer__c = :customerId' +
	        							'   OR Customer__c =  :customerId' +
	        							' )' +
	        							' AND (Balance__c > 0 OR Id IN :customerInvoiceIds)' +
	        							' AND Status__c not in (\'Closed\',\'Cancelled\',\'Void\') '+ //,\'Void\' -OTC-816
	        							'AND Finalized__c = true'+ //OTC-588
                						' AND Currency__c = :currencyId'+
                						' AND Company__c = :companyId'+
	        							' ORDER BY Name' : ' Id IN :customerInvoiceIds ORDER BY Name';
			 soql = new SOQLUtil('Customer_Invoice__c',true);//KNDY-10473
	        soql.addFields('Customer_Receipt_RO');
	        soql.addFields(new Set<String>{'Amount_Paid__c', 
	        	 'Allowances__c', 'Subtotal__c','Early_Payment_Discount_Date__c',
	        	 'Payment_Term__c', 'Payment_Term__r.Always_Take_Discount__c', 'Payment_Term__r.Discount_Percent__c'});
	        soql.setWhereClause(masterWhereClause);   
			for(Customer_Invoice__c ci : (List<Customer_Invoice__c>) Database.query(soql.getQuery())){    
	        	CustomerInvoiceWrapper ciWrapper = new CustomerInvoiceWrapper();
	        	ciWrapper.customerInvoice = ci;
	            
	            // Set the amounts to zero in case there are no existing customer receipt lines found.
	            // The amounts reflect the values in the current receipt only, not the amounts applied from a previous receipt.
	            ciWrapper.customerInvoice.Amount_Applied__c = 0;
	            ciWrapper.customerInvoice.Write_Off_Amount__c = 0;
	            ciWrapper.ciUnearnedDiscountAmount = 0;//KNDY-17349
	            ciWrapper.ciEarnedDiscountAmount = getEarnedDiscountAmount(ci, dateReceived); //KNDY-17349

	            system.debug(logginglevel.error,'inside getCIs - ciWrapper '+ciWrapper);
	        	if(String.isBlank(String.valueOf(ciWrapper.customerInvoice.Amount_Paid__c))){
	                ciWrapper.customerInvoice.Amount_Paid__c = 0;
	            }
	            system.debug(logginglevel.error,'inside CRManage, crl map: '+crlMap);
	            List<Customer_Receipt_Line__c> crlList = crlMap.get(ci.Id);
	            
	        	if(crlList != null && crlList.size() > 0){
	        		ciWrapper.selected = true;
	        	    
	        	    for(Customer_Receipt_Line__c crl : crlList){
	        	    	ciWrapper.customerInvoice.Memo__c = crl.Memo__c;
	        	    	system.debug('inside CRManage, crl type: '+ crl.Type__c);
	        		    if(crl.Type__c == PaymentService.TYPE_PAYMENT){
	        			    ciWrapper.paymentLine = crl;
	        			    ciWrapper.customerInvoice.Amount_Applied__c = crl.Amount__c;
	        			    //ciWrapper.customerInvoice.Amount_Paid__c = KSE.subtractDecimals(ciWrapper.customerInvoice.Amount_Paid__c, crl.Amount__c);
	        		    }
	        		    
	        		    if(crl.Type__c == PaymentService.TYPE_WRITEOFF || crl.Type__c == PaymentService.TYPE_WRITEOFF_CREDIT){
	        			    ciWrapper.writeOffLine = crl;
	        			    ciWrapper.customerInvoice.Write_Off_Amount__c = crl.Amount__c;
                            // Add the Resolution code of the CI to capture the Write off reason code
                            ciWrapper.customerInvoice.Resolution_Code__c = crl.Reason_Code__c;
	        		    }
	        		    
	        		    if(crl.Type__c == PaymentService.TYPE_EARNED_DISCOUNT){
	        		    	ciWrapper.earnedDiscountLine = crl;
	        		    	ciWrapper.ciEarnedDiscountAmount = crl.Amount__c; //KNDY-17349
	        			}
	        		    
	        		    if(crl.Type__c == PaymentService.TYPE_UNEARNED_DISCOUNT){
	        			    ciWrapper.unearnedDiscountLine = crl;
	        			    ciWrapper.ciUnearnedDiscountAmount = crl.Amount__c; //KNDY-17349
	        		    }
	        		    
	        			if(crl.Type__c == PaymentService.TYPE_INVOICE_DEDUCTION){
	        			   // crl.Amount__c = crl.Amount__c;
	        			    //crl.Reason_Code__c = crl.Reason_Code__c;
	        			   invoiceDeductionTotal += crl.Amount__c;
	        			    system.debug('inside.get CRs for GetCIS: '+crl);
	        			    ciWrapper.invoiceDeductions.add(crl);
	        			}
	        			
	        			
	        	    }
	        	    
	        	}
	        	else
	        	{
	        		ciWrapper.selected = false;
	        		//KNDY-11277 //ciWrapper.customerInvoice.Amount_Applied__c = ciWrapper.customerInvoice.Balance__c - ciWrapper.ciEarnedDiscountAmount;
	        	}
	        	system.debug(logginglevel.error,'inside getCIs - ciWrapper after '+ciWrapper);
	        	customerInvoiceWrappers.add(ciWrapper);
		    }
			
			JsonResult result = new JsonResult();
			result.records = customerInvoiceWrappers;
	        result.total = customerInvoiceWrappers.size();
	        return result; 
		}  

	}
	
	@RemoteAction
public static JsonResult getClaims(String companyId, String customerId, String currencyId, String customerReceiptId){

		if(customerId.trim() == '' || customerId == null) { //KNDY-10759
			JsonResult result = new JsonResult();
			result.records = new List<CreditMemoWrapper>();
	        return result;
		}
		else {

		system.debug('customerId '+customerId);
		system.debug('customerReceiptId '+customerReceiptId);
		List<ClaimWrapper> claimsList = new List<ClaimWrapper>();
		SchemaUtil shUtil = new SchemaUtil();
		Set<Id> generalDeductionLines = new Set<Id>();
		//Map<Id, Customer_Receipt_Line__c> ciToCrlMap = new Map<Id, Customer_Receipt_Line__c>();
		Set<Id> paidClaimIds = new Set<Id>();
		Set<String> paymentServiceTypes = new Set<String>{ PaymentService.TYPE_GEN_DED, PaymentService.TYPE_INVOICE_DEDUCTION, PaymentService.TYPE_CLAIM_PAYMENT };
		map<ID,Customer_Receipt_Line__c> claimsToCRL = new map<ID,Customer_Receipt_Line__c>(); //otc-182
		// Get Invoice deduction customer receipt lines
		String detailWhereClause =  ' Invoice_Type__c = \''+ClaimService.SETTLE_CHARGEBACK+'\' ' ;
                                    
		String detailQueryString = shUtil.generateQueryFromFieldSet('Customer_Invoice__c', new Set<String>{'Customer_Receipt_RO'}, null, detailWhereClause);
		detailQueryString = detailQueryString.replace('Customer_Invoice__c', 'Customer_Invoices__r');
		SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Customer_Invoice__c','Customer_Invoice__r.Claim__c','Amount__c','Type__c','Claim__c'
		});
		soql.setWhereClause(' Customer_Receipt__c = :customerReceiptId AND Type__c in :paymentServiceTypes ');
		
		for(Customer_Receipt_Line__c crl :Database.query(soql.getQuery()) 
        ){  
            if(crl.Type__c == PaymentService.TYPE_GEN_DED || crl.Type__c == PaymentService.TYPE_INVOICE_DEDUCTION){
    		    generalDeductionLines.add(crl.Id);
            }
            else
            if(crl.Type__c == PaymentService.TYPE_CLAIM_PAYMENT){
                //ciToCrlMap.put(crl.Customer_Invoice__c, crl);
                paidClaimIds.add(crl.Claim__c);
                claimsToCRL.put(crl.Claim__c,crl);
            }
		}
		
		String whereClause = isRenderGrid(customerReceiptId) == true  ? ' ( Sold_To_Customer__c = :customerId' +
							 '   OR Bill_To_Customer__c = :customerId' +
							 '   OR Parent_Customer__c =  :customerId' +
							 ' )' +
            				 ' AND Currency__c = :currencyId' +
							 ' AND Customer_Receipt_Line__c NOT IN :generalDeductionLines AND Amount__c > 0' +
							 ' AND Company__c = :companyId'+
							 ' AND Source__c != \'' + ClaimService.SOURCE_MANUAL + '\'' + //KNDY-15037
							 ' AND ((Status__c != \'' + ClaimService.STATUS_CLOSED +'\' AND Status__c != \'' + ClaimService.STATUS_CANCELLED +'\') OR Id IN :paidClaimIds)' : ' Id IN :paidClaimIds'; //ar-125
		soql = new SOQLUtil('Claim__c',true);//KNDY-10473
        soql.addFields('Customer_Receipt_RO');
        soql.addFields(detailQueryString);
        soql.addFields(new Set<String>{'Customer_Receipt__c'});
        soql.setWhereClause(whereClause);
							 
		for(Claim__c claim : (List<Claim__c>) Database.query(soql.getQuery())){    
		    ClaimWrapper wrappedClaim = new ClaimWrapper();
			wrappedClaim.claim = claim;
			wrappedClaim.amountApplied = claim.Amount__c;
			if(claimsToCRL.containsKey(claim.ID))
			{
				wrappedClaim.selected = true;
				wrappedClaim.claimLine = claimsToCRL.get(claim.id);
				wrappedClaim.amountApplied = claimsToCRL.get(claim.id).Amount__c;
			}
			
			claimsList.add(wrappedClaim);
		}
			
		JsonResult result = new JsonResult();
		result.records = claimsList;
        result.total = claimsList.size();
        return result;   
	}
	
	}
	
	@RemoteAction
	public static JsonResult getAdditionalPayments(String customerReceiptId){
		List<AdditionalPaymentWrapper> additionalPaymentsList = new List<AdditionalPaymentWrapper>();
		SchemaUtil shUtil = new SchemaUtil();
		
		String whereClause = ' Type__c IN :additionalPaymentTypes' +
							 ' AND Customer_Receipt__c = :customerReceiptId';
        					 
		SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c',true);//KNDY-10473
        soql.addFields('Overpayment');        
        soql.addFields(new Set<String>{'Customer_Invoice__r.Bill_To_Customer__r.Name'}); //KNDY-13995
        soql.setWhereClause(whereClause);					 
							 
		//for(Customer_Receipt_Line__c crl : (List<Customer_Receipt_Line__c>) Database.query(queryString)){
        for(Customer_Receipt_Line__c crl : (List<Customer_Receipt_Line__c>) Database.query(soql.getQuery())){    
			AdditionalPaymentWrapper apWrapper = new AdditionalPaymentWrapper();
			apWrapper.creditMemo.Bill_To_Customer__c = crl.Customer_Invoice__r.Bill_To_Customer__c; //KNDY-13995
			apWrapper.creditMemo.Bill_To_Customer__r = new Customer__c();
			apWrapper.creditMemo.Bill_To_Customer__r.Name = crl.Customer_Invoice__r.Bill_To_Customer__r.Name; //KNDY-13995
			apWrapper.additionalPayment = crl;
			additionalPaymentsList.add(apWrapper);
		}
			
		JsonResult result = new JsonResult();
		result.records = additionalPaymentsList;
        result.total = additionalPaymentsList.size();
        return result;   
	}
	
	@RemoteAction
	public static JSONResult getCompanyDefaultCurrency(String companyId) {
		JsonResult result = new JsonResult();
		try {
			Id currencyId = CompanyService.defaultTransactionCurrency(companyId);
			result.success = true;
			SOQLUtil soql = new SOQLUtil('Currency__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','ISO_Code__c','name'
			});
			soql.setWhereClause('Id = :currencyId');
			
			result.records = Database.query(soql.getQuery());
			return result;
		}catch(exception ex) {
			system.debug(LoggingLevel.Error, 'ex: '+ex.getMessage()+' stacktrace: '+ex.getStacktraceString());
			result.success = false;
			result.addMessage(ex.getmessage(), ApexPages.Severity.ERROR);
			return result;
		}
	}
	//KNDY-18029 fetch bank accounts' other detials
    @RemoteAction
    public static JsonResult getBankAccountDetails(id baId){  
       JsonResult result = new JsonResult();
       
       Bank_Account__c baccount = PaymentService.getBankAccount(baId);
       system.debug('bank account=='+baccount);
	
       result.records = (new List<Bank_Account__c>{baccount});
       result.total = 1;
       return result; 
    }
    
	//KNDY-14482
	@RemoteAction
	public static JSONResult getCompanyDefaultBankAndCurrency(String companyId) {
		JsonResult result = new JsonResult();
		try {
			List<Company__c> companyList = new List<Company__c>();
			//KNDY-18030 - Created generic method to get all bank details from company in serivce class
			Company__c  companyObj = CompanyService.getCompanyBankAccount(companyId);
			result.success = true;
			companyList.add(companyObj);
			system.debug('companyList=='+companyList);
			result.records = companyList;
			return result;
		}catch(exception ex) {
			system.debug(LoggingLevel.Error, 'ex: '+ex.getMessage()+' stacktrace: '+ex.getStacktraceString());
			result.success = false;
			result.addMessage(ex.getmessage(), ApexPages.Severity.ERROR);
			return result;
		}
	}
	
	@RemoteAction
	public static JsonResult getCustomerReceipt(String customerReceiptId, String calledFrom){
		
		List<Customer_Receipt__c> customerReceipts = new List<Customer_Receipt__c>();
		SchemaUtil shUtil = new SchemaUtil();
		JsonResult result = new JsonResult();
		
		// Return an emoty record for new customer reciept
		if(customerReceiptId == null || customerReceiptId == ''){
			Customer_Receipt__c customerReceipt = new Customer_Receipt__c();
			ID companyID = CompanyService.getDefaultCompanyId();
          
            if(!(String.isBlank(companyID))){
			customerReceipt.Company__c = companyID;
			SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Name'
			});
			soql.setWhereClause('Id = :companyId');
			soql.setLimit(1);
			
			customerReceipt.Company__r = Database.query(soql.getQuery());
				//KNDY14482
				Id currencyId;
				//KNDY-18030 - Created generic method to get all bank details from company in serivce class
				Company__c  companyObj = CompanyService.getCompanyBankAccount(companyId);
				customerReceipt.Bank_Account_2__c = companyObj != null ? companyObj.deposit_bank_account__c : null;
				if (customerReceipt.Bank_Account_2__c != null) {
					
					
					system.debug('companyObj=='+companyObj);
					if (companyObj != null){
						customerReceipt.Bank_Account_2__r = companyObj.deposit_bank_account__r;
						customerReceipt.Currency__c =companyObj.deposit_bank_account__r.Currency__c;
						currencyId = customerReceipt.Currency__c;
						customerReceipt.Currency__r = companyObj.deposit_bank_account__r.Currency__r;
						//KNDY-18029 fetch default payment method set for deposit bank account
						customerReceipt.Payment_Method_G__c = companyObj.deposit_bank_account__r.Primary_Deposit_Payment_Method__c;
						system.debug('customerReceipt=='+customerReceipt);
					}
				}else{
					customerReceipt.Currency__c =CompanyService.defaultTransactionCurrencyId(companyID);
					currencyId = customerReceipt.Currency__c;
					customerReceipt.Currency__r = companyObj.Default_Transaction_Currency__r;
				}

            }
		    customerReceipt.Date_Received__c = system.now();
			customerReceipts.add(customerReceipt);
		}else{
			
			String whereClause = ' Id = :customerReceiptId';
			set<String> fieldSets = new set<String>();
              SOQLUtil soql = new SOQLUtil('Customer_Receipt__c',true);
			if(calledFrom.equalsIgnoreCase('HeaderDetailList'))
            {
               // fieldSets = new set<String>{'Cash_App_Header','Cash_App_Additional'};
               soql.addFields('Cash_App_Header');
                soql.addFields('Cash_App_Additional');
                    }
			else if(calledFrom.equalsIgnoreCase('PaymentDetailList'))
            {	//fieldSets = new set<String>{'Apply_Payment'};
            soql.addFields('Apply_Payment');   
            }
            soql.addFields(new Set<String>{'Name','Finalized__c' ,'Void__c','Status__c','Total_Number_Of_Lines__c'});
            soql.setWhereClause(whereClause);	        
			//String queryString = shUtil.generateQueryFromFieldSet('Customer_Receipt__c', fieldSets, new Set<String>{'Finalized__c' ,'Void__c','Status__c','Total_Number_Of_Lines__c'}, whereClause);
			//customerReceipts = (List<Customer_Receipt__c>) Database.query(queryString);	
            customerReceipts = (List<Customer_Receipt__c>) Database.query(soql.getQuery());	
			
			if(customerReceipts.size() > 0){
			    if(customerReceipts[0].Finalized__c){
			    	if(customerReceipts[0].Void__c)
			    	{
			    		result.addMessage('Payments cannot be managed on a void customer receipt.', ApexPages.Severity.WARNING);
			    	}
			    }
			    else if(customerReceipts[0].Status__c == 'Cancelled')
			    {
			    	result.addMessage('Payments cannot be managed on a cancelled customer receipt.', ApexPages.Severity.WARNING);
			    	
                    
			    }else if(customerReceipts[0].Status__c == CustomerReceiptService.STATUS_HELD_FOR_REVIEW) {
			    	result.addMessage('Payments cannot be managed on a customer receipt thats held for review.', ApexPages.Severity.WARNING);
			    }
			  
			}
		}
		
		result.success = true;
		result.records = customerReceipts;
        result.total = customerReceipts.size();
        
        return result;	
	}
	
	
	
	@RemoteAction
	public static JsonResult save(Customer_Receipt__c customerReceipt, List<String> headerDateFields,  Map<String, List<CreditMemoWrapper>> creditMemosChangeLists,
	 Map<String, List<DeductionWrapper>> deductionChangeLists, Map<String, List<CustomerInvoiceWrapper>> customerInvoicesChangeLists, Map<String, List<ClaimWrapper>> claimsChangeList, Map<String, List<AdditionalPaymentWrapper>> additionalPaymentsChangeList){
		system.debug(LoggingLevel.INFO, 'customerReceipt: ' + customerReceipt);
		system.debug(LoggingLevel.INFO, 'headerDateFields: ' + headerDateFields);
		system.debug(LoggingLevel.INFO, 'creditMemosChangeLists: ' + creditMemosChangeLists);
		system.debug(LoggingLevel.INFO, 'deductionChangeLists: ' + deductionChangeLists);
		system.debug(LoggingLevel.INFO, 'customerInvoicesChangeLists: ' + customerInvoicesChangeLists);
		system.debug(LoggingLevel.INFO, 'claimsChangeList: ' + claimsChangeList);
		system.debug(LoggingLevel.INFO, 'additionalPaymentsChangeList: ' + additionalPaymentsChangeList);
		
		JsonResult result = new JsonResult();
        Savepoint sp = Database.setSavepoint();
        list<Customer_Receipt__c> records = new list<Customer_Receipt__c>();
        
        try{ 
        	ExceptionServiceAPI.isCashAppRunning = true; // OTC-725  
        	
        	boolean anyChanges = false;
        	
        	
        	//saveCustomerReceipt
        	 Id crId = saveCustomerReceipt(customerReceipt, result, headerDateFields);
        	//saveBankFileLines(customerReceipt, bankFileLinesChangeList, result);
	        anyChanges = saveCreditMemos(customerReceipt, creditMemosChangeLists, result, crId) ||anyChanges;
	        anyChanges = saveDeductions(customerReceipt, deductionChangeLists, result, crId) ||anyChanges;
	        anyChanges = saveCustomerInvoices(customerReceipt, customerInvoicesChangeLists, result, crId) ||anyChanges;
	        anyChanges = saveClaims(customerReceipt, claimsChangeList, result, crId) ||anyChanges;
	        anyChanges = saveAdditionalPayments(customerReceipt, additionalPaymentsChangeList, result, crId) ||anyChanges;
	        system.debug('anyChanges '+anyChanges);
	        //KNDY-17347
	        if(anyChanges){ 
	        	if(customerReceipt.Id != null){
	        		list<Customer_Receipt_Line__c> lstCRL = new list<Customer_Receipt_Line__c>();
	        		SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); 
					soql.addFields(new set<string>{'Id'});
					soql.setWhereClause('Customer_Receipt__c ='+'\''+customerReceipt.Id+'\''); 
	        		lstCRL = Database.query(soql.getQuery());
	        		if(!lstCRL.isEmpty()){
	        			finalizeCustomerReceipt(customerReceipt, result);
	        		}
	        	}
	        }
            system.debug('ExceptionService.hasErrors='+ExceptionService.hasErrors);
            if(ExceptionService.hasErrors) {
            	result.success = true;
            	records.add(customerReceipt);
	            result.records = records;
            	for(map<String,String> msg : ExceptionService.messages) {
            		if(msg.get('severity') == MessageUtil.Severity.ERROR.name() || msg.get('severity') == MessageUtil.Severity.FATAL.name()) {
            			String id = String.escapeSingleQuotes(msg.get('recordName'));
    					if((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id))
    						continue;
            			result.addMessage(msg.get('message'), ApexPages.Severity.WARNING); 
				}
				
				}
            }
            
	        else if (result.success) {
	            records.add(customerReceipt);
	            result.records = records;
	            result.addMessage(Label.Changes_saved, ApexPages.Severity.CONFIRM);
	            system.debug('result='+result);
	        }
        }catch(DMLException ex) {
			Database.rollback(sp);
            result.success = false;
            for (Integer idx = 0; idx < ex.getNumDml() ; idx++) {
                
                    string errorMessage = ex.getDmlMessage(idx);
                    Integer location;    
                    if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
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
                    
                result.addMessage( errorMessage, ApexPages.severity.ERROR);
        	}
            //System.debug(logginglevel.info,result);
		}
        catch ( DML.InsuffientAccessException e ) { 
 			Database.rollback(sp);
            result.success = false;
 			result.addMessage(Label.Insufficient_access_contact_administrator_for_permissions, ApexPages.Severity.ERROR); 
 		}catch (Exception e) { //AR-15 JSONResult addMessage handles DML Exception
        	Database.rollback(sp);
        	string errorMessage = e.getMessage();
	        integer location;    
	        if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
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
            result.success = false;
            
            result.addMessage(e, ApexPages.Severity.ERROR); //AR-15
        }

        return result;
	}
    
    public static Id saveCustomerReceipt(Customer_Receipt__c customerReceipt, JsonResult result, List<String> headerDateFields){
        
        if(customerReceipt != null){
            if(customerReceipt.Amount_Unapplied__c < 0){
                throw new CustomerReceiptManageExtException(Label.Cannot_apply_more_than_the_amount_received_from_this_receipt);
            }
            KendoUtils.UpdateDateFields(customerReceipt, headerDateFields);
        
           // customerReceipt.Finalized__c =true;
            //customerReceipt.Finalized_Date__c = system.now();
            //customerReceipt.Posting_Date__c = system.now();
           	system.debug('customerReceipt '+customerReceipt);
            DML.checkUpsertAsUser(customerReceipt); upsert customerReceipt;
        }
        result.success = true;
        return customerReceipt.Id;
    }
    
    public static void finalizeCustomerReceipt(Customer_Receipt__c customerReceipt, JsonResult result) {
    		system.debug('inside finalizeCR');
    		customerReceipt.Finalized__c =true;
	        //customerReceipt.Finalized_Date__c = system.now();
	        //customerReceipt.Posting_Date__c = system.now();
	        DML.updateAsUser(customerReceipt);
    	
    }
    
    public static boolean saveCreditMemos(Customer_Receipt__c customerReceipt, Map<String, List<CreditMemoWrapper>> changeLists, JsonResult result, ID crId){
    	boolean anyChanges = false;
		List<Customer_Receipt_Line__c> upsertList = new List<Customer_Receipt_Line__c>();
		List<Customer_Receipt_Line__c> deleteList = new List<Customer_Receipt_Line__c>();
		
		system.debug(logginglevel.error,changeLists.get('updatedRows') != null);
		if(changeLists.get('updatedRows') != null)
		{
			for(CreditMemoWrapper cm : changeLists.get('updatedRows')){
			   System.debug(logginglevel.error,'CreditMemoWrapper-->'+cm);
		        
			    if(cm.creditMemo.Amount_To_Apply__c > 0){
			       
			        Customer_Receipt_Line__c crl = cm.paymentLine;
			        Decimal previousAmt = KSE.addQuantityToField(crl.Amount__c, 0);
	                crl.Amount__c = cm.creditMemo.Amount_To_Apply__c;
	                crl.Customer_Receipt__c = crId;
	                crl.Customer_Invoice__c = cm.creditMemo.Id;//KNDY-13995
	                crl.Memo__c = cm.creditMemo.Memo__c;
	                if(cm.creditMemo.invoice_type__c == CustomerInvoiceService.CM_PREPAYMENT){
	                    crl.Type__c = PaymentService.TYPE_PREPAYMENT_CREDIT;
	                }else if(cm.creditMemo.invoice_type__c == CustomerInvoiceService.CM_OVERPAYMENT){
	                    crl.Type__c = PaymentService.TYPE_OVERPAYMENT_CREDIT;
	                }else{
	                    crl.Type__c = PaymentService.TYPE_CREDIT_MEMO;
	                }
	                crl.Memo__c = cm.creditMemo.Memo__c;
	                upsertList.add(crl);
	            }else{
	                Customer_Receipt_Line__c crl = cm.paymentLine;  
	                if(crl.Id != null){
	                    deleteList.add(crl);    
	                }
	            }
	            //KNDY-17347    
		        if(cm.creditMemo.Amount_To_Apply__c < 0 && cm.creditMemo.Write_Off_Amount__c >= 0){
		                throw new CustomerReceiptManageExtException(Label.Amount_To_Apply_Cannot_be_Zero);
		        } 
		        
		        //KNDY-17347
	            if(cm.creditMemo.Amount_To_Apply__c >= 0 && cm.creditMemo.Write_Off_Amount__c > 0 ){
                    
                    Customer_Receipt_Line__c crl = cm.writeOffLine;
                    
                    crl.Amount__c = cm.creditMemo.Write_Off_Amount__c;
	                crl.Customer_Receipt__c = crId;
	                crl.Customer_Invoice__c = cm.creditMemo.Id;//KNDY-13995
	                crl.Type__c = PaymentService.TYPE_WRITEOFF_CREDIT;
	                crl.Reason_Code__c =  cm.creditMemo.Resolution_Code__c;
	                crl.Memo__c = cm.creditMemo.Memo__c;
                    
                    upsertList.add(crl);
	            }else{
                    Customer_Receipt_Line__c crl = cm.writeOffLine;
	                if(crl.Id != null){
	                    deleteList.add(crl);    
	                }
	            }
			}
		}
		
		
		if(! upsertList.isEmpty()){
		    System.debug(logginglevel.error,'upsertList--->'+upsertList);
			DML.checkUpsertAsUser(upsertList); upsert upsertList;
			anyChanges = true;
		}
		
		if(! deleteList.isEmpty()){
			DML.deleteAsUser(deleteList);
			anyChanges = true;
		}
		
		result.success = true;	
		return anyChanges;
    }
    
    public static boolean saveDeductions(Customer_Receipt__c customerReceipt, Map<String, List<DeductionWrapper>> changeLists, JsonResult result, Id crId){
    	
    	boolean anyChanges = false;
    	
		List<Customer_Receipt_Line__c> upsertList = new List<Customer_Receipt_Line__c>();
		List<Customer_Receipt_Line__c> deleteList = new List<Customer_Receipt_Line__c>();
		
	
		if(changeLists.get('newRows') != null)
		{
			for(DeductionWrapper ded : changeLists.get('newRows')){
				ded.deduction.Customer_Receipt__c = crId;
				ded.deduction.Type__c = PaymentService.TYPE_GEN_DED;
                //if(ded.deduction.Reason_Code__c  == null)
					//throw new CustomerReceiptManageExtException('Missing_Reason_Code_On_Deductions');
				upsertList.add(ded.deduction);
			}
		}
		
		if(changeLists.get('updatedRows') != null)
		{
			for(DeductionWrapper ded : changeLists.get('updatedRows')){
               //if(ded.deduction.Reason_Code__c == null)
					//throw new CustomerReceiptManageExtException('Missing_Reason_Code_On_Deductions');
				upsertList.add(ded.deduction);
			}
		}
		
		system.debug('deductions '+upsertList);
		if(! upsertList.isEmpty()){
			DML.checkUpsertAsUser(upsertList); upsert upsertList; // Will generate claims in the background.
			anyChanges = true;
		}
		
		if(changeLists.get('deletedRows') != null)
		{
			for(DeductionWrapper ded : changeLists.get('deletedRows')){
				deleteList.add(ded.deduction);
			}
		}
		
		
		if(! deleteList.isEmpty()){
			DML.deleteAsUser(deleteList);
			anyChanges = true;
		}
		
		result.success = true;
		system.debug('anyChanges on deductions '+anyChanges);
		return anyChanges;	
    }
    
    public static boolean saveCustomerInvoices(Customer_Receipt__c customerReceipt, Map<String, List<CustomerInvoiceWrapper>> changeLists, JsonResult result, Id crId) {
    	
    	boolean anyChanges = true;
    	
    	List<Customer_Receipt_Line__c> upsertList = new List<Customer_Receipt_Line__c>();
		List<Customer_Receipt_Line__c> deleteList = new List<Customer_Receipt_Line__c>();
		
    	List<Customer_Invoice__c> customerInvoiceList = new List<Customer_Invoice__c>();
    	system.debug('inside test: '+changeLists.get('updatedRows') );
    	if(changeLists.get('updatedRows') != null)
    	{	
    		List<Customer_Receipt_Line__c> invoiceDeductions = new List<Customer_Receipt_Line__c>();
    		Decimal totalInvDed = 0;
    		
    		
			for(CustomerInvoiceWrapper ciw : changeLists.get('updatedRows')) {
				
				for(Customer_Receipt_Line__c invDed : ciw.invoiceDeductions){ //OTC-501
						totalInvDed += invDed.Amount__c;
				}
				
		    	for(Customer_Receipt_Line__c invDed : ciw.invoiceDeductions){
		    		system.debug('total inv ded '+totalInvDed +' '+ciw.ciEarnedDiscountAmount);
		    		system.debug('test condition: '+(invDed.Amount__c > 0 && ciw.customerInvoice.Amount_Applied__c > 0) );
		    		system.debug('test condition: '+( (invDed.Amount__c > 0 && totalInvDed == ciw.customerInvoice.Balance__c-ciw.ciEarnedDiscountAmount)));
		    		system.debug('test condition: '+(ciw.selected == true));
		    		
		    	   //KNDY-17347
                   if(ciw.selected == true && (ciw.customerInvoice.Amount_Applied__c == 0
                      || ciw.customerInvoice.Amount_Applied__c == null) && invDed.Amount__c > 0 &&
                     (ciw.ciEarnedDiscountAmount != 0 || ciw.ciUnearnedDiscountAmount != 0)){
                        throw new CustomerReceiptManageExtException(Label.Discounts_should_not_zero_during_writeoff);
                   }
                   
	                if(ciw.selected == true && invDed.Amount__c > 0 && ciw.customerInvoice.Amount_Applied__c >= 0){ //OTC-501
	                	
	                    invDed.Customer_Receipt__c = crId;
				        invDed.Customer_Invoice__c = ciw.customerInvoice.Id;
				        invDed.Type__c = PaymentService.TYPE_INVOICE_DEDUCTION;
				        invDed.Amount__c = invDed.Amount__c;
				        invDed.Memo__c = ciw.customerInvoice.Memo__c;
				        if(String.isBlank(invDed.Id)) 
				        	invDed.Id = null;
	                    upsertList.add(invDed);
	                }else{
	                     if(String.isBlank(invDed.Id) == false){
	                        deleteList.add(invDed);    
	                    }
	                    
	                    else if(invDed.Amount__c <= 0)
	                    	throw new CustomerReceiptManageExtException(label.Cannot_save_negative_invoice_deductions +' '+ ciw.customerInvoice.name);
	                }
	            }
				
			}
				
				
				
    		
    		for(CustomerInvoiceWrapper ciw : changeLists.get('updatedRows')) { 
    			
    				system.debug('inside save CIs: ciw '+ciw.customerInvoice.Amount_Applied__c);
	                if(ciw.selected == true && ciw.customerInvoice.Amount_Applied__c > 0){
		                Customer_Receipt_Line__c crl = ciw.paymentLine;
		                crl.Amount__c = ciw.customerInvoice.Amount_Applied__c;
		                crl.Customer_Receipt__c = crId;
		                crl.Customer_Invoice__c = ciw.customerInvoice.Id;
		                crl.Type__c = PaymentService.TYPE_PAYMENT;
		                crl.Memo__c = ciw.customerInvoice.Memo__c;

		                //ciw.customerInvoice.Amount_Paid__c = KSE.addQuantityToField(ciw.customerInvoice.Amount_Paid__c, ciw.customerInvoice.Amount_Applied__c);
		                
		                upsertList.add(crl);
		            }else{
		                Customer_Receipt_Line__c crl = ciw.paymentLine;
		                if(crl.Id != null){
		                    //ciw.customerInvoice.Amount_Paid__c = KSE.addQuantityToField(ciw.customerInvoice.Amount_Paid__c, 0);
		                    deleteList.add(crl);    
		                }
		            }
		           
		           //KNDY-17347
		           if(ciw.selected == true && ciw.customerInvoice.Write_Off_Amount__c > 0 && ciw.customerInvoice.Amount_Applied__c < 0){
                        throw new CustomerReceiptManageExtException(Label.Amount_Applied_cannot_be_zero);
                   }
                   
                   //KNDY-17347
                   if(ciw.selected == true && ciw.customerInvoice.Write_Off_Amount__c > 0 && (ciw.customerInvoice.Amount_Applied__c == 0
                      || ciw.customerInvoice.Amount_Applied__c == null) && 
                       (ciw.ciEarnedDiscountAmount != 0 || ciw.ciUnearnedDiscountAmount != 0)){ //KNDY-17349
                        throw new CustomerReceiptManageExtException(Label.Discounts_should_not_zero_during_writeoff);
                   }
                    
		            if(ciw.selected == true && ciw.customerInvoice.Write_Off_Amount__c > 0 && ciw.customerInvoice.Amount_Applied__c >= 0){
		                Customer_Receipt_Line__c crl = ciw.writeOffLine;
		                crl.Amount__c = ciw.customerInvoice.Write_Off_Amount__c;
		                crl.Customer_Receipt__c = crId;
		                crl.Customer_Invoice__c = ciw.customerInvoice.Id;
		                crl.Type__c = PaymentService.TYPE_WRITEOFF;
		                crl.Reason_Code__c = ciw.customerInvoice.Resolution_Code__c;
		                crl.Memo__c = ciw.customerInvoice.Memo__c;
		                upsertList.add(crl);
		            }else{
		                Customer_Receipt_Line__c crl = ciw.writeOffLine;
		                if(crl.Id != null){
		                    deleteList.add(crl);    
		                }
		            }
		            //moving to trigger CR.finalize() before update KNDY-17347
		            if(ciw.selected == true && ciw.ciEarnedDiscountAmount > 0 && ciw.customerInvoice.Amount_Applied__c >= 0){ //OTC-501
		                Customer_Receipt_Line__c crl = ciw.earnedDiscountLine;
		                crl.Amount__c = ciw.ciEarnedDiscountAmount; //KNDY-17349
		                crl.Customer_Receipt__c = crId;
		                crl.Customer_Invoice__c = ciw.customerInvoice.Id;
		                crl.Type__c = PaymentService.TYPE_EARNED_DISCOUNT;
		                crl.Memo__c = ciw.customerInvoice.Memo__c;
		                system.debug('EARNED CRL '+crl);
		                upsertList.add(crl);
		            }else{
		                Customer_Receipt_Line__c crl = ciw.earnedDiscountLine;
		                if(crl.Id != null){
		                    deleteList.add(crl);    
		                }
		            }
		            
		            //KNDY-17347
		            if(ciw.selected == true && ciw.ciUnearnedDiscountAmount > 0 && ciw.customerInvoice.Amount_Applied__c >= 0){
		                Customer_Receipt_Line__c crl = ciw.unearnedDiscountLine;
		                crl.Amount__c = ciw.ciUnearnedDiscountAmount; //KNDY-17349
		                crl.Customer_Receipt__c = crId;
		                crl.Customer_Invoice__c = ciw.customerInvoice.Id;
		                crl.Type__c = PaymentService.TYPE_UNEARNED_DISCOUNT;
		                crl.Memo__c = ciw.customerInvoice.Memo__c;
		                upsertList.add(crl);
		            }else{
		                Customer_Receipt_Line__c crl = ciw.unearnedDiscountLine;
		                if(crl.Id != null){
		                    deleteList.add(crl);    
		                }
		            }
		        
		        	customerInvoiceList.add(ciw.customerInvoice);    
		            
		            // Collect all the invoice decutions
		            invoiceDeductions.addAll(ciw.invoiceDeductions);
    			
	        }
    		
        }
        
		if( ! upsertList.isEmpty() ){
			DML.checkUpsertAsUser(upsertList); upsert upsertList;
			anyChanges = true;
        }
        system.debug('deleteList '+deleteList);
		if( ! deleteList.isEmpty() ){
			DML.deleteAsUser(deleteList);
			anyChanges = true;
		}
		
		
        result.success = true;
        return anyChanges;
    }
    
    public static boolean saveClaims(Customer_Receipt__c customerReceipt, Map<String, List<ClaimWrapper>> changeLists, JsonResult result, Id crId){
    	boolean anyChanges = false;
    	List<Customer_Receipt_Line__c> upsertList = new List<Customer_Receipt_Line__c>();
		List<Customer_Receipt_Line__c> deleteList = new List<Customer_Receipt_Line__c>();
		Set<Id> claimIds = new Set<Id>();
		
		if(changeLists.get('updatedRows') != null)
		{
			for(ClaimWrapper cw : changeLists.get('updatedRows')){
	    		if( cw.selected == true && cw.claim.Id != null){
	    			claimIds.add(cw.claim.Id);   
		    	}
		    	//updateClaimList.add(cw.claim);
	    	}
	    	    	
	    		
	    	for(ClaimWrapper cw : changeLists.get('updatedRows')){
	    		system.debug('ClaimWrapper: '+cw.selected);
	    		system.debug('ClaimWrapper: '+cw);
	    	    if(cw.selected){
	        	    if(cw.claim.Id != null ){ //&& mChargeBacks.containsKey(cw.claim.Id)
	        	        
	        	        Customer_Receipt_Line__c crl = cw.claimLine;
	            	    crl.Amount__c = cw.amountApplied;
	            	    if(cw.amountApplied > cw.claim.Amount__c)
	            	    	throw new CustomerReceiptManageExtException('Amount Applied to '+cw.claim.Name+' is more than the amount on the claim');
	            	    crl.Type__c = PaymentService.TYPE_CLAIM_PAYMENT;
	            	    crl.Claim__c = cw.claim.ID;
	            	    crl.Customer_Receipt__c = crId;
	            	    
	            	    upsertList.add(crl);
	        	    }
	        	}
	        	else{
	        	    system.debug('ClaimWrapper: '+cw.selected);
	        	    system.debug('ClaimWrapper: '+cw.claimLine);
	        	    if(cw.claimLine.Id != null){
	        	        deleteList.add(cw.claimLine);
	        	    }
	        	}
	    	}
		}
    	
    	
    	//OTC-182 Saving list of CRL. will use this to update amount Paid on CI after CR is finalized. 
    	if(upsertList.size() > 0){
    	    DML.checkUpsertAsUser(upsertList); upsert upsertList;
    	    anyChanges = true;
    	   
    	}
    	system.debug(deleteList);
    	if(deleteList.size() > 0){
    	    DML.deleteAsUser(deleteList);
    	    anyChanges = true;
    	}
		
		result.success = true;
		return anyChanges;
    	
    }
    
    public static boolean saveAdditionalPayments(Customer_Receipt__c customerReceipt, Map<String, List<AdditionalPaymentWrapper>> changeLists, JsonResult result, Id crId){
    	
    	boolean anyChanges = false;
    	
		List<Customer_Receipt_Line__c> upsertList = new List<Customer_Receipt_Line__c>();
		List<Customer_Receipt_Line__c> deleteList = new List<Customer_Receipt_Line__c>();
		
		List<Customer_Invoice__c> creditMemos = new List<Customer_Invoice__c>();
		Set<Id> creditMemoIds = new Set<Id>();
		
		List<AdditionalPaymentWrapper> apWraperList = new List<AdditionalPaymentWrapper>();
		
		if(changeLists.get('newRows') != null)
		{
			for(AdditionalPaymentWrapper apw : changeLists.get('newRows')){
				system.debug('new additional payments: '+ apw);
				if(apw.additionalPayment.Type__c == null || apw.additionalPayment.Type__c.trim() == '')
					throw new CustomerReceiptManageExtException(Label.Missing_Type_On_Additional_Payments);
				
				apw.additionalPayment.Customer_Receipt__c = crId;
				upsertList.add(apw.additionalPayment);
			}
			
			apWraperList.addAll(changeLists.get('newRows'));
		}
		
		if(changeLists.get('updatedRows') != null)
		{
			for(AdditionalPaymentWrapper apw : changeLists.get('updatedRows')){
				system.debug('updated additional payments: '+ apw);
				if(apw.additionalPayment.Customer_Invoice__c != null){//KNDY-13995
				    creditMemoIds.add(apw.additionalPayment.Customer_Invoice__c); //KNDY-13995
				}
				if(apw.additionalPayment.Type__c == null || apw.additionalPayment.Type__c.trim() == '')
					throw new CustomerReceiptManageExtException(Label.Missing_Type_On_Additional_Payments);//OTC-679
				
				apw.additionalPayment.Customer_Receipt__c = crId;
				upsertList.add(apw.additionalPayment);
			}
			
			apWraperList.addAll(changeLists.get('updatedRows'));
		}
		
		
		
		if(! upsertList.isEmpty()){
			DML.checkUpsertAsUser(upsertList); upsert upsertList;
			anyChanges = true;
		}
		
		List<Customer_Invoice__c> deleteCreditMemos = new List<Customer_Invoice__c>();
		
		if(changeLists.get('deletedRows') != null)
		{
			for(AdditionalPaymentWrapper apw : changeLists.get('deletedRows')){
			    deleteList.add(apw.additionalPayment);
			}
			
		}
		if( deleteList != null && !deleteList.isEmpty()){
			DML.deleteAsUser(deleteList);
			anyChanges = true;
		}
		
		result.success = true;	
		return anyChanges;
    }
}