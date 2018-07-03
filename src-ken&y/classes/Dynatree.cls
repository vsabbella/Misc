public with sharing class Dynatree {
	public Dynatree( ) {}	
	
	/** 
	 *
	 */
	public string subject { get; set; } 
	public Dynatree( Apexpages.Standardcontroller con ) { subject = con.getId();	}
	public PageReference changeTheSubject() {
		String newSubject = Apexpages.currentPage().getParameters().get('subject'); 
		subject = newSubject;		return null; 
	}
	
	/** 
	 *
	 */
	@RemoteAction public static Hierarchy.Node getHierarchy( string sobject_id,
																							string fieldSetName) { 
		SchemaUtil util = SchemaUtil.getInstance();
		Schema.Sobjecttype objectInstance = util.getSObjectType( sobject_id );
 
		// find the fields we will use for hierarchy
		Hierarchy hh = new Hierarchy();
		hh.sobjectName = objectInstance.getDescribe().getName().replace( KSE.NamespaceUU,'' );
		system.assert( hh.sobjectName != null, ' expected a valid sobject name ');
		
		for( Schema.Childrelationship cr :objectInstance.getDescribe().getChildRelationships() ) {
			if ( cr.getChildSObject() == objectInstance ) {
				// this is a self referencing field , now look for two fields, these start with the string
				// Parent  or Top, tossing the namespace if it exists, and to lower case  
				string field_name = cr.getField().getDescribe().getName().replace( KSE.NamespaceUU,'' ).toLowerCase();
				if ( field_name.startsWith('top') )
					hh.topParentFieldName = cr.getField().getDescribe().getName();
				if ( field_name.startsWith('parent') )
					hh.parentFieldName = cr.getField().getDescribe().getName();
			}
		}
		
		system.assert( hh.topParentFieldName != null , 'expected a lookup field to '+hh.sobjectName + ' starting with Top');
		system.assert( hh.parentFieldName != null, 'expected a lookup field to '+hh.sobjectName + ' starting with Parent');
		
		// TODO read the field names from the field set and stuff them into the field set property
		//hh.fieldSet.addAll( fieldsList.split(',') );
		Hierarchy.Node nod =  hh.getHierarchy( sobject_id );
		return nod;
	}
	
}