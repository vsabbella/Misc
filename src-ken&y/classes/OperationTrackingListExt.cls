public with sharing class OperationTrackingListExt {
	public String namespaceUU { get { return KSE.NamespaceUU; } }
	public Id woId { get; set; }
	public List<Operation_Tracking__c> operations { get; set; }

	public OperationTrackingListExt(ApexPages.StandardController con) {
		woId = con.getId();

		SOQLUtil opQuery = new SOQLUtil('Operation_Tracking__c');
		opQuery.addAllCustomFields();
		opQuery.addFields('ViewOperations');
		opQuery.setWhereClause('Work_Order__c = :woId');
		opQuery.setOrderByClause('Sequence__c ASC');

		operations = Database.query(opQuery.getQuery());
	}
}