/*
 * Class to update DTPForecast date on all Open CI
 * based on last 3 month DTP Average for the customer,payment term 
 */
public with sharing class DTPBatch implements Database.Batchable<sObject>, 
													Database.Stateful,
													Process.Runnable2 {
															
    public string selectClause = '';
    public string whereClause ='';
    public string query='';
    public Id companyId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    
    public DaysToPayService DTPService;
    public list<customer_invoice__c> UpdateCIList;
    public set<string> QueryFields = new set<string>{'id','name','Bill_To_Customer__c' ,'Payment_Term__c','Due_Date__c','Date_Invoiced__c','Date_Time_Paid__c ','Period_Paid__c', 'DTPForecastDate__c'};
    public string customFilter='';
    public DTPBatch(){}
    public DTPBatch(id compid)
    {
        this.companyId=compid;
    }
    public Database.QueryLocator start(Database.BatchableContext info)
    {
        DTPService = new DaysToPayService();
        CustomFilter='';
        CustomFilter=DTPService.getDTPFilterFromCustomSetting();        
        updateQueryLocator();
        return Database.getQueryLocator(query);
    }
    
    
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
        DTPBatch Obj=new DTPBatch(  job.Company__c );
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Id jobId=Database.executebatch(obj, defaultBatchSize);
    }

    public void execute(Database.BatchableContext info, List<sObject> scope)
    {
        DTPService.setCompany(companyId);
        Savepoint sp = Database.setSavepoint();        
        try
        {
            UpdateCIList =DTPService.computeForecastDate(scope);          
            DML.updateAsSystem(UpdateCIList);            
        }catch(Exception ex){
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ex.getStackTraceString()));
        }

    }
    public void finish(Database.BatchableContext info)
    {
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
    }
    
    void updateQueryLocator()
    {

    	selectClause = 'select  '+ string.join(new List<string>(QueryFields), ',')+' from customer_invoice__c ';
        whereclause = ' where status__c = \'Open\' and finalized__c=true ' +customfilter;//and DTPForecastDate__c=null?
        query= selectclause+whereclause;
        system.debug(query);
        
    }    
}