/**
 * Test cases for Pick Assignment
 */
@isTest
public with sharing class PickAssignmentTest {
    @testSetup
    static void setupData() {


        List<Skid__c> skids = new List<Skid__c>();
        TestFuel data = new TestFuel();



        User_Preference__c up= new User_Preference__c(default_company__c= data.company.id,default_facility__c=data.facility.id);
        Insert up;

        Shipment__c shipment1 = new Shipment__c();
        shipment1.Company__c = data.company.id;
        shipment1.Date_Shipped__c = system.now();
        shipment1.Transaction_Date__c = system.now();
        shipment1.Currency__c = TestFuel.currencyUSD.id;
        shipment1.Status__c = 'Confirmed';
        insert shipment1;

        Shipment_Line__c shipLine1 = new Shipment_Line__c();
        shipLine1.Company__c = data.company.id;
        shipLine1.Facility__c= data.facility.id;
        shipLine1.Extended_Cost__c = 5;
        shipLine1.Quantity_Planned__c = 5;
        shipLine1.Quantity_Allocated__c = 0;
        shipLine1.Quantity_To_Pick__c = 0;
        shipLine1.Quantity_Picked__c = 0;
        shipLine1.Quantity_Shipped__c = 5;
        shipLine1.Sales_Order__c = data.salesOrder.id;
        shipLine1.Sales_Order_Line__c = data.SalesOrderLines[0].id;
        shipLine1.Unit_Price__c = 25;
        shipLine1.Item__c = data.product.Item__c;
        shipLine1.Product__c = data.product.id;
        shipLine1.Location__c = data.location.id;
        shipLine1.Shipment__c = shipment1.id;
        shipLine1.Line_Type__c = null;
        shipLine1.Subtransaction_Type__c = 'Goods';
        insert shipLine1;

        SKID__c skid = new SKID__c();
        skid.location__c = data.location3.id;  // this is STOCK
        skid.Company__c= data.company.id;
        skid.Quantity__c = 200.0;
        skid.Quantity_Stocking_UOM__c = 200.0;
        skid.Item__c= data.itemList[0].Id;
        skid.Type__c = SkidService3.SKID_TYPE_PLANNED;
        skid.Expiration_Date__c = System.today() + 30;
        skid.Packaging_UOM__c =data.uomList[8].Id;
        skid.Stocking_UOM__c = data.uomList[8].Id;
        skid.Shipment_Line__c = shipLine1.id;
        insert skid;

    }
    static TestFuelQuery fuel = new TestFuelQuery();

    static testMethod void testPickAssignment () {
        Test.setCurrentPage(Page.PickAssignment);
        PickAssignmentExt ext = new PickAssignmentExt();
        system.assert( ext.nameSpaceUU != null );
        system.assert(ext.gridFieldsJson != null);
        system.assert( ext.gridConfigJson != null);

        Map<String,String> filter = new Map<String,String>();
        JsonResult res = PickAssignmentExt.getPickAssignmentData (JSON.serialize(filter));
        system.assert( res.records ==null || res.records.size() == 0 );

        filter.put('location', fuel.location3.Id );
        res = PickAssignmentExt.getPickAssignmentData (JSON.serialize(filter));
        system.assert(res.success);
        system.assert( res.records.size() > 0);

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standtpo', Email='standardwwwwwuser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName='standardwwwwwuser@testorg.com');
        insert u;

        Id shipId = null;
        for (Skid__c rec : (List<Skid__c>)res.records) {
            shipId = rec.Shipment_Line__r.Shipment__c;
            break;
        }
        Map<Id,Id> mapPickAssignment = new Map<Id,Id>{shipId=>u.Id};
        res = PickAssignmentExt.saveAssignment(JSON.serialize(mapPickAssignment) , fuel.location3.Id);
        system.assert( res.success );
        res = PickAssignmentExt.getPickAssignmentData (JSON.serialize(filter));
        system.assert(res.success);
        system.assert( res.records.size() > 0);

        for (Skid__c rec : (List<Skid__c>)res.records) {
            if ( rec.Shipment_Line__r.Shipment__c == shipId) {
                system.assert( rec.get('Picker__c') != null );
            }
        }

    }

}