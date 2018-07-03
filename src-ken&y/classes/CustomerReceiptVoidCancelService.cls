public with sharing class CustomerReceiptVoidCancelService extends VoidCancelService{
	
	public list<Customer_Receipt__c> lCRs;
	public boolean calledFromUI;
	public CustomerReceiptVoidCancelService(list<Customer_Receipt__c> sObjects)
	{
		super(sObjects);
		lCRs = new list<Customer_Receipt__c>();
		calledFromUI = false;
	}
	
	public class CustomerReceiptVoidCancelServiceException extends Exception{}
	
    public CustomerReceiptVoidCancelService(){
    }

	//AR-75
	public CustomerReceiptVoidCancelService(list<Customer_Receipt__c> sObjects, boolean calledFromUI) // This constructor would be called from the UI controller and will set the boolena to true. 
	{
		super(sObjects);
		lCRs = new list<Customer_Receipt__c>();
		this.calledFromUI = calledFromUI;
	}
	
	private Map<Id, VoidCancelResponse> voidCreditCardTransactions() {
		Map<Id, VoidCancelResponse> responses = new Map<Id, VoidCancelResponse>();
		Service_Configuration__c sc = Service_Configuration__c.getAll().get('AuthorizeNetV1');
		for(Customer_Receipt__c sObj : lCRs) {
			VoidCancelResponse iVCR = new VoidCancelResponse();
            iVCR.recordId = sObj.Id;
            iVCR.recordName = sObj.Name;
            iVCR.Action = Action.CANCELDOC;
			if(sc != null && sObj.Payment_Method_3__c != null && sObj.Transaction_ID__C != null) {
				PaymentHandler ph = new PaymentHandler();
            iVCR.Success = ph.voidTransaction(sObj.Id, sObj.Transaction_ID__c);
            if(!ivCR.success) 
	            	iVCR.messages.add('Unable to void transaction at the gateway.');
            else
	            	iVCR.messages.add('Transaction successfully voided at the gaetway.');
			}else {
				iVCR.Success = true;// if no cc transaction let the prep be true!!
			}
            responses.put(sObj.Id, iVCR);
		}
		return responses;
	}
	
	public override Map<Id, VoidCancelResponse> prepForCancel(List<sObject> sObjRecs) {
		return voidCreditCardTransactions();
	}
	
	public override Map<Id, VoidCancelResponse> prepForVoid(List<sObject> sObjRecs) {
		return voidCreditCardTransactions();
	}
	
	public override Map<Id, VoidCancelService.VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs){
		
		map<Id, VoidCancelService.VoidCancelDetail> mBusinessVoidCancelDetails = new map<Id, VoidCancelService.VoidCancelDetail>();
		set<Id> sourceDocIds = new set<id>();
		Service_Configuration__c sc = Service_Configuration__c.getAll().get('AuthorizeNetV1');
		
	 	for(sObject sObj : sObjRecs)
	 		sourceDocIds.add(sObj.id);
		
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'ID','Finalized__c','Void__c','Status__c','Name','Payment_Method_3__c','Transaction_Id__c'
			});
			soql.setWhereClause('id in :sourceDocIds');
			SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Customer_Receipt_Lines__r');
			childRel1.addFields(new set<string>{
				//KNDY-13995
				'Id','Type__c','Amount__c','Customer_Invoice__c','Customer_Invoice__r.Name','Customer_Invoice__r.Total_Amount__c',
				'Customer_Invoice__r.Balance__c'
			});
			String over = PaymentService.TYPE_OVERPAYMENT;
			String pre = PaymentService.TYPE_PREPAYMENT;
			childRel1.setWhereClause('Type__c = :over OR Type__c = :pre');
			soql.addChildRelationship(childRel1);
			SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Claims__r');
			childRel2.addFields(new set<string>{
				'Id','Name','Amount__c','Source__c','Claim_Balance__c','Status__c'
			});
			childRel2.setWhereClause('Status__c = \'Closed\'');
			soql.addChildRelationship(childRel2);
			SOQLUtil.ChildRelationship childRel3 = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
			childRel3.addFields(new set<string>{
				'id','name'
			});
			childRel3.setWhereClause('status__c = \'Active\' and Has_Exceptions__c != true');
			soql.addChildRelationship(childRel3);
			lCRs = Database.query(soql.getQuery());
		
		if(!lCRs.isEmpty())
		{
			boolean isVoidedOrCancelled = false;
			for(Customer_Receipt__c cr : lCRs)
			{
				VoidCancelDetail iVCD = new VoidCancelDetail();
	            iVCD.recordId = cr.Id;
	            iVCD.recordName = cr.Name;
	            iVCD.isVoidable = true;
	            iVCD.isCancellable = true;
	            iVCD.voidMessages = new List<string>();
	            iVCD.cancelMessages = new List<string>();
	            list<Accounting_Entry__c> aelist = cr.Accounting_Entries__r;
	            
	            if(cr.Void__c) {
	            	isVoidedOrCancelled = true;
	            	iVCD.cancelMessages.add( cr.Name + ': Cannot Cancel, this Customer Receipt is already Void');
	            }
	            	
	           if(cr.Status__c == 'Cancelled') {
	            	isVoidedOrCancelled = true;
	            	iVCD.voidMessages.add(cr.Name + ': Cannot Void, this Customer Receipt is already Cancelled');
	            }
	            	
	            if(!(aelist.size()> 0))
					iVCD.voidMessages.add(cr.Name + ': Cannot Void, this Customer Receipt does not have Accounting Entry generated or has Exceptions');
				
	            if(cr.Claims__r.size() > 0)
	            {
	            	list<String> claimNames = new list<String>();
	            	for(Claim__c c : cr.Claims__r)
	            	{
	            		claimNames.add(c.Name);
	            	}
	            	iVCD.cancelMessages.add( cr.Name + ': Cannot Cancel as following claims are closed. Please reopen these first : '+String.join(claimNames, ','));
	            	iVCD.voidMessages.add(cr.Name + ': Cannot Void as following claims are closed. Please reopen these first : '+String.join(claimNames, ','));
	            }
	            
	            if(cr.Customer_Receipt_Lines__r.size() > 0)
	            {
	            	system.debug('Receipt lines: '+cr.Customer_Receipt_Lines__r);
	            	list<String> ciNames = new list<String>();
	            	for(Customer_Receipt_Line__c crl : cr.Customer_Receipt_Lines__r)
	            	{
	            		//KNDY-13995
	            		if(crl.Customer_Invoice__r.Total_Amount__c != crl.Customer_Invoice__r.Balance__c) //this indicates that the invoice has some payments made
	            			ciNames.add(crl.Customer_Invoice__r.Name);
	            	}
	            	if(!ciNames.isEmpty())
	            	{
	            		iVCD.cancelMessages.add( cr.Name + ': Cannot Cancel as following prepayment/overpayment invoices are closed. Please unapply the payments on these first : '+String.join(ciNames, ','));
	            		iVCD.voidMessages.add(cr.Name + ': Cannot Void as following prepayment/overpayment invoices are closed. Please unapply the payments on these first : '+String.join(ciNames, ','));
	            	}
	            }
	            if(sc != null && cr.Payment_Method_3__c != null && cr.Transaction_ID__c != null && !isVoidedOrCancelled) {
	            	PaymentHandler ph = new PaymentHandler();
	            	boolean isRefundable = ph.isTransactionRefundable(cr.Transaction_ID__c);
	            	if(isRefundable) {
		            	iVCD.cancelMessages.add(cr.Name + ': ' + Label.Cannot_cancel_settled_customer_receipt); 
						iVCD.voidMessages.add(cr.Name + ': ' + Label.Cannot_void_settled_customer_receipt); 
	            	}
	            }
	            if(iVCD.voidMessages.size() > 0) {
				iVCD.isVoidable = false;
				}
				if(iVCD.cancelMessages.size() > 0) {
					iVCD.isCancellable = false;
				}
	            
	            mBusinessVoidCancelDetails.put(cr.Id, iVCD);
	            
			}
		}
		
		
		
		
		return mBusinessVoidCancelDetails;
	}
	
	
	public override Map<Id, VoidCancelService.VoidCancelResponse> businessVoid(List<sObject> sObjRecs){
		
		Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
    	Savepoint sp = Database.setSavepoint();
    	try {
    		
    		CustomerReceiptService.onVoid(lCRs);
    		List<String> messages = new List<String>{Label.Customer_Receipt_Was_Voided};	
	    	for(sObject sObj : sObjRecs)
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.VOIDDOC));
    	}
    	catch(Exception ex){
			system.debug(LoggingLevel.Error, 'CR business void: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.VOIDDOC));
            }
            Database.rollback(sp);  
            return mResponses;
        }
    	return mResponses;
	}
	
	
	public override Map<Id, VoidCancelService.VoidCancelResponse> businessCancel(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();

    	for(sObject sObj : sObjRecs){
    		List<String> messages = new List<String>{Label.Customer_Receipt_Was_Cancelled};
    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.CANCELDOC));
    	}
    	
    	return mResponses;
    }
	
	

}