public with sharing class AccountingEntryVoidBatch implements Database.Batchable<sObject>, Database.Stateful, Process.Runnable2, Schedulable{

    public set<Id> AEtoVoid;
    public Id batchJobId;
    public Id CompId;																																											
    private List<Period__c> periods;
    private List<Id> periodIds = new list<Id>();
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    //This Id is used to pass which period we're closing the subledger for
    public Id subledgerClosePeriodId;
    //This is the field of the subledger closed field we intend to populate
    public string subledgerCloseField;
    
    public AccountingEntryVoidBatch(set<Id> AEtoVoid){
        this.AEtoVoid = AEtoVoid;
    }
    
    public AccountingEntryVoidBatch(Id batchJobId){
    	this.batchJobId = batchJobId;
    }
 
    public AccountingEntryVoidBatch() {}
    
    public void runBatch( Process_Job__c job ) { 		// Process.Runnable2 implementation 
    	
    	system.debug('job: ' + job);
    	AccountingEntryVoidBatch batch = new AccountingEntryVoidBatch();
        batch.CompId=job.company__c;
    	
    	integer defaultBatchSize = 200;
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
    
    
    public void execute(SchedulableContext context){
        Database.executeBatch(new AccountingEntryVoidBatch());
    }
    public Database.QueryLocator start(Database.BatchableContext BC){
                
	   	string query =  'SELECT Id, Accounting_Entry__c, Accounting_Entry__r.Period__c,Accounting_Entry__r.Journal_Entry__r.Auto_Reverse__c FROM Accounting_Entry_Line__c'
						+ ' WHERE Accounting_Entry__c  IN'
    					+ ' (SELECT Id FROM Accounting_Entry__c'
    					+ ' WHERE status__c = \'Active\' AND (Journal_Entry__r.Void__c = true '
    					+ ' OR Supplier_Invoice__r.Void__c = true OR Supplier_Payment__r.Void__c = true OR Journal_Entry__r.Auto_Reverse__c = true OR Customer_Invoice__r.Void__c = true OR Customer_Receipt__r.Void__c = true OR Receiving_Document__r.Void__c = true OR Bank_Transaction_Group__r.Void__c = true) AND Has_Exceptions__c != true  )'
						+ ' AND Accounting_Entry__c NOT  IN (SELECT Related_Accounting_Entry__c from Accounting_entry__c where Status__c=\'Active\' AND Has_Exceptions__c=false AND Related_Accounting_Entry__c!=null)'//Exclude valid reversal AEs .  					
    					+ ' AND Related_Accounting_entry_line__c = null';
    					
		/*if(AEtoVoid != null){
			query += ' AND Accounting_Entry__c in: AEtoVoid';
		}*/
		
		if(CompId!=null)
		{
			query +=  ' AND Accounting_Entry__r.company__c=:compId';
		}
		if(batchJobId != null){
			query += ' AND Accounting_Entry__r.BatchJobId__c = :batchJobId';
		}
		 //FIN-903 Pick reverse AEs with exceptions
    		//query += ' OR Accounting_Entry__c  IN (SELECT related_accounting_entry__c from Accounting_Entry__c where status__c=\'Active\' AND related_accounting_entry__c!=null and has_exceptions__c=true)';
        
        system.debug('queryLocator: ' + query);
        system.debug('AEtoVoid: ' + AEtoVoid);
        system.debug('compId: ' + CompId);
        system.debug('batchJobId: ' + batchJobId);
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Accounting_Entry_Line__c> scope){
        list<Accounting_Entry_Line__c> AELtoVoid = new list<Accounting_Entry_Line__c>();
        list<Accounting_Entry_Line__c> AELtoReverse = new list<Accounting_Entry_Line__c>();
        for(Accounting_Entry_Line__c ael:scope){
        	periodIds.add(ael.Accounting_Entry__r.Period__c);
        
        	if(ael.Accounting_Entry__r.Journal_Entry__r.Auto_Reverse__c == true)
	        	AELtoReverse.add(ael);
        	else
	        	AELtoVoid.add(ael);
        }
        AccountingEntryService aes = AccountingEntryService.getInstance();
        //FIN-903 Send batchjob id to stamp in the reversal lines.
        if(!AELtoReverse.isEmpty())
	        aes.AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEReverse, AELtoReverse,info.getJobId());        		
        if(!AELtoVoid.isEmpty())
	        aes.AccountingEntryLineReversal(AccountingEntryService.AEReverseType.AEVoid, AELtoVoid,info.getJobId());        		
    }
    
    public void finish(Database.BatchableContext info){
    	
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this ); 
        Map<Id, Period__c> mPeriods = new Map<Id, Period__c>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('Period__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id','name','AR_Subledger_Job__c','AP_Subledger_Job__c','Shipment_Subledger_Job__c','Receiving_Subledger_Job__c','Inventory_Subledger_Job__c',
			'FA_Subledger_Job__c','JE_Subledger_Job__c'
		});
		soql.setWhereClause('open__c = true AND Id in :periodIds AND type__c IN (\'Fiscal\', \'Adjustment\',null)');
		periods = Database.query(soql.getQuery());
        
        system.debug('periods: ' + periods);
       	for(period__c p : periods){
            
            Period__c iPeriod;
            if(mPeriods.containsKey(p.Id)){
            	system.debug('getting period: ' + p.Id);
                iPeriod = mPeriods.get(p.Id);
            }else{
                iPeriod = p;
                system.debug('setting period: ' + p.Id);
                system.debug('iPeriod matches subledger close period ' + iPeriod.Id + ' - ' + subledgerClosePeriodId + ' - ' +  subledgerCloseField);
                if(iPeriod.Id != null && iPeriod.Id == subledgerClosePeriodId){
                	
                	if(subledgerCloseField != null){
                		PeriodService.systemEditable.add(iPeriod.Id);
                		iPeriod.put(subledgerCloseField, system.now());
                		system.debug('subledger closed: ' + iPeriod.get(subledgerCloseField));
                	}
                }
            }
            
			if(iPeriod.AR_Subledger_Job__c == info.getJobId())
		    	iPeriod.AR_Subledger_Job__c = null;   			
			if(iPeriod.AP_Subledger_Job__c == info.getJobId())
		    	iPeriod.AP_Subledger_Job__c = null;   			
			if(iPeriod.Shipment_Subledger_Job__c == info.getJobId())
		    	iPeriod.Shipment_Subledger_Job__c = null;   			
			if(iPeriod.FA_Subledger_Job__c == info.getJobId())
		    	iPeriod.FA_Subledger_Job__c = null;   			
			if(iPeriod.Receiving_Subledger_Job__c == info.getJobId())
		    	iPeriod.Receiving_Subledger_Job__c = null;   			
			if(iPeriod.Inventory_Subledger_Job__c == info.getJobId())
		    	iPeriod.Inventory_Subledger_Job__c = null;   			
			if(iPeriod.JE_Subledger_Job__c == info.getJobId())
		    	iPeriod.JE_Subledger_Job__c = null;   			
		    PeriodService.systemEditable.add(iPeriod.Id);
            system.debug('add period: ' + iPeriod);
			mPeriods.put(iPeriod.Id, iPeriod);
            
       	}
       	
       	
       	if(mPeriods.keySet().size() > 0) {
            system.debug('mPeriods: ' +  mPeriods);
       		DML.updateAsSystem(mPeriods.values());
        }       
    }
}