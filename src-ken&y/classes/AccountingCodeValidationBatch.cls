/*
* without sharing is intentional.  accounting needs to be run in system mode.
*/
public without sharing class AccountingCodeValidationBatch implements Database.batchable<sObject>, Process.Runnable2, Database.Stateful {
    
    public string query;
    public set<Id> operatingCompanyIds = new set<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    AccountingCodeService ACS = new AccountingCodeService();
	SegmentService SS = new SegmentService();
	
    public void runBatch( Process_Job__c job ) {     // Process.Runnable2 implementation 
		AccountingCodeValidationBatch obj=new AccountingCodeValidationBatch(new set<id>{ job.Company__c} );
		integer defaultBatchSize = 10;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) <= 20 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Database.executebatch(obj, defaultBatchSize);
    }
    
    public AccountingCodeValidationBatch() {}

    public AccountingCodeValidationBatch(set<Id> operatingCompIds){
        operatingCompanyIds = operatingCompIds;
        string segFields = '';
		for(Segment_Definition__c sd : SS.segments){
			segFields += ', ' + sd.Accounting_entry_field__c ;
		}
   	
      	query = 'SELECT Id, name, Valid__c, last_validated__c, SCOA_Key__c '
      				+ segFields
      				+ ' FROM Accounting_Code__c' 
      				+ ' WHERE Company__c IN :operatingCompanyIds ';
    }
      
    public Database.QueryLocator start(Database.BatchableContext BC){ 
    	MasterControlProgram.checkAlreadyRunning( this, BC );    
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Accounting_Code__c> scope){
        
        Savepoint sp = Database.setSavepoint();
        try{
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			SOQLUtil soql = new SOQLUtil('Accounting_Code__c', false); //enforceFLS=false, running in system mode
			soql.addFields(new set<string>{
				'Last_Validated__c'
			});
			soql.setOrderByClause('last_validated__c ASC'); 
			soql.setLimit(1);
			Accounting_Code__c acctCode = Database.query(soql.getQuery());


			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('segment_validation__c', false); //enforceFLS=false, running in system mode
			soql.addFields(new set<string>{
				'lastmodifiedDate'
			});
			soql.setOrderByClause('lastmodifieddate DESC'); 
			soql.setLimit(1);
			Segment_Validation__c segValidation = Database.query(soql.getQuery());
 			
 			
 			system.debug(logginglevel.info,'segValidation.lastmodifiedDate:'+segValidation.lastmodifiedDate);
 			system.debug(logginglevel.info,'acctCode.Last_Validated__c:'+acctCode.Last_Validated__c);
 			if(segValidation.lastmodifiedDate > acctCode.Last_Validated__c){
 				system.debug(logginglevel.info,'Inside if loop of execute');
 				AccountingCodeService.isInvokedfromBatch = true;
 				AccountingCodeService.segmentValidation(scope);
 			}
        } catch(Exception e) {
        	system.debug('EXCEPTION: ' + e);
            Database.rollback(sp);
            messages.add(Notify.getErrorMessage(scope, e.getMessage(), e.getStackTraceString()));
        }
    }
    
    public void finish(Database.BatchableContext info){
  	
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this ); 

    }
}