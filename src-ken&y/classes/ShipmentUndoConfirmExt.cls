public with Sharing Class ShipmentUndoConfirmExt{
    
    private ApexPages.StandardController con;
    public Boolean errorFound = false;
    string sourceDocument='';
    string shipmentStatusMessage='';
    public ShipmentUndoConfirmExt(ApexPages.StandardController sc){
         
        con = sc;
        Id shipmentId = con.getId();
         
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Shipment_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','Sales_Order_Line__c','Order_Line__c','shipment__r.status__c', 'shipment__r.type__c','Order__r.Status__c','Sales_Order__r.Status__c','Sales_Order__r.Released_to_3PL__c',
			'Item__r.Packaging_UOM__c'
		});
		soql.setWhereClause('Shipment__c = :shipmentId');
		
		SOQLUtil.ChildRelationship childRel1 = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
		childRel1.addFields(new set<string>{
			'id'
		});
		childRel1.setWhereClause('status__c not in (\'Void\',\'Cancelled\')');
		soql.addChildRelationship(childRel1);
		
		SOQLUtil.ChildRelationship childRel2 = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoice_Lines__r');
		childRel2.addFields(new set<string>{
			'Id'
		});
		childRel2.setWhereClause('Customer_Invoice__r.Status__c != \'Cancelled\' AND Customer_Invoice__r.Status__c != \'Void\'');
		soql.addChildRelationship(childRel2);
		
		Map<id,Shipment_Line__c> shipLines = NEW Map<id,Shipment_Line__c>((List<Shipment_Line__c>)Database.query(soql.getQuery()));

         integer receiptLinesCount = 0;   

         integer linesCICount = 0;
         Boolean invalidshipmentType = false;
         
    	 for(Shipment_Line__c sl:shipLines.values())
    	 {
    		if(sl.Receipt_Lines__r.size()>0)
    			receiptLinesCount += sl.Receipt_Lines__r.size();
    		if(sl.Customer_Invoice_Lines__r.size() > 0)
    			linesCICount += sl.Customer_Invoice_Lines__r.size();
    		if(sl.shipment__r.type__c != 'Transfer Order Shipment' && invalidshipmentType == false){
        		invalidshipmentType = true;
         	}
    	 }
    	 if(invalidshipmentType){
    	 	errorFound = true;
    	 	shipmentStatusMessage = 'You can only undo shipment of type Transfer Order Shipment. Please use Manage Delivery page.';
        	
        	return;
         }
    	 if(linesCICount > 0)  //OTC-518
    	 {
    	 	errorFound = true;
    	 	shipmentStatusMessage = 'The sales order linked to the shipment has been invoiced. This shipment cannot be undone'; 
    	 }
    	 if(receiptLinesCount>0){
        	errorFound = true;
        	shipmentStatusMessage = 'The shipment is partially/fully received. This shipment cannot be undone';
    	 }
    
        if(shipmentStatusMessage=='')
        {
            if(shipLines.values()[0].shipment__r.status__c!='Confirmed' && shipLines.values()[0].shipment__r.status__c!='Delivered')
            {
            	errorFound = true;
            	shipmentStatusMessage = 'The shipment is in '+ shipLines.values()[0].shipment__r.status__c + ' Status. Only Confirmed or Delivered Shipments can be Undone';
            }
            else
            {
            	shipmentStatusMessage ='';
	            if(shipLines.values()[0].Sales_Order_Line__c!=null) 
	            {  
			      	if (shipLines.values()[0].Sales_Order__r.Status__c == 'Open' && shipLines.values()[0].Sales_Order__r.Released_to_3PL__c == true) 
			      	{
			        	errorFound = true;
			        	sourceDocument = 'Sales Order';	            
			        }  
	            }
	            if(shipLines.values()[0].Order_Line__c!=null) 
	            {  
			      	if (shipLines.values()[0].Order__r.Status__c != 'Open') 
			      	{
			      		sourceDocument = 'Transfer Order';
			        	errorFound = true;
			        }  
	            }
            }
        }
    }
    
    public PageReference undoShipConfirm(){
        
        try{
        	if(shipmentStatusMessage!='')
        	{
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, shipmentStatusMessage));
        		return null;
        	}
        	if(errorFound == true && sourceDocument!='Transfer Order'){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.SO_released_to_3PL));
        	}
        	else if(errorFound == true  && sourceDocument=='Transfer Order'){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Transfer Order is CLosed. No Modification allowed.'));
        	}            	
        	else{
            	SalesOrderService sos = new SalesOrderService();
            	sos.undoShipConfirm(new Set<Id>{con.getId()});
            
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Shipment_unconfirmed));
        	}
            
        }
        catch( Exception e ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
			system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        return null; 
    }
}