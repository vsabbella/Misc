public with Sharing Class ReceivingDocumentCloseExt{
    
    private ApexPages.StandardController con;
            
    public ReceivingDocumentCloseExt(ApexPages.StandardController sc)
    {
         
         con = sc;
    }
    
    public PageReference close(){
        
        try
        {
            ReceivingDocumentService.close(new Set<Id>{con.getId()},'Receipt_Line__c','Receiving_Document__c','Receiving_Document__c',
                                            new list<String>{SkidService2.SKID_TYPE_INTRANSIT}, false, false,'Closed');
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Receiving_Document_has_been_Closed));
        }
        catch( Exception e )
        {
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ' '+ MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        return null; 
    }
}