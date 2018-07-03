@isTest
private class ItemCostCloneExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        List<Item_Cost__c> costs = new List<Item_Cost__c>();
        for (Item__c item:f.itemList) {
            if (item.Source__c == 'Miscellaneous') continue;
            costs.add(new Item_Cost__c(
                Name = item.Name,
                Item__c = item.Id,
                Material_Cost__c = 1,
                Labor_Cost__c = 1,
                Facility__c = f.facility2.Id,
                Status__c = 'Planning - 1',
                Start_Date__c = System.now().addDays(-1),
                Company__c = f.company.Id
            ));
        }
        insert costs;
    }

    private static testMethod void testClone() {
        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addField('Id');
        costQuery.setWhereClause('Status__c = \'Planning - 1\'');
        List<Item_Cost__c> costs = Database.query(costQuery.getQuery());

        Test.setCurrentPage(Page.ItemCostCloneMass);
        ItemCostCloneExt ext = new ItemCostCloneExt(new ApexPages.StandardSetController(costs));
        System.assert(ext.massRedirect() != null);

        ApexPages.currentPage().getParameters().put('clone', '1');
        ext = new ItemCostCloneExt();
        System.assert(ApexPages.getMessages().size() == 1, ApexPages.getMessages().size());

        ApexPages.currentPage().getParameters().put('recs', String.join(new List<Id>((new Map<Id, Item_Cost__c>(costs)).keySet()), ','));
        ext = new ItemCostCloneExt();
        ext.getItemCostStatuses();
        ext.enableSave();
        ext.cancel();

        ext.saveClone();
        System.assert(ApexPages.getMessages().size() == 2, ApexPages.getMessages().size());

        ext.targetStatus = 'Planning - 2';
        ext.saveClone();
        System.assert([SELECT Id FROM Item_Cost__c WHERE Status__c = 'Planning - 1'].size() == costs.size());
        System.assert([SELECT Id FROM Item_Cost__c WHERE Status__c = 'Planning - 2' AND Planning_Reference__c != null].size() == costs.size());

        ext.saveClone();
        System.assert(ApexPages.getMessages().size() == 3, ApexPages.getMessages().size());
    }

    private static testMethod void testPropose() {
        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addField('Id');
        costQuery.setWhereClause('Status__c = \'Approved\'');
        List<Item_Cost__c> costs = Database.query(costQuery.getQuery());

        ApexPages.currentPage().getParameters().put('recs', String.join(new List<Id>((new Map<Id, Item_Cost__c>(costs)).keySet()), ','));
        ItemCostCloneExt ext = new ItemCostCloneExt();
        System.assert(ApexPages.getMessages().size() == 1, ApexPages.getMessages().size());
        
        costQuery.setWhereClause('Status__c = \'Planning - 1\'');
        costs = Database.query(costQuery.getQuery());

        ApexPages.currentPage().getParameters().put('recs', String.join(new List<Id>((new Map<Id, Item_Cost__c>(costs)).keySet()), ','));
        ext = new ItemCostCloneExt();

        ext.propose();
        System.assert(ApexPages.getMessages().size() == 2, ApexPages.getMessages().size());

        delete [SELECT Id FROM Item_Cost__c WHERE Status__c = 'Proposed'];
        ext.propose();
        System.assert([SELECT Id FROM Item_Cost__c WHERE Status__c = 'Planning - 1'].size() == costs.size());
        System.assert([SELECT Id FROM Item_Cost__c WHERE Status__c = 'Proposed' AND Planning_Reference__c != null].size() == costs.size());
    }
}