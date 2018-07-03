public  with sharing class Hierarchy {

	/* 
	 * public members
	 */
	public  set<string> fieldSet = new set<String>{'Id','Name'};		// fields that will be used in the query for an individual record
	public  string sobjectName = null;
	public  string parentFieldName  = null;  	
	public  string topParentFieldName  = null;
	 
    /* 
     * private members
     */
    private  sobject topSObject = null;  
	private Map<String,List<Sobject>> mapSObjects = new Map<String,List<Sobject>>();
 
	/* 
	 * public methods
	 */
	public Sobject getRecordById( id p ) { 
		
		//system.debug(LoggingLevel.INFO, allFieldsString ); 
	    //return Database.query( 'select '+ allFieldsString +' from '+ this.sobjectName+' where id = :p limit 1');
	    
        String whereClause = 'id = :p limit 1';//KNDY-8796
        set<string> fieldStr = new set<string>(allFieldsString.split(','));
        
        SOQLUtil soql = new SOQLUtil(this.sobjectName);
        soql.addFields(fieldStr);
        soql.setWhereClause(whereClause);
        system.debug('query:*****'+soql.getQuery());
        return Database.query( soql.getQuery());
        
	}
	
	/*public Sobject findTopNode( Sobject theRecord ) { 	
		if ( theRecord.get( parentFieldName )  == null ) {	
			return theRecord; 	// exit condition 
		} else { 						// recurse
			return findTopNode(  getRecordById( (Id)theRecord.get( parentFieldName ) ) );	
		}
	}*/

	public Node getHierarchy( Id theID ) {
		// find the top object in this tree, could by theID or a related record.
		if ( theID == null )  {
			throw new HierarchyException('Missing record ID to getHierarchy() method');
		}
		if ( this.sobjectName == null )  {
			throw new HierarchyException('Expected this.sobjectName to be set');
		}
		if ( this.parentFieldName == null )  {
			throw new HierarchyException('Expected this.parentFieldName to be set');
		}
		if ( this.topParentFieldName == null )  {
			throw new HierarchyException('Expected this.topParentFieldName to be set');
		}
		// start doing work
		if ( this.topSObject == null ) {
			//this.topSObject = findTopNode( getRecordById( theID) );
			sobject tmp = getRecordById( theID); 
			if ( tmp.get( parentFieldName ) == null && tmp.get( topParentFieldName ) == null ) {
				this.topSObject = tmp;  	// this is the top  
			} else if ( tmp.get( topParentFieldName ) != null ){ 
				this.topSObject = getRecordById( (Id) tmp.get( topParentFieldName ) ); // top is specified for us
			} else { 
				throw new HierarchyException('Could not locate top node from :'+theID);
			}
		}
		Node top = new Node( this.topSObject );
		mapSObjects.clear(); 					// reset this map so the query happens again
			
		// each time thru, need to fetch the list of all customers that share this top
		
		/* make a map by parent  so that the recursion can quickly find "who's your daddy" 
		 * allows us to grab all records in this hierarachy set, because they each have this in common, except the top...
		 * which has parent == null, and topparent == null, but we can explictly add this record now, since it's passed in
		 */
		String theTopID = (String)top.node.id; 		
		mapSObjects.put( theTopID, new List<Sobject>() );		// initial list of direct children of top 
		
		set<string> fieldStr = new set<string>(allFieldsString.split(','));
        String whereClause = this.topParentFieldName +'  = :theTopID '; //KNDY-8796
        SOQLUtil soql = new SOQLUtil(this.sobjectName,true);
        soql.addFields(fieldStr);
        soql.setWhereClause(whereClause);
        
		//for ( sobject tmp :  Database.query( 	'select '+ allFieldsString  + '  from '+ this.sobjectName+ 
		//							 							' where  '+ this.topParentFieldName +'  = :theTopID ' ) )  {
        for ( sobject tmp :  Database.query( soql.getQuery()) )  {                                                            
			string key = (String)tmp.get( parentFieldName );
			//KNDY-8428 Mods to relax Cust Hierarchy
			if(key == null){
				key = (string)tmp.get(topParentFieldName);				
			}
			//End Mods
			
			if ( ! mapSObjects.containsKey( key ) ) {	mapSObjects.put( key, new List<Sobject>() );				}
			mapSObjects.get( key ).add( tmp );
		}
		
		getHeirarchy_worker( top );			// load the tree
		return top;
	}

	/* 
	 * private methods 
	 */

	private void getHeirarchy_worker( Node theNode ) {		// recurse on the children, top is aleady added 
		if ( mapSObjects.containsKey ( (String)theNode.node.id) ) {
			for ( sobject bp : mapSObjects.get( (String)theNode.node.id  ) )	{
				Node child = new Node( bp );
				theNode.children.add( child );
				getHeirarchy_worker( child ); // recurse so we pick up the grand children
			}
		}
	} 	
 
	private String allFieldsString { get { 										// starting from a set, return a unique joined string for query
		// some objects have a record type, include that if it's present
		Map<String,String> rtMap = KSE.RecordTypeDevNameMap(this.sobjectName);
		if ( rtMap.keySet().size() > 0 ) {
			fieldSet.add('RecordType.DeveloperName');
			fieldSet.add('RecordType.Name');
		} 
		List<String > tmpFieldList = new List<String>(fieldSet);
		if ( this.parentFieldName != null ) tmpFieldList.add( this.parentFieldName );
		if ( this.topParentFieldName != null ) tmpFieldList.add( this.topParentFieldName );
		return String.join( tmpFieldList, ',' );
	}}
	 	
	/* 
	 * inner class that represents the tree we need to output
	 */
	public class Node {
    	public Sobject node; 
    	public List<Node> children {get; set; } 
    	public Node( Sobject p) { 
    		node = p; 
    		children = new List<Node>(); 
    	}
    } 
 	
 	public class HierarchyException extends Exception {}   
}