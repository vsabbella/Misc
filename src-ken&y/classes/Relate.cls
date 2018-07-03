global with sharing class Relate {
    /** 
     * @description Static utility methods used by several triggers to set
     * default lookups based on text identifiers.  Useful for data loading processes
     * 
     */

    global static void setLookupUsingField( List<sobject> objects, Boolean isBefore,string relatedObjectAPIName, string lvalue , string rvalue) { 
            setLookupUsingField(objects, isBefore, relatedObjectAPIName, lvalue, rvalue, rvalue);
    }
    
    global static void setLookupUsingField( List<sobject> objects, Boolean isBefore,
                                    string relatedObjectAPIName,     // object we will query info from 
                                    string lvalue ,                     	// final field name to PUT into (field in objects)
                                    string rvalue,                      // related fieldname in objects that relates to a record in relatedObjectAPIName
                                    string sourcevalue) {           // field where the value is in relatedObjectAPIName  
        
        if ( isBefore == false ) {  return ; }
     	
     	//system.debug(logginglevel.INFO, 'set lookup using  ' + relatedObjectAPIName);
     	
        List<String> ref = new List<string>();
    
        for ( Sobject obj: objects ) { 
            if ( obj.get(lvalue) == null  && obj.get(rvalue) != null ) {
                ref.add( (string)obj.get(rvalue) );
            }
        }
        
        //system.debug(logginglevel.INFO, ref + ' srcvalue : ' + sourcevalue);
        
        if (ref.size() > 0 ) {

        	Map<string,id> myMap = new Map<string,id>();
            
            String whereClause = sourcevalue + ' in :ref ';

		    SOQLUtil soql = new SOQLUtil(relatedObjectAPIName);
		    soql.addFields(new Set<String>{'id', sourcevalue});
		    soql.setWhereClause(whereClause);
	    
        	/*for ( sobject i: Database.query('select id, '+sourcevalue + 
                                                        '  from ' + relatedObjectAPIName +
                                                        '  where '+sourcevalue+'  in :ref ') ) {*/
            for ( sobject i: Database.query(soql.getQuery())){
            	myMap.put( (string)i.get(sourcevalue), i.id);
        	}
			//system.debug(logginglevel.INFO, myMap.keySet() );
		
			for ( sobject obj: objects) { 
                if (    obj.get(lvalue) == null     && 
                        obj.get(rvalue) != null     && 
                        myMap.containsKey( (string)obj.get(rvalue) ) )  
                {
                    obj.put(lvalue, myMap.get( (string)obj.get(rvalue) ) );
                }
            }
        }
    }

	/**
	 * setRecordTypeUsingDeveloperName()
	 * 
	 * in some orgs the lvalue will be not null in the insert phase (record type defaults), 
	 * therefore we cannot rely on lvalue == null instead we will force that during insert, 
	 * if the rvalue is provided, perform the query and set the record type. KNDY-6040 
	 */  
	global static void setRecordTypeUsingDeveloperName( List<sobject> objects, Boolean isBefore, string rvalue) 
    {         
        string relatedObjectAPIName = 'RecordType';
		string lvalue ='RecordTypeId';   
       	string sourcevalue = 'DeveloperName';
                                                                       
        if ( isBefore == false ) { return; }
     	
        List<String> ref = new List<string>();

        for ( Sobject obj: objects ) {
            if ( (obj.get(lvalue) == null || trigger.isInsert) && obj.get(rvalue) != null ) {
                ref.add( (string)obj.get(rvalue) );
            }
        }
        
        //system.debug(logginglevel.INFO, ref + ' srcvalue : ' + sourcevalue);
        
        if (ref.size() > 0 ) {

        	Map<string,id> myMap = new Map<string,id>();
            
            String whereClause = sourcevalue + ' in :ref ';
    
		    SOQLUtil soql = new SOQLUtil(relatedObjectAPIName);
		    soql.addFields(new Set<String>{'id', sourcevalue});
		    soql.setWhereClause(whereClause);
    
        	/*for ( sobject i: Database.query('select id, '+sourcevalue + 
                                                        '  from ' + relatedObjectAPIName +
                                                        '  where '+sourcevalue+'  in :ref ') ) {*/
            for ( sobject i: Database.query(soql.getQuery()) ) {
            	myMap.put( (string)i.get(sourcevalue), i.id);
        	}
			//system.debug(logginglevel.INFO, myMap.keySet() );
		
			for ( sobject obj: objects) { 
                if (   obj.get(rvalue) != null     && 
                        myMap.containsKey( (string)obj.get(rvalue) ) )  
                {
                    obj.put(lvalue, myMap.get( (string)obj.get(rvalue) ) );
                }
            }
        }                                
        
    }
}