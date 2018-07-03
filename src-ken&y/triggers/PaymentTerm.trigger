trigger PaymentTerm on Payment_Term__c (before update,before delete) {
    
    //Bypassed the trigger for special cases like post install script
    if(DML.checkTriggerDispatch(Payment_Term__c.getSobjectType())){return;}
    
    set<Id> termsid = new set<Id>();
    for(Payment_Term__c pt : trigger.isUpdate ? trigger.new : trigger.old)
    {
    	if(trigger.isUpdate) {
    		set<String> fieldNames= SchemaUtil.getInstance().getAllPackagedFieldsFromSObject(null,'Payment_Term__c');
    		fieldNames.add('Name');
    		for(String name : fieldNames)
    			if(KSE.isFieldChanging(name,pt,trigger.oldmap))
    				termsid.add(pt.id);
    	}
    	else
        	termsid.add(pt.id);
    }
    
    set<String> relationShipNames = new set<String>();
    for( Schema.ChildRelationship rp : Payment_Term__c.sObjectType.getdescribe().getChildRelationships()) //get all child relationships on payment term
    {
        if(rp.getChildSObject().getDescribe().isCustom()){//checks if its a custom object
            if (rp.getRelationshipName() != null){ //KNDY-12096 KNDY-12187
                relationShipNames.add(rp.getRelationshipName() );
            }
        }
    }
    
    if(!relationShipNames.isEmpty())
    {
    	// KNDY-10473 FLS Security Fixes for SOQL queries
        list<String> childQueries= new list<String>();
        SOQLUtil soql = new SOQLUtil ('Payment_term__c') ;
        soql.addField ('Id');
        soql.setWhereClause ('Id in :termsid');
        //String template = '(Select id from <CHILDNAME>)';
        for(String child : relationShipNames) 
        {
            //childQueries.add(template.replace('<CHILDNAME>',child));
            SOQLUtil.ChildRelationship childSoql = new SOQLUtil.ChildRelationship ( soql , child ) ;
            childSoql.addField ('Id');
            
            soql.addChildRelationship (childSoql);
        }
        
        String subqueries = String.join(childQueries,',');// EX: (Select id from Customer_Invoices__r)
        //String query = 'Select id, '+subqueries+' from Payment_term__c where Id in :termsid';
        //system.debug('inside pt trigger, query: '+query);
        
        set<id> termsCannotUpdateDelete = new set<id>();
        //for(Payment_Term__c pt : (List<Payment_Term__c>) Database.query(query))
        for(Payment_Term__c pt : (List<Payment_Term__c>) Database.query( soql.getQuery() ))
        {
            system.debug(pt);
            for(String child : relationShipNames)
            {
                system.debug('child: '+child);
                //system.debug('inside PT trigger, pt.get() '+pt.Suppliers1__r);
                if(pt.getsObjects (child) != null && pt.getsObjects (child).size() >0) //if the relationship exists and has data, u cant delete so save the term id in a list
                    termsCannotUpdateDelete.add(pt.id);
            }
        }
        
        if(!termsCannotUpdateDelete.isEmpty())
        {
            for(Payment_Term__c pt : trigger.isUpdate ? trigger.new : trigger.old)
            {
                if(termsCannotUpdateDelete.contains(pt.Id))
                    pt.addError(Label.CannotUpdateDeletePaymentTerms);
                    
            }
        }
        
        
    }

}