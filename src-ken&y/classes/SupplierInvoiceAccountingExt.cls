public with sharing class SupplierInvoiceAccountingExt {
    
    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; } 
    public list<Supplier_Invoice__c> objectList {get;set;}
    set<ID> invoiceIDs = new set<ID>();
    //GenerateAccountingService GAS = new GenerateAccountingService();
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
    public boolean disableGenerate {get;set;}
    
    List<Accounting_Entry__c> acctEntryListCM = new List<Accounting_Entry__c>();
   
    public SupplierInvoiceAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        disableGenerate = false;
        
        if ( ! Schema.sObjectType.Supplier_Invoice__c.isCreateable() ) {
		      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                    Label.Insufficient_access_to_create_a_supplier_invoice));
			requiredFielderror = true;
			disableGenerate = true;
			return;
	    }
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            disableGenerate = true;
            return;
        }
        
        for (Supplier_Invoice__c invoice: (List<Supplier_Invoice__c>)setCon.getSelected() ) {      
            invoiceIDs.add(invoice.ID);
        }
        
       // String dynamicQuery = ARS.getQueryStringList(new List<String>{'Supplier Invoice','Supplier Credit Memo'});
        
        /*String objectQuery = 'SELECT id, Name, Finalized__c, Date_Invoiced__c, Company__c, Currency__c,Amount_Due__c,'
        						+ 'Invoice_Type__c, Credit_Memo_Amount__c '+
                            	+ ' FROM Supplier_Invoice__c'
                               	+ ' WHERE ID IN :invoiceIDs'
                               	+ ' AND Finalized__c = true'
                               	+ ' AND transaction_date__c != null '
                                + ' AND finalized_date__c != null ' 
                               	+ ' AND Id NOT IN ( SELECT Supplier_Invoice__c FROM Accounting_Entry__c WHERE Supplier_Invoice__c in :invoiceIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        */
        String whereClause = 'ID IN :invoiceIDs'
                           	+ ' AND Finalized__c = true'
                           	+ ' AND transaction_date__c != null '
                            + ' AND finalized_date__c != null ' 
                           	+ ' AND Id NOT IN ( SELECT Supplier_Invoice__c FROM Accounting_Entry__c' 
           					+ ' WHERE Supplier_Invoice__c in :invoiceIDs AND' 
           					+ ' related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';

	    SOQLUtil soql = new SOQLUtil('Supplier_Invoice__c');
	    soql.addFields(new Set<String>{'id', 'Name', 'Finalized__c', 'Date_Invoiced__c', 'Company__c', 'Currency__c', 
	    								'Amount_Due__c', 'Invoice_Type__c', 'transaction_type__c', 'Credit_Memo_Amount__c'});
	    soql.setWhereClause(whereClause);
	                
        objectList = Database.query(soql.getQuery());
         
        if (selecterror ) {
            return ;
        }        
        list<string> transactionTypeList = new list<string>();
        for(Supplier_Invoice__c si: (list<Supplier_Invoice__c>)objectList){
            if( String.isNotBlank(si.transaction_type__c) )
                transactionTypeList.add(si.transaction_type__c);
            else
                transactionTypeList.add(si.invoice_type__c);                    
        }      
        system.debug(LoggingLevel.Error,'__transactionTypeList___'+transactionTypeList);  
        if(!ARS.isRuleDefined(new List<String>{'Supplier_Invoice__c'}, transactionTypeList )){
	        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Create_Accounting_Rules));
	    		requiredFielderror = true;
	        	selecterror = true;
	        	disableGenerate = true;
	        	return;
        }
        
        if(objectList == null || objectList.size() < 1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process ) );
	        	requiredFielderror = true;
	          	selecterror = true;
	          	disableGenerate = true;
	        	return;
        }
        
        for(integer i = 0; i < objectList.size(); i++) {
	        	if(objectList[i].Date_Invoiced__c == null){
	        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Date_Invoiced_is_blank + objectList[i].Name ) );
	        		requiredFielderror = true;
	            	selecterror = true;
	            	disableGenerate = true;
	            	return;
	        	}
	        	if(objectList[i].Currency__c == null) {
	        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Currency_is_blank +objectList[i].Name ) );
	        		requiredFielderror = true;
	            	selecterror = true;
	            	disableGenerate = true;
	            	return;
	        	}
	        	if(objectList[i].Company__c == null) {
	        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Company_is_blank +objectList[i].Name ) );
	        		requiredFielderror = true;
	            	selecterror = true;
	            	disableGenerate = true;
	            	return;
	        	}
        }
    	    
    	    if(objectList.size() > 200 ) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Limit_selection_to_200_rows ) ); 
        		selecterror = true;
        		requiredFielderror = true; // hide the generate button KNDY-1801
        		disableGenerate = true;
            	return;
        	}
        
    } // End of Constructor
    
    //Function to generate the accounting entries for the invoice lines
    public pagereference GenerateSupplierInvAccounting() {
        Map<Id,Supplier_Invoice__c> invoiceMapUpd = new Map<Id,Supplier_Invoice__c>();
        Map<Id,Supplier_Invoice__c> invoiceMapUpdCM = new Map<Id,Supplier_Invoice__c>();
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                    //AccountingService.upsertAccountingEntry(objectList);          
	                set<Id> sourceDocIds = new set<Id>();
	                set<Id> companyIds = new set<Id>();
	                for(Supplier_Invoice__c si : objectList){
	                    companyIds.add(si.company__c);
	                    sourceDocIds.add(si.Id);
	                }   
	                                    
	                SupplierInvoiceAccountingBatch  batch = new SupplierInvoiceAccountingBatch(companyIds);
	                batch.setSourceDocId(sourceDocIds);
	                batch.setuseSuperWhere(true);
	                string jobid= Database.ExecuteBatch(batch);
	                
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
	                disableGenerate = true;
      
                }catch(Exception e){
                    Database.rollback(sp);
                    selecterror = true;
                    ApexPages.addMessages(e);
                    disableGenerate = true;
                    return null;
                }
        }
        
         //KNDY-2020 Checking for Pg msgs before moving the page forward. Hiding the button if any error or fatal msgs
        if (Apexpages.hasMessages(ApexPages.Severity.FATAL) || Apexpages.hasMessages(ApexPages.Severity.ERROR)){
	        	requiredFielderror = true;
	        	selecterror = true;	      
        }
        
        return (Apexpages.hasMessages() ? null : this.setcon.cancel() ); 
        
    } 
    
}