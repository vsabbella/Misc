/** 
 * @description utilities to build queries and field lists  
 */
global with sharing class SchemaUtil {
	global static SchemaUtil getInstance(){
        if ( instance == null ) instance = new SchemaUtil();
        return instance;
    } 
   	private static SchemaUtil instance = null;
	
	private Map<String, Schema.SObjectType> globalDescribe;
	
	global string namespace { get; set; } 
	private string namespaceUU { get {  return  String.isNotBlank(namespace)  ? namespace+'__' : '' ; } }
	
	// TODO make this a private constructor 
	// private SchemaUtil() {  	
	global SchemaUtil() {  		
		globalDescribe=Schema.getGlobalDescribe();  
		namespace=KSE.namespace;
	} 
	
	global class SchemaUtilException extends Exception {}
	
	global Schema.SObjectType getGlobalDescribe(string sObjectName) { 
		if ( globalDescribe.containsKey( namespaceUU + sObjectName ) ) 
			return globalDescribe.get( namespaceUU + sObjectName); 
		else if ( globalDescribe.containsKey( sObjectName) ) 
			return globalDescribe.get(sObjectName);
		else 
			throw new SchemaUtilException('Cannot locate sobject by name :'+sObjectName);
	}    
	
	public Boolean objectExists(string sObjectName){
        //KNDY-7410
        sObjectName = sObjectName == null ? '' : sObjectName.toLowerCase();
        if (globalDescribe.containsKey(namespaceUU.toLowerCase() + sObjectName)) {
            return true;    
        } else if (globalDescribe.containsKey(sObjectName)) {
            return true;      
        } else {
            return false;     
        }        
	}
	
	public boolean fieldExists(string sObjectName, string fieldName){
		//KNDY-7410
        if(objectExists(sObjectName)){
		    fieldName = fieldName == null ? '' : fieldName.toLowerCase();
            if(getFieldsMap(sObjectName).containsKey(namespaceUU.toLowerCase() + fieldName)){
				return true;
            } else if (getFieldsMap(sObjectName).containsKey(fieldName)) {
				return true;
            } else {
				return false;
			}
		} else {
			return false;
		}
	}

	public Schema.DescribeFieldResult retrieveFieldDescribeResult(string sObjectName, string fieldName){
		if(objectExists(sObjectName)){
			fieldName = fieldName == null ? '' : fieldName.toLowerCase();
			if(getFieldsMap(sObjectName).containsKey(namespaceUU.toLowerCase() + fieldName)){
				return getFieldsMap(sObjectName).get(namespaceUU.toLowerCase() + fieldName).getDescribe();
			} else if (getFieldsMap(sObjectName).containsKey(fieldName)) {
				return getFieldsMap(sObjectName).get(fieldName).getDescribe();
			} else {
				throw new SchemaUtilException('Unable to resolve sObject field');
			}
		} else {
			throw new SchemaUtilException('Unable to resolve sObject field');
		}
	}

	//Check if the fieldpath is valid.
    public boolean isValidFieldPath(string fieldPath, string sObjectName){
		
		if ( fieldPath == null || string.isBlank(fieldPath) == true ) {
			return false;		
		}
		
		string baseObject = sObjectName;
		map<string, sObjectField> mObjectFields = SchemaUtil.getInstance().getFieldsMap(baseObject);
		string fieldRef = fieldPath;
		
		if(fieldPath.contains('.')){
			//We're crawling the foreign keys to resolve the object and field
			string[] refStringArray = fieldPath.split('\\.');
			for(Integer i=0, j=refStringArray.size(); i<j; i++) {
				
				fieldRef = refStringArray[i];
				if(fieldRef.endsWith('__r')){
					fieldRef = fieldRef.removeEnd('__r') + '__c';
				}
				system.debug('fieldRef'+fieldRef);
				system.debug('mObjectFields'+JSON.serialize(mObjectFields.keyset()));
				
				Schema.Describefieldresult fld;
				if(mObjectFields.containsKey(fieldRef)){
					//for custom object relationships
					fld = mObjectFields.get(fieldRef).getDescribe();
					system.debug('fld'+fld);					
				}else if(mObjectFields.containsKey(fieldRef+'id')){
					//for standard object relationships...
					fld = mObjectFields.get(fieldRef+'id').getDescribe();
				}
				
				if(fld == null){ 				
					throw new SchemaUtilException('Unable to resolve field path ' + fieldPath + ' on ' + sObjectName); }
				
				
				if(!fld.getReferenceTo().isEmpty()){
					baseObject = fld.getReferenceTo()[0].getDescribe().getLocalName();
									system.debug('baseObject'+baseObject);
					
					mObjectFields = SchemaUtil.getInstance().getFieldsMap(baseObject);
				}
				
			}
		}
		
		Schema.Describefieldresult fld;
		if(mObjectFields.containsKey(fieldRef)){
			//for custom object relationships
			fld = mObjectFields.get(fieldRef).getDescribe();
		}else if(mObjectFields.containsKey(fieldRef+'id')){
			//for standard object relationships...
			fld = mObjectFields.get(fieldRef+'id').getDescribe();
		}
		
		if(fld == null){ throw new SchemaUtilException('Unable to resolve field path ' + fieldPath + ' on ' + sObjectName); }
		return true;
	}
		
	public boolean isFieldAccessible(string fieldPath, string sObjectName){
		
		if ( fieldPath == null || string.isBlank(fieldPath) == true ) {
			return false;		
		}
		
		string baseObject = sObjectName;
		map<string, sObjectField> mObjectFields = SchemaUtil.getInstance().getFieldsMap(baseObject);
		string fieldRef = fieldPath;
		
		if(fieldPath.contains('.')){
			//We're crawling the foreign keys to resolve the object and field
			string[] refStringArray = fieldPath.split('\\.');
			for(Integer i=0, j=refStringArray.size(); i<j; i++) {
				
				fieldRef = refStringArray[i];
				if(fieldRef.endsWith('__r')){
					fieldRef = fieldRef.removeEnd('__r') + '__c';
				}
				Schema.Describefieldresult fld;
				if(mObjectFields.containsKey(fieldRef)){
					//for custom object relationships
					fld = mObjectFields.get(fieldRef).getDescribe();
				}else if(mObjectFields.containsKey(fieldRef+'id')){
					//for standard object relationships...
					fld = mObjectFields.get(fieldRef+'id').getDescribe();
				}
				if(fld == null){ throw new SchemaUtilException('Unable to resolve field path ' + fieldPath + ' on ' + sObjectName); }
				
				if(!fld.isAccessible()){ 
					//There is a gap in accessibility across the foreign keys
					return false;
				}
				
				//System.debug(LoggingLevel.INFO, '*** baseObject: ' + baseObject);
				//System.debug(LoggingLevel.INFO, '*** fieldRef: ' + fieldRef);
				// The i!=j-1 exists because we want to only reassign baseObject and fieldRef if path terminates on a referenced object
				if(!fld.getReferenceTo().isEmpty() && i != j-1){
					baseObject = fld.getReferenceTo()[0].getDescribe().getLocalName();
					//System.debug(LoggingLevel.INFO, '*** baseObject: ' + baseObject);
					mObjectFields = SchemaUtil.getInstance().getFieldsMap(baseObject);
					//System.debug(LoggingLevel.INFO, '*** mObjectFields: ' + mObjectFields);
				}
				
			}
		}
		
		Schema.Describefieldresult fld;
		if(mObjectFields.containsKey(fieldRef)){
			//for custom object relationships
			fld = mObjectFields.get(fieldRef).getDescribe();
		}else if(mObjectFields.containsKey(fieldRef+'id')){
			//for standard object relationships...
			fld = mObjectFields.get(fieldRef+'id').getDescribe();
		}
		
		if(fld == null){ throw new SchemaUtilException('Unable to resolve field path ' + fieldPath + ' on ' + sObjectName); }
		return fld.isAccessible();
	}
	
	public Map<String, Schema.FieldSet> generateFieldSetsFromObjectName(String sObjectName){
		//system.debug(logginglevel.info,'sobjName'+sObjectName+','+globalDescribe.keySet());
		//describe the provided sObject  
    		Schema.DescribeSObjectResult res=getGlobalDescribe(sObjectName).getDescribe();  
	    
	    //get the fields set map  
	    Map<String, Schema.FieldSet> fieldSetMap= res.FieldSets.getMap();
	    return fieldSetMap; 
	}
	
	public Set<String> removeNSfromSetString(Set<String> inputSet) {
		Set<String> outputSet = new Set<String>();
	    for(String s : inputSet ){  
        	if (s != null) {
	        	s = s.replace( namespaceUU, '').replace(namespaceUU.toLowerCase(),'');
				outputSet.add(s);        		
        	}
	     }			
		return outputSet; 	
	}
	
	public String removeNSfromString(String input) {
		String output;
        	if (input != null) {
	        	output = input.replace( namespaceUU, '').replace(namespaceUU.toLowerCase(),'');
        	}
		return output; 	
	}
	
   	/*  
   	 *  http://blogforce9.blogspot.com/2012/10/generate-query-from-fieldsets.html
   	 */
	public String generateQueryFromFieldSet(String 			sObjectName,	
											Set<String> 	fieldSets,
											Set<String> 	additionalFields,
											String 			whereClause){
		
		SOQLUtil soql = new SOQLUtil(sObjectName);
		
		Set<String> fields_s = new Set<String>{'Id'};
		if (sObjectName != 'Task') {
			fields_s.add('name');
		}

		if (additionalFields != null)  {
			for (string s : additionalFields) {
				if (!s.containsIgnoreCase('select ')) {
					fields_s.add(s.toLowerCase().trim()); 
				} else {
					// A subquery is being passed in the additionalFields
					SOQLUtil.ChildRelationship childRel = soql.createChildRelationship(s);
			        soql.addChildRelationship(childRel);
				}
			}
		}

		Schema.DescribeSObjectResult res = getGlobalDescribe(sObjectName).getDescribe();  
		Map<String, Schema.FieldSet> fieldSetMap= res.fieldSets.getMap();
	  //  //iterate through provided fieldsets and generate query  
	    for (String fieldSetName : fieldSets){  
    		for (Schema.FieldSetMember fsm : this.getFieldsFromFieldSet(res.getSobjectType(), fieldSetName)){            
	       		fields_s.add(fsm.getFieldPath().replace( namespaceUU, '').toLowerCase().trim());  
	       		if( String.valueOf( fsm.getType() ) == 'REFERENCE'){
	       			String refName = fsm.getFieldPath().replace('__c','__r.Name');
	       			fields_s.add(refName.replace(namespaceUU, '').toLowerCase().trim()); 
		       	}  
			}
	     }	
	     
		// some fields are too important to be left out	     
		for (sObjectField sf : this.getFieldsMap(sObjectName).values() ) {
			Schema.DescribeFieldResult dfr = sf.getDescribe();
			
			if (dfr.getType() == Schema.DisplayType.REFERENCE && 
				dfr.isDefaultedOnCreate()  == false && 
				dfr.isNillable() == false ) {
				String refName = dfr.getName();
				fields_s.add(refName.replace(namespaceUU, '').toLowerCase().trim());
			}
	       	
	       	String refName = dfr.getName().replace(namespaceUU, '').toLowerCase();
	       	if(fields_s.contains(refName) && dfr.getType() == Schema.DisplayType.REFERENCE){
	       	    fields_s.add(refName.replace('__c','__r.Name').toLowerCase().trim());
	       	}
	    }


		soql.addFields(fields_s);
		if (String.isNotBlank(whereClause)){
			soql.setWhereClause(whereClause);
		}
		return soql.getQuery();
	
	}  

	public Schema.SObjectType getSObjectType( id myRecordID) {
        return myRecordID.getSObjectType(); 			// introduced in or about V27.0  
	}   
	
	/**
	 *  @description Describes all fields for a given sObject and returns them in a string to be used for a query.  
	 *     This is a query * in other languages
	 *
	 */ 
	global string getFieldsforQuery(string objectType){
		
		string searchString = '';
		system.assert( objecttype != null, 'No value for objectType.  Expected valid SObject');

		Schema.DescribesobjectResult obj = getGlobalDescribe(objectType).getDescribe();
		//system.debug(obj.fields.getMap());
		for(Schema.sObjectField fieldapi: obj.fields.getMap().values()) {
			if(string.valueof(fieldAPI).contains('Autonumber')==false){ // TODO: this is brittle
				searchstring += string.valueof(fieldAPI) + ', ';
			}
		}
		searchString = searchString.left(searchString.length()-2);
		
		return searchString;
	} 
	
	/**
	Should use this method to return only KNDY packaged fields. 
	when called internally this would work like getAllCustomFieldsFromSObject
	
	**/
	global set<String> getAllPackagedFieldsFromSObject (String prefix, string objectType) {
    	
    	set<String> fields = new set<String>();
		if(String.isBlank(namespaceUU))
			fields = getAllCustomFieldsFromObject(prefix, objectType);
		
		else {
			Schema.DescribesobjectResult obj = getGlobalDescribe(objectType).getDescribe();
			for(Schema.sObjectField fieldapi: obj.fields.getMap().values()) {
				
				if(string.valueof(fieldAPI).contains('__c') && string.valueof(fieldAPI).startswith(namespaceUU)){
					if( prefix == null )
						fields.add( string.valueof(fieldAPI).replace( namespaceUU, '').toLowerCase() );
					else
						fields.add( prefix + string.valueof(fieldAPI).replace( namespaceUU, '').toLowerCase() );	
				}
			}
		}
		
		
		return fields;
    }
	    
	
	
	global set<String> getAllCustomFieldsFromObject( String prefix,  string objectType ){
		
		Schema.DescribesobjectResult obj = getGlobalDescribe(objectType).getDescribe();
		set<String> fields = new set<String>();
		
		for(Schema.sObjectField fieldapi: obj.fields.getMap().values()) {
			
			if( string.valueof(fieldAPI).contains('__c') ){
				if( prefix == null )
					fields.add( string.valueof(fieldAPI).replace( namespaceUU, '').toLowerCase() );
				else
					fields.add( prefix + string.valueof(fieldAPI).replace( namespaceUU, '').toLowerCase() );	
			}
		}
		
		return fields;
	}
	
	global String getObjectNameFromId(Id recId) { //strip out 
		String objectName = recId.getSObjectType().getDescribe().getName();
		return objectname.replace(namespaceUU, '');
	}
	/** 
	 * @description return the list of  picklist values from a picklist field given the objectName  and picklistField Name 
	 */	 
	public list<Schema.PicklistEntry> getPickListEntriesFromField(string objectName,string pickListField)
	{
		//The key in the below map is not prefixed with Namespace by Salesforce if both executing code and object are in the same NS.
		//Thereby,As this method can be called only by classes within our package we need not handle for namespace.
		map<string,Schema.SObjectField> mFieldNameToFieldToken = getFieldsMap(objectName);
		if( mFieldNameToFieldToken.containsKey(pickListField))
		{
		    Schema.DescribeFieldResult FieldDescResult= mFieldNameToFieldToken.get(pickListField).getDescribe();
		    if(FieldDescResult.getType()==Schema.DisplayType.PICKLIST || FieldDescResult.getType()==Schema.DisplayType.MULTIPICKLIST)
		    {
			   return FieldDescResult.getPickListValues();					    	
		    }
		    else
		    {
		    	throw new SchemaUtilException(pickListField+'is not a  pickListField');
		    }
		}
		else
		{
			throw new SchemaUtilException('Cannot locate field by name :'+pickListField+'in object '+objectName);
		}	
		
	}
	
	/** 
	 * @description return the list of  FieldSetMember from an object given the SObject Type and name 
	 * of the field set.  Take into account the namespace if present
	 */
	public  List<Schema.FieldSetMember> getFieldsFromFieldSet( Schema.SObjectType  objectType, string fieldSet ) {
        
        system.assert( objectType != null, 'expected a valid sobject type'+objectType );
        
        List<Schema.FieldSetMember> ret = new List<Schema.FieldSetMember>(); 
        Map<String, Schema.FieldSet> fieldSetMap = objectType.getDescribe().FieldSets.getMap();
        String fsName = namespaceUU + fieldSet;	
        
        if (fieldSetMap.containsKey(fsName)) {   
        	ret = fieldSetMap.get(fsName).getFields();
        }
        else if (fieldSetMap.containsKey(fieldSet)) {
        	ret = fieldSetMap.get(fieldSet).getFields();
        }else{
        	throw new SchemaUtilException('No fieldset found for ' + fieldSet + ' on ' + objectType.getDescribe().getLocalName());
        }
        
        return ret; 
    }
	
	/** 
	 * @description return the list of Strings from an object given the SObject Type and name 
	 * of the field set.  Take into account the namespace if present
	 */
	public  List<String> getFieldsFromFieldSetString( Schema.SObjectType  objectType, string fieldSet ) {
        
        system.assert( objectType != null, 'expected a valid sobject type'+objectType );
        
        List<Schema.FieldSetMember> ret = new List<Schema.FieldSetMember>(); 
        List<String> strReturn = new List<String>();
        
        String fsName = KSE.NamespaceUU + fieldSet;	
        
        if (  objectType.getDescribe().FieldSets.getMap().get(fsName) != null ) {   
        		ret = (objectType.getDescribe().FieldSets.getMap().get(fsName).getFields() ) ;
        		//system.debug(logginglevel.info,'ret:'+ret);
        }
        for(Schema.FieldSetMember fsm: ret){
        	//system.debug(logginglevel.info,'fsm.getFieldPath():'+fsm.getFieldPath());
        	strReturn.add(fsm.getFieldPath());
        }
        //system.debug(logginglevel.info,'strReturn:'+strReturn);
        return strReturn; 
    }
    
    public  List<String> getFieldsFromFieldSetString( string sObjectName, string fieldSet ) {
    	Schema.sObjectType sObjType = getGlobalDescribe(sObjectName);
    	return getFieldsFromFieldSetString( sObjType, fieldSet);
    }
	 
	/** 
	  * @description return the map of the sObjectField
	  */
	public Map<String, sObjectField> getFieldsMap(string objectName) {
		if(mObjectFields.containsKey(objectName)){
			return mObjectFields.get(objectName);
		}else{

			//KNDY-7410
			Map<String, sObjectField> objectFields = addNoNSfieldsToMap(getGlobalDescribe(objectName).getDescribe().fields.getMap());
			
			mObjectFields.put(objectName, objectFields);
			return objectFields;
		}
	}


	/*
	* KNDY-7410: objectType.getDescribe().fields.getMap(); has changed.  
	* this method lets our legacy code work by referring with or without the namespace
	*/
	public Map<String, sObjectField> addNoNSfieldsToMap(Map<String, sObjectField> inMap) {
		if (inMap == null) {
			return null;
		}
		
		//clone the map we passed in
		Map<String, sObjectField> outMap = new Map<String, sObjectField>(inMap);
		
		String nsUUlCase = namespaceUU.toLowerCase();	
			
		//loop through all the fields in this map, create a copy with the ns removed	
		for (String f: inMap.keySet()) {
			outMap.put(f.removeStart(nsUUlCase), inMap.get(f));
		}				
		
		return outMap;
	}
	
	public Map<String, String> getFieldNamesMap(string objectName) {
		Map<String, String> objectFields = new Map<String, String>();
		for(sObjectField f : getGlobalDescribe(objectName).getDescribe().fields.getMap().values()) {
			objectFields.put(f.getDescribe().getName(), f.getDescribe().getLabel());
		}	
		
		return objectFields;
	}
	
	
	private Map<String, Map<String, sObjectField>> mObjectFields = new Map<String, Map<String, sObjectField>>();
	
	 
	/** 
	  * @description find all the related custom object fields given an object name 
	  * return a list
	  */
	public list<string> relatedCustomObjects(string sobjectname) { 
		list<string> ret = new list<string>(); 
		for ( sObjectField sf : this.getFieldsMap( sobjectname ).values() ) {
			Schema.DescribeFieldResult dfr = sf.getDescribe();
			if ( dfr.getType() == Schema.DisplayType.REFERENCE && dfr.isCustom() ) {
				//system.debug(logginglevel.info, dfr.getName() + '  ' + dfr.getType() );
				ret.add( dfr.getName() );	
			}
		}
		return ret;
	}	
	
	public string getLocalNameFromObject(sObject sObjectRec){
		return sObjectRec.getsObjectType().getDescribe().getLocalName();
	}
	
	public string getObjectPrefix(sObject sObjectRec){
		return sObjectRec.getsObjectType().getDescribe().getKeyPrefix();
	}
	
	private class QueryFilter{
		Set<String> stringValues = new Set<String>();
		Set<Date> dateValues = new Set<Date>();
		Set<Datetime> dateTimeValues = new Set<Datetime>();
	}
	
	
	public String formatDateTimeForSOQL(DateTime filterDateTime) {
       	
       		if(filterDateTime == null)
       			throw new SchemaUtilException('Cannot pass an empty dateTime for formatting');
       		else
       			return filterDateTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
       }
	
	public static String getQueryFilter(List<sObject> records, Set<String> fieldNames){
		String queryWithFilters = ' Id != null '; // Dummy where clause.
        List<Date> dateList = new List<Date>();
		map<String, QueryFilter> fieldValuesMap = new map<String, QueryFilter>();
        
		for(String fieldName : fieldNames){
			for(SObject record : records){
				
				if(record == null){
					continue;
				}
				if(record.get(fieldName) != null){
	        		if(! fieldValuesMap.containsKey(fieldName)){
	        			fieldValuesMap.put(fieldName, new QueryFilter());
	        		}
	        		
	        		if(record.get(fieldName) instanceof String){
	        			fieldValuesMap.get(fieldName).stringValues.add(String.valueOf(record.get(fieldName)));
	        		}
	        		else
	        		if(record.get(fieldName) instanceof Id){
	        			fieldValuesMap.get(fieldName).stringValues.add(String.valueOf(record.get(fieldName)));
	        		}
	        		else
	        		if(record.get(fieldName) instanceof Date){
	        			fieldValuesMap.get(fieldName).dateValues.add((Date) record.get(fieldName));
	        		}
	        		else
	        		if(record.get(fieldName) instanceof DateTime){
	        			fieldValuesMap.get(fieldName).dateTimeValues.add(((DateTime)record.get(fieldName)));
	        		}
	        	}
	        }
		}
       for(String fieldName : fieldValuesMap.keySet()){
        	if( fieldValuesMap.containsKey(fieldName) && (fieldValuesMap.get(fieldName).stringValues.size() > 0 || fieldValuesMap.get(fieldName).dateValues.size() > 0 ||  fieldValuesMap.get(fieldName).dateTimeValues.size() > 0)){
        		String values = '(';
        		
        		Iterator<String> iStringValues = fieldValuesMap.get(fieldName).stringValues.iterator();
        	
		        while(iStringValues.hasNext()){
		            values += '\'' + iStringValues.next() + '\'';
		            
		            if(iStringValues.hasNext()){
		                values += ' , ';    
		            }
		        }
		        
		        Iterator<Date> iDateValues = fieldValuesMap.get(fieldName).dateValues.iterator();
		        Iterator<DateTime> iDateTimeValues = fieldValuesMap.get(fieldName).dateTimeValues.iterator();
		        while(iDateValues.hasNext()){
		        	
		        	Date dt = iDateValues.next();
		        	String dtstr = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('yyyy-MM-dd');
		            values += dtstr;
		            
		            if(iDateValues.hasNext()){
		                values += ' , ';    
		            }
		        }
		        while(iDateTimeValues.hasNext()){  
 		        	  
 		        	DateTime dtime = iDateTimeValues.next();
 		        	
		        	String dtimestr = DateTime.newInstance(dtime.yearGmt(),dtime.monthGmt(),dtime.dayGmt(),dtime.hourGmt(),dtime.minuteGmt(),dtime.secondGmt()).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
 		            values += dtimestr;
 		            
 		            if(iDateTimeValues.hasNext()){
		                values += ' , ';    
 		            }
 		        }
		        
		        values += ')';
        		
        		queryWithFilters += ' AND (' + fieldName + ' IN '+ values +' OR ' + fieldName + ' = null )';
	        }
        }
        
		return queryWithFilters;
	}
}