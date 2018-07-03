/* 
 * HierarchyController: 
 * used by the hierarchy viewers and Kendo Treview ( HierarchyView.page )
 * construct data that can be passed to 
 * http://docs.telerik.com/kendo-ui/api/framework/hierarchicaldatasource
 */
global with sharing class HierarchyController {
    
    public class HierarchyException extends Exception {}

	private Apexpages.standardController con;
    public HierarchyController(Apexpages.standardController c) { 
        con=c; 
        eff_date = System.today();
        // if date is passed in, set the effective date, used in queries
        if ( ApexPages.currentPage()!=null && ApexPages.currentPage().getParameters().get('date') != null ) {
            try { 
                Date tmp = Date.valueof(ApexPages.currentPage().getParameters().get('date') );
                eff_date = tmp;
            } catch( System.TypeException te ) {}
        }
	} 
	
    public HierarchyController() { eff_date = System.today(); } 
    
	public map<id,Hierarchy__c> allRecords = null; // if set, accumlate a list of records to update Path__c
       
	public Map<String,List<Sobject>> mapSObjects  = new Map<String,List<Sobject>>();
	public Date eff_date {get; set;} 
	
    private boolean getHierarchyRecurse (Node theNode ) {
        // TODO 
        // add code (using a set ?) to detect if we are called with the exact same code twice
        // this appears as a max stack depth error
        // 
        boolean child_selected = false; 
		if ( this.mapSObjects.containsKey ( (String)theNode.code ) ) {
			
			for ( sobject bp : this.mapSObjects.get( (String)theNode.code ) )
			{
				Node child = new Node( bp, sobject_name );
                if ( allRecords !=null ) {
                    child.path = theNode.path+'|'+bp.get('Code__c');
                    // check to see if there is already a hierarchy record in the map
					allRecords.put(bp.id, new Hierarchy__c( id=bp.id,path__c=child.path)); 
               	}

				if ( child.id == this.recordId ) {
					child.selected = true;		// select one record in the hierarchy
					child_selected = true;
				}
					
				theNode.items.add( child );
                
                if ( theNode.code == child.code ) { 
                    // note: this should never occur because we validate the data on insert/update
                	throw new HierarchyException('Code and Parent Code are identical :'+theNode.code);
                }
				if ( getHierarchyRecurse( child  ) ) {  // recurse so we pick up the grand children, etc 
					child_selected = true; 
				} 
			}
			
			// if any of my children are selected, i must become expanded 
			if ( child_selected == true ) {
				theNode.expanded = true;
			}
			
		}
		
		if ( theNode.id == this.recordId ) {
			// i am selected
			theNode.selected = true; 
		}
		return child_selected;		
	} 	
	
	/* 
	 * loadHierarchyMap() 
	 * make a map by parent  so that the recursion can quickly find "who's your parent"
	 * grab all records in this hierarachy set, because they have this "Type" in common
	 *
	 */
	public void loadHierarchyMap(Node theNode ) {
		string typ = this.typeString; 
		date efd = this.eff_date;
       /* string qstr =  'select '+ this.fieldList  + ' from Hierarchy__c ' + 
            ' where  Type__c  = :typ AND '+ this.parentFieldName  +'  != null ' +
            ' and (End_Date__c = NULL OR End_Date__c >= :efd )  ' +
            ' and (Start_Date__c != null AND Start_Date__c <= :efd )'   ; */
		
		// there should be no duplicate codes in this result set, check here?
		// 
		set<string> fieldStr = new set<string>(this.fieldList.split(','));
		String whereClause = 'Type__c  = :typ AND '+ this.parentFieldName  +'  != null  and (End_Date__c = NULL OR End_Date__c >= :efd )  and (Start_Date__c != null AND Start_Date__c <= :efd )'; //KNDY-8796
        SOQLUtil soql = new SOQLUtil('Hierarchy__c',true);
        soql.addFields(fieldStr);
        soql.setWhereClause(whereClause);
        
        system.debug('query:*****'+soql.getQuery());
		
		//for ( Hierarchy__c tmp :  Database.query(qstr) ) {
        for ( Hierarchy__c tmp :  Database.query(soql.getQuery()) ) {    
			string key = (String)tmp.get('Parent_Code__c');
			if ( ! this.mapSObjects.containsKey( key ) ) {	
				this.mapSObjects.put( key, new List<Sobject>() );	// new list of children
			}
			
			this.mapSObjects.get( key ).add( (Sobject) tmp );
		}
	}	
	
    /* given a node, find the matching Hierarchy Id at or under this node
     * like jQuery .find()
     */
	public static Node getNodeById(Node thisNode, id HierarchyId ) { 
		if ( thisNode.Id  ==HierarchyId ) return thisNode; 
        for ( Node child: thisNode.items) {
            Node hn = getNodeById( child, HierarchyId );
            if ( hn!=null ) return hn;
        }
        return null;
    }
    
    /* return the ID's of all nodes at or below the node passed in
     * used to join hierarchies with products which are mentioned 
     * under a hierarchy group
     */
    public static list<id> children( Node thisNode ) {
        list<id> ret = new list<id>{(id)thisNode.id};
        for ( HierarchyController.Node child: thisNode.items) {
            ret.addAll( children(child) );
        }
        return ret;
    }
    
    // called to build the tree for the overview page, also selects the id 
    // of the record passed in.
	@RemoteAction global static List<Node> getHierarchy( Id pid ) {
		HierarchyController thisCon = new HierarchyController();
		thisCon.recordId = pid; 	
		Node top = new Node( thisCon.topSObject, thisCon.sobject_name );
        thisCon.loadHierarchyMap ( top );
        thisCon.getHierarchyRecurse( top );	    	
        return new List<Node>{ top };
   	}
	
	@RemoteAction global static List<Node> getHierarchyWithDate( Id pid, string theDate ) {
		HierarchyController thisCon = new HierarchyController();
		if ( theDate != null && theDate != '' ) {
			thisCon.eff_date = date.valueof(theDate);
		} 
		thisCon.recordId = pid; 	
		Node top = new Node( thisCon.topSObject, thisCon.sobject_name );
        thisCon.loadHierarchyMap ( top );
        thisCon.getHierarchyRecurse( top );	    	
        return new List<Node>{ top };
   	}
   	
    // generate a full tree for this type, collect the paths, 
    // update the database, return to the detail page
    public void setHierarchyPath() {
		this.recordId = con.getId(); 
        Node top; 
        try {
            top = new Node( this.topSObject, this.sobject_name );
            top.path = this.topSObject.Code__c;
        } catch( exception ex) {
            throw new HierarchyException(Label.Cannot_locate_Top_for_this_hierarchy + this.typeString);
        }
        // in this case, we init a list of all records to collect hold the path for performing an update
        this.allRecords = new map<id,Hierarchy__c>();
        this.allRecords.put(this.topSObject.id, new Hierarchy__c( id=this.topSObject.id,path__c=top.path));
        
		this.loadHierarchyMap ( top );
        this.getHierarchyRecurse( top );	    	
        // leaves this.allRecords map populated
	}
    
	private id recordId { get; set; } 
	
	private string typeString { 
        get { 
            if ( typeString == null ) { 

				/*
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				                */
				SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Type__c'
				});
                ID rId = this.recordId;
                soql.setWhereClause('id = :rId');
soql.setLimit(1);
                Hierarchy__c typeStringHierarchy = Database.query(soql.getQuery());
                typeString = typeStringHierarchy.Type__c ;
            } return typeString;  
        } 
        set; 
    } 
	
	private Hierarchy__c topSObject { 
         // TODO add effective date check?
        get {
            string typ = this.typeString; 
            set<string> fieldStr = new set<string>(this.fieldList.split(','));
            String whereClause = 'Type__c = :typ AND Parent_Code__c = null limit 1'; //KNDY-8796
            SOQLUtil soql = new SOQLUtil(sobject_name,true);
            soql.addFields(fieldStr);
            soql.setWhereClause(whereClause);
            return Database.query(soql.getQuery());
        }
    }
	
	public string fieldList = ' id, name, Level__c, Code__c, Type__c,Parent_Code__c  ';
	public string sobject_name = 'Hierarchy__c'; 	
	public string parentFieldName  = 'Parent_Code__c';  				

	global class Node { 
		public string  text, parent, code,id, spriteCssClass, path;
		// from kendo: boolean  encoded,  checked, imageUrl, url;
		public boolean expanded, selected; 
		public List<Node> items {get; set; }
		public Node( Sobject p, String oName) { 
	    		text = (string)p.get('Name');
	    		id = p.Id;
	    		id = id.substring(0,15);    	
	    		parent = (string)p.get('Parent_Code__c');
	    		code = (string)p.get('Code__c');
	    		items = new List<Node>();   	
	    		expanded = false;
	    		selected = false; 
	    		spriteCssClass = (string)p.get('Level__c');
	    	}
	}   
}