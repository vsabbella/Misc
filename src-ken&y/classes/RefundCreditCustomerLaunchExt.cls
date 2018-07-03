public with sharing class RefundCreditCustomerLaunchExt {
    
    ApexPages.StandardController stdcon;
    public string theCustomerId;
    public string CustomerName { get; private set; }
    public sObject tmpsObj;
    public RefundCreditCustomerLaunchExt(ApexPages.StandardController controller){
        stdcon = controller;
        tmpsObj = stdcon.getRecord() ;
        theCustomerId = String.valueof((Id) tmpsObj.get('Id'));
    }
    
    // pass the id ( one or more ) as parameter to the navigated Page
    public PageReference navigateToRefundCredit() { 
        
        boolean inValidCustomer = false;
        PageReference p = Page.RefundCreditManage;
        
        system.debug('theCustomerId'+theCustomerId);
        if(stdcon != null && String.isBlank( theCustomerId ) == false){  
            inValidCustomer = validateTheCustomer( theCustomerId );  // inValidCustomer is true for a not eligible customer type.
            System.debug(logginglevel.error,'inValidCustomer-->'+inValidCustomer); 
            if( !inValidCustomer ){
                System.debug(logginglevel.error,'theCustomerId-->'+theCustomerId);   
                p.getParameters().put('cuId', theCustomerId);
            }    
        }
       
        if( !inValidCustomer )
          return p.setRedirect(false);
        else
          return null; 
    }
    
    private boolean validateTheCustomer( String theCustomerId ){
        
        boolean validFlag = false;
        if( String.isBlank( theCustomerId ) == false ){
            SOQLUtil soql = new SOQLUtil( 'Customer__c', true ); //enforceFLS=true, running in user mode  
            soql.addFields(new set<string>{
                'Id','Name','RecordType.Name'
            });
            soql.setWhereClause( 'Id = :theCustomerId' );
            soql.setLimit(1);
            
            List<Customer__c> customerList = Database.query(soql.getQuery());
            system.debug(logginglevel.error,'customerList-->'+customerList);
            if (customerList.size() > 0){
                
               CustomerName = 'Return to ' + customerList[0].Name;   
               if( customerList[0].RecordType.Name == 'Ship To' || customerList[0].RecordType.Name == 'Site' || customerList[0].RecordType.Name == 'Sold To' ){
                   validFlag = true;
                   //pageMessages(label.Refund_Credit_Invalid_Customer,'ERROR'); 
                   ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,label.Refund_Credit_Invalid_Customer));
               }  
            }
        }
        return validFlag;
    }
    
    // return behaves different on standardcontroller(detail page)
    public Pagereference returnToCustomer() {  
        
        if ( Apexpages.hasMessages(Apexpages.severity.FATAL)|| Apexpages.hasMessages(Apexpages.severity.WARNING) || Apexpages.hasMessages(Apexpages.severity.ERROR)) { 
                
                return null;
        }else{
            
             return new PageReference( '/' +theCustomerId );   
        }
    }     
    
}