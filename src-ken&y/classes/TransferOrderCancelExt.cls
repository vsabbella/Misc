public with sharing class TransferOrderCancelExt {
    private ApexPages.StandardController con;
              
        public TransferOrderCancelExt(ApexPages.StandardController sc)
        {
            con = sc;
        }
        
        public Order__c order {get; set;}
        
        public PageReference Cancel(){
        
        try
        {           
            this.order =   (Order__c)con.getRecord();           
                        
            if(this.order.status__c=='Cancelled' || this.order.status__c =='Closed')
            {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Transfer_Order_cancelled_closed));
                return null;
            } 
            Boolean showerror = false;          
            
            //Cancel Order Lines
            
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			Id orderId = this.order.Id;
			SOQLUtil soql = new SOQLUtil('Order_Line__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Name','Status__c','Quantity_Allocated__c','Quantity_Received__c','Quantity_Shipped__c'
			});
			soql.setWhereClause('Order__c = :orderId');

			List<Order_Line__c> orderLineList = Database.query(soql.getQuery());

            for(Order_Line__c oline: orderLineList){ 
                if(oline.Quantity_Allocated__c >0 || oline.Quantity_Received__c >0 || oline.Quantity_Shipped__c >0){
                    showerror = true;
                    break;
                }               
                System.debug('After break');
            }
            if(orderLineList.size()>0 && showerror == true){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Transfer_Order_cannot_be_cancelled));
                return null;
            }
                        
            if(orderLineList.size()>0 && showerror == false){
                ReceivingDocumentService.close(new Set<Id>{con.getId()},'Order_Line__c','Order__c','Order__c',null, true, false,'Cancelled');               
            }
                        
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Transfer_Order_cancelled));
            
        }
        catch( Exception e )
        {            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        return null; 
    }
}