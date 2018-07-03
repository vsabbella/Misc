public with sharing class BatchInjector {

	private BatchInjector(){}

	public Type executer{get;private set;}
	public Integer sequence{get;private set;}
	public Integer scope{get;private set;}

	public static BatchInjector getNextBatch(String obj, Integer currentSequence){

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Process__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Namespace__c','Object_Step__c', 'State__c', 'Sequence__c'
		});
		soql.setWhereClause('Object__c =: obj and Active__c = true and Bulk__c = true and Sequence__c >:currentSequence');
		soql.setLimit(1);
		soql.setOrderByClause('Sequence__c');
		List<Process__c> p = Database.query(soql.getQuery());

		if(p != null && p.size() == 1){
			return BatchInjector.getNextBatch(p.get(0));
		}else{
			BatchInjector b = new BatchInjector();
			b.executer = null;
			b.scope = -1;
			b.sequence = -1;
			return b;
		} 

		
		
	}

	public static BatchInjector getNextBatch(Process__c p){
		Type t = null;
		Integer scopeSize = -1;
		Integer sequence = -1;

		t = Type.forName(p.Namespace__c, p.Object_Step__c);
		sequence = p.Sequence__c.intValue();
		try{
			scopeSize = Integer.valueOf(p.State__c);
		}catch(Exception ex){

		}

		if(scopeSize < 10){
			scopeSize = 200;
		}

		BatchInjector b = new BatchInjector();
		b.executer = t;
		b.scope = scopeSize;
		b.sequence = sequence;

		return b;

	}
}