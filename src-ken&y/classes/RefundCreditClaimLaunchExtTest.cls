@isTest
private class RefundCreditClaimLaunchExtTest {
    private static testmethod void  invalidClaimRefundCredit_InvoiceDeduction(){
        Claim__c cl = new Claim__c();
        cl.Source__c = 'Invoice Deduction';
		cl.Amount__c = 100;
        insert cl;
        String expectedErrorMessage = Label.Refund_Credit_Invalid_Claim;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        PageReference p = controller.navigateToRefundCredit();
        Test.stopTest();
        system.assertNotEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size());

    }

    private static testmethod void  invalidClaimRefundCredit_GeneralDeduction(){
        Claim__c cl = new Claim__c();
        cl.Source__c = 'General Deduction';
		cl.Amount__c = 100;
        insert cl;
        String expectedErrorMessage = Label.Refund_Credit_Invalid_Claim;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        PageReference p = controller.navigateToRefundCredit();
        Test.stopTest();
        system.assertNotEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size());

    }

    private static testmethod void  invalidClaimRefundCredit_Manual_0Balance(){
        Claim__c cl = new Claim__c();
        cl.Source__c = 'Manual';
		insert cl;
        cl = [Select Id, Name, Claim_Balance__c, Source__c from Claim__c where Id = :cl.Id];
        system.assertNotEquals(null, cl);
        system.assertEquals(cl.Claim_Balance__c, 0, '>>> cl: ' + cl);

        String expectedErrorMessage = Label.Refund_Credit_Invalid_Claim;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        PageReference p = controller.navigateToRefundCredit();
        Test.stopTest();
        system.assertEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size());
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            if(message.getDetail() == expectedErrorMessage) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }

    private static testmethod void  invalidClaimRefundCredit_Manual_Closed(){
        list<Configuration__c> lConfigs = new list<Configuration__c>();
        lConfigs.add(new Configuration__c(Name = 'Claim__c-'+Claim__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserId()));
        lConfigs.add(new Configuration__c(Name = 'Claim_Line__c-'+Claim_Line__c.getSobjectType().getDescribe().getKeyPrefix(), Value__c = UserInfo.getUserId()));
        insert lConfigs;
        Claim__c cl = new Claim__c();
        cl.Source__c = 'Manual';
        cl.Amount__c = 10;
        //cl.Status__c = 'Closed';
        cl.Settlement_Method__c = 'Automatic';
        cl.Settlement_Date__c = system.today();
        insert cl;

        cl.Status__c = 'Closed';
        update cl;
        delete lConfigs;
        cl = [Select Id, Name, Claim_Balance__c, Source__c from Claim__c where Id = :cl.Id];
        system.assertNotEquals(null, cl);
        system.assertEquals(cl.Claim_Balance__c, 0, '>>> cl: ' + cl);

        String expectedErrorMessage = Label.You_can_settle_only_an_open_claim;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        PageReference p = controller.navigateToRefundCredit();
        Test.stopTest();
        system.assertEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size());
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            if(message.getDetail() == expectedErrorMessage) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }

    // Manaul CLaim with a positive claim balance and claim lines
    // This scenario should not occur in a live environment
    private static testmethod void  invalidClaimRefundCredit_Manual_withLines(){
        // Claim Balance = Amount - total line Amount
        Claim__c cl = new Claim__c();
        cl.Source__c = 'Manual';
        cl.Amount__c = 100;
        insert cl;
        Claim_Line__c clLine = new Claim_Line__c();
        clLine.Claim__c = cl.Id;
        clLine.Total_Amount__c = 10;
        insert clLine;
        cl = [Select Id, Name, Claim_Balance__c, Source__c from Claim__c where Id = :cl.Id];
        system.assertNotEquals(null, cl);
        system.assert(cl.Claim_Balance__c > 0, '>>> cl: ' + cl);

        String expectedErrorMessage = Label.Refund_Credit_Invalid_Claim;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        PageReference p = controller.navigateToRefundCredit();
        Test.stopTest();
        system.assertEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size());
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            if(message.getDetail() == expectedErrorMessage) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }

   // Manaul CLaim with a positive claim balance and no claim lines
    private static testmethod void validClaimRefundCredit_Manual_NoLines(){
        // Claim Balance = Amount - total line Amount
        Claim__c cl = new Claim__c();
        cl.Source__c = 'Manual';
        cl.Amount__c = 100;
        insert cl;
        cl = [Select Id, Name, Claim_Balance__c, Source__c from Claim__c where Id = :cl.Id];
        system.assertNotEquals(null, cl);
        system.assert(cl.Claim_Balance__c > 0, '>>> cl: ' + cl);

        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        PageReference p = controller.navigateToRefundCredit();
        Test.stopTest();
        system.assertNotEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size());
    }

    // Page has no error messages
    private static testmethod void returnToClaim_Success(){
        Claim__c cl = new Claim__c();
        cl.Source__c = 'Manual';
        insert cl;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        PageReference p = controller.returnToClaim();
        Test.stopTest();
        system.assertNotEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size());
    }

    // Page has an error message
    private static testmethod void  returnToClaim_Failure(){
        Claim__c cl = new Claim__c();
        cl.Source__c = 'Manual';
        insert cl;
        String expectedErrorMessage = Label.Refund_Credit_Invalid_Claim;
        Test.startTest();
        PageReference pageRef = Page.RefundCreditClaimLaunchingPage;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(cl);
        RefundCreditClaimLaunchExt controller = new RefundCreditClaimLaunchExt(stdController);
        // Add a dummy error message on page
        ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR,label.Refund_Credit_Invalid_Claim));
        PageReference p = controller.returnToClaim();
        Test.stopTest();
        system.assertEquals(p, null, '>>> p: ' + p);
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size());
        Boolean messageFound = false;
        for(ApexPages.Message message : pageMessages) {
            if(message.getDetail() == expectedErrorMessage) {
                messageFound = true;
            }
        }
        System.assert(messageFound);
    }
}