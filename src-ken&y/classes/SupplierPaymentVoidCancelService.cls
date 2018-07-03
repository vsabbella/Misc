public with sharing class SupplierPaymentVoidCancelService extends VoidCancelService{

    public SupplierPaymentVoidCancelService(List<Supplier_Payment__c> SupplierPayments){
    	super(SupplierPayments);  
    }
    
    public SupplierPaymentVoidCancelService(){
    }
    
    

    public override Map<Id, VoidCancelService.VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelDetail> mBusinessVoidCancelDetails = new Map<Id, VoidCancelService.VoidCancelDetail>();
    	Set<Id> sourceDocIds = new Set<Id>();
    	for(sObject sObj : sObjRecs) {
    		sourceDocIds.add(sObj.Id);
    	}

		SOQLUtil soql = new SOQLUtil('Supplier_Payment__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Name','Transaction_Date__c','Finalized_Date__c','Payment_Amount__c','Bank_Account__c','Date_Paid__c','Supplier__c',
			'Finalized__c','Company__c','Currency__c','Payment_Method_G__c','Status__c'
		});
		soql.setWhereClause('Id IN :sourceDocIds');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
		childRel.addFields(new set<string>{
			'id','Name'
		});
		childRel.setWhereClause('status__c = \'Active\' and Has_Exceptions__c != true');
		soql.addChildRelationship(childRel);

		List<Supplier_Payment__c> sourceDocumentChildren = Database.query(soql.getQuery());
		
		for(Supplier_Payment__c sp : sourceDocumentChildren) {
			VoidCancelDetail iVCD = new VoidCancelDetail();
            iVCD.recordId = sp.Id;
            iVCD.recordName = sp.Name;
            iVCD.isVoidable = true;
            iVCD.isCancellable = true;
            iVCD.voidMessages = new List<string>();
            iVCD.cancelMessages = new List<string>();
            list<Accounting_Entry__c> aelist = sp.Accounting_Entries__r;
            
            if(sp.Status__c == 'Void') {
				iVCD.voidMessages.add(Label.Cannot_Void_this_Supplier_Payments_is_already_Void);
				iVCD.cancelMessages.add(Label.Cannot_Cancel_this_Supplier_Payments_is_already_Void);
            }
			if(sp.Status__c == 'Cancelled') {
				iVCD.voidMessages.add(Label.Cannot_Void_this_Supplier_Payments_is_already_Cancelled);
			}
		    if(!(aelist.size()> 0)){
				iVCD.voidMessages.add(Label.Cannot_Void_this_Supplier_Payments_does_not_have_Accounting_Entry_generated);
			}
			
			
			if(iVCD.voidMessages.size() > 0) {
				iVCD.isVoidable = false;
			}
			if(iVCD.cancelMessages.size() > 0) {
				iVCD.isCancellable = false;
			}
			
			mBusinessVoidCancelDetails.put(sp.Id, iVCD);
		}

    	return mBusinessVoidCancelDetails; 
    }
    
    public override Map<Id, VoidCancelService.VoidCancelResponse> businessVoid(List<sObject> sObjRecs){

    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
    	Savepoint sp = Database.setSavepoint();
		try {
				SupplierPaymentService.onVoidCancel(sObjRecs);
	    		List<String> messages = new List<String>{Label.Successfully_Voided};	
				for(sObject sObj : sObjRecs)  
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.VOIDDOC));
	    	return mResponses;
		}
		catch(Exception ex){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.VOIDDOC));
            }
            Database.rollback(sp);  
            return mResponses;
        }

    }
    
	public override Map<Id, VoidCancelService.VoidCancelResponse> businessCancel(List<sObject> sObjRecs){ 
		Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
		Savepoint sp = Database.setSavepoint();
        try {
              SupplierPaymentService.onVoidCancel(sObjRecs);
			  List<String> messages = new List<String>{Label.Successfully_Cancelled};
              for(sObject sObj : sObjRecs)   
			mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.CANCELDOC));
            return mResponses;
		}
        catch(Exception ex){
            Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
            for(sObject sObj : sObjRecs){
                mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.CANCELDOC));
            }
            Database.rollback(sp);  
    	return mResponses;
	}
		
	}
}