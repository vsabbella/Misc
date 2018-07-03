public with sharing class SOQLUtil {
    
    public class SOQLUtilException extends Exception{}
    
    protected string sObjectName;
    protected string whereClause;
    protected string orderByClause;
    protected boolean enforceFLS;
    protected integer limitRows;
    protected Integer offset;
    protected boolean searchRecycle;
    protected Schema.sObjectType sObjType;
    protected set<string> queryFields;
    protected set<string> subQueries;
    protected map<string, ChildRelationship> mChildRelationships = new map<string, ChildRelationship>();   
    
    public   enum sortOrder {SORTASC, SORTDESC}
    protected map<string,string> mFieldNameToSortOrder = new map<string,string>();   
    protected boolean setNullsLast = false;
    protected boolean isAggregateQuery = false;
    
    protected boolean forUpdate = false;
    
    @TestVisible
    private static boolean overrideFLS {
    	get{
    		if(overrideFLS == null && Test.isRunningTest()){
    			//Security review: this query is intentionally in user mode.
				User usr = [select id, FirstName, LastName, UserType, Profile.Name from User where id = :UserInfo.getUserId() LIMIT 1];
    			String profileName = usr.Profile.Name;
				
                if(profileName != null && profileName.equalsIgnoreCase('System Administrator')){
                    overrideFLS = true;
				}else{
					overrideFLS = false;
				}
			}
            
            //don't want custom permissions to be more restrictive.
			//don't bother re-setting the flag if it is already set
            if (overrideFLS != true) {
            	overrideFLS = Permissions.checkSystemMode();    
            }
            
            
            if(overrideFLS == null){
                return false;
            }else{
               	return overrideFLS;
    		}
        }
    	set;
    }
    
    //public enum sortOrder {ASCENDING, DESCENDING}
    //default: enforce FLS, unless test
    public SOQLUtil(string sObjectName){
    	this(sObjectName, !overrideFLS);
    }
    
    public SOQLUtil(string sObjectName, boolean enforceFLS){
    	this(sObjectName, enforceFLS, false);
    }
    
    public SOQLUtil(string sObjectName, boolean enforceFLS, boolean isAggregateQuery){
        if(!SchemaUtil.getInstance().objectExists(sObjectName)){
            throw new SOQLUtilException(sObjectName + ' is not a valid sObject');
        }
        
        this.queryFields = new set<string>();
        this.subQueries = new set<string>();
        this.sObjectName = sObjectName;
        this.sObjType = SchemaUtil.getInstance().getGlobalDescribe(this.sObjectName);
        this.searchRecycle = false;
        this.isAggregateQuery = isAggregateQuery;
        
        if(overrideFLS){
        	this.enforceFLS = false;
        }else{
        	this.enforceFLS = enforceFLS;
        }
    }
    
    public class ChildRelationship{
    	
    	protected string childSObjectName;
    	protected string relationshipName;
    	protected set<string> queryFields;
    	protected string whereClause;
        protected string orderByClause;
    	protected integer limitRows;
    	protected Schema.sObjectType sObjType;
    	protected Schema.sObjectType childSObject;
    	protected boolean enforceFLS;
	    protected map<string,string> mFieldNameToSortOrder = new map<string,string>();   
	    protected boolean setNullsLast = false;
	    protected string childOrderByClause;   	
	    
    	public ChildRelationship(SOQLUtil soql, string relationshipName){
    		
    		this.sObjType = soql.sObjType;
    		this.enforceFLS = soql.enforceFLS;
    		List<Schema.ChildRelationship> childRelationships = soql.sObjType.getDescribe().getChildRelationships();
	    	boolean foundRelationship = false;
    		set<string> childFields = new set<string>();
	    	for(Schema.ChildRelationship cr : childRelationships){
	    		if(cr.getRelationShipName() == relationshipName){
	    			foundRelationship = true;
	    			this.childSObject = cr.getChildSObject();
	    			this.childSObjectName = childSObject.getDescribe().getName();
	    		}else if(cr.getRelationShipName() == KSE.NamespaceUU + relationshipName){
	    			foundRelationship = true;
	    			this.childSObject = cr.getChildSObject();
	    			this.childSObjectName = childSObject.getDescribe().getName();
	    		}
	    	}
	    	
    		if(!foundRelationship){
	    		throw new SOQLUtilException('Unable to resolve child relationship ' + relationshipName + ' on ' + sObjType.getDescribe().getLocalName());
	    	}
	    	
	    	this.relationshipName = relationshipName;
    		this.queryFields = new set<string>();
		    		
    	}
    	
    	public void addField(string fieldPath){
    		if(fieldPath == null){
    			return;
    		}
            if (fieldPath.contains(',')) {
                addFields(new set<string>(fieldPath.split(',')));
            } else {
    		    addFields(new set<string>{fieldPath});
    		}
    	}
    	
    	public void addAllFields(){
    		set<string> allFields = new set<string>();
	    	for(Schema.sObjectField sObjField : this.childSObject.getDescribe().fields.getMap().values()) {
				allFields.add(string.valueOf(sObjField));
			}
			addFields(allFields);
	    }
    	
    	// fields identified in the excludeFields will be not be added while adding all fields for the object
    	public void addAllFields(Set<String> excludeFields ){
    		set<string> allFields = new set<string>();
	    	for(Schema.sObjectField sObjField : this.childSObject.getDescribe().fields.getMap().values()) {
				String field = string.valueOf(sObjField) ;
				if ( excludeFields.contains( field )  == false )
				    allFields.add(field);
			}
			addFields(allFields);
	    }
	    
        public void addAllCustomFields() { addAllCustomFields(childSObject,null); }
        public void addAllCustomFields(sObjectType objType,String prefix) {
            if (String.isBlank(prefix)) prefix = '';
            else prefix += '.';
            
            Set<String> fieldList = new Set<String>();
            for (Schema.sObjectField sObjField:objType.getDescribe().fields.getMap().values()) {
                String fieldStr = String.valueOf(sObjField).toLowerCase();
                if (fieldStr.endsWith('__c') || fieldStr == 'id' || fieldStr == 'name') {
                    fieldList.add(prefix + fieldStr);
                }
            }
            addFields(fieldList);
        }
	    
    	public void addFields(string fieldsetName){

            //Adding reference Name field as kendoUI Widgets require it to be rendered correctly.    		
            list<string> fieldNames = new list<string>();
		    list<Schema.FieldSetMember> fsmList = new list<Schema.FieldSetMember>(); 
		    Schema.sObjectType childSObjType = schemaUtil.getInstance().getGlobalDescribe(this.childSobjectName);
		    
		    Map<String, Schema.FieldSet> fieldSetMap = childSObjType.getDescribe().FieldSets.getMap();
		    String fsName = KSE.namespaceUU + fieldsetName;	
		    
		    if (fieldSetMap.containsKey(fsName)) {   
		    	fsmList = fieldSetMap.get(fsName).getFields();
		    }
		    else if (fieldSetMap.containsKey(fieldsetName)) {
		    	fsmList = fieldSetMap.get(fieldsetName).getFields();
		    }
			for( Schema.FieldSetMember fsm : fsmList ){            
	       		fieldNames.add( fsm.getFieldPath());//.replace( KSE.namespaceUU, '').toLowerCase().trim() );  
	       		
	       		if( String.valueOf( fsm.getType() ) == 'REFERENCE'){
	       			String refName = fsm.getFieldPath().replace( KSE.namespaceUU, '').toLowerCase().trim();
	       			if(refName.endsWith('__c')){
	       				refName = KSE.replaceLast(refName, '__c', '__r.name');	
	       			}
	       			fieldNames.add( refName ); 
		       	} 
			}
	        addFields(new set<string>(fieldNames));
	    }
    	
    	public void addFields(set<string> fieldPaths){
    		if(fieldPaths == null){
    			return;
    		}
    		Schema.sObjectType sObjType = schemaUtil.getInstance().getGlobalDescribe(this.childSobjectName);
        	Map<String, Schema.sObjectField> fieldsMap = sObjType.getDescribe().fields.getMap();
        	String namespaceUU = String.isBlank(KSE.NamespaceUU) ? '' : KSE.NamespaceUU.toLowerCase();
        	
			for(string s : fieldPaths){
				if(s == null){
					continue;
				}
				string fieldPath = string.escapeSingleQuotes(s);
				fieldpath = fieldpath.trim();//Removing spaces
				
	            if(isFieldAccessible(this.childSObjectName, fieldPath)){
	                fieldPath = fieldPath.toLowerCase().replace(namespaceUU, '');
	                queryFields.add(fieldPath);
	            }
	            
	            Schema.sObjectField sObjField;
            	sObjField = fieldsMap.containsKey(fieldPath) ? fieldsMap.get(fieldPath) : fieldsMap.get(namespaceUU + fieldPath);
            
	            if(sObjField != null){
					Schema.DescribeFieldResult dfr = sObjField.getDescribe();
					
					String refName = fieldPath.replace(namespaceUU, '').toLowerCase().trim();
					
					if(queryFields.contains(fieldPath) && dfr.getType() == Schema.DisplayType.REFERENCE){
						if(refName.endsWith('__c')){
		       				refName = KSE.replaceLast(refName, '__c', '__r.name');	
		       			}
		       			queryFields.add(refName);
			       	}
	            }
	    	}
        }
        
    	public void setWhereClause(string whereClause){
	        this.whereClause = whereClause;
	    }
	    
	    //Builds order by clause given map of field names to their sorting order.    
	    public void setOrderBy(map<string,SOQLUtil.sortOrder> mInputFieldNameToOrder)
	    {
			 for(string fieldName: mInputFieldNameToOrder.keyset())
			 {
			 	if(SchemaUtil.getInstance().isValidFieldPath(fieldName.trim(), this.childSObjectName) )
			 	{
					SOQLUtil.sortOrder sortOrderVal = mInputFieldNameToOrder.get(fieldName);
				 	if(sortOrderVal == sortOrder.sortASC)
				 	{
				 		mFieldNameToSortOrder.put(fieldName.trim(),'ASC');
				 	}
				 	else if(sortOrderVal  == sortOrder.sortDESC)
				 	{
				 		mFieldNameToSortOrder.put(fieldName.trim(),'DESC');			 		
				 	}
				 	else
				 	{
				 		//Not possible as we use Enums.
				 		throw new SOQLUtilException('Invalid sort order specified for '+mInputFieldNameToOrder.get(fieldName));
				 	}	 		
			 	}
			 	else
			 	{
			 		//If Bad field path specified then Schemautil will throw exception.
			 	}
		 	
			 }    	
	    }
	    
	    public void removeOrderBy(string fieldName)
	    {
	    	if(mFieldNameToSortOrder.containsKey(fieldName))
	    	{
	         	mFieldNameToSortOrder.remove(fieldName);    
	         	system.debug('mFieldNameToSortOrder in remove:'+mFieldNameToSortOrder);	    		
	    	}
	    	else
	    	{
	    		throw new SOQLUtilException('Invalid sort field specified');    		
	    	}
	    }	    
	    public string getWhereClause(){
	        return this.whereClause;
	    }
	    
        public void setOrderByClause(string orderByClause){
            this.orderByClause = orderByClause;
        }
        
        public string getOrderByClause(){
            return this.orderByClause;
        }
	    
	    public void setLimit(integer limitRows){
	        this.limitRows = limitRows;
	    }
	    
	    public integer getLimit(){
	        return this.limitRows;
	    }
	    
	    public string getSubquery(){
	    	string subQuery = '(SELECT ' + string.join(new list<string>(this.queryFields), ',') + ' FROM ' + this.relationshipName;
    		if(!string.isEmpty(this.whereClause)){
    			subQuery += ' WHERE ' + this.whereClause;
    		}
	    	
            if(mFieldNameToSortOrder.keyset().size()>0)
	        {
	        	set<string> orderByComponents = new set<string>();
	        	for(String fieldName :mFieldNameToSortOrder.keyset())
	        	{
	        		orderByComponents.add(fieldName+' '+ mFieldNameToSortOrder.get(fieldName));
	        	}
	        	childOrderByClause=String.join(new list<string>(orderByComponents),',');
	        	subQuery+= ' ORDER BY '+ childOrderByClause;
		        if(setNullsLast)
		        {
		        	subQuery+=' NULLS LAST ';
		        }
	        	
	        }
	        else if ( String.isNotEmpty (this.orderByClause) ) {
	            subQuery += ' ORDER BY ' + this.orderByClause ;
	        }
            
    		if(this.limitRows != null){
    			subQuery += ' LIMIT ' + this.limitRows;
    		}
    		subQuery += ')';
    		//system.debug('subQuery '+subQuery);
    		return subQuery;
	    }

	    private boolean isFieldAccessible(string sObjectName, string fieldPath){
	    	//If a bad field path is specified, schemautil will throw an exception
	       return SchemaUtil.getInstance().isFieldAccessible(fieldPath, sObjectName) || !enforceFLS;
	    }
	    
    }// ChildRelationship class ends here.
    
    public void setOrderBy(map<string,sortOrder> mInputFieldNameToOrder,Boolean setNullsLast)
    {
    	this.setNullsLast=true;//Default is Nulls first.
    	setOrderBy(mInputFieldNameToOrder);
    }
    //Builds order by clause given map of field names to their sorting order.    
    public void setOrderBy(map<string,sortOrder> mInputFieldNameToOrder)
    {
		 for(string fieldName: mInputFieldNameToOrder.keyset())
		 {
		 	if(SchemaUtil.getInstance().isValidFieldPath(fieldName, this.sObjectName) )
		 	{
				sortOrder sortOrderVal = mInputFieldNameToOrder.get(fieldName);
			 	if(sortOrderVal == sortOrder.sortASC)
			 	{
			 		mFieldNameToSortOrder.put(fieldName,'ASC');
			 	}
			 	else if(sortOrderVal  == sortOrder.sortDESC)
			 	{
			 		mFieldNameToSortOrder.put(fieldName,'DESC');			 		
			 	}
			 	else
			 	{
			 		//Not possible as we use Enums.
			 		throw new SOQLUtilException('Invalid sort order specified for '+mInputFieldNameToOrder.get(fieldName));
			 	}	 		
		 	}
		 	else
		 	{
		 		//If Bad field path specified then Schemautil will throw exception.
		 	}
	 	
		 }    	
    }
    
    public void removeOrderBy(string fieldName)
    {
    	if(mFieldNameToSortOrder.containsKey(fieldName))
    	{
         	mFieldNameToSortOrder.remove(fieldName); 
         	system.debug('mFieldNameToSortOrder in remove:'+mFieldNameToSortOrder);	    		
         	   	    		
    	}
    	else
    	{
    		throw new SOQLUtilException('Invalid sort field specified');    		
    	}
    }
    
    public void addAllFields(){
    	for(Schema.sObjectField sObjField : sObjType.getDescribe().fields.getMap().values()) {
			addField(string.valueOf(sObjField));
		}
    }
    
    // fields identified in the excludeFields will be not be added while adding all fields for the object
	public void addAllFields(Set<String> excludeFields ){
		for(Schema.sObjectField sObjField : sObjType.getDescribe().fields.getMap().values()) {
			String field = string.valueOf(sObjField) ;
			if ( excludeFields.contains( field )  == false )
			    addField( field );
		}
    }
    
    public void addAllCustomFields() { addAllCustomFields(sObjType,null); }
    public void addAllCustomFields(sObjectType objType,String prefix) {
        if (String.isBlank(prefix)) prefix = '';
        else prefix += '.';
            
        Set<String> fieldList = new Set<String>();
        for (Schema.sObjectField sObjField:objType.getDescribe().fields.getMap().values()) {
            String fieldStr = String.valueOf(sObjField).toLowerCase();
            if (fieldStr.endsWith('__c') || fieldStr == 'id' || fieldStr == 'name') {
                fieldList.add(prefix + fieldStr);
            }
        }
        addFields(fieldList);
    }

	public void addField(string fieldPath){
		if(fieldPath == null){
			return;
		}
        if (fieldPath.contains(',')) {
            addFields(new set<string>(fieldPath.split(',')));
        } else {
		    addFields(new set<string>{fieldPath});
		}
	}    

    public void addFields(string fieldsetName){
        //Adding reference Name field as kendoUI Widgets require it to be rendered correctly.    		
        list<string> fieldNames = new list<string>();
	    list<Schema.FieldSetMember> fsmList = new list<Schema.FieldSetMember>(); 
	    
	    Map<String, Schema.FieldSet> fieldSetMap = sObjType.getDescribe().FieldSets.getMap();
	    String fsName = KSE.namespaceUU + fieldsetName;	
	    
	    if (fieldSetMap.containsKey(fsName)) {   
	    	fsmList = fieldSetMap.get(fsName).getFields();
	    }
	    else if (fieldSetMap.containsKey(fieldsetName)) {
	    	fsmList = fieldSetMap.get(fieldsetName).getFields();
	    }
		for( Schema.FieldSetMember fsm : fsmList ){            
       		fieldNames.add( fsm.getFieldPath());//.replace( KSE.namespaceUU, '').toLowerCase().trim() );  
       		/*if( String.valueOf( fsm.getType() ) == 'REFERENCE'){
       			String refName = fsm.getFieldPath();
       			
       			if(refName.endsWith('__c')){
       				refName = KSE.replaceLast(refName, '__c', '__r.Name');	
       			}
       			 
       			fieldNames.add( refName.replace( KSE.namespaceUU, '').toLowerCase().trim() ); 
	       	} */
		}
        addFields(new set<string>(fieldNames));
    }

    public void addFields(set<string> fieldPaths){
    	if(fieldPaths == null){
    		return ;
    	}	
	    Map<String, Schema.sObjectField> fieldsMap = sObjType.getDescribe().fields.getMap();
        String namespaceUU = String.isBlank(KSE.NamespaceUU) ? '' : KSE.NamespaceUU.toLowerCase();
        
        for(string s : fieldPaths){
            if(s == null){
            	continue;
            }
            
			string fieldPath = string.escapeSingleQuotes(s);
            fieldpath = fieldpath.trim();
            
			//special case for count() queries which return Integer
            Boolean isCount = (fieldpath.toLowerCase() == 'count()');             
            
            String fieldApiName = fieldpath;
			
			// Get the fieldname from aggregate query columns
            if(fieldApiName.indexOf('(') > -1){
            	fieldApiName = fieldApiName.substring(fieldApiName.indexOf('(') + 1, fieldApiName.indexOf(')')).trim();
            }
			
			// Get the fieldname from alias columns
            if(fieldApiName.indexOf(' ') > -1){
            	fieldApiName = fieldApiName.substring(0, fieldApiName.indexOf(' ')).trim();
            } 
            
            //check the fieldApiName for accessibility, unless it is a count() query, use Id instead 
            //since count() isn't a real field on the object
            String fieldToCheck = isCount ? 'id' : fieldApiName;
            
            // Add the original field
            if(isFieldAccessible(this.sObjectName, fieldToCheck)){
            	fieldPath = fieldPath.toLowerCase().replace(namespaceUU, '');
            	queryFields.add(fieldPath);
            }
            
            // Add the '.Name' field if the specified field is a reference type
            if(! this.isAggregateQuery ){ // Don't add '.Name' for fields in an aggregate query.
	            addNameField(this.SObjType, fieldApiName);
	        }
        }
    }
    
    private void addNameField(SObjectType fieldSObjectType, String fieldApiName){
    	
    	String[] fieldSegments = fieldApiName.split('\\.');
         
        String namespaceUU = String.isBlank(KSE.NamespaceUU) ? '' : KSE.NamespaceUU.toLowerCase();
        
        Boolean isReference = false;
        
        for(String fieldSegment : fieldSegments){
        	if(fieldSegment.endsWith('__r')){
        		fieldSegment = KSE.replaceLast(fieldSegment, '__r', '__c');	
            }
        	
        	Schema.sObjectField sObjField;
        	Map<String, Schema.sObjectField> fieldsMap = fieldSObjectType.getDescribe().fields.getMap();
        	
        	sObjField = fieldsMap.containsKey(fieldSegment) ? fieldsMap.get(fieldSegment) : fieldsMap.get(namespaceUU + fieldSegment);
            
            if(sObjField != null){
	            Schema.DescribeFieldResult dfr = sObjField.getDescribe();
	        	
	        	if(isFieldAccessible(fieldSObjectType.getDescribe().getLocalName(), fieldSegment) 
	        		&& dfr.getType() == Schema.DisplayType.Reference 
	        		&& ! dfr.isNamePointing()
	        	){
	    			isReference = true;
	        		fieldSObjectType = dfr.getReferenceTo()[0];
	    		}else{
	    			isReference = false;
	            	break;
	            }
            }
    	}
        
        if(isReference){
        	fieldApiName = fieldApiName.toLowerCase().replace(namespaceUU, '');
					
			if(queryFields.contains(fieldApiName)){
				String refName = fieldApiName;
   			
       			if(refName.endsWith('__c')){
       				String nameFieldPath = '';
       				Map<String, Schema.sObjectField> fieldsMap = fieldSObjectType.getDescribe().fields.getMap();
       				
       				if(fieldsMap.containsKey('name')){
       					nameFieldPath = 'name';
       				}else if(fieldSObjectType.getDescribe().getLocalName() == 'QuoteLineItem'){//special case of quote line item object
       					nameFieldPath =  'LineNumber'; 
       				}
       				else{
       					nameFieldPath = fieldSObjectType.getDescribe().getLocalName() + 'Number'; // Ex: CaseNumber
       				}
       				
       				if(! String.isBlank(nameFieldPath)){
	       				refName = KSE.replaceLast(refName, '__c', '__r.'+nameFieldPath);
	       				queryFields.add(refName);
       				}	
	       		}
       		}
        }
    }

    public Set<String> getFields() { return this.queryFields; }
    
    public void addChildRelationship(ChildRelationship childRelationship){
     	mChildRelationships.put(childRelationship.relationshipName, childRelationship);
    }
    
    public ChildRelationship getChildRelationship(string relationshipName){
    	return mChildRelationships.get(relationshipName);
    }
    
    public List<ChildRelationship> getChildRelationships(){
    	return mChildRelationships.values();
    }
    
    public void removeChildRelationship(string relationshipName){
    	mChildRelationships.remove(relationshipName);
    }
    
    public void setWhereClause(string whereClause){
        this.whereClause = whereClause;
    }
    
    public string getWhereClause(){
        return this.whereClause;
    }

    public void setOrderByClause(string orderByClause){
        this.orderByClause = orderByClause;
    }
    
    public string getOrderByClause(){
        return this.orderByClause;
    }

    public void setLimit(integer limitRows){
        this.limitRows = limitRows;
    }
    
    public integer getLimit(){
        return this.limitRows;
    }
    
    public void setForUpdate () {
        this.forUpdate = true;
    }
    
    public void unsetForUpdate () {
        this.forUpdate = false;
    }

    public void setOffset(Integer offset) {
    	this.offset = offset;
    }

    public Integer getOffset() {
    	return this.offset;
    }
    
    public void setSearchRecycle(boolean searchRecycle){
        this.searchRecycle = searchRecycle;
    }
    
    public boolean getSearchRecycle(){
        return this.searchRecycle;
    }
    
    public string getQuery(){
        
        if(queryFields.isEmpty()){
            throw new SOQLUtilException('No fields specified for query for sObject '+this.sObjectName);
        }
        
        string query = 'SELECT ' + string.join(new list<string>(this.queryFields),',');
        
        
        if(mChildRelationships.keySet().size() > 0){
        	for(string relationshipName : mChildRelationships.keySet()){
	    		subQueries.add(mChildRelationships.get(relationshipName).getSubquery());
        	}
        	
	        if(!subQueries.isEmpty()){
	        	query += ',' + string.join(new list<string>(this.subQueries),',');
	        }
        }
        
        query += ' FROM ' + this.sObjectName;
        
        if(!string.isBlank(this.whereClause)){
            query += ' WHERE ' + whereClause;
        }

        if(mFieldNameToSortOrder.keyset().size()>0)
        {
        	set<string> orderByComponents = new set<string>();
        	for(String fieldName :mFieldNameToSortOrder.keyset())
        	{
        		orderByComponents.add(fieldName+' '+ mFieldNameToSortOrder.get(fieldName));
        	}
        	orderByClause=String.join(new list<string>(orderByComponents),',');
        	query+= ' ORDER BY '+ orderByClause;
	        if(setNullsLast)
	        {
	        	query+=' NULLS LAST ';
	        }        	

        }
        else if ( String.isNotEmpty( this.orderByClause ) ) {
            query += ' ORDER BY ' + this.orderByClause ;
        }
	        
        if(limitRows != null){
            query += ' LIMIT ' + limitRows;
        }

        if (offset != null) {
        	query += ' OFFSET ' + offset;
        }
        
        if(searchRecycle){
            query += ' ALL ROWS';
        }
        
        // Note: You can’t use the ORDER BY keywords in any SOQL query that uses locking.
        // SOQL parser will throw a QueryException
        if (this.forUpdate ) {
            query += ' FOR UPDATE ';
        }

        //system.debug('query: ' + query);
        return query;
    }
    
    public list<sObject> returnQueryResult(){
        List<sObject> sObjRecs;
        try{
            sObjRecs = Database.query(getQuery()); 
        }catch(Exception ex){
            throw new SOQLUtilException(ex.getMessage());
        }
        return sObjRecs;
    }
    
    public ChildRelationship createChildRelationship(string query){
        // VG: This may be a temp fix. Should we force SchemaUtil.generateQueryFromFieldSet additionalFields
        // to not include subqueries?
        // Takes a subquery string, parses it as a ChildRelationship, and adds it the soql object
        //query = query.toLowerCase().replace(')','').trim();
        query = query.trim().removeEnd(')').trim();
        query = KSE.replaceCaseInsensitive(query, 'select ', 'select ');
        query = KSE.replaceCaseInsensitive(query, 'from ', 'from ');
        query = KSE.replaceCaseInsensitive(query, 'where ', 'where ');
        query = KSE.replaceCaseInsensitive(query, 'order by ', 'order by ');
        list<string> soqlKeywords = new list<string>{'from ', 'where ', 'order by ', 'limit '};
        if (query.containsIgnoreCase('select')){
            string fieldNames = query.substringBetween('select ', 'from ').toLowerCase().replaceAll('(\\s+)', '');
            map<string, string> chunkData = new map<string, string>(); // keyword, data
            // the soql keywords are the list of optional keywords.. loop through them
            for (integer i=0; i<soqlKeywords.size(); i++){
                if (query.containsIgnoreCase(soqlKeywords[i])) {
                    // start by adding the keyword and data until the end
                    chunkData.put(soqlKeywords[i], query.substring(query.indexOfIgnoreCase(soqlKeywords[i])));
                    for (integer j=i+1; j<soqlKeywords.size(); j++){
                        if (query.containsIgnoreCase(soqlKeywords[j])) {
                            // if you find a keyword that exists in the soql keywords list, update the data chunk map
                            chunkData.put(soqlKeywords[i], query.substringBetween(soqlKeywords[i], soqlKeywords[j]));
                            break;
                        }
                    }
                }
            }

            
            set<string> fieldNamesSet = new set<string>();
            fieldNamesSet.addAll(fieldNames.split(','));                
            
            string whereClause;
            string orderByClause;
            integer limitBy;
            string relationshipName;

            for (string keyword : chunkData.keySet()) {
                if (keyword == 'from '){
                    relationshipName = chunkData.get('from ').replace('from', '').trim();
                } else if (keyword == 'where '){
                    whereClause = chunkData.get('where ').replace('where', '').trim();
                } else if (keyword == 'order by '){
                    orderByClause = chunkData.get('order by ').replace ('order by','').trim();
                } else if (keyword == 'limit '){
                    limitBy = integer.valueof(chunkData.get('limit ').replace('limit', '').trim());
                }
            }

            SOQLUtil.ChildRelationship childRelationship = new SOQLUtil.ChildRelationship(this, relationshipName);
            
            childRelationship.addFields(fieldNamesSet);
            childRelationship.setWhereClause(whereClause);
            childRelationship.setOrderByClause(orderByClause);
            childRelationship.setLimit(limitBy);

            return childRelationship;
        } else {
            throw new SOQLUtilException('Unable to parse subquery ' + query );
        }   
    }

    private boolean isFieldAccessible(string sObjectName, string fieldPath){
    	//If a bad field path is specified, schemautil will throw an exception
    	
    	Boolean isFieldAccessible = SchemaUtil.getInstance().isFieldAccessible(fieldPath, sObjectName);
    	
    	if(enforceFLS){
    		return isFieldAccessible;
    	}else{
    		return true;
    	}
    }
}