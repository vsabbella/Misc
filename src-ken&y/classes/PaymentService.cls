public with sharing class PaymentService {
    
   
    /***********Used in Customer Receipt/AR *************/
    public static final string TYPE_OVERPAYMENT = 'Overpayment';
    public static final string TYPE_OVERPAYMENT_CREDIT = 'Overpayment Applied';
    public static final string TYPE_CREDIT_MEMO = 'Credit Applied';
    public static final string TYPE_DEBIT_MEMO = 'Debit Applied';

    public static final string TYPE_ALLOWANCE_ACCRUAL_APPLIED = 'Allowance Accrual Applied';
    public static final string TYPE_CREDIT_CLAIM = 'Credit Applied - Claim';
    public static final string TYPE_DEBIT_CLAIM = 'Debit Applied - Claim';
    public static final string TYPE_CLAIM_PAYMENT = 'Claim Payment';
    public static final string TYPE_PREPAYMENT_CREDIT = 'Prepayment Applied';
    public static final string TYPE_REFUND_APPLIED_PREPAYMENT = 'Refund Applied Prepayment';
    public static final string TYPE_REFUND_APPLIED_PAYMENT = 'Refund Applied Payment';
    public static final string TYPE_DEDUCTION = 'Deduction';
    public static final string TYPE_INVOICE_DEDUCTION = 'Invoice Deduction';
    public static final string TYPE_GEN_DED = 'General Deduction';
    public static final string TYPE_UNEARNED_DISCOUNT = 'Unearned Terms Discount';
    public static final string TYPE_WRITEOFF = 'Writeoff';
    public static final string TYPE_WRITEOFF_CREDIT = 'Writeoff Credit'; //KNDY-19379

    /***************Used in refund credit *************/
    public static final string TYPE_REFUND_UNAPPLIED_PREPAYMENT = 'Refund Unapplied Prepayment';
    public static final string TYPE_REFUND_UNAPPLIED_OVERPREPAYMENT = 'Refund Unapplied Overpayment';
    public static final string TYPE_REFUND_CREDIT = 'Refund Credit';
    public static final string TYPE_REFUND_ALLOWANCE_ACCRUAL = 'Refund Allowance Accrual'; //KNDY-15033
    
    /***************Used in Supplier Payment/Supplier Invoice/AP *************/
    public static final string STATUS_CANCELLED = 'Cancelled';
    public static final string STATUS_VOID = 'Void';
    public static final string STATUS_APPROVED = 'Approved';
    public static final string STATUS_CLOSED = 'Closed';
    public static final string STATUS_APPLIED = 'Applied';
    public static final string STATUS_REASON_VOID_FROM_OVERFLOW_ADVICE = 'Void from Overflow Advice';
    public static final string STATUS_REASON_ZERO_AMT_PAYMENT_NOT_ALLOWED = 'Zero Amount Payment Creation Not Allowed';
    
    public static final string PAYMENT_METHOD_CHECK = 'Check';
    public static final string TYPE_CREDITMEMO = 'Credit Memo';   
    public static final string TYPE_INVOICE = 'Invoice';
    /***************Used common AP/AR *************/
    public static final string TYPE_PAYMENT = 'Payment';
    public static final string TYPE_PREPAYMENT = 'Prepayment';   
    
    public static final string TYPE_EARNED_DISCOUNT = 'Earned Terms Discount';
    

    public static ExceptionService exService = new ExceptionService();
    
    //This is the ExceptionService for the Payment/Interco, eventually will be consolidated with the payment model
    public static ExceptionService pmtExService = new ExceptionService();

    // match invoice
    public static void matchInvoice(list<Customer_Receipt_Line__c> inputList){
        try{
                // look to match Customer Invoice Number or Customer PO
            set<string> InvoiceNumberSet = new set<string>();
            set<string> CustomerPOSet = new set<string>();
            set<Customer_Receipt_Line__c> validCRLs = new set<Customer_Receipt_Line__c>();
            //Build a set of all Invoice and PO Numbers
            for(Customer_Receipt_Line__c p:inputList){
                if(p.Customer_Invoice_Number__c!=null && p.Customer_Invoice__c == null){ //OTC-725
                	validCRLs.add(p);
                    InvoiceNumberSet.add(p.Customer_Invoice_Number__c);
                }
                if(p.Customer_PO_Number__c!=null){  
                	validCRLs.add(p);
                    CustomerPOSet.add(p.Customer_PO_Number__c);
                }       
            } 
            
            map<string, Customer_Invoice__c> POCImap = new map<string, Customer_Invoice__c>();
            map<string, Customer_Invoice__c> InvNumMap = new map<string, Customer_Invoice__c>();
            
            if(InvoiceNumberSet.size()==0){return;}
            
            // Build maps for all matching invoices
           

            /*
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
            SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'id','Customer__c','name','Customer_Purchase_Order__c','Invoice_Type__c','Sales_Order__c'
            });
            soql.setWhereClause('Customer_Purchase_Order__c in:CustomerPOSet or name in: InvoiceNumberSet');
            for(Customer_Invoice__c CI: Database.query(soql.getQuery())){



                if(ci.Customer_Purchase_Order__c!=null){    
                    POCImap.put(ci.Customer_Purchase_Order__c, ci);
                }       
                
                InvNumMap.put(ci.name, ci);
            }
            
            set<id> ciChangedSet = new set<id>();
            for(Customer_Receipt_Line__c p:validCRLs){
                    // if invoice number matches then copy
                if(InvNumMap.containsKey(p.Customer_Invoice_Number__c)){
                    p.Customer_Invoice__c = InvNumMap.get(p.Customer_Invoice_Number__c).id;
                }else if(POCImap.containsKey(p.Customer_PO_Number__c)){
                    // if no match on invoice number then look for customer PO # (but verify customer is a match)
                    p.Customer_Invoice__c = POCImap.get(p.Customer_PO_Number__c).id;
                }else{
                    //system.debug('Could not find matching Customer Invoice for Payment: ' + p);             
                }
                
                if(p.Customer_Invoice__c!=null){
                    ciChangedSet.add(p.Customer_Invoice__c);
                    exService.clearException(p, ExceptionUtil.CRL_INVOICE_MISSING);
                }else{
                    exService.setException(p, ExceptionUtil.CRL_INVOICE_MISSING);
                }
                //system.debug('P after match ' + p);
            }
            
            
        }catch(exception e){
            //system.debug(logginglevel.error, 'Exception: ' + e);
        }
    }
    
    
    // match credit memo
    public static void matchCreditMemo(list<Customer_Receipt_Line__c> inputList){
        set<string> CreditMemoSet = new set<string>();
        
        for(Customer_Receipt_Line__c p:inputList){
            if(p.Credit_Memo_Number__c!=null){
                CreditMemoSet.add(p.Credit_Memo_Number__c);
            }
        }
        if(CreditMemoSet.size()==0){ return;}
        
        map<string, Customer_Invoice__c> CMNumCIMap = new map<string, Customer_Invoice__c>();
       
        
        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'id','name','Customer__c'
        });
        soql.setWhereClause('name in: CreditMemoSet and Invoice_Type__c = \'Credit Memo\'');
        for(Customer_Invoice__c ci:Database.query(soql.getQuery())){
            
            CMNumCIMap.put(ci.name, ci);
                    
        }
        //system.debug('CM Map ' + CMNumCIMap);
        
        for(Customer_Receipt_Line__c p:inputList){
            //if(CMNumCIMap.containskey(p.Credit_Memo_Number__c)){
            //    p.Customer_Invoice__c = CMNumCIMap.get(p.Credit_Memo_Number__c).id;
            //}else{
            //    //system.debug('Credit Memo could not be found');
            //}

            if(CMNumCIMap.containskey(p.Credit_Memo_Number__c) && CMNumCIMap.get(p.Credit_Memo_Number__c).id!=null){
                p.Customer_Invoice__c = CMNumCIMap.get(p.Credit_Memo_Number__c).id;
                exService.clearException(p, ExceptionUtil.CRL_CREDITMEMO_MISSING);
            }else{
                exService.setException(p, ExceptionUtil.CRL_CREDITMEMO_MISSING);
            }
        }
        
    }
    
    public static void updateLineAmounts(List<Customer_Receipt_Line__c> customerReceiptLines){
        
        for(Customer_Receipt_Line__c crl : customerReceiptLines){
            
            if(crl.amount__c != null && crl.Type__c != null){
                
                //Assign invoice amount and payment amount fields based on type
                if(crl.Type__c == 'Payment'){
                    crl.Invoice_Amount__c = crl.Amount__c;
                    crl.Payment_Amount__c = (-1)*crl.Amount__c;
                }else if(crl.Type__c == 'Invoice Deduction'){
                    crl.Invoice_Amount__c = (-1)*crl.Amount__c;
                    crl.Payment_Amount__c = null;
                }else if(crl.Type__c == 'General Deduction'){
                    crl.Invoice_Amount__c = null;
                    crl.Payment_Amount__c = (-1)*crl.Amount__c;    
                }else if(crl.Type__c.contains('Credit')){
                    crl.Invoice_Amount__c = null;
                    crl.Payment_Amount__c = (-1)*crl.Amount__c;
                }else if(crl.Type__c == PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED){
                    crl.Invoice_Amount__c = null;
                    crl.Payment_Amount__c = (-1)*crl.Amount__c;
                }else if(crl.Type__c == 'Prepayment'){
                    crl.Invoice_Amount__c = null;
                    crl.Payment_Amount__c = (-1)*crl.Amount__c;
                }else if(crl.Type__c == 'Overpayment'){
                    crl.Invoice_Amount__c = null;
                    crl.Payment_Amount__c = (-1)*crl.Amount__c;
                }else if(crl.Type__c == 'Earned Terms Discount'){
                    crl.Invoice_Amount__c = (-1)*crl.Amount__c;
                    crl.Payment_Amount__c = null;
                }else if(crl.Type__c == 'Unearned Terms Discount'){
                    crl.Invoice_Amount__c = (-1)*crl.Amount__c;
                    crl.Payment_Amount__c = null;
                }else if(crl.Type__c == 'Writeoff'){
                    crl.Invoice_Amount__c = (-1)*crl.Amount__c;
                    crl.Payment_Amount__c = null;
                }
            }
        }
        
    }

    @TestVisible
    private static set<Id> processedPaymentMatchIds = new set<Id>();
    public static void updateLineMatchTotals(List<Payment_Match__c> paymentMatches){
    	map<Id, Payment_Match__c> mPaymentMatches = new map<Id, Payment_Match__c>(paymentMatches);
    	if(!processedPaymentMatchIds.containsAll(mPaymentMatches.keySet())){
    		set<Id> invoiceIds = new set<Id>();
    		set<Id> paymentLineIds = new set<Id>();
    		processedPaymentMatchIds.addAll(mPaymentMatches.keySet());
    		for(Payment_Match__c pm : paymentMatches){
	    		paymentLineIds.add(pm.Payment_Line__c);
	    		invoiceIds.add(pm.Invoice__c);
	    		updateMatchTotals(paymentLineIds, invoiceIds);
	    	}
	    	
    	}
    }
    
    
    public static void updateMatchTotals(set<Id> paymentLineIds, set<Id> invoiceIds){
    	
    	map<Id, Invoice__c> mUpdateInvoices = new map<Id, Invoice__c>();
		map<Id, Payment_Line__c> mUpdatePaymentLines = new map<Id, Payment_Line__c>();
		
    	for(Id paymentLineId : paymentLineIds){
    		if(paymentLineId != null){
    			mUpdatePaymentLines.put(paymentLineId, new Payment_Line__c(Id = paymentLineId, Total_Matched_Amount__c = 0));
    		}
    	}
    	
    	for(Id invoiceId : invoiceIds){
    		if(invoiceId != null){
    			mUpdateInvoices.put(invoiceId, new Invoice__c(Id = invoiceId, Amount_Paid__c = 0));
    		}
    	}
    	
		List<AggregateResult> arPmts = [SELECT sum(Amount__c) amount, Invoice__c invoiceId, Payment_Line__c paymentLineId,
												Invoice__r.From_Company__c invoiceFromCompanyId, 
												Invoice__r.To_Company__c invoiceToCompanyId,
												Payment_Line__r.Payment__r.From_Company__c paymentFromCompanyId,
												Payment_Line__r.Payment__r.To_Company__c paymentToCompanyId
											FROM Payment_Match__c
											WHERE 
											(Invoice__c IN :invoiceIds OR Payment_Line__c IN :paymentLineIds)
											AND Invoice__c != null
											AND Finalized__c = true
											GROUP BY 	Invoice__c, Payment_Line__c, 
														Invoice__r.From_Company__c, Invoice__r.To_Company__c,
														Payment_Line__r.Payment__r.From_Company__c, Payment_Line__r.Payment__r.To_Company__c];
		
		
		
		for(AggregateResult ar : arPmts){
			decimal paymentAmount = 0;
			decimal iAmt = decimal.valueOf(string.valueOf(ar.get('amount')));
			
			if(ar.get('invoiceFromCompanyId') == ar.get('paymentToCompanyId')
					&& ar.get('invoiceToCompanyId') == ar.get('paymentFromCompanyId')){
				//If the Payment To is the same as the Invoice From and vice versa, then increase the amount paid
				paymentAmount += iAmt;			
			}else if(ar.get('invoiceFromCompanyId') == ar.get('paymentFromCompanyId')
					&& ar.get('invoiceToCompanyId') == ar.get('paymentToCompanyId')){
				//If the Invoice From is the same as the Payment From and vice versa, then decrease the amount paid
				//Will this ever happen? Validation Rules? Should this show as negative in the UI?
				paymentAmount += iAmt;				
			}
			
			if(ar.get('invoiceId') != null){
				Invoice__c iInv;
				Id iInvId = (Id)ar.get('invoiceId');
				if(mUpdateInvoices.containsKey(iInvId)){
					iInv = mUpdateInvoices.get(iInvId);
				}else{
					iInv = new Invoice__c(Id = iInvId, Amount_Paid__c = 0);
				}
				iInv.Amount_Paid__c += paymentAmount;
				system.debug('iInv: ' + iInv);
				mUpdateInvoices.put(iInv.Id, iInv);
			}
			
			if(ar.get('paymentLineId') != null){
				Payment_Line__c iPml;
				Id iPmlId = (Id)ar.get('paymentLineId');
				if(mUpdatePaymentLines.containsKey(iPmlId)){
					iPml = mUpdatePaymentLines.get(iPmlId);
				}else{
					iPml = new Payment_Line__c(Id = iPmlId, Total_Matched_Amount__c = 0);
				}
				iPml.Total_Matched_Amount__c = paymentAmount;
				system.debug('iPml: ' + iPml);
				mUpdatePaymentLines.put(iPml.Id, iPml);
			}
			
			
		}
		
		if(mUpdateInvoices.keySet().size() > 0){
			update mUpdateInvoices.values();
		}
		
		if(mUpdatePaymentLines.keySet().size() > 0){
			update mUpdatePaymentLines.values();
		}
    		
    		
    	
    }
    
    /*
     *	This method is used to cleanup payment matches when a payment header is being deleted as payment line cascade delete doesn't fire triggers
     */
    public static void paymentCleanup(){
    	if(trigger.isBefore && trigger.isDelete){
    		set<Id> paymentIds = new set<Id>();
    		for(Payment__c pmt : (List<Payment__c>)trigger.old){
    			paymentIds.add(pmt.Id);
    		}
    		if(paymentIds.size() > 0){
    			PaymentLineService.paymentMatchCleanup(paymentIds);
    		}
    	}
    }
    
    public static void onFinalizeChange(){
    	if(trigger.isAfter && trigger.isUpdate){
    		set<Id> finalizeChangeIds = new set<Id>();
    		for(Payment__c pmt : (List<Payment__c>)trigger.new){
    			if(KSE.isFieldChanging('finalized__c', pmt, trigger.oldMap)){
    				finalizeChangeIds.add(pmt.Id);
    			}
    		}
    		if(finalizeChangeIds.size() > 0){
    			updateLineMatchTotals([SELECT Id, Invoice__c, Payment_Line__c 
    									FROM Payment_Match__c 
    									WHERE Payment_Line__r.Payment__c IN :finalizeChangeIds]);
    		}
    	}
    }
    
    
    public static void onUnfinalize() {//KNDY-10986
    	if(trigger.isAfter && trigger.isUpdate) {
    		list<Payment__c> lPs = new list<Payment__c>();
    		for(Payment__c p : (list<Payment__c>)trigger.new) {
    			if(!p.Finalized__c && KSE.isFieldChanging('Finalized__c', p, trigger.oldMap))
    				lPs.add(p);
    		}
    		
    		if(!lPs.isEmpty()){
    			list<Bank_Transaction_Match__c> lBTM2Delete = [Select Id from Bank_Transaction_Match__c where Payment__c in :lPs];
		    	if(!lBTM2Delete.isEmpty())
		    		delete lBTM2Delete;
    		}
    	}
    }
    //KNDY-17564 
    /*
	Description : get next payment number (check/ach/wire) for given bank account
	param
	@ id : pass bank account id to fetch next check/ach/wire number in sequence
	return param
	@Bank_Account__C : returns bank account object with required fields
    */
    public static Bank_Account__c getPaymentNumber( Id bankAccountId ){
		// KNDY-10473 Security Fixes for SOQL queries
        String whereClause = ' id = :bankAccountId FOR UPDATE ' ;
   		SOQLUtil soql = new SOQLUtil ( 'Bank_Account__c' ) ;
   		///KNDY-17919 NEXT ach and Wire numbers are deprecated
   		//KNDY-18900 Replace next check number (number) field with text field
   		soql.addFields ( new Set<String> {'Next_Check_Number_2__c','Use_Pre_Printed_Check_Stock__c','Number_of_Advice_Lines_Per_Page__c'} ) ;
   		soql.setWhereClause ( whereClause ) ;
        
        List<Bank_Account__c> bankAccounts = Database.query ( soql.getQuery () ) ;
        Bank_Account__c ba = bankAccounts.get(0) ;
		return ba;
	}
	//KNDY-18029 - get bank account details for given bank acc id
	/* Description : get bank account details
    @param : ID : bank account id to be fetched
    @return param : sObject of type bank account
    */
    public static Bank_Account__c getBankAccount(Id baId){ //KNDY-13561
        SOQLUtil soql = new SOQLUtil('Bank_Account__c', true); //enforceFLS=true, running in user mode
        //KNDY-18029 - fetch disbursment/deposit bank account payment method
        soql.addFields(new set<string>{
            'id','Company__c', 'Currency__c','Primary_Disbursement_Payment_Method__c','Primary_Deposit_Payment_Method__c'
                });
        soql.setWhereClause('Id = :baId');
        soql.setLimit(1);
        List<Bank_Account__c> bas = Database.query(soql.getQuery());
        Bank_Account__c ba = bas[0] ;
        return ba;
    }   
}