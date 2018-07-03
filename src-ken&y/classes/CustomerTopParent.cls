public with sharing class CustomerTopParent {
		/*  KNDY-307 */
	
	public static void setupTopParent( List<Customer__c> trigger_new ) {
			
		List<Customer__c> missingTops = new List<Customer__c>(); 
		
		for ( Customer__c obj : trigger_new ) {
			
			if ( obj.Top_Parent_Customer__c == null  &&  // NB: should we check if parent_customer is changing?
				  obj.Parent_Customer__c != null ) 
			{
				// need to set top parent on this, and it has a parent but no top
				missingTops.add( obj);
			}
		}

		if ( missingTops.size() > 0 ) {
		
			// grab the parent ids into a set
			Set<Id> parentSet = new Set<Id>();	
			for ( Customer__c obj:  missingTops ) {	parentSet.add( obj.Parent_Customer__c );			} 

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Parent_Customer__c','RecordTypeId'
			});
			soql.setWhereClause('id in :parentSet');
			Map<id, Customer__c> parentMap = new Map<id, Customer__c>((List<Customer__c>)Database.query(soql.getQuery()));

			// for all the parents in parentMap, if their parent field is empty, they are the top.  if not, fetch their parents now
			parentSet.clear(); 
			for ( Customer__c obj : parentMap.values() ) {	
				if ( obj.Parent_Customer__c != null ) 
					parentSet.add( obj.Parent_Customer__c );			
			}
			if ( parentSet.size() > 0 ) { 
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				soql = new SOQLUtil('Customer__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Parent_Customer__c','RecordTypeId'
				});
				soql.setWhereClause('id in :parentSet');
				for ( Customer__c obj: Database.query(soql.getQuery())) {
					parentMap.put( obj.id, obj );
				}
			}

			// start at the corp parent
			Map<String,String> CustomerRecordTypes = KSE.RecordTypeDevNameMap('Customer__c');
			for ( Customer__c obj : missingTops) { 
				
				// nothing to do on copr parent, start with bill to
				if (  CustomerRecordTypes.get('Bill_To') == obj.RecordTypeId ) {
					// my parent is the top, so set that
					obj.Top_Parent_Customer__c = obj.Parent_Customer__c; 
				} else if (  CustomerRecordTypes.get('Sold_To') == obj.RecordTypeId ) {
					// my parent's parent
					if ( parentMap.get(obj.Parent_Customer__c) != null )
						obj.Top_Parent_Customer__c = parentMap.get(obj.Parent_Customer__c).Parent_Customer__c;
						
				} else if (  CustomerRecordTypes.get('Ship_To') == obj.RecordTypeId ) {
					// my great grand parent
					if ( parentMap.get(obj.Parent_Customer__c) != null ) {
						Id gp = parentMap.get(obj.Parent_Customer__c).Parent_Customer__c;
						if ( gp != null )
							obj.Top_Parent_Customer__c = parentMap.get(gp).Parent_Customer__c;
					}

				} 				
				
			}
			
		} 
	}
	
}