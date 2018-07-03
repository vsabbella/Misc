trigger Supplier on Supplier__c (before insert, before update, before delete) {
    // deal with record types on supplier data load
    // Purchase_From, Remit_To
    // set the record type if the record type name field is filled in       
    if(DML.checkTriggerDispatch(Supplier__c.getSobjectType())){return;}
    
    if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
        Relate.setRecordTypeUsingDeveloperName( Trigger.New, Trigger.isBefore, 'Record_Type_Name__c' );
        for(Supplier__c sup : Trigger.new){
        	if(sup.Invoice_Matching__c == null || sup.Invoice_Matching__c == ''){
        		sup.Invoice_Matching__c = 'Three Way';
        	}
        }
    }
    
    if(trigger.isBefore && trigger.isDelete){
		KSE.blockRecordDeletion();
	}
}