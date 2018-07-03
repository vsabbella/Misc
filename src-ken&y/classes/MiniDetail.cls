public with sharing class MiniDetail {

	public string subjectId { get; set; } 
	public String field_set_name { get; set; } 
	
	SchemaUtil util = SchemaUtil.getInstance(); 
	public MiniDetail() { }
		
	private Schema.SObjectType objectInstance { get {
		if (objectInstance == null )  
			objectInstance = util.getSObjectType(subjectid);
		return objectInstance;	
	} private set; }
		
	public Sobject GETsubjectRecord() { 						// pull all the fields in the field set 
		//system.assert( field_set_name != null, 'expected a valid field_set_name ');
		
		Set<string> fields_s = new Set<String>{'Id', 'Name'}; 
		for ( Schema.FieldSetMember fsm : getFields() ) {	
			fields_s.add(fsm.getFieldPath() );		
		}
		
		//List<String> fields_l = new List<String>(); 
		//fields_l.addAll(fields_s);
		
		String whereClause = 'id = :subjectId limit 1';
        
	    SOQLUtil soql = new SOQLUtil(objectInstance.getDescribe().getName());
	    soql.addFields(fields_s);
	    soql.setWhereClause(whereClause);	
		
		/*string query = 	 ' select  ' + String.join(fields_l, ',') +
			 																' from '+ objectInstance.getDescribe().getName() + 
			 																' where id = :subjectId limit 1';
		//System.debug(LoggingLevel.INFO, query );*/
		sobject subjectRecord = Database.query(soql.getQuery());
		return subjectRecord;
	} 
		
	public List<Schema.FieldSetMember> getFields() {
		
		if(field_set_name != null)
        	return util.getFieldsFromFieldSet(objectInstance, field_set_name);
        else
        	return new List<Schema.FieldSetMember>();
    } 
    
    /* 
     * allow a link on the page to go and view the detail for the selected record
     */ 
   public PageReference viewDetail() {
		Pagereference p = new PageReference('/'+subjectId);
		p.setRedirect(true);
		return  p;
	} 
   
   
}