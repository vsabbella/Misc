public with sharing class TransferOrderCloseExt {
    private ApexPages.StandardController con;
	      
        Public Class TransferOrderException Extends Exception{

        }
        public TransferOrderCloseExt(ApexPages.StandardController sc)
        {
            con = sc;
        }
        
        public Order__c order {get; set;}
        
        public PageReference Close(){
        
        try
        {           
            this.order =   (Order__c)con.getRecord();           
            if(this.order.status__c=='Draft')
            {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Transfer_Order_cannot_be_closed));
                return null;
            }             
            if(this.order.status__c=='Cancelled' || this.order.status__c =='Closed')
            {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Transfer_Order_cancelled_closed));
                return null;
            } 
            Boolean showerror = false;          


            // Order Lines
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id orderId = this.order.Id;
			
			SOQLUtil soql = new SOQLUtil('Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name','Status__c','Quantity_Allocated__c','Quantity_Received__c','Quantity_Shipped__c'
			});
			soql.setWhereClause('Order__c = :orderId');

			List<Order_Line__c> orderLineList = Database.query(soql.getQuery());

            if(orderLineList.size()>0 && showerror == false && this.order.status__c=='Open'){
                List<SKID__c> skidlist = [select id,name from SKID__c where (Shipment_Line__r.Order_Line__c = :orderLineList[0].Id or Order_Line__c=:orderLineList[0].Id) and Type__c In ('Planned Pick', 'Allocated', 'Location','In-Transit')];
                if(skidlist.size()>0){
                    Throw New TransferOrderException(' Unable to close as shipment is not picked yet.');
                }

                ReceivingDocumentService.close(new Set<Id>{con.getId()},'Order_Line__c','Order__c','Order__c',new String[]{'Planned Pick'}, true, false,Label.Closed);
                OrderService.ClearExceptions(orderLineList);            
            }
                        
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Transfer_Order_closed));
        }
        catch( Exception e )
        {            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        return null; 
    }
}