/**
 * Created by zainab_shikari on 10/13/17.
 */

public with sharing class CustomerReceiptAddDepositIDExt {

	public Apexpages.Standardsetcontroller ssCon {get;set;}
	public static list<String> sCRIds {get;set;}
	public String lCRIdsJSON{get{
		return JSON.serialize(sCRIds);}}

	public CustomerReceiptAddDepositIDExt (Apexpages.Standardsetcontroller ssController) {
		ssCon = ssController;
		sCRIds = new list<String>((Set<String>)JSON.deserialize(JSON.serialize(KSE.grepIdSetFromList(ssCon.getSelected())), Set<String>.class));
		system.debug(LoggingLevel.Error,'sCRIds '+sCRIds);
	}


	@RemoteAction
	public static JsonResult validateCustomerReceipts(list<id> sCRIds) {

		JsonResult result = new JsonResult();
		SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', true);
		soql.addFields(new set<String>{'Id','Name'});
		soql.setWhereClause('ID in :sCRIds and (Type__c != \'Receipt\' OR Status__c in (\'Cancelled\',\'Void\') OR Bank_Account_2__c = null)');
		soql.setLimit(1);
		list<Customer_Receipt__c> badCustomerReceipts = Database.query(soql.getQuery());
		if(!badCustomerReceipts.isEmpty()) {
			result.success=false;
			result.addMessage(Label.Deposit_ID_CR_Bad_Selection,ApexPages.severity.ERROR);
		}else{
			result.success = true;
		}
		return  result;

	}

	@RemoteAction
	public static JsonResult saveDepositIDs(list<String> crIDs, String depositId) {
		JsonResult result = new JsonResult();
		list<Customer_Receipt__c> lCRs = new list<Customer_Receipt__c>();
		for(String id : crIDs) {
			lCRs.add(new Customer_Receipt__c(Id = id, Deposit_Identifier__c = depositId));
		}

		try{
			DML.updateAsUser(lCRs);
			result.success = true;
		}catch(DmlException ex) {
			result.addMessage(ex, ApexPages.Severity.ERROR);
			result.success = false;
		}catch(Exception ex) {
			result.addMessage(ex, ApexPages.Severity.ERROR);
			result.success = false;
		}
		return result;
	}


}