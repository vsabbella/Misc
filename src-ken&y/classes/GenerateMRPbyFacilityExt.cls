public with sharing class GenerateMRPbyFacilityExt implements Process.Runnable2 {
    
    public  Id companyId { get;set;}
    public  ID facilityID { get;set;}
    public boolean runPlanning {get; set; } { runPlanning = false; }
    MRPSettingsService MRPService = new MRPSettingsService();
    public Facility__c fRec {get; set; } { fRec= new Facility__c();}

    public GenerateMRPbyFacilityExt(ApexPages.StandardController controller) {        
        facilityID = controller.getId();			
        if ( facilityId != null ) {
            // fetch all fields to show the defaults we will use on this run
			/*
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			*/
			SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
			//KNDY-13342
            soql.addFields('MRPRun_RO');
            soql.addFields('MRPRun_WR');
			soql.setWhereClause('id = :facilityID');
			soql.setLimit(1);
			fRec = Database.query(soql.getQuery());

        }

        
    }
    
    public GenerateMRPbyFacilityExt() { } 			// Process.Runnable2 requires no arg constructor
    
    public void runBatch( Process_Job__c job ) {  	// called from master control program schedule job
        facilityID = job.Facility__c;				// get the facility id from the lookup on job record
        
        // fetch all fields in the event we are started from a scheduled job instead of a button PTM-383
		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		*/
		SOQLUtil soql = new SOQLUtil('Facility__c', true); //enforceFLS=true, running in user mode
		//KNDY-13342
        soql.addFields('MRPRun_RO');
        soql.addFields('MRPRun_WR');
		soql.setWhereClause('id = :facilityID');
		soql.setLimit(1);
		fRec = Database.query(soql.getQuery());

        ApexPages.Message myMsg = generatePlanWorker();
        
        MasterControlProgram.chatterDebug( 1, 'GenerateMRPbyFacilityExt : '+myMsg.getSummary() );
    }
    
    public void generatePlan () {  // planning , phase 2
    		// this is only called from VF page, should call addMessage()
   		ApexPages.addMessage( generatePlanWorker() );   		
    } 
    
    // KNDY-6379 
    // dont call addMessages(), cause: ApexPages.addMessage can only be called from a Visualforce
   	// refactor the work to be done here, returning a message about what happened
    private ApexPages.Message generatePlanWorker() { 
        ID PcalID, RcalID;
		
        
        companyID = fRec.Company__c;
        
        //  PTM-153 combine Facility and Company ID to allow simultaneous Facility MRPs to run
        String cfID = companyID +'-' +facilityID;        
    
        if (MRPService.mrp_running(cfId)) {
            return new ApexPages.Message(ApexPages.severity.FATAL, Label.MRP_is_currently_running );          
        }
        
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = companyID;
        mrpRun.Completion_Status__c = 'Running';
        mrpRun.Facility__c = facilityID;
        mrpRun.Failure_Message__c  = null;
        mrpRun.Level_Zero_QOH_as_Supply__c = fRec.Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c;
        mrpRun.MRP_Backward_Horizon_in_Days__c = fRec.MRP_Backward_Horizon_in_Days__c;
        mrpRun.MRP_Demand_Time_Fence_in_Days__c = fRec.MRP_Demand_Time_Fence_in_Days__c;
        mrpRun.MRP_Forward_Horizon_in_Days__c = fRec.MRP_Forward_Horizon_in_Days__c;
        mrpRun.MRP_Planning_Time_Fence_in_Days__c = fRec.MRP_Planning_Time_Fence_in_Days__c;
        mrpRun.Order_Forecast_as_Demand__c = fRec.Use_Order_Forecast_as_Demand_in_MRP__c;
        mrpRun.Planning_Calendar__c = fRec.Planning_Calendar__c;
        mrpRun.Purchase_Orders_as_Supply__c = fRec.Use_Purchase_Orders_as_Supply_in_MRP__c;
        mrpRun.Quantity_on_Hand_as_Supply__c = fRec.Use_Quantity_on_Hand_as_Supply_in_MRP__c;
        mrpRun.Receiving_Calendar__c = fRec.Receiving_Calendar__c;
        mrpRun.Sales_Orders_as_Demand__c = fRec.Use_Sales_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Demand__c = fRec.Use_Work_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Supply__c = fRec.Use_Work_Orders_as_Supply_in_MRP__c;
        try {
            DML.insertAsUser(mrpRun);
        }
        catch (DmlException e) {
           return new  ApexPages.Message(ApexPages.severity.FATAL, e.getMessage());           
        }
        
        runPlanning = true;

		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		*/
		SOQLUtil soql = new SOQLUtil('BusinessHours', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'Id'
		});
		soql.setWhereClause('isDefault = true');
		soql.setLimit(1);
		BusinessHours Pcal = Database.query(soql.getQuery());
		PcalID = Pcal.id;


        RcalID = PcalID;
        
        if (mrpRun.Planning_Calendar__c != null) {
            PcalID = mrpRun.Planning_Calendar__c;
            RcalID = PcalID;
        }
        
        if (mrpRun.Receiving_Calendar__c != null) RcalID = mrpRun.Receiving_Calendar__c;
                
        // KNDY-3080 if not using qoh skip GenerateSafetyDemand
        if (mrpRun.Level_Zero_QOH_as_Supply__c == true || mrpRun.Quantity_on_Hand_as_Supply__c == true) {
            // PTM-765 user defined batch size
            integer defaultBatchSize = 200;
            MRP_Batch_Sizes__c mrpbs = MRP_Batch_Sizes__c.getInstance('GenerateSafetyDemand');
            if (mrpbs != null) defaultBatchSize = integer.valueOf(mrpbs.Batch_Size__c);
                
            GenerateSafetyDemand obj = new GenerateSafetyDemand(mrpRun.ID, PcalID, RcalID);
            Database.executeBatch( obj, defaultBatchSize);
        }      
        else {
            // PTM-765 user defined batch size
            integer defaultBatchSize = 10;
            MRP_Batch_Sizes__c mrpbs = MRP_Batch_Sizes__c.getInstance('GenerateMRPTempData');
            if (mrpbs != null) defaultBatchSize = integer.valueOf(mrpbs.Batch_Size__c);
                
            GenerateMRPTempData obj1 = new GenerateMRPTempData(mrpRun.ID, PcalID, RcalID);
            Database.executeBatch( obj1, defaultBatchSize);
        }
        
        MRPService.mrp_start(cfID);       // notify the service we have started
        
        return new ApexPages.Message(ApexPages.Severity.INFO,Label.BatchEmail);          
    }

    /** 
     * used by the Apex Jobs component, just lists out async jobs
     * that are invloved in MRP
     */
    private List<String> planningClassNames = new List<String>{
            'GenerateMRPPlanData',
            'GenerateMRPTempData',
            'GenerateSafetyDemand','GenerateMRPEraseTemp',
            'ClearItemLevels','CleanFinalData','CreateNextLevel','ClearItemLevels'
            };
    public void IncrementCounter() {} 
    public List<AsyncApexJob> getApexJobList() { 
		/*
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		*/
		SOQLUtil soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'a.TotalJobItems','a.Status','a.ParentJobId','a.NumberOfErrors','a.MethodName','a.LastProcessedOffset','a.LastProcessed',
			'a.JobType','a.JobItemsProcessed','a.Id','a.ExtendedStatus','a.CreatedDate','a.CreatedById','a.CompletedDate','a.ApexClassId',
			'a.ApexClass.Name','a.ApexClass.NamespacePrefix'
		});
		soql.setWhereClause('a.ApexClass.Name in :planningClassNames');
		soql.setOrderByClause('a.CreatedDate desc');
		soql.setLimit(20);
		return Database.query(soql.getQuery());


    }
}