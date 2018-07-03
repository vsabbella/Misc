/**
 * Created by zainab_shikari on 11/6/17.
 */

public with sharing class SupplierInvoiceValidateExt {

	ApexPages.StandardController stdcon;
	Supplier_Invoice__c si;
	Schemautil util = Schemautil.getInstance();
	public boolean OnholdFlag{get;set;}
	public boolean redirect {get;private set;}

	public SupplierInvoiceValidateExt(Apexpages.standardcontroller controller) {
		this.stdcon = controller;
		OnholdFlag= false;
		si = (Supplier_Invoice__c)stdcon.getRecord();
		system.debug(LoggingLevel.Error,'si '+si);
		if (si == null || si.Id == null ) {
			pageMessages(Label.No_record_ID_found, 'FATAL');
		} else {
			system.debug(LoggingLevel.Error,'si in else of no record ID found '+si);
			set<String> fieldStrings = new set<string>{'Id','Name','Status__c','Finalized__c','Hold__c'};
			SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c');
			soql.addFields(fieldStrings);
			String siId = si.Id;
			soql.setWhereClause('Id = :siId and Status__c not in (\'Approved\',\'Void\',\'Cancelled\' )');
			soql.setForUpdate();
			soql.setLimit(1);
			try {
				si = Database.query(soql.getQuery());
				system.debug(LoggingLevel.Error,'si '+si);
				if(si.Hold__c == true) {
					PageMessages(Label.Invoice_is_on_hold,'FATAL');
					onholdflag = true;
				}
			}catch(Exception ex) {
				onholdflag = true;
				system.debug(LoggingLevel.Error,'ex '+ex);
				system.debug(LoggingLevel.Error,'ex '+ex.getMessage());
				if(ex.getMessage().contains('List has no rows for assignment to SObject'))
					PageMessages(Label.Supplier_Invoice_Cannot_Validate, 'FATAL');
			}
		}
	}

	public Pagereference close() {
		PageReference pr;
		if( si.id != null ) {
			pr = new PageReference('/'+si.id);
		} else {
			if (apexPages.currentPage().getParameters().get('retUrl') != null) {
				pr = new PageReference('/' + apexPages.currentPage().getParameters().get('retUrl') );
			} else {
				Schema.DescribeSObjectResult dsr = Supplier_Invoice__c.SObjectType.getDescribe();
				pr = new PageReference('/' + dsr.getKeyPrefix());
			}
			pr.setRedirect(true);
		}
		return pr;
	}

	public PageReference inspect() {

		JsonResult result = SupplierInvoiceService.inspectSI(si.Id);
		system.debug(LoggingLevel.Error,'result '+result);
		for(Map<String, String> message: result.messages) {
			PageMessages(message.get('message'), message.get('severity'));
		}

		SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c');
		soql.addFields(new set<String>{'Id', 'Status__c'});
		String siId = si.Id;
		soql.setWhereClause('Id = :siId');
		soql.setForUpdate();
		soql.setLimit(1);
		try {
			si = Database.query(soql.getQuery());
			if(si.Status__c  == 'Incomplete' || si.Status__c  == 'Draft') {
				PageMessages(Label.Inspect_process_complete_check_exception_task_list,'INFO');
				onholdflag = true;
				redirect = false;
			}else {
				redirect = true;
			}
		}catch(Exception ex) {
			PageMessages(ex.getMessage(), 'ERROR');
			redirect = false;
		}

		return null;
	}

	// function to show page messages
	void pageMessages( string msg , String severityLevel) {
		if(severityLevel.equalsIgnoreCase('FATAL')){
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.FATAL, MessageUtil.toFriendlyErrorMessage(msg)));
		}else if(severityLevel.equalsIgnoreCase('WARNING') ){
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, MessageUtil.toFriendlyErrorMessage(msg)));
		}else if(severityLevel.equalsIgnoreCase('INFO') ){
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.INFO, MessageUtil.toFriendlyErrorMessage(msg)));
		}
	}
}

