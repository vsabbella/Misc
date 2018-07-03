global virtual with sharing class BaseController {

	public class BaseControllerException extends Exception{}

	// This will show a top page along with the existing bottom pager fr serials popup
	public Boolean serialShowTopBar { get {
		if ( serialShowTopBar == null ) {
			Configuration__c config = Configuration__c.getAll().get ( 'SerialShowTopBar' );
			if ( config == null || String.isEmpty(config.Value__c) || !config.Value__c.equalsIgnoreCase('true') ) {
				serialShowTopBar = false;
			} else {
				serialShowTopBar = true;
			}
		}
		return serialShowTopBar;
	} private set;}

	public BaseController() {
	}

	public BaseController(ApexPages.StandardSetController scon) {
		// just to support integration with vf pages
	}

	public BaseController(ApexPages.StandardController scon) {
		// just to support integration with vf pages
	}

	@AuraEnabled
	@RemoteAction
	global static Action.Response doAction(string actionTarget, string obj){
		system.debug('actionTarget: ' + actionTarget);
		system.debug('object: ' + obj);
		Action.Target actionType;
		long thenTime = system.now().getTime();
		APIGateway__mdt route = APIGateway.getRoute(actionTarget);
		if(route != null){
			Type t;
			if(!string.isBlank(route.Namespace__c)){
				t = Type.forName(route.Namespace__c, route.Target__c);
			}else{
				t = Type.forName(route.Target__c);
			}
			actionType = (Action.Target)t.newInstance();
		}else{
			throw new BaseControllerException('Unknown target');
		}
		Action.Response r = actionType.execute(obj);
		long nowTime = system.now().getTime();
		system.debug('TIME: '  + (nowTime - thenTime));
		system.debug('resp: ' + r);
		return r;
	}

	@RemoteAction
	global static List<SelectListItem> lookupSearch(string searchTerm, string objectName) {
		return lookupSearchFilter(searchTerm, objectName, '');
	}

	@RemoteAction
	global static List<SelectListItem> lookupSearchFilter(string searchTerm, string objectName, string filterCriteria) {
		SchemaUtil util = SchemaUtil.getInstance();
		List<SelectListItem> selectList = new List<SelectListItem>();

		if (String.isBlank(objectName))
		{
			return selectList;
		}

		Schema.SObjectType objectType = util.getGlobalDescribe(objectName);

		SOQLUtil soql = new SOQLUtil(objectName);
		soql.addFields(new set<string>{'Id', 'Name'});

		String filterString = '';
		System.debug(LoggingLevel.INFO, '*** searchTerm: ' + searchTerm);
		if(String.isNotBlank(searchTerm)){
			filterString += 'Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';

			if(searchTerm.length() <= 3) {
				soql.setLimit(100);
			}
		}else{
			soql.setLimit(100);
		}

		if(String.isNotBlank(filterCriteria)){
			if(filterString.trim().startsWith('Name')) {
				filterString += ' AND ' + filterCriteria;
			}
			else {
				filterString += filterCriteria;
			}
		}

		soql.setWhereClause(filterString);
		soql.setOrderByClause('Name');
		system.debug('query: ' + soql.getQuery());
		List<SObject> result = Database.query(soql.getQuery());

		for (SObject obj : result) {
			String id = String.valueOf(obj.get('Id'));
			String name = String.valueOf(obj.get('Name'));

			selectList.add(new SelectListItem(id, name));
		}

		return selectList;
	}

	@RemoteAction
	global static set<SelectListItem> lookupSearchFilterNoDuplicates(string searchTerm, string objectName, string filterCriteria) {
		SchemaUtil util = SchemaUtil.getInstance();
		set<SelectListItem> selectList = new set<SelectListItem>();
		map<id,list<SelectListItem>>  mSelectItems = new map<id,list<SelectListItem>>();
		if (String.isBlank(objectName))
		{
			return selectList;
		}

		Schema.SObjectType objectType = util.getGlobalDescribe(objectName);

		SOQLUtil soql = new SOQLUtil(objectName);
		soql.addFields(new set<string>{'Name'});
		String filterString = '';
		System.debug(LoggingLevel.INFO, '*** searchTerm: ' + searchTerm);
		if(String.isNotBlank(searchTerm)){
			filterString += 'Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';

			if(searchTerm.length() <= 3) {
				soql.setLimit(100);
			}
		}

		if(String.isNotBlank(filterCriteria)){
			if(filterString.trim().startsWith('Name')) {
				filterString += ' AND ' + filterCriteria;
			}
			else {
				filterString += filterCriteria;
			}
		}
		if(String.isNotBlank(searchTerm)){
			filterString += ' GROUP BY Name';

		}
		soql.setWhereClause(filterString );
		//soql.setOrderByClause('Name');
		system.debug('query: ' + soql.getQuery());
		List<SObject> result = Database.query(soql.getQuery());
		set<string> sObjectNameSet = new set<string>();
	    /*for (SObject obj : result) {
	    	//String id = String.valueOf(obj.get('Id'));
			String name = String.valueOf(obj.get('Name'));
			sObjectNameSet.add(name);
		}*/
		for (SObject obj : result) {
			selectList.add(new SelectListItem(String.valueOf(obj.get('Name')), String.valueOf(obj.get('Name'))));

		}

		return selectList;
	}

	@RemoteAction
	global static List<SelectListItem> getPicklistValues(string objectName, string fieldName)
	{
		SchemaUtil util = SchemaUtil.getInstance();
		List<SelectListItem> selectList = new List<SelectListItem>();

		if (String.isBlank(objectName) || String.isBlank(fieldName))
		{
			return selectList;
		}

		Map<String, sObjectField> fieldmap = util.getFieldsMap(objectName);
		Schema.DescribeFieldResult dfr = fieldMap.get(fieldName).getDescribe();

		if (dfr.getType() == Schema.DisplayType.Picklist) {
			selectList.add(new SelectListItem(' ', '--Any--'));

			for (Schema.PicklistEntry pe : dfr.getPicklistValues()) {
				if (pe.isActive()) {
					selectList.add(new SelectListItem(pe.getValue(), pe.getLabel()));
				}
			}
		}

		return selectList;
	}

	@RemoteAction
	global static Serial__c refreshSerialAttr( Id serialId ){

		set<String> serialFields = new set<string>{ 'id', 'name', 'Fixed_Asset__r.Name'};
		serialFields.addAll(SchemaUtil.getInstance().getAllCustomFieldsFromObject(null, 'Serial__c'));
		String whereClause = ' Id =:serialId ';

		SOQLUtil soql = new SOQLUtil('Serial__c');
		soql.addFields(serialFields);
		soql.setWhereClause(whereClause);

		List<Serial__c> serials = (List<Serial__c>)Database.query(soql.getQuery());
		if(serials.size() > 0){
			return serials[0];
		}
		else{
			return null;
		}
	}

    @RemoteAction
    global static Location__c getLocation(Id locId) {
        SOQLUtil locQuery = new SOQLUtil('Location__c');
        locQuery.addFields(new Set<String>{ 'Id', 'Name', 'Bin_Tracked__c', 'Facility__c', 'Mixed_Bins_Allowed__c', 'Track_Bin_Capacity__c' });
        locQuery.setWhereClause('Id = :locId');
        return Database.query(locQuery.getQuery());
    }

    @RemoteAction
    global static Bin__c getBin(Id binId) {
        SOQLUtil binQuery = new SOQLUtil('Bin__c');
        binQuery.addFields(new Set<String>{ 'Id', 'Name', 'Blocked__c', 'Location__c', 'Max_Capacity__c', 'Packaging_UOM__c', 'Packaging_UOM__r.Package_Class__c' });
        binQuery.setWhereClause('Id = :binId');
        return Database.query(binQuery.getQuery());
    }
}
