public with sharing class SalesOrderPlanBatch implements 
                            Database.Batchable<sObject>, 
                            Process.Runnable2,
                            Database.Stateful{
    
    public Set<Id> operatingCompanyIds = new Set<Id>();
    public Id salesOrderId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    public SalesOrderPlanBatch(){
        
    }
    
    public SalesOrderPlanBatch(set<Id> operatingCompIds){
        operatingCompanyIds = operatingCompIds;
    }
    
    public SalesOrderPlanBatch(set<Id> operatingCompIds, Id soId){
        operatingCompanyIds = operatingCompIds;
        salesOrderId = soId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
		Set<String> standardOrderTypes = SalesOrderService.STANDARD_ORDER_TYPES;
    	
        /*String query =  ' SELECT Id ' +
                        '   FROM Sales_Order__c ' +
                        '  WHERE Status__c = \'' + SalesOrderService.SO_STATUS_DRAFT + '\'' +
                        '    AND Ready__c = true ' + 
                        '    AND Has_Exceptions__c = false ';

        
        query += ' ORDER BY CreatedDate ';*/
		
		String whereClause = ' Status__c = \'' + SalesOrderService.SO_STATUS_DRAFT + '\'' +
	                         ' AND Ready__c = true ' +
	                         ' AND Company__c IN:operatingCompanyIds ' +
	                         (salesOrderId != null ? 'AND Id = \'' + salesOrderId + '\'' : '')+
	                         ' AND Has_Exceptions__c = false ORDER BY CreatedDate ';
	                         

		
		SOQLUtil soql = new SOQLUtil('Sales_Order__c');
	    soql.addFields(new Set<String>{'Id'});
	    soql.setWhereClause(whereClause);
	    
        return Database.getQueryLocator(soql.getQuery());
    }
    
    public void execute(Database.BatchableContext info, List<Sales_Order__c> scope){
        SalesOrderService sos = new SalesOrderService();
        sos.plan(KSE.grepIdSetFromList(scope));
    }
    
    public void finish(Database.BatchableContext info){
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);
        
        if(salesOrderId != null){
            SalesOrderAllocateBatch allocateBatch = new SalesOrderAllocateBatch(salesOrderId);
            Database.executeBatch(allocateBatch, 1);
        }
        else{
            MasterControlProgram.finishedBatch( this ); 
        }
    }
    
    public void runBatch( Process_Job__c job ) {
        SalesOrderPlanBatch batchInstance = new SalesOrderPlanBatch(new Set<Id>{ job.Company__c });
        integer defaultBatchSize = 1;
        if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) < 10) 
            defaultBatchSize = integer.valueOf(job.Batch_Size__c);
        
        Id batchJobId = Database.executebatch(batchInstance, defaultBatchSize);
    }
}