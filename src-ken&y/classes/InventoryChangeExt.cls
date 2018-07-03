/**
 * controller for InventoryChangeAcctEntryGen.page
 */ 
public with sharing class InventoryChangeExt {
  private apexpages.StandardSetController setCon;
    public Boolean selecterror {get; set;}
    public Boolean workdone {get; set;} 
	public Boolean BatchInitiated {get; set;} { BatchInitiated = false; } 
	
	public List<Inventory_Change__c> finalized { get; set; } 
	
	public Pagereference gsave() {

        //GenerateAccountingService GAS = new GenerateAccountingService();
        InventoryChangeAccounting ica = new InventoryChangeAccounting();
		// KNDY 2196 - Changed the approach to update the Accounted flag on source document.
		try { 
			//GAS.createInventoryAccounting( finalized );
			//ica.execute(finalized);
			//AccountingService.upsertAccountingEntry(finalized);          
            set<Id> sourceDocIds = new set<Id>();
            set<Id> companyIds = new set<Id>();   
            for(Inventory_Change__c ic : finalized){
                companyIds.add(ic.company__c);
                sourceDocIds.add(ic.Id);
            }             
            InventoryChangeAccountingBatch  batch = new InventoryChangeAccountingBatch(companyIds);
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
		// TODO if we use a field set, we need to have all those fields here...
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Inventory_Change__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','type__c','Finalized__c','name','company__c','createdDate','count_quantity__c','computer_Quantity__c'
		});
        set<id> mKeyset =   mapp.keySet();      
        soql.setWhereClause('Finalized__c = true and id in :mKeyset and id not in (Select Inventory_Change__c from Accounting_Entry__c where Inventory_Change__c in :mKeyset AND related_accounting_entry__c = null AND has_exceptions__c = false AND status__c=\'Active\')');
		finalized = Database.query(soql.getQuery());
         									
        if (finalized.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL,
            	Label.No_Finalized_records_selected_or_all_records_have_been_accounted) );
            selecterror = true;
             
            return;
        }    
	}
	
	public InventoryChangeExt(apexpages.standardSetController controller){  
		setCon = controller;   
		selecterror = workdone = false;
	}
 
 

}