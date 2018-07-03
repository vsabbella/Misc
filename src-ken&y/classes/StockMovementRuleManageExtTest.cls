@isTest
private class StockMovementRuleManageExtTest {

    static testMethod void testNewStockMovementRule() {
        
        TestFuel fuel = new TestFuel();
        
        Test.startTest();
        
        StockMovementRuleManageExt smrme = new StockMovementRuleManageExt(new Apexpages.Standardcontroller( new Stock_Movement_Rule__c() ));
        smrme.smr.Name = 'Test rule1';
        smrme.smr.Rule_Type__c = 'Putaway';
        smrme.smr.Company__c = fuel.company.id;
        smrme.smr.Facility__c = fuel.facility2.id;
        smrme.smr.Class__c = fuel.clsObj.id;
        smrme.smr.Item__c = null;
        smrme.smr.Customer__c = null;
        smrme.smr.Source_Document__c = 'Purchase Order';
        smrme.smr.Priority__c = 1;
        smrme.smr.Active__c = true;
        
        system.assert( smrme.smrList.size() == 1);
        
        smrme.smrList[0].Location__c = fuel.location3.id;
        smrme.save();
        
        Test.stopTest();
        
        List<Stock_Movement_Rule__c> smrList = [ select id, Name, Location__c, Location_List__c From Stock_Movement_Rule__c where Name='Test rule1'];
        system.assert( smrList.size() == 1);
        
        system.assert( smrList[0].Location__c == fuel.location3.id );
        system.assert( smrList[0].Location_List__c != null );
        
        list<Id> locList = (list<Id>)JSON.deserialize(smrList[0].Location_List__c, list<Id>.Class);
        system.assert(locList.size() == 1);
        system.assertEquals( locList[0], fuel.location3.id );
    }
    
    static testMethod void testNewStockMovementRuleWithMultipleLocations() {
        
        TestFuel fuel = new TestFuel();
        
        Test.startTest();
        
        StockMovementRuleManageExt smrme = new StockMovementRuleManageExt(new Apexpages.Standardcontroller( new Stock_Movement_Rule__c() ));
        smrme.smr.Name = 'Test rule1';
        smrme.smr.Rule_Type__c = 'Putaway';
        smrme.smr.Company__c = fuel.company.id;
        smrme.smr.Facility__c = fuel.facility2.id;
        smrme.smr.Class__c = fuel.clsObj.id;
        smrme.smr.Item__c = null;
        smrme.smr.Customer__c = null;
        smrme.smr.Source_Document__c = 'Purchase Order';
        smrme.smr.Priority__c = 1;
        smrme.smr.Active__c = true;
        
        system.assert( smrme.smrList.size() == 1);
        
        smrme.smrList[0].Location__c = fuel.location3.id;
        
        smrme.addNewLocation();
        system.assert( smrme.smrList.size() == 2);
        
        smrme.smrList[1].Location__c = fuel.location5.id;
        
        smrme.save();
        system.assert( ApexPages.hasMessages() == false, ApexPages.getMessages() );
        
        Test.stopTest();
        
        List<Stock_Movement_Rule__c> smrList = [ select id, Name, Location__c, Location_List__c From Stock_Movement_Rule__c where Name='Test rule1'];
        system.assert( smrList.size() == 1);
        
        system.assert( smrList[0].Location__c == fuel.location3.id );
        system.assert( smrList[0].Location_List__c != null );
        
        list<Id> locList = (list<Id>)JSON.deserialize(smrList[0].Location_List__c, list<Id>.Class);
        system.assert(locList.size() == 2);
        system.assertEquals( locList[0], fuel.location3.id );
        system.assertEquals( locList[1], fuel.location5.id );
    }
    
    static testMethod void testNewStockMovementRuleEdit() {
        
        TestFuel fuel = new TestFuel();

        StockMovementRuleManageExt smrme = new StockMovementRuleManageExt(new Apexpages.Standardcontroller( new Stock_Movement_Rule__c() ));
        smrme.smr.Name = 'Test rule1';
        smrme.smr.Rule_Type__c = 'Putaway';
        smrme.smr.Company__c = fuel.company.id;
        smrme.smr.Facility__c = fuel.facility2.id;
        smrme.smr.Class__c = fuel.clsObj.id;
        smrme.smr.Item__c = null;
        smrme.smr.Customer__c = null;
        smrme.smr.Source_Document__c = 'Purchase Order';
        smrme.smr.Priority__c = 1;
        smrme.smr.Active__c = true;
        
        system.assert( smrme.smrList.size() == 1);
        smrme.smrList[0].Location__c = fuel.location3.id;
        
        smrme.addNewLocation();
        system.assert( smrme.smrList.size() == 2);
        
        smrme.smrList[1].Location__c = fuel.location5.id;
        smrme.save();
        system.assert( ApexPages.hasMessages() == false, ApexPages.getMessages() );

        List<Stock_Movement_Rule__c> smrList = [ select id, Name, Location__c,Facility__c, Company__c, Location_List__c From Stock_Movement_Rule__c where Name='Test rule1'];
        system.assert( smrList.size() == 1);
        
        Test.startTest();
        
        smrme = new StockMovementRuleManageExt(new Apexpages.Standardcontroller( smrList[0] ));
        system.assert( smrme.smrList.size() == 2);
        
        smrme.smr.Name = 'Test rule2';
        smrme.smrList[0].Location__c = fuel.location5.id;
        smrme.smrList[1].Location__c = fuel.location3.id;
        smrme.save();
        
        Test.stopTest();
        
        system.assert( ApexPages.hasMessages() == false, ApexPages.getMessages());
        
        smrList = [ select id, Name, Location__c, Location_List__c From Stock_Movement_Rule__c where Name='Test rule2'];
        system.assert( smrList.size() == 1);
        
        system.assertEquals( smrList[0].Location__c, fuel.location5.id, ApexPages.getMessages() );
        system.assert( smrList[0].Location_List__c != null );
        
        list<Id> locList = (list<Id>)JSON.deserialize(smrList[0].Location_List__c, list<Id>.Class);
        system.assert(locList.size() == 2);
        system.assertEquals( locList[0], fuel.location5.id );
        system.assertEquals( locList[1], fuel.location3.id );
    }
    
    static testMethod void testStockMovementRuleErrors() {
        
        TestFuel fuel = new TestFuel();

        StockMovementRuleManageExt smrme = new StockMovementRuleManageExt(new Apexpages.Standardcontroller( new Stock_Movement_Rule__c() ));
        smrme.smr.Name = 'Test rule1';
        smrme.smr.Rule_Type__c = 'Putaway';
        smrme.smr.Company__c = fuel.company.id;
        smrme.smr.Facility__c = fuel.facility2.id;
        smrme.smr.Class__c = fuel.clsObj.id;
        smrme.smr.Item__c = null;
        smrme.smr.Customer__c = null;
        smrme.smr.Source_Document__c = 'Purchase Order';
        smrme.smr.Priority__c = 1;
        smrme.smr.Active__c = true;
        
        system.assert( smrme.smrList.size() == 1);
        smrme.smrList[0].Location__c = fuel.location3.id;
        
        smrme.addNewLocation();
        system.assert( smrme.smrList.size() == 2);
        
        smrme.smrList[1].Location__c = fuel.location5.id;
        smrme.save();
        system.assert( ApexPages.hasMessages() == false, ApexPages.getMessages() );

        List<Stock_Movement_Rule__c> smrList = [ select id, Name, Location__c,Facility__c, Company__c, Location_List__c From Stock_Movement_Rule__c where Name='Test rule1'];
        system.assert( smrList.size() == 1);
        
        Test.startTest();
        
        smrme = new StockMovementRuleManageExt(new Apexpages.Standardcontroller( smrList[0] ));
        system.assert( smrme.smrList.size() == 2);
        
        smrme.smr.Name = 'Test rule2';
        smrme.smr.Facility__c = fuel.facility.id;
        
        ApexPages.currentPage().getParameters().put('changedId',fuel.facility.id);
        ApexPages.currentPage().getParameters().put('fieldPath',KSE.namespaceUU+'Facility__c');
        
        smrme.syncClones();
        system.assert( smrme.smrList[0].Facility__c == fuel.facility.id);
        system.assert( smrme.smrList[1].Facility__c == fuel.facility.id);
        
        smrme.smrList[1].Location__c = fuel.location3.id;
        
        smrme.save();
        system.assert( ApexPages.getMessages().size() == 1, 'location cannot be specified more than once');
        
        smrme.smrList[1].location__c = null;
        smrme.save();
        system.assert( ApexPages.getMessages().size() == 2, 'location must belong to the company/facility specified');
        
        smrme.smrList[0].location__c = null;
        smrme.save();
        system.assert( ApexPages.getMessages().size() == 3, 'no locations have been specified');
        
        smrme.smrList[0].location__c = fuel.location.id;
        smrme.save();
        
        Test.stopTest();
        
        system.assert( ApexPages.getMessages().size() == 3);
        
        smrList = [ select id, Name, Location__c, Location_List__c From Stock_Movement_Rule__c where Name='Test rule2'];
        system.assert( smrList.size() == 1);
        
        system.assertEquals( smrList[0].Location__c, fuel.location.id, ApexPages.getMessages() );
        system.assert( smrList[0].Location_List__c != null );
        
        list<Id> locList = (list<Id>)JSON.deserialize(smrList[0].Location_List__c, list<Id>.Class);
        system.assert(locList.size() == 1);
        system.assertEquals( locList[0], fuel.location.id );
    }
    
    static testMethod void testLocationListExtension() {
        
        TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule__c> smrList = fuel.stockMovementRuleList;
        
        Test.startTest();
        
        LocationListExtension lle = new LocationListExtension(new Apexpages.Standardcontroller( smrList[0] ));
        
        system.assertEquals(lle.smrList.size() , 2);
        system.assertEquals(lle.smrList[0].Sequence__c , 1);
        system.assertEquals(lle.smrList[0].Location__c , fuel.location3.id);
        system.assertEquals(lle.smrList[1].Sequence__c , 2);
        system.assertEquals(lle.smrList[1].Location__c , fuel.location5.id);
        
        smrList[0].Location_List__c = null;
        update smrList[0];
        
        lle = new LocationListExtension(new Apexpages.Standardcontroller( smrList[0] ));
        system.assert( ApexPages.hasMessages() == true ); //No Locations have been specified for this rule!
        
        Test.stopTest();
        
    }
    static testMethod void testCloneSMR() {
        TestFuel fuel = new TestFuel();
        List<Stock_Movement_Rule__c> smrs = fuel.stockMovementRuleList;
        delete [SELECT Id FROM Stock_Movement_Rule__c WHERE Id <> :smrs[0].Id];

        Test.setCurrentPage(Page.StockMovementRuleManage);
        ApexPages.currentPage().getParameters().put('clone','1');
        StockMovementRuleManageExt ext = new StockMovementRuleManageExt(new Apexpages.Standardcontroller(smrs[0]));
        ext.smr.Priority__c = 2;
        ext.save();
        
        System.assert([SELECT Id FROM Stock_Movement_Rule__c].size() == 2);
    }
}