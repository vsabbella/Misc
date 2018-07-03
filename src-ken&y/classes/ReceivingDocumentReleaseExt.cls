public with sharing class ReceivingDocumentReleaseExt{

    private ApexPages.StandardController con;
            
    public ReceivingDocumentReleaseExt(ApexPages.StandardController sc){
         
         con = sc;
    }
    
    public PageReference release(){
        
        try{
            ReceivingDocumentService.release(new Set<Id>{con.getId()});
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Receiving_Document_has_been_released));
        }
        catch( Exception e ){
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ' '+ MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        return null; 
    }
}