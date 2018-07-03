public with sharing class POReceiptAccountingExt {
    
public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; } 
    public list<Receiving_Document__c> objectList {get;set;}
    set<ID> receiptIDs = new set<ID>();
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; } 
    
    
    //GenerateAccountingService GAS = new GenerateAccountingService();     
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();

    public POReceiptAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        try{
            init();
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, MessageUtil.toFriendlyErrorMessage(ex.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + ex.getMessage() + ' ' + ex.getStackTraceString());
        }
        
    } // End of Constructor
    
    public void init(){
        if ( ! Schema.sObjectType.Accounting_Entry__c.isCreateable() ) {
		      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                               	Label.Insufficient_access_to_create_Accounting_Entries));
			selecterror = true;
			return;
	    }
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
            											Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Receiving_Document__c shipment: (List<Receiving_Document__c>)setCon.getSelected() ) {      
            receiptIDs.add(shipment.ID);
        }
        
        //String dynamicQuery = ARS.getQueryStringList(new List<String>{'Purchase Receipt'});
        
        /*String objectQuery = 'Select id, Name, Date_Received__c, Company__c, Finalized__c, Currency__c,'+
        					   '(Select id, Name, Unit_Price__c, Item__c, ' +
                               'Extended_Cost__c,Purchase_Order__c, Purchase_Order_Line__c, Purchase_Order_Line__r.Company__c,' +
                               'Quantity_Received__c, Quantity_Declared__c,' +
                               'Receiving_Document__c, Status__c, Company__c '+
                            //    (dynamicQuery != null? ','+dynamicQuery : '')+
                               ' from Receipt_Lines__r)'+
                               ' from Receiving_Document__c'+
                               ' where id in :receiptIds '+ 
                               ' and Finalized__c = true' + 
                               ' and Status__c != \'Void\'' +
                               ' and transaction_date__c != null '+
                               ' and finalized_date__c != null ' +
                               ' and id not in ( Select Receiving_Document__c from Accounting_Entry__c where Receiving_Document__c in :receiptIds AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';*/
		
		String whereClause = ' id in :receiptIds '+ 
                             ' and Finalized__c = true' + 
                             ' and Status__c != \'Void\'' +
                             ' and transaction_date__c != null '+
                             ' and finalized_date__c != null ' +
                             ' and id not in ( Select Receiving_Document__c from Accounting_Entry__c where Receiving_Document__c in :receiptIds AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        
	    SOQLUtil soql = new SOQLUtil('Receiving_Document__c');
	    soql.addFields(new Set<String>{'id', 'Name', 'Date_Received__c', 'Company__c', 'Finalized__c', 'Currency__c','type__c','transaction_type__c'});
	    soql.setWhereClause(whereClause);
	    
	    SOQLUtil.ChildRelationship receiptLines = new SOQLUtil.ChildRelationship(soql, 'Receipt_Lines__r');
	    receiptLines.addFields(new Set<String>{'id', 'Name', 'Unit_Price__c', 'Item__c', 'Extended_Cost__c', 'Purchase_Order__c', 'Purchase_Order_Line__c', 
	    								'Purchase_Order_Line__r.Company__c', 'Quantity_Received__c', 'Quantity_Declared__c', 'Receiving_Document__c', 'Status__c', 'Company__c'});
	    soql.addChildRelationship(receiptLines);
	    
	    objectList = Database.query(soql.getQuery());

        if (selecterror ) {
            return ;
        }
	     //FIN-566 fix ASN Accounting
        list<string> transactionTypeList = new list<string>();
        
        for(Receiving_Document__c rd: (list<Receiving_Document__c>)objectList){
        		if(rd.transaction_type__c != null && rd.transaction_type__c != '')
        			transactionTypeList.add(rd.transaction_type__c);
        		else
        			transactionTypeList.add(rd.type__c);
        
        }
        if(!ARS.isRuleDefined(new List<String>{'Receiving_Document__c'}, transactionTypeList)){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Create_Accounting_Rules));
    		requiredFielderror = true;
        	selecterror = true;
        	return;
        }
        if(objectList == null || objectList.size() < 1){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process) );
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
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Currency_is_blank +objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        	if(objectList[i].Company__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Company_is_blank +objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	return;
        	}
        }
    }
    
    //Function to generate the accounting entries for the shipment lines
    public pagereference GeneratePOReceiptAccounting() {
        Map<Id,Receiving_Document__c> receiptMapUpd = new Map<Id,Receiving_Document__c>();
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                //GAS.createPurchaseReceiptAccounting(objectList); 
                //ReceivingDocumentAccounting rda = new ReceivingDocumentAccounting();
        		//rda.execute(objectList);	
        		//AccountingService.upsertAccountingEntry(objectList);          
                set<Id> sourceDocIds = new set<Id>();
                set<Id> companyIds = new set<Id>();   
                for(Receiving_Document__c rd : objectList){
                    companyIds.add(rd.company__c);
                    sourceDocIds.add(rd.Id);
                }             
                POReceiptAccountingBatch  batch = new POReceiptAccountingBatch(companyIds);
                batch.setSourceDocId(sourceDocIds);
                batch.setuseSuperWhere(true);
                string jobid= Database.ExecuteBatch(batch);  
        		
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
                BatchInitiated=true;   
            }catch(Exception e){
                Database.rollback(sp);
                String errorMessage = MessageUtil.toFriendlyErrorMessage(e.getMessage());
                ApexPages.addMessages(e);
                system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
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