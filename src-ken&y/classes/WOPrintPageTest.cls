@isTest
public with sharing class WOPrintPageTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.smrsList != null);
        System.assert(f.stockMovementRuleList != null);

        WorkOrderPlanningService.release(new Set<Id>{ f.workOrder.Id });
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void testNoWorkOrder() {
        WOPrintPageExt ext = new WOPrintPageExt();
        System.assert(ApexPages.hasMessages());
    }
    private static testMethod void testNoOperation() {
        Test.setCurrentPage(Page.WOPrintPage);
        ApexPages.currentPage().getParameters().put('wo',fuel.workOrder.Id);
        WOPrintPageExt ext = new WOPrintPageExt();
        System.assert(ApexPages.hasMessages());
    }
    private static testMethod void testNoSkids() {
        Id opId = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id AND Sequence__c = 1][0].Id;

        Test.setCurrentPage(Page.WOPrintPage);
        ApexPages.currentPage().getParameters().put('wo',fuel.workOrder.Id);
        ApexPages.currentPage().getParameters().put('op',opId);

        WOPrintPageExt ext = new WOPrintPageExt();
        System.assert(ext.skids != null && ext.skids.size() > 0);
    }
    private static testMethod void testSuccess() {
        Id opId = [SELECT Id FROM Operation_Tracking__c WHERE Work_Order__c = :fuel.workOrder.Id AND Sequence__c = 1][0].Id;

        Map<Id,Lot__c> lots = new Map<Id,Lot__c>();
        List<SKID__c> skids = new List<SKID__c>();
        for (Item__c item:fuel.itemList) {
            lots.put(item.Id,new Lot__c(
                Name = 'ABC',
                Company__c = fuel.company.Id,
                Expiration_Date__c = System.today() + 365,
                Item__c = item.Id
            ));
            skids.add(new SKID__c(
                Company__c = fuel.company.Id,
                Item__c = item.Id,
                Location__c = fuel.location3.Id,
                Quantity__c = 100,
                Expiration_Date__c = System.today() + 365,
                Lot_Number__c = 'ABC',
                Type__c = SkidService3.SKID_TYPE_LOCATION
            ));
        }
        insert lots.values();
        for (SKID__c skid:skids) {
            skid.Lot__c = lots.get(skid.Item__c).Id;
        }
        insert skids;

        Test.setCurrentPage(Page.WOPrintPage);
        ApexPages.currentPage().getParameters().put('wo',fuel.workOrder.Id);
        ApexPages.currentPage().getParameters().put('op',opId);

        WOPrintPageExt ext = new WOPrintPageExt();
        System.assert(ext.skids != null && ext.skids.size() > 0);
    }
}