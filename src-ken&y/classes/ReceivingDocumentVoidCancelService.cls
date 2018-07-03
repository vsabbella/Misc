/*
* without sharing is intentional.  Void / Cancel needs to be run in system mode.
*/
public without sharing class ReceivingDocumentVoidCancelService extends VoidCancelService{
	
	public static final String LOGICAL_SALES_ORDER_SHIPMENT = InventoryTransactionService.LOGICAL_SALES_ORDER_SHIPMENT;
	
	public Boolean calledFromService;
	
    public ReceivingDocumentVoidCancelService(List<Receiving_Document__c> ReceivingDocuments){
    	super(ReceivingDocuments);  
    	calledFromService = false;
    }
    
    public ReceivingDocumentVoidCancelService(List<Receiving_Document__c> ReceivingDocuments, Boolean calledFromService){
    	super(ReceivingDocuments);  
    	this.calledFromService = calledFromService;
    }
    
    public ReceivingDocumentVoidCancelService(){
    }
    
     
	
    public override Map<Id, VoidCancelService.VoidCancelDetail> getBusinessVoidCancelDetails(List<sObject> sObjRecs){
    	Map<Id, VoidCancelService.VoidCancelDetail> mBusinessVoidCancelDetails = new Map<Id, VoidCancelService.VoidCancelDetail>();
    	Set<Id> sourceDocIds = new Set<Id>();
    	for(sObject sObj : sObjRecs) {
    		sourceDocIds.add(sObj.Id);
    	}
    	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Receiving_Document__c', false); //enforceFLS=false, running in system mode
		soql.addFields(new set<string>{
			'Id','Name','Status__c','Type__c','Transaction_Type__c'
		});
		soql.setWhereClause('Id IN :sourceDocIds');

		SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
		childRel1.addFields(new set<string>{
			'Id','Invoiced__c','Uninvoiced_Quantity__c','Quantity_Received__c', 'Sales_Order_Line__c', 'Receiving_Document__r.Transaction_Type__c',
			'Related_Receipt_Line__r.Status__c', 'Receiving_Document__c', 'Quantity_To_Consume__c', 'Line_Type__c'
		});
		soql.addChildRelationship(childRel1);

		SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
		childRel2.addFields(new set<string>{
			'id','name'
		});
		childRel2.setWhereClause('status__c = \'Active\' and Has_Exceptions__c != true');
		soql.addChildRelationship(childRel2);

		List<Receiving_Document__c> sourceDocumentChildren = Database.query(soql.getQuery());
		Map<Id, Id> rlinesmap = new Map<Id, Id>();

		for(Receiving_Document__c rd : sourceDocumentChildren) {
			VoidCancelDetail iVCD = new VoidCancelDetail();
            iVCD.recordId = rd.Id;
            iVCD.recordName = rd.Name;
            iVCD.isVoidable = true;
            iVCD.isCancellable = true;
            iVCD.voidMessages = new List<string>();
            iVCD.cancelMessages = new List<string>();
            list<Accounting_Entry__c> aelist = rd.Accounting_Entries__r;
            
            if((rd.Type__c == 'In-Transit' || rd.Type__c == 'Return Receipt') && calledFromService == false) {
				iVCD.voidMessages.add(Label.Cannot_Void_In_Transit_RD+' '+rd.Type__c);
				iVCD.cancelMessages.add(Label.Cannot_Cancel_In_Transit_RD+' '+rd.Type__c);
			}
			else{
				if (rd.Transaction_Type__c == 'Logical Purchase Order Receipt'  && calledFromService == false ) {
					iVCD.voidMessages.add(Label.Cannot_void_logical_po_receipt);
					iVCD.cancelMessages.add(Label.Cannot_cancel_logical_po_receipt);
				}
	            if(rd.Status__c == 'Void') {
					iVCD.voidMessages.add('Cannot Void, this Receiving Document is already Void');
					iVCD.cancelMessages.add('Cannot Cancel, this Receiving Document is already Void');
				}
				if(rd.Status__c == 'Cancelled') {
					iVCD.voidMessages.add('Cannot Void, this Receiving Document is already Cancelled');
					//iVCD.cancelMessages.add('Cannot Cancel, this Receiving Document is already Cancelled');
				}
				
				Boolean invoiced = false;
				Boolean relatedOpenRD = false;
				System.Debug(rd.Receipt_Lines__r);
				for(Receipt_Line__c rl : rd.Receipt_Lines__r){
	                //check if receipt is invoiced in full or uninvoiced quantity is > 0
	                if ((((rl.Invoiced__c) || (rl.line_Type__c != 'Consigned' && rl.Uninvoiced_Quantity__c != rl.Quantity_Received__c) || (rl.line_Type__c == 'Consigned' && rl.Quantity_To_Consume__c != rl.Quantity_Received__c)) &&
	                    (rd.Type__c != ReceivingDocumentServiceV2.RD_TYPE_RETURN && rd.Type__c != ReceivingDocumentServiceV2.RD_TYPE_MISCELLANEOUS && rd.Type__c != ReceivingDocumentServiceV2.RD_STATUS_INTRANSIT )) || 
                        ((rl.Invoiced__c) && (rd.Type__c == ReceivingDocumentServiceV2.RD_TYPE_RETURN || rd.Type__c == ReceivingDocumentServiceV2.RD_TYPE_MISCELLANEOUS || rd.Type__c == ReceivingDocumentServiceV2.RD_STATUS_INTRANSIT))){
	                	invoiced = true;
	                }
	                if(rl.Receiving_Document__r.Transaction_Type__c == 'Logical RMA Receipt' && !rlinesmap.containskey(rl.Receiving_Document__c)){
	                	rlinesmap.put(rl.Receiving_Document__c, rl.Id);
	                }
	                
				}
				
				if(invoiced) {
					iVCD.voidMessages.add('Cannot Void, this Receiving Document is already fully/partially invoiced');
					iVCD.cancelMessages.add('Cannot Cancel, this Receiving Document is already fully/partially invoiced');
				}
	                    
	
				if(!(aelist.size()> 0)){
					iVCD.voidMessages.add('Cannot Void, this Receiving Document does not have Accounting Entry generated or have Exceptions');
				}
				
			}
			Set<Id> rlineIds = new Set<Id>();
			if(rlinesmap.values().size() >0){
				for(Id rlId:rlinesmap.values()){
					rlineIds.add(rlId);
				}
				for(Receipt_Line__c rline: [Select Id,Status__c, Receiving_Document__c, Receiving_Document__r.Name, Receiving_Document__r.Status__c from Receipt_Line__c where Related_Receipt_Line__c In :rlineIds]){
					
					if(rline.Receiving_Document__r.Status__c != 'Cancelled' && rline.Receiving_Document__r.Status__c != 'Void'){
						iVCD.voidMessages.add('Cannot Void, the related Receiving Document need to be voided. Please void this Receiving Document: '+rline.Receiving_Document__r.Name);
						iVCD.cancelMessages.add('Cannot Cancel, the related Receiving Document need to be cancelled. Please cancel this Receiving Document: '+rline.Receiving_Document__r.Name);
						break;
					}
				}
			}
			
			if(iVCD.voidMessages.size() > 0) {
				iVCD.isVoidable = false;
			}
			if(iVCD.cancelMessages.size() > 0) {
				iVCD.isCancellable = false;
			}
			
			mBusinessVoidCancelDetails.put(rd.Id, iVCD);
		}

    	return mBusinessVoidCancelDetails; 
    }
    
    public override Map<Id, VoidCancelService.VoidCancelResponse> businessVoid(List<sObject> sObjRecs){
	 	Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
		
	 	try{		
			Id companyId;
	    	for(sObject sObj : sObjRecs){
	  			companyId = (Id) sObj.get('Company__c');
	    		List<String> messages = new List<String>{'Successfully Voided!'};	
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.VOIDDOC));
	    	}
	    	
	    	ReceivingDocumentServiceV2 rds = ReceivingDocumentServiceV2.getInstance();
			rds.voidOrderReceipts(mResponses.keyset(), 'Void');

	    	return mResponses;
    	}
    	catch(Exception ex){
            //Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, ex.getMessage()));
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.VOIDDOC));
            }
        
            return mResponses;
        }
    }
    

	public override Map<Id, VoidCancelService.VoidCancelResponse> businessCancel(List<sObject> sObjRecs){
		Map<Id, VoidCancelService.VoidCancelResponse> mResponses = new Map<Id, VoidCancelService.VoidCancelResponse>();
		
    	try{
	    	Id companyId;
	    	for(sObject sObj : sObjRecs){
	    		companyId = (Id) sObj.get('Company__c');
	    		List<String> messages = new List<String>{'Successfully Cancelled!'};
	    		mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), true, messages, VoidCancelService.Action.CANCELDOC));
	    	}
	    	
	    	ReceivingDocumentServiceV2 rds = ReceivingDocumentServiceV2.getInstance();
	    	rds.voidOrderReceipts(mResponses.keyset(), 'Cancelled');
		    
	    	return mResponses;
    	}
    	catch(Exception ex){
    		system.debug(LoggingLevel.ERROR, ex.getStackTraceString());
            //Apexpages.addMessage(new Apexpages.Message(Apexpages.Severity.ERROR, ex.getMessage()));
            for(sObject sObj : sObjRecs){
            	mResponses.put(sObj.Id, new VoidCancelService.VoidCancelResponse(sObj.Id, (string)sObj.get('Name'), false, new List<String>{ex.getMessage()}, VoidCancelService.Action.CANCELDOC));
            }
            Database.rollback(sp);
            return mResponses;
        }
    }
}