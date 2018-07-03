public with sharing class PurchaseOrderCloneExt {
    ID oldISID;
    private ApexPages.StandardController controller;
    public Boolean isVisible { get; set;}
    
    public PurchaseOrderCloneExt (ApexPages.StandardController c) {
        controller = c;
        oldISID = controller.getRecord().id;
        isVisible = true;
    }
    
     public Pagereference Save(){
     
        Purchase_Order__c oldPO = new Purchase_Order__c();
        Purchase_Order__c newPO = new Purchase_Order__c();
        List<Purchase_Order_Line__c> POLList = new List<Purchase_Order_Line__c> ();
        set<Id> itemIds = new set<Id>(); //PTP-328
        set<Id> facilityIds = new set<Id>();
        
        oldPO = (Purchase_Order__c)controller.getRecord();    
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id supplierId = oldPO.Supplier__c;
		
		SOQLUtil soql = new SOQLUtil('Supplier__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Remit_To__c','Hold_Purchasing__c','RecordType.Name','RecordType.DeveloperName','RecordTypeId','Company__c'
		});
		soql.setWhereClause('id = :supplierId');

		Supplier__c supplier = Database.query(soql.getQuery());
        
        //PTP-652
        if(!String.isBlank(supplier.Company__c) 
        	&& (oldPO.Company__c != supplier.Company__c)){
            
            ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,
                    Label.Purchase_from_Supplier_not_tagged_to_the_Company));
            return null;
        }
        
        if (supplier.Hold_Purchasing__c){
        	ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,
                    Label.Purchase_Order_clone_failed));
            isVisible = false;
            return null;
        }
        else if(oldPO.Type__c == 'Drop Ship'){
        	ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,'Cannot clone a Drop Ship PO'));
            isVisible = false;
            return null;
        }else {
	        newPO = oldPO.clone(false,true);
	        
	        newPO.Approval_Status__c = 'Pending Authorization';
	        newPO.Date_Closed__c = null;
	        newPO.Order_Date__c = system.today();
	        newPO.Status__c = 'Open';        
	        // PTP-567 Supplier on clone may be changed, reset remit to supplier
	        newPO.Remit_To_Supplier__c = supplier.Remit_To__c;
	        
	        Savepoint sp = Database.setSavepoint();
	        
	        SegmentService seg = new SegmentService(); 
	        List<string> tmp = new List<string>(); 
	        for ( string st : seg.segmentNameList() ) { tmp.add( 'Accounting_segment__r.' + st);  } // KNDY-1677
	         
	        try {
	            DML.insertAsUser( new list<sobject>{ newPO });
	            
	            list<Accounting_Default__c> newDefaults = new list<Accounting_Default__c>();
	            id oid = oldPO.id;
	            
	            String whereClause = 'Purchase_Order__c = :oid';
        		Set<String> polFields = new Set<String>{'Id', 'Company__c', 'Description__c', 'Item__c', 'Latest_Promise_Date__c',
		                                                'Line__c', 'Delivery_Location__c', 'Delivery_Facility__c', 'Contract_Line__c', 'Need_Date__c', 'Order_Quantity__c', 'Invoice_Matching__c', 'Supplier__c',
		                                                'Overage_Percentage__c', 'Promise_date__c', 'Purchase_UOM__c', 'Requisition_Number__c',
		                                                'Rush_Line__c', 'Special_Notes__c', 'Suppliers_Part_Description__c', 'Supplier_Part__c', 'Unit_Price__c', 'Memo__c', 
		                                                'Accounting_Segment__c', 'Standard_Cost__c'};
        		polFields.addAll(tmp);
        		
			    soql = new SOQLUtil('Purchase_Order_Line__c');
			    soql.addFields(polFields);
			    soql.setWhereClause(whereClause);
	    
	            List<Purchase_Order_Line__c> oldPOLines = Database.query(soql.getQuery()); 
		        
		        for (Purchase_Order_Line__c oldPOLObject: oldPOLines)  {
		            //PTP-328
		            itemIds.add(oldPOLObject.Item__c);
		            facilityIds.add(oldPOLObject.Delivery_Facility__c);
		        }
		        for (Purchase_Order_Line__c oldPOLObject: oldPOLines)  {    	
		            Purchase_Order_Line__c newPOLObject = new Purchase_Order_Line__c();          
		            newPOLObject = oldPOLObject.clone(false,true); //ToDo need to add standard cost on new PO Line
		            system.debug('New PO Line: ' + newPOLObject);
		            newPOLObject.Date_Added__c = system.today();
		            newPOLObject.Date_Closed__c = null;
		            newPOLObject.Date_Last_Changed__c = system.today();
		            newPOLObject.MRP_Plan__c = null;           
		            newPOLObject.Purchase_Order__c = newPO.ID;
                    //KNDY#2993 Clone PO Issue
                    if(newPO.Need_Date__c != null){
                    	newPOLObject.Need_Date__c = newPO.Need_Date__c;
                    }
                    
		            newPOLObject.Quantity_Returned_to_Supplier__c = 0.0;
		            newPOLObject.Status__c = 'Open';
		            
		            if ( newPOLObject.Accounting_segment__r != null ) { // KNDY-1677
			            newPOLObject.Accounting_segment__r = oldPOLObject.Accounting_segment__r.clone(false, true); 
			            newDefaults.add( newPOLObject.Accounting_segment__r );
		            }
		            //PTP-328		            
		            DateTime costDate;
		            if(newPO.Order_Date__c != null)
		            	costDate =datetime.newInstance(newPO.Order_Date__c.year(), newPO.Order_Date__c.month(),newPO.Order_Date__c.day());
		            newPOLObject.Standard_Cost__c = ItemService.getActiveStandardCostDecimal(itemIds,facilityIds, newPOLObject.Company__c, newPOLObject.Delivery_Facility__c,costDate,newPOLObject.Item__c );
        		 
		            POLList.add(newPOLObject);
		            
				}
				
	        		DML.insertAsUser(  newDefaults ); 											// KNDY-1677
	        		for ( Purchase_Order_Line__c p:POLList  ) { 			// KNDY-1677
	        			if ( p.Accounting_segment__r != null ) p.Accounting_segment__c=p.Accounting_segment__r.id;
	        		}
	        		
				DML.insertAsUser(  POLList );
				
	        } 
	        catch (DmlException e) {
	           ApexPages.addMessages(e);
	           Database.rollback(sp);
	           //isVisible = false; //PTP-172
	           return null;
	        }          
	
	        PageReference POPage = new PageReference('/'+newPO.Id);
	        POPage.setRedirect(true);
	        return POPage;
        }
    }

   // Kenandy 3.0 KNDY-133   show a message before allowing a cancel operation, check no receipts
    public Pagereference DoCancelOrder() {
        Purchase_Order__c PO = (Purchase_Order__c)controller.getRecord();
        List<Purchase_Order_Line__c> POLList = new List<Purchase_Order_Line__c> ();
        PO.Status__c = 'Cancelled';

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id poId = PO.Id;
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c'
		});
		soql.setWhereClause('Purchase_Order__c = :poId');

		for (Purchase_Order_Line__c POL : Database.query(soql.getQuery())){
            POL.Status__c = PO.Status__c;
            POLList.add(POL);
        }
 
        Savepoint sp = Database.setSavepoint(); //KNDY-6557 
	    try {
        	DML.updateAsUser( POLList );
        	return controller.save();  
	    }catch (Exception e) {
	            Apexpages.addMessage(new ApexPages.Message(ApexPages.severity.Error, Label.Cannot_cancel_Purchase_Order_due_to_exceptions + MessageUtil.toFriendlyErrorMessage(e.getMessage())));
	           //ApexPages.addMessages(e);
			   system.debug(LoggingLevel.Error, 'Exceptions encounted during PO Cancel: ' + e.getMessage() + ' ' + e.getStackTraceString());
	           Database.rollback(sp);
	           return null;
	   } 
                 
    }
    
    public Boolean hasErrors { get { return ApexPages.hasMessages(); } }
    public void CancelOrder() {
        Purchase_Order__c PO = (Purchase_Order__c)controller.getRecord();
        string errorLines = '';
     	
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id poId = PO.Id;
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Status__c'
		});
		soql.setWhereClause('id = :poId');

		PO = Database.query(soql.getQuery());

        if (PO.Status__c == 'Cancelled') {
                ApexPages.addMessage( new Apexpages.Message(ApexPages.severity.FATAL,
                    Label.Purchase_Order_already_been_Cancelled));
                return;
        }
        
        // Get POLines that cannot be canceled
        List<Purchase_Order_Line__c> poLines = new List<Purchase_Order_Line__c>();
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Name','Quantity_Received__c','Invoice_Matching__c','Order_Quantity__c','Line__c','Quantity_Matched__c'
		});
		soql.setWhereClause('Purchase_Order__c = :poId');
		
		for (List<Purchase_Order_Line__c> lines : Database.query(soql.getQuery())){
            poLines.addAll(lines);             	
        }
        
        List<Purchase_Order_Line__c> errorPOLs = PurchaseOrderService.validatePOLineCancel(poLines);
        for (Purchase_Order_Line__c POL : errorPOLs){
        	errorLines = errorLines + POL.Name + ',';
        }
        
        if (errorLines.length() > 0){
        	errorLines = errorLines.subString(0,errorLines.length()-1);
        	Apexpages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Cannot_cancel_Purchase_Order + errorLines));
        	
        	return;	
        }
    }
}