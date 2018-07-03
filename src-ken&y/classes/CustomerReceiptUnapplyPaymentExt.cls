public with sharing class CustomerReceiptUnapplyPaymentExt {

	private Id CRId;
	private Customer_Receipt__c CRRecord;
	private apexpages.standardController controller; 
	
	public Boolean unapplyDisabled{get;set;}

	public CustomerReceiptUnapplyPaymentExt(apexpages.standardController con){
		this.controller = con; 
		//get the current customer receipt record
		this.CRId = con.getRecord().Id;
	
	}
}