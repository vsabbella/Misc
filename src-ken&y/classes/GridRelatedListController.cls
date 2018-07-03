global virtual with sharing class GridRelatedListController extends BaseController {
    global string NamespaceUU { get { return KSE.NamespaceUU; }} 
    private static SchemaUtil util = SchemaUtil.getInstance();
     
    global GridRelatedListConfig config {get; set;}
    public string fieldList = null;
    public List<FieldInfo> fieldInfoList;

    global class GridRelatedListConfig {
        global String uniqueId { get; set; }
        global String title { get; set; }
        global SObject parentRecord { get; set; }
        global String objectName { get; set; }
        global String parentField { get; set; }
        global String fieldset { get; set; }
        global String additionalFields { get; set; }
        global String readOnlyFields { get; set; }
        global String buttons { get; set; }
        global Integer pageSize { get; set; }   
        global String height { get; set; }  
        global String sortField { get; set; }
        global string sortOrder { get; set; }
        global string namespace { get; set; }
        global string addlWhereClause {get; set; }   
            
        global Boolean alwaysUseFullDateTimeFormat { 
            get; set {
                // Set the flag on field info to make data formatting work as required
                FieldInfo.AlwaysUseFullDateTimeFormat = value;
                alwaysUseFullDateTimeFormat = value;
            }
        }                                 
    }

    global GridRelatedListController() {
        this.config = new GridRelatedListConfig();
    }
    
    public virtual String getConfigJson() {
		if (String.isNotBlank(this.config.namespace)) {
		util.namespace = this.config.namespace;
        }
        
        String configStr = JSON.serialize(this.config);
          
        System.debug(configStr);
        return configStr;
    }
    
    public virtual string getFieldList() {
        if (fieldList == null && config != null) {
            fieldInfoList = FieldInfo.fetchJsonFieldInfos(config.objectName, config.fieldset, config.readOnlyFields);
            fieldList = JSON.serialize(fieldInfoList);
        }
        
        return fieldList;
    }
    
    @RemoteAction 
    global static DataSourceResult getRelatedList(GridRelatedListConfig config) {
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : null;
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        //String additionalFields = (String.isNotBlank(config.additionalFields)) ? config.additionalFields : null;
        //RS - prevent empty field refs in the query from unspecified additional fields in the component

        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        String whereClause = '';
        
        if ( String.isNotEmpty( parentfield )) {
            whereClause = parentId == null ?  parentfield + ' != null' : parentfield + ' = :parentId';
        }
        
        //RS - add supplemental where clause where necessary
        if(config.addlWhereClause != null && config.addlWhereClause != ''){
            if ( String.isNotBlank(whereClause)) {
                whereClause += ' AND ';
            }
        	whereClause += ' (' + config.addlWhereClause.replace('\\', '') + ')';
        }
        
        //RS - add sort order and sequence for returned records based on optional component inputs
        if(String.isNotBlank(config.sortField)){
            whereClause += ' ORDER BY ' + config.sortField;
            if(String.isNotBlank(config.sortOrder)){
                whereClause += ' ' + config.sortOrder;
            }
        }
        
        if (String.isNotBlank(config.namespace)) {
        		util.namespace = config.namespace;
        }
        
       /* String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        List<sObject> result = database.query(queryString); */
        
        
        SOQLUtil soql = new SOQLUtil(config.objectName);
        soql.addFields(fieldset);
        soql.addFields(addlFields);
        soql.setWhereClause(whereClause);
        List<sObject> result = database.query(soql.getQuery() ); 
         
        return new DataSourceResult(result, result.size());
    }
    
    public static Map<String,String> childObjectMap(sObject parentRecord) {

		Map<String,String> childMap = new Map<String,String>();

		if(parentRecord != null) {
			Schema.DescribeSObjectResult dsr = parentRecord.getSObjectType().getDescribe();
			List<Schema.ChildRelationship> childObjects = dsr.getChildRelationships(); 
			
			for(Schema.ChildRelationship child : childObjects) {
				// KNDY-12186 KNDY-12050 get only the Master-Detail relationship objects
				if(!child.isCascadeDelete()){
					continue;
				}
				Schema.DescribeFieldResult childDFR = child.getField().getDescribe();
				if(childDFR.isCustom()) {
					childMap.put(child.getChildSObject().getDescribe().getLocalName(),childDFR.getLocalName());
				}
			}
		}
		return childMap;

	}
	
	public static Map<Id,String> taskWhatIds (sObject parentRecord, GridRelatedListConfig config) {
		Map<Id,String> whatIds = new Map<Id,String>();
		Id parentId = (parentRecord != null && String.isNotBlank(parentRecord.Id)) ? parentRecord.Id : '';
        whatIds.put(parentRecord.Id,(String) parentRecord.get('Name'));
        
        Map<String,String> childMap = childObjectMap(parentRecord);

        for(String type : childMap.keyset()) {
			//String query = 'SELECT Id, Name FROM ' + type + ' WHERE ' + childMap.get(type) + ' = \'' + parentId + '\''; 
            
            String whereClause = + childMap.get(type) + ' = \'' + parentId + '\'';//KNDY-8796
            SOQLUtil soql = new SOQLUtil(type);
            soql.addFields(new Set<String>{'Id', 'Name'});
            soql.setWhereClause(whereClause);
			//for(sObject obj : database.query(query)) {
            for(sObject obj : database.query(soql.getQuery())) {    
				whatIds.put(obj.Id, (String) obj.get('Name'));
			}
		}

		return whatIds;
	}
    
    @RemoteAction 
    global static DataSourceResult getTaskRelatedList(GridRelatedListConfig config) {
        Id parentId = (config.parentRecord != null && String.isNotBlank(config.parentRecord.Id)) ? config.parentRecord.Id : '';
        String fieldset = (String.isNotBlank(config.fieldset)) ? config.fieldset : '';
        //String additionalFields = (String.isNotBlank(config.additionalFields)) ? config.additionalFields : null;
        //RS - prevent empty field refs in the query from unspecified additional fields in the component
        set<string> addlFields = (String.isNotBlank(config.additionalFields)) ? new set<string>(config.additionalFields.split(',')) : null;
        String parentfield = (String.isNotBlank(config.parentfield)) ? config.parentfield : '';
        
        Set<Id> whatIds = taskWhatIds(config.ParentRecord, config).keyset();

        string whereClause = parentfield + ' IN :whatIds AND isClosed = false and Type = \'Exception\'';
        //RS - add supplemental where clause where necessary
        if(config.addlWhereClause != null && config.addlWhereClause != ''){
        	whereClause += ' AND (' + config.addlWhereClause.replace('\\', '') + ')';
        }
        
        whereClause += ' ORDER BY CreatedDate DESC,Source_Document_Id__c DESC NULLS LAST,WhatId DESC ';
        
        
        if (String.isNotBlank(config.namespace)) {
        		util.namespace = config.namespace;
        }
        
        /*String queryString = util.generateQueryFromFieldSet(config.objectName, new Set<string>{ fieldset }, addlFields, whereClause);
        
        List<sObject> result = database.query(queryString); */
        //KNDY-8796
        SOQLUtil soql = new SOQLUtil(config.objectName,true);
        soql.addFields(fieldset);
        soql.addFields(addlFields);
        soql.setWhereClause(whereClause);
        List<sObject> result = database.query(soql.getQuery()); 
        return new DataSourceResult(result, result.size());
    }
    
    @RemoteAction
    global static DataSourceResult saveRelatedList(List<SObject> updatedList, List<SObject> newList, List<Sobject> deletedList) {
        DataSourceResult result = new DataSourceResult();
        Savepoint sp = Database.setSavepoint();

        try {
            if (updatedList.size() > 0) {
                DML.updateAsUser(updatedList); 
            }
            
            if (newList.size() > 0) {
                DML.insertAsUser(newList);
            }
            
            if (deletedList.size() > 0) {
                DML.deleteAsUser(deletedList);
            }
            // Leave it from here and let JS handle !
            result.addMessage('Your changes have been saved successfully', ApexPages.Severity.CONFIRM);

        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e, ApexPages.Severity.ERROR);
        }

        return result;
    }
    
    
     @RemoteAction
    global static DataSourceResult saveList(List<SObject> updatedList, List<SObject> newList, List<Sobject> deletedList, List<String> dateFields) {
    	for (SObject row: updatedList) { 
        	KendoUtils.UpdateDateFields(row, dateFields);
		}
		
		for (SObject row: newList) { 
        	KendoUtils.UpdateDateFields(row, dateFields);
		}
		
        DataSourceResult result = new DataSourceResult();
        Savepoint sp = Database.setSavepoint();

        try {
            if (updatedList.size() > 0) {
                DML.updateAsUser(updatedList); 
            }
            
            if (newList.size() > 0) {
                DML.insertAsUser(newList);
            }
            
            if (deletedList.size() > 0) {
                // OTC-439 users with Del perm on object can delete any row (even owned by others)
                new DML.WithoutSharing().sobjectDel( deletedList );
            }
            // Leave it from here and let JS handle !
            result.addMessage('Your changes have been saved successfully', ApexPages.Severity.CONFIRM);

        } catch (Exception e) {
            Database.rollback(sp);
            result.success = false;
            result.addMessage(e, ApexPages.Severity.ERROR);
        }

        return result;
    }
}