public with sharing class DownpaymentInvoiceExt {
	public string NamespaceUU { get { return KSE.NamespaceUU; }}
	public Apexpages.Standardcontroller con {get;set;}
	public boolean isDisabled {get;set;}
	public OneTimeInvoiceService.CustomerInvoiceWrapper wrapper{get;set;}
	public String errorMsg{get;set;}
	public boolean isSuccess {get;set;}
	public DownpaymentInvoiceExt(ApexPages.standardController sCon) {
		
		if(sCon == null) {
			ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.ERROR, 'No agreement is specified.'));
		}else{
			this.con = sCon;
			isDisabled = false;
			isSuccess =false;
			wrapper = new OneTimeInvoiceService.CustomerInvoiceWrapper();
		}
		
	}
	
	public void validate() {
	  
	  Agreement__c a = (Agreement__c) con.getRecord();
	  map<Id,String> errorResponses = OneTimeInvoiceService.validateInvoiceCreate(new set<Id>{a.Id});
	  for(Id agId : errorResponses.keySet()) {
			ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(errorResponses.get(agId))));
			isDisabled = true;
	  }
	}
	
	
	public void createDownPaymentInvoice() {
		
		validate();
		
		if(!isDisabled) {
			Agreement__c a = (Agreement__c) con.getRecord();
			try {
				OneTimeInvoiceService.createDownpaymentInvoices(new set<Id>{a.Id});
				wrapper = OneTimeInvoiceService.mAgreement2Invoices.get(a.Id);
				
			}catch(Exception ex) {
				ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
			}
		}
		
	}
	
	public void saveInvoice() {
        list<OneTimeInvoiceService.CustomerInvoiceWrapper> wrappers = new list<OneTimeInvoiceService.CustomerInvoiceWrapper>();
        boolean setWrapper = false;
        for(OneTimeInvoiceService.CustomerInvoiceLineWrapper cil: wrapper.lCILs) {
            if(cil.selected) {
                setWrapper = true;
                
            } else {
                ApexPages.addMessage( new ApexPages.Message( ApexPages.severity.WARNING, 'Please select lines'));
            }
        }
        if(setWrapper){
            wrappers.add(wrapper);
            try {
                list<Customer_Invoice__c> lCI = OneTimeInvoiceService.saveWrapper(wrappers);

				//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
				SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
				soql.addFields(new set<string>{
					'id','Name'
				});
				soql.setWhereClause('id in :lCI');
				soql.setLimit(1);
				Customer_Invoice__c ci = ((List<Customer_Invoice__c>)Database.query(soql.getQuery()))[0];

                errorMsg = '<a href="/'+ci.Id+'">' + ci.Name + '</a>' + ' was created successfully';
                isSuccess =true;
            }catch(exception ex) {
                system.debug('ex '+ex.getMessage());
                system.debug('ex '+ex.getStackTraceString());
                isSuccess =false;
                ApexPages.addMessage(new ApexPages.Message( ApexPages.severity.ERROR, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
				system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
                //return null;
            }  
        }
		
	}

}