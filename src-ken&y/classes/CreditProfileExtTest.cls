@isTest
public class CreditProfileExtTest{
    public static testmethod void t1() {    
        List<Credit_Profile_Rules__c>  rules = [select Name, AR_Percent_Past_Due__c, Days_Past_Due__c, Percent_Over_Credit__c from Credit_Profile_Rules__c];
        Credit_Profile_Rules__c rule = new Credit_Profile_Rules__c();
        rule.name = 'A';
        rule.AR_Percent_Past_Due__c = 10;
        rule.Days_Past_Due__c = 10;
        rule.Percent_Over_Credit__c = 10;
        insert rule;
        
        Account account = new Account();
        account.name = 'Kenandy';
        account.billingstreet = '303 Twin Dolphin Drive, Suite 500';
        account.billingcity = 'Redwood City';
        account.billingstate = 'CA';
        account.billingpostalcode = '94065';
        account.billingcountry = 'USA';
        account.shippingstreet = '303 Twin Dolphin Drive, Suite 500';
        account.shippingcity = 'Redwood City';
        account.shippingstate = 'CA';
        account.shippingpostalcode = '94065';
        account.shippingcountry = 'USA';
        account.phone = '650-468-2000';
        account.fax = '650-468-2010';
        account.website = 'kenandy.com';
        insert account; 
        
        Company__c company = new Company__c();
        company.name = 'Kenandy';
        company.Address__c = account.ID;
        company.A_Days__c = 30;
        company.B_Days__c = 60;
        company.C_Days__c = 180;
        company.Company_Identifier__c = 'KEN'; 
        company.Comp_Currency__c = TestFuel.currencySGD.id;
        company.Consol_Currency__c = TestFuel.currencyEUR.id;
        company.Stat_Currency__c = TestFuel.currencyGBP.id;
        company.Subs_Currency__c = TestFuel.currencyUSD.id;
        company.Default_Transaction_Currency__c = TestFuel.currencyUSD.id;
        insert company;
        
        
        Test.startTest();
        System.assertNotEquals(null, rules );
        ApexPages.StandardController sc = new ApexPages.StandardController(company);
        
        CreditProfileExt cpExt = new CreditProfileExt(sc);
        cpExt.saveSSCon();
        
        ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(company);
        cpExt = new CreditProfileExt(sc1);
        cpExt.newRule.Name = 'foo';
        cpExt.saveNewRule();
        Test.setCurrentPage( Page.CreditProfileEdit);
        Apexpages.currentPage().getParameters().put('recId', rule.id );
        cpExt.recId = rule.id;
        cpExt.deleteRef();
        system.assert( Apexpages.hasMessages() == false , Apexpages.getMessages() );
        
    }
    
}