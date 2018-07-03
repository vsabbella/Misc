public with sharing class RefundCreditService {
    
 public static List<Customer_Invoice__c> retrieveCreditsforRefund(List<KendoUtils.FilterDescriptor> filters, String creditsType){
        
        Set<Id> invCreditsIds = new Set<Id>(); 
        List<Customer_Invoice__c> invCreditsList = new List<Customer_Invoice__c>(); 
        Set<String> transactionIds = new Set<String>(); 
        Set<Id> invoicesLst = new Set<Id>();
        
        List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
        String customerId = '';
        for(KendoUtils.FilterDescriptor fd: filters){
            System.debug(logginglevel.error,'fd---->'+fd); 
            String tmp = String.valueOf(fd.value); 
            String filterVal = tmp.trim();
            if(fd.field == 'Customer__c'){
                customerId = String.valueOf(fd.value);
            }
            if (filterVal.length() > 0){ //condition that checks for value and adds it to the filters
                newFilters.add(fd);
            }
        } 
        
        String whereClauseCondition = ' Customer_Receipt__c != Null  AND Customer_Receipt__r.Transaction_ID__c != Null ' +
                            ' AND Customer_Receipt__r.Payment_Method_3__c != Null ';
        
        //Fetching the Payment Gateway Credits(CIs)
        SOQLUtil soqltofilterCIs = new SOQLUtil('Customer_Invoice__c',true);  
        soqltofilterCIs.addFields(new set<string>{'Id'});  //'Customer_Receipt__r.Transaction_Id__c'
        soqltofilterCIs.setWhereClause(whereClauseCondition);
        
        for(Customer_Invoice__c ci : (List<Customer_Invoice__c>)Database.query(soqltofilterCIs.getQuery())){
            invCreditsIds.add(ci.Id);
        }
        
        //Fetching the Bill to, Record Type of Customer
        SOQLUtil customerRecordTypeSoql = new SOQLUtil('Customer__c',true);  
        customerRecordTypeSoql.addFields(new set<string>{'Id'});
        customerRecordTypeSoql.setWhereClause('RecordType.Name = \'Bill To\' and Id = :customerId' );
        
        List<Customer__c> custList = Database.query(customerRecordTypeSoql.getQuery());
        
        List<String> filterCriteria = KendoUtils.getFilterCriteria(newFilters);
        filterCriteria.add('Balance__c < 0');
        filterCriteria.add('Status__c not in (\'Closed\',\'Cancelled\',\'Void\')');
        filterCriteria.add('Finalized__c = true');
        
        String whereClause = '';
        if ( filterCriteria.size() > 0 ) {
            whereClause += String.join(filterCriteria, ' AND ');
            
            if( custList != null && custList.size() == 1 ){ // to determine if the customer is of record type - Bill To
               System.debug(logginglevel.error, 'custList-->>'+custList);
               whereClause =  whereClause.replace('Customer__c', 'Bill_To_Customer__c'); 
               System.debug(logginglevel.error, 'whereClause-->>'+whereClause);
            }
            if( invCreditsIds != null && invCreditsIds.size() > 0 ){
	             if(creditsType != null && creditsType.equals('Invoice')){
	              whereClause += ' AND Id not in :invCreditsIds order by CreatedDate';  
	                
	            }else
	            {
	              whereClause += ' AND Id in :invCreditsIds order by CreatedDate';
	            }
            }
        }
   
        SOQLUtil soql = new SOQLUtil('Customer_Invoice__c',true);
        soql.addFields(new set<string>{'Id'});
        if(creditsType != null && creditsType.equals('Invoice'))
        soql.addFields('Invoice_Credits');
        else
          soql.addFields('Payment_Gateway_Credits');    
        soql.setWhereClause(whereClause);
        
        // Assumption: Allowance Accrual CIs will have 1 line only
        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoice_Lines__r');//KNDY-15030
        childRel.addFields(new set<string>{
            'Id', 'Allowance_Applied__c', 'Allowance_Applied__r.Id','Allowance_Applied__r.Allowance_Code__c'
        });
        childRel.setWhereClause('Customer_Invoice__r.Invoice_Type__c = \'' + AllowanceRuleService.ALLOWANCE_ACCRUAL + '\'  limit 1');
        soql.addChildRelationship(childRel);
        system.debug(loggingLevel.error, 'query-2->' + soql.getQuery());
        
        invCreditsList = Database.query(soql.getQuery());
       
        return invCreditsList;
   }
   
 
   public static List<RefundCreditService.InvoiceCreditsWrapper> fetchSetteledInvoices(List<RefundCreditService.InvoiceCreditsWrapper> pgcreditInvoices, String customerInvoiceId, Boolean searchFlag){
   
       List<RefundCreditService.InvoiceCreditsWrapper> validpgcredits = new List<RefundCreditService.InvoiceCreditsWrapper>();
       Set<Id> invoiceIds = new Set<Id>();
       Map<String,Id> transCusInvMap = new Map<String,Id>();
       Set<Id> validCusInvIds = new Set<Id>();
       
       for(RefundCreditService.InvoiceCreditsWrapper invCrWrap : pgcreditInvoices){
           invoiceIds.add(invCrWrap.cusInv.Id);
       }
       
        String whereClauseCondition = ' Customer_Receipt__c != Null  AND Customer_Receipt__r.Transaction_ID__c != Null ' +
                            ' AND Customer_Receipt__r.Payment_Method_3__c != Null ';
                            
        if(customerInvoiceId != null && !searchFlag)
          whereClauseCondition += ' AND Id = :customerInvoiceId ';
        else
          whereClauseCondition += ' AND Id in :invoiceIds ';
        
        //Fetching the Payment Gateway Credits(CIs) & Transaction Ids
        SOQLUtil soqltofilterCIs = new SOQLUtil('Customer_Invoice__c',true);  
        soqltofilterCIs.addFields(new set<string>{'Id','Customer_Receipt__r.Transaction_Id__c'}); 
        soqltofilterCIs.setWhereClause(whereClauseCondition);
        
        List<Customer_Invoice__c> cusInvList = Database.query(soqltofilterCIs.getQuery());
        
        for(Customer_Invoice__c ci : cusInvList){
           transCusInvMap.put(ci.Customer_Receipt__r.Transaction_Id__c, ci.Id);
        }
       
       // call the payment handler to get the settledSuccessfully Invoices.
       try{
             PaymentHandler ph = new PaymentHandler();
             for(String transId : transCusInvMap.keySet()){
		           if(ph.isTransactionRefundable(transId)){
		               validCusInvIds.add(transCusInvMap.get(transId));
		           }
		       }
       	
        }catch(PaymentHandler.PaymentHandlerException phException){
           system.debug(logginglevel.error,'Inside PaymentHandlerException--->'+phException.getMessage());
        }
       
       for(RefundCreditService.InvoiceCreditsWrapper invCrWrap : pgcreditInvoices){
           if(validCusInvIds.contains(invCrWrap.cusInv.Id)){
               validpgcredits.add(invCrWrap);
           }
        }
      
       return validpgcredits;
   }
   
   public static Id saveCustomerReceipt(Customer_Receipt__c customerReceipt, JsonResult result, Double refundAmount ){
       
        List<Customer_Receipt__c> custRecptList = new List<Customer_Receipt__c>();
        Customer_Receipt__c custRecpt = new Customer_Receipt__c();
        
        if(customerReceipt != null){
            system.debug(logginglevel.error,'customerReceipt '+customerReceipt);
            
            
            custRecpt.Company__c = customerReceipt.Company__c;
            custRecpt.Bank_Account_2__c = customerReceipt.Bank_Account_2__c;
            custRecpt.Customer__c = customerReceipt.Customer__c;  
            custRecpt.Currency__c = customerReceipt.Currency__c;
            if (customerReceipt.Claim__c != null){
                custRecpt.Claim__c = customerReceipt.Claim__c; //KNDY-15033
            }
            custRecpt.Amount_Received__c = -1 * refundAmount;
            custRecpt.Type__c = CustomerReceiptService.TYPE_REFUND;
            custRecpt.Date_Received__c = customerReceipt.Date_Received__c;
            custRecpt.Payment_Method_G__c = customerReceipt.Payment_Method_G__c;
            custRecpt.Reference_Number__c = customerReceipt.Reference_Number__c;
            system.debug(logginglevel.error,'customerReceipt PM -->'+customerReceipt.Payment_Method_G__c);
            system.debug(logginglevel.error,'customerReceipt  RN-->'+customerReceipt.Reference_Number__c);
            system.debug(logginglevel.error,'custRecpt -->'+custRecpt);
            //KNDY-17697 commented since bank info will be updated while finalizing CR due to overflow remittance
            //List<Bank_Account__c> bankDetails = getBankAccountDetails(customerReceipt.Bank_Account_2__c);
            List<Customer__c> customerDetails = getCustomerDetails(customerReceipt.Customer__c);
            //KNDY-17697 commented since bank info will be updated while finalizing CR due to overflow remittance
            /*if(bankDetails != null && bankDetails.size() == 1){
	            if(customerReceipt.Payment_Method_G__c == 'Check'){
	               custRecpt.Reference_Number__c = String.valueOf(bankDetails[0].Next_Check_Number__c);
	               bankDetails[0].Next_Check_Number__c += 1;
	            }else if(customerReceipt.Payment_Method_G__c == 'Wire'){
	               custRecpt.Reference_Number__c = String.valueOf(bankDetails[0].Next_Wire_Number__c);
	               bankDetails[0].Next_Wire_Number__c += 1;
	            }
	        }*/
	        
	        if(customerDetails != null && customerDetails.size() == 1){
	            
	            custRecpt.Customer_Street__c = customerDetails[0].Customer_Street__c;
	            custRecpt.Customer_City__c = customerDetails[0].Customer_City__c;
	            custRecpt.Customer_State__c = customerDetails[0].Customer_State__c;
	            custRecpt.Customer_Country__c = customerDetails[0].Customer_Country__c;
	            custRecpt.Customer_Zip_Code__c = customerDetails[0].Customer_Zip_Code__c;
	            
	        }
	        
	        DML.InsertAsUser(custRecpt);
            if(custRecpt.Id != null){
                custRecptList.add(custRecpt);
                //KNDY-17697 commented since bank info will be updated while finalizing CR due to overflow remittance
                //DML.UpdateAsUser(bankDetails);
            }
             
        }
        result.success = true;
        return custRecpt.Id;
    }
    
    public static List<Customer_Receipt__c> getCustomerReceiptDetails(String crId){
        
            List<Customer_Receipt__c> customerReceiptLst = new List<Customer_Receipt__c>();
            Customer_Receipt__c customerReceipt = new Customer_Receipt__c();
            SOQLUtil soql = new SOQLUtil('Customer_Receipt__c',true);
            //KNDY-17697 added total no of lines, bank acc and payment method for overflow remittance
            soql.addFields(new set<string>{'Id','name','Total_Number_Of_Lines__c','Bank_Account_2__c','Payment_Method_G__c'}); 
            soql.setWhereClause('Id = :crId');
            soql.setLimit(1);
            system.debug(loggingLevel.error, 'query-->' + soql.getQuery());
        
            customerReceipt = Database.query(soql.getQuery());
            customerReceiptLst.add(customerReceipt);
            
            return customerReceiptLst;
        
    }
    
    //KNDY-17919 - deprecate ACH/Wire numbers from bank. so allowing user to enter reference number
    //commented since method usage is commented out
    /*public static List<Bank_Account__c> getBankAccountDetails(String bankAccountId){
        List<Bank_Account__c> bankAccDetails = new List<Bank_Account__c>();
        
        SOQLUtil soql = new SOQLUtil('Bank_Account__c',true);
        soql.addFields(new set<string>{'Id', 'Next_Check_Number__c','Next_Wire_Number__c'});
        soql.setWhereClause('Id = :bankAccountId');
        soql.setLimit(1);
        system.debug(loggingLevel.error, 'query-->' + soql.getQuery());
        
        bankAccDetails = Database.query(soql.getQuery());
        
        return bankAccDetails;
    }*/
    
    public static boolean getCITransactionStatus(Id theCustomerInvoiceId){
    
        //Fetching the Payment Gateway CI - transaction status
        boolean status = false;
        SOQLUtil soqltoCI = new SOQLUtil('Customer_Invoice__c',true);  
        soqltoCI.addFields(new set<string>{'Id', 'Customer_Receipt__c', 'Customer_Receipt__r.Transaction_ID__c', 'Customer_Receipt__r.Payment_Method_3__c'}); 
        soqltoCI.setWhereClause('Id = :theCustomerInvoiceId');
        soqltoCI.setLimit(1);
        
        List<Customer_Invoice__c> custInvoiceLst = Database.query(soqltoCI.getQuery());
        System.debug(logginglevel.error,'custInvoiceLst--->'+custInvoiceLst); 
        
       try{
	           if(custInvoiceLst[0].Customer_Receipt__c != null && custInvoiceLst[0].Customer_Receipt__r.Transaction_ID__c != null 
	                                             && custInvoiceLst[0].Customer_Receipt__r.Payment_Method_3__c != null){
                   PaymentHandler ph = new PaymentHandler();
	               status = ph.isTransactionRefundable(custInvoiceLst[0].Customer_Receipt__r.Transaction_ID__c);
	           }    
        }catch(PaymentHandler.PaymentHandlerException phException){
           system.debug(logginglevel.error,'Inside PaymentHandlerException--->'+phException.getMessage());
           //custInvoiceLst[0].addError(phException.getMessage());
        }
        return status;
   }
    
    public static boolean saveCustomerReceiptLines( List<RefundCreditService.InvoiceCreditsWrapper> custInvoices, JsonResult result, Id crId ){
        system.debug(logginglevel.error,'Inside the saveCustomerReceiptLines****1');
        boolean successStatus = false;
        List<Customer_Receipt_Line__c> recptLinestoInsert = new List<Customer_Receipt_Line__c>();
        //set<String> InvoiceTypesForAccurals = new set<String>{}; //Add Invoice Types for Accurals  
        
        for(RefundCreditService.InvoiceCreditsWrapper invCreditWrap : custInvoices){
                Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();

                if(invCreditWrap.refundAmount > 0){
                   
                    crl.Amount__c = -1 * invCreditWrap.refundAmount; 
                    crl.Customer_Receipt__c = crId;
                    crl.Customer_Invoice__c = invCreditWrap.cusInv.Id; //KNDY-13995 - removed reference of customer credit invoice field
                    
                    if(invCreditWrap.cusInv.invoice_type__c == CustomerInvoiceService.CM_PREPAYMENT){
                        crl.Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT;
                    }else if(invCreditWrap.cusInv.invoice_type__c == CustomerInvoiceService.CM_OVERPAYMENT){
                        crl.Type__c = PaymentService.TYPE_REFUND_UNAPPLIED_OVERPREPAYMENT;
                    }else if(invCreditWrap.cusInv.invoice_type__c == CustomerInvoiceService.TYPE_MANUAL){
                        crl.Type__c = PaymentService.TYPE_REFUND_CREDIT;
                    }else if(invCreditWrap.cusInv.invoice_type__c.contains(CustomerInvoiceService.TYPE_ADJUSTMENT)){ 
                        crl.Type__c = PaymentService.TYPE_REFUND_CREDIT;    
                    }else if(invCreditWrap.cusInv.invoice_type__c.contains(CustomerInvoiceService.TYPE_RMA)){
                        crl.Type__c = PaymentService.TYPE_REFUND_CREDIT;
                    }else if(invCreditWrap.cusInv.invoice_type__c.contains(AllowanceRuleService.ALLOWANCE_ACCRUAL)){
                        crl.Type__c = PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL;//KNDY-15033
                    }
                    else{
                        crl.Type__c = PaymentService.TYPE_REFUND_CREDIT; 
                    }
                    /* KK : To be uncommented when the Invoice types for accurals are added.
                     else if(InvoiceTypesForAccurals.contains(invCreditWrap.cusInv.invoice_type__c)){
                        crl.Type__c = PaymentService.TYPE_REFUND_CREDIT;
                    } */
                     crl.Memo__c = invCreditWrap.cusInv.Memo__c;
                    
                    recptLinestoInsert.add(crl);
               }
        }   
        
        if(! recptLinestoInsert.isEmpty()){
            DML.insertAsUser(recptLinestoInsert);
            successStatus = true;
        }      
        
        result.success = true;  
        return successStatus;
    }
    
    
    public static PaymentHandler.PaymentResponse paymentGatewayReceiptHandling(List<RefundCreditService.InvoiceCreditsWrapper> invCreditWrapper, String paymentMethodId,  String transactionId){
      
      PaymentHandler.PaymentResponse pResponse = null;
      
      try
      {  
        PaymentHandler ph = new PaymentHandler();
        pResponse = ph.refundTransaction( paymentMethodId, transactionId, invCreditWrapper[0].cusInv.Customer_Receipt__c, invCreditWrapper[0].refundAmount, invCreditWrapper[0].cusInv.Memo__c);
        System.debug(logginglevel.error,'pResponse-->'+pResponse);
      }catch(PaymentHandler.PaymentHandlerException phExp){
        system.debug(LoggingLevel.ERROR, 'PH EXCEPTION: ' +phExp.getMessage() + ' ' + phExp.getStackTraceString());  
      }  
      return pResponse;
    }       
    
    
    public static List<Customer_Invoice__c> getInvoiceCreditsforSingleCI( List<KendoUtils.FilterDescriptor> filters, String creditsType, Id customerInvoiceId ){
          
          System.debug(logginglevel.error,'Inside the method getInvoiceCreditsforSingleCI****');
         String customerId = '';
         List<KendoUtils.FilterDescriptor> newFilters = new List<KendoUtils.FilterDescriptor>();
	     for(KendoUtils.FilterDescriptor fd: filters){
	            System.debug(logginglevel.error,'fd---->'+fd); 
	            String tmp = String.valueOf(fd.value); 
	            String filterVal = tmp.trim();
	            if(fd.field == 'Customer__c'){
                  customerId = String.valueOf(fd.value);
                }
	            if (filterVal.length() > 0){ //condition that checks for value and adds it to the filters
	                newFilters.add(fd);
	            }
          }
          
            List<String> filterCriteria = KendoUtils.getFilterCriteria(newFilters);
	        filterCriteria.add('Balance__c < 0');
	        filterCriteria.add('Status__c not in (\'Closed\',\'Cancelled\',\'Void\')');
	        filterCriteria.add('Finalized__c = true');
	        
	        String whereClause = '';
	        if ( filterCriteria.size() > 0 ) {
	            whereClause += String.join(filterCriteria, ' AND ');
	        }
	        
	        if(customerInvoiceId != null) {
	          whereClause += ' AND Id = :customerInvoiceId order by CreatedDate';
	        }
          
            //Fetching the Bill to, Record Type of Customer
	        SOQLUtil customerRecordTypeSoql = new SOQLUtil('Customer__c',true);  
	        customerRecordTypeSoql.addFields(new set<string>{'Id'});
	        customerRecordTypeSoql.setWhereClause('RecordType.Name = \'Bill To\' and Id = :customerId' );
	        
	        List<Customer__c> custList = Database.query(customerRecordTypeSoql.getQuery());
            
            if( custList != null && custList.size() == 1 ){ // to determine if the customer is of record type - Bill To
               System.debug(logginglevel.error, 'custList-->>'+custList);
               whereClause =  whereClause.replace('Customer__c', 'Bill_To_Customer__c'); 
               System.debug(logginglevel.error, 'whereClause-->>'+whereClause);
            }
	        
          List<Customer_Invoice__c> invCreditsList = new List<Customer_Invoice__c>(); 
            SOQLUtil soql = new SOQLUtil('Customer_Invoice__c',true);
            soql.addFields(new set<string>{'Id'});
            if(creditsType != null && creditsType.equals('Invoice'))
              soql.addFields('Invoice_Credits');
            else
              soql.addFields('Payment_Gateway_Credits');    
            soql.setWhereClause(whereClause);
            
            // Assumption: Allowance Accrual CIs will have 1 line only
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoice_Lines__r');//KNDY-15030
            childRel.addFields(new set<string>{
                'Id', 'Allowance_Applied__c', 'Allowance_Applied__r.Id','Allowance_Applied__r.Allowance_Code__c'
            });
            childRel.setWhereClause('Customer_Invoice__r.Invoice_Type__c = \'' + AllowanceRuleService.ALLOWANCE_ACCRUAL + '\'  limit 1');
            soql.addChildRelationship(childRel);
		
            system.debug(loggingLevel.error, 'getInvoiceCreditsforSingleCI --query-->' + soql.getQuery());
            invCreditsList = Database.query(soql.getQuery());
           System.debug(logginglevel.error,'invCreditsList---getInvoiceCreditsforSingleCI--->'+invCreditsList); 
         return invCreditsList;
    }
    
    
    public static List<Customer__c> getCustomerDetails(String customerId){
        
        List<Customer__c> customerDetails = new List<Customer__c>();
        
        SOQLUtil soql = new SOQLUtil('Customer__c',true);
        soql.addFields(new set<string>{'Id', 'Customer_Street__c','Customer_City__c','Customer_State__c',
                                                     'Customer_Country__c','Customer_Zip_Code__c'});
        soql.setWhereClause('Id = :customerId');
        soql.setLimit(1);
        system.debug(loggingLevel.error, 'query-->' + soql.getQuery());
        
        customerDetails = Database.query(soql.getQuery());
        
        return customerDetails;
    }
    
    
    
    /*public static void finalizeCustomerReceipt(Id crId, JsonResult result) {
            
            List<Customer_Receipt__c> customerReceiptLst = getCustomerReceiptDetails(crId);
                Customer_Receipt__c customerReceipt = (Customer_Receipt__c)customerReceiptLst.get(0);
	            customerReceipt.Finalized__c = true;
	            customerReceipt.Finalized_Date__c = system.now();
	            customerReceipt.Posting_Date__c = system.now();
           
            DML.updateAsUser(customerReceipt);
            
   } */
   //KNDY-17697 added total no of lines for overflow remittance
	public static void finalizeCustomerReceipt(Id crId, JsonResult result) {
        Map<id,Map<decimal,sObject>> skippedCheckNoIdMap = new Map<id,Map<decimal,sObject>>();
		Map<decimal,sObject> skippedCheckSObj = new Map<decimal,sObject>();
		Map<decimal,sObject> skippedCheckSObjTemp = new Map<decimal,sObject>();
		decimal nextNumberFromBank = 0;
		//try{      
		//fetch customer receipt from DB		
		List<Customer_Receipt__c> customerReceiptLst = getCustomerReceiptDetails(crId);
		Customer_Receipt__c customerReceipt = (Customer_Receipt__c)customerReceiptLst.get(0);
		customerReceipt.Finalized__c = true;
        customerReceipt.Finalized_Date__c = system.now();
        customerReceipt.Posting_Date__c = system.now();        
		//get skipped check map for refunded customer receipt
		Bank_Account__c bankAccount = PaymentService.getPaymentNumber( customerReceipt.Bank_Account_2__c );
		
		if (customerReceipt.Payment_Method_G__c == 'Check' && bankAccount != null) {
			//KNDY-18900 Replace next check number (number) field with text field
			nextNumberFromBank =  bankAccount.Next_Check_Number_2__c == null ? 0 : Decimal.ValueOf(bankAccount.Next_Check_Number_2__c);			
			if (bankAccount.Use_Pre_Printed_Check_Stock__c && bankAccount.Number_of_Advice_Lines_Per_Page__c > 0){
				skippedCheckNoIdMap = CheckService.getSkippedCheckDetailsForSingleRecord((Integer)customerReceipt.Total_Number_Of_Lines__c,customerReceipt.Id,bankAccount);
			}
		} 
		//fetch next check/wire numbers 
		if( nextNumberFromBank == null ) { nextNumberFromBank = 0; }
		
	   	if(customerReceipt.Payment_Method_G__c == 'Check'){
	   		customerReceipt.Reference_Number__c = String.valueOf(nextNumberFromBank);     
       		if (bankAccount.Use_Pre_Printed_Check_Stock__c && bankAccount.Number_of_Advice_Lines_Per_Page__c > 0){
	           	skippedCheckSObj = skippedCheckNoIdMap.get(customerReceipt.Id);
	           	system.debug(LoggingLevel.WARN,'inside finalizeSupplierPayment skippedCheckSObj='+skippedCheckSObj);
	           	//no need to sequence check numbers since we only do one CR at a time
	           	if (skippedCheckSObj != null){
	           		skippedCheckSObj = CheckService.updateClonedObject((sObject) customerReceipt,skippedCheckSObj);
					List<Customer_Receipt__c> clonedCRList = new List<Customer_Receipt__c>();
					system.debug(LoggingLevel.Error,'skippedCheckSObj.values()=='+skippedCheckSObj.values());
					for (sObject sobjReceipt : skippedCheckSObj.values()){
						clonedCRList.add((Customer_Receipt__c) sobjReceipt);					
						nextNumberFromBank = Decimal.ValueOf((string)sobjReceipt.get('Reference_Number__c'));
					}
					customerReceiptLst.addAll(clonedCRList);
	           	}
   			}  
            
	  	 }     
		
		//to insert new cloned CRs and update original CR used upsert instead of update
     	DML.upsertAsSystem(); upsert customerReceiptLst id;
        nextNumberFromBank++;          
        system.debug(LoggingLevel.Error,'nextNumberFromBank before updating in bank='+nextNumberFromBank);
        CheckService.updateBankAccount(bankAccount,nextNumberFromBank,customerReceipt.Payment_Method_G__c);  
        /*}
        catch(Exception ex){
        	system.debug('exception in finalizing ' + ex.getMessage() + ' Stacktrace : ' + ex.getStackTraceString());
        }*/
   }
    public class InvoiceCreditsWrapper{
        
        public Customer_Invoice__c cusInv { get; set;}
        public decimal refundAmount {get; set;}
        public String lineAllowanceCode {get; set;}
        public InvoiceCreditsWrapper(){
            this.cusInv = new Customer_Invoice__c(); 
            this.refundAmount = 0.00;
            this.lineAllowanceCode = '';
        }   
    }
    
}