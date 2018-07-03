public with sharing class RefundCreditInvoiceLaunchExt {
    
    ApexPages.StandardController stdcon;
    public string theCustomerInvoiceId;
    public string CustomerInvoiceName { get; private set; }
    public sObject tmpsObj;
    public RefundCreditInvoiceLaunchExt(ApexPages.StandardController controller){
        stdcon = controller;
        tmpsObj = stdcon.getRecord() ;
        theCustomerInvoiceId = String.valueof((Id) tmpsObj.get('Id'));
    }
    
    // pass the id ( one or more ) as parameter to the navigated Page
    public PageReference navigateToRefundCredit() { 
        
        boolean inValidCI = false;
        PageReference p = Page.RefundCreditManage;
        
        system.debug('theCustomerInvoiceId'+theCustomerInvoiceId);
        if(stdcon != null && String.isBlank( theCustomerInvoiceId ) == false){
            inValidCI = validateTheCustomerInvoice( theCustomerInvoiceId ); // inValidCI is true, for the not eligible CI
            if( !inValidCI ){ 
                p.getParameters().put('ciId', theCustomerInvoiceId);
                p.getParameters().put('launchTab', 'tab2'); //differentiating parameter, for the launch on tab2 on the RC workbench
            }    
        }
       
        if( !inValidCI )
          return p.setRedirect(false);
        else
          return null; 
    }
    
    private boolean validateTheCustomerInvoice( String theCustomerInvoiceId ){
        
        boolean validFlag = false;
        if( String.isBlank( theCustomerInvoiceId ) == false ){
            SOQLUtil soql = new SOQLUtil( 'Customer_Invoice__c', true ); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Customer__c','Bill_To_Customer__c','Balance__c','Invoice_Type__c','Finalized__c','Total_Amount__c','Void__c','Status__c','Customer_Receipt__c',
                'Customer_Receipt__r.Transaction_ID__c','Customer_Receipt__r.Payment_Method_3__c'
            });
            soql.setWhereClause( 'Id = :theCustomerInvoiceId' );
            soql.setLimit(1);
            
            List<Customer_Invoice__c> custInvoiceLst = Database.query(soql.getQuery());
            
            if (custInvoiceLst.size() > 0){
                
               CustomerInvoiceName = 'Return to ' + custInvoiceLst[0].Name;   
               if( custInvoiceLst[0].Total_Amount__c > 0 || custInvoiceLst[0].Void__c == true || custInvoiceLst[0].Finalized__c == false || custInvoiceLst[0].Status__c == 'Closed' || custInvoiceLst[0].Status__c == 'Cancelled'  ){
                   validFlag = true;
                   //pageMessages(Label.Refund_Credit_Invalid_Customer_Invoice,'ERROR');
                   ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,Label.Refund_Credit_Invalid_Customer_Invoice)); 
               }else if(custInvoiceLst[0].Customer_Receipt__c != null && custInvoiceLst[0].Customer_Receipt__r.Transaction_ID__c != null && custInvoiceLst[0].Customer_Receipt__r.Payment_Method_3__c != null){
                     if(!RefundCreditService.getCITransactionStatus(Id.valueOf(theCustomerInvoiceId))){ // if the transaction on the CI is not settled Successfully show error 
                       validFlag = true;
                       //pageMessages(Label.Refund_Credit_Unsettled_Transaction,'ERROR');
                       ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,Label.Refund_Credit_Unsettled_Transaction));      
                    }    
               }    
            }
        }
        return validFlag;
    }
    
    // return behaves different on standardcontroller(detail page)
    public Pagereference returnToCI() {  
        
        if ( Apexpages.hasMessages(Apexpages.severity.FATAL)|| Apexpages.hasMessages(Apexpages.severity.WARNING) || Apexpages.hasMessages(Apexpages.severity.ERROR)) { 
                
                return null;
        }else{
            
             return new PageReference( '/' +theCustomerInvoiceId );   
        }
    }     
    
}