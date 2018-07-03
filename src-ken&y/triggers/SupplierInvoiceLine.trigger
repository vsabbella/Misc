trigger SupplierInvoiceLine on Supplier_Invoice_Line__c (after delete, after insert, after update, 
before delete, before insert, before update, after undelete) {

	if(DML.checkTriggerDispatch(Supplier_Invoice_Line__c.getSobjectType())){return;}
    
    // KNDY-9649 Get SI Invoice Type
	Map<Id, Supplier_Invoice__c> siMap ;	
	if ((trigger.isBefore && trigger.isUpdate) ||( trigger.isAfter && trigger.isDelete)){
		Set<Id> siIds = new Set<Id>();		
		if ((trigger.isBefore && trigger.isUpdate)){
			for (Supplier_Invoice_Line__c sil : trigger.New){
				siIds.add(sil.Supplier_Invoice__c);
			}
		}
		else if ((trigger.isAfter && trigger.isDelete)){
			for (Supplier_Invoice_Line__c sil : trigger.Old){
				siIds.add(sil.Supplier_Invoice__c);
			}
		}
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Invoice_Type__c'
		});
		soql.setWhereClause('Id in :siIds');
		siMap = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
	
	}

if ( trigger.isBefore) {
		if (trigger.isInsert || trigger.isUpdate){
	    	for(Supplier_Invoice_Line__c sil : trigger.new){ //KNDY-6707
	    		//KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price
				if(sil.Unit_Price__c != null){ 
					sil.Unit_Price__c = sil.Unit_Price__c.setScale(6);
				}	
			}
		}	
        if ( trigger.IsInsert) {
           // SupplierInvoiceService.preventDuplicatedInvoiceLine(trigger.new);  commenting out this method as we need the ability to do partial payments KNDY-1277
           // and also the busy wait on the add manage screen prevents double clicking and makes this method not necessary.
           
           SupplierInvoiceService.updateQuantitytoStock(trigger.new);
        
        }
        
		if (trigger.isUpdate){ //KNDY-2322
			List<Supplier_Invoice_Line__c> putSILQtyBack = new List<Supplier_Invoice_Line__c>();
			for(Supplier_Invoice_Line__c sil : trigger.new){
				if( siMap.get(sil.Supplier_Invoice__c).Invoice_Type__c != 'Prepayment' && // KNDY-9649
					 ( KSE.isFieldChanging('Invoice_Quantity__c', sil, trigger.oldMap) 
					|| KSE.isFieldChanging('Unit_Price__c', sil, trigger.oldMap) //KNDY-14371 - replace invoice unit price with unit price and delete invoice unit price
					|| KSE.isFieldChanging('Purchase_Order_Line__c', sil, trigger.oldMap))){
						
						//system.debug('before update Trigger is getting fired'); 
						putSILQtyBack.add(sil);	
				}	
			}
			if(putSILQtyBack.size() > 0 && !SupplierInvoiceService.lineResetFlag){
				//system.debug('before update passing the buck to service class');
				SupplierInvoiceService.returnMatchedQuantity(putSILQtyBack,trigger.oldMap, false, false, false, false);
				SupplierInvoiceService.lineResetFlag = true; //KNDY-13946
			}
		}
        
    }
        
    
	if ( trigger.isAfter) {
    
        if ( trigger.isDelete) {
        		List<Supplier_Invoice_Line__c> putSILQtyBack = new List<Supplier_Invoice_Line__c>();       	
    			for(Supplier_Invoice_Line__c sil : trigger.old){ // KNDY-9649
				if(siMap.get(sil.Supplier_Invoice__c).Invoice_Type__c != 'Prepayment'){
					putSILQtyBack.add(sil);	
				}
    			}
    			if (putSILQtyBack.size() > 0){
    				SupplierInvoiceService.returnMatchedQuantity(putSILQtyBack, trigger.oldMap, true, false, false, false); //KNDY-2322	
    			}
        }
  
    } 
    
    // Restricting the SIL with Void/Cancelled status to be edited
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate || trigger.isDelete)){
         SupplierInvoiceService.restrictEditOnVoidAndCancelSIL();   
    }     
    
    if((trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete))
    	 	|| (trigger.isBefore && trigger.isDelete)){
        
    	FinalizeService.validateLineFinalize();
        
	}
}