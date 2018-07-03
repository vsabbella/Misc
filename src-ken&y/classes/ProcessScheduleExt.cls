public with sharing class ProcessScheduleExt {
	
	public List<Process_Job__c> jobs {  
        get { 
            List<Process_Job__c> tmp = MasterControlProgram.getAllJobs( con.getId() );
            // pick up any extra details from the jobs table if we can.
            set<id> jobids = kse.grepRelatedIdSetFromList(tmp, 'Queueable_Id__c', true);

			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'TotalJobItems','Status','ParentJobId','NumberOfErrors','MethodName','LastProcessedOffset','LastProcessed',
				'JobType','JobItemsProcessed','Id','ExtendedStatus','CreatedDate','CreatedById','CompletedDate','ApexClassId'
			});
			soql.setWhereClause('id in :jobids');

			map<id,AsyncApexJob> asyncRecords = new map<id,AsyncApexJob> ((List<AsyncApexJob>)Database.query(soql.getQuery()));
            
            for (Process_Job__c t:tmp ) {
                AsyncApexJob jobInfo = asyncRecords.get(t.Queueable_Id__c);
                
                if ( jobInfo!= null && String.isBlank(t.Exception__c) && !String.isBlank(jobInfo.ExtendedStatus) ) {
                    t.Exception__c = jobInfo.Status + ': ' +jobInfo.ExtendedStatus;
                }
            }
			tmp.sort();  // KNDY-6542 sort jobs for the page (by name)
            return tmp;
        } 
    } 
   
   	private ApexPages.StandardController con;
	public boolean hasEditProcessJob {get; private set; }
	
    public ProcessScheduleExt(ApexPages.StandardController controller) {     
        con = controller;
        // query the process job table get perms for the current user, KNDY-6654
        hasEditProcessJob = Process_Job__c.getSObjectType().getDescribe().isUpdateable();
	} 
    public PageReference reloadPage() { 
    	PageReference p = Page.ProcessSchedule;
        p.getParameters().put('id', con.getId());
        return p.setRedirect(true);
    }
    public PageReference runNow2() {
        try { 
            // KNDY-4266 do not run a job if its already running
            if ( JobIsRunning( ApexPages.currentPage().getParameters().get('recordid')) ) return null;
            
            MasterControlProgram.executeNow( ApexPages.currentPage().getParameters().get('recordid') );
            
        } catch ( Exception e) { 
            Apexpages.addMessages( e);
        }
        return null;
    }
    
    // KNDY-4266 find current job by id, see if it's in the queue or running, 
    // report a message if it is running and return boolean 
	private boolean JobIsRunning( id jobid ) {

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('Process_Job__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'name','Apex_Class__c'
		});
		soql.setWhereClause('id =:jobid');
		soql.setLimit(1);

		Process_Job__c job = Database.query(soql.getQuery());

        list<string>jobNames = new list<string>{job.Apex_Class__c};

       	// special case for MRP jobs since the process_job class names dont always match the batch class names that are running
        if ( job.Apex_Class__c == 'GenerateMRP.ItemLevel')    {
            jobNames.addAll( new list<string>{'ClearItemLevels','GenerateTempLevels','CreateNextLevel','CleanFinalData'} ); 
        }
        if ( job.Apex_Class__c == 'GenerateMRP.Planning') {
            jobNames.addAll( new list<string>{'GenerateMRPEraseTemp','GenerateSafetyDemand','GenerateMRPTempData','GenerateMRPPlanData'});
        }

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'id','status','ApexClass.Name'
		});
		soql.setWhereClause('status IN(\'Holding\',\'Queued\',\'Preparing\',\'Processing\') and ApexClass.Name in :jobNames');
		soql.setOrderByClause('CreatedDate desc');
		soql.setLimit(1);

		AsyncApexJob[] runningJob = Database.query(soql.getQuery());
																	
		if ( runningJob.size() > 0 ) 
        {
            ApexPages.addMessage( 	new ApexPages.Message(ApexPages.Severity.INFO, 
                                                          Label.Job_is_running_please_wait + job.Name ));
        } 

		return ApexPages.hasMessages(); 	
	}
	
	//public PageReference incrementCounter() {	return null;	}
	
    public PageReference newJob() {
        Schema.DescribeSObjectResult r = Process_Job__c.sObjectType.getDescribe();
        return new PageReference( '/'+ r.getKeyPrefix()  /*+'/e'*/  ); // what about cancel ?   TODO 
    }
    
    public PageReference abortJob() {
        id  abortid = ApexPages.currentPage().getParameters().get('abortid');
        if ( abortid != null ) 
            system.abortJob( abortid );    	
        return null;
    }
    
	public List<AsyncApexJob> getApexJobList() { 
        list<AsyncApexJob> ret = new list<AsyncApexJob>();
        set<string> inlist = new set<string>();

		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'TotalJobItems','Status','ParentJobId','NumberOfErrors','MethodName','LastProcessedOffset','LastProcessed',
			'JobType','JobItemsProcessed','Id','ExtendedStatus','CreatedDate','CreatedById','CompletedDate','ApexClassId',
			'ApexClass.Name','ApexClass.NamespacePrefix'
		});
		soql.setWhereClause('JobType != \'TestRequest\'');
		soql.setOrderByClause('CreatedDate desc');
		soql.setLimit(25);
		
		for( AsyncApexJob j: Database.query(soql.getQuery())){
            if ( ! inlist.contains(j.ApexClassId) ) {
            	ret.add(j);    
                inlist.add(j.ApexClassId);
            }
        }        
        return ret;
    }
    
    public Pagereference newScheduledJob() {
        try { 
            MasterControlProgram.establishScheduled(); 
        } catch ( Exception e) {  		
            Apexpages.addMessages( e);
        }
        return null;
    }
    
    // ENHANCE, would be nice to show the one job we know is ours, instead of all trigger jobs
    // needs a custom setting to store our job id 
    public List<CronTrigger> GETscheduledJobs () { 
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		
		SOQLUtil soql = new SOQLUtil('CronTrigger', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'TimesTriggered','TimeZoneSidKey','State','StartTime','CronJobDetail.name','PreviousFireTime','OwnerId','NextFireTime',
			'LastModifiedById','Id','EndTime','CronExpression','CreatedDate','CreatedById'
		});
		soql.setWhereClause('');
		soql.setLimit(20);
		
		CronTrigger[] ct = Database.query(soql.getQuery());
        
        //of all the jobs, how do i know if mine is running or not ? no name, nothing to know...
        return ct;
    }
    
    public void AbortAllMasterSchedule() { 
    	CronTrigger[] ct = GETscheduledJobs();
        for (crontrigger c :ct) {
			if ( c.CronJobDetail.Name.startsWith('Master Control') )
                system.abortJob(c.id);
        }
    }
    
    public void DefaultJobsBuild( ) {   	// construct default process jobs 
    	
        // query the ones we have 
        set<string> haveJobNameSet = new Set<string>(); 
        
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		Id conId = con.getId();
		
		SOQLUtil soql = new SOQLUtil('Process_Job__c', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Apex_Class__c'
		});
		soql.setWhereClause('company__c = :conId');
		
		for (Process_Job__c j: Database.query(soql.getQuery())){
	        haveJobNameSet.add(j.Apex_Class__c);
	    }
        
        List<Process_Job__c> jobList = new List<Process_Job__c>(); // all jobs we need
        
        jobList.add( new Process_Job__c( name= 'Apply Payments',apex_class__c = 'ApplyPaymentsBatch', Description__c = 'Selects all customer invoices which are changed and pulls the list of Payment Details to sum up',		Interval__c = 1.0, Frequency__c = 'Days' 	));
        jobList.add( new Process_Job__c( name= 'AccountingEntry Void Batch',apex_class__c = 'AccountingEntryVoidBatch', Description__c = 'Regenerates the reversal accounting entries for source docs which are voided and Accrual journal entries',		Interval__c = 1.0, Frequency__c = 'Days' 	));
		
        jobList.add( new Process_Job__c( name= 'MRP Planning',apex_class__c = 'GenerateMRP.Planning'	,		Description__c = 'Perform all material planning steps, including all outstanding SO demand, PO supply and item inventory, work in process and generate a consolidated plan for this company ', Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'MRP Item Leveling',apex_class__c = 'GenerateMRP.ItemLevel'	,	 Description__c = 'Ensure that each item in the item database has the correct item level information, this step is required prior to MRP demand generation whenever new items are added or item components or item assemblies are modified.',	Interval__c = 1.0, Frequency__c = 'Weeks' 			));
        
        jobList.add( new Process_Job__c( name= 'Customer Invoicing With Grouping Rules',apex_class__c = 'CustomerInvoiceBatch'	, Description__c = 'Generates customer invoices based on grouping rules for the given company.', 		Interval__c = 1.0, Frequency__c = 'Days' 			));        
        jobList.add( new Process_Job__c( name= 'Customer Invoice Accounting',apex_class__c = 'CustomerInvoiceAccountingBatch'	, Description__c = 'Generates accounting entries for all customer invoices, that are finalized but not yet accounted for, for the given company',		Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'Payment Accounting',apex_class__c = 'PaymentAccountingBatch'	, Description__c = 'Generates accounting entries for all Payments, that are finalized but not yet accounted, for the given company.',		Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'Invoice Accounting',apex_class__c = 'InvoiceAccountingBatch'	, Description__c = 'Generates accounting entries for all Invoices, that are finalized but not yet accounted, for the given company.',		Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'Customer Receipt Accounting',apex_class__c = 'CustomerReceiptAccountingBatch'	,	Description__c = 'Generates accounting entries for all customer receipts, which are finalized but not yet accounted for, for the given company.',	Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'DTP Batch',apex_class__c = 'DTPBatch',Batch_Size__c = 1, Active__c = true,Description__c = 'Days to Pay Batch job which updates DTPForecast date on all open customer Invoices used for Cashforecasting reports',	Interval__c = 1.0, Frequency__c = 'Days' 			)); 
        jobList.add( new Process_Job__c( name= 'PO Receipt Accounting',apex_class__c = 'POReceiptAccountingBatch'	,	Description__c = 'Generates accounting entries for all purchase order receipts, that have corresponding closed purchase orders, but not yet accounted for the given company.',	Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'Supplier Invoice Accounting',apex_class__c = 'SupplierInvoiceAccountingBatch'	,	Description__c = 'Generates accounting entries for all supplier invoices, that are finalized but not yet accounted for, for the given company.',	Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'Supplier Payment Accounting',apex_class__c = 'SupplierPaymentAccountingBatch'	,	Description__c = 'Generates accounting entries for all payments made against supplier invoices, but not yet accounted for, for the given company.',	Interval__c = 1.0, Frequency__c = 'Days' 			));
        jobList.add( new Process_Job__c( name= 'Journal Entry Accounting',apex_class__c = 'JournalEntryAccountingBatch'	,	Description__c = 'Generates accounting entries for all journal entries created, but not yet accounted for, for the given company.',	Interval__c = 1.0, Frequency__c = 'Days' 			));
        
        jobList.add( new Process_Job__c( name= 'Fixed Asset Depreciation',apex_class__c = 'FixedAssetDepreciationBatch'	, Description__c = 'Runs through all the fixed assets that have been marked as depreciated and calculates their values based on the pre-defined algorithm for that asset class.',		Interval__c = 1.0, Frequency__c = 'Weeks' 			));
        jobList.add( new Process_Job__c( name= 'Fixed Asset Depreciation Accounting',apex_class__c = 'FixedAssetDepreciationAccountingBatch'	,	Description__c = 'Generates accounting entries for all the fixed assets that have been depreciated but not yet accounted for.',	Interval__c = 1.0, Frequency__c = 'Weeks' 			));
        
        jobList.add( new Process_Job__c( name= 'Fixed Asset Adjustment Accounting',apex_class__c = 'FixedAssetAdjustmentAccountingBatch'    ,   Description__c = 'Generates accounting entries for all the fixed assets that have been adjusted but not yet accounted for.', Interval__c = 1.0, Frequency__c = 'Weeks'           ));
        

        jobList.add( new Process_Job__c( name= 'Inventory Change Accounting',apex_class__c = 'InventoryChangeAccountingBatch'	,	Description__c = 'Generates accounting entries for all inventory changes, which are finalized but not yet accounted for, for the given company.',	Interval__c = 1.0, Frequency__c = 'Weeks' 			));

       	 
        jobList.add( new Process_Job__c( name= 'Sales Order Automation',apex_class__c = 'SalesOrderInspect',    
                                        Description__c = 'Automation processing, invoke standard or custom code for automation', Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false ));
        jobList.add( new Process_Job__c( name= 'Purchase Order Automation',apex_class__c = 'PurchaseOrderInspect',  
                                        Description__c = 'Automation processing, invoke standard or custom code for automation', Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false ));
        jobList.add( new Process_Job__c( name= 'Receiving Doc Automation',apex_class__c = 'ReceivingDocumentInspect',   
                                        Description__c = 'Automation processing, invoke standard or custom code for automation', Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false ));
        jobList.add( new Process_Job__c( name= 'Shipment Order Automation',apex_class__c = 'ShipmentInspect',   
                                        Description__c = 'Automation processing, invoke standard or custom code for automation', Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false ));        	
        
        jobList.add( new Process_Job__c( name= 'Supplier Invoice Automation',apex_class__c = 'SupplierInvoiceAutomationBatch'  ,   
                                        Description__c = 'Automation processing, invoke standard or custom code for automation',   Interval__c = 1.0, Frequency__c = 'Days' ));
        jobList.add( new Process_Job__c( name= 'Supplier Invoice Validate Draft',apex_class__c = 'SupplierInvoiceDraftInspectBatch'  ,   
                                        Description__c = 'Matches receipt invoice lines to the corresponding receipt & PO lines',   Interval__c = 1.0, Frequency__c = 'Hours' ));
        jobList.add( new Process_Job__c( name= 'Supplier Invoice Validate Incomplete',apex_class__c = 'SupplierInvoiceIncompleteInspectBatch'    ,   
                                        Description__c = 'Validate supplier invoices which are in Incomplete status & move them to Draft status',    Interval__c = 1.0, Frequency__c = 'Hours' ));
        jobList.add( new Process_Job__c( name= 'Customer Inspect ',apex_class__c = 'CustomerInspect'  ,  
                                        Description__c = 'Inspect Customer records',  Interval__c = 1.0, Frequency__c = 'Days'   ));
        jobList.add( new Process_Job__c( name= 'Consume Order Forecast ',apex_class__c = 'ConsumeForecastBatch'    ,   
                                        Description__c = 'Consume Order Forecast',    Interval__c = 1.0, Frequency__c = 'Days'    ));
        jobList.add( new Process_Job__c( name= 'Update Lot Status ',apex_class__c = 'LotUpdateStatusBatch'    ,   
                                        Description__c = 'Update Lot Status',    Interval__c = 1.0, Frequency__c = 'Days'    ));
        jobList.add( new Process_Job__c( name= 'Contract Netting ',apex_class__c = 'ContractLineNettingBatch'    ,   
                                        Description__c = 'Recalculates the netting buckets on a contract line ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false   ));
        jobList.add( new Process_Job__c( name= 'Bank Transaction Group Accounting',apex_class__c = 'BankTransactionGroupAccountingBatch'    ,   
                                        Description__c = 'Generates accounting entries for all Bank Transaction Group s, which are finalized but not yet accounted for, for the given company. ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false   ));
        jobList.add( new Process_Job__c( name= 'Recurring Journal Entries',apex_class__c = 'RecurringJournalEntryBatch'    ,   
                                        Description__c = 'Generates journal entries from the recurring template, for the given company. ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false   ));
        jobList.add( new Process_Job__c( name= 'Accounting Code Validation',apex_class__c = 'AccountingCodeValidationBatch'    ,   
                                        Description__c = 'Validates the Accounting Codes for the given company. ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false   ));
        jobList.add( new Process_Job__c( name= 'AccountingEntryLine Delete',apex_class__c = 'AccountingEntryLineDeleteBatch'    ,   
                                        Description__c = 'Deletes draft accounting which are a 24hr old and not held by accounting batches for the given company. ',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false   ));
        jobList.add( new Process_Job__c( name= 'Hierarchy Path',apex_class__c = 'HierarchyPathBatch'    ,  Batch_Size__c = 18, 
                                        Description__c = 'Generates proper Path values from the Hierarchy relationships',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true   ));
        jobList.add( new Process_Job__c( name= 'Erase All MRP Runs',apex_class__c = 'EraseAllMRPRuns'    ,  Batch_Size__c = 2000, 
                                        Description__c = 'Erases all MRP records for MRP Runs with Completion Status Complete or Failure',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true   ));
        jobList.add( new Process_Job__c( name= 'Activate Proposed Costs',apex_class__c = 'ActivateProposedCostsBatch'    ,  Batch_Size__c = 200, 
                                        Description__c = 'Activate proposed costs by company or facility',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true   ));
        
        jobList.add( new Process_Job__c( name= 'Customer Invoice Aging',apex_class__c = 'CustomerAgingBatch'    ,  Batch_Size__c = 200, 
                                        Description__c = 'Provide Invoice againg for Bill To Customers',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true   ));                                
        jobList.add( new Process_Job__c( name= 'Delete Obsolete Accounting Entries',apex_class__c = 'AccountingDeleteObseleteEntriesBatch'    ,  Batch_Size__c = 200, 
                                        Description__c = 'Deletes all accounting entries that are marked as Obsolete or are within a period that allow for Obsolete accounting entries to be deleted.',    Interval__c = 1.0, Frequency__c = 'Days' , Active__c = true   ));                                
        jobList.add( new Process_Job__c( name= 'Customer Outstanding Balance',apex_class__c = 'CustomerOutstandingBalanceBatch',    
                                        Description__c = 'Calculates Outstanding balance ', Interval__c = 1.0, Frequency__c = 'Days' , Active__c = false ));
        jobList.add(new Process_Job__c(Name = 'Sales Order Allocation', Apex_Class__c = 'SalesOrderAllocate', Days_Ahead__c = 30, Active__c = true));     
        
        // fill in the company field on each job
        for (Process_Job__c j :jobList ) {              
        		j.Company__c = con.getId();   
        		j.Active__c = false ; // KNDY-6558   
    		}
        
        List<Process_Job__c> toCreate  = new List<Process_Job__c>(); 
        for (Process_Job__c p : jobList ) {
            if ( ! haveJobNameSet.contains(p.Apex_Class__c) ) { 
                toCreate.add( p);  /// only create the ones we don't have
            }
        }
        
        try { 
            
            DML.insertAsUser( toCreate ); 
            Apexpages.addMessage( new Apexpages.Message( Apexpages.Severity.INFO, Label.Default_Jobs_Created ) );
            
        } catch ( Exception e ) { 
            ApexPages.addMessages(e);
        }	
    }
    
    @ReadOnly    
    @RemoteAction
    public static String getAsyncCount() { 
        String asyncCount = '';
        try { 
            DateTime past24 = System.now().addHours(-24);

            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            SOQLUtil soql = new SOQLUtil('AsyncApexJob', true, true); //enforceFLS=true, running in user mode
            soql.addFields(new set<string>{
                'sum(TotalJobItems) total'
            });
            soql.setWhereClause('CreatedDate >= :past24');

            list<AggregateResult> ag = Database.query(soql.getQuery());
            asyncCount = Integer.valueOf( ag[0].get('total'))+'';
        } catch ( Exception ex) {
            System.debug( LoggingLevel.INFO, ex.getStackTraceString());
            asyncCount = ex.getStackTraceString();
        }
        return asyncCount;
    }
}
