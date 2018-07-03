public with sharing class CustomerReceiptAccountingExt {

    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; }
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; }
    
    public list<Customer_Receipt__c> objectList {get;set;}
    set<ID> receiptIDs = new set<ID>();
    //GenerateAccountingService GAS = new GenerateAccountingService();
    CustomerReceiptAccounting cra = new CustomerReceiptAccounting();
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
    
    public CustomerReceiptAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        if ( ! Schema.sObjectType.Customer_Receipt__c.isCreateable() ) {
		      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                               	Label.Insufficient_access_to_create_Customer_Receipt));
			requiredFielderror = true;
			return;
	    }
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Customer_Receipt__c receipt: (List<Customer_Receipt__c>)setCon.getSelected() ) {      
            receiptIDs.add(receipt.ID);
        }
        
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Customer Receipt'});

        String fieldString = ' ID, Name, Amount_Received__c, Amount_Unapplied__c, Customer__c, Finalized__c, Company__c, Currency__c, Date_Received__c,Type__c, transaction_type__c ';
        Set<String> fieldPaths = new Set<String>(fieldString.split(','));
		String whereClause = 'ID in :receiptIDs'+
                    ' and Finalized__c = true'+
                    ' and transaction_date__c != null'+
                    ' and finalized_date__c != null' +
                    ' and id not in ( Select Customer_Receipt__c from Accounting_Entry__c where Customer_Receipt__c in :receiptIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
                        
                    //' and id not in ( Select Customer_Receipt__c from Accounting_Entry__c where Customer_Receipt__c in :receiptIDs and void__c != true ) ' ; // TODO: Add logic to pick the src doc records which are not voided or cancelled ?
        SOQLUtil soql = new SOQLUtil('Customer_Receipt__c', TRUE);
        soql.addFields(fieldPaths);
        soql.setWhereClause(whereClause);

        objectList = Database.query(soql.getQuery());
        
        if (selecterror ) {
            return ;
        }
        list<string> transactionTypeList = new list<string>();
        
        for(Customer_Receipt__c cr: (list<Customer_Receipt__c>)objectList){
        		if(cr.transaction_type__c != null && cr.transaction_type__c != '')
        			transactionTypeList.add(cr.transaction_type__c);
        		else
        			transactionTypeList.add(cr.type__c);
        
        }
        transactionTypeList.add('Customer Receipt');
        if(!ARS.isRuleDefined(new List<String>{'Customer_Receipt__c'}, transactionTypeList)){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Create_Accounting_Rules));
    		requiredFielderror = true;
        	selecterror = true;
        	return;
        }
        if(objectList == null || objectList.size() < 1){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process ) );
          	requiredFielderror = true;
          	selecterror = true;
        	return;
        }
        for(integer i = 0; i < objectList.size(); i++){
        	if(objectList[i].Date_Received__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Date_Received_is_blank_for + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Currency__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Currency_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Company__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Company_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        }
        
    } // End of Constructor
    
    
    //Function to generate the accounting entries for the invoice lines
    public pagereference GenerateCustomerReceiptAccounting() {
        Map<Id,Customer_Receipt__c> receiptMapUpd = new Map<Id,Customer_Receipt__c>();
        
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                //GAS.createCustReceiptAccounting(objectList);
                //FIN-759 CR Generate Accounting List fix
                set<Id> sourceDocIds = new set<Id>();
                set<Id> companyIds = new set<Id>();
                for(customer_receipt__c cr : objectList){
                	companyIds.add(cr.company__c);
                	sourceDocIds.add(cr.Id);
                }
                
                CustomerReceiptAccountingBatch  batch = new CustomerReceiptAccountingBatch(companyIds);
                batch.setSourceDocId(sourceDocIds);
                batch.setuseSuperWhere(true);
                
                //Create a stub header
                //AccountingService.upsertAccountingEntry(objectList);
                
                String jobid=Database.ExecuteBatch(batch);
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
				BatchInitiated=true;
                
                // KNDY 2196 - Changed the approach to update the Accounted flag on source document.
                
            }catch(Exception e){
                Database.rollback(sp);
                selecterror=true;
                String errorMessage = e.getMessage();
                ApexPages.addMessages(e);
                return null;
            }
        }

        //KNDY-2020 Checking for Pg msgs before moving the page forward. Hiding the button if any error or fatal msgs
        if (Apexpages.hasMessages(ApexPages.Severity.FATAL) || Apexpages.hasMessages(ApexPages.Severity.ERROR)){
        	requiredFielderror = true;
        	selecterror = true;
        	
        }
        return (Apexpages.hasMessages() ? null : this.setcon.cancel() ); 
        //return setcon.cancel();
    } 
    
    
}