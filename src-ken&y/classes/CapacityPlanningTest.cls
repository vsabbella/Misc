@isTest
private class CapacityPlanningTest {
	@testSetup
	private static void setupData() {
		TestFuel fuel = new TestFuel();
		insert new User_Preference__c(
			Default_Company__c = fuel.company.Id,
			Default_Facility__c = fuel.facility2.Id,
			OwnerID = UserInfo.getUserID()
		);
		WorkOrderPlanningService.release(new Set<Id>{fuel.workOrder.Id});
	}
	
	private static testMethod void testCapacityPlanning() {
		CapacityPlanningExt ext = new CapacityPlanningExt();
		System.assert(ext.defaultCompany != null,ext);
		System.assert(ext.defaultFacility != null,ext);
		System.assert(ext.wcrFieldsJson != null,ext.wcrFieldsJson);
		System.assert(ext.woFieldsJson != null,ext.woFieldsJson);
		System.assert(ext.opFieldsJson != null,ext.opFieldsJson);
		
		List<Operation_Tracking__c> ops = [SELECT Id,Work_Order__c,Work_Order__r.Facility__c,Work_Order__r.Start_Date2__c,Work_Center_Resource__c,Work_Center_Resource__r.Work_Center__c,Work_Center_Resource__r.Resource__c FROM Operation_Tracking__c];
		
		JsonResult result = CapacityPlanningExt.getWCRData(ops[0].Work_Order__r.Facility__c,ops[0].Work_Center_Resource__r.Work_Center__c,ops[0].Work_Center_Resource__r.Resource__c,ops[0].Work_Center_Resource__c,DateTime.newInstance(ops[0].Work_Order__r.Start_Date2__c.date(),Time.newInstance(0,0,0,0)),30);
		System.assert(result.success,result);
		System.assert(result.records.size() == 1,result.records);
		
		result = CapacityPlanningExt.getWOData(new List<Id>{ops[0].Work_Order__c});
		System.assert(result.success,result);
		System.assert(result.records.size() == 1,result.records);
		
		result = CapacityPlanningExt.getOPData(new List<Id>((new Map<Id,Operation_Tracking__c>(ops)).keyset()));
		System.assert(result.success,result);
		System.assert(result.records.size() == 3,result.records);
	}
}