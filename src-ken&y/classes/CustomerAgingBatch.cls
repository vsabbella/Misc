global with sharing class CustomerAgingBatch implements Database.Batchable<sObject>, Database.Stateful, Process.Runnable {
    
    global Id companyId;
    global List<Notify.Message> messages = new List<Notify.Message>();
    global String query;
    global map<id, Customer__c> mCorporateCustomers = new map<Id,Customer__c>(); //Store roll up on Corporate Customer
    global CustomerAgingBatch (Id comp){
        companyId = comp;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<String> rtIds = new Set<String>();
        String rtId = KSE.RecordTypeDevNameMap('Customer__c').get('Bill_To');
        query = 'SELECT Id, Name, Top_Parent_Customer__c,Oldest_Invoice_Age__c, X1_30_Days_Past_Due__c, X31_60_Days_Past_Due__c, X61_90_Days_Past_Due__c, More_Than_90_Days_Past_Due__c, Parent_Customer__c FROM Customer__c WHERE RecordTypeId = :rtId AND Company__c = :companyId AND Status__c = \'Approved\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Customer__c> scope) {
        System.debug(scope);
        try {
            
            Map<Id, Decimal> custToAgingMap = new Map<Id, Decimal>();
            Map<Id, Decimal[]> custToBucketMap = new Map<Id, Decimal[]>();
            Map<Id, Decimal> custToAvgPastYear = new Map<Id, Decimal>();
            //INT-132: remove reference to recordtype
            //String rtId = KSE.RecordTypeDevNameMap('Customer_Invoice__c').get('Invoice');
            Map<Id, Map<Id, Customer_Invoice__c>> analystToInvoice = new Map<Id, Map<Id, Customer_Invoice__c>>();
            Map<Id, Map<Id, Customer__c>> analystToCustomer = new Map<Id, Map<Id, Customer__c>>();
            
            //INT-205 Changing the query for invoices to match that of CustomerCreditBucketBatch to ensure aging buckets sum up to open past due.    
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			String allowanceAccrualType = AllowanceRuleService.ALLOWANCE_ACCRUAL;
			SOQLUtil soql = new SOQLUtil('Customer_Invoice__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'Id','Name','Amount_Past_Due__c','Balance__c','Customer__c','Customer__r.Parent_Customer__c','Days_Past_Due__c','Bill_To_Customer__c',
				'Date_Invoiced__c','Status__c','Customer__r.Risk_Class__c','Due_Date__c'
			});
			soql.setWhereClause('Bill_To_Customer__c IN :scope AND Status__c=\'Open\' AND Finalized__c = true and Invoice_Type__c != :allowanceAccrualType');
			for (Customer_Invoice__c invoice : Database.query(soql.getQuery())) {
                // Initialize aging buckets if needed
                if (!custToAgingMap.containsKey(invoice.Bill_To_Customer__c))
                    custToAgingMap.put(invoice.Bill_To_Customer__c, 0);
                if (!custToBucketMap.containsKey(invoice.Bill_To_Customer__c))
                     custToBucketMap.put(invoice.Bill_To_Customer__c, new List<Decimal>{0, 0, 0, 0, 0});
                
                // Do stuff based on whether the invoice is open or closed
                if (invoice.Status__c == 'Open') {

                    // Recalculate aging buckets
                    if (invoice.Days_Past_Due__c != null) {
                        if (custToAgingMap.get(invoice.Bill_To_Customer__c) < invoice.Days_Past_Due__c)
                            custToAgingMap.put(invoice.Bill_To_Customer__c, invoice.Days_Past_Due__c);
                        if (invoice.Days_Past_Due__c <= 0)
                            custToBucketMap.get(invoice.Bill_To_Customer__c)[0] += invoice.Balance__c;
                        else if (invoice.Days_Past_Due__c > 0 && invoice.Days_Past_Due__c < 31)
                            custToBucketMap.get(invoice.Bill_To_Customer__c)[1] += invoice.Balance__c;
                        else if (invoice.Days_Past_Due__c > 30 && invoice.Days_Past_Due__c < 61)
                            custToBucketMap.get(invoice.Bill_To_Customer__c)[2] += invoice.Balance__c;
                        else if (invoice.Days_Past_Due__c > 60 && invoice.Days_Past_Due__c < 91)
                            custToBucketMap.get(invoice.Bill_To_Customer__c)[3] += invoice.Balance__c;
                        else if (invoice.Days_Past_Due__c > 90)
                            custToBucketMap.get(invoice.Bill_To_Customer__c)[4] += invoice.Balance__c;
                    }
                } 
            }
            
            system.debug('custToBucketMap '+custToBucketMap);
            for (Customer__c customer : scope) {
            	
            	//AR-132 using stateful feature of the batch collect the rollup on corporate customers. update the customers in the finish
            	Customer__c corp = mCorporateCustomers.containsKey(customer.Parent_Customer__c) ? mCorporateCustomers.get(customer.Parent_Customer__c) : new Customer__c(Id = customer.Parent_Customer__c, Current_Balance__c = 0,
        																																							 X1_30_Days_Past_Due__c = 0, X31_60_Days_Past_Due__c = 0,
        																																							 X61_90_Days_Past_Due__c = 0, More_Than_90_Days_Past_Due__c = 0,
        																																							 Oldest_Invoice_Age__c = 0);
        		system.debug('corp at start '+corp);
                customer.Oldest_Invoice_Age__c = custToAgingMap.get(customer.Id);
                if (customer.Oldest_Invoice_Age__c == null)
                    customer.Oldest_Invoice_Age__c = 0;
                
                corp.Oldest_Invoice_Age__c  =  corp.Oldest_Invoice_Age__c < customer.Oldest_Invoice_Age__c ? customer.Oldest_Invoice_Age__c : corp.Oldest_Invoice_Age__c;
                
                if (custToBucketMap.containsKey(customer.Id)) {
                		
                    if (custToBucketMap.get(customer.Id)[0] != null) {
                        customer.Current_Balance__c = custToBucketMap.get(customer.Id)[0];
                        corp.Current_Balance__c += custToBucketMap.get(customer.Id)[0];
                    }
                    if (custToBucketMap.get(customer.Id)[1] != null) {
                        customer.X1_30_Days_Past_Due__c = custToBucketMap.get(customer.Id)[1];
                        corp.X1_30_Days_Past_Due__c += custToBucketMap.get(customer.Id)[1];
                    }
                    if (custToBucketMap.get(customer.Id)[2] != null) {
                        customer.X31_60_Days_Past_Due__c = custToBucketMap.get(customer.Id)[2];
                        corp.X31_60_Days_Past_Due__c += custToBucketMap.get(customer.Id)[2];
                    }
                    if (custToBucketMap.get(customer.Id)[3] != null) {
                        customer.X61_90_Days_Past_Due__c = custToBucketMap.get(customer.Id)[3];
                        corp.X61_90_Days_Past_Due__c += custToBucketMap.get(customer.Id)[3];
                    }
                    if (custToBucketMap.get(customer.Id)[4] != null) {
                        customer.More_Than_90_Days_Past_Due__c = custToBucketMap.get(customer.Id)[4];
                        corp.More_Than_90_Days_Past_Due__c += custToBucketMap.get(customer.Id)[4];
                    }
                }else {//KNDY-10794 if bill to customer not part of the map, implies all buckets are zero.
                	customer.Current_Balance__c = 0; 
                	customer.X1_30_Days_Past_Due__c =0;
                	customer.X31_60_Days_Past_Due__c = 0; 
                	customer.X61_90_Days_Past_Due__c = 0; 
                	customer.More_Than_90_Days_Past_Due__c = 0;
                	
                }
                system.debug('corp at end '+corp);
                mCorporateCustomers.put(corp.Id,corp);
            }
            Database.SaveResult[] results = DML.updateAsSystem(scope, false);
            Integer count = 0;
            String errorMsg = '';
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    count++;
                    errorMsg = result.getErrors()[0].getMessage();
                }
            }
            if (count > 0) {
                messages.add(new Notify.Message(count + ' errors. First error message: ' + errorMsg, ''));
            }
        } catch(Exception e) {
            System.debug(e.getMessage() + ' ' + e.getStackTraceString());
            messages.add(new Notify.Message('Failure message: ' + e.getMessage(), e.getStackTraceString()));
        }
    }
    
    global void finish(Database.BatchableContext BC) {
    	
    	system.debug('at batch finish: mCorporateCustomers '+mCorporateCustomers);
    	//AR-132
    	if(!mCorporateCustomers.isEmpty()) {
    		try {
    			DML.updateAsSystem(mCorporateCustomers.values());
    		}catch(Exception ex) {
    			messages.add(Notify.getErrorMessage(mCorporateCustomers.values(), ex.getMessage(), ex.getStackTraceString()));
    		}
    	}
    	
        Map<Id, String> chatterMessages = BatchToChatter.processBatchInformation(BC.getJobId(), this, messages);
        MasterControlProgram.finishedBatch( this );
        if (chatterMessages.values().size() > 0) {
            KSE.sendEmailBatchCompletion(chatterMessages.values()[0]);
        }
    }
 
    /* implementation of Runnable 
     */
    global CustomerAgingBatch () {}
    global void runBatch( id CompanyId ) {
        Integer batchSize = 200; //reduced batch size to prevent too many query rows error
        CustomerAgingBatch jpBatch = new CustomerAgingBatch(CompanyId);
        ID jobId = Database.executeBatch(jpBatch, batchSize); 
    }
}