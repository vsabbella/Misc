public with sharing class PurchaseOrderAccountingExt {
//DEPRECATED CLASS FIN-1046    
/*    public ApexPages.StandardSetController setcon{get; set;}
    public Boolean selecterror {get; set;} { selecterror = false; } 
    public Boolean requiredFielderror {get; set;} { requiredFielderror = false; } 
    public list<Purchase_Order__c> objectList {get;set;}
    set<ID> purchaseOrderIds = new set<ID>();
    AccountingRuleService ARS = new AccountingRuleService();
    public boolean disableGenerate {get;set;}
     
    public PurchaseOrderAccountingExt(ApexPages.StandardSetController controller) {     
        
        setcon = controller;
        disableGenerate = false;
        
        if ( ! Schema.sObjectType.Purchase_Order__c.isCreateable() ) {
		      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,
	                                               	Label.Insufficient_access_to_create_Purchase_Order));
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
        
        for (Purchase_Order__c po : (List<Purchase_Order__c>)setCon.getSelected() ) {      
            purchaseOrderIds.add(po.ID);
        }
        
        set<string> purchaseOrderFields = new set<string>{'id', 'name', 'company__c', 'finalized__c', 'finalized_date__c', 'transaction_currency__c', 'transaction_date__c', 'type__c', 'Purchase_Order_Value__c'};
        set<string> purchaseOrderLineFields = new set<string>{ 'id', 'name', 'subtransaction_type__c', 'line_type__c', 'line_value__c'};
        
        string purchaseOrderQuery = 'SELECT ' + string.join(new List<string>(purchaseOrderFields),', ');
		purchaseOrderQuery += ' FROM Purchase_Order__c '
							+ 'WHERE id in :purchaseOrderIds '
                            + 'AND Finalized__c = true '
                            + 'AND Company__c != null '
                            + 'AND Transaction_Date__c != null '
                            + 'AND Transaction_Currency__c != null '
                            + 'AND Id NOT IN (SELECT Purchase_Order__c FROM Accounting_Entry__c WHERE Purchase_Order__c in :purchaseOrderIds AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c = \'Active\') ';
                            
        objectList = Database.query(purchaseOrderQuery);    
        
        if(!ARS.objectHasRules('Purchase_Order__c')){
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.No_Accounting_Rules_defined_for_Purchase_Orders));
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
        	if(objectList[i].Transaction_Date__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Date_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	disableGenerate = true;
            	return;
        	}
        	if(objectList[i].Transaction_Currency__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Transaction_Currency_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	disableGenerate = true;
            	return;
        	}
        	if(objectList[i].Company__c == null){
        		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.Company_is_blank + objectList[i].Name ) );
        		requiredFielderror = true;
            	selecterror = true;
            	disableGenerate = true;
            	return;
        	}
        }
        
    } // End of Constructor
    
    
    //Function to generate the accounting entries for the invoice lines
    public pagereference GeneratePurchaseOrderAccounting() {
        Map<Id,Purchase_Order__c> invoiceMapUpd = new Map<Id,Purchase_Order__c>();
        Map<Id,Purchase_Order__c> invoiceMapUpdCM = new Map<Id,Purchase_Order__c>();
        If(objectList != null && objectList.size() > 0){
        	Savepoint sp = Database.setSavepoint();
        	try{
	            	//AccountingService.upsertAccountingEntry(objectList);          
	                set<Id> sourceDocIds = new set<Id>();
	                set<Id> companyIds = new set<Id>();
	                for(Purchase_Order__c po : objectList){
	                    companyIds.add(po.company__c);
	                    sourceDocIds.add(po.Id);
	                }   
	                                    
	                PurchaseOrderAccountingBatch  batch = new PurchaseOrderAccountingBatch(companyIds);
	                batch.setSourceDocId(sourceDocIds);
	                batch.setuseSuperWhere(true);
	                string jobid= Database.ExecuteBatch(batch);
	                disableGenerate = true;
	                
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
	            	
            	} catch(Exception e) {
            		system.debug('EXCEPTION: ' + e.getStackTraceString());
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
	
*/}