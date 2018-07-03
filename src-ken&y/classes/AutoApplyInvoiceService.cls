public with sharing class AutoApplyInvoiceService {
	
	public class AutoApplyInvoiceServiceException extends Exception{}
	
	//OUTER WRAPPER STORES STD INVOICE AND MAP OF SALES ORDER TIED TO IT
	private class standardInvoiceWrapper {
		Customer_Invoice__c stdCI;
		map<Id,OrderPrepaymentWrapper> mapSO2Prepayments;
		standardInvoiceWrapper(Customer_Invoice__c stdCI) {
			this.stdCI = stdCI;
			mapSO2Prepayments = new map<Id, OrderPrepaymentWrapper>();
		}
	}
	
	//INNER WRAPPER: HAS SO ID AND LIST OF OPEN PREPAYMENTS TIED TO IT. THE CLASS ALSO STORES HOW MUCH PREPAYMENT AMOUNT SHOULD BE ASSOCIATED WITH THE SO
	private class OrderPrepaymentWrapper {
		Id salesOrderId;
		list<Customer_Invoice__c> prepayments;
		Decimal amountToApply;
		OrderPrepaymentWrapper(ID salesOrderId, Decimal amountToApply) {
			this.salesOrderId = salesOrderId;
			this.prepayments = new list<Customer_Invoice__c>();
			this.amountToApply = amountToApply;
		}
		
	}
	
	private static map<Id,Customer_Invoice__c> getInvoices(set<Id> invoiceIds) {
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Bill_To_Customer__c','Company__c','Balance__c','Currency__c'
		});
		soql.setWhereClause('id in : invoiceIds');
		return new map<Id,Customer_Invoice__c>((List<Customer_Invoice__c>)Database.query(soql.getQuery()));
	}
	
	public static void autoApplyPrepayments(map<Id,Customer_Invoice__c> mCIs) { //MAP SHOULD HAVE ALL FIELDS REQUIRED TO CREATE CR (CUSTOMER, CURRENCY, COMPANY,...)
		
		map<Id,Customer_Receipt__c> mCRs = new map<id,Customer_Receipt__c>();
		map<Id,list<Customer_Receipt_Line__c>> mCRLs = new map<Id,list<Customer_Receipt_Line__c>>();
		map<Id,standardInvoiceWrapper> stdInvoicePrepayments = new map<Id,standardInvoiceWrapper>();
		set<Id> SOIds = new set<Id>();
		
		//REQUERY TO GRAB ALL RELEVANT FIELDS FOR CREATING RECEIPTS
		mCIs = getInvoices(mCIs.keySet());

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Customer_Invoice_Line__c', true); //enforceFLS=true, running in user mode.
		soql.addFields(new set<string>{
			'Customer_Invoice__r.Balance__c','Sales_Order_Line__r.Sales_Order__c'
		});
		Set<Id> mCIids = mCIs.keySet();
		soql.setWhereClause(
			'Customer_Invoice__c in :mCIids ' +
			'and Sales_Order_Line__c != null ' +
			'and Customer_Invoice__r.Has_Exceptions__c = false ' +
			'and Customer_Invoice__r.Balance__c > 0 ' +
			'and Customer_Invoice__r.Status__c = \'Open\' ' +
			'and Customer_Invoice__r.Finalized__c = true'
		);
		
		//GETS US CI AND TOTAL OF LINES GROUPED BY SO
		for(Customer_Invoice_Line__c cil : Database.query(soql.getQuery())) {
				
				Decimal orderTotal = (Decimal) cil.Customer_Invoice__r.Balance__c;
				
				if(orderTotal == null || orderTotal == 0){
					continue;
				}
				
				Id invoiceId = cil.Customer_Invoice__c;
				id orderId = cil.Sales_Order_Line__r.Sales_Order__c;
				
				StandardInvoiceWrapper stdCIWrapper;
				
				if(!stdInvoicePrepayments.containsKey(invoiceId)) {
					stdCIWrapper =  new StandardInvoiceWrapper(mCIs.get(invoiceId));
					stdCIWrapper.mapSO2Prepayments = new map<Id,OrderPrepaymentWrapper>(); 
				}	
				else{
					stdCIWrapper = stdInvoicePrepayments.get(invoiceId);
				}
				
				map<Id, OrderPrepaymentWrapper> mPrepayments = stdCIWrapper.mapSO2Prepayments;
				mPrepayments.put(orderId, new OrderPrepaymentWrapper(orderId, orderTotal));
				
				stdInvoicePrepayments.put(invoiceId,stdCIWrapper);
				SOIds.add(orderId);
		}
		

		system.debug(logginglevel.info,'stdInvoicePrepayments '+stdInvoicePrepayments);
		system.debug(logginglevel.info,'mCIs '+mCIs);
		if(!stdInvoicePrepayments.isEmpty()) {
		map<Id, list<Customer_Invoice__c>> mOrderPrepayments = new map<Id, list<Customer_Invoice__c>>();
		//BUILDING OUR MAP SO.Id -->LIST<CI> PREPAYMENTS
		for(Customer_Invoice__c ci  : [select id, Balance__c, Date_Invoiced__c, Sales_Order__c from Customer_Invoice__c where Invoice_Type__c = :PaymentService.TYPE_PREPAYMENT and Status__c = 'Open' and Balance__c < 0 
									   and Sales_Order__c in :SOIds order By Date_Invoiced__c ASC]) {
			system.debug(logginglevel.info,'ci '+ci);
			if(!mOrderPrepayments.containsKey(ci.Sales_Order__c))
				mOrderPrepayments.put(ci.Sales_Order__c, new list<Customer_Invoice__c>());
		 	
		 	list<Customer_Invoice__c> lCI = mOrderPrepayments.get(ci.Sales_Order__c);
		 	lCI.add(ci);
		 	mOrderPrepayments.put(ci.Sales_Order__c, lCI);
			
		}
		system.debug(logginglevel.info,'mOrderPrepayments '+ mOrderPrepayments);
		//Get Rid of keys with empty values
		for(Id orderId : mOrderPrepayments.keySet()) {
			if(mOrderPrepayments.get(orderID).isEmpty())
				mOrderPrepayments.remove(orderId);
		}
		
		for(standardInvoiceWrapper stdCIWrapper : stdInvoicePrepayments.values()) {
			for(Id orderId : stdCIWrapper.mapSO2Prepayments.keySet()) {
				
				if(mOrderPrepayments.get(orderId) == null)
					stdCIWrapper.mapSO2Prepayments.remove(orderId); //IF NO PREPAYMENTS THEN REMOVE IT FROM OUTERR WRAPPER. 
				else {
					stdCIWrapper.mapSO2Prepayments.get(orderId).prepayments = mOrderPrepayments.get(orderId);
				}
				
			}
		}
		
		//Need to track in memory balance of prepayments after it is associated with std invoice
		map<id, Decimal> mPrepaymentBalance = new map<Id,Decimal>();
		
		for(Id invoiceId : mCIs.keySet()) {
			system.debug(logginglevel.info,'hello invoiceId '+invoiceId);
			if(stdInvoicePrepayments.get(invoiceId) != null) {//KNDY-10846 need to consider CIs created that have 0 balance (because of 100% discount). these CIs would not be in the prepaymentWrapper but in the main MCIs map
				list<Customer_Receipt_Line__c> lCRLs = new list<Customer_Receipt_Line__c>();
			
				Customer_Invoice__c stdCI = stdInvoicePrepayments.get(invoiceId).stdCI;
				system.debug(logginglevel.info,'stdCI '+stdCI);
				Decimal invoiceBalance = stdCI.Balance__c;
				system.debug(logginglevel.info,'invoiceBalance '+invoiceBalance);
				for(Id orderId : stdInvoicePrepayments.get(invoiceId).mapSO2Prepayments.keySet()) {
					 OrderPrepaymentWrapper orderWrapper = stdInvoicePrepayments.get(invoiceId).mapSO2Prepayments.get(orderId);
					 Decimal amountPerOrder = orderWrapper.amountToApply;
					 if(invoiceBalance == 0)
					 	break;//NO NEED TO GO THROUGH PREPAYMENTS AS CANT APPLY ANYTHING FURTHER;
					 		
					for(Customer_Invoice__c prepayment : orderWrapper.prepayments) {
						system.debug(logginglevel.info,'prepayment '+prepayment);
						if(!mPrepaymentBalance.containsKey(prepayment.Id)) 
							mPrepaymentBalance.put(prepayment.Id, Math.abs(prepayment.Balance__c));
						
						Decimal prepaymentBalance = mPrepaymentBalance.get(prepayment.Id);
						system.debug(logginglevel.info,'prepaymentBalance '+prepaymentBalance);
						if(prepaymentBalance > 0 && amountPerOrder > 0) {
							Customer_Receipt_Line__c crl = new Customer_Receipt_Line__c();
							crl.Type__c = PaymentService.TYPE_PREPAYMENT_CREDIT;
							crl.Customer_Invoice__c = prepayment.Id;//KNDY-13995
							if(amountPerOrder <= prepaymentBalance) {
								crl.Amount__c = amountPerOrder;
								invoiceBalance -= amountPerOrder;
								mPrepaymentBalance.put(prepayment.Id, prepaymentBalance - amountPerOrder);
								amountPerOrder = 0;
							}else {
								crl.Amount__c = prepaymentBalance;
								invoiceBalance -= prepaymentBalance;
								amountPerOrder -= prepaymentBalance;
								mPrepaymentBalance.put(prepayment.Id, 0);
							}
							lCRLs.add(crl);
						
						}
					}
				}
			
			//ADD DATA TO OUR DML MAP
			if(!lCRLs.isEmpty()) {
				//CREATE ONE LINE AS PAYMENT AGAINST STD INVOICE
				lCRLs.add(new Customer_Receipt_Line__c(Amount__c = invoiceBalance == 0 ? stdCI.Balance__c : (stdCI.Balance__c - invoiceBalance) , Type__c = PaymentService.TYPE_PAYMENT, Customer_Invoice__c = stdCI.Id));
				mCRLs.put(invoiceID, lCRLs);
				if(!(mCRLs.get(invoiceId).IsEmpty())) {
					mCRs.put(invoiceId, new Customer_Receipt__c(Type__c = CustomerReceiptService.TYPE_RECEIPT, Company__c = stdCI.Company__c, Transaction_Date__c = system.now(), Customer__c = stdCI.Bill_To_Customer__c, 
															    Currency__c = stdCI.Currency__c, Date_Received__c = system.now()));
				}
					system.debug(logginglevel.info,'mCRs '+mCRs);
					system.debug(logginglevel.info,'mCRLs '+mCRLs);
				}
				
				system.debug('mCRs '+mCRs);
				system.debug('mCRLs '+mCRLs);
			}
		}// END OF OUTERMOST LOOP
		
		Savepoint sp = Database.setSavepoint();
		try {
			if(!mCRs.isEmpty()) {
				DML.insertAsUser(mCRs.values());
				for(Id ciId : mCRLs.keyset()) {
					for(Customer_Receipt_Line__c crl : mCRLs.get(ciId))
							crl.Customer_Receipt__c = mCRs.get(ciId).Id;
				}
				DML.insertAsUser(KSE.grepListFromMap(mCRLs, null));
				//FINALIZE THE CRs
				for(Customer_Receipt__c cr : mCRs.values()) {
					cr.Finalized__c =true;
					cr.Finalized_Date__c = system.now();
				}
				DML.updateAsUser(mCRs.values());
			}
			
		}catch(Exception ex) {
			system.debug(logginglevel.info,'ex autoapply prepayment '+ex.getMessage() +' '+ex.getStackTraceString());
			throw ex;
		}
			
		}
		
		
	}
}