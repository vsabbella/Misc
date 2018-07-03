public with sharing class RefundCreditManageExt extends BaseController{

    public class RefundCreditManageExtException extends Exception{}

    private static SchemaUtil util = SchemaUtil.getInstance();
    public GridRelatedListController.GridRelatedListConfig InvoiceCreditsConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig RefundMethodConfig {get; set;}
    public GridRelatedListController.GridRelatedListConfig PaymentCreditsConfig {get; set;}
    public String NamespaceUU { get { return KSE.NamespaceUU; }}
    public String InvoiceCreditsFieldList = null;
    public String RefundMethodFieldList = null;
    public String PaymentCreditsFieldList = null;
    public Id defaultCustomer{ get; set;}
    public Id defaultCompany{ get; set;}
    public Id defaultCurrency{ get; set;}
    public Id customerInvoiceId{get;set;}
    public Id customerId{get;set;}
    public Id claimId{get;set;}//KNDY-15030

    public RefundCreditManageExt()
    {
        Id userId = UserInfo.getUserID();
		customerInvoiceId = String.isNotBlank(ApexPages.currentPage().getParameters().get('ciId')) ? ApexPages.currentPage().getParameters().get('ciId') : null;
		customerId = String.isNotBlank(ApexPages.currentPage().getParameters().get('cuId')) ? ApexPages.currentPage().getParameters().get('cuId') : null;
		claimId = String.isNotBlank(ApexPages.currentPage().getParameters().get('claimId')) ? ApexPages.currentPage().getParameters().get('claimId') : null;

		List<Customer_Invoice__c> custInvoiceLst;
		List<Customer__c> customerList;


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
	        if(defaultCompany != null)
	           defaultCurrency = CompanyService.defaultTransactionCurrencyId( defaultCompany );
		}

		if( String.isBlank(customerInvoiceId) == false ){
            SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Customer__c','Bill_To_Customer__c','Invoice_Type__c','Company__c','Currency__c','Customer_Receipt__c',
                'Customer_Receipt__r.Transaction_ID__c','Customer_Receipt__r.Payment_Method_3__c'
            });
            soql.setWhereClause('Id = :customerInvoiceId');
            soql.setLimit(1);

            custInvoiceLst = Database.query(soql.getQuery());

            if (custInvoiceLst.size() > 0  && custInvoiceLst[0].Id != null){
                if (custInvoiceLst[0].Bill_To_Customer__c != null)
                    defaultCustomer = custInvoiceLst[0].Bill_To_Customer__c;
                else
                    defaultCustomer = custInvoiceLst[0].Customer__c;
            }
            defaultCompany = custInvoiceLst[0].Company__c;
            defaultCurrency = custInvoiceLst[0].Currency__c;
        }

        if( String.isBlank(customerId) == false ){
            SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Record_Type_Name__c'
            });
            soql.setWhereClause('Id = :customerId');
            soql.setLimit(1);

            customerList = Database.query(soql.getQuery());

            if (customerList.size() > 0){
                if (customerList[0].Id != null)
                    defaultCustomer = customerList[0].Id;
                }
        }

        //Invoice Credits Grid config
        InvoiceCreditsConfig = new GridRelatedListController.GridRelatedListConfig();
        InvoiceCreditsConfig.uniqueId = 'InvoiceCreditsGrid';
        InvoiceCreditsConfig.title = 'Invoice Credits';
        InvoiceCreditsConfig.objectName = 'Customer_Invoice__c';
        InvoiceCreditsConfig.fieldset = 'Invoice_Credits';
        InvoiceCreditsConfig.sortField = 'Name';
        InvoiceCreditsConfig.buttons = 'search';
        InvoiceCreditsConfig.alwaysUseFullDateTimeFormat = false;

        //Refund Method Grid config
        RefundMethodConfig = new GridRelatedListController.GridRelatedListConfig();
        RefundMethodConfig.uniqueId = 'RefundMethodGrid';
        RefundMethodConfig.title = 'Refund Method';
        RefundMethodConfig.objectName = 'Customer_Receipt__c';
        RefundMethodConfig.fieldset = 'Refund_Method';
        RefundMethodConfig.sortField = 'Name';
        RefundMethodConfig.alwaysUseFullDateTimeFormat = false;

        //Payment Gateway Credits Grid config
        PaymentCreditsConfig = new GridRelatedListController.GridRelatedListConfig();
        PaymentCreditsConfig.uniqueId = 'PaymentCreditsGrid';
        PaymentCreditsConfig.title = 'Payment Gateway Credits';
        PaymentCreditsConfig.objectName = 'Customer_Invoice__c';
        PaymentCreditsConfig.fieldset = 'Payment_Gateway_Credits';
        PaymentCreditsConfig.sortField = 'Name';
        PaymentCreditsConfig.alwaysUseFullDateTimeFormat = false;

    }

    public String getReturnUrl(){
        PageReference pageRef;

        if (customerInvoiceId != null ){
            pageRef =  new PageReference('/' + customerInvoiceId);
        }else if(customerId != null){
            pageRef =  new PageReference('/' + customerId);
        }


        return pageRef.getUrl();
    }

    public String getClaimUrl(){ //KNDY-15033
        PageReference pageRef = new PageReference('/' + claimId);
        return pageRef.getUrl();
    }

    public String getInvoiceCreditsConfigJson() {
        String configStr = JSON.serialize(this.InvoiceCreditsConfig);

        return configStr;
    }

    public string getInvoiceCreditsFieldList() {
        if (InvoiceCreditsFieldList == null && InvoiceCreditsConfig != null) {
            FieldInfo fieldInfoItem;
            FieldInfo fieldInfoItemTemp;
            FieldInfo fieldAllowanceCode;

            // get the Invoice Credits field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(InvoiceCreditsConfig.objectName, InvoiceCreditsConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id' };

            // to set the Refund Amount in the last but one position
            fieldInfoItem = new FieldInfo('refundAmount', claimId == null ? Label.Refund_Amount : Label.Settlement_Amount, 'double',false);
            fieldInfoItem.editable = true;
            fieldInfoItem.required = true;
            fieldInfoItem.scale = 2;
            fieldInfoItem.width = 100;
            fieldInfoItem.filterable = false;

            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                system.debug(logginglevel.error,'fieldName---->'+fieldName);
                fieldInfoList[i].field = 'cusInv.' + fieldName;
                if(fieldName == 'Memo__c'){
                   fieldInfoList[i].editable = true;
                   fieldInfoList[i].filterable = false;
                }else{
                   fieldInfoList[i].editable = false;
                   fieldInfoList[i].filterable = true;
                }
                if(fieldInfoList[i].field =='cusInv.Name'){
                  fieldInfoList[i].referenceTo = 'cusInv.Id';
                  fieldInfoList[i].fieldtype ='Name';
                }
                fieldInfoList[i].width = 100;
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }

            if(claimId != null){ //KNDY-15030
                // to set the Allowance Code
                fieldAllowanceCode = new FieldInfo('lineAllowanceCode', 'Allowance Code' , 'String',false);
                fieldAllowanceCode.editable = false;
                fieldAllowanceCode.required = false;
                fieldAllowanceCode.width = 100;
                fieldAllowanceCode.filterable = true;
                fieldInfoList.add(3, fieldAllowanceCode);
            }

             fieldInfoItemTemp = fieldInfoList[fieldInfoList.size()-1];
             fieldInfoList[fieldInfoList.size()-1] = fieldInfoItem;
             fieldInfoList.add(fieldInfoItemTemp);

             InvoiceCreditsFieldList = JSON.serialize(fieldInfoList);
        }
        return InvoiceCreditsFieldList;
    }

    public String getPaymentCreditsConfigJson() {
        String configStr = JSON.serialize(this.PaymentCreditsConfig);
        return configStr;
    }

    public string getPaymentCreditsFieldList() {
        if (PaymentCreditsFieldList == null &&  PaymentCreditsConfig != null) {
            FieldInfo fieldInfoItem;
            FieldInfo fieldInfoItemTemp;
            // get the Invoice Credits field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(PaymentCreditsConfig.objectName, PaymentCreditsConfig.fieldset);
            Set<String> hiddenFields = new Set<String> { 'Id','Customer_Receipt__r.Payment_Method_3__c' };

            // to set the Refund Amount in the last but one position
            fieldInfoItem = new FieldInfo('refundAmount', Label.Refund_Amount , 'double',false);
            fieldInfoItem.editable = true;
            fieldInfoItem.required = true;
            fieldInfoItem.scale = 2;
            fieldInfoItem.width = 200;

            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                fieldInfoList[i].field = 'cusInv.' + fieldName;
                if(fieldInfoList[i].field == 'cusInv.Memo__c'){
                   fieldInfoList[i].editable = true;
                   fieldInfoList[i].width = 200;
                }else{
                   fieldInfoList[i].editable = false;
                }
                if(fieldInfoList[i].field =='cusInv.Name'){
                  fieldInfoList[i].referenceTo = 'cusInv.Id';
                  fieldInfoList[i].fieldtype ='Name';
                }
                fieldInfoList[i].hidden = hiddenFields.contains(fieldName);
            }

             fieldInfoItemTemp = fieldInfoList[fieldInfoList.size()-1];
             fieldInfoList[fieldInfoList.size()-1] = fieldInfoItem;
             fieldInfoList.add(fieldInfoItemTemp);

             PaymentCreditsFieldList = JSON.serialize(fieldInfoList);
        }
        return PaymentCreditsFieldList;
    }

    public string getRefundMethodFieldList() {

            // get the Refund Method field info list
            List<FieldInfo> fieldInfoList = FieldInfo.fetchJsonFieldInfos(RefundMethodConfig.objectName, RefundMethodConfig.fieldset);
            fieldInfoList.remove(0); //remove ID

            for(Integer i = 0; i < fieldInfoList.size(); i++){
                String fieldName = fieldInfoList[i].field;
                if(fieldName == 'Date_Received__c'){
                   fieldInfoList[i].title = claimId == null ? Label.Refund_Date : Label.Payment_Date;
                }
                fieldInfoList[i].field = fieldName;
                fieldInfoList[i].editable = true;
                fieldInfoList[i].required = true;
                if(fieldName == 'Reference_Number__c'){
                   fieldInfoList[i].required = false;
            }
            }
             RefundMethodFieldList = JSON.serialize(fieldInfoList);
        return RefundMethodFieldList;
    }

    @RemoteAction
    public static JsonResult getRefundMethod(){
       JsonResult result = new JsonResult();
       List<Customer_Receipt__c> custReceiptList = new List<Customer_Receipt__c>();

       Customer_Receipt__c cr = new Customer_Receipt__c();
       cr.Date_Received__c = system.now();
       custReceiptList.add(cr);


       result.records = custReceiptList;
       result.total = custReceiptList.size();
       return result;
    }
    //KNDY-18030 - Method to fetch disbursement bank account from company
    @RemoteAction
    public static JsonResult getRefundBankAccountMethod(id defaultCompany){
       JsonResult result = new JsonResult();

       Company__c defaultDisbursementBankAcct = CompanyService.getCompanyBankAccount(defaultCompany);
       system.debug('defaultDisbursementBankAcct=='+defaultDisbursementBankAcct);

       result.records = (new List<Company__C>{defaultDisbursementBankAcct});
       result.total = 1;
       return result;
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

    @RemoteAction
    public static Claim__c getClaimDetails(Id claimId){
        Claim__c cl = null;
        if( !String.isBlank(claimId)){
            SOQLUtil soql = new SOQLUtil('Claim__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Claim_Balance__c', 'Company__c', 'Company__r.Name',
                'Currency__c', 'Currency__r.Name',
                'Bill_to_Customer__c', 'Bill_to_Customer__r.Name',
                'Parent_Customer__c', 'Parent_Customer__r.Name','Type__c','Source__c'
            });
            soql.setWhereClause('Id = :claimId');
            List<Claim__c> claimList = Database.query(soql.getQuery());
            if (claimList.size() > 0){
                cl = claimList[0];
            }
        }
       return cl;
    }

    @RemoteAction
    public static JsonResult createRefundReceipt( List<Customer_Receipt__c> customerReceiptList, List<String> dateFields,
                                      List<RefundCreditService.InvoiceCreditsWrapper> custInvoices, Double totalRefundAmount ){
       JsonResult result = new JsonResult();
       Savepoint sp = Database.setSavepoint();
       List<Customer_Receipt__c> records = new List<Customer_Receipt__c>();
       boolean goAheadtoFinalizeReceipt = false;
       Id  crId = null;


       try{
	         if( customerReceiptList != null && customerReceiptList.size() > 0  && custInvoices.size() > 0 && totalRefundAmount > 0 ){

	               Customer_Receipt__c customerReceipt = customerReceiptList.get(0);
	               KendoUtils.UpdateDateFields(customerReceipt, dateFields);
	               // save the CustomerReceipt  & Update Bank Account Step - 1
	               crId = RefundCreditService.saveCustomerReceipt( customerReceipt, result, totalRefundAmount );
	               System.debug(logginglevel.error,'crId--->'+crId);

	               // save the Customer Receipt Lines Step - 2
	               if( crId != null ){
	                  goAheadtoFinalizeReceipt = RefundCreditService.saveCustomerReceiptLines( custInvoices, result, crId );
	                  System.debug(logginglevel.error,'goAheadtoFinalizeReceipt--->'+goAheadtoFinalizeReceipt);
	               }

	               // Finalize the CR Step - 3
			       if( goAheadtoFinalizeReceipt ){
			           RefundCreditService.finalizeCustomerReceipt( crId, result );
			       }
		      }
		      if ( result.success ) {
		            System.debug(logginglevel.error, 'In the success result---'+result);
		            List<Customer_Receipt__c> crLst = RefundCreditService.getCustomerReceiptDetails(String.valueOf(crId));
		            String hyperlink = '<a href="/'+ crLst.get(0).Id + '">' +  crLst.get(0).Name + '</a>';
                    result.addMessage( hyperlink +'has been created.', ApexPages.Severity.CONFIRM);
              }


		}catch( DMLException ex ) {
		   system.debug(LoggingLevel.Error,'ex '+ex.getMessage());
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
	        }catch ( DML.InsuffientAccessException e ) {
	            Database.rollback(sp);
	            result.success = false;
	            result.addMessage(Label.Insufficient_access_contact_administrator_for_permissions, ApexPages.Severity.ERROR);
	        }catch ( Exception e ) {
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
	            result.addMessage(e, ApexPages.Severity.ERROR);
	        }
	  return result;
    }


   @RemoteAction
   public static JSONResult settleClaim(Id claimId, List<RefundCreditService.InvoiceCreditsWrapper> custInvoices) {
	   JsonResult result = new JsonResult();
	   Savepoint sp = Database.setSavepoint();

	   try {

		   if(!custInvoices.isEmpty()){
			   list<Customer_Receipt__c> lCRs = ClaimService.credit2(new map<id, list<RefundCreditService.InvoiceCreditsWrapper>> {claimId => custInvoices} );

			   SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true);
			   soql.addFields(new set<String>{'Id','Name'});
			   soql.setWhereClause('Id in :lCRs');

			   lCRs = Database.query(soql.getQuery());
			   String hyperlink = '<a href="/'+ lCRs.get(0).Id + '">' +  lCRs.get(0).Name + '</a>';
			   result.addMessage( hyperlink +'has been created.', ApexPages.Severity.CONFIRM);
		   }
	   }catch( DMLException ex ) {
		   system.debug(LoggingLevel.Error,'ex stacktrace '+ ex.getStackTraceString());
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
	   }catch ( DML.InsuffientAccessException e ) {
		   system.debug(LoggingLevel.Error,'ex stacktrace '+ e.getStackTraceString());
		   Database.rollback(sp);
		   result.success = false;
		   result.addMessage(Label.Insufficient_access_contact_administrator_for_permissions, ApexPages.Severity.ERROR);
	   }catch ( Exception e ) {
		   system.debug(LoggingLevel.Error,'ex stacktrace '+ e.getStackTraceString());
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
		   result.addMessage(e, ApexPages.Severity.ERROR);
	   }

	   return result;
   }

    @RemoteAction
    public static JsonResult getValidInvoicePaymentCredits(List<RefundCreditService.InvoiceCreditsWrapper> invCreditsWrapperList, String customerInvoiceId, Boolean searchFlag){
        JsonResult result = new JsonResult();

        List<RefundCreditService.InvoiceCreditsWrapper> successfulCusInvs =  RefundCreditService.fetchSetteledInvoices( invCreditsWrapperList, customerInvoiceId, searchFlag );

        result.records = successfulCusInvs;
        result.total = successfulCusInvs.size();

        return result;
    }

    @RemoteAction
    public static JsonResult createPaymentGatewayRefundReceipt(List<RefundCreditService.InvoiceCreditsWrapper> invCreditWrapper, String paymentMethodId,  String transactionId){
        JsonResult result = new JsonResult();
        String hyperlink = null;
        system.debug(logginglevel.error,'invCreditWrapper--->>'+invCreditWrapper);
        try{

            PaymentHandler.PaymentResponse pResponse = RefundCreditService.paymentGatewayReceiptHandling(invCreditWrapper, paymentMethodId, transactionId);
	        system.debug(logginglevel.error,'pResponse-->'+pResponse);
	        if(pResponse.isSuccess != null && pResponse.isSuccess == true){
	             result.success = pResponse.isSuccess;
	        }else{

	             result.success = false;
                 result.message = pResponse.response;
	        }
	        if ( result.success ) {
                    Id refundCustReceiptId = pResponse.customerReceiptId;
	                List<Customer_Receipt__c> crLst = RefundCreditService.getCustomerReceiptDetails(String.valueOf(refundCustReceiptId));
	                hyperlink = '<a href="/'+ crLst.get(0).Id + '">' +  crLst.get(0).Name + '</a>';
                    result.addMessage( hyperlink + 'has been created. ', ApexPages.Severity.CONFIRM);
                    System.debug(logginglevel.error, 'In the success result---'+result);
              }

        }catch(Exception ex){
               result.success = false;
               result.message = ex.getMessage();
               system.debug('EXCEPTION: ' +ex.getMessage() + ' ' + ex.getStackTraceString());
        }
        System.debug(logginglevel.error,'result-->'+result);
        return result;
    }



    @RemoteAction
    public static JsonResult getInvoiceCredits(List<KendoUtils.FilterDescriptor> filters, String creditsType, String customerInvoiceId, Boolean searchFlag){

        JsonResult result = new JsonResult();
        List<Customer_Invoice__c> invCreditsList = new List<Customer_Invoice__c>();
        boolean transactionStatus = false;

        if(String.isBlank(customerInvoiceId) == false){
          transactionStatus = RefundCreditService.getCITransactionStatus( Id.valueOf(customerInvoiceId) );
        }
        system.debug(logginglevel.error,'transactionStatus-->'+transactionStatus);
        system.debug(logginglevel.error,'String.isBlank(customerInvoiceId)-->'+String.isBlank(customerInvoiceId));
        system.debug(logginglevel.error,'creditsType-->'+creditsType);
        system.debug(logginglevel.error,'searchFlag-->'+searchFlag);


        if(String.isBlank(customerInvoiceId) == false && transactionStatus && creditsType.equalsIgnoreCase('PaymentGateway') && !searchFlag){
	          system.debug(logginglevel.error,'creditsType--12345-->'+creditsType);
	          invCreditsList = RefundCreditService.getInvoiceCreditsforSingleCI( filters, creditsType, customerInvoiceId );
	    }

	     if(String.isBlank(customerInvoiceId) == false && !transactionStatus && creditsType.equalsIgnoreCase('Invoice') && !searchFlag){
              system.debug(logginglevel.error,'creditsType---->'+creditsType);
              invCreditsList = RefundCreditService.getInvoiceCreditsforSingleCI( filters, creditsType, customerInvoiceId );
        }


        if(String.isBlank(customerInvoiceId) == true || (String.isBlank(customerInvoiceId) == false && searchFlag)){
        //retrieve the query and can fetch records both for Invoice Credits and Payment Gateway
        invCreditsList =   RefundCreditService.retrieveCreditsforRefund(filters,creditsType);
        }

        system.debug(loggingLevel.error, 'queryString--getInvoiceCredits--->' + invCreditsList);

        List<RefundCreditService.InvoiceCreditsWrapper> ciWrapperLines = new List<RefundCreditService.InvoiceCreditsWrapper>();
        RefundCreditService.InvoiceCreditsWrapper invCreditWrapper = null;

        for(Customer_Invoice__c ci : invCreditsList){
            invCreditWrapper = new RefundCreditService.InvoiceCreditsWrapper();
            invCreditWrapper.cusInv = ci;
            invCreditWrapper.refundAmount = 0.00;
            if (ci.Invoice_Type__c == AllowanceRuleService.ALLOWANCE_ACCRUAL &&
                ci.Customer_Invoice_Lines__r != null && ci.Customer_Invoice_Lines__r.size() == 1){
                if(ci.Customer_Invoice_Lines__r[0].Allowance_Applied__c != null && ci.Customer_Invoice_Lines__r[0].Allowance_Applied__r != null){
                    invCreditWrapper.lineAllowanceCode = ci.Customer_Invoice_Lines__r[0].Allowance_Applied__r.Allowance_Code__c;
                }
            }
            ciWrapperLines.add(invCreditWrapper);
        }

        result.records = ciWrapperLines;
        result.total = ciWrapperLines.size();

        return result;
    }

}