public with sharing class EraseAllMRPRuns implements Database.batchable<sObject>,Database.Stateful, Process.Runnable2 {
    
    public ID CompanyID { get;set;}
    public string query;
    public String errMsg;
    public List<MRP_Run__c> mrprun = new List<MRP_Run__c>();
    public Set<ID> mrIDs = new Set<ID>();
    public Boolean recBin;
    
   
    MRPSettingsService settings = new MRPSettingsService();
    
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
    
        EraseAllMRPRuns obj = new EraseAllMRPRuns(job.Company__c);
        
        integer defaultBatchSize = 2000;
        if ( job.Batch_Size__c != null && integer.valueOf(job.Batch_Size__c) <= 2000 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
            defaultBatchSize = integer.valueOf(job.Batch_Size__c);
        }
        if (defaultBatchSize == 1999) obj.recBin = false;
        else obj.recBin = true;
        Database.executebatch(obj, defaultBatchSize);
    }
    
    public EraseAllMRPRuns() {}
    
    public EraseAllMRPRuns(ID cid) {
        
        CompanyID = cid;
        
        
        if ( !settings.mrp_running(CompanyID) ) {
            
            
        // PTM-704 redid the query locator
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('MRP_Run__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID'
		});
		soql.setWhereClause('Company__c =: CompanyID and (Completion_Status__c = \'Complete\' or Completion_Status__c = \'Failure\')');
		mrprun = Database.query(soql.getQuery());

        for (MRP_Run__c mr : mrprun) mrIDs.add(mr.ID);
            
        query ='select ID '+
               'from MRP__c '+
               'where MRP_Run__c in: mrIDs';
                   
            settings.mrp_start(CompanyID);
        } else {
            
            /* We are now disallowing multiple MRP runs on company or facility. Say we have a MRP job running on Facility, and there is a erase request, 
            the user will have to wait till the running job has been completed, before the erase call is invoked...
            */
            
            throw new GenerateMRP.GenerateMRPException(Label.MRP_is_currently_running);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        system.assert(CompanyID != null, 'EraseAllMRPRuns expected Company ID set');
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<MRP__c> tempList){
        
        execute( tempList );
    }
   
    public void execute( List<MRP__c> tempList) {
        
        errMsg = null;
            
        try {
            for (MRP_Run__c mr : mrprun) mr.Completion_Status__c = 'Erasing';
            DML.updateAsUser(mrprun);
// KNDY-6184 allow non admin users to run the MRP
// user must have Del perm on the MRP object at least
            new DML.WithoutSharing().sobjectDel(tempList);
// KNDY-7315 empty the deleted records from the recycle bin
            if (recBin) Database.emptyRecycleBin(tempList);
        }
        catch (Exception e) {
            errMsg = errMsg +e.getMessage()+','+e.getStackTraceString();
            throw e;
        }
    }
    
    public void finish(Database.BatchableContext info) {
        String msg, status;
        settings.mrp_complete ( CompanyID ) ;
        if (errMsg != null) {
            status = 'Failure';
            
            msg = 'EraseAllMRPRuns for run Failed with error: ' +errMsg;
            Notify.sendEmailBatchFinish( null, msg, info);        
        }
        else {
            status = 'Erased';
        
            msg = 'EraseAllMRPRuns Completed';
            Notify.sendEmailBatchFinish( null, msg, info);        
        }
        
        for (MRP_Run__c mr : mrprun) mr.Completion_Status__c = status;
        DML.updateAsUser(mrpRun);
        MasterControlProgram.finishedBatch( this );
    }
}