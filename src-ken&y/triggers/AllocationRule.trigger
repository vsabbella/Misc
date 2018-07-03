trigger AllocationRule on Allocation_Rule__c (before insert, after insert, before update) {
	if(DML.checkTriggerDispatch(Allocation_Rule__c.getSobjectType())){return;}
	if (Trigger.isInsert) {
	    
	    if (trigger.isAfter) {
	        Allocation_Rule__c[] rulesToValidate = new Allocation_Rule__c[]{};
	        for (Allocation_Rule__c newAR : Trigger.new) {
    			rulesToValidate.add(newAR); 
	        }
	        
	        Allocation_Rule__c[] validRules = AllocationRuleService.validate(rulesToValidate);
        	System.debug('Post Insert Valid Rules: ' + validRules);
        	if (!validRules.isEmpty()) {
        	    List<Allocation_Rule__c> rulesForCalc = new List<Allocation_Rule__c>(); 
        	    for (Allocation_Rule__c ar : validRules) {
        	        rulesForCalc.add(ar.clone(true));
        	    }
        	    // calculate allocation used
        	   AllocationRuleService.populateUsedAllocation(rulesForCalc, null, false); 
        	    // For Allocation Used field
        	    DML.updateAsUser(rulesForCalc);
        	}
	    }
	    
	} else {
	    Allocation_Rule__c[] rulesToValidate = new Allocation_Rule__c[]{};
		for (Allocation_Rule__c newAR : Trigger.new) {
			if (KSE.isFieldChanging('Product__c', newAR, Trigger.oldMap)
				|| KSE.isFieldChanging('Customer__c', newAR, Trigger.oldMap)
				|| KSE.isFieldChanging('Company__c', newAR, Trigger.oldMap)
				|| KSE.isFieldChanging('Facility__c', newAR, Trigger.oldMap)
				|| KSE.isFieldChanging('Start_Date__c', newAR, Trigger.oldMap)
				|| KSE.isFieldChanging('End_Date__c', newAR, Trigger.oldMap)
				|| KSE.isFieldChanging('Allocation__c', newAR, Trigger.oldMap)
				) {
				Allocation_Rule__c oldAR = Trigger.oldMap.get(newAR.Id);
				rulesToValidate.add(newAR);		
			}
		}	
		if (!rulesToValidate.isEmpty()) {
    		Allocation_Rule__c[] validRules = AllocationRuleService.validate(rulesToValidate);
    		set<Id>SOL_IDs = new set<Id>();
        	System.debug('Before Update Valid Rules: ' + validRules);
        	if (!validRules.isEmpty()) {
        	    // calculate allocation used
        	    
				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				
				SOQLUtil soql = new SOQLUtil('Allocation_Rule__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'Id'
				});
				soql.setWhereClause('Id in :validRules');
				
				SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Sales_Order_Lines__r');
				childRel.addFields(new set<string>{
					'Id'
				});
				soql.addChildRelationship(childRel);

				list<Allocation_Rule__c> rules = Database.query(soql.getQuery());

        	    for(Allocation_Rule__c rule : rules)
        	    {
        	    	for(Sales_Order_Line__c sol : rule.Sales_Order_Lines__r)
        	    		SOL_IDs.add(sol.id);
        	    }
        	    AllocationRuleService.populateUsedAllocation(validRules, SOL_IDs, false);
        	    // no update needed on rules, as its before update context
        	}
		}
	}
}