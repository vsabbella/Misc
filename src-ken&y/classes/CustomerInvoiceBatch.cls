public with sharing class CustomerInvoiceBatch implements Database.batchable<sObject>, Database.Stateful,  Process.Runnable2{
	
	private static SchemaUtil util = SchemaUtil.getInstance();
	private static InvoiceGroupingRuleService igrUtil = InvoiceGroupingRuleService.getInstance(); 
	public List<Notify.Message> messages = new List<Notify.Message>();
	public set<InvoiceGroupingRuleDefinition> sGroupingRules;
	public set<Id> operatingCompanyIds = new set<Id>();
	
	
	public CustomerInvoiceBatch(set<Id> operatingCompIds) {
		operatingCompanyIds = operatingCompIds;
		DateTime timeNow = system.now();
		sGroupingRules = new set<InvoiceGroupingRuleDefinition>();
		String immediate = FrequencyService.FREQUENCY_PERIOD_IMMEDIATE;
		String whereClause = 'Is_Valid__c = true and Start_Date__c != null and Start_Date__c <= :timeNow and Company__c in :operatingCompanyIds and Rank__c != null and Is_Active__c = true';
		SOQLUtil soql = new SOQLUtil('Invoice_Grouping_Rule__c', TRUE);
		soql.addAllFields();
		soql.addFields(new set<String>{'Billing_UOM__r.Recurrence__c', 'BILLING_UOM__r.Every__c'});
		soql.setWhereClause(whereClause);
		system.debug('query igr '+soql.getQuery());
		for(Invoice_Grouping_Rule__c igr : Database.query(soql.getQuery()))
		{
			sGroupingRules.add(new InvoiceGroupingRuleDefinition(igr));
		}
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC){ 
		DateTime timeNow = system.now();
		string immediate = FrequencyService.FREQUENCY_PERIOD_IMMEDIATE;		 
		string  allowanceAccrual = AllowanceRuleService.ALLOWANCE_ACCRUAL;
		String query = util.generateQueryFromFieldSet('Fulfillment__c', new set<String>{},new set<String>{'Id', 'Name'}, igrUtil.getWhereClause());
		System.debug(logginglevel.error,query);
		return Database.getQueryLocator(query);
	}
	
	public void execute(Database.BatchableContext info, List<Fulfillment__c> scope) {
		system.debug(logginglevel.error,'scope--> '+scope);
		map<Id,Fulfillment__c> mFulfillments = igrUtil.getFulfillments('Fulfillment__c', KSE.grepIdSetFromList(scope)); 
		
		system.debug(logginglevel.error,'mFulfillments '+mFulfillments);

		Map<Id, Fulfillment__c> fulfillmentForAllowances = new Map<Id, Fulfillment__c>();
		for (Fulfillment__c ful : mFulfillments.values()){
			fulfillmentForAllowances.put(ful.id, ful);
		}
		list<InvoiceGroupingRuleDefinition> sortedRules = new list<InvoiceGroupingRuleDefinition>(sGroupingRules);
	    sortedRules.sort(); //will sort in descending as modified the comaprable.  
		system.debug(logginglevel.error,'sortedrules '+sortedRules);
					
						
		map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> typeToFulfillments = new map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>>();
		typeToFulfillments = igrUtil.buildTypeToFulfillments(mFulfillments, sortedRules);
					
					
	   Savepoint sp = Database.setSavepoint();
					
	   system.debug(logginglevel.error,'typeToFulfillments '+typeToFulfillments);
	   try {
	   map<String,Customer_Invoice__c> mCIs = new map<String,Customer_Invoice__c>();
	   map<String,Customer_Invoice_Line__c> mCILs = new map<String,Customer_Invoice_Line__c>();
	   map<String,Customer_Invoice_Sub_Line__c> mFulfillmentMap = new map<String,Customer_Invoice_Sub_Line__c>();
	   map<Id, Fulfillment__c> mFulfillmentsToUpdate = new  map<Id, Fulfillment__c>();
	   
	   	 igrUtil.createInvoices(typeToFulfillments, info.getJobID(), mCIs, mCILs, mFulfillmentMap, mFulfillmentsToUpdate);

		 igrUtil.calculateBestPrice(mCILs, mFulfillmentMap.values(), typeToFulfillments.values() );

		 igrUtil.finishConsolidate(mCIs, mCILs, mFulfillmentMap, mFulfillmentsToUpdate);
	     system.debug(logginglevel.error,'after calling finishConsolidate');

		   //TODO: what abt allowances???
	  	 igrUtil.allowancesOperations(mCILs.values(),'Sales_Order__c',true, mFulfillmentMap.values(), fulfillmentForAllowances);
	  	 //Set<id> cilIds = KSE.grepIdSetFromList(mCILs.values());
	  	//AllowanceRuleService.copyManualAllowancesFromOrderToInvoice( cilIds, KSE.grepRelatedIdSetFromList(mCils.values(), 'Sales_Order__c', true));
	  	//AllowanceRuleService.calculateInvoiceAllowances( cilIds );

	   	
	   }catch(Exception ex) {
	   	  system.debug(logginglevel.error, 'invoice batch exception '+ ex.getMessage() + ' ' +  ex.getStackTraceString());
	   	  Database.rollback(sp);
	   	  messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ex.getStackTraceString()));
	   }
	   
	   
		
		
	}
	
	
	public void finish(Database.BatchableContext info){
		
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish(messages.size(), null, messages, info);        

        //NOW call the batch to do actions before the invoices get finalized

        BatchInjector nextBatch = null;
        if(TaxService.getInstance().HasTaxService){
        	nextBatch = TaxService.getInstance().getInvoicingBatch();
        }

        if(nextBatch == null){
        	nextBatch = BatchInjector.getNextBatch(Schema.Customer_Invoice__c.getSObjectType().getDescribe().getName(), 0);
        }

        Id batchId;
        if(nextBatch != null && nextBatch.executer != null){
        	//run next batch
        	batchId = Database.executeBatch(new CustomerInvoicePreFinalizeBatch(info.getJobId(), nextBatch.executer, nextBatch.sequence), nextBatch.scope);
        }else{
        	//call finish
        	MasterControlProgram.finishedBatch( this ); 
        	batchId = Database.executeBatch(new FinalizeCustomerInvoiceBatch(info.getJobId()),200);
        }

        
	}
	
	
	
	public CustomerInvoiceBatch() {}  // newInstance(); needs a no-arg consturctor  
 	public void runBatch( Process_Job__c job) {
		CustomerInvoiceBatch Obj=new CustomerInvoiceBatch(new Set<ID>{ job.Company__c });
		integer defaultBatchSize = 1;
		if ( job.Batch_Size__c !=null && integer.valueOf(job.Batch_Size__c) < 100 && integer.valueOf(job.Batch_Size__c) >= 1 ) { 
			defaultBatchSize = integer.valueOf(job.Batch_Size__c);
		}
        Id jobId=Database.executebatch(obj, defaultBatchSize);
 	}
	
	private void pushToMap(map<InvoiceGroupingRuleService.FulfillmentType,map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>> typeToFulfillments, InvoiceGroupingRuleService.FulfillmentType  fType, Fulfillment__c f, InvoiceGroupingRuleContainer container) {
		
		if(typeToFulfillments.containsKey(fType)) {
			
			map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> mFs = typeToFulfillments.get(fType);
			
			if(mFs.containsKey(container)) {
				list<Fulfillment__c> lFs = mFs.get(container);
				lFs.add(f);
				mFs.put(container,lFs);
			}
			else
				mFs.put(container,new list<Fulfillment__c>{f});
			
			
			typeToFulfillments.put(fType,mFs);
		}
		else {
			map<InvoiceGroupingRuleContainer,list<Fulfillment__c>> mFs = new map<InvoiceGroupingRuleContainer,list<Fulfillment__c>>();
			mFs.put(container, new list<Fulfillment__c>{f});
			typeToFulfillments.put(fType,mFs);
		}
		
	}
	

}