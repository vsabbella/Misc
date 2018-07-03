trigger ProductGroup on Product_Group__c (before insert, before update) {
	
	if(DML.checkTriggerDispatch(Product_Group__c.getSobjectType())){return;}
	
	if ( trigger.isBefore && ( trigger.isInsert || trigger.isUpdate ) ) {
		/*
		 * when loading prod groups match up  
		 * with existing hierarchy records using hierarchy code, set the Hierarchy__c field
		 */
		Relate.setLookupUsingField(	Trigger.New,	Trigger.isBefore,
													'Hierarchy__c' ,		// table
													'Hierarchy__c', 		// field to set
													'Hierarchy_Code__c',  // text field we know
													'Code__c');				// field in table that has field we know
	 	
	 	Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
						                            'Company__c', 
						                            'Company__c', 
						                            'Company_Identifier__c', 
						                            'Company_Identifier__c');
	}
}