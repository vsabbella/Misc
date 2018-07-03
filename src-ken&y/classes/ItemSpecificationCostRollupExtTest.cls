@isTest
public with sharing class ItemSpecificationCostRollupExtTest {
    @testSetup
    private static void setupData() {
        TestFuel f = new TestFuel();
        System.assert(f.assembly != null);
        System.assert(f.assembly2 != null);

        User_Preference__c pref = UserPreference.getInstance().preference;
        pref.Default_Company__c = f.company.Id;
        pref.Default_Facility__c = f.facility2.Id;
        UserPreference.getInstance().updateUserPreference();
    }

    private static TestFuelQuery fuel = new TestFuelQuery();

    private static testMethod void testRollupItemSpec() {
        Test.setCurrentPage(Page.ItemSpecificationCostRollup);
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt();
        ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));

        ext.redirect();
        Set<String> s = ItemSpecificationCostRollupExt.csvScopeRanges;
        ext.getScopeRange();
        ext.getCostRollupModels();
        ext.getAssemblyItemCostStatusOptions();
        ext.getComponentItemCostStatusOptions();
        ext.getExplosionBasis();

        ext.selectedScopeRange = 'SINGLE';
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        ext.showReport();
        System.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
        System.assert(ext.thisBom.size() > 0, ext.thisBom);

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 1, itemCosts);
        Item_Cost__c itemCost = itemCosts[0];

        System.assert(itemCost.Item__c == fuel.assembly.Item__c, itemCost);
        System.assert(itemCost.Facility__c == fuel.facility2.Id, itemCost);
        System.assert(itemCost.Item_Specification__c == fuel.assembly.Id, itemCost);
        System.assert(itemCost.Start_Date__c.date() == Date.today(), itemCost);

        System.assert(itemCost.Material_Cost__c == 68.5, itemCost);
        System.assert(itemCost.Labor_Cost__c == 0, itemCost);
        System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
        System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
        System.assert(itemCost.Standard_Cost__c == 68.5, itemCost);
    }

    private static testMethod void testRollupInactiveItemSpec() {
        Test.setCurrentPage(Page.ItemSpecificationCostRollup);
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt();
        fuel.assembly.Active__c = false;
        update fuel.assembly;
        ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));

        ext.redirect();
        Set<String> s = ItemSpecificationCostRollupExt.csvScopeRanges;
        ext.getScopeRange();
        ext.getCostRollupModels();
        ext.getAssemblyItemCostStatusOptions();
        ext.getComponentItemCostStatusOptions();
        ext.getExplosionBasis();

        ext.selectedScopeRange = 'SINGLE';
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = system.now());

        ext.showReport();
        System.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
        System.assert(ext.thisBom.size() > 0, ext.thisBom);

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR), 'Expected error message while saving cost rollup for inactive item spec');
    }

    private static testMethod void testRollupItemSpecLinear() {
        update new Company__c(Id = fuel.company.Id, Default_Rollup_Basis__c = 'Linear');
        update new Item_Specification__c(Id = fuel.assembly.Id, Facility__c = fuel.facility.Id);
        update new Item_Specification__c(Id = fuel.assembly2.Id, Facility__c = fuel.facility.Id);

        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'SINGLE';
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        ext.showReport();
        System.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
        System.assert(ext.thisBom.size() > 0, ext.thisBom);

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 1, itemCosts);
        Item_Cost__c itemCost = itemCosts[0];

        System.assert(itemCost.Item__c == fuel.assembly.Item__c, itemCost);
        System.assert(itemCost.Facility__c == fuel.facility.Id, itemCost);
        System.assert(itemCost.Item_Specification__c == fuel.assembly.Id, itemCost);
        System.assert(itemCost.Start_Date__c.date() == Date.today(), itemCost);

        System.assert(itemCost.Material_Cost__c == 84.05, itemCost);
        System.assert(itemCost.Labor_Cost__c == 30, itemCost);
        System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
        System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
        System.assert(itemCost.Standard_Cost__c == 114.05, itemCost);
    }

    private static testMethod void testRollupItemSpecLinearOverride() {
        update new Company__c(Id = fuel.company.Id, Default_Rollup_Basis__c = 'Linear');
        update new Item_Specification__c(Id = fuel.assembly.Id, Facility__c = fuel.facility.Id);
        update new Item_Specification__c(Id = fuel.assembly2.Id, Facility__c = fuel.facility.Id);

        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'SINGLE';
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.isWipeoutCostsOn = true;
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        ext.showReport();
        System.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
        System.assert(ext.thisBom.size() > 0, ext.thisBom);

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 1, itemCosts);
        Item_Cost__c itemCost = itemCosts[0];

        System.assert(itemCost.Item__c == fuel.assembly.Item__c, itemCost);
        System.assert(itemCost.Facility__c == fuel.facility.Id, itemCost);
        System.assert(itemCost.Item_Specification__c == fuel.assembly.Id, itemCost);
        System.assert(itemCost.Start_Date__c.date() == Date.today(), itemCost);

        System.assert(itemCost.Material_Cost__c == 84.05, itemCost);
        System.assert(itemCost.Labor_Cost__c == 18, itemCost);
        System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
        System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
        System.assert(itemCost.Standard_Cost__c == 102.05, itemCost);
    }

    private static testMethod void testRollupItemSpecNoPurchased() {
        update new Item__c(Id = fuel.assembly2.Item__c, Source__c = 'Purchased');

        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'SINGLE';
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = false;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        ext.showReport();
        System.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
        System.assert(ext.thisBom.size() > 0, ext.thisBom);

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 1, itemCosts);
        Item_Cost__c itemCost = itemCosts[0];

        System.assert(itemCost.Item__c == fuel.assembly.Item__c, itemCost);
        System.assert(itemCost.Facility__c == fuel.facility2.Id, itemCost);
        System.assert(itemCost.Item_Specification__c == fuel.assembly.Id, itemCost);
        System.assert(itemCost.Start_Date__c.date() == Date.today(), itemCost);

        System.assert(itemCost.Material_Cost__c == 18, itemCost);
        System.assert(itemCost.Labor_Cost__c == 0, itemCost);
        System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
        System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
        System.assert(itemCost.Standard_Cost__c == 18, itemCost);
    }

    private static testMethod void testErrors() {
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));

        ext.selectedScopeRange = null;
        ext.showReport();
        System.assert(ApexPages.getMessages().size() == 1, ApexPages.getMessages());

        ext.selectedScopeRange = 'SINGLE';
        ext.inputHolder.Company__c = null;
        ext.showReport();
        System.assert(ApexPages.getMessages().size() == 2, ApexPages.getMessages());

        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = null;
        ext.showReport();
        System.assert(ApexPages.getMessages().size() == 3, ApexPages.getMessages());

        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.isWipeoutCostsOn = false;
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = null;
        ext.showReport();
        System.assert(ApexPages.getMessages().size() == 4, ApexPages.getMessages());

        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.startDate = null;
        ext.showReport();
        System.assert(ext.startDate.Start_Date2__c == fuel.assembly.Start_Date2__c, ext.startDate);

        ext.startDate.Start_Date2__c = System.now().addDays(-60);
        ext.showReport();
        System.assert(ApexPages.getMessages().size() == 5, ApexPages.getMessages());

        ext.startDate.Start_Date2__c = System.now();
        ext.showReport();

        ext.selectedAssemblyItemCostStatus = 'Approved';
        ext.saveReport();
        System.assert(ApexPages.getMessages().size() == 6, ApexPages.getMessages());
    }

    private static testMethod void testBomDisplay() {
        Test.setCurrentPage(Page.BOMDisplay);
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));

        System.assert(ext.selectedScopeRange == 'SINGLE FOR EXPANDED BOM', ext.selectedScopeRange);
        System.assert(ext.thisBom.size() > 0, ext.thisBom);

        ext.refresh();
    }

    private static testMethod void testRollupItemSpecRead() {
        Test.setCurrentPage(Page.ItemSpecificationCostRollup);
        ApexPages.currentPage().getParameters().put('readReport', 'true');
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));

        ext.selectedScopeRange = 'SINGLE';
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        ext.showReport();
        System.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
        System.assert(ext.reportDocId != null, ext.reportDocId);
        System.assert(ext.reportDocName != null, ext.reportDocName);
    }

    private static testMethod void testRollupFacility() {
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'FACILITY';
        ext.refreshCriteria();
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        Test.startTest();

        ext.showReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        Test.stopTest();

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 2, itemCosts);

        for (Item_Cost__c itemCost:itemCosts) {
            System.assert(itemCost.Facility__c == fuel.facility2.Id, itemCost);
            System.assert(itemCost.Start_Date__c.date() == Date.today(), itemCost);

            if (itemCost.Item__c == fuel.assembly.Item__c) {
                System.assert(itemCost.Item_Specification__c == fuel.assembly.Id, itemCost);

                System.assert(itemCost.Material_Cost__c == 68.5, itemCost);
                System.assert(itemCost.Labor_Cost__c == 0, itemCost);
                System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
                System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
                System.assert(itemCost.Standard_Cost__c == 68.5, itemCost);
            } else if (itemCost.Item__c == fuel.assembly2.Item__c) {
                System.assert(itemCost.Item_Specification__c == fuel.assembly2.Id, itemCost);

                System.assert(itemCost.Material_Cost__c == 55.5, itemCost);
                System.assert(itemCost.Labor_Cost__c == 0, itemCost);
                System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
                System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
                System.assert(itemCost.Standard_Cost__c == 55.5, itemCost);
            }
        }
    }

    private static testMethod void testRollupFacilityWithInactiveItemSpec() {
        // Should skip inactive itemspec
        fuel.assembly.Active__c = false;
        update fuel.assembly;
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'FACILITY';
        ext.refreshCriteria();
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        DateTime now = System.now();
        ext.startDate = new Item_Specification__c(Start_Date2__c = now);

        Test.startTest();

        ext.showReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        Test.stopTest();

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 1, itemCosts.size());

        for (Item_Cost__c itemCost:itemCosts) {
            System.assert(itemCost.Facility__c == fuel.facility2.Id, itemCost);
            System.assert(itemCost.Start_Date__c.day() == now.day(),itemCost + ' -- ' + now);

            if (itemCost.Item__c == fuel.assembly.Item__c) {
                System.assert(itemCost.Item_Specification__c == fuel.assembly.Id, itemCost);

                System.assert(itemCost.Material_Cost__c == 68.5, itemCost);
                System.assert(itemCost.Labor_Cost__c == 0, itemCost);
                System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
                System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
                System.assert(itemCost.Standard_Cost__c == 68.5, itemCost);
            } else if (itemCost.Item__c == fuel.assembly2.Item__c) {
                System.assert(itemCost.Item_Specification__c == fuel.assembly2.Id, itemCost);

                System.assert(itemCost.Material_Cost__c == 55.5, itemCost);
                System.assert(itemCost.Labor_Cost__c == 0, itemCost);
                System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
                System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
                System.assert(itemCost.Standard_Cost__c == 55.5, itemCost);
            }
        }
    }

    private static testMethod void testRollupCompany() {
        ItemService.allowItemCostUpdate = true;
        List<Item_Cost__c> itemCosts = [SELECT Id FROM Item_Cost__c WHERE Status__c = 'Approved'];
        for (Item_Cost__c itemCost:itemCosts) itemCost.Facility__c = null;
        update itemCosts;
        ItemService.allowItemCostUpdate = false;

        update new Item_Specification__c(Id = fuel.assembly.Id, Facility__c = null);
        update new Item_Specification__c(Id = fuel.assembly2.Id, Facility__c = null);

        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'COMPANY';
        ext.refreshCriteria();
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        Test.startTest();

        ext.showReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        Test.stopTest();

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 2, itemCosts);

        for (Item_Cost__c itemCost:itemCosts) {
            System.assert(itemCost.Facility__c == null, itemCost);
            System.assert(itemCost.Start_Date__c.date() == Date.today(), itemCost);

            if (itemCost.Item__c == fuel.assembly.Item__c) {
                System.assert(itemCost.Item_Specification__c == fuel.assembly.Id, itemCost);

                System.assert(itemCost.Material_Cost__c == 113.05, itemCost);
                System.assert(itemCost.Labor_Cost__c == 12, itemCost);
                System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
                System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
                System.assert(itemCost.Standard_Cost__c == 125.05, itemCost);
            } else if (itemCost.Item__c == fuel.assembly2.Item__c) {
                System.assert(itemCost.Item_Specification__c == fuel.assembly2.Id, itemCost);

                System.assert(itemCost.Material_Cost__c == 55.5, itemCost);
                System.assert(itemCost.Labor_Cost__c == 0, itemCost);
                System.assert(itemCost.Overhead_Cost__c == 0, itemCost);
                System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
                System.assert(itemCost.Standard_Cost__c == 55.5, itemCost);
            }
        }
    }

    private static testMethod void testRollupBatchRead() {
        Test.setCurrentPage(Page.ItemSpecificationCostRollup);
        ApexPages.currentPage().getParameters().put('readReport', 'true');
        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'FACILITY';
        ext.refreshCriteria();
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility2.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        List<Item__c> itemList = fuel.itemList;
        itemList[0].Level__c = 2;
        for (Integer i = 1; i < 6; i++) {
            itemList[i].Level__c = 1;
        }
        for (Integer i = 6; i < 11; i++) {
            itemList[i].Level__c = 0;
        }
        update itemList;

        Test.startTest();

        ext.showReport();
        System.assert(!ApexPages.hasMessages(ApexPages.Severity.ERROR), ApexPages.getMessages());

        Test.stopTest();

        System.assert(ext.jobId != null, ext.jobId);
        ext.fetchDocument();
        System.assert(ext.reportDocId != null, ext.reportDocId);
        System.assert(ext.reportDocName != null, ext.reportDocName);
    }

    private static testMethod void rollupRoutings() {
        update new Item_Specification__c(Id = fuel.assembly.Id, Facility__c = fuel.facility.Id);
        update new Item_Specification__c(Id = fuel.assembly2.Id, Facility__c = fuel.facility.Id);

        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'SINGLE';
        ext.rollupRouting = true;
        ext.calcMfgOverhead = true;
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        ext.showReport();
        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 1, itemCosts);
        Item_Cost__c itemCost = itemCosts[0];

        System.assert(itemCost.Material_Cost__c == 122.05, itemCost);
        System.assert(itemCost.Labor_Cost__c == 6, itemCost);
        System.assert(itemCost.Overhead_Cost__c == 14, itemCost);
        System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
        System.assert(itemCost.Standard_Cost__c == 142.05, itemCost);
    }

    private static testMethod void rollupRoutingsBypassPhantoms() {
        update new Company__c(Id = fuel.company.Id, Use_Item_Types_For_Costing__c = true);
        update new Item_Specification__c(Id = fuel.assembly.Id, Facility__c = fuel.facility.Id);
        update new Item_Specification__c(Id = fuel.assembly2.Id, Facility__c = fuel.facility.Id);

        ItemSpecificationCostRollupExt ext = new ItemSpecificationCostRollupExt(new ApexPages.StandardController(fuel.assembly));
        ext.selectedScopeRange = 'SINGLE';
        ext.rollupRouting = true;
        ext.calcMfgOverhead = true;
        ext.inputHolder.Company__c = fuel.company.Id;
        ext.inputHolder.Facility__c = fuel.facility.Id;
        ext.selectedComponentItemCostStatus = 'Approved';
        ext.selectedExplosionBasis = 'Costing';
        ext.explodePurchased = true;
        ext.inputHolder.Item_Specification__c = fuel.assembly.Id;
        ext.getItemSpecInfo();
        ext.startDate = new Item_Specification__c(Start_Date2__c = System.now());

        ext.showReport();
        ext.selectedAssemblyItemCostStatus = 'Planning - 3';
        ext.saveReport();

        SOQLUtil costQuery = new SOQLUtil('Item_Cost__c');
        costQuery.addAllCustomFields();
        costQuery.setWhereClause('Status__c = \'Planning - 3\'');
        List<Item_Cost__c> itemCosts = Database.query(costQuery.getQuery());
        System.assert(itemCosts.size() == 1, itemCosts);
        Item_Cost__c itemCost = itemCosts[0];

        System.assert(itemCost.Material_Cost__c == 102.05, itemCost);
        System.assert(itemCost.Labor_Cost__c == 12, itemCost);
        System.assert(itemCost.Overhead_Cost__c == 28, itemCost);
        System.assert(itemCost.Outside_Processing_Cost__c == 0, itemCost);
        System.assert(itemCost.Standard_Cost__c == 142.05, itemCost);
    }
}