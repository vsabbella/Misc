public with sharing class EraseMRP_RunExt {

    public Boolean have_jobid {get; set;}
    ApexPages.StandardController con;
    ID mrpRunID;
    List<MRP_Run__c> mrprun = new List<MRP_Run__c>();

    public EraseMRP_RunExt(ApexPages.StandardController controller) {
        
        con = controller;
        MRP_Run__c mrpRn= (MRP_Run__c)con.getRecord();
        mrpRunID = mrpRn.ID;
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('MRP_Run__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'ID','Name','Completion_Status__c'
		});
		soql.setWhereClause('ID =: mrpRunId');
		mrpRun = Database.query(soql.getQuery());

        // PTM-441
        if (mrpRun[0].Completion_Status__c != 'Complete' && mrpRun[0].Completion_Status__c != 'Failure') {
            have_jobid = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, Label.MRP_Run_Completion_Status_Error_Message));
        	return;
        }
        
        have_jobid = false;
    }
    
    public pagereference eraseMrpRun() {
        // PTM-441 
        mrpRun[0].Completion_Status__c = 'Erasing';
        DML.updateAsUser(mrpRun);
        GenerateMRPEraseTemp obj = new GenerateMRPEraseTemp(mrpRunID);
        Database.executeBatch( obj, 2000); 
        
        have_jobid = true;
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,Label.BatchEmail);        
        ApexPages.addMessage(myMsg);
        return null;
    }
}