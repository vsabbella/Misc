public with Sharing Class PurchaseOrderCloseExt{
    
    private ApexPages.StandardController con;
            
    public PurchaseOrderCloseExt(ApexPages.StandardController sc){
         
         con = sc;
    }
    
    public PageReference close(){
        
        if ( PurchaseOrderService.CheckForInvoicesOnHeaderClose(con.getId()).size() > 0 ){

            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.Cannot_close_purchase_order_lines));
            return null;
        }

        try{
            ReceivingDocumentService.close(new Set<Id>{con.getId()},'Purchase_Order_Line__c','Purchase_Order__c','Purchase_Order__c',
                                            new list<String>{SkidService2.SKID_TYPE_PO_SUPPLY}, false, false,'Closed');
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Purchase_Order_has_been_Closed));
        }
        catch( Exception e ){
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ' '+ MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        return null; 
    }
}