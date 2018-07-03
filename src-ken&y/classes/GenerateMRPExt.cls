public with sharing class GenerateMRPExt  {
    public  Id companyId { get;set;}
    public  ID facilityID { get;set;}
    public boolean runLeveling {get; set; } { runLeveling = false; } 
    public boolean runPlanning {get; set; } { runPlanning = false; }
    MRPSettingsService MRPService = new MRPSettingsService();
    Company__c cRec = new Company__c();
    
    ApexPages.StandardController con;
    
    public GenerateMRPExt(ApexPages.StandardController controller) {     
        con = controller; 
        //PTM-440 move retrival of company id to constructor
        cRec = (Company__c)con.getRecord();
        companyID = cRec.ID;
        facilityID = null;
    }
    
    public GenerateMRPExt() { }
     
    public void generatePlan () {  // planning , phase 2
    
        ID PcalID, RcalID;
    
    //  PTM-153 combine Facility and Company ID to allow simultaneous Facility MRPs to run
        String cfID = companyID;
        if (MRPService.mrp_running(cfId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.MRP_is_currently_running));            
            return;
        }

        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = companyID;
        mrpRun.Completion_Status__c = 'Running';
        mrpRun.Facility__c = null;
        mrpRun.Failure_Message__c  = null;
        mrpRun.Level_Zero_QOH_as_Supply__c = cRec.Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c;
        mrpRun.MRP_Backward_Horizon_in_Days__c = cRec.MRP_Backward_Horizon_in_Days__c;
        mrpRun.MRP_Demand_Time_Fence_in_Days__c = cRec.MRP_Demand_Time_Fence_in_Days__c;
        mrpRun.MRP_Forward_Horizon_in_Days__c = cRec.MRP_Forward_Horizon_in_Days__c;
        mrpRun.MRP_Planning_Time_Fence_in_Days__c = cRec.MRP_Planning_Time_Fence_in_Days__c;
        mrpRun.Order_Forecast_as_Demand__c = cRec.Use_Order_Forecast_as_Demand_in_MRP__c;
        mrpRun.Planning_Calendar__c = cRec.Planning_Calendar__c;
        mrpRun.Purchase_Orders_as_Supply__c = cRec.Use_Purchase_Orders_as_Supply_in_MRP__c;
        mrpRun.Quantity_on_Hand_as_Supply__c = cRec.Use_Quantity_on_Hand_as_Supply_in_MRP__c;
        mrpRun.Receiving_Calendar__c = cRec.Receiving_Calendar__c;
        mrpRun.Sales_Orders_as_Demand__c = cRec.Use_Sales_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Demand__c = cRec.Use_Work_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Supply__c = cRec.Use_Work_Orders_as_Supply_in_MRP__c;
        try {
            DML.insertAsUser(mrpRun);
        }
        catch (DmlException e) {
           ApexPages.addMessages(e);
           return;
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
        
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,Label.BatchEmail);        
        ApexPages.addMessage(myMsg);
    }
    
    public void generateItemLevel () {  // all starts here
        runLeveling = true;
        ClearItemLevels Obj=new ClearItemLevels();
        obj.companyId=companyId;
        Database.executebatch(obj,2000);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,Label.BatchEmail) );              
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
		//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
		SOQLUtil soql = new SOQLUtil('AsyncApexJob', true); //enforceFLS=true, running in user mode
		soql.addFields(new set<string>{
			'TotalJobItems','Status','ParentJobId','NumberOfErrors','MethodName','LastProcessedOffset','LastProcessed',
			'JobType','JobItemsProcessed','Id','ExtendedStatus','CreatedDate','CreatedById','CompletedDate','ApexClassId',
			'ApexClass.Name','ApexClass.NamespacePrefix'
		});
		soql.setWhereClause('ApexClass.Name in :planningClassNames');
		soql.setOrderByClause('CreatedDate desc');
		soql.setLimit(20);
		return Database.query(soql.getQuery());
    }
}