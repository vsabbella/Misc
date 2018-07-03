trigger Supplier1099 on Supplier_1099__c (after insert) {

	if(DML.checkTriggerDispatch(Supplier_1099__c.getSobjectType())){return;}
	//TODO Move this to a service class

	//Initialize a set of ids of supplier 1099 to retrive
	Set<Id> supplierIds = new Set<Id>();
	Set<Id> supp1099Ids = new Set<Id>();
	Set<Id> companyIds = new Set<Id>();
	Map<String, Supplier_1099__c> x1099Map = new Map<String, Supplier_1099__c>();

	for(Supplier_1099__c record:Trigger.new){
		String key = record.Company__c ;
		key += record.Supplier__c ;
		x1099Map.put(key, record);
		supplierIds.add(record.Supplier__c);
		supp1099Ids.add(record.Id);
		companyIds.add(record.Company__c);
	}

	//Query the previous supplier 1099 records for the records to process
	List<Supplier_1099__c> previousRecords = new List<Supplier_1099__c>();

	//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
	
	SOQLUtil soql = new SOQLUtil('Supplier_1099__c', true); //enforceFLS=true, running in user mode
	soql.addFields(new set<string>{
		'Id', 'Filed__c', 'Company__c', 'Supplier__c'
	});
	soql.setWhereClause('Supplier__c IN :supplierIds and Company__c in :companyIds and Exclude__c = false and Id NOT IN :supp1099Ids');
	previousRecords = Database.query(soql.getQuery());

	if(previousRecords.size() > 0){
		
		for(Supplier_1099__c prevRecord:previousRecords){
			if (!prevRecord.Filed__c){
				String prevRecordKey = prevRecord.Company__c;
				prevRecordKey += prevRecord.Supplier__c;
				if (x1099Map.containsKey(prevRecordKey)){
					prevRecord.Exclude__c = true;
				}
			}
		}

		DML.updateAsUser(previousRecords);
		
	}
}