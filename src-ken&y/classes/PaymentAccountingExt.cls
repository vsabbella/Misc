public with sharing class PaymentAccountingExt {
    
    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; } 
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; } 
    
    public list<Payment__c> objectList {get;set;}
    set<ID> paymentIDs = new set<ID>();
    //GenerateAccountingService GAS = new GenerateAccountingService();
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    List<Accounting_Entry__c> acctEntryListCM = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
     
    public PaymentAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        
        if ( ! Schema.sObjectType.Payment__c.isCreateable() ) {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
                                                    Label.Insufficient_access_to_create_payment));
            requiredFielderror = true;
            return;
        }
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Payment__c payment: (List<Payment__c>)setCon.getSelected() ) {      
            paymentIDs.add(payment.ID);
        }

        String objectQuery =  'Select id, Name, Finalized__c, Finalized_Date__c, Currency__c, '+
                                'From_Company__c,From_Company__r.id,From_City__c, From_State__c, From_Country__c, From_Street__c, From_Zip_Code__c, '+ 
                                'To_City__c, To_Company__c, To_Company__r.id ,To_Country__c, To_State__c, To_Street__c, To_Zip_Code__c, Type__c,Transaction_Type__c, '+
                                'transaction_date__c, total_number_of_lines__c, '+       
                                '(select id, name, Amount__c, Payment__c, type__c, '+
                                'line_type__c, subtransaction_type__c, Payment__r.from_Company__r.Comp_Currency__c, Payment__r.Currency__c, Payment__r.transaction_date__c, Payment__r.to_Company__r.Comp_Currency__c '+
                                'from payment_Lines__r), (select id from Accounting_Entries__r where Status__c = \'Active\')' +
                                ' from Payment__c '+
                                ' where id in :paymentIDs'+
                                ' and Finalized__c = true' +
                                ' and transaction_date__c != null '+
                                ' and finalized_date__c != null ' ;
//                                +' and id not in ( Select Payment__c from Accounting_Entry__c where Payment__c in :paymentIDs AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
        // TODO: put try catch for the query
		list<Payment__c> includeObjectList  = Database.query (objectQuery);
		objectList = new list<Payment__c>();
		for(integer i = 0; i < includeObjectList.size(); i++){
			if(includeObjectList[i].Accounting_Entries__r.size()< 2){
				objectList.add(includeObjectList[i]);
			}
		}
        
        if (selecterror ) {
            return ;
        }
        list<string> transactionTypeList = new list<string>();
        
        for(Payment__c pmt: (list<Payment__c>)objectList){
        		if(pmt.transaction_type__c != null && pmt.transaction_type__c != '')
        			transactionTypeList.add(pmt.transaction_type__c);
        		else
        			transactionTypeList.add(pmt.type__c);
        
        }
        if(!ARS.isRuleDefined(new List<String>{'Payment__c'}, transactionTypeList)){
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
            if(objectList[i].Transaction_Date__c == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Date_is_blank + objectList[i].Name ) );
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
            if(objectList[i].from_Company__c == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.From_Company_is_blank + objectList[i].Name ) );
                requiredFielderror = true;
                selecterror = true;
                return;
            }
            if(objectList[i].To_Company__c == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.To_Company_is_blank + objectList[i].Name ) );
                requiredFielderror = true;
                selecterror = true;
                return;
            }
        }
        
    } // End of Constructor
    
    
    //Function to generate the accounting entries for the payment lines
    public pagereference GeneratePaymentAccounting() {
        Map<Id,Payment__c> paymentMapUpd = new Map<Id,Payment__c>();
        Map<Id,Payment__c> paymentMapUpdCM = new Map<Id,Payment__c>();
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{
                    set<Id> sourceDocIds = new set<Id>();
                    set<Id> companyIds = new set<Id>();   
                    for(Payment__c inv : objectList){
                        companyIds.add(inv.from_company__c);
                        companyIds.add(inv.to_company__c);
                        sourceDocIds.add(inv.Id);
                    }             
                    paymentAccountingBatch  batch = new paymentAccountingBatch(companyIds);
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
        if (Apexpages.hasMessages(ApexPages.Severity.FATAL) || Apexpages.hasMessages(ApexPages.Severity.ERROR)){
            requiredFielderror = true;
            selecterror = true;
            
        }
        return (Apexpages.hasMessages() ? null : this.setcon.cancel() ); 
       
    } 
    
}