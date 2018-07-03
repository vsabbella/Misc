public with sharing class SupplierInvoiceVoidCancelService extends VoidCancelService{

    public SupplierInvoiceVoidCancelService(List<Supplier_Invoice__c> supplierInvoices){
    	super(supplierInvoices);  
    }
    
    public SupplierInvoiceVoidCancelService(){
    }
    
    
    
    public override Map<Id, VoidCancelService.VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelDetail> mBusinessVoidCancelDetails = new Map<Id, VoidCancelService.VoidCancelDetail>();
    	Set<Id> sourceDocIds = new Set<Id>();
    	for(sObject sObj : sObjRecs) {
    		sourceDocIds.add(sObj.Id);
    	}
    	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Status__c','Void__c'
		});
		soql.setWhereClause('Id IN :sourceDocIds');
		
		SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Supplier_Payment_Lines__r');
		childRel1.addFields(new set<string>{
			'Id'
		});
		childRel1.setWhereClause('Supplier_Payment__r.Status__c != \'Void\' AND Supplier_Payment__r.Status__c != \'Cancel\' AND Supplier_Payment__r.Void__c = false');
		soql.addChildRelationship(childRel1);
		
		SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Supplier_Payment_Lines1__r');
		childRel2.addFields(new set<string>{
			'Id'
		});
		childRel2.setWhereClause('Supplier_Payment__r.Status__c != \'Void\' AND Supplier_Payment__r.Status__c != \'Cancel\' AND Supplier_Payment__r.Void__c = false');
		soql.addChildRelationship(childRel2);
		
		SOQLUtil.ChildRelationship childRel3 = new SOQLUtil.ChildRelationship(soql, 'Credit_Memos__r');
		childRel3.addFields(new set<string>{
			'Id'
		});
		childRel3.setWhereClause('Status__c != \'Void\' AND Status__c != \'Cancel\' AND Void__c = false');
		soql.addChildRelationship(childRel3);
		
		SOQLUtil.ChildRelationship childRel4 = new SOQLUtil.ChildRelationship(soql, 'Fixed_Asset_Adjustments__r');
		childRel4.addFields(new set<string>{
			'Id'
		});
		soql.addChildRelationship(childRel4);
		
		SOQLUtil.ChildRelationship childRel5 = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
		childRel5.addFields(new set<string>{
			'id','name'
		});
		childRel5.setWhereClause('status__c = \'Active\' and Has_Exceptions__c != true');
		soql.addChildRelationship(childRel5);

		List<Supplier_Invoice__c> sourceDocumentChildren = Database.query(soql.getQuery());
		
		for(Supplier_Invoice__c si : sourceDocumentChildren) {
			VoidCancelDetail iVCD = new VoidCancelDetail();
            iVCD.recordId = si.Id;
            iVCD.recordName = si.Name;
            iVCD.isVoidable = true;
            iVCD.isCancellable = true;
            iVCD.voidMessages = new List<string>();
            iVCD.cancelMessages = new List<string>();
            list<Accounting_Entry__c> aelist = si.Accounting_Entries__r;
            
            
            
            if(si.Void__c) {
				//iVCD.voidMessages.add('Cannot Void, this Supplier Invoice is already Void');
				iVCD.cancelMessages.add('Cannot Cancel, this Supplier Invoice is already Void');
			}
			if(si.Status__c == 'Cancelled') {
				iVCD.voidMessages.add('Cannot Void, this Supplier Invoice is already Cancelled');
				//iVCD.cancelMessages.add('Cannot Cancel, this Supplier Invoice is already Cancelled');
			}
			if(si.Supplier_Payment_Lines__r != null && si.Supplier_Payment_Lines__r.size() > 0) {
				iVCD.voidMessages.add('Cannot Void, this Supplier Invoice is referenced in one or more Supplier Payments');
				iVCD.cancelMessages.add('Cannot Cancel, this Supplier Invoice is referenced in one or more Supplier Payments');
			}
			if(si.Supplier_Payment_Lines1__r != null && si.Supplier_Payment_Lines1__r.size() > 0) {
				iVCD.voidMessages.add('Cannot Void, this Supplier Invoice is referenced in one or more Supplier Payments');
				iVCD.cancelMessages.add('Cannot Cancel, this Supplier Invoice is referenced in one or more Supplier Payments');
			}
			if(si.Credit_Memos__r != null && si.Credit_Memos__r.size() > 0) {
				iVCD.voidMessages.add('Cannot Void, this Supplier Invoice is referenced in one or more Credit Memos');
				iVCD.cancelMessages.add('Cannot Cancel, this Supplier Invoice is referenced in one or more Credit Memos');
			}
			if(si.Fixed_Asset_Adjustments__r != null && si.Fixed_Asset_Adjustments__r.size() > 0) {
				iVCD.voidMessages.add('Cannot Void, this Supplier Invoice is referenced in one or more Fixed Asset Adjustments');
				iVCD.cancelMessages.add('Cannot Cancel, this Supplier Invoice is referenced in one or more Fixed Asset Adjustments');
			}
			
	    	if(!(aelist.size()> 0)){
				iVCD.voidMessages.add('Cannot Void, this Supplier Invoice does not have Accounting Entry generated or have Exceptions');
			}
			if(iVCD.voidMessages.size() > 0) {
				iVCD.isVoidable = false;
			}
			if(iVCD.cancelMessages.size() > 0) {
				iVCD.isCancellable = false;
			}
			
			mBusinessVoidCancelDetails.put(si.Id, iVCD);
		}
        system.debug(logginglevel.error,'mBusinessVoidCancelDetails--->'+mBusinessVoidCancelDetails);
    	return mBusinessVoidCancelDetails; 
    }
    
    public override Map<Id, VoidCancelService.VoidCancelResponse> businessVoid(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
		
    	for(sObject sObj : sObjRecs){
    		//Business Process Logic
    		
    		List<String> messages = new List<String>{'Successfully Voided!'};	
    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.VOIDDOC));
    	}
    	
    	return mResponses;
    }
    

	public override Map<Id, VoidCancelService.VoidCancelResponse> businessCancel(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();

    	for(sObject sObj : sObjRecs){
    		//Business Process Logic
    		List<String> messages = new List<String>{'Successfully Cancelled!'};
    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.CANCELDOC));
    	}
    	
    	return mResponses;
    }

}