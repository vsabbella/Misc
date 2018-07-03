public with sharing class CustomerReceiptService {
	
	public class CustomerReceiptException extends Exception {}
	public static boolean isCodeExecuted = false;
	public static boolean isCRUnfinalized = false;
	public static final string TYPE_RECEIPT = 'Receipt';
	public static final string TYPE_PREPAYMENT = 'Prepayment';
	public static final string TYPE_CLAIM_SETTLEMENT = 'Claim Settlement';
	public static final string  STATUS_HELD_FOR_REVIEW= 'Held for Review';
	public static final string TYPE_REFUND = 'Refund';
	public static ExceptionService exService = new ExceptionService();
    public static Set<Id> finalizedCRIds = new set<Id>();
    
    
    //AR-139
    public static void checkCustomerHeirarchyOnReceiptLines() {
    	if(trigger.isBefore && trigger.isUpdate) {
    		for(Customer_Receipt__c cr : (list<Customer_Receipt__c>)trigger.new) {
    			if(KSE.isFieldChanging('Customer__c',cr,trigger.oldmap) && cr.Total_Number_Of_Lines__c != 0) 
    				cr.addError(Label.Cannot_change_the_customer_on_the_receipt_that_has_lines);
			}
		}	
    }
   
    

    
    //OTC-406
    public  class PaymentFieldsWrapper
    {
    	decimal amountToApply;
    	decimal totalPayment;
    	
    	
    	PaymentFieldsWrapper()
    	{
    		this.amountToApply = 0.0;
    		this.totalPayment = 0.0;
    	}
    	void addSource(decimal source)
    	{
    		amountToApply = amountToApply + source;
    	}
    	void addPayment(decimal payment)
    	{
    		totalPayment = totalPayment + payment;
    	}
    }
    
    public static void validateReceipts(List<Customer_Receipt__c> customerReceipts){
        for(Customer_Receipt__c cr : customerReceipts){
            if(cr.finalized__c && cr.Balance__c != 0){
                //exService.setException(cr, ExceptionUtil.CR_BALANCE);
            }else{
                //exService.clearException(cr, ExceptionUtil.CR_BALANCE);
            }
        }
    }
    
    //OTC-406 - Finalize()
    public static void finalize()
    {
    	set<ID> CR_IDs = new set<ID>();
    	map<Id,Customer_Receipt__c> triggerMap = new map<ID,Customer_Receipt__c>();
    	list<Customer_Receipt__c> lCRs  = new list<Customer_Receipt__c>();
    	system.debug(logginglevel.error,'isCodeExecuted '+isCodeExecuted);
    	if(trigger.isUpdate && trigger.isBefore  && isCodeExecuted == false)
    	{
    		system.debug(logginglevel.error,'isCodeExecuted: '+isCodeExecuted);
    		for(Customer_Receipt__c cr : (list<Customer_Receipt__c>)trigger.new)
    		{
    			if(cr.Finalized__c && cr.Finalized__c != trigger.oldmap.get(cr.Id).get('Finalized__c'))
    			{
    				triggerMap.put(cr.id, cr);
    				//cr.Finalized_Date__c = system.now();
    				//cr.posting_date__c = system.now();
    			}
    		}
    		if(!triggermap.isEmpty())
    		{
    			isCodeExecuted = true;
    			for(Customer_receipt__c validCR :  recalculateAmountUnappplied(triggermap))
	    		{
	    			if(validCR.Amount_Unapplied__c != 0)
	    			{
	    				system.debug('unfinalize back==' + validCR.Amount_Unapplied__c);
	    				validCR.Finalized_Date__c = null;
	    				validCR.posting_date__c = null;
	    				validCR.Finalized__c = false;
	    			}
	    				
	    		}
    		}
    		
    	}
    }
    
    public static list<Customer_Receipt__c> recalculateAmountUnappplied(map<Id,Customer_Receipt__c> triggerMap)
    {
    	map<Id,PaymentFieldsWrapper> mapCRs = new map<ID,PaymentFieldsWrapper>();
    	//CRL types that hold money to use somewhere else
    	set<String> sourcePayment = new set<String>{PaymentService.TYPE_CREDIT_MEMO,PaymentService.TYPE_GEN_DED, PaymentService.TYPE_PREPAYMENT_CREDIT, PaymentService.TYPE_OVERPAYMENT_CREDIT, PaymentService.TYPE_CREDIT_CLAIM,PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED};
    	// CRL types apply the money from source
    	set<String> applyPayment = new set<String>{PaymentService.TYPE_REFUND_APPLIED_PAYMENT, PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT,PaymentService.TYPE_PAYMENT,PaymentService.TYPE_CLAIM_PAYMENT, PaymentService.TYPE_PREPAYMENT,PaymentService.TYPE_OVERPAYMENT, PaymentService.TYPE_DEBIT_MEMO, PaymentService.TYPE_DEBIT_CLAIM, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT,PaymentService.TYPE_REFUND_UNAPPLIED_OVERPREPAYMENT,PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL,PaymentService.TYPE_REFUND_CREDIT};
    	map<Id,Customer_Receipt_Line__c> mapCRLs = new map<Id,Customer_Receipt_Line__c>();
    	list<Customer_Receipt__c> listCRs = new list<Customer_Receipt__c>();
    	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		Set<Id> tIds = triggerMap.keySet();
		soql.setWhereClause('ID in :tIds');
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipt_Lines__r');
		childRel.addFields(new set<string>{
			'Id','Type__c','Amount__c','Customer_Receipt__c','Customer_Invoice__c','Customer_Invoice__r.Total_Amount__c'//,'Customer_Credit_Memo__c' KNDY-13995
		});
		childRel.setWhereClause('Type__c in :sourcePayment OR Type__c in :applyPayment');
		soql.addChildRelationship(childRel);
		for (Customer_Receipt__c cr : Database.query(soql.getQuery())) {
			system.debug('process amount on CR=' + cr);
			system.debug('process amount on trigger CR=' + triggerMap.get(cr.Id));
    		Decimal amtReceived = triggerMap.get(cr.Id).Amount_Received__c;
    		if(!mapCRs.containsKey(cr.Id))
    		{
    			PaymentFieldsWrapper p = new PaymentFieldsWrapper();
    			p.addSource((amtReceived == null ? 0 :amtReceived)); // added to amount to apply
    			mapCRs.put(cr.Id, p);
    		}
    		else
    		{
    			mapCRs.get(cr.ID).addSource((amtReceived == null ? 0 :amtReceived));
    		}
    		
	    	
	    	for(Customer_Receipt_Line__c crl : cr.Customer_Receipt_Lines__r)
	    	{
	    		system.debug('inside cr service. type: '+crl.Type__c);
	    		system.debug(applyPayment);
	    		if(sourcePayment.contains(crl.Type__c))
	    		{
	    			if((crl.Type__c == PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED || crl.Type__c == PaymentService.TYPE_CREDIT_MEMO)
	    				 && crl.Customer_Invoice__c != null && crl.Customer_Invoice__r.Total_Amount__c > 0 )//&& crl.Customer_Credit_Memo__c != null && crl.Customer_Invoice__c == crl.Customer_Credit_Memo__c KNDY-13995
	    			{	
	    				system.debug('continue in recalculation'+ crl);
	    				continue;
	    			}
	    			else
	    			{
	    				if(!mapCRs.containsKey(crl.Customer_Receipt__c))
			    		{
			    			PaymentFieldsWrapper p = new PaymentFieldsWrapper();
			    			p.addSource(crl.Amount__c); // added to CR amount to apply
			    			mapCRs.put(crl.Customer_Receipt__c, p);
			    		}
			    		else
			    			mapCRs.get(crl.Customer_Receipt__c).addSource(crl.Amount__c);
		    		}
	    			
	    		}
	    		
	    		else if(applyPayment.contains(crl.Type__c))
	    		{
	    			if(!mapCRs.containsKey(crl.Customer_Receipt__c))
		    		{
		    			PaymentFieldsWrapper p = new PaymentFieldsWrapper();
		    			p.addPayment(crl.Amount__c); // added to totalPayment
		    			mapCRs.put(crl.Customer_Receipt__c, p);
		    		}
		    		else
		    			mapCRs.get(crl.Customer_Receipt__c).addPayment(crl.Amount__c);
	    		}
	    		
	    	}
    		
    	}
    	if(!mapCRs.isEmpty())
    	{
    		
    		
    		for(ID CR_ID : mapCRs.keyset())
    		{
    			Customer_Receipt__c cr = triggerMap.get(CR_ID);
       			cr.Amount_To_Apply__c = mapCRs.get(CR_ID).amountToApply;
    			cr.Amount_UnApplied__c = mapCRs.get(CR_ID).amountToApply - mapCRs.get(CR_ID).totalPayment;
    			listCrs.add(cr);
    			system.debug('recalcualate completed cr='+ cr);
    		}
    		
    		
    	}
    	
    	return listCRs;
    	
    	
    }
	
	//OTC-65
	public static void onFinalize(){
		system.debug(logginglevel.error,'OnFinalize CR');
		if(trigger.isExecuting){
			if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
				List<Customer_Receipt__c> finalizedCustReceipts = new List<Customer_Receipt__c>();
				Map<Id, List<Customer_Receipt_Line__c>> refundClaimCustReceiptLines = new Map<Id, List<Customer_Receipt_Line__c>>();//KNDY-15033
				Set<Id> refundClaimIds = new Set<Id>();
				list<Customer_Invoice__c> CIsSumInvoice = new list<Customer_Invoice__c>();
				for(Customer_Receipt__c cr : (List<Customer_Receipt__c>)trigger.new){
					if(cr.Finalized__c && KSE.isFieldChanging('Finalized__c', cr, trigger.oldMap)){
						if(cr.has_Exceptions__c)
							throw new CustomerReceiptException(Label.Cant_Finalize_CR_Has_Exceptions);
						finalizedCustReceipts.add(cr);
					}		
				}
				List<Customer_Receipt_Line__c> finalizedCRLines = new List<Customer_Receipt_Line__c>();
				
				// KNDY-15028 Claim settled against Allowance Accrual CI will be closed
				set<String> claimCreditDebitTypes = new set<String> { PaymentService.TYPE_CREDIT_CLAIM, PaymentService.TYPE_DEBIT_CLAIM};
				
				map<Id,Claim__c> closeClaims = new map<Id,Claim__c>(); //AR-165 //KNDY-9835--> Convert from list to map to avoid duplicates!
				list<Claim_Line__c> claimLines = new list<Claim_Line__c>();//KNDY-7738
				if(finalizedCustReceipts.size() > 0){
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'Id','name','type__c','amount__c','customer__c','customer_invoice__c','Claim__c','Sold_To_Customer__c','Sales_Order__c','customer_receipt__c',
						'customer_receipt__r.finalized__c','customer_receipt__r.company__c','customer_receipt__r.currency__c','customer_receipt__r.transaction_date__c',
						'customer_receipt__r.Claim__c','customer_receipt__r.customer__c','customer_receipt__r.customer__r.top_parent_customer__c','customer_receipt__r.customer__r.recordType.developerName',
						'customer_Receipt__r.Type__c','Customer_Receipt__r.Date_Received__c'
					});
					soql.setWhereClause('Customer_Receipt__c IN :finalizedCustReceipts and Customer_Receipt__c not in :finalizedCRIds');
					for(Customer_Receipt_Line__c crL :Database.query(soql.getQuery())) {
						finalizedCRLines.add(crL);
						
						if (crl.Customer_Receipt__c != null && crl.Customer_Receipt__r.Type__c == 'Refund' && crl.Customer_Receipt__r.Claim__c != null){ //KNDY-15033
							refundClaimIds.add(crl.Customer_Receipt__r.Claim__c);
							if (refundClaimCustReceiptLines.containsKey(crl.Customer_Receipt__c)){
								refundClaimCustReceiptLines.get(crl.Customer_Receipt__c).add(crl);
							}
							else{
								refundClaimCustReceiptLines.put(crl.Customer_Receipt__c, new List<Customer_Receipt_Line__c>{crl});
							}
						}
						DateTime dateReceived = crl.Customer_Receipt__r.Date_Received__c;
						if(crL.type__c == PaymentService.TYPE_CLAIM_PAYMENT && crL.Claim__c != null && !closeClaims.containsKey(crl.Claim__c)) //KNDY-7738
						{
							system.debug(logginglevel.error,'inside on finalize'+ crl.type__C+ ' '+crl.ID);
							claimLines.add(new Claim_Line__c(Claim__c = crl.Claim__c, Total_Amount__c = crl.Amount__c));
							closeClaims.put(crl.Claim__c, new Claim__c(Id = crl.Claim__c, Status__c = ClaimService.STATUS_CLOSED, Settlement_Date__c = Date.newInstance(dateReceived.year(),dateReceived.month(),dateReceived.day()), Settlement_Method__c = ClaimService.SETTLE_CLAIM_AGAINST_CASH));
						}
						
						if(crl.Customer_Invoice__c != null )
							CIsSumInvoice.add(new Customer_Invoice__c(id = crl.Customer_Invoice__c));
						//AR-165
						if(claimCreditDebitTypes.contains(crl.Type__c) && crl.Claim__c != null && !closeClaims.containsKey(crl.Claim__c)) {//KNDY-9835
							closeClaims.put(crl.Claim__c, new Claim__c(Id = crl.Claim__c, Status__c = ClaimService.STATUS_CLOSED, Settlement_Date__c = Date.newInstance(dateReceived.year(),dateReceived.month(),dateReceived.day()), Settlement_Method__c = ClaimService.SETTLE_CREDIT_CONSUME));
						}	
					}
					
													
					map<Id,Customer_Receipt__c> mCustReceipt = new Map<Id, Customer_Receipt__c>((List<Customer_Receipt__c>)trigger.new);
					finalizedCRIds.addAll(mCustReceipt.keyset());
					Savepoint sp = Database.setSavepoint();
					list<Customer_Invoice__c> closeChargeBackCIs = new list<Customer_Invoice__c>();
					try{								
						ClaimService.CreateClaims(finalizedCRLines);// create deduction claims
						generateCreditsForLines(finalizedCRLines); //create overpayments
						if (refundClaimIds.size() > 0){ //KNDY-15033
							String errorMsg = ClaimService.settleRefundCreditClaims(refundClaimIds, refundClaimCustReceiptLines, claimLines, closeClaims);
							if (!String.isBlank(errorMsg)){
								database.rollback(sp);
								throw new CustomerReceiptException(errorMsg);
							}
						}
						
						if(!claimLines.isEmpty())
							DML.insertAsUser(claimLines); //insert lines for claims when applying against cash. 
							
						DML.updateAsUser(closeClaims.values()); //ar-165 //close claims wether against credit or against cash //KNDY-9835
						
						
						
    					//OTC-725 optimizing onfinlalize
    					system.debug('onFinalize CIsSumInvoice=='+CIsSumInvoice);    					
    					if(!CIsSumInvoice.isEmpty())
    					{
    						 CustomerInvoiceService.sumInvoicePayments(CIsSumInvoice);
    					}
    					
    				}catch(Exception ex){
			    		database.rollback(sp);
			    		throw ex;
			    	}
			    	
					
					
				}
			}
		}
	}
	
	public static void onUnfinalize(){
		if(trigger.isExecuting){
			if(trigger.isAfter && trigger.isUpdate){
				List<Customer_Receipt__c> unFinalizedCustReceipts = new List<Customer_Receipt__c>();
				set<ID> reOpenClaims = new set<ID>();
				map<Id, Customer_Invoice__c> updateCIBalances = new map<Id,Customer_Invoice__c>();
				map<Id,Id> mapCItoCRL = new map<Id,Id>();	
				set<String> PaymentTypes = new set<String>{PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED, PaymentService.TYPE_PAYMENT,PaymentService.TYPE_CREDIT_MEMO, PaymentService.TYPE_UNEARNED_DISCOUNT, PaymentService.TYPE_EARNED_DISCOUNT, PaymentService.TYPE_WRITEOFF,PaymentService.TYPE_WRITEOFF_CREDIT,
														   PaymentService.TYPE_DEBIT_MEMO, PaymentService.TYPE_OVERPAYMENT_CREDIT, PaymentService.TYPE_PREPAYMENT_CREDIT, PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, 
														   PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT, PaymentService.TYPE_REFUND_APPLIED_PAYMENT, PaymentService.TYPE_REFUND_UNAPPLIED_OVERPREPAYMENT, PaymentService.TYPE_REFUND_CREDIT,
														   PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL};

				for(Customer_Receipt__c cr : (List<Customer_Receipt__c>)trigger.new){
					if(!cr.Finalized__c && KSE.isFieldChanging('Finalized__c', cr, trigger.oldMap)){  
						unFinalizedCustReceipts.add(cr);
					}		
				}
				
				system.debug(logginglevel.error,'isCRUnfinalized: '+isCRUnfinalized); 
				if(unfinalizedCustReceipts.size() > 0 && !isCRUnfinalized){
					
					isCRUnfinalized =true; //WFR on CR that changes stat to OPEN refires Unfinalize method. So need to set a static boolean to ensure this method isnt called twice in the same transaction!
					
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'Id','name','type__c','amount__c','customer__c','Claim__c','Customer_Invoice__c','Historical__c','Sales_Order__c','customer_receipt__c',
						'customer_receipt__r.claim__c','customer_receipt__r.Type__c',
						'customer_receipt__r.finalized__c','customer_receipt__r.posting_date__c','customer_receipt__r.company__c','customer_receipt__r.currency__c',
						'customer_receipt__r.transaction_date__c','customer_receipt__r.customer__c','customer_receipt__r.customer__r.top_parent_customer__c',
						'customer_receipt__r.customer__r.recordType.developerName',
						//KNDY-13995
						//'customer_credit_memo__c','customer_credit_memo__r.Name','customer_credit_memo__r.transaction_date__c','customer_credit_memo__r.finalized_date__c','customer_credit_memo__r.Historical__c','customer_credit_memo__r.posting_date__c','customer_credit_memo__r.Status__c','customer_credit_memo__r.Void__c','customer_credit_memo__r.Void_Date__c','customer_credit_memo__r.Finalized__c',
						'customer_invoice__r.historical__c','customer_invoice__r.Status__c','customer_invoice__r.Posting_Date__c','customer_invoice__r.Finalized__c',
						'customer_invoice__r.Name','customer_invoice__r.Transaction_Date__c','customer_invoice__r.Finalized_Date__c','customer_invoice__r.Void__c',
						'customer_invoice__r.Void_Date__c'
					});
					soql.setWhereClause('Customer_Receipt__c IN :unFinalizedCustReceipts');
					List<Customer_Receipt_Line__c> unFinalizedCRLines = Database.query(soql.getQuery());
					
					//KNDY-10191 delete all BTMs tied to the CR.
					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					soql = new SOQLUtil('Bank_Transaction_Match__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'Id'
					});
					List<String> crIds = KSE.grepFieldFromList(unFinalizedCRLines, 'Customer_Receipt__c', true);
					soql.setWhereClause('Customer_Receipt__c in :crIds');
					list<Bank_Transaction_Match__c> lBTM2Delete = Database.query(soql.getQuery());
																	
					list<Customer_Invoice__c> newCredits = new list<Customer_Invoice__c>();														
					for(Customer_Receipt_Line__c crl : unFinalizedCRLines){
						system.debug('condition '+ crl.Type__c);
						system.debug((crl.Type__c == PaymentService.TYPE_CREDIT_CLAIM || crl.Type__c == PaymentService.TYPE_CREDIT_CLAIM) && crl.Claim__c != null);
						//KNDY-13995 replaced customer credit memo with customer invoice
						if((crl.Type__c == PaymentService.TYPE_OVERPAYMENT || crl.Type__c == PaymentService.TYPE_PREPAYMENT) && crl.Customer_Invoice__r != null) { //Additional Payments
							newCredits.add(new Customer_Invoice__c(Id = crl.Customer_Invoice__c, Status__c = crl.Customer_Invoice__r.Status__c,
														Name =  crl.Customer_Invoice__r.Name,
														Posting_Date__c = crl.Customer_Invoice__r.posting_date__c,
														Finalized__c = crl.Customer_Invoice__r.Finalized__c ,
														Transaction_Date__c = crl.Customer_Invoice__r.Transaction_Date__c,
														Finalized_Date__c = crl.Customer_Invoice__r.Finalized_Date__c,
														Void__c  = crl.Customer_Invoice__r.Void__c,
														Historical__c = crl.Customer_Invoice__r.Historical__c,
														Void_Date__c = crl.Customer_Invoice__r.Void_Date__c));
				
							mapCItoCRL.put(crl.Customer_Invoice__c,crl.Id);	
						}						
						
						//AR-165 //KNDY-7738
						else if((crl.Type__c == PaymentService.TYPE_CREDIT_CLAIM || crl.Type__c == PaymentService.TYPE_DEBIT_CLAIM || crl.Type__c == PaymentService.TYPE_CLAIM_PAYMENT) && crl.Claim__c != null)
							reOpenClaims.add(crl.Claim__c);
						else if(PaymentTypes.contains(crl.Type__c)) //OTC-727
						{
							if(crl.Customer_Invoice__c!= null)
								updateCIBalances.put(crl.Customer_Invoice__c, new Customer_Invoice__c(id = crl.Customer_Invoice__c));
							/*KNDY-13995 
							if(crl.Customer_Credit_Memo__c!= null)
								updateCIBalances.put(crl.Customer_Credit_Memo__c, new Customer_Invoice__c(id = crl.Customer_Credit_Memo__c));*/
						}
						
						if (crl.Customer_Receipt__r.Type__c == 'Refund' && crl.Customer_Receipt__r.Claim__c != null){ //KNDY-15255
							reOpenClaims.add(crl.Customer_Receipt__r.Claim__c);
						}
					}
					
					//map<id,Decimal> mSOToReceivedAmount = getMapPrePaymentReceived(unFinalizedCRLines);
					system.debug('inside CR unfinialize'+ reOpenClaims);
					Savepoint sp = Database.setSavepoint();
					try{
						
						/*
						CANCELLING OP/PP INVOICES
						*/
						cancelAdditionalInvoices(newCredits, mapCItoCRL);
						
						ClaimService.ReOpen(reOpenClaims);							
						ClaimService.cancelClaims(unFinalizedCRLines);// GEN DED + INvoice Ded
						
						if(!updateCIBalances.isEmpty())
							CustomerInvoiceService.sumInvoicePayments(updateCIBalances.values());
						if(!lBTM2Delete.isEmpty()){
							DML.deleteAsUser(lBTM2Delete);
						}
						
						soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
						soql.addFields(new set<string>{'Id'});
						soql.setWhereClause('Finalized__c = false and Status__c != \'Cancelled\' and Id = :unFinalizedCustReceipts');
						unFinalizedCustReceipts = Database.query(soql.getQuery());
						
						//unFinalizedCustReceipts = [Select Id from Customer_Receipt__c where Finalized__c = false and Status__c != 'Cancelled' and Id in :unFinalizedCustReceipts];
						if(!unFinalizedCustReceipts.isEmpty()) {
							for(Customer_Receipt__c cr : unFinalizedCustReceipts) {
								cr.Status__c = 'Open';
							}
							update unFinalizedCustReceipts;
						}
					}catch(Exception ex){
						database.rollback(sp);
						throw ex;
					}
				}
			}
		}
	}
	
	
	//AR-75 VOID CR
	public static void onVoid (list<Customer_Receipt__c> lCRs)
	{
		set<ID> reOpenClaims = new set<ID>();
		list<Customer_Invoice__c> updateCBCIs = new list<Customer_Invoice__c>();
		map<Id, Customer_Invoice__c> updateCIBalances = new map<Id,Customer_Invoice__c>();
		set<String> PaymentTypes = new set<String>{PaymentService.TYPE_ALLOWANCE_ACCRUAL_APPLIED, PaymentService.TYPE_PAYMENT,PaymentService.TYPE_CREDIT_MEMO, PaymentService.TYPE_UNEARNED_DISCOUNT, PaymentService.TYPE_EARNED_DISCOUNT, PaymentService.TYPE_WRITEOFF, PaymentService.TYPE_WRITEOFF_CREDIT,
												   PaymentService.TYPE_DEBIT_MEMO, PaymentService.TYPE_OVERPAYMENT_CREDIT, PaymentService.TYPE_PREPAYMENT_CREDIT,PaymentService.TYPE_REFUND_UNAPPLIED_PREPAYMENT, 
												   PaymentService.TYPE_REFUND_APPLIED_PREPAYMENT, PaymentService.TYPE_REFUND_APPLIED_PAYMENT, PaymentService.TYPE_REFUND_UNAPPLIED_OVERPREPAYMENT, PaymentService.TYPE_REFUND_CREDIT,
												   PaymentService.TYPE_REFUND_ALLOWANCE_ACCRUAL};

		map<Id,Id> mapCItoCRL = new map<Id,Id>();		

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Receipt_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','type__c','amount__c','customer__c','Claim__c','Customer_Invoice__c','Historical__c','Sales_Order__c','customer_receipt__c',
			'customer_receipt__r.claim__c','customer_receipt__r.Type__c',
			'customer_receipt__r.finalized__c','customer_receipt__r.posting_date__c','customer_receipt__r.company__c','customer_receipt__r.currency__c',
			'customer_receipt__r.transaction_date__c','customer_receipt__r.customer__c','customer_receipt__r.customer__r.top_parent_customer__c',
			'customer_receipt__r.customer__r.recordType.developerName','customer_Receipt__r.Void_Date__c',
			//KNDY-13995 Deprecating cutomer credit memo field, instead using customer invoice
			//'customer_credit_memo__c','customer_credit_memo__r.transaction_date__c','customer_credit_memo__r.finalized_date__c','customer_credit_memo__r.Historical__c','customer_credit_memo__r.posting_date__c','customer_credit_memo__r.Status__c','customer_credit_memo__r.Void__c','customer_credit_memo__r.Void_Date__c','customer_credit_memo__r.Finalized__c',
			'customer_invoice__r.historical__c','customer_invoice__r.Status__c','customer_invoice__r.Posting_Date__c','customer_invoice__r.Finalized__c',
			'customer_invoice__r.Transaction_Date__c','customer_invoice__r.Finalized_Date__c','customer_invoice__r.Void__c','customer_invoice__r.Void_Date__c'
		});
		soql.setWhereClause('Customer_Receipt__c IN :lCRs');
		List<Customer_Receipt_Line__c> lCRLs = Database.query(soql.getQuery());

		//KNDY-10191 delete all BTMs tied to the CR.
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Bank_Transaction_Match__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		List<String> crIds = KSE.grepFieldFromList(lCRLs, 'Customer_Receipt__c', true);
		soql.setWhereClause('Customer_Receipt__c in :crIds');
		list<Bank_Transaction_Match__c> lBTM2Delete = Database.query(soql.getQuery());
					
		list<Customer_Invoice__c> newCredits = new list<Customer_Invoice__c>();														
		for(Customer_Receipt_Line__c crl : lCRLs)
		{
			if((crl.Type__c == PaymentService.TYPE_OVERPAYMENT || crl.Type__c == PaymentService.TYPE_PREPAYMENT) && crl.Customer_Invoice__r != null)
			{ //Additional Payments
				//KNDY-13995 
				newCredits.add(new Customer_Invoice__c(Id = crl.Customer_Invoice__c, Status__c = crl.Customer_Invoice__r.Status__c, 
														Posting_Date__c = crl.Customer_Invoice__r.posting_date__c,
														Finalized__c = crl.Customer_Invoice__r.Finalized__c ,
														Transaction_Date__c = crl.Customer_Invoice__r.Transaction_Date__c,
														Finalized_Date__c = crl.Customer_Invoice__r.Finalized_Date__c,
														Void__c  = crl.Customer_Invoice__r.Void__c,
														Historical__c = crl.Customer_Invoice__r.Historical__c,
														Void_Date__c = crl.Customer_Receipt__r.Void_Date__c));
				
				mapCItoCRL.put(crl.Customer_Invoice__c,crl.Id);			
			}
			
			else if((crl.Type__c == PaymentService.TYPE_CREDIT_CLAIM || crl.Type__c == PaymentService.TYPE_DEBIT_CLAIM || crl.Type__c == PaymentService.TYPE_CLAIM_PAYMENT) && crl.Claim__c != null)
							reOpenClaims.add(crl.Claim__c);
						
			else if(PaymentTypes.contains(crl.Type__c)) //OTC-727
			{
				if(crl.Customer_Invoice__c!= null)
					updateCIBalances.put(crl.Customer_Invoice__c, new Customer_Invoice__c(id = crl.Customer_Invoice__c));
				/*KNDY-13995 - NO MORE NEEDED ABOVE Condition will be suffice
				if(crl.Customer_Credit_Memo__c!= null)
					updateCIBalances.put(crl.Customer_Credit_Memo__c, new Customer_Invoice__c(id = crl.Customer_Credit_Memo__c));*/
			}
			
			if (crl.Customer_Receipt__r.Type__c == 'Refund' && crl.Customer_Receipt__r.Claim__c != null){ //KNDY-15255
				reOpenClaims.add(crl.Customer_Receipt__r.Claim__c);
			}
		}
		
		
		Savepoint sp = Database.setSavepoint();
		try
		{
			//1 UPDATE BALANCES ON CIS
			if(!updateCIBalances.isEmpty())
				CustomerInvoiceService.sumInvoicePayments(updateCIBalances.values());
			
			
			//3 VOID CHARGEBACK AND ADDITIONAL INVOICES
			
			voidAdditionalInvoices(newCredits, mapCItoCRL);
			
				
			//5 REOPEN CLAIMS
			ClaimService.reOpen(reOpenClaims);
			
			//6 CANCEL DEDUCTION CLAIMS
			ClaimService.cancelClaims(lCRLs);
			
			if(!lBTM2Delete.isEmpty())
			{
				DML.deleteAsUser(lBTM2Delete);
			}
			
		}catch(Exception ex)
		{
			system.debug('CR service exception: '+ex.getMessage());
			database.rollback(sp);
			throw ex;
		}
		
		
		
																		
	}
	
	//AR-93
	public static void voidAdditionalInvoices(list<Customer_Invoice__c> newCredits, map<Id,Id> mapCItoCRL)
	{
		VoidCancelService vcS  = new CustomerInvoiceVoidCancelService(newCredits);
		Map<Id, VoidCancelService.VoidCancelDetail> vcDetails = vcS.getVoidCancelDetails();
		list<String> messages = new list<String>();
		for(VoidCancelService.VoidCancelDetail detail : vcDetails.values())
		{
			if(!detail.isVoidable)
			{
				messages.addAll(detail.voidMessages);
			}
		}
		if(!messages.isEmpty())
		{
			system.debug('Void messages: '+messages);
			throw new CustomerReceiptException(String.join(messages,','));
		}
		else
		{
			messages = new list<String>();
			for(VoidCancelService.VoidCancelResponse response : vcS.voidSourceDocuments(newCredits).values())
			{
				if(!response.success)
				{
					messages.addAll(response.messages);
					
				}
			}
			
			if(!messages.isEmpty())
				throw new CustomerReceiptException(String.join(messages,','));
			else
			{
				list<Customer_Receipt_Line__c> lCRLs = new list<Customer_Receipt_Line__c>();
				for(Customer_Invoice__c ci : newCredits){
					//if(ci.Invoice_Type__c != 'Chargeback')
					//KNDY-13995
						lCRLs.add(new Customer_Receipt_Line__c(Id = mapCItoCRL.get(ci.Id),  Customer_invoice__c = null));
				}
				if(!lCRLs.isEmpty())
					DML.updateAsUser(lCRLs);
			}
		}
	}
	
	//AR-93
	public static void cancelAdditionalInvoices(list<Customer_Invoice__c> newCredits, map<Id,ID> mapCItoCRL)
	{
		system.debug('To Cancel CIs : '+newCredits);
		VoidCancelService vcS  = new CustomerInvoiceVoidCancelService(newCredits);
		Map<Id, VoidCancelService.VoidCancelDetail> vcDetails = vcS.getVoidCancelDetails();
		list<String> messages = new list<String>();
		for(VoidCancelService.VoidCancelDetail detail : vcDetails.values())
		{
			if(!detail.isCancellable)
			{
				messages.addAll(detail.cancelMessages);
			}
		}
		if(!messages.isEmpty())
		{
			throw new CustomerReceiptException(String.join(messages,','));
		}
		else
		{
			messages = new list<String>();
			for(VoidCancelService.VoidCancelResponse response : vcS.cancelSourceDocuments(newCredits).values())
			{
				if(!response.success)
				{
					messages.addAll(response.messages);
				}
			}
			
			if(!messages.isEmpty())
				throw new CustomerReceiptException(String.join(messages,','));
			else
			{
				list<Customer_Receipt_Line__c> lCRLs = new list<Customer_Receipt_Line__c>();
				for(Customer_Invoice__c ci : newCredits)
					lCRLs.add(new Customer_Receipt_Line__c(Id = mapCItoCRL.get(ci.Id), Customer_Invoice__c = null)); //KNDY-13995
				
				system.debug('lCRLs: '+lCRLs);
				if(!lCRLs.isEmpty())
					DML.updateAsUser(lCRLs);
			}
		}
	}
	
	public static List<Customer_Invoice__c> generateCreditMemoInvoices(Set<Id> prepaymentReceiptIds){
		List<Customer_Invoice__c> creditMemos = new List<Customer_Invoice__c>();
		List<Customer_Invoice_Line__c> sils = new List<Customer_Invoice_Line__c>();
		string custInvName = SchemaUtil.getInstance().getLocalNameFromObject(new Customer_Invoice__c());
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','company__c','amount_unapplied__c','customer__c','Type__c'
		});
		soql.setWhereClause('Id IN :prepaymentReceiptIds');
		Map<Id, Customer_Receipt__c> mPrepaymentReceipts = new Map<Id, Customer_Receipt__c>((List<Customer_Receipt__c>)Database.query(soql.getQuery()));
														
		for(Customer_Receipt__c cr : mPrepaymentReceipts.values()){
			if(cr.Type__c == TYPE_PREPAYMENT){
				Customer_Invoice__c iCM = new Customer_Invoice__c();
				iCM.Invoice_Type__c = CustomerInvoiceService.CM_PREPAYMENT;
				iCM.Date_Invoiced__c = system.now();
				iCM.Customer_Receipt__c = cr.Id;
				iCM.Company__c = cr.Company__c;
				iCM.Bill_To_Customer__c = cr.Customer__c;
				iCM.finalized__c = true;
				creditMemos.add(iCM);
			}
		}
		
		DML.insertAsUser(creditMemos);
		
		for(Customer_Invoice__c cm : creditMemos){
			Customer_Invoice_Line__c iSIL = new Customer_Invoice_Line__c();
			iSIL.Company__c = cm.company__c;
			iSIL.Quantity_Shipped__c = -1;
			iSIL.Unit_Price__c = mPrepaymentReceipts.get(cm.customer_Receipt__c).amount_unapplied__c;
			iSIL.Customer_Invoice__c = cm.Id;
			sils.add(iSIL);
		}
		
		DML.insertAsUser(sils);
		
		return creditMemos;
	}
	
	
	
	/**
    *	Description: OTC-65 This method is called only when a Customer Receipt is finalized
    */
    private static void generateCreditsForLines(List<Customer_Receipt_Line__c> customerReceiptLines){
		
		Map<Id, Customer_Invoice__c> mCredits = new Map<Id, Customer_Invoice__c>();
		Map<Id, Customer_Invoice_Line__c> mCreditLines = new Map<Id, Customer_Invoice_Line__c>();
		Map<Id, Customer_Receipt_Line__c> mReceiptLines = new Map<Id, Customer_Receipt_Line__c>();
			
		for(Customer_Receipt_Line__c crl : customerReceiptLines){
			
			if(crl.Type__c == PaymentService.TYPE_PREPAYMENT 
					|| crl.Type__c == PaymentService.TYPE_OVERPAYMENT){		
						
				Customer_Invoice__c iCI = new Customer_Invoice__c();
				iCI.company__c = crl.customer_receipt__r.company__c;
				iCI.transaction_date__c = crl.customer_receipt__r.transaction_date__c;
				iCI.date_invoiced__c = crl.customer_receipt__r.transaction_date__c;
				iCI.currency__c = crl.customer_receipt__r.currency__c;
				iCI.invoice_type__c = crl.Type__c == PaymentService.TYPE_PREPAYMENT ? CustomerInvoiceService.CM_PREPAYMENT : CustomerInvoiceService.CM_OVERPAYMENT;
				iCI.customer_receipt__c = crl.customer_receipt__c; //OTC-565
				iCI.Customer_Receipt_Line__c = crl.Id; //AR-92
				iCI.Sales_Order__c = crl.Type__c == PaymentService.TYPE_PREPAYMENT ? crl.Sales_Order__c : null; //AR_PREPAYMENTS
				
				//Assign Bill To OTC-582
				if(crl.customer__c != null){
					iCI.Bill_to_Customer__c = crl.customer__c;
					iCI.Sold_To_Customer__c = crl.Sold_To_Customer__c;
				}
				// OTC-290 Allow null Bill to Customer
				/*else{
					iCI.Bill_to_Customer__c = crl.customer_receipt__r.customer__c;
				}
				*/
				
				//Assign Customer
				if(crl.customer_receipt__r.customer__r.recordType.DeveloperName == 'Bill_To'){
					iCI.Customer__c = crl.customer_receipt__r.customer__r.top_parent_customer__c;
					iCI.Bill_To_Customer__c = crl.Customer_Receipt__r.Customer__c; //KNDY-19006
				}else{
					iCI.Customer__c = crl.customer_receipt__r.customer__c;
				}
				
				
				Customer_Invoice_Line__c iCIL = new Customer_Invoice_Line__c();
				iCIL.subtransaction_type__c = crl.Type__c == PaymentService.TYPE_PREPAYMENT ? CustomerInvoiceService.CM_PREPAYMENT : CustomerInvoiceService.CM_OVERPAYMENT;					
				iCIL.quantity_shipped__c = -1;
				iCIL.unit_price__c = crl.amount__c;
				
				mCredits.put(crl.Id, iCI);
				mCreditLines.put(crl.Id, iCIL);
				mReceiptLines.put(crl.Id, crl);
			}
			
		}
		try
		{
		DML.insertAsUser(mCredits.values());
		
		for(Id crlId : mCreditLines.keySet()){
			mCreditLines.get(crlId).Customer_Invoice__c = mCredits.get(crlId).Id;
			mCredits.get(crlId).Finalized__c = true;
		}
		
		DML.insertAsUser(mCreditLines.values());
		DML.updateAsUser(mCredits.values());
		
		for(Customer_Receipt_Line__c crl : mReceiptLines.values()){
			if((crl.Type__c == PaymentService.TYPE_PREPAYMENT || crl.Type__c == PaymentService.TYPE_OVERPAYMENT)
					&& mCredits.containsKey(crl.Id)){
				crl.Customer_Invoice__c = mCredits.get(crl.Id).Id; //KNDY-13995
			}
		}
			DML.updateAsUser(mReceiptLines.values());
		}catch(Exception ex)
		{
			throw ex;
		}
														
	}
	
	public static void populateAmountInWords(){
		if(trigger.isBefore){
			list<Customer_Receipt__c> lstCRToUpdate = new list<Customer_Receipt__c>();
			if(trigger.isInsert){
				for(Customer_Receipt__c cr : (list<Customer_Receipt__c>)trigger.new){
					if(cr.Amount_Received__c != null && cr.Finalized__c && cr.Type__c != null &&
					   cr.Type__c.equalsIgnoreCase('Refund')){
						lstCRToUpdate.add(cr);
					}
				}
			}else if(trigger.isUpdate){
				for(Customer_Receipt__c cr : (list<Customer_Receipt__c>)trigger.new){
					if(cr.Amount_Received__c != null && cr.Finalized__c && cr.Type__c != null &&
					   cr.Type__c.equalsIgnoreCase('Refund') &&
					   KSE.isFieldChanging('Finalized__c',cr,(map<Id,Customer_Receipt__c>)trigger.oldMap)){
						lstCRToUpdate.add(cr);
					}
				}
			}
			if(!lstCRToUpdate.isEmpty()){
				populateAmountInWords(lstCRToUpdate);
			}
		}
	}
	
	public static void populateAmountInWords(list<Customer_Receipt__c> lstCR){
		if(!lstCR.isEmpty()){
			for(Customer_Receipt__c cr: lstCR){
				if(cr.Amount_Received__c != null){
					decimal amountReceived = cr.Amount_Received__c<0?-1*cr.Amount_Received__c:
											 cr.Amount_Received__c;
					cr.Amount_In_Words__c = NumberToWordUtil.numberToWordsWithDecimal(amountReceived);
				}
			}
		}
	}
}