@isTest
public with sharing class TestExtensions2 {
    public static TestFuel data = new TestFuel();
    static Work_Order__c workorder1 = new Work_Order__c(); 
    
    

    public static testmethod void test_companydefault() { // company default extension test
        // CompanyDefaultExt.cls 
        CompanyDefaultExt con = new CompanyDefaultExt( 
            new Apexpages.Standardcontroller( new Customer_Receipt__c() ));
        system.assert( con != null );
             
    }
    
    public static void createWorkOrder() {
        workorder1.Company__c = data.company.id;
        workorder1.Status__c = 'Draft';
        workorder1.Assembly_Item_Specification__c = data.assembly.id;
        workorder1.Start_Date2__c = System.today();
        workorder1.Need_Date2__c = System.today() + 30;
        workorder1.Order_Quantity__c = 22;
        workorder1.Facility__c = data.facility2.Id;
        insert workorder1;
    }
    
}