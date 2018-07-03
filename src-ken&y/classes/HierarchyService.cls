public with sharing class HierarchyService {
	// Map<Id, sObject> mSObjects is the map of sobject id, and the sobject
	public static HierarchyResult buildHierarchy(Map<Id, sObject> mSObjects, Datetime asOfDate){

/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'Id','name','codeId__c','parentcodeId__c','start_datetime__c','end_datetime__c'
});
    set <id> objKeySet = mSObjects.keySet();
    soql.setWhereClause('start_datetime__c <= :asOfDate and (end_datetime__c = null OR end_datetime__c > :asOfDate) and (codeId__c in :objKeySet OR parentcodeId__c in :objKeySet)');
List<Hierarchy__c> hs = Database.query(soql.getQuery());


	
		map<Id, set<Id>> mChildren = new map<Id, set<Id>>(); // Id - parent id, set of Id - child id
		map<Id, Id> mParents = new map<Id, Id>(); // Id - hierarchy id, Id - record id (here the parent of the record will be null as this is the root)
		map<Id, Id> mChildParent = new Map<Id, Id>();
		map<Id, Node> mNodes = new map<Id, Node>();
		
		for(Hierarchy__c h : hs){
			if(h.parentcodeId__c == null){
				mParents.put(h.Id, h.codeId__c); 
			}else{
				if(mChildren.containsKey(h.parentcodeId__c)){
					mChildren.get(h.parentcodeId__c).add(h.codeId__c);
				}else{
					mChildren.put(h.parentcodeId__c, new set<Id>{h.codeId__c});
				}	
			}
		}
		
		system.debug('mParents:  ' + mParents);
		system.debug('mChildren:  ' + mChildren);
		//Loop through the parents (root nodes) and stub out the nodes
		for(Id parentId : mParents.values()){
			//Top level node
			Id nodeId = parentId;
			Node node = new Node();
			node.Id = nodeId;
			node.label = (String) mSObjects.get(nodeId).get('name');
			node.nodes = new List<Node>();
			mNodes.put(node.Id, node);
									
		}
		
		//Now loop through all children relationships and stub out their nodes
		for(Id parentId : mChildren.keySet()){
			for(Id childId : mChildren.get(parentId)){
		system.debug('childId:  ' + childId);
				if(mSObjects.get(childId) != null){
					mChildParent.put(childId, parentId); // TODO: Add logic to handle one child with multiple parents
					Node childNode = new Node();
					childNode.Id = childId;
					childNode.label = (String) mSObjects.get(childId).get('name');
					childNode.nodes = new List<Node>();
					mNodes.put(childNode.Id, childNode);
				}
			}
		}
		
		
		//Now point the nodes in memory at each other
		for(Id parentId : mChildren.keySet()){
			for(Id childId : mChildren.get(parentId)){
				if(mNodes.containsKey(parentId) && mNodes.containsKey(childId)){
					mNodes.get(parentId).nodes.add(mNodes.get(childId));
				}
			}
		}
				
		HierarchyResult hr = new HierarchyResult();
		hr.mNodes = mNodes;
		hr.rootNodes = mParents;
		hr.mChildParent = mChildParent;
		return hr;
		
	}
	
	public static HierarchyResult buildHierarchy(Map<Id, sObject> mSObjects, Datetime asOfDate, string HierarchyType, string HierarchyName){

	/*
	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
    */
		SOQLUtil soql = new SOQLUtil('Hierarchy__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','codeId__c','parentcodeId__c','start_datetime__c','end_datetime__c'
		});
	    set <id> objKeySet = mSObjects.keySet();
	    	string WhereClause = 'start_datetime__c <= :asOfDate and (end_datetime__c = null OR end_datetime__c > :asOfDate) and (codeId__c in :objKeySet OR parentcodeId__c in :objKeySet)';
	    if(HierarchyType!= null){
	    	WhereClause += ' and Type__c =' + '\'' + HierarchyType + '\'' ;
	    }
	    if(HierarchyName!= null && HierarchyName != ''){
	    	WhereClause += ' and Name like ' + '\'%' + HierarchyName + '%\'';
	    }
	    
	    soql.setWhereClause(WhereClause);
		List<Hierarchy__c> hs = Database.query(soql.getQuery());
		
		system.debug('HierarchyType:' + HierarchyType);
		system.debug('HierarchyName:' + HierarchyName);
		system.debug('hs:' + hs);

	
		map<Id, set<Id>> mChildren = new map<Id, set<Id>>(); // Id - parent id, set of Id - child id
		map<Id, Id> mParents = new map<Id, Id>(); // Id - hierarchy id, Id - record id (here the parent of the record will be null as this is the root)
		map<Id, Id> mChildParent = new Map<Id, Id>();
		map<Id, Node> mNodes = new map<Id, Node>();
		
		for(Hierarchy__c h : hs){
			if(h.parentcodeId__c == null){
				mParents.put(h.Id, h.codeId__c); 
			}else{
				if(mChildren.containsKey(h.parentcodeId__c)){
					mChildren.get(h.parentcodeId__c).add(h.codeId__c);
				}else{
					mChildren.put(h.parentcodeId__c, new set<Id>{h.codeId__c});
				}	
			}
		}
		
		
		//Loop through the parents (root nodes) and stub out the nodes
		for(Id parentId : mParents.values()){
			//Top level node
			Id nodeId = parentId;
			Node node = new Node();
			node.Id = nodeId;
			node.label = (String) mSObjects.get(nodeId).get('name');
			node.nodes = new List<Node>();
			mNodes.put(node.Id, node);
									
		}
		
		//Now loop through all children relationships and stub out their nodes
		for(Id parentId : mChildren.keySet()){
			for(Id childId : mChildren.get(parentId)){
		system.debug('childId:  ' + childId);
				if(mSObjects.get(childId) != null){
					mChildParent.put(childId, parentId); // TODO: Add logic to handle one child with multiple parents
					Node childNode = new Node();
					childNode.Id = childId;
					childNode.label = (String) mSObjects.get(childId).get('name');
					childNode.nodes = new List<Node>();
					mNodes.put(childNode.Id, childNode);
				}
			}
		}
		
		//Now point the nodes in memory at each other
		for(Id parentId : mChildren.keySet()){
			for(Id childId : mChildren.get(parentId)){
				if(mNodes.containsKey(parentId) && mNodes.containsKey(childId)){
					mNodes.get(parentId).nodes.add(mNodes.get(childId));
				}
			}
		}
		
		HierarchyResult hr = new HierarchyResult();
		hr.mNodes = mNodes;
		hr.rootNodes = mParents;
		hr.mChildParent = mChildParent;
		return hr;
		
	}
	
	// Map<Id, sObject> mSObjects is the map of sobject id, and the sobject
	public static HierarchyResult buildHierarchy(Map<Id, sObject> mSObjects, String relFieldName){
		map<Id, set<Id>> mChildren = new map<Id, set<Id>>(); // Id - parent id, set of Id - child id
		map<Id, Id> mParents = new map<Id, Id>(); // Id - hierarchy id, Id - record id (here the parent of the record will be null as this is the root)
		map<Id, Id> mChildParent = new Map<Id, Id>();
		map<Id, Node> mNodes = new map<Id, Node>();                                                               
		
		for(SObject sObj : mSObjects.values()){
			if((Id) sObj.get(relFieldName) == null){
				mParents.put((Id) sObj.get('Id'),(Id) sObj.get('Id')); 
			}else{
				if(mChildren.containsKey((Id) sObj.get(relFieldName))){
					mChildren.get((Id) sObj.get(relFieldName)).add((Id) sObj.get('Id'));
				}else{
					mChildren.put((Id) sObj.get(relFieldName), new set<Id>{(Id) sObj.get('Id')});
				}	
			}
		}
			
		
		//Loop through the parents (root nodes) and stub out the nodes
		for(Id parentId : mParents.values()){
			//Top level node
			Id nodeId = parentId;
			Node node = new Node();
			node.Id = nodeId;
			node.label = (String) mSObjects.get(nodeId).get('name');
			node.nodes = new List<Node>();
			mNodes.put(node.Id, node);
									
		}
		
		//Now loop through all children relationships and stub out their nodes
		for(Id parentId : mChildren.keySet()){
			for(Id childId : mChildren.get(parentId)){
				mChildParent.put(childId, parentId); // TODO: Add logic to handle one child with multiple parents
				Node childNode = new Node();
				childNode.Id = childId;
				childNode.label = (String) mSObjects.get(childId).get('name');
				childNode.nodes = new List<Node>();
				mNodes.put(childNode.Id, childNode);
			}
		}
		
		
		//Now point the nodes in memory at each other
		for(Id parentId : mChildren.keySet()){
			for(Id childId : mChildren.get(parentId)){
				if(mNodes.containsKey(parentId) && mNodes.containsKey(childId)){
					mNodes.get(parentId).nodes.add(mNodes.get(childId));
				}
			}
		}
		
		HierarchyResult hr = new HierarchyResult();
		hr.mNodes = mNodes;
		hr.rootNodes = mParents;
		hr.mChildParent = mChildParent;
		return hr;
		
	}
	
	public static List<Node> getChildren(Id ParentId, Map<Id, Node> mNodes){
		if(mNodes.containsKey(ParentId)){
			return mNodes.get(ParentId).nodes;
		}else{
			return null;
		}	
	}
	
	
	public static boolean isMyParent(Id childId, Id parentId, Map<Id, Id> mChildParent){
		boolean result = false;
		while(result == false && childId != null){
			if(mChildParent.containsKey(childId)){
				if(mChildParent.get(childId) == parentId){
					result = true;
				}else{
					childId = mChildParent.get(childId);
				}
			}else{
				childId = null;
				result = false;
				break;
			}
			
		}
		return result;
	}
	
	public static void setPeriodDates(List<Hierarchy__c> hierarchyList){
		if(trigger.isbefore && (trigger.isInsert || trigger.isUpdate)){
			for(Hierarchy__c h: hierarchyList){
	
				//KNDY-10208 Enforcing Hierarchy Type.
				if(h.type__c == null){
					h.addError('Please specify hierarchy type.');
				}
				else{
					if(h.Type__c.equalsIgnoreCase('Segment Hierarchy')){
						if(h.start_period_date__c != null){
							h.start_datetime__c = h.start_period_date__c;
						}
						h.end_datetime__c = h.end_period__c != null? h.end_period_date__c: null;
						//KNDY-10316 Defaulting Start date
						h.start_date__c  = h.start_datetime__c != null ? h.start_datetime__c.date() : null;
					}
					else{//KNDY-10316 Defaulting Start date.
						if(h.start_date__c == null){
							h.start_date__c = system.today();
						}					
					}
				}
			}
		}
	}
		

}