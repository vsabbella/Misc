public class BankTransactionAccountingExt {
    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean RequiredFieldError {get; set;} { RequiredFieldError = false; }    
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; }
    
    public list<Bank_Transaction__c> objectList {get;set;}
    set<ID> BTIds = new set<ID>();
    BankTransactionGroupAccounting btga = new BankTransactionGroupAccounting();
    List<Accounting_Entry__c> acctEntryList = new List<Accounting_Entry__c>();
    AccountingRuleService ARS = new AccountingRuleService();
    
    public BankTransactionAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        
        if (setCon.getSelected().size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_records_selected) );
            selecterror = true;
            return;
        }
        
        for (Bank_Transaction__c bt: (List<Bank_Transaction__c>)setCon.getSelected() ) {      
            BTIds.add(bt.id);
        }
        
        set<string> BTFields = new set<string>(schemautil.getinstance().getFieldsFromFieldSetString('Bank_Transaction__c','Bank_Transaction_AE_RO'));
        BTFields.add('Bank_Transaction_Group__c');
        string Fields = String.join(new list<string>(BTFields),',' );
        String Querystr = 'Select '+Fields+ ' From Bank_Transaction__c'
            			+ ' where ID in :BTIds'
                        + '  and Finalized__c = true '
                        + '  and Bank_Transaction_Group__r.transaction_date__c != null '
                        + '  and Bank_Transaction_Group__r.finalized_date__c != null '
                        + '  and id not in ( Select Bank_Transaction__c from Accounting_Entry_Line__c where Bank_Transaction__c in :BTIds AND Related_Accounting_Entry_Line__c  = null AND has_exceptions__c = false AND status__c = \'Active\')';
        objectList  = Database.Query(Querystr);
                        
                    


        if(objectList == null || objectList.size() < 1){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_eligible_records_to_process ) );
          	selecterror = true;
        	return;
        }

        
    } // End of Constructor
    
    
    //Function to generate the accounting entries for the invoice lines
    public pagereference generateBankTransactionAccounting() {
        
        If(objectList != null && objectList.size() > 0){
            Savepoint sp = Database.setSavepoint();
            try{

                set<Id> sourceDocIds = new set<Id>();
                set<Id> companyIds = new set<Id>();
                for(Bank_Transaction__c bt : objectList){
                	companyIds.add(bt.company__c);
                	sourceDocIds.add(bt.Bank_Transaction_Group__c);
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