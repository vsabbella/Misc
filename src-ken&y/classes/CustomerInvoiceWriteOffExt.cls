public with sharing class CustomerInvoiceWriteOffExt {
	
	Apexpages.Standardcontroller con {get;set;}
	public boolean disableAction {get;set;}
	public SchemaUtil util = new SchemaUtil();
	
	
	public CustomerInvoiceWriteOffExt(Apexpages.Standardcontroller controller){
		con = controller;
		validate();
	}
	
	public void validate(){
		//con.reset();
		Customer_Invoice__c ci = (Customer_Invoice__c)con.getRecord();
		if(ci.Status__c == CustomerInvoiceService.STATUS_CLOSED || ci.Status__c == CustomerInvoiceService.STATUS_CANCEL || ci.Status__c =='Void'){
			disableAction = true;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, Label.This_invoice_is_not_open));
		}else if(!ci.Finalized__c){
			disableAction = true;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, Label.Cannot_writeoff_invoice_not_finalized));
		}else{
			disableAction = false;
		}
		/*
		else if(ci.RecordType.Name == CustomerInvoiceService.RT_CREDIT_MEMO){
			disableAction = true;
			Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, 'You cannot write off a credit memo.'));
		}
		*/
	}
	
	public void writeOff(){
		validate();
		if(!disableAction){
			CustomerInvoiceService cis = new CustomerInvoiceService();
			try
			{
				con.save(); //AR-85 save the RES CODE
				if(!Test.isRunningTest())
					con.reset();
				Customer_Invoice__c ci = (Customer_Invoice__c)con.getRecord();
				cis.writeOffInvoices(new List<Customer_Invoice__c>{ci}); //Writes OFF the balance, saves the CI and sets the status
				disableAction = true;
				if(!Test.isRunningTest())
					con.reset(); //reset to how the new status and balance. 
				Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.CONFIRM, Label.WriteOff_completed));
			}
			catch(Exception ex)
			{
				Apexpages.addMessage(new Apexpages.Message(Apexpages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			}
			
		}
	}
	
}