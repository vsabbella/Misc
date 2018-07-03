public with sharing class PurchaseAgreeementCloseCancelExt {

    private Contract__c con;
    private ContractService cs;
    private string CancelCloseStatus {get;set;}

    public PurchaseAgreeementCloseCancelExt(ApexPages.StandardController controller) {
        con = (Contract__c)controller.getrecord();
        cs = new ContractService();
    }
    
    public PageReference Close(){

        CancelCloseStatus = cs.ClosePurchaseAgreement(con.ID);
        if (CancelCloseStatus.contains('Closed!'))
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, CancelCloseStatus));
        else
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, CancelCloseStatus));
                
        return null;
    }
    
    public PageReference Cancel(){
    
        CancelCloseStatus = cs.CancelPurchaseAgreement(con.ID);
        if (CancelCloseStatus.contains('has been Cancelled!'))
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, CancelCloseStatus));
        else
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, CancelCloseStatus));
                
        return null;
    }

}