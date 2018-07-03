public with sharing class TransferOrderCloneExt {
    ID orderID;
    public string redirectToRecordId{get;set;}
    private ApexPages.StandardController controller;
    
    public TransferOrderCloneExt(ApexPages.StandardController c) {
        controller = c;
        orderID = controller.getRecord().id;
    }
    
     public void Save(){
     
        Order__c oldTO = new Order__c();
        Order__c newTO = new Order__c();
        List<Order_Line__c> TOLList = new List<Order_Line__c> ();
        
        oldTO = (Order__c)controller.getRecord();    
        newTO = oldTO.clone(false,true);
        
        newTO.Status__c = Orderservice.O_STATUS_DRAFT;        
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            DML.insertAsUser(newTO);
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Shipping_Company__c','Receiving_Company__c','Description__c','Shipping_Item__c','Receiving_Item__c','Quantity_Backordered__c',
				'Quantity_Ordered__c','Quantity_Shipped__c','Ship_From_Location__c','Deliver_To_Location__c','Ship_From_Facility__c','Deliver_To_Facility__c',
				'Required_Date__c','Order__c','Status__c'
			});
			soql.setWhereClause('Order__c = \'' + oldTO.Id + '\'');

			for (Order_Line__c oldTOLObject : Database.query(soql.getQuery())){
                Order_Line__c newTOLObject = new Order_Line__c();          
                newTOLObject = oldTOLObject.clone(false,true);
                newTOLObject.Quantity_Shipped__c = 0;
                newTOLObject.Quantity_Backordered__c = 0;
                newTOLObject.Order__c = newTO.ID;
                
                
                if(newTO.Shipping_Company__c!=null)
                    newTOLObject.Shipping_Company__c = newTO.Shipping_Company__c;
                
                if(newTO.Receiving_Company__c!=null)
                    newTOLObject.Receiving_Company__c = newTO.Receiving_Company__c;
                    
                if(newTO.Ship_From_Location__c!=null)
                    newTOLObject.Ship_From_Location__c = newTO.Ship_From_Location__c;
                
                if(newTO.Deliver_To_Location__c!=null)
                    newTOLObject.Deliver_To_Location__c = newTO.Deliver_To_Location__c;
                    
                if(newTO.Ship_From_Facility__c!=null)
                    newTOLObject.Ship_From_Facility__c = newTO.Ship_From_Facility__c;
                    
                if(newTO.Deliver_To_Facility__c!=null)
                    newTOLObject.Deliver_To_Facility__c = newTO.Deliver_To_Facility__c;
                    
                if(newTO.Need_Date__c!=null)
                    newTOLObject.Required_Date__c = newTO.Need_Date__c;
                    
                if(newTO.Order_Date__c!=null)
                    newTOLObject.Required_Date__c = date.valueof(newTO.Order_Date__c);
                
                newTOLObject.Status__c = Orderservice.O_STATUS_DRAFT;
                                 
                TOLList.add(newTOLObject);
            }            
            DML.insertAsUser(TOLList);
            
            }
        catch (DmlException e) {
           ApexPages.addMessages(e);
           Database.rollback(sp);
           return;
        }

        redirectToRecordId =(String) newTO.Id;
        return ;
    }

    
}