/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class AccountingEntryLineDeleteBatch implements Database.Batchable<sObject>, Process.Runnable2,Database.Stateful {
	
	private set<Id> deleteAEIds;
	private Id batchJobId;
	public Integer BatchErrorCount=0;
    public List<Notify.Message> messages = new List<Notify.Message>();
	public 
	 map<string,set<id>> mErrMsgToRecId = new map<string,set<id>>(); 	
	
	public  void runBatch( Process_Job__c job ) { 		// Process.Runnable2 implementation 
    	
    	system.debug('job: ' + job);
        AccountingEntryLineDeleteBatch batch = new AccountingEntryLineDeleteBatch();
    	integer defaultBatchSize = 2000;
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
	
	public AccountingEntryLineDeleteBatch(set<Id> deleteAEIds){
		this.deleteAEIds = deleteAEIds;
	}
	
	public AccountingEntryLineDeleteBatch(Id batchJobId){
		this.batchJobId = batchJobId;
	}
	
	public AccountingEntryLineDeleteBatch(){
		//Just get rid of bad data...
	}
	
	public Database.QueryLocator start(Database.BatchableContext IC){    
		MasterControlProgram.checkAlreadyRunning( this, IC );
        string query;
        if(deleteAEIds != null){
            query = 'SELECT Id FROM Accounting_Entry_Line__c WHERE Accounting_Entry__c IN :deleteAEIds';
        }else if(batchJobId != null){
        	query = 'SELECT Id FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.BatchJobId__c = :batchJobId AND Accounting_Entry__r.Status__c = \'Draft\'';
        }else{
            //query = 'SELECT Id FROM Accounting_Entry_Line__c WHERE Id = null';
             //KNDY-10268 - deprecating bank file and bank file line objects so removed BankAccountingBatch class //'BankFileAccountingBatch', 
            set<string> accountingJobNames = new set<string>{'JournalEntryAccountingBatch', 'CustomerInvoiceAccountingBatch', 'CustomerReceiptAccountingBatch', 
            													'POReceiptAccountingBatch', 'SupplierInvoiceAccountingBatch', 'SupplierPaymentAccountingBatch', 
            													'InventoryChangeAccountingBatch', 'FixedAssetDepreciationAccountingBatch', 'FixedAssetAdjustmentAccountingBatch',
            													'AccountingEntryVoidBatch'};
            set<string> runningJobIds = new set<string>();

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('AsyncApexJob', false); //enforceFLS=false, running in system mode
			soql.addFields(new set<string>{
				'Id'
			});
			soql.setWhereClause('ApexClass.Name IN :accountingJobNames AND JobType = \'BatchApex\' AND Status IN (\'Holding\', \'Queued\', \'Preparing\', \'Processing\')');
			List<AsyncApexJob> runningJobs = Database.query(soql.getQuery());

            for(AsyncApexJob job : runningJobs){
            	runningJobIds.add(job.Id);
            }
            datetime past24Hr= system.now().addhours(-24);
            system.debug('runningJobIds: ' + runningJobIds);
            //query = 'SELECT Id FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' AND Accounting_Entry__r.BatchJobId__c NOT IN :runningJobIds';
            query = 'SELECT Id FROM Accounting_Entry_Line__c WHERE Accounting_Entry__r.Status__c = \'Draft\' '
                    +' AND Accounting_Entry__r.BatchJobId__c NOT IN :runningJobIds'
                    +' AND Accounting_Entry__r.createddate < :past24Hr';
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<sObject> scope){
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
		soql.addFields(new set<string>{
			'Id','total_lines__c'
		});
		soql.setWhereClause('Id IN (SELECT Accounting_Entry__c FROM Accounting_Entry_Line__c WHERE Id IN :scope)');
		List<Accounting_Entry__c> aes = Database.query(soql.getQuery());

        list<Database.DeleteResult> drList = DML.deleteAsSystem(scope, false);

        populateDBErrorsToChatter(drList);
        List<Accounting_Entry__c> emptyAEs = new List<Accounting_Entry__c>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		soql = new SOQLUtil('Accounting_Entry__c', false); //enforceFLS=false, running in system mode
		soql.addFields(new set<string>{
			'Id','total_lines__c'
		});
		soql.setWhereClause('Id IN :aes');
		aes = Database.query(soql.getQuery());

        for(Accounting_Entry__c ae : aes){
            if(ae.total_lines__c == 0 || ae.total_lines__c == null){
                emptyAEs.add(ae);
            }
        }
        
        if(emptyAEs.size() > 0){
            list<Database.DeleteResult> drListAEs = DML.deleteAsSystem(emptyAEs, false);
            populateDBErrorsToChatter(drListAEs);
        }

    }
    
    public void populateDBErrorsToChatter(list<Database.DeleteResult> drList)
    {
    	system.debug('drlist'+drList);
    	Boolean batchHasError=false;
		for(Database.DeleteResult dr : drList) {
		    if (dr.isSuccess()) {
		        // Operation was successful, so get the ID of the record that was processed
		        System.debug('Successfully deleted AE with ID: ' + dr.getId());
		    }
		    else {
		        // Operation failed, so get all errors  
		        //TODO:Check with SK if we need to limit message list addition to avoid heap size issue in case all records fail.  
                batchHasError=true;
		        for(Database.Error err:dr.getErrors())
	            {
		        	if(mErrMsgToRecId.containsKey(err.getMessage()))
		        	{
		        		mErrMsgToRecId.get(err.getMessage()).add(dr.getId());
		        	}
		        	else
		        	{
		        		mErrMsgToRecId.put(err.getMessage(),new set<id>{dr.getId()});
		        		
		        	}
	            }			         
		                   
		    }       
        
        }  
        if(BatchHasError) 
        {
        	BatchErrorCount=BatchErrorCount+1;
        }

         	
    }

    
    public void finish(Database.BatchableContext info)
    {
    	 for(string s:mErrMsgToRecId.keyset())
        {
          string errRecs = string.join(new list<id>(mErrMsgToRecId.get(s)), ',');
          messages.add(new Notify.Message('The  records '+ errRecs,'  have following errors '+s));
        	
        }
    	system.debug('messages'+messages);
    	//KNDY-7361 Implement batch email template and chatter feed .
    	BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish( BatchErrorCount,null, messages, info);        
		MasterControlProgram.finishedBatch( this ); 
                  
    }
}