@IsTest
private class ReadCustomPermissionsTest {
    /*private static final String TEST_CUSTOM_PERMISSION = 'Sales_Order_Release';

	private static testMethod void testCustomPermissionAssigned() {

		// Create PermissionSet with Custom Permission and asisgn to test user
		PermissionSet ps = new PermissionSet();
		ps.Name = 'ReadCustomPermissionsTest';
		ps.Label = 'ReadCustomPermissionsTest';
		insert ps;
		
		SetupEntityAccess sea = new SetupEntityAccess();
		sea.ParentId = ps.Id;
		sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = :TEST_CUSTOM_PERMISSION][0].Id;
		insert sea;
		
		PermissionSetAssignment psa = new PermissionSetAssignment();
		psa.AssigneeId = UserInfo.getUserId();
		psa.PermissionSetId = ps.Id;
		insert psa;

		ReadCustomPermissions cpr = new ReadCustomPermissions(Company__c.SObjectType);
		System.assertEquals(true, cpr.hasPermission(TEST_CUSTOM_PERMISSION));
	}	

	private static testMethod void testCustomPermissionNotValid() {
		try {
			System.assertEquals(false, new ReadCustomPermissions(Company__c.SObjectType).hasPermission('NotValid'));
			System.assert(false, 'Expected an exception');
		} catch (Exception e) {
			System.assertEquals('Custom Permission NotValid is not valid.', e.getMessage());
		}
	}*/
}