public with sharing class CustomerInvoiceAccountingExt {
    
    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; } 
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; } 
    
    public list<Customer_Invoice__c> objectList {get;set;}
    set<ID> invoiceIDs = new set<ID>();
    //GenerateAccountingService GAS = new GenerateAccountingService();
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    List<Accounting_Entry__c> acctEntryListCM = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
     
    public CustomerInvoiceAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        
        if ( ! Schema.sObjectType.Customer_Invoice__c.isCreateable() ) {
		      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                               	Label.Insufficient_access_to_create_Customer_Invoice));
			requiredFielderror = true;
			return;
	    }
	    
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Customer_Invoice__c invoice: (List<Customer_Invoice__c>)setCon.getSelected() ) {      
            invoiceIDs.add(invoice.ID);
        }

        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Customer Invoice','Adjustment','Customer Credit Memo'});

        //String hdrdynamicQuery = ARS.getQueryStringList(new List<String>{'Customer Credit Memo'});
        
        String objectFieldString = 'id, Name, Date_Invoiced__c, Company__c, Finalized__c, Total_Sales_Tax__c, Currency__c, transaction_type__c, '+
        						'Apply_to_Invoice__c, Invoice_Type__c,Bill_To_Customer__c,Sold_To_Customer__c, Subtotal__c';
		String subQueryFieldString = 'id, Name, Discount_Percent__c, Extended_Price__c,'+
                                ' Product__r.Item__c, Quantity_Shipped__c,  '+
                                ' Unit_Price__c, Shipment_Line__r.Sales_Order_Line__r.Sales_Order__r.id,'+
                                ' Customer_Invoice__r.Total_Sales_Tax__c, Shipment_Line__r.Sales_Order__r.Type__c, Shipment_Line__c,'+
                                'Shipment_Line__r.Sales_Order__r.Company__c, Customer_Invoice__r.Date_Invoiced__c,Customer_Invoice__r.Finalized__c, Customer_Invoice__r.Sales_Order__r.Type__c';
								//(dynamicQuery != null? ','+dynamicQuery : '')+
								//(hdrdynamicQuery != null? ','+hdrdynamicQuery : '')+
        String whereClause = 'id in :invoiceIDs'+
                            ' and Finalized__c = true' +
                            ' and transaction_date__c != null '+
                            ' and finalized_date__c != null ' +
                            ' and id not in ( Select Customer_Invoice__c from Accounting_Entry__c where Customer_Invoice__c in :invoiceIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        // TODO: put try catch for the query
        Set<String> objectFieldPaths = new Set<String>(objectFieldString.split(','));
        Set<String> subQueryFieldPaths = new Set<String>(subQueryFieldString.split(','));

        SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', TRUE);
        soql.addFields(objectFieldPaths);
        soql.setWhereClause(whereClause);

        SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'Customer_Invoice_Lines__r');
        childRel.addFields(subQueryFieldPaths);

        soql.addChildRelationship(childRel);

		objectList = Database.query (soql.getQuery());
		
        if (selecterror ) {
            return ;
        }
        
        list<string> transactionTypeList = new list<string>();
        
        for(Customer_Invoice__c ci: (list<Customer_Invoice__c>)objectList){
        		if(ci.transaction_type__c != null && ci.transaction_type__c != '')
        			transactionTypeList.add(ci.transaction_type__c);
        		else
        			transactionTypeList.add(ci.invoice_type__c);
        			
        }
        if(!ARS.isRuleDefined(new List<String>{'Customer_Invoice__c'}, transactionTypeList)){
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
        	if(objectList[i].Date_Invoiced__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Date_Invoiced_is_blank + objectList[i].Name ) );
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
    public pagereference GenerateCustomerInvoiceAccounting() {
        Map<Id,Customer_Invoice__c> invoiceMapUpd = new Map<Id,Customer_Invoice__c>();
        Map<Id,Customer_Invoice__c> invoiceMapUpdCM = new Map<Id,Customer_Invoice__c>();
        If(objectList != null && objectList.size() > 0){
        	Savepoint sp = Database.setSavepoint();
        	try{
	            	//GAS.createCustInvoiceAccounting(objectList);
	            	//CustomerInvoiceAccounting cia = new CustomerInvoiceAccounting();
	            	//cia.execute(objectList);
	            	// KNDY 2196 - Changed the approach to update the Accounted flag on source document.
	            	// FIN-758 Invoke Batch
	            	
                     //Create a stub header
                    //AccountingService.upsertAccountingEntry(objectList);   
                           
                    set<Id> sourceDocIds = new set<Id>();
                    set<Id> companyIds = new set<Id>();   
                    for(Customer_Invoice__c ci : objectList){
                        companyIds.add(ci.company__c);
                        sourceDocIds.add(ci.Id);
                    }             
                    CustomerInvoiceAccountingBatch  batch = new CustomerInvoiceAccountingBatch(companyIds);
                    batch.setSourceDocId(sourceDocIds);
                    batch.setuseSuperWhere(true);
                    string jobid= Database.ExecuteBatch(batch);  
                

                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
                    BatchInitiated=true;   
	            	
	            					
            	} catch(Exception e) {
            		Database.rollback(sp);
                	selecterror = true;
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