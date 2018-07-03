public with sharing class WorkOrderAcctEntryGenExt {
/*
  private apexpages.StandardSetController setCon;
    public Boolean selecterror {get; set;}
    public Boolean workdone {get; set;} 
    public Boolean BatchInitiated {get; set;} { BatchInitiated = false; } 
    
    public List<Work_Order__c> finalized { get; set; } 
    
    public Pagereference gsave() {

        //GenerateAccountingService GAS = new GenerateAccountingService();
        WorkOrderAccounting woa = new WorkOrderAccounting();
   
        try { 
	
	        //GAS.createWorkOrderAccounting( finalized );
	        // woa.execute(finalized);
	        //AccountingService.upsertAccountingEntry(finalized);          
            set<Id> sourceDocIds = new set<Id>();
            set<Id> companyIds = new set<Id>();   
            for(Work_Order__c wo : finalized){
                companyIds.add(wo.company__c);
                sourceDocIds.add(wo.Id);
            }             
            WorkOrderAccountingBatch  batch = new WorkOrderAccountingBatch(companyIds);
            batch.setSourceDocId(sourceDocIds);
            batch.setuseSuperWhere(true);
            string jobid= Database.ExecuteBatch(batch);  

            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Batch Job '+ jobid+ ' has been initiated.' ) );
            BatchInitiated=true;   
	            	
		    
        } catch( Exception ex) { 
            Apexpages.addMessages(ex); 
            return null; 
        } 
        
        Apexpages.addMessage(new Apexpages.Message( Apexpages.Severity.INFO, Label.Accounting_Entries_generated ) );
        workdone= true;
        return null; 
    }
    
    public void lines() {
        map<id,Sobject> mapp = new map <id,Sobject>(setCon.getSelected());
        finalized = new List<Work_Order__c>();
        // TODO if we use a field set, we need to have all those fields here...
        
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Work_Order__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','Finalized__c','name','company__c','createdDate'
		});
		soql.setWhereClause('Finalized__c = true and id in :mapp.keySet() and id not in (Select Work_Order__c from Accounting_Entry__c where Work_Order__c in :mapp.keySet() AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c=\'Active\') ');
		
		SOQLUtil.ChildRelationship childRel = new SOQLUtil.ChildRelationship(soql, 'accounting_entries__r');
		childRel.addFields(new set<string>{
			'id','Name'
		});
		childRel.setWhereClause('void__c = false');
		soql.addChildRelationship(childRel);
		
		List<Work_Order__c> wos = Database.query(soql.getQuery());
                                            
        //KNDY-1600 - limit selected size to 50 to avoid 200K script limit, will revisit to consider @future or batch processing for large volumes delivered to this standardsetcontroller
        integer counter = 0;                                   
        for(integer i=0; i<wos.size(); i++){
			//KNDY-3369 
			if(counter < 50 && wos[i].finalized__c && (wos[i].accounting_entries__r.size() == 0 || wos[i].accounting_entries__r != null)){
				finalized.add(wos[i]);
				counter++;
			}else if(counter >= 50){
				Apexpages.addMessage(new Apexpages.Message( Apexpages.Severity.WARNING, Label.Process_50_records_at_a_time ) );
        		break;	
			}
        }
        
        if (finalized.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
                Label.No_Finalized_records_selected_or_all_records_have_been_accounted) );
            selecterror = true;
        }    
    }
    
    public WorkOrderAcctEntryGenExt ( apexpages.standardSetController controller){  
        setCon = controller;   
        selecterror = workdone = false;        
        lines();
    }
 */
}