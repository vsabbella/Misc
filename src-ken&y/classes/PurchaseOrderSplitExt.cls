public with sharing class PurchaseOrderSplitExt {
	/* 
	 * spilt a production purchase order into a shipment order, decrementing the values on the production order
	 */
	private ApexPages.StandardController controller;
	
    public boolean setuperror {get; private set;} { setuperror = false; } 
    
    public PurchaseOrderSplitExt (ApexPages.StandardController c) {        
    	controller = c;    
    	Purchase_Order__c po = (Purchase_Order__c)controller.getRecord();
    	OrderLines = new List<OrderLine>(); 
    	for ( Purchase_Order_Line__c tmp : getLines() ) {
    		OrderLines.add ( new OrderLine( tmp) );
    	}
    	
    	if ( po.type__c != 'Production') {
    		 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 
					Label.ShipmentOrders_created_from_production_PurchaseOrders));
    		setuperror = true;
    	}
    	if ( po.Status__c != 'Open') {
    		 ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 
					Label.ShipmentOrders_created_from_open_production_PurchaseOrders));
    		setuperror = true;
    	}
    }
    
    public List<OrderLine> OrderLines {get; set; }  
    
	public class OrderLine { 
		public decimal Quantity_To_Split {get; set; }
		public boolean selected { get; set; }  
		public Purchase_Order_Line__c poLine {get; set; } 
		public OrderLine(Purchase_Order_Line__c p ) { poLine = p; Quantity_To_Split = 0; } 
	} 
	
	public PageReference saveChild() { 
		
		// first verify that there were some lines entered, or thow a message
		integer have_a_line = 0;
		for ( OrderLine ol : OrderLines) {
			if ( ol.Quantity_To_Split > 0 ) {				have_a_line++;			}		
		}
		if ( have_a_line == 0 ) {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 
					Label.No_quantity_to_allocate_to_the_new_Purchase_order));
			return null;
		}
		
		// ready to go...
		// split info from the header and the lines selected / edited into a new order ( like a clone but receives quantity )
		Purchase_Order__c oldPO = (Purchase_Order__c)controller.getRecord();    
        Purchase_Order__c newPO = oldPO.clone(false,true);
        
        newPO.Approval_Status__c = 'Pending Authorization';
        newPO.Date_Closed__c = null;
        newPO.Order_Date__c = system.today();
        newPO.Status__c = 'Open';    
        newPO.Production_Purchase_Order__c = oldPO.id;
        newPO.Type__c = 'Shipment'; 
        newPO.Delivery_Location__c = oldPO.Delivery_Location__c; // this is bound to the page , snag it here

        Savepoint sp = Database.setSavepoint();
        
        try {
        		List<Purchase_Order_Line__c> POLListOrig = new List<Purchase_Order_Line__c> ();
        		List<Purchase_Order_Line__c> POLListNew = new List<Purchase_Order_Line__c> ();
        		
            	DML.insertAsUser( new list<sobject>{ newPO } );
         
	        	for ( OrderLine ol : OrderLines ) {
	        		
	        		if ( ol.Quantity_To_Split == 0.0 ) { continue; }
	        		
	        		Purchase_Order_Line__c oldPOLobject = ol.poLine;
	        		Purchase_Order_Line__c newPOLObject = oldPOLObject.clone(false,true);
		            	            
	        		if ( ol.Quantity_To_Split > oldPOLobject.Quantity_Still_Due__c ) { 
		        		// over allocated, bad...
		        		throw new QuantityException (Label.Cannot_ship_greater_than_Quantity_Still_Due);
		        	}
		        	
        			newPOLObject.Date_Added__c = system.today();
				newPOLObject.Date_Closed__c = null;
				newPOLObject.Date_Last_Changed__c = system.today();
				newPOLObject.MRP_Plan__c = null;           
				newPOLObject.Purchase_Order__c = newPO.ID;
				newPOLObject.Quantity_Returned_to_Supplier__c = 0.0;
				newPOLObject.Status__c = 'Open';
				newPOLObject.Order_Quantity__c = ol.Quantity_To_Split;
				newPOLObject.Quantity_Received__c = 0.0;
				newPOLObject.Primary_Key__c = null; // if the original had this field , we cannot carry it forward, it's a unique field
				
    				// infact, all Shipment lines for a Shipment order are set to a single location, got it?
		        	newPOLObject.Delivery_Location__c = oldPO.Delivery_Location__c;
		        	
		        POLListNew.add(newPOLObject);
		        	
		        	// now modify the old lines and update them also....
		        	oldPOLobject.Quantity_Received__c = KSE.addQuantityToField( oldPOLobject.Quantity_Received__c , ol.Quantity_To_Split );
		        	 
	        		POLListOrig.add(oldPOLobject); 
	        	}

			DML.updateAsUser( POLListOrig );
	        	DML.insertAsUser( POLListNew );  // update the old lines and insert the new lines 
	      	
        } catch (Exception e) {
	        	ApexPages.addMessages(e); 
	        	Database.rollback(sp);
        		return null;
        }
		
		// take them to the new record
		return new Apexpages.Standardcontroller( newPO ).view();
	}
	
	public class QuantityException extends Exception {} 
	
	private List<Purchase_Order_Line__c> getLines() { 

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id conId = controller.getId();
		
		SOQLUtil soql = new SOQLUtil('Purchase_Order_Line__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'SystemModstamp','Name','LastModifiedDate','LastModifiedById','Unit_Price__c','Type__c','Currency__c',
			'Suppliers_Part_Description__c','Supplier_Part__c','Status__c','Special_Notes__c','Rush_Line__c','Requisition_Number__c',
			'Quantity_Still_Due__c','Quantity_Returned_to_Supplier_for_Credit__c','Quantity_Returned_to_Supplier__c','Quantity_Received__c',
			'Purchase_UOM__c','Purchase_Order__c','Purchase_Order_Number__c','Promise_Date__c','Primary_Key__c','Overage_Quantity__c',
			'Overage_Percentage__c','Order_Quantity__c','Need_Date__c','Manufacturers_Part__c','MRP_Plan__c','Line__c','Line_Value__c',
			'Latest_Promise_Date__c','Item__c','Item_Name__c','Indirect__c','Description__c','Delivery_Location__c','Days_from_Promised__c',
			'Date_Last_Changed__c','Date_Closed__c','Date_Added__c','Company__c'
		});
		soql.setWhereClause('Purchase_Order__c = :conId');
		soql.setOrderByClause('Line__c asc');

		return Database.query(soql.getQuery());

	}
	
}