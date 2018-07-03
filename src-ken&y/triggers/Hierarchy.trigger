trigger Hierarchy on Hierarchy__c (before insert, before update) {
	
	if(DML.checkTriggerDispatch(Hierarchy__c.getSobjectType())){return;}
	
	// set the parent lookup if possible
	if ( trigger.isBefore && ( trigger.isInsert || trigger.isUpdate)) {
		HierarchyService.setPeriodDates(Trigger.new);	
		 /*Relate.setLookupUsingField(
            Trigger.New, Trigger.isBefore, 'Hierarchy__c', 'Parent__c', 'Parent_Code__c','Code__c'); */
        string relatedObjectAPIName='Hierarchy__c';
        string lvalue='Parent__c';
        string rvalue='Parent_Code__c';
        string sourcevalue='Code__c';
        string and_where = ' and Current_bool__c = true ';
        List<String> ref = new List<string>();
    
        for ( Sobject obj: Trigger.New ) { 
            if ( obj.get(lvalue) == null  && obj.get(rvalue) != null ) {
                ref.add( (string)obj.get(rvalue) );
            }
        }
        
        //system.debug(logginglevel.INFO, ref + ' srcvalue : ' + sourcevalue);
        
        if (ref.size() > 0 ) {
            // KNDY-10473 FLS Security Fixes for SOQL queries
            Map<string,id> myMap = new Map<string,id>();
            SOQLUtil soql = new SOQLUtil ( relatedObjectAPIName ) ;
            soql.addFields ( new Set<String> {'id' , sourcevalue } ) ;
            soql.setWhereClause ( sourcevalue+'  in :ref '+ and_where);
            /*for ( sobject i: Database.query('select id, '+sourcevalue + 
                                            '  from ' + relatedObjectAPIName +
                                            '  where '+sourcevalue+'  in :ref '
                                            + and_where ) ) {*/
            for ( sobject i : Database.query (soql.getQuery()) ) {                                 
                                                myMap.put( (string)i.get(sourcevalue), i.id);
                                            }
            //system.debug(logginglevel.INFO, myMap.keySet() );
            
            for ( sobject obj: Trigger.New) { 
                if (obj.get(lvalue) == null     && 
                    obj.get(rvalue) != null     && 
                    myMap.containsKey( (string)obj.get(rvalue) ) )  
                {
                    obj.put(lvalue, myMap.get( (string)obj.get(rvalue) ) );
                }
            }
        }
	}
}