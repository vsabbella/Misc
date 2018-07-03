/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public abstract without sharing class AccountingBatchBaseClass  implements Database.batchable<sObject>,process.Runnable2,database.stateful
{
    public boolean useSuperWhere=false;
    public string BaseQuery;
    public string whereClause;
    public string Query;
	public string BatchJobId;  
	public set<id> openPeriodIDs;
    public boolean isComplete=false;
    public set<id> SourceDocIDs;
    public set<id> OperatingCompanyIDs;
    public List<Notify.Message> messages = new List<Notify.Message>();
    public string sObjectName;
    //public AccountingService worker;
    
    public class AccountingBatchException extends Exception{}
    
    public set<Id> recordIds = new set<Id>();
    
    public Process_Job__c processJob;
    
    public AccountingBatchBaseClass(string sObjectName){
        this.sObjectName = sObjectName;
        //Type t = Type.forName(AccountingService.mAccountingWorkers.get(sObjectName));
        //worker = (AccountingService)t.newInstance();
    }
    
	//Abstract method get construct Base query
	public abstract void createBaseQuery();

	//Virtual method to construct Where clause
	public virtual void createWhereClause()
    {

    }
	public void setSuperwhereclause()
    {
        if(operatingCompanyIds!=null)
        {
            if(sObjectName == 'Invoice__c' || sObjectName == 'Payment__c'){
            
            	string sObjectLookupFromCompany = sObjectName.replace('__c', '__r.from_Company__c');
             	string sObjectLookupToCompany = sObjectName.replace('__c', '__r.to_Company__c');
    			whereClause=' where ('+ sObjectLookupFromCompany+' in :operatingCompanyIds OR ' + sObjectLookupToCompany + ' in :operatingCompanyIds)'  + 'AND '+sObjectName +' in :SourceDocIDs';
            }
            else{
            	string sObjectLookup = sObjectName.replace('__c', '__r.Company__c');
    		//if(sObjectName=='Journal_entry__c'){
    			whereClause=' where '+sObjectLookup+' in :operatingCompanyIds AND '+sObjectName +' in :SourceDocIDs';
    		}
    	//	}else{
        //		whereClause=' where Company__c in :operatingCompanyIds and ID in :SourceDocIDs';
    	//	}
            
        }
       //else if(sObjectName=='Journal_entry__c')
        else    
        {
        	whereClause=' where '+sObjectName+ ' IN :SourceDocIDs';
            
        }
        /*
        //TODO:Remove this after transitioning
        else
        {
        	whereClause=' where ' +' ID IN :SourceDocIDs';

        }*/
    }
    public void runBatch( Process_Job__c job ) { 		// Process.Runnable2 implementation 
    	
    	system.debug('job: ' + job);
    	Type t =type.forname(job.Apex_Class__c);
        AccountingBatchBaseClass batch = (AccountingBatchBaseClass)t.newInstance();
        batch.setOperatingCompIDs(new set<id>{job.Company__c});
        batch.processJob = job;
    	integer defaultBatchSize = 200;
		//if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 100 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
		//	defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		//}
		if(job.batch_size__c != null){
			if(job.batch_size__c < 1){
				defaultBatchSize = 1;
			}else if(job.batch_size__c > 2000){
				defaultBatchSize = 2000;
			}else{
				defaultBatchSize = integer.valueOf(job.Batch_Size__c);
			}
		}
		
        Database.executebatch(batch, defaultBatchSize);
    } 
	public void setuseSuperWhere(boolean val)
    {
        useSuperWhere=val;
    }
    public void setSourceDocID(set<ID> SDids)
    {
        this.SourceDocIDs=SDids;
    }
    public void setBatchJobId(string val)
    {
        BatchJobId=val;
        //worker.batchJobID=BatchJobId.substring(0, 15);

    }
    public virtual Database.QueryLocator start(Database.BatchableContext BC){ 
        MasterControlProgram.checkAlreadyRunning( this, BC );
        setBatchJobId(BC.getJobId());
        updateQueryLocator();    

        return Database.getQueryLocator(query);
    } 
    public virtual void execute(Database.BatchableContext info, List<sObject> scope)
    {
        map<id,sobject> mSobjects = new map<id,sobject>(scope);
        Savepoint sp = Database.setSavepoint();
        AccountingService worker;
        try{
        	
        	Type t = Type.forName(AccountingService.mAccountingWorkers.get(sObjectName));
        	worker = (AccountingService)t.newInstance();
        	worker.batchJobID = info.getJobId();
            worker.execute(scope);
            
        } catch(Exception e) {
            Database.rollback(sp);
            Notify.Message errorMsg = Notify.getErrorMessage(scope, e.getMessage(), e.getStackTraceString());
            messages.add(errorMsg);
            throw new AccountingBatchException(errorMsg.title + ' - ' + errorMsg.body);
        }
    }

     public virtual void finish(Database.BatchableContext info){
     	system.debug('batch base class jobId: ' + info.getJobId()); 
        		
    	//Database.executeBatch(new AccountingEntryLineDeleteBatch(info.getJobId()), 2000);
    	//Database.executeBatch(new AccountingEntryLineDeleteBatch(), 2000);
    	Database.executeBatch(new AccountingEntryVoidBatch(info.getJobId()), 200);
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
        isComplete=true;
    }   
    
    
    public void setOperatingCompIDs(set<id> compids)
    {
        operatingCompanyIds = compids;
        
    }
        
    public void updateQueryLocator()
    {
        openPeriodIDs =  new set<ID>();
        map<id,period__c> openperiodmap = new map<id,period__c> ([select id, Name from period__c where open__c = true and company__c in: operatingCompanyIds]);
        if(openperiodmap != null){
        	openPeriodIDs.addall(openperiodmap.keyset());
        }
        createBaseQuery();
        if(!useSuperWhere)
            {
            createwhereClause();
                
            }
        else
        {
            setSuperwhereclause();
        }
        query=BaseQuery +whereclause;
        system.debug('query'+query);
        
    } 
	 
}