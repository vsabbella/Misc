trigger SupplierPaymentLine on Supplier_Payment_Line__c (before insert, before update, after insert, after update, before delete, after undelete) {
    
    if(DML.checkTriggerDispatch(Supplier_Payment_Line__c.getSobjectType())){return;}
    
    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
	    set<Id> supplierInvoiceIds = new set<Id>();
	    for(Supplier_Payment_Line__c pl : trigger.new){
	        supplierInvoiceIds.add(pl.Supplier_Invoice__c);
	    }
	    
	    //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Supplier__r.X1099_Box_G__c','Invoice_Type__c','Credit_Memo_Balance__c',
			'Credit_Memo_Amount__c', 'Amount_Paid__c', 'Credit_Memo_Applied__c'
		});
		soql.setWhereClause('Id IN :supplierInvoiceIds');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Supplier_Payment_Lines__r');
		childRel.addFields(new set<string>{
			'Id','name','amount__c','type__c','supplier_payment__r.finalized__c','Supplier_Payment__r.Status__c'
		});
		soql.addChildRelationship(childRel);
		
		Map<Id, Supplier_Invoice__c> mSupplierInvoices = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
	    
	    if (trigger.isInsert){
		    for(Supplier_Payment_Line__c pl : trigger.new){
		        if((pl.X1099_Box_G__c == null || pl.X1099_Box_G__c == '') && mSupplierInvoices.containsKey(pl.Supplier_Invoice__c)){
		            pl.X1099_Box_G__c = mSupplierInvoices.get(pl.Supplier_Invoice__c).Supplier__r.X1099_Box_G__c;
		        }
		    }
	    }
	    try{
	    	//apex cpu time out error while performing preview operation for more than 300 records. to avoid failure made another query to preserve call to suminvoicepayments   	    	
			soql = new SOQLUtil('Supplier_Invoice__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Supplier__r.X1099_Box_G__c','Invoice_Type__c','Credit_Memo_Balance__c',
				'Credit_Memo_Amount__c', 'Amount_Paid__c', 'Credit_Memo_Applied__c'
			});
			soql.setWhereClause('Id IN :supplierInvoiceIds');
			
			childRel = new SOQLUtil.ChildRelationship(soql, 'Supplier_Payment_Lines__r');
			childRel.addFields(new set<string>{
				'Id','name','amount__c','type__c','supplier_payment__r.finalized__c','Supplier_Payment__r.Status__c','supplier_payment__r.Void__c'
			});
			childRel.setWhereClause(' supplier_payment__r.finalized__c = true And supplier_payment__r.Void__c = false ');
			soql.addChildRelationship(childRel);
			mSupplierInvoices = new Map<Id, Supplier_Invoice__c>((List<Supplier_Invoice__c>)Database.query(soql.getQuery()));
	    	SupplierPaymentService.sumInvoicePayments(mSupplierInvoices.values());
	    }catch(exception ex){
	    	throw ex;
	    }
    }
    
    if((trigger.isAfter && (trigger.isInsert || trigger.isUpdate || trigger.isUndelete))
    	 	|| (trigger.isBefore && trigger.isDelete)){
        
    	FinalizeService.validateLineFinalize();
        
	}
    
}