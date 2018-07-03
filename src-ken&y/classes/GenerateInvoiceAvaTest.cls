global with sharing class GenerateInvoiceAvaTest implements ICustomAction {

	global List<Object> executeAction(List<SObject> scope){

		List<CustomActionResponse>results = new List<CustomActionResponse>();

		List<Customer_Invoice__c>invoices = (List<Customer_Invoice__c>)scope;

		List<Customer_Invoice_Line__c>invoiceLines = [Select Id From Customer_Invoice_Line__c Where Customer_Invoice__c in: invoices];

		for(Customer_Invoice_Line__c cl : invoiceLines){
			cl.Sales_Tax__c = 20;
		}

		DML.updateAsUser(invoiceLines);


		for(Customer_Invoice__c inv : invoices){
			inv.Memo__c = 'Process injected.';

			CustomActionResponse car = new CustomActionResponse();
			car.isSuccess = true;
			car.msg = 'nothing';
			car.obj = inv;
			results.add(car);
		}

		return results;
	}

}