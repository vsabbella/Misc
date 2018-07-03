public with sharing class ClaimInspect implements Database.batchable<sObject>, Process.Runnable, Database.Stateful {
	
	public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    private List<Process.ProcessFlow> flows = Process.returnObjectFlows('Claim__c');
    
    public void runBatch( id companyid ) { 		// Process.Runnable implementation 
    	Database.executebatch( new ClaimInspect(new set<id>{companyid} ), 10);
    }
   	
   	public ClaimInspect(){
   		updateQuery();
   	} 
   	
    public ClaimInspect(set<Id> companyIds){
    	this.operatingCompanyIds = companyIds;
    	updateQuery();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(query);
    }
    
	public void execute(Database.BatchableContext info, List<sObject> scope){
		flows.sort();
		ProcessService ps = new ProcessService();
		for(Process.ProcessFlow flow : flows){
			if(flow.proc.Bulk__c){
				ps.init(flow, scope);
			}	
		}
	}
	
	public void finish(Database.BatchableContext info){    	
    		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
    }
    
    private void updateQuery(){
    	query = 'SELECT ' + SchemaUtil.getInstance().getFieldsForQuery('Claim__c');
		query += ' FROM Claim__c WHERE Ready__c = true ';
		if(operatingCompanyIds != null && operatingCompanyIds.size() > 0){
			query += ' AND company__c IN :operatingCompanyIds';
		}
		system.debug('query: ' + query);
    }
}