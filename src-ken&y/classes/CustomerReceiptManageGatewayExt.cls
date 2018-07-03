public with sharing class CustomerReceiptManageGatewayExt {
    
    Apexpages.StandardController con {get;set;}
    public string trxnStatus {get;set;}
    public string trxnType {get;set;}
    public boolean isRefundable {get;private set;}
    public decimal amountToRefund {get;set;}
    public Customer_Receipt__c cr {get; private set;}
    public CustomerReceiptManageGatewayExt(Apexpages.StandardController controller){
        this.con = controller;
        isRefundable = false;
        updateTransactionDetails();
    }
    
    public void updateTransactionDetails(){
        try{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Payment_Method_3__c','Transaction_ID__c', 'Amount_Received__c'
			});
			Id recordId = con.getId();
			soql.setWhereClause('Id = :recordId');
			
			String cReceiptWhereClause = ' Status__c = \'Closed\' and Finalized__c = true';
			SOQLUtil.ChildRelationship customerReceiptSubQuery = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipts__r');
			customerReceiptSubQuery.addFields(new Set<String>{'Id', 'Name', 'Amount_Received__c'});
			customerReceiptSubQuery.setWhereClause(cReceiptWhereClause);
			soql.addChildRelationship(customerReceiptSubQuery);

			Customer_Receipt__c cr = Database.query(soql.getQuery());

            amountToRefund = cr.Amount_Received__c; //KNDY-12536 KNDY-12895
            
            Decimal amountAvailableToRefund = cr.Amount_Received__c;
           // system.assert(1 != 1, '>>>cr.Customer_Receipts__r: ' + cr.Customer_Receipts__r);
            
            // Deduct the amount that has already been refunded
            for(Customer_Receipt__c refunded : cr.Customer_Receipts__r){
               amountAvailableToRefund  += refunded.Amount_Received__c;
            }
            // only payments that was made via authorize.net should be refundable
            if (cr.Transaction_ID__c == null) { //KNDY-12536 KNDY-12895
                isRefundable = false; 
                ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,'Cannot refund this CR as it does not have a Transaction Id'));  
                return;
            }
            PaymentHandler ph = new PaymentHandler();
            PaymentHandler.TransactionDetail td = ph.getTransaction(cr.Transaction_ID__c);
            trxnStatus = mStatuses.get(td.transactionStatus);
            trxnType = 'Auth/Capture';
            system.debug(td.transactionStatus);
            if(amountAvailableToRefund <= 0) {
	          list<String> refundedCRs = new list<String>();
	          for(Customer_Receipt__c refunded : cr.Customer_Receipts__r) 
	          	  refundedCRs.add(refunded.Name + ': has refunded '+ (-1) * refunded.Amount_Received__c);
	          
	          isRefundable = false;	
	          ApexPages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,'Cannot refund this transaction as the enitre amount has been already refunded:'));  
	          Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, String.join(refundedCRs,',')));
	          return;
            } 
            if(td.transactionStatus == 'capturedPendingSettlement'){
                isRefundable = false;
            }else if(td.transactionStatus == 'settledSuccessfully'){
                isRefundable = true;
            }else{
                isRefundable = false;
            }
            system.debug('isRefundable: ' + isRefundable);
            if(!isRefundable)
            	Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Cannot refund this transaction as it is not yet settled with the gateway. Please go through the void/cancel process. ')); 
        }catch(Exception ex){
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
        }
    }
    
    public void validateRefundAmount() {
    	if(isRefundable) {
    		try{
    			system.debug('hello amountToRefund '+amountToRefund);
    			
    			SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Payment_Method_3__c','Transaction_ID__c', 'Amount_Received__c'
			});
			Id recordId = con.getId();
			soql.setWhereClause('Id = :recordId');
			
			String cReceiptWhereClause = ' Status__c = \'Closed\' and Finalized__c = true';
			SOQLUtil.ChildRelationship customerReceiptSubQuery = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipts__r');
			customerReceiptSubQuery.addFields(new Set<String>{'Id', 'Name', 'Amount_Received__c'});
			customerReceiptSubQuery.setWhereClause(cReceiptWhereClause);
			soql.addChildRelationship(customerReceiptSubQuery);
			Customer_Receipt__c cr = Database.query(soql.getQuery());

              Decimal amountAvailableToRefund = cr.Amount_Received__c;
              for(Customer_Receipt__c refunded : cr.Customer_Receipts__r) 
                  amountAvailableToRefund  += refunded.Amount_Received__c;                  
              
              if( amountToRefund > cr.Amount_Received__c) {
              	  Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Cannot refund an amount higher than the amount received on orginal transaction ' + cr.Amount_Received__c)); // KNDY-12536
              }
              if( amountToRefund > amountAvailableToRefund) {
              	Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Cannot refund an amount higher than amount available to refund '+ amountAvailableToRefund)); // KNDY-12536
              }
              else {
              	refundPayment(amountToRefund);
              }
    		}catch(Exception ex) {
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
    		}                         
    	}
    }
    
    /*public void cancelPayment(){
        if(isCancellable){
            try{
               Customer_Receipt__c cr = [SELECT Id, Payment_Method_3__c, Transaction_ID__c
                                     FROM Customer_Receipt__c
                                     WHERE Id = :con.getId()];
                PaymentHandler ph = new PaymentHandler();
                Boolean isCancelled = ph.voidTransaction(cr.Id, cr.Transaction_ID__c);
                if(isCancelled){
                    trxnStatus = 'Voided';
                    isRefundable = false;
                    Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'Transaction successfully cancelled')); 
                }else{
                    Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Unable to cancel transaction')); 
                }
                //updateTransactionDetails();
            }catch(Exception ex){
                system.debug('EXCEPTION: ' +ex.getMessage() + ' ' + ex.getStackTraceString());
               Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, ex.getMessage())); 
            }
        }
    }*/
    public void refundPayment(Decimal amountToRefund){
        if(isRefundable){
            try{
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil            	
				SOQLUtil soql = new SOQLUtil('Customer_Receipt__c');
				soql.addFields(new set<string>{'Id','Payment_Method_3__c','Transaction_ID__c', 'Company__r.Credit_Card_Bank_Account__c'});
				Id crId = con.getId();
				soql.setWhereClause('Id =: crId');
            	Customer_Receipt__c cr = ((List<Customer_Receipt__c>)Database.query(soql.getQuery()))[0];

                PaymentHandler ph = new PaymentHandler();
                //system.assert(1 != 1, '>>> calling ph.refundTransaction');
                if(cr.Company__r.Credit_Card_Bank_Account__c == null) {
                   Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, 'Please populate the Credit Card Bank Account lookup on the company.'));
                   isRefundable = false;
                   return;
                }
                PaymentHandler.PaymentResponse pResponse = ph.refundTransaction(cr.Payment_Method_3__c, cr.Transaction_ID__c, cr.Id, amountToRefund, null);
                if(pResponse.isSuccess != null){
                    trxnStatus = 'Refund Pending Settlement';

					//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
					Id refundCustReceiptId = pResponse.customerReceiptId;
					soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
					soql.addFields(new set<string>{
						'Id','name'
					});
					soql.setWhereClause('Id = :refundCustReceiptId');
					Customer_Receipt__c refund = Database.query(soql.getQuery());

                    isRefundable = false;
                    Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.CONFIRM, pResponse.response));
                    Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'Transaction successfully refunded with Customer Receipt ' + refund.Name)); 
                }else{
                    Apexpages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR, pResponse.response));
                }
                //updateTransactionDetails();
            }catch(Exception ex){
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                Apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
            }
        }
    }
    
    private map<string, string> mStatuses = new map<string, string>{
        
        'authorizedPendingCapture' => 'Authorize Pending Capture',
        'capturedPendingSettlement' => 'Captured Pending Settlement',
        'communicationError' => 'Communication Error',
        'refundSettledSuccessfully' => 'Refund Settled Successfully',
        'refundPendingSettlement' => 'Refund Pending Settlement',
        'approvedReview' => 'Approved Review',
        'declined' => 'Declined',
        'couldNotVoid' => 'Could Not Void',
        'expired' => 'Expired',
        'generalError' => 'General Error',
        'failedReview' => 'Failed Review',
        'settledSuccessfully' => 'Settled Successfully',
        'settlementError' => 'Settlement Error',
        'underReview' => 'Under Review',
        'voided' => 'Voided',
        'FDSPendingReview' => 'FDS Pending Review',
        'FDSAuthorizedPendingReview' => 'FDS Authorized Pending Review',
        'returnedItem' => 'Returned Item'
    };
    
}