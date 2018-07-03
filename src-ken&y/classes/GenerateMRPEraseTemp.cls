/** 
 * @description Assume that the Item level process is completed, now we 
 * begin the actuall planning process by clearing out all the temp records 
 * that hold supply and demand, we will recreate these in the second step.
 * This simple step deletes all MRPTemp records for the company passed in
 * 
 *  MRP planning follows these steps
 * erase all MRP temp records ( GenerateMRPEraseTemp )
 * GenerateSafetyDemand
 * GenerateMRPTempData
 * GenerateMRPPlanData (Max_level)
 * GenerateMRPPlanData (Max_level-1)
 * [...]
 * GenerateMRPPlanData ( 0 )
 * 
 */
public with sharing class GenerateMRPEraseTemp implements Database.batchable<sObject>,Database.Stateful {
            
    public String query;
    public ID mrpRunID;
    List<MRP_Run__c> mrprun = new List<MRP_Run__c>();
    public String errMsg;
    public  Id companyId { get;set;}
    public  ID facilityID { get;set;}
    MRPSettingsService mrpSetting = new MRPSettingsService();
    String cfID;
   
    public GenerateMRPEraseTemp(ID mrpRID) {
        this.mrpRunID = mrpRID;
        
        errMsg = '';

//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
SOQLUtil soql = new SOQLUtil('MRP_Run__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
    	'ID','Name','Company__c','Facility__c'
});
soql.setWhereClause('ID =: mrpRunId');
mrpRun = Database.query(soql.getQuery());

    facilityID = mrpRun[0].Facility__c;
    companyId = mrpRun[0].Company__c;
    if(facilityID != null ){
       cfID = companyID +'-' +facilityID;   
    }else {
       cfID = companyID; 
    }

        /* We are now disallowing multiple MRP runs on company or facility. Say we have a MRP job running on Facility, and there is a erase request, 
        the user will have to wait till the running job has been completed, before the erase call is invoked...
        */
    if ( mrpSetting.mrp_running(cfID) ) {
      throw new GenerateMRP.GenerateMRPException(Label.MRP_is_currently_running);  
    } 
        
        query='Select Id from MRP__c where MRP_Run__c=: mrpRunId';
         //it sets the Flag.
     mrpSetting.mrp_start(cfID);
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        
        system.assert( this.mrpRunId != null, 'GenerateMRPEraseTemp expected MRP_Run ID set');
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<MRP__c> tempList){
        
        execute( tempList );
    }
   
    public void execute( List<Sobject> tempList) {       
        // KNDY-6184 allow non admin users to run the MRP
        // user must have Del perm on the MRP object at least
        try {
            new DML.WithoutSharing().sobjectDel( tempList );
        // KNDY-7315 empty the deleted records from the recycle bin
            Database.emptyRecycleBin(tempList);
        }
        catch (Exception e) {
            errMsg = errMsg +e.getMessage()+','+e.getStackTraceString();
            throw e;
        }
    }
    
    public void finish(Database.BatchableContext info) {
        
        String msg;
        mrpSetting.mrp_complete ( cfID ) ;
        if (errmsg.length() > 0) {
            mrpRun[0].Completion_Status__c = 'Failure';
            DML.updateAsUser(mrpRun);
            
            msg = 'MRPEraseTemp for run: ' +mrpRun[0].Name +' Failed with error: ' +errMsg;
            Notify.sendEmailBatchFinish( null, msg, info);        
        }
        else {
            // PTM-441 
            mrpRun[0].Completion_Status__c = 'Erased';
            DML.updateAsUser(mrpRun);
        
            msg = 'MRP Run: ' +mrpRun[0].Name + ' Erase Completed';
            Notify.sendEmailBatchFinish( null, msg, info);        
        }
    }
}