trigger SupplierInvoice on Supplier_Invoice__c ( before insert, before update, before delete, after update) {

	if(DML.checkTriggerDispatch(Supplier_Invoice__c.getSobjectType())){return;}
	 SupplierInvoiceService.setCreditMemoBalance(); //KNDY-13507
     Set<Id> SupplierInvIds = new Set<Id>();
     map<Id,List<Accounting_Entry__c>> supplierInvMap = new Map<Id, List<Accounting_Entry__c>>();
     List<Supplier_Invoice__c> supplierInvList = new List<Supplier_Invoice__c>();
     // KNDY-1482
     SupplierInvoiceService.setDefaultPaymentMethod();
     static SchemaUtil util = SchemaUtil.getInstance();
     
     System.debug(logginglevel.error,'Inside the trigger');
     //VoidCancelService.validateHeader();
     SupplierInvoiceService.setPaymentDueDate(); //KNDY-11064 KNDY-11689

     if(trigger.isBefore && ( trigger.isInsert || trigger.isUpdate)){
		 KSE.setValidateFinalizedFlagonSD();

        // set finalized date on the shipment
        FinalizeService.setFinalizedDate(Trigger.new);
        
        for(Supplier_Invoice__c supplierInvoice : Trigger.new){ //KNDY-6707
            if(supplierInvoice.Invoice_Amount__c != null){
                supplierInvoice.Invoice_Amount__c = supplierInvoice.Invoice_Amount__c.setScale(2);
            }
        } 
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

		SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Name'
		});
		soql.setWhereClause('id in :SupplierInvIds');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Accounting_Entries__r');
		childRel.addFields(new set<string>{
			'id','Name'
		});
		childRel.setWhereClause('void__c = false');
		soql.addChildRelationship(childRel);
		
		//KNDY-3369
        
		supplierInvList = Database.query(soql.getQuery());
		
        for(Supplier_Invoice__c thisSupInv: supplierInvList){
            supplierInvMap.put(thisSupInv.id, thisSupInv.Accounting_Entries__r);
        }
        //KNDY-17276 round decimal fields
        Scale.govern(trigger.new);
     }
     if(trigger.isBefore && trigger.isUpdate){

            for(Supplier_Invoice__c SInvoice: Trigger.new){
                
                //system.debug('SInvoice:'+SInvoice);
                //KNDY-3369
                Boolean Accounted = false;
                if(supplierInvMap.containsKey(SInvoice.id)){
                    if((supplierInvMap.get(SInvoice.id)).size() > 0){
                        Accounted = true;
                    }
                }

                //KNDY-1818 excluding credit memo from the below check
                //KNDY-3369 if(((SInvoice.Invoice_Type__c.toLowerCase()) != 'credit memo') && SInvoice.Accounted__c && trigger.oldMap.get(SInvoice.Id).accounted__c && SInvoice.Status__c != 'Void'
                if(((SInvoice.Invoice_Type__c.toLowerCase()) != 'credit memo') && Accounted && (!SInvoice.Void__c || SInvoice.Status__c != 'Cancelled')
                    && ((KSE.isFieldChanging('Amount_Paid__c', SInvoice, Trigger.oldMap)) == False) && ((KSE.isFieldChanging('Credit_Memo_Applied__c', SInvoice, Trigger.oldMap)) == False)
                    && ((KSE.isFieldChanging('Credit_Memo_Balance__c', SInvoice, Trigger.oldMap)) == False) && ((KSE.isFieldChanging('Discount_Taken__c', SInvoice, Trigger.oldMap)) == False)
                    && ((KSE.isFieldChanging('Status__c', SInvoice, Trigger.oldMap)) == False)){
                    
                    if (KSE.isFieldChanging('Hold__c', SInvoice, Trigger.oldMap) == false) //KNDY-2512 ignoring the error when SI is put on hold/removed from hold
                        SInvoice.addError(Label.AccountedInvoices_cannot_be_modified);
                }
                /*
                //KNDY-1533 - User should not be able to edit supplier invoice information once status = Paid (Closed)
                if((SInvoice.Status__c == 'Paid' || SInvoice.Status__c == 'Closed')
                        && !KSE.isFieldChanging('Status__c', SInvoice, trigger.oldMap)
                        //KNDY-3369 && !(KSE.isFieldChanging('Accounted__c', Sinvoice, trigger.oldMap) || KSE.isFieldChanging('Finalized__c', SInvoice, trigger.oldMap))){
                        && !(KSE.isFieldChanging('Finalized__c', SInvoice, trigger.oldMap))){
                    SInvoice.addError(Label.ClosedInvoices_cannot_be_modified);
                }
                */
            }
            
            SupplierInvoiceService.preventChangeSupplier(Trigger.new,Trigger.oldMap);
            
    }

    // Restricting the SI with Void/Cancelled status to be edited
    if(trigger.isBefore && (trigger.isDelete || trigger.isInsert || trigger.isUpdate)){
            SupplierInvoiceService.restrictEditOnVoidAndCancelSI();
     }
     
    if (trigger.isBefore && trigger.isUpdate){ //KNDY-2322
        Map<Id, Supplier_Invoice__c> voidedInvoices = new Map<Id, Supplier_Invoice__c>();
        Map<Id, Supplier_Invoice__c> voidedIncompleteDraftInvoicesOnly = new Map<Id, Supplier_Invoice__c>();
        Map<Id, Supplier_Invoice__c> unfinalizedInvoices = new Map<Id, Supplier_Invoice__c>();
        Map<Id, Supplier_Invoice__c> resetInvoices = new Map<Id, Supplier_Invoice__c>();
        Map<Id, Supplier_Invoice__c> polQty = new Map<Id, Supplier_Invoice__c>();
        
        
        for(Supplier_Invoice__c SInvoice : trigger.new){
            
            //KNDY-3247 Checking for status update to Incomplete/Draft upon void
           /* if(KSE.isFieldChanging('Status__c', SInvoice, trigger.oldMap) &&  
                ((SInvoice.Void__c || SInvoice.Status__c == 'Cancelled') && 
                    trigger.oldMap.get(SInvoice.id).Status__c == 'Draft' 
                    
            )){
                if(SInvoice.Invoice_Type__c =='Invoice'){
                    voidedIncompleteDraftInvoicesOnly.put(SInvoice.id, SInvoice);
                    
                } 
            } */
            
            
            if(KSE.isFieldChanging('Status__c', SInvoice, trigger.oldMap) && SInvoice.Invoice_Type__c != 'Prepayment') { // KNDY-9649
                if (SInvoice.Void__c || SInvoice.Status__c == 'Cancelled'){ //KNDY-2512 Checking for status update to Incomplete upon edits
                    
                    if(trigger.oldMap.get(SInvoice.Id).Status__c == 'Approved'){
	                    voidedInvoices.put(SInvoice.id, SInvoice);
                    }else if(trigger.oldMap.get(SInvoice.Id).Status__c == 'Draft'){
                    	resetInvoices.put(SInvoice.id, SInvoice);
	                		polQty.put(SInvoice.Id, SInvoice);
		                }else if(trigger.oldMap.get(SInvoice.Id).Status__c == 'Incomplete') {
		                    polQty.put(SInvoice.Id, SInvoice);
                    }	
                    	
	       				
                }
                
                if (SInvoice.Status__c == 'Incomplete'){ //KNDY-2512 Checking for status update to Incomplete upon edits
	       			 if (trigger.oldMap.get(SInvoice.id).Status__c == 'Approved'){
 	       			 	unfinalizedInvoices.put(SInvoice.id, SInvoice); //KNDY-13512
	       			 }
	       			 else{
	       			 	resetInvoices.put(SInvoice.id, SInvoice);
	       			 }
	       			
                }      
        	}
            
        } // end of for loop
        
        System.debug(logginglevel.error,'voidedFlag--->'+SupplierInvoiceService.voidedFlag);
        System.debug(logginglevel.error,'voidedInvoices---->'+voidedInvoices);
        System.debug(logginglevel.error,'resetFlag---->'+SupplierInvoiceService.resetFlag);
        System.debug(logginglevel.error,'resetInvoices---->'+resetInvoices);
        
        if(!voidedInvoices.isEmpty() && !SupplierInvoiceService.voidedFlag ){
             SupplierInvoiceService.returnMatchedQuantityUponVoid(voidedInvoices, true, false, false);
            SupplierInvoiceService.voidedFlag = true;
            
            
        }
        
        if(!resetInvoices.isEmpty() && !SupplierInvoiceService.resetFlag){
             SupplierInvoiceService.returnMatchedQuantityUponVoid(resetInvoices, false, true, false);
            SupplierInvoiceService.resetFlag = true;
            
        }
	    
	   /* if(!polQty.isEmpty() && !SupplierInvoiceService.polQtyFlag) {
             SupplierInvoiceService.returnPOL_QtyUnInvoiced(polQty);
              SupplierInvoiceService.polQtyFlag = true;
	    } */
	    
         if(!unfinalizedInvoices.isEmpty() && !SupplierInvoiceService.unfinalizeFlag){ //KNDY-13512
            SupplierInvoiceService.returnMatchedQuantityUponVoid(unfinalizedInvoices, false, false, true);
            SupplierInvoiceService.unfinalizeFlag = true;
    }
    
    }
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isDelete)){
        InvoiceService.restrictEditOnApprovedClosedInvoices();
     	FinalizeService.validateHeaderFinalize();
	}

    if(trigger.isBefore && trigger.isInsert){
        Set<ID> companyIDs = new set<ID>();
        List<Supplier_Invoice__c> recWithoutCurrency = new List<Supplier_Invoice__c>();
        Map<ID,ID> companyCurrencyMap = new Map<ID,ID>();
            for(Supplier_Invoice__c rec : trigger.new){
                 if(rec.Currency__c == null && rec.Company__c != null){
                    companyIDs.add(rec.Company__c);
                    recWithoutCurrency.add(rec);
                 }
            }
        
            if(companyIDs.size() > 0 ){
                companyCurrencyMap = CompanyService.setDefaultCurrency(companyIDs);
            }
      		for(Supplier_Invoice__c rec : recWithoutCurrency){
      			if(rec.Currency__c ==  NULL && companyCurrencyMap.containsKey(rec.Company__c)){
      				rec.Currency__c = companyCurrencyMap.get(rec.Company__c);
      			}
      		}
     }

}