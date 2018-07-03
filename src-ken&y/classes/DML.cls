public with sharing class DML {
	
	private static boolean check_access = ( Test.isRunningTest() == false ); // dont throw IA exception in tests 
	@TestVisible
	private static final string globalDispatch = 'GTRGRDSPTCH';
	@TestVisible
	private static final string globalDispatchDisable = 'DISABLE';
	@TestVisible 
	private static Datetime systemTime = system.now();
	public static boolean checkTriggerDispatch(Schema.sObjectType sObjType){
        
		Configuration__c globalDispatchConfig = Configuration__c.getInstance(globalDispatch);
		if(globalDispatchConfig != null){
			//Global disable - unit testing or db migrations
            if(checkDispatchTime(globalDispatchConfig)){
            	return globalDispatchDisable == globalDispatchConfig.value__c;
            }else{
                delete globalDispatchConfig;
            }
			
		}
        
        string sObjectName = sObjType.getDescribe().getLocalName();
        string dispatchKey = sObjectName + '-' + sObjType.getDescribe().getKeyPrefix();
        Configuration__c config = Configuration__c.getInstance(dispatchKey);
        if(config != null){
			Id userId;
            try{
                userId = (Id)config.value__c;
            }catch(Exception ex){
                //do nothing
            }
            
            if(checkDispatchTime(config)){
                return userId == userinfo.getUserId();
            }else{
                delete config;
            }
		}
        return false;
	}
    
    private static boolean checkDispatchTime(Configuration__c config){
        return config.CreatedDate >= systemTime.addHours(-1);
    }
	
	public class InsuffientAccessException extends Exception {}
	
    public without sharing class WithoutSharing {
        public void sobjectDel( sobject[] records) {
            if ( records.size() >0 && records[0].getSObjectType().getDescribe().isDeletable() == false ) {
                throw new InsuffientAccessException();
            }	
            Database.delete( records );
        }
    }
    
	/*
	Instead of calling DML directly, call the methods below which explicitly state we are inserting in system mode, or user mode.
	When in user mode, we check for CRUD / FLS access before doing the DML.  If they don't have access we throw an exception.
	
	Unfortunately this method doesn't work for upserts for 2 reasons:  
	1) upserts can't be done on a generic sObject/sObject list
	2) we can't pass in the the upsert key as a variable 
	  
	so for upserts we use this pattern in the calling code:
	
	system mode:
	DML.upsertAsSystem(); upsert sObjectList key;
	
	user mode:
	DML.checkUpsertAsUser(sObjectList); upsert sObjectList;
	*/    
    
    
    /*
    * BEGIN: Pass-thru methods to do raw DML operations in system mode.  Allows us to explicity show this
    * is what we mean to do for security review purposes. 
    */
	//system mode, single object
	public static Database.SaveResult   insertAsSystem(sObject obj) { return Database.insert(obj); }
	public static Database.SaveResult   updateAsSystem(sObject obj) { return Database.update(obj); }
	public static Database.DeleteResult deleteAsSystem(sObject obj) { return Database.delete(obj); }	

	//system mode, lists of object, allOrNone=true (default)
	public static List<Database.SaveResult>   insertAsSystem(List<SObject> objList) { return Database.insert(objList); }
	public static List<Database.SaveResult>   updateAsSystem(List<SObject> objList) { return Database.update(objList); }
	public static List<Database.DeleteResult> deleteAsSystem(List<SObject> objList) { return Database.delete(objList); }		
	public static List<Database.DeleteResult> deleteAsSystem(List<Id> idList)       { return Database.delete(idList);  }	
	
	//system mode, lists of object, allOrNone is passed in
	public static List<Database.SaveResult>   insertAsSystem(List<SObject> objList, Boolean allOrNone) { return Database.insert(objList, allOrNone); }
	public static List<Database.SaveResult>   updateAsSystem(List<SObject> objList, Boolean allOrNone) { return Database.update(objList, allOrNone); }
	public static List<Database.DeleteResult> deleteAsSystem(List<SObject> objList, Boolean allOrNone) { return Database.delete(objList, allOrNone); }		
	public static List<Database.DeleteResult> deleteAsSystem(List<Id> idList, Boolean allOrNone)       { return Database.delete(idList, allOrNone);  }		

	//checks for access to upsert.  since it is in system mode, nothing really to check.  more for documentation purposes.
	public static void upsertAsSystem() {}
    /*
	* END system mode
    */	


    /*
    * BEGIN: DML in user mode methods
    */
    //user mode, single object
    public static Database.SaveResult insertAsUser(sObject obj) { 
		//if custom Permissions have entered us into System Mode, run in system mode.
		//else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.insert(obj); 
        } else {
            return insertAsUserWorker(obj, true);     
        }
    }
    public static Database.SaveResult updateAsUser(sObject obj) { 
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.update(obj); 
        } else {
            return updateAsUserWorker(obj, true);    
        }        
    }
    
    public static Database.DeleteResult deleteAsUser(sObject obj) {
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.delete(obj); 
        } else {
            return deleteAsUserWorker(obj, true);     
        }             
    }		    
    
    //user mode, lists of object, allOrNone=true (default)
    public static List<Database.SaveResult> insertAsUser(List<SObject> objList)	{
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.insert(objList);
        } else {
            return insertAsUserWorker(objList, true);     
        }               
    }
    public static List<Database.SaveResult> updateAsUser(List<SObject> objList) { 
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.update(objList);
        } else {
            return updateAsUserWorker(objList, true);     
        }            
    }
    public static List<Database.DeleteResult> deleteAsUser(List<SObject> objList) {
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.delete(objList);
        } else {
            return deleteAsUserWorker(objList, true);     
        }            
    }	
    public static List<Database.DeleteResult> deleteAsUser(List<Id> idList) { 
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.delete(idList);
        } else {
            return deleteAsUserWorker(idList, true);    
        }            
    }	
    
    //user mode, lists of object, allOrNone is passed in
    public static List<Database.SaveResult> insertAsUser(List<SObject> objList, Boolean allOrNone) { 
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.insert(objList, allOrNone);
        } else {
            return insertAsUserWorker(objList, allOrNone);
        }            
    }
    public static List<Database.SaveResult> updateAsUser(List<SObject> objList, Boolean allOrNone) { 
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.update(objList, allOrNone);
        } else {
            return updateAsUserWorker(objList, allOrNone); 
        }               
    }
    public static List<Database.DeleteResult> deleteAsUser(List<SObject> objList, Boolean allOrNone) { 
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.delete(objList, allOrNone);
        } else {
            return deleteAsUserWorker(objList, allOrNone);  
        }               
    }
    public static List<Database.DeleteResult> deleteAsUser(List<Id> idList, Boolean allOrNone) { 
        //if custom Permissions have entered us into System Mode, run in system mode.
        //else do CRUD/FLS checks
        if (Permissions.checkSystemMode()) {
            return Database.delete(idList, allOrNone);
        } else {
            return deleteAsUserWorker(idList, allOrNone);   
        }               
    }				

    //checks for access to upsert.  use these in calling class before doing an upsert.  allows for all upsert features to be used like ext id and upsert result	
    public static void checkUpsertAsUser(sObject obj) {
        //If we aren't in System Mode, do the CRUD/FLS checks
        if (Permissions.checkSystemMode() == false) {
            checkUpsert(obj);
            allowUpdateFields(obj);        
        }
    }
    public static void checkUpsertAsUser(List<SObject> objList)	{
        //If we aren't in System Mode, do the CRUD/FLS checks
        if (Permissions.checkSystemMode() == false) {
            checkUpsert(objList);
            allowUpdateFields(objList);    
        }        
    }
    /*
	* END user mode
    */	
    
	
    /************************************************************
	* BEGIN Worker Methods
    *************************************************************/
    public static Database.SaveResult insertAsUserWorker (sobject record, Boolean allOrNone) {
        checkInsert(record);		
		allowUpdateFields(new list<sobject>{record});
		return Database.insert(record, allOrNone);   	
    }
    public static List<Database.SaveResult> insertAsUserWorker (List<sobject> records, Boolean allOrNone) {
 		checkInsert(records);		
		allowUpdateFields(records);
		return Database.insert(records, allOrNone);   	
    }  
    
    public static Database.SaveResult updateAsUserWorker (sobject record, Boolean allOrNone) {
 		checkUpdate(record);		
		allowUpdateFields(new list<sobject>{record});
		return Database.update(record, allOrNone);   	
    }
    public static List<Database.SaveResult> updateAsUserWorker (List<sobject> records, Boolean allOrNone) {
 		checkUpdate(records);		
		allowUpdateFields(records);
		return Database.update(records, allOrNone);   	
    }         

    public static Database.DeleteResult deleteAsUserWorker (sobject record, Boolean allOrNone) {
 		checkDelete(record);		
		return Database.delete(record, allOrNone);   	
    }
    public static List<Database.DeleteResult> deleteAsUserWorker (List<sobject> records, Boolean allOrNone) {
 		checkDelete(records);		
		return Database.delete(records, allOrNone);   	
    }  
    public static List<Database.DeleteResult> deleteAsUserWorker (List<Id> idList, Boolean allOrNone) {
 		checkDelete(idList);		
		return Database.delete(idList, allOrNone);   	
    }                   
    /************************************************************
	* END Worker Methods
    *************************************************************/	     	    	
	
	
	    

    
    /************************************************************
	* BEGIN CRUD Checks
    *************************************************************/	    
    public static void checkInsert (sobject record) {
		checkInsert (new list<sobject>{record}); 	
    }
    public static void checkInsert (list<sobject> records) {
		if ( records.size() > 0 && records[0].getSObjectType().getDescribe().isCreateable() == false ) {
        		if (check_access) throw new InsuffientAccessException(); 
		}    	
    }    
    
	public static void checkUpdate (sobject record) {
		checkUpdate (new list<sobject>{record}); 	
	}    
	public static void checkUpdate (list<sobject> records) {
		if ( records.size() > 0 && records[0].getSObjectType().getDescribe().isUpdateable() == false ) {
        		if (check_access) throw new InsuffientAccessException(); 
		}
	}    
	
	
	public static void checkUpsert (sobject record) {
		checkInsert(record);
		checkUpdate(record);
	}    	
	public static void checkUpsert (list<sobject> records) {
		checkInsert(records);
		checkUpdate(records);
	}   
		
	
	public static void checkDelete (sobject record) { 
		checkDelete (new list<sobject>{record}); 
	}	
	public static void checkDelete (list<sobject> records) { 
		if ( records.size() > 0 && records[0].getSObjectType().getDescribe().isDeletable() == false ) {
        		if (check_access) throw new InsuffientAccessException(); 
		}	
	}	
	public static void checkDelete (List<Id> recordIds) { 
		if ( recordIds.size() > 0 && recordIds[0].getSObjectType().getDescribe().isDeletable() == false ) {
        		if (check_access) throw new InsuffientAccessException(); 
		}	
	}				
    /************************************************************
	* END CRUD Checks
    *************************************************************/	         
    
    
    

    /************************************************************
	* BEGIN FLS Checks
    *************************************************************/	    
	
	/* 
	 * i can update the fields on this object , true or throw exception
	 */
	 public static void allowUpdateFields( list<string> fieldSet , Schema.SObjectType ctype) {  
	 	if ( check_access == false ) return;
	 	
		//KNDY-7410
		//Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
		SchemaUtil util = SchemaUtil.getInstance();
		Map<String, sObjectField> fmap = util.addNoNSfieldsToMap(ctype.getDescribe().fields.getMap());     	 	
	 	
	 	
	 	// Obtaining the field name/token map for the Contact object
		for (String fieldToCheck :  fieldSet) {
			// Check if the user has update access on the each field
			system.assert( fmap.get(fieldToCheck) != null , 'Expected valid field name for '+string.valueof(ctype) + '.' +fieldToCheck );
		
			if (!fmap.get(fieldToCheck).getDescribe().isUpdateable() 
					&& fmap.get(fieldToCheck).getDescribe().isPermissionable() 
					&& !fmap.get(fieldToCheck).getDescribe().isAutonumber()) {
				throw new InsuffientAccessException(); 
			}
		}
	 } 
	 

	 /** 
	  * @description can we ( the running user ) update the fields in these records
	  * check FLS for the records passed in, assumes that each record has the same fields
	  */
	 public static void allowUpdateFields(sobject record) {  
	 	allowUpdateFields(new list<sobject>{record});	
	 }	  
	 public static void allowUpdateFields( list<sobject> records ) {  	 			
	 	if ( check_access == false ) return;
 	 	
	 	// introspect the fields on the records to see if they contain any fields we cannot allow a user to update
	 	for ( sobject obj: records) { 
			Schema.SObjectType ctype = obj.getSObjectType();
			//KNDY-7410
			//Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();
			SchemaUtil util = SchemaUtil.getInstance();
			Map<String, sObjectField> fmap = util.addNoNSfieldsToMap(ctype.getDescribe().fields.getMap());     			 	
			
			
			//	system.debug ( logginglevel.info, obj );
	 		map<string,object> objmap = (map<string,object>) Json.deserializeuntyped(JSON.serialize(obj));
	 		
	 		for ( string fieldname : objmap.keySet() ) { 
	 			if ( fmap.containsKey( fieldname ) ) { 
		 			Schema.Describefieldresult fld = fmap.get(fieldname).getDescribe();
		 			
		 			if ( fld.isPermissionable() && ! fld.isCalculated() ) {
		 			
						if ( ! fld.isUpdateable() && !fld.isAutoNumber() ) {
							throw new InsuffientAccessException( Label.Insufficient_Access_permissions_to_field +  ctype + '.' + fld.getName() );
 			 			}	
		 			}
	 			} 
	 			/* else { 
	 				// fieldname not in describe info, is ok: examples are company__r 
	 				// system.debug ( logginglevel.info, fieldname + ' is missing  from fmap ');
	 			} */
	 		}
	 		break; // inpsect only the first record
	 	}
	 }

    /************************************************************
	* END FLS Checks
    *************************************************************/	    




    /************************************************************
	* BEGIN MISC CRUD / DML methods.
    *************************************************************/	    
	
	
	/* FALSE POSITIVE Bulkify_Apex_Methods_Using_Collections_In_Methods */		
	//have to keep this method around, other classes doing checks at fieldset/object level
	public static list<Database.Saveresult> sobjectUpdate( sobject record ) {
		return sobjectUpdate( new List<sobject>{ record} );
	}
	
	public static list<Database.Saveresult> sobjectUpdate( list<sobject> records ) {
		 
		if ( records.size() >0 && records[0].getSObjectType().getDescribe().isUpdateable() == false ) {
        		if ( check_access ) throw new InsuffientAccessException(); 
		}
		return Database.update(records);
	}
	
    /************************************************************
	* END MISC CRUD / DML methods.
    *************************************************************/	 	




	 
	 /**
	   * @description saveSobjectList will take an un ordered list of multiple sobject types and 
	   * sort them into lists by sobject type, then insert them 10 unique objects at a time to 
	   * prevent an obscure limit when inserting many different sobjects in one insert statement
       * 
       * observed System.TypeException: Cannot have more than 10 chunks in a single operation
       * used by SetupSampleData.cls and ExceptionService.cls
       */
    public static void updateSobjectList(list <Sobject> setToUpdate) {
        modifySobjectList( setToUpdate, false);
    }
    public static void insertSobjectList(list <Sobject> setToInsert) {
        modifySobjectList( setToInsert, true);
    }
    private static void modifySobjectList(list <Sobject> setToModify, boolean useInsert) {
        Integer SFDC_CHUNK_LIMIT = 10;
        
        Map<Schema.SObjectType, List<Sobject>> sortedMapPerObjectType = new Map<Schema.SObjectType, List<Sobject>>();
        
        for (Sobject obj : setToModify) {
            Schema.SObjectType objType = obj.getSObjectType();
            if (! sortedMapPerObjectType.containsKey(objType)) {
                sortedMapPerObjectType.put(objType, new List<Sobject>());
            }                
            sortedMapPerObjectType.get(objType).add(obj);        
        }
        
        while(sortedMapPerObjectType.size() > 0) {
            // Create a new list, which can contain a max of chunking limit, and sorted, so we don't get any errors 
            List<Sobject> safeListForChunking = new List<Sobject>();
            list<SchemaWrapper> SchemaWrapperList = new list<SchemaWrapper>();            
            //List<Schema.SObjectType> keyListSobjectType = new List<Schema.SObjectType>(sortedMapPerObjectType.keySet());
            for( Schema.SObjectType t : sortedMapPerObjectType.keySet() ) {
                SchemaWrapperList.add( new SchemaWrapper(t) );
            }
            SchemaWrapperList.sort();
            for (Integer i = 0;i<SFDC_CHUNK_LIMIT && !sortedMapPerObjectType.isEmpty();i++) {
                SchemaWrapper tmp = SchemaWrapperList.remove(0);
                List<Sobject> listSobjectOfOneType = sortedMapPerObjectType.remove(tmp.sobjectType); 
                safeListForChunking.addAll(listSobjectOfOneType);
            }

            // upsert caueses test failures, not sure why, dont try to optimize this...
            if ( useInsert ) {	
                insert safeListForChunking; 
            } else {
                update safeListForChunking;
            } 	
        }
    }
    
    public class SchemaWrapper implements Comparable  {
        public Schema.SObjectType sobjectType;
        
        public SchemaWrapper( Schema.SObjectType typ ) { sobjectType = typ; }
        public integer compareTo ( object compareTo ) {
            SchemaWrapper wrap = (SchemaWrapper)compareTo;
            Integer returnValue = 0;
            if (sobjectType.getDescribe().getName() > wrap.sobjectType.getDescribe().getName() ) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (sobjectType.getDescribe().getName() < wrap.sobjectType.getDescribe().getName() ) {
                // Set return value to a negative value.
                returnValue = -1;
            }        
            return returnValue;                   
        }
    }
}