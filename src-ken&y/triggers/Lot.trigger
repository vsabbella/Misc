trigger Lot on Lot__c (before delete, after update) {
	
	if(DML.checkTriggerDispatch(Lot__c.getSobjectType())){return;}
	
	if(trigger.isAfter && trigger.isUpdate){
		set<Id> lotIds = new set<Id>();
		map< Id, Date > expirationMap = new map< Id, Date >();
		
		for( Lot__c l : trigger.new ){
			
			if ((KSE.isFieldChanging('Expiration_Date__c', l, Trigger.oldMap)) == true){
				
				lotIds.add( l.id );
				expirationMap.put( l.id, l.Expiration_Date__c );
			}
		}
		
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','expiration_date__c','lot__c'
		});
		soql.setWhereClause('Lot__c IN :lotIds and Type__c = \'Location\'');
	
		List<SKID__c> skidList = Database.query(soql.getQuery());
		
		for( SKID__c skid : skidList ){
			
			skid.Expiration_Date__c = expirationMap.get( skid.lot__c );
		}
		
		DML.updateAsSystem(skidList);
	}
	
	if(trigger.isBefore && trigger.isDelete){
		KSE.blockRecordDeletion();
	}
}