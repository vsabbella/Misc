@isTest
private class ItemSpecificationNewTest {
	private static testMethod void nameError() {
		ApexPages.StandardController con = new ApexPages.StandardController(new Item_Specification__c());
		ItemSpecificationNewExt ext = new ItemSpecificationNewExt(con);
		Item_Specification__c spec = (Item_Specification__c)con.getRecord();

		spec.Type__c = 'Template';
		ext.save();

		System.assert(ApexPages.hasMessages(ApexPages.Severity.FATAL));
	}

	private static testMethod void successNew() {
		TestFuel fuel = new TestFuel();
		ApexPages.StandardController con = new ApexPages.StandardController(new Item_Specification__c());
		ItemSpecificationNewExt ext = new ItemSpecificationNewExt(con);
		Item_Specification__c spec = (Item_Specification__c)con.getRecord();

		spec.Company__c = fuel.company.Id;
		spec.Facility__c = fuel.facility2.Id;
		spec.Item__c = fuel.itemList[2].Id;
		spec.Revision__c = 'R1';
		spec.Start_Date2__c = System.now().addDays(-1);
		spec.Costing__c = true;
		spec.Production__c = true;
		spec.Type__c = 'Assembly';
		ext.save();
		System.assert(!ApexPages.hasMessages(),ApexPages.getMessages());

		List<Item_Specification__c> specs = [SELECT Id FROM Item_Specification__c WHERE Item__c = :fuel.itemList[2].Id];
		System.assert(specs.size() == 1);
	}

	private static testMethod void successClone() {
		TestFuel fuel = new TestFuel();
		Item_Specification__c spec = fuel.itemSpec;
		List<Routing__c> routings = fuel.routings;
		ApexPages.StandardController con = new ApexPages.StandardController(spec);
		ItemSpecificationNewExt ext = new ItemSpecificationNewExt(con);
		spec = (Item_Specification__c)con.getRecord();

		spec.Item__c = fuel.itemList[6].Id;
		ext.save();
		System.assert(!ApexPages.hasMessages(),ApexPages.getMessages());


		List<Item_Specification__c> specs = [SELECT Id,(SELECT Id FROM Routings__r),(SELECT Id FROM Components__r) FROM Item_Specification__c WHERE Item__c = :fuel.itemList[6].Id];
		System.assert(specs.size() == 1,specs);
		System.assert(specs[0].Routings__r.size() == fuel.routings.size(),specs[0].Routings__r);
		System.assert(specs[0].Components__r.size() == fuel.components.size(),specs[0].Components__r);
	}

//	private static testMethod void failureNew() {
//		TestFuel fuel = new TestFuel();
//		ApexPages.StandardController con = new ApexPages.StandardController(new Item_Specification__c());
//		ItemSpecificationNewExt ext = new ItemSpecificationNewExt(con);
//		Item_Specification__c spec = (Item_Specification__c)con.getRecord();
//
//		spec.Company__c = fuel.company.Id;
//		spec.Facility__c = fuel.facility2.Id;
//		spec.Item__c = fuel.itemList[2].Id;
//		spec.Revision__c = 'R1';
//		spec.Start_Date__c = System.today() - 1;
//		spec.Costing__c = true;
//		spec.Production__c = true;
//		spec.Type__c = 'Assembly';
//		spec.Packaging_UOM__c = fuel.uomList[0].Id;
//		spec.Default_Work_Order_Packaging_UOM__c = fuel.uomList[8].Id;
//		ext.save();
//		System.assert(ApexPages.hasMessages(),'Expected create failure with invalid packaging uom for item master');
//		system.assert(String.valueOf(ApexPages.getMessages()).contains(Label.Packaging_UOM_not_configured_for_the_Item), ApexPages.getMessages());
//
//		spec.Company__c = fuel.company.Id;
//		spec.Facility__c = fuel.facility2.Id;
//		spec.Item__c = fuel.itemList[2].Id;
//		spec.Revision__c = 'R1';
//		spec.Start_Date__c = System.today() - 1;
//		spec.Costing__c = true;
//		spec.Production__c = true;
//		spec.Type__c = 'Assembly';
//		spec.Packaging_UOM__c = fuel.uomList[8].Id;
//		spec.Default_Work_Order_Packaging_UOM__c = fuel.uomList[0].Id;
//		ext.save();
//		System.assert(ApexPages.hasMessages(),'Expected create failure with invalid packaging uom for item master');
//		system.assert(String.valueOf(ApexPages.getMessages()).contains(Label.Packaging_UOM_not_configured_for_the_Item), ApexPages.getMessages());
//	}
//
//	private static testMethod void failureUpdate() {
//		TestFuel fuel = new TestFuel();
//		ApexPages.StandardController con = new ApexPages.StandardController(new Item_Specification__c());
//		ItemSpecificationNewExt ext = new ItemSpecificationNewExt(con);
//		Item_Specification__c spec = (Item_Specification__c)con.getRecord();
//
//		spec.Company__c = fuel.company.Id;
//		spec.Facility__c = fuel.facility2.Id;
//		spec.Item__c = fuel.itemList[2].Id;
//		spec.Revision__c = 'R1';
//		spec.Start_Date__c = System.today() - 1;
//		spec.Costing__c = true;
//		spec.Production__c = true;
//		spec.Type__c = 'Assembly';
//		spec.Packaging_UOM__c = fuel.itemList[2].Stocking_UOM__c;
//		spec.Default_Work_Order_Packaging_UOM__c = fuel.itemList[2].Stocking_UOM__c;
//		ext.save();
//		System.assert(!ApexPages.hasMessages(), ApexPages.getMessages());
//
//		SOQLUtil util = new SOQLUtil('Item_Specification__c');
//		util.addAllCustomFields();
//		util.setLimit(1);
//		util.setOrderByClause('CreatedDate DESC');
//		List<Item_Specification__c> itemSpecs = Database.query(util.getQuery());
//
//		System.assert(itemSpecs.size() > 0);
//		con = new ApexPages.StandardController(itemSpecs[0]);
//		ext = new ItemSpecificationNewExt(con);
//		spec = (Item_Specification__c)con.getRecord();
//		spec.Packaging_UOM__c = fuel.uomList[8].Id;
//		spec.Default_Work_Order_Packaging_UOM__c = fuel.uomList[0].Id;
//		ext.save();
//		System.assert(ApexPages.hasMessages(),'Expected create failure with invalid packaging uom for item master');
//		system.assert(String.valueOf(ApexPages.getMessages()).contains(Label.Packaging_UOM_not_configured_for_the_Item), ApexPages.getMessages());
//	}

}