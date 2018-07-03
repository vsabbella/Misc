public class BankTransactionGroupAccountingExt {
    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean RequiredFieldError {get; set;} { RequiredFieldError = false; }    
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; }
    
    public list<Bank_Transaction_group__c> objectList {get;set;}
    set<ID> BTGIds = new set<ID>();
    BankTransactionGroupAccounting btga = new BankTransactionGroupAccounting();
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
    
    public BankTransactionGroupAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Bank_Transaction_group__c btg: (List<Bank_Transaction_group__c>)setCon.getSelected() ) {      
            BTGIds.add(btg.ID);
        }
        
        string Fields = String.join(schemautil.getinstance().getFieldsFromFieldSetString( 'Bank_Transaction_Group__c','Bank_Transaction_Group_AE_RO'),',' );
        String Querystr = 'Select '+Fields+ ' From Bank_Transaction_group__c'
            			+ ' where ID in :BTGIds'
                        + '  and Finalized__c = true '
                        + '  and transaction_date__c != null '
                        + '  and finalized_date__c != null '
                        + '  and id not in ( Select Bank_Transaction_group__c from Accounting_Entry__c where Bank_Transaction_group__c in :BTGIds AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\')';
        objectList  = Database.Query(Querystr);
                        
                    


        if(objectList == null || objectList.size() < 1){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process ) );
          	selecterror = true;
        	return;
        }

        
    } // End of Constructor
    
    
    //Function to generate the accounting entries for the invoice lines
    public pagereference generateBankTransactionGroupAccounting() {
        
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{

                set<Id> sourceDocIds = new set<Id>();
                set<Id> companyIds = new set<Id>();
                for(Bank_Transaction_Group__c btg : objectList){
                	companyIds.add(btg.company__c);
                	sourceDocIds.add(btg.Id);
                }
                
                BankTransactionGroupAccountingBatch  batch = new BankTransactionGroupAccountingBatch(companyIds);
                batch.setSourceDocId(sourceDocIds);
                batch.setuseSuperWhere(true);
               
                
                String jobid=Database.ExecuteBatch(batch);
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
				BatchInitiated=true;
                
                
            }catch(Exception e){
                Database.rollback(sp);
                selecterror=true;
                String errorMessage = e.getMessage();
                ApexPages.addMessages(e);
                return null;
            }
        }

        if (Apexpages.hasMessages(ApexPages.Severity.FATAL) || Apexpages.hasMessages(ApexPages.Severity.ERROR)){
        	requiredFielderror = true;
        	selecterror = true;
        	
        }
        return (Apexpages.hasMessages() ? null : this.setcon.cancel() ); 
        //return setcon.cancel();
    } 
}