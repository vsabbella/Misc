/** 
 * @description When inserting an item sepcifcation with no item lookup filled in, make an attempt
 * to locate the correct item in the system.  This depends on the Item_Name field filled in correctly
 * and on this field being unique.
 * 
 */
trigger ItemSpec on Item_Specification__c (before insert, before update, before delete) {
	
	if(DML.checkTriggerDispatch(Item_Specification__c.getSobjectType())){return;}
	
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
		// KNDY-19153
//		ItemService.validatePackagingUOMs(trigger.new);

		if(trigger.isUpdate) {
			ItemService.itemSpecWOCheck(trigger.new);
		}
		
		// relate this record to item and compay using text fields ( if they are filled in )
		// designed to work with both before insert AND before update
		
        Relate.setLookupUsingField( Trigger.New,Trigger.isBefore, 
                                   'Company__c', 
                                   'Company__c', 
                                   'Company_Identifier__c',
                                   'Company_Identifier__c' 
                                  );
	
        Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,  
                                   'Item__c',
                                   'Item__c',
                                   'Item_Name__c',
                                   'Name'
                                  );				
        
        Relate.setLookupUsingField(Trigger.New,Trigger.isBefore,
                                   'Facility__c' , // related object 
                                   'Facility__c',  // lookup field name to fill 
                                   'Facility_Identifier__c', // field to use to query
                                   'Primary_Key__c' );   // field in related table to find
        
		
	} // end isBefore
	
	if(trigger.isBefore && trigger.isDelete){
		KSE.blockRecordDeletion();
	}
}