@isTest
private class ClaimRejectExtTest {

    static testMethod void testRejectClaimGeneralDeduction_Error() {
        List<Reason_Code__c> resolutions = new list<Reason_Code__c>();
        resolutions.add(new Reason_Code__c(name = 'Damage',type__c = 'Resolution'));
        insert resolutions;
        Claim__c c =new Claim__c(Amount__c = 10, Status__c ='Open', Source__c ='General Deduction',Resolution_Code__c = resolutions[0].Id);
        insert c;
        Test.startTest();      
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
        ClaimRejectExt ext = new ClaimRejectExt(con); 
        ext.reject();
        system.assertEquals(ext.disableAction,true, 'The claim should fail validation - ' + Apexpages.getMessages());        
        system.assertEquals(ext.canReject,false);
        system.assertEquals( Apexpages.hasMessages(), true );
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
            System.assertEquals(Label.You_can_reject_only_a_claim_with_a_manual_source, msg.getSummary());          
        }       
        Test.stopTest();
    }
    static testMethod void testRejectClaimInvoiceDeduction_Error() {
        List<Reason_Code__c> resolutions = new list<Reason_Code__c>();
        resolutions.add(new Reason_Code__c(name = 'Damage',type__c = 'Resolution'));
        insert resolutions;
        Claim__c c =new Claim__c(Amount__c = 10, Status__c ='Open', Source__c ='Invoice Deduction',Resolution_Code__c = resolutions[0].Id);
        insert c;
        Test.startTest();      
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
        ClaimRejectExt ext = new ClaimRejectExt(con); 
        ext.reject();
        system.assertEquals(ext.disableAction,true, 'The claim should fail validation - ' + Apexpages.getMessages());
        system.assertEquals(ext.canReject,false);
        system.assertEquals( Apexpages.hasMessages(), true );
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
            System.assertEquals(Label.You_can_reject_only_a_claim_with_a_manual_source, msg.getSummary());          
        }       
        Test.stopTest();
    }
    static testMethod void testRejectClosedClaim_Error() {
        List<Reason_Code__c> resolutions = new list<Reason_Code__c>();
        resolutions.add(new Reason_Code__c(name = 'Damage',type__c = 'Resolution'));
        insert resolutions;
        
        //Turn triggers off to insert test data claims
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Claim__c-'+Claim__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        //Manual Claim
        Claim__c c =new Claim__c(Amount__c = 10, Status__c ='Closed', 
                                 Source__c ='Manual',Resolution_Code__c = resolutions[0].Id,
                                Settlement_Method__c = 'Refund');
        insert c;
        Test.startTest();      
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
        ClaimRejectExt ext = new ClaimRejectExt(con); 
        ext.reject();
        system.assertEquals(ext.disableAction,true, 'The claim should fail validation - ' + Apexpages.getMessages());
        system.assertEquals(ext.canReject,false);
        system.assertEquals( Apexpages.hasMessages(), true );
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
            System.assertEquals(Label.Claim_is_closed, msg.getSummary());          
        }       
        Test.stopTest();
    }
    static testMethod void testRejectCancelledClaim_Error() {
        List<Reason_Code__c> resolutions = new list<Reason_Code__c>();
        resolutions.add(new Reason_Code__c(name = 'Damage',type__c = 'Resolution'));
        insert resolutions;
        
        //Turn triggers off to insert test data claims
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Claim__c-'+Claim__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        //Manual Claim
        Claim__c c =new Claim__c(Amount__c = 10, Status__c ='Cancelled', 
                                 Source__c ='Manual',Resolution_Code__c = resolutions[0].Id,
                                Settlement_Method__c = 'Refund');
        insert c;
        Test.startTest();      
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
        ClaimRejectExt ext = new ClaimRejectExt(con); 
        ext.reject();
        system.assertEquals(ext.disableAction,true, 'The claim should fail validation - ' + Apexpages.getMessages());
        system.assertEquals(ext.canReject,false);
        system.assertEquals( Apexpages.hasMessages(), true );
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
            System.assertEquals(Label.Claim_is_closed, msg.getSummary());          
        }       
        Test.stopTest();
    }
    
    static testMethod void testRejectOpenClaimWithLines_Error() {
        List<Reason_Code__c> resolutions = new list<Reason_Code__c>();
        resolutions.add(new Reason_Code__c(name = 'Damage',type__c = 'Resolution'));
        insert resolutions;
        
        //Turn triggers off to insert test data claims
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Claim__c-'+Claim__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
           lConfigs.add(new Configuration__c(Name = 'Claim_Line__c-'+Claim_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));        
        insert lConfigs;
        
        //Manual Claim
        Claim__c c =new Claim__c(Amount__c = 10, Status__c ='Open', 
                                 Source__c ='Manual',Resolution_Code__c = resolutions[0].Id,
                                Settlement_Method__c = 'Refund');
        insert c;
        // Claim lines
        Claim_Line__c cl = new Claim_Line__c(Resolution_Code__c = c.Resolution_Code__c,
                                Reason_Code__c = c.Resolution_Code__c,
                                Claim__c= c.Id,
                                Total_Amount__c= c.Amount__c);
        insert cl;
        Test.startTest();      
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
        ClaimRejectExt ext = new ClaimRejectExt(con); 
        ext.reject();
        system.assertEquals(ext.disableAction,true, 'The claim should fail validation - ' + Apexpages.getMessages());
        system.assertEquals(ext.canReject,false);
        system.assertEquals( Apexpages.hasMessages(), true );
        for(ApexPages.Message msg :  ApexPages.getMessages()) {
            System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
            System.assertEquals(Label.You_can_t_reject_this_manual_claim_because_it_has_at_least_one_line, msg.getSummary());          
        }       
        Test.stopTest();
    }
    static testMethod void testRejectClaimNoResolutionCode() {
        List<Reason_Code__c> resolutions = new list<Reason_Code__c>();
        resolutions.add(new Reason_Code__c(name = 'Damage',type__c = 'Resolution'));
        insert resolutions;
        
        //Turn triggers off to insert test data claims
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Claim__c-'+Claim__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        //Manual Claim
        Claim__c c =new Claim__c(Amount__c = 10, Status__c ='Open', 
                                 Source__c ='Manual',Resolution_Code__c = null,
                                Settlement_Method__c = 'Refund');
        insert c;
        Test.startTest();      
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
        ClaimRejectExt ext = new ClaimRejectExt(con); 
        ext.reject();
        // Cannot be rejected without a resolution code
        system.assertEquals(ext.disableAction,true, 'The claim should fail validation - ' + Apexpages.getMessages());
        system.assertEquals(ext.canReject,true);
        // No error messages on page
        system.assertEquals( Apexpages.hasMessages(), false );
        Test.stopTest();
    }
    
    static testMethod void testRejectClaimWithResolutionCode_Success() {
        List<Reason_Code__c> resolutions = new list<Reason_Code__c>();
        resolutions.add(new Reason_Code__c(name = 'Damage',type__c = 'Resolution'));
        insert resolutions;
        
        //Turn triggers off to insert test data claims
        User currentUser = [select Id from User where Id = :UserInfo.getUserId() limit 1];
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Claim__c-'+Claim__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = currentUser.id));
        insert lConfigs;
        
        //Manual Claim
        Claim__c c =new Claim__c(Amount__c = 10, Status__c ='Open', 
                                 Source__c ='Manual',Resolution_Code__c = resolutions[0].Id,
                                Settlement_Method__c = null);
        insert c;
        Test.startTest();      
        Apexpages.Standardcontroller con = new Apexpages.Standardcontroller(c);
        ClaimRejectExt ext = new ClaimRejectExt(con); 
        ext.reject();

        // No error messages on page
        system.assertEquals( Apexpages.hasMessages(), false );
        c =[Select Id, Settlement_Method__c,Settlement_Date__c, Status__c, Amount__c,Resolution_Code__c, Related_Claim__c,
             (select Id, Name, Resolution_Code__c, Reason_Code__c, Total_Amount__c from Claim_Lines__r)
           from Claim__c where Id = :c.Id];
        system.assertEquals(c.Status__c,ClaimService.STATUS_CLOSED, c);
        system.assertEquals(c.Settlement_Method__c,ClaimService.SETTLEMENT_METHOD_REJECTED, c);
        system.assertNotEquals(c.Settlement_Date__c,null, c);
        system.assertEquals(c.Claim_Lines__r.size(), 1);
        Claim_Line__c cl = c.Claim_Lines__r[0];
        system.assertEquals(cl.Resolution_Code__c,c.Resolution_Code__c, cl);  
        system.assertEquals(cl.Reason_Code__c,c.Resolution_Code__c, cl); 
        system.assertEquals(cl.Total_Amount__c,c.Amount__c, cl); 
        Test.stopTest();
    }
}