public with sharing class RelatedListEditCon {
	
	public string NamespaceUU { get { return KSE.NamespaceUU; }} 
	private static SchemaUtil util = SchemaUtil.getInstance();
	
	/* support for query and update on PQgrid component */
	public class fieldSetData { 
		public String FieldPath; 
		public string Label; 
		public string Type; 
		public fieldSetData() {} 
		public fieldSetData( string FieldPath, string Label, String Type) {
			this.FieldPath = FieldPath;
			this.Label = Label;
			this.Type = Type; 
		}
		public fieldSetData( Schema.FieldSetMember fsm ) {
			this.FieldPath = fsm.getFieldPath();
			this.Label = fsm.getLabel();
			this.Type = fsm.getType().name(); 
		}
	} 
	
	public class RemoteReturn { 
		public list<sobject> lines; 
		public list<fieldSetData> fieldset;
	}
	
	public class IdNameWrapper{
		
		String id;	
		String value;
		
		public IdNameWrapper( Sobject sobj ){			
			id = String.valueOf( sobj.get('Id') );
			value = String.valueOf( sobj.get( 'Name') );
		}
	}
	
	
	@RemoteAction  
	public static IdNameWrapper[] lookupSearch(String searchTerm, String ObjectName ) {
        System.debug('searchField: '+searchTerm +','+ObjectName );
        
        String whereClause = 'name like \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
        
	    SOQLUtil soql = new SOQLUtil(objectName);
	    soql.addFields(new set<string>{'id', 'Name'});
	    soql.setWhereClause(whereClause);
	    
        /*List<SObject> ret = Database.query(
        							'Select Id, Name from ' + objectName +' where name like \'%' + 
        							String.escapeSingleQuotes(searchTerm) + '%\'' );*/
        
        List<SObject> ret = Database.query(soql.getQuery());
        							
       	List<IdNameWrapper> retList = convertSobjToWrapper( ret );
        			
        return retList;
    }
    
    @RemoteAction  
	public static list<sobject> sobjectupdate( list<sobject> sobjects,
														string objectid, 
														string relatedlist, 
														string fieldset , 
														string parentfield,
														list<sobject> removed  ) {
															
   //     System.debug(logginglevel.INFO, 'sobjectupdate: '+ sobjects);
        // build an insert list also
        list<sobject> inserts = new list<sobject>();
        list<sobject> updates = new list<sobject>();
        for ( sobject so : sobjects) { 
        		if ( so.id != null ) { 
        			updates.add(so);		
        		} else {
        			inserts.add(so);
        		}
        }  
     //   system.debug( logginglevel.info, updates.size() );
    //    system.debug( logginglevel.info, inserts);
        
        DML.updateAsUser(updates); 
        DML.insertAsUser(inserts);
        DML.deleteAsUser(removed); 
        
        // re-query for the return
        // TODO should just return queryTableWithFieldSet()
        
        id oid = objectid; 
        
        /*string qry =  util.generateQueryFromFieldSet(
														relatedlist,
														new set<string>{ fieldset }, 
														new set<string>{'id'}, 
														parentfield + '  = :oid '	 
														);*/
		
		String whereClause = parentfield + '  = :oid ';
        
	    SOQLUtil soql = new SOQLUtil(relatedlist);
	    soql.addFields(fieldset);
	    soql.addFields(new set<string>{'id'});
	    soql.setWhereClause(whereClause);
	    
		return Database.query(soql.getQuery());   		 
	}
	
    public static List<IdNameWrapper> convertSobjToWrapper(List<SObject> sList ){
		
		List<IdNameWrapper> wrapList = new List<IdNameWrapper>();
		
		for( SObject sobj : sList ){
			IdNameWrapper newObj = new IdNameWrapper( sobj );
			wrapList.add( newObj );	
		}
		
		return wrapList;
	}
	
	@remoteAction 
	public static RemoteReturn queryTableWithFieldSet( 
                                                        string objectid, 
                                                        string relatedlist, 
                                                        string fieldset , 
                                                        string parentfield	,
                                                        string relatedfields	 ) {
		id oid = objectid; 
		RemoteReturn tmp = new RemoteReturn();  
		set <string> addtl = new set<string>(relatedfields.split(',')); 
		/*string qry =  util.generateQueryFromFieldSet(
														relatedlist,
														new set<string>{ fieldset }, 
														addtl, 
														parentfield + '  = :oid '	 
														);*/
		
		String whereClause = parentfield + '  = :oid ';
        
	    SOQLUtil soql = new SOQLUtil(relatedlist);
	    soql.addFields(fieldset);
	    soql.addFields(addtl);
	    soql.setWhereClause(whereClause);
	    
		tmp.lines = Database.query(soql.getQuery());   
		system.debug(Logginglevel.info, tmp.lines);

		tmp.fieldset = new List<fieldSetData>{ new fieldSetData('Id','Id','STRING') };
		
		if ( tmp.lines != null && tmp.lines.size() > 0 ) {
			for ( Schema.FieldSetMember fs : 	util.getFieldsFromFieldSet( tmp.lines[0].getsObjectType(), 
																fieldset) ) 
			{
				tmp.fieldset.add( new fieldSetData(fs) );
			}
		}
		return tmp;
	} 	
	
	@RemoteAction
	public static list<PicklistEntry> getPicklistValues(string obj, String fld)
	{
		Map<String, sObjectField> fieldmap = util.getFieldsMap(obj);
		list <PicklistEntry> ret = new list<PicklistEntry>();
		for ( Schema.PicklistEntry pe : fieldMap.get(fld).getDescribe().getPickListValues() ){
			ret.add ( new PicklistEntry ( pe));
		}
		return ret; 
      /*for (Schema.PicklistEntry a : values)
      { 
         options.add(new SelectOption(a.getLabel(), a.getValue())); 
      }*/
      //return options;
   	}
   	public class PicklistEntry { 
   		string label, value; boolean isactive, isdefault;
   		public PicklistEntry( Schema.Picklistentry pe) { 
   			label = pe.getLabel(); 
   			value = pe.getValue(); 
   			isactive = pe.isActive(); 
   			isdefault = pe.isDefaultValue();
   		}
   	}
}