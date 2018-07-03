@isTest
private class AgreementConsoleExtTest {
    
    static testMethod void testAgreementConsoleExt(){
        
        TestFuel data = new TestFuel();
        Agreement__c ag = data.agreement;
        Agreement_Line__c agl = data.agreementLine;

        ApexPages.StandardController std = new ApexPages.StandardController(ag);
      
        AgreementConsoleExt con = new AgreementConsoleExt(std);

        system.assertEquals(ag, con.agreement);
    }
    
}