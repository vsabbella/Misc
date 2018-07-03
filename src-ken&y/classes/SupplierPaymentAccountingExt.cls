public with sharing class SupplierPaymentAccountingExt {

    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; } 
    public list<Supplier_Payment__c> objectList {get;set;}
    set<ID> sPaymentIDs = new set<ID>();
    //GenerateAccountingService GAS = new GenerateAccountingService();
    SupplierPaymentAccounting spa = new SupplierPaymentAccounting();
    public boolean disableGenerate {get;set;}
    
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
    
    public SupplierPaymentAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        disableGenerate = false;
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            disableGenerate = true;
            return;
        }
        
        for (Supplier_Payment__c sPayment: (List<Supplier_Payment__c>)setCon.getSelected() ) {      
            sPaymentIDs.add(sPayment.ID);
        }
        
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Supplier Payment'});
        
        /*String objectQuery = 'select ID, Name, Payment_Amount__c, Bank_Account__c, Date_Paid__c, Supplier__c, Finalized__c, Company__c, Currency__c, Payment_Method__c'+ 
                    ' FROM Supplier_Payment__c where id in :sPaymentIDs' + 
                    ' AND Finalized__c = true ' + 
                    ' AND transaction_date__c != null '+
                    ' AND finalized_date__c != null ' +
                    ' AND ID NOT IN ( Select Supplier_Payment__c from Accounting_Entry__c WHERE Supplier_Payment__c in :sPaymentIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        */
        String whereClause = 'id in :sPaymentIDs' + 
			                    ' AND Finalized__c = true ' + 
			                    ' AND transaction_date__c != null '+
			                    ' AND finalized_date__c != null ' +
			                    ' AND ID NOT IN ( Select Supplier_Payment__c from Accounting_Entry__c' + 
			                    ' WHERE Supplier_Payment__c in :sPaymentIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        
	    SOQLUtil soql = new SOQLUtil('Supplier_Payment__c');
	    soql.addFields(new Set<String>{'ID', 'Name', 'Payment_Amount__c', 'Bank_Account__c', 'Date_Paid__c', 'Supplier__c', 'Finalized__c', 'Company__c', 'Currency__c', 'Payment_Method_G__c','Transaction_Type__c'});
	    soql.setWhereClause(whereClause);
	    
        objectList = Database.query(soql.getQuery());
      
        if (selecterror ) {
            return ;
        }
        
        list<string> transactionTypeList = new list<string>();
        
        for(Supplier_Payment__c sp: (list<Supplier_Payment__c>)objectList){
        		transactionTypeList.add(sp.Transaction_Type__c);
        
        }
        transactionTypeList.add('Supplier Payment');
        if(!ARS.isRuleDefined(new List<String>{'Supplier_Payment__c'}, transactionTypeList)){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Create_Accounting_Rules));
    		requiredFielderror = true;
        	selecterror = true;
        	disableGenerate = true;
        	return;
        }
        if(objectList == null || objectList.size() < 1){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process ) );
        	requiredFielderror = true;
          	selecterror = true;
          	disableGenerate = true;
        	return;
        }
        for(integer i = 0; i < objectList.size(); i++){
        	if(objectList[i].Date_Paid__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Date_Paid_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	disableGenerate = true;
            	return;
        	}
        	if(objectList[i].Currency__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Currency_is_blank +objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	disableGenerate = true;
            	return;
        	}
        	if(objectList[i].Company__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Company_is_blank +objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	disableGenerate = true;
            	return;
        	}
        }
        
    } // End of Constructor
    
    
    //Function to generate the accounting entries for the invoice lines
    public pagereference GenerateSupplierPaymentAccounting() {
        Map<Id,Supplier_Payment__c> sPaymentMapUpd = new Map<Id,Supplier_Payment__c>();
        
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                
				//AccountingService.upsertAccountingEntry(objectList);          
                set<Id> sourceDocIds = new set<Id>();
                set<Id> companyIds = new set<Id>();
                for(Supplier_Payment__c spay : objectList){
                    companyIds.add(spay.company__c);
                    sourceDocIds.add(spay.Id);
                }   
                                    
                SupplierPaymentAccountingBatch  batch = new SupplierPaymentAccountingBatch(companyIds);
                batch.setSourceDocId(sourceDocIds);
                batch.setuseSuperWhere(true);
                string jobid= Database.ExecuteBatch(batch);
                
                disableGenerate = true;
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
                			
            }catch(Exception e){
                Database.rollback(sp);
                String errorMessage = e.getMessage();
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
        //return setcon.cancel();
    } 
    
}