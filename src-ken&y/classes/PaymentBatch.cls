public with sharing class PaymentBatch implements Database.Batchable<sObject>, Process.Runnable, Database.Stateful{

	public Id companyId;
	public List<KendoUtils.FilterDescriptor> filters;
    map<id,SupplierPaymentService.InvoiceWrapper> initialScopeInvsFromUI = new map<id,SupplierPaymentService.InvoiceWrapper>();   //store id with invoice amount to be paid/consumed      
    public Set<Id> initialSetOfSuppliersChosenToBePaid = new Set<Id>();  
    public List<Notify.Message> messages = new List<Notify.Message>();
    public string paymentMethod;
    public Boolean totalCreditsExceedsDebits = false;
    public string query;
    public set<id> SIset = new set<Id>();
    public class PymtBatchException extends Exception{}
    
    public PaymentBatch ( List<KendoUtils.FilterDescriptor> filterCriteria, map<id,SupplierPaymentService.InvoiceWrapper> scopeInvoicesFromUI, Set<Id> scopeOfSuppliersChosen){
        filters = filterCriteria;
        initialScopeInvsFromUI = scopeInvoicesFromUI;
        initialSetOfSuppliersChosenToBePaid = scopeOfSuppliersChosen;
        SIset.addall(initialScopeInvsFromUI.keyset() );
        system.debug('SISet=='+ SISet);
        for(KendoUtils.FilterDescriptor fd: filterCriteria){
            system.debug(LoggingLevel.info,'Filter: ' + fd);            
            if (fd.field == 'Payment_Method_G__c'){                
                paymentMethod = String.valueOf(fd.value);  
            }    
            if (fd.field == 'totalCreditsExceedsDebits'){                
                totalCreditsExceedsDebits =  String.valueOf(fd.value).toLowerCase() == 'true' ? True : False;
            }             
        }
        
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        system.debug(LoggingLevel.ERROR, 'entered query locator, suppliers: ' + initialSetOfSuppliersChosenToBePaid + '=initialScopeInvsFromUI='+ initialScopeInvsFromUI.keyset() + '=paymentMethod=' + paymentMethod);
        MasterControlProgram.checkAlreadyRunning( this, BC );
        string whereClause = ' where Status__c = \'Approved\'  AND Hold__c = false and  Invoice_Type__c NOT IN (\'Credit Memo\') AND Payment_Method_G__c = : paymentMethod AND Supplier__r.Hold_Payment__c = false ' +
            			' AND Supplier__c= : initialSetOfSuppliersChosenToBePaid  And  Id IN :SIset order by Invoice_Amount__c desc,Supplier__c asc';
    	query =	'Select Id, Name,Supplier__c,Invoice_amount__c,Invoice_Type__c From Supplier_Invoice__c ' + whereClause;  
    	return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<sObject> scope){        
    	system.debug(LoggingLevel.ERROR, 'entered execute, supplier invoice scope: ' + scope);
    	Savepoint sp = Database.setSavepoint();  
    	try{     
    		string suppId = (string)scope[0].get('Supplier__c');            
            SOQLUtil supplierSoql = new SOQLUtil ( 'Supplier__c',true) ; //enforceFLS = true, runs in user mode
	    	supplierSoql.addFields ( new Set<String> { 'Id', 'Name','Pay_Per_Invoice__c'} ) ;
	    	supplierSoql.setWhereClause ( ' Hold_Payment__c = false and Id In :initialSetOfSuppliersChosenToBePaid' );
        	supplierSoql.setOrderByClause ( 'Name ASC' ) ;
        	List<Supplier__C> supplierList = database.query(supplierSoql.getQuery());
        	 
 			SupplierPaymentService spService = new SupplierPaymentService();
        	spService.processPayments( filters, initialScopeInvsFromUI,scope, supplierList, BC.getJobId());
        }catch(Exception ex) {
            system.debug('exception in batch processing : '+ ex.getMessage() + '=' + ex.getStackTraceString());
            Database.rollback(sp);
            if (!Test.isRunningTest()){
                messages.add(new Notify.Message(Label.Error_Occurred_While_Processing_Payment_Batch + ':'  + ex.getMessage() +'.' + Label.Contact_Kenandy_administrator_for_help, '')); //PTP-625
            	//messages.add(Notify.getErrorMessage(scope, ex.getMessage(), ''));
                //failureCounter = 1;
            }else
            	throw new PymtBatchException(ex.getMessage(), ex); 
        }
    } 
    
    public void finish(Database.BatchableContext info){
        system.debug(LoggingLevel.INFO,'finish method : '+ initialScopeInvsFromUI);
		BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
		Notify.sendEmailBatchFinish(messages.size(), null, messages, info);      
		system.debug('error messages : '+ messages.size());
		////NOW call the batch to do actions before the Supplier invoices get finalized
		//KNDY-16750 - seperate batch to finalize SPs
        BatchInjector nextBatch = null;
        Integer finalizeBatchSize = 200;
        if (messages.size() == 0){
	        if(nextBatch == null){
	        	nextBatch = BatchInjector.getNextBatch(Schema.Supplier_Payment__c.getSObjectType().getDescribe().getName(), 0);
	        }
	
	        Id batchId;
	        if(nextBatch != null && nextBatch.executer != null  ){
	        	//run next batch
	        	system.debug('finish method of payment batch, starting SupplierPaymentPreFinalizeBatch' + info.getJobId() + ' , nextBatch ='+nextBatch);
	        	batchId = Database.executeBatch(new SupplierPaymentPreFinalizeBatch(info.getJobId(),totalCreditsExceedsDebits, nextBatch.executer, nextBatch.sequence), nextBatch.scope);
	        }else{
	        	//call finish
	        	MasterControlProgram.finishedBatch( this ); 
	            system.debug('finish method of payment batch, starting SupplierPaymentFinalizeBatch' + info.getJobId() );
	            //KNDY-19040 fetch finalize batch scope from configuration MDT
	            List<ConfigurationMDT__mdt> mdtRecords = [SELECT developerName, Value__c, namespacePrefix
                                        FROM ConfigurationMDT__mdt
                                        WHERE developerName = 'Supplier_Payment_Finalize_Batch_Size'
                                        LIMIT 1];
		        if (mdtRecords.size() > 0){
		            finalizeBatchSize = mdtRecords[0].Value__c != null ? Integer.ValueOf(mdtRecords[0].Value__c) : finalizeBatchSize;
		        }
	        	batchId = Database.executeBatch(new SupplierPaymentFinalizeBatch(info.getJobId(),totalCreditsExceedsDebits),finalizeBatchSize);
	        }
        }else
        	MasterControlProgram.finishedBatch( this ); 

    }
 
 	/* implementation of Runnable 
 	 */
 	public PaymentBatch() {}
 	public void runBatch( id CompanyId) {
		Integer batchSize = 1;
		if (Test.isRunningTest()) {
			batchSize = 10; //need to run more than one in the test, since we only get 1 batch execution in test context
		}
		//KNDY-18789 - Fetch batch scope from CMDT and if it doesnt exists set default batchsize =1
		List<ConfigurationMDT__mdt> mdtRecords = [SELECT developerName, Value__c, namespacePrefix
                                        FROM ConfigurationMDT__mdt
                                        WHERE developerName = 'Supplier_Payment_Batch_Size'
                                        LIMIT 1];
        if (mdtRecords.size() > 0){
            batchSize = mdtRecords[0].Value__c != null ? Integer.ValueOf(mdtRecords[0].Value__c) : batchSize;
        }
		system.debug(LoggingLevel.Error,'Batch size from MDT : ' +mdtRecords + ' and Actual Batch Size : ' + batchSize );
		PaymentBatch jpBatch = new PaymentBatch(filters, initialScopeInvsFromUI, initialSetOfSuppliersChosenToBePaid);
        ID jobId = Database.executeBatch(jpBatch, batchSize); 
	}  
}