public with sharing class Datatable2 {

	@remoteAction 
	public static Datatable.RemoteReturn foobar( string objectid, string relatedlist, string fieldset , string parentfield) {
		id oid = objectid; 
		SchemaUtil util = SchemaUtil.getInstance();
		Datatable.RemoteReturn tmp = new Datatable.RemoteReturn();  
		
        String whereClause = parentfield + '  = :oid ';
        SOQLUtil soql = new SOQLUtil(relatedlist);//KNDY-10473
        soql.addFields('fieldset');
        soql.addFields('Id');
        soql.setWhereClause(whereClause);
        
		/*string qry =  util.generateQueryFromFieldSet(
														relatedlist,
														new set<string>{ fieldset }, 
														new set<string>{ 'Id' }, 
														parentfield + '  = :oid '	 
														);
		system.debug( '****dt2Query***'+ qry );
		
			
		tmp.lines = database.query(qry);  */
		tmp.lines = database.query(soql.getQuery());  	
		tmp.fieldset = new List<Datatable.fieldSetData>{ new Datatable.fieldSetData('Id','Id','STRING') };
		
		if ( tmp.lines != null && tmp.lines.size() > 0 ) {
			for ( Schema.FieldSetMember fs : 
										util.getFieldsFromFieldSet( tmp.lines[0].getsObjectType(), 
										fieldset) ) 
			{
				tmp.fieldset.add( new Datatable.fieldSetData(fs) );
			}
		}
		return tmp;
	} 	
	
	public Datatable2( apexpages.standardcontroller c) {} 
	public Datatable2() {}
	
}