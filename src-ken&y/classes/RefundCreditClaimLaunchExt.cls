public with sharing class RefundCreditClaimLaunchExt {
    ApexPages.StandardController stdcon;
    public string theClaimId;
    public string claimName { get; private set; }

    public RefundCreditClaimLaunchExt(ApexPages.StandardController controller){
        stdcon = controller;
        sObject tmpsObj = stdcon.getRecord() ;
        theClaimId = String.valueof((Id) tmpsObj.get('Id'));
    }
    
    // pass the id ( one or more ) as parameter to the navigated Page
    public PageReference navigateToRefundCredit() {        
        boolean isValidClaim = false;
        system.debug(logginglevel.error,'theClaimId'+theClaimId);
        if(stdcon != null && !String.isBlank( theClaimId )){
            isValidClaim = validateTheClaim( theClaimId );
            System.debug(logginglevel.error,'isValidClaim-->'+isValidClaim);
        }

        if( !isValidClaim){
          return null;
        }else{
          PageReference p = Page.RefundCreditManage;
          p.getParameters().put('claimId', theClaimId);
          return p.setRedirect(true);
        }
    }

    // Assumption: parameter not null, and claim exists
    private boolean validateTheClaim( String theClaimId ){
        boolean validFlag = true;
        try{
            system.assert(!String.isBlank( theClaimId ));
            SOQLUtil soql = new SOQLUtil( 'Claim__c', true ); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'Id','Name','Source__c', 'Claim_Balance__c','Status__c'
            });
            soql.setWhereClause( 'Id = :theClaimId' );
            SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Claim_Lines__r');
            childRel.addFields(new set<string>{
                'Id','Name'
            });
            soql.addChildRelationship(childRel);
            List<Claim__c> claimList = Database.query(soql.getQuery());
            system.debug(logginglevel.error,'claimList-->'+claimList);
            system.assertEquals(claimList.size(), 1, '>>> claimList: ' + claimList);
            claimName = 'Return to ' + claimList[0].Name;

            if(claimList[0].Status__c == 'Closed') {
                validFlag = false;
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,label.You_can_settle_only_an_open_claim));
            }
            else if( claimList[0].Claim_Balance__c <= 0 ||
               (claimList[0].Claim_Lines__r != null && claimList[0].Claim_Lines__r.size() != 0) ){
                validFlag = false;
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,label.Refund_Credit_Invalid_Claim));
            }
        }
        catch (Exception ex){
            validFlag = false;
            ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }
        return validFlag;
    }

    public Pagereference returnToClaim() {
        if ( Apexpages.hasMessages(Apexpages.severity.FATAL)|| Apexpages.hasMessages(Apexpages.severity.WARNING) || Apexpages.hasMessages(Apexpages.severity.ERROR)) {
                return null;
        }else{
             return new PageReference( '/' +theClaimId );
        }
    }
}