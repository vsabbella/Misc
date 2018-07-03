@IsTest
private class PermissionsTest {
	
	public static String CUSTOM_PERMISSION_NAME = 'Sales_Order_Release';
	
    private static testMethod void doPermissionsTest() {
    	
    	Profile profile = [select Id from Profile where Name = 'System Administrator']; 

        User salesOrderUser = new user(alias = 'test123', email='test123@noemail.com', 
                            emailencodingkey='UTF-8', firstName='Sales Order', lastname='User', languagelocalekey='en_US',
                            localesidkey='en_IN', profileid = profile.Id, country='India',
                            timezonesidkey='Asia/Kolkata', username='custrep@noemail.com'); 
        insert salesOrderUser;
        
    	// Create PermissionSet with Custom Permission and asisgn to test user
		PermissionSet ps = new PermissionSet();
		ps.Name = 'ReadCustomPermissionsTest';
		ps.Label = 'ReadCustomPermissionsTest';
		insert ps;
		
		PermissionSetAssignment psa = new PermissionSetAssignment();
		psa.AssigneeId = salesOrderUser.Id;
		psa.PermissionSetId = ps.Id;
		insert psa;
		
		SetupEntityAccess sea = new SetupEntityAccess();
		sea.ParentId = ps.Id;
		sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = :CUSTOM_PERMISSION_NAME][0].Id;
		insert sea;
		
		system.runAs(salesOrderUser){
			Permissions.startAction(CUSTOM_PERMISSION_NAME);
	    	Permissions.checkSystemMode();       
	
	        system.assertEquals(true, Permissions.permActions.get(CUSTOM_PERMISSION_NAME).hasAccess);
	        system.assertEquals(true, Permissions.permActions.get(CUSTOM_PERMISSION_NAME).isExecuting);
	
			Permissions.endAction(CUSTOM_PERMISSION_NAME); 
	        system.assertEquals(true, Permissions.permActions.get(CUSTOM_PERMISSION_NAME).hasAccess);
	        system.assertEquals(false, Permissions.permActions.get(CUSTOM_PERMISSION_NAME).isExecuting);
		}       
    }

}