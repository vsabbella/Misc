@isTest
private class ReceivingDocumentReleaseExtTest {

    static testMethod void testReceivingDocumentRelease() {
        
        TestFuel testData = new TestFuel();
        
        Receiving_Document__c rd = testData.receivingDocumentMisc;
        
        Test.startTest();
        
        ApexPages.StandardController con = new ApexPages.StandardController(rd);
        ReceivingDocumentReleaseExt rdre = new ReceivingDocumentReleaseExt(con);
        
        rdre.release();
        
        Test.stopTest();
        
        list<Receipt_Line__c> rlList = [ select id, Status__c, Quantity_Still_Due_For_Putaway__c, Receiving_Document__r.Status__c, Quantity_Declared__c From Receipt_Line__c 
                                        where Receiving_Document__c =:rd.id ];
        
        system.assert( rlList.size() == 1 );
        
        Receipt_Line__c rl = rlList[0];
        system.assert( rl.status__c == 'Open', ApexPages.getMessages());
        system.assert( rl.Receiving_Document__r.status__c == 'Open');
        system.assert( rl.Quantity_Still_Due_For_Putaway__c == rl.Quantity_declared__c);
    }
    
    static testMethod void testReceivingDocumentReleaseErrors() {
        
        TestFuel testData = new TestFuel();
        
        Receiving_Document__c rd = testData.receivingDocumentMisc;
        Receipt_Line__c rl = testData.receivingDocumentMiscLines[0];
        rl.Status__c = 'Closed';
        DML.updateAsUser( rl );
        
        Test.startTest();
        
        ApexPages.StandardController con = new ApexPages.StandardController(rd);
        ReceivingDocumentReleaseExt rdre = new ReceivingDocumentReleaseExt(con);
        
        rdre.release();
        system.assert( ApexPages.getMessages().size() == 1, Label.Cannot_release_Receiving_Document );
        
        Test.stopTest();
    }
}