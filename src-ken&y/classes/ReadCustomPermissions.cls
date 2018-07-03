public virtual without sharing class ReadCustomPermissions {
/*
	private SObjectType managedObject;

	private Set<String> customPermissionNames;

	private Set<String> customPermissionsForCurrentUser;

	public ReadCustomPermissions() {
		this(null);
	}

	public ReadCustomPermissions(SObjectType managedObject) {
		this.managedObject = managedObject;
	}

	public Boolean hasPermission(String customPermissionName) {
		// Demand load the custom permissions from the database?		
		//if(customPermissionNames==null)	
			//init();
		// Is this a valid custom permission name?
		if(!FeatureManagement.checkPermission(customPermissionName))
			throw new CustomPermissionsException('Custom Permission ' + customPermissionName + ' is not valid.');
		// Has this user been assigned this custom permission?
		return FeatureManagement.checkPermission(customPermissionName);//customPermissionsForCurrentUser.contains(customPermissionName);
	}

	private void init() {
		customPermissionNames = new Set<String>();
		customPermissionsForCurrentUser = new Set<String>();

		// Determine the namespace context for the custom permissions via the SObject passed in?
		String namespacePrefix = null;
		if(managedObject!=null) {
			DescribeSObjectResult describe = managedObject.getDescribe();
			String name = describe.getName();
			String localName = describe.getLocalName();
			namespacePrefix = name.removeEnd(localName).removeEnd('__');
		}

		// Query the full set of Custom Permissions for the given namespace
		Map<Id, String> customPermissionNamesById = new Map<Id, String>();
		List<CustomPermission> customPermissions = 
			[select Id, DeveloperName from CustomPermission where NamespacePrefix = :namespacePrefix];
		for(CustomPermission customPermission : customPermissions) {
			customPermissionNames.add(customPermission.DeveloperName);
			customPermissionNamesById.put(customPermission.Id, customPermission.DeveloperName);
		}

		// Query to determine which of these custome settings are assigned to this user
		List<SetupEntityAccess> setupEntities = 
			[SELECT SetupEntityId
				FROM SetupEntityAccess
				WHERE SetupEntityId in :customPermissionNamesById.keySet() AND
					  ParentId
						IN (SELECT PermissionSetId 
   							FROM PermissionSetAssignment
   							WHERE AssigneeId = :UserInfo.getUserId())];	
		for(SetupEntityAccess setupEntity : setupEntities)
			customPermissionsForCurrentUser.add(customPermissionNamesById.get(setupEntity.SetupEntityId));	
	}

	public class CustomPermissionsException extends Exception {}*/
}