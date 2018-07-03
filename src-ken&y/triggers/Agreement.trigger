trigger Agreement on Agreement__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    if(DML.checkTriggerDispatch(Agreement__c.getSobjectType())){return;}
    if(trigger.isDelete){
        for(Agreement__c  ar:Trigger.old){
          	if(ar.Status__c  == 'Approved' ){
            	ar.addError('Approved Agreement Cannot be Deleted');
            }
     	}
    }
    
    AgreementService.setRecurrenceStartDate();
     //KNDY-8247
    if(trigger.isAfter && trigger.isInsert){
       	set<id> aId =new set<id>(); 
        
        for(Agreement__c  ar:Trigger.new){
            aId.add(ar.id);
        }
	    
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Agreement__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id'
		});
		soql.setWhereClause('id in :aId');

		List <Agreement__c> aList = Database.query(soql.getQuery());

        AgreementService.getPaymentTerms(aList);  
    }
}