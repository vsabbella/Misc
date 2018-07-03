public with sharing class FacilityViewExt {
    /* overview of facilities , locations and details about stockpoints */
    Apexpages.Standardcontroller con;
    
    public string subject { get; set; }  // expect this to be Facility__c
        
    public FacilityViewExt() {  } 
    public FacilityViewExt( Apexpages.Standardcontroller con ) { 
        subject = con.getId();  
        this.con = con; 
    }
            
    /* like Hierarchy.cls except we are joining different objects in the tree 
    
    company 
       --> Facility 1  
           ---> location 1... N 
               ---> stockpoint
       --> Facility 2
           ---> location 1..N
               ---> stockpoint
           
        the facilities share a company, the locations share a facility.  
        below location we will lazy load the stockpoint feature details
    */
        /** 
     *
     */
    @RemoteAction public static Node getHierarchy( string sobject_id )  {  
        // find the fields we will use for hierarchy
        FacilityViewExt hh = new FacilityViewExt();
        hh.sobjectName = 'Facility__c';
        system.assert( sobject_id != null, 'expected valid object id ');
        Node nod =  hh.getHierarchy_start( sobject_id );
        return nod;
    }
    
    
    
    
        
    
    /* 
     * public members
     */
    public  set<string> fieldSet = new set<String>{'Id','Name,Company__c'};     // fields that will be used in the query for an individual record
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
        //.debug(LoggingLevel.INFO, 'select '+ allFieldsString +' from '+ this.sobjectName+' where id = :p limit 1' );
       
        String whereClause = 'id = :p limit 1';//KNDY-10473
		SOQLUtil soql = new SOQLUtil(this.sobjectName);
        soql.addFields(new Set<String>{allFieldsString});
        soql.setWhereClause(whereClause);
        String queryString = soql.getQuery();
        List<Sobject> sobjects = soql.returnQueryResult();
        return sobjects[0];
        //return Database.query( 'select '+ allFieldsString +' from '+ this.sobjectName+' where id = :p limit 1');
    }
    
    
    public Node getHierarchy_start( Id theID ) {
        // find the top object in this tree, could by theID or a related record.
        if ( theID == null )  {
            throw new HierarchyException(Label.Missing_record_ID);
        }
        if ( this.sobjectName == null )  {
            throw new HierarchyException(Label.Expected_sobject_name_to_be_set);
        }
        if ( this.parentFieldName == null )  {
            //  throw new HierarchyException('Expected this.parentFieldName to be set');
        }
        if ( this.topParentFieldName == null )  {
            //throw new HierarchyException('Expected this.topParentFieldName to be set');
        }
        // start doing work
        if ( this.topSObject == null ) {
            // current facility and parent
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','name','company__r.Name','company__r.id'
			});
			soql.setWhereClause('id = :theID');
			soql.setLimit(1);
			sobject tmp = Database.query(soql.getQuery())[0];

            this.topSObject = tmp.getSObject('Company__r'); 
        }
        Node top = new Node( this.topSObject );
        String prefix  = String.valueof(this.topSObject.id).subString(0,3);
        top.objectName = String.valueof( this.topSObject.id.getSObjectType() );
        
        mapSObjects.clear();                    // reset this map so the query happens again
            
        // each time thru, need to fetch the list of all customers that share this top
        
        /* make a map by parent          */
        String theTopID = (String)top.node.id;      
        mapSObjects.put( theTopID, new List<Sobject>() );       // initial list of direct children of top 
        
        Set<id> fac_ids = new set<id>();
        set<string> cFields = new Set<String>(allFieldsString.split(','));
        // facilities at this company 
        String whereClause = 'company__c  = :theTopID ';//KNDY-10473
		SOQLUtil soql = new SOQLUtil('Facility__c');
        soql.addFields(cFields);
        soql.setWhereClause(whereClause);
        
       //for ( sobject tmp :  Database.query(    'select '+ allFieldsString  + '  from '+ 'Facility__c' + 
       //                                                        ' where  company__c  = :theTopID ' ) )
        for ( sobject tmp : Database.query(soql.getQuery()) )     
        {
            string key = (String)tmp.get( 'Company__c' );
            if ( ! mapSObjects.containsKey( key ) ) {   mapSObjects.put( key, new List<Sobject>() );                }
            mapSObjects.get( key ).add( tmp );
            
            fac_ids.add(tmp.id);
        }
        
        // get Locations at all facilities
        Set<id> loc_ids = new set<id>();
        whereClause = 'Facility__c  in :fac_ids ';//KNDY-10473
		soql = new SOQLUtil('Location__c');
        soql.addFields(new Set<String>{'id','name','Facility__c'});
        soql.setWhereClause(whereClause);
        
        for ( sobject tmp :  Database.query(soql.getQuery()) )      
        {
            string key = (String)tmp.get( 'Facility__c' );
            if ( ! mapSObjects.containsKey( key ) ) {   mapSObjects.put( key, new List<Sobject>() );                }
            mapSObjects.get( key ).add( tmp );
            
            loc_ids.add( tmp.id ); 
        }
        
        getHeirarchy_worker( top );         // load the tree
        return top;
    }

    /* 
     * private methods 
     */
    private void getHeirarchy_worker( Node theNode ) {      // recurse on the children, top is aleady added 
        if ( mapSObjects.containsKey ( (String)theNode.node.id) ) {
            for ( sobject bp : mapSObjects.get( (String)theNode.node.id  ) )    {
                Node child = new Node( bp );
                child.objectName = String.valueof( this.topSObject.id.getSObjectType() );
                theNode.children.add( child );
                getHeirarchy_worker( child ); // recurse so we pick up the grand children
            }
        }        
    }   
 
    private String allFieldsString { get {                                      // starting from a set, return a unique joined string for query
        // some objects have a record type, include that if it's present
        Map<String,String> rtMap = KSE.RecordTypeDevNameMap(this.sobjectName);
        
        if ( rtMap.keySet().size() > 0 ) {
            fieldSet.add('RecordType.DeveloperName');
            fieldSet.add('RecordType.Name');
        }
        if ( this.parentFieldName != null ) fieldSet.add( this.parentFieldName );
        if ( this.topParentFieldName != null ) fieldSet.add( this.topParentFieldName );
        
        List<String > tmpFieldList = new List<String>(fieldSet);
        
        return String.join( tmpFieldList, ',' );
    }}
        
    /* 
     * inner class that represents the tree we need to output
     */
    public class Node {
        public Sobject node; 
        public String objectName;    // used to style the output
        public List<Node> children { get; set; } 
        public Node( Sobject p) { 
            node = p; 
            children = new List<Node>(); 
        }
    } 
    
    public class HierarchyException extends Exception {}    
    
}