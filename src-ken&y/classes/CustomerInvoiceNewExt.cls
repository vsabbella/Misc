public with sharing class CustomerInvoiceNewExt {
	
    public string title {get; private set; }
    public List<Schema.FieldSetMember> inputFields { get; set; } 
        
	public CustomerInvoiceNewExt(ApexPages.StandardController controller) {
		
		// set some simple defaults for customer invoices  
        Customer_Invoice__c newObj = (Customer_Invoice__c)controller.getRecord();
        newObj.Company__c = CompanyService.getDefaultCompanyId();
        newObj.Date_Invoiced__c = Datetime.Now();
        newObj.Status__c = 'Open';

		// default a few fields differently depending on the record type
    			title='Invoice';
    			newObj.Invoice_Type__c = 'Manual';
    			inputFields = util.getFieldsFromFieldSet(Customer_Invoice__c.SobjectType, 
    																		'New_Customer_Invoice_Type');
		
    }

    private SchemaUtil util = SchemaUtil.getInstance();

}