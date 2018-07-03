public with sharing class HierarchyManageExt {
    public Hierarchy__c originalNode {get; set; }
    public Hierarchy__c newNode {get; set; }
	
    public HierarchyManageExt(Apexpages.standardController con) { 
        ApexPages.currentPage().getParameters().put('hid',con.getId());
        LoadAllNodes(); 
    } 
     
    public PageReference LoadAllNodes() { 

//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil

SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
//Start_Period__c is added to the fields -- Sohini
soql.addFields(new set<string>{
	'id','name','Parent_Code__c','Code__c','Level__c','start_date__c','end_date__c','Description__c','Type__c'
});
            string cId = ApexPages.currentPage().getParameters().get('hid');        
            soql.setWhereClause('id = :cId');
soql.setLimit(1);
originalNode = Database.query(soql.getQuery());
        // defaults for the user convience
        originalNode.End_Date__c  = system.today(); 
        
        newNode = originalNode.clone(false,true); // clear id, deep clone
        newNode.Primary_Key__c = null; 	// since this is unique, cannot copy it
        newNode.Start_Date__c = system.today().addDays(1); // start date must be > end date
        newNode.End_Date__c = null; 	// nulling this says new node does not expire
        return null;
    }
    
    
    /* manage methods */
    public PageReference moveNode() { 
    	// save changes to both the original ( new end_date )
    	// and the new node ( new parent, new start date )
        Savepoint sp = Database.setSavepoint();
        try { 
        	// if new start <= old end throw
            if (originalNode.End_Date__c >= newNode.Start_Date__c ) 
                throw new HierarchyController.HierarchyException('New record must start after old record end date');
            if ( newNode.Parent__c == null ) 
                throw new HierarchyController.HierarchyException('No new parent specified');
            
            // fetch the parent_code from the record mentioned in newNode.Parent__c

/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Code__c'
});
            string parentId = newNode.Parent__c;
            soql.setWhereClause('id = :parentId');
soql.setLimit(1);
Hierarchy__c tmp = Database.query(soql.getQuery());


            newNode.Parent_Code__c = tmp.Code__c;
            
        	DML.updateAsUser(originalNode);
            DML.insertAsUser(new List<sobject>{newNode} );
            
        } catch( Exception ex) {
            database.rollback(sp); 
            ApexPages.addMessages(ex);
            return null;
        }
        // if all goes well, return to the new node we just inserted
        return new Apexpages.standardController(newNode).cancel();
    }
    
}