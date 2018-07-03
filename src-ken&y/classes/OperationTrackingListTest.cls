@isTest
private class OperationTrackingListTest {
	private static testMethod void testView() {
		TestFuel fuel = new TestFuel();
		Work_Order__c wo = fuel.workOrder;
		
		OperationTrackingListExt ext = new OperationTrackingListExt(new ApexPages.StandardController(wo));
		String namespace = ext.namespaceUU;
		System.assert(ext.operations.size() == 0);
		
		WorkOrderPlanningService.release(new Set<Id>{wo.Id});
		ext = new OperationTrackingListExt(new ApexPages.StandardController(wo));
		System.assert(ext.operations.size() > 0);
	}
}