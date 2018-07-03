/**
 * GenerateMRPbyFacilityExtV2 : Generate the MRP for the facility
 * This is accessible on the Facilities. 
 * 
 * Design: For generating the MRP, MRP Run is created in Salesforce
 * MRP Run id thus created will be sent to the heroku app to generate MRP records
 * MRPSettingsService will be used to block requests per company
 * 
 * Note that there is no leveling in salesforce. It happens in the heroku backend app
 * 
 */ 
public class GenerateMRPbyFacilityExtV2 {
    public  Id companyId { get;set;}
    public  ID facilityID { get;set;}
    public Facility__c fRec {get; set; } { fRec= new Facility__c();}
    public boolean runPlanning {get; set; } { runPlanning = false; }
    MRPSettingsService mrpSetting = new MRPSettingsService();
    String cfID;
    
    // Enable or disable the Generate MRP button based on the MRP Settings [custom settings]
    public Boolean isButtonDisabled { get{return mrpSetting.mrp_running ( cfID );}set;} 
    
    public GenerateMRPbyFacilityExtV2(ApexPages.StandardController controller) {        
        facilityID = controller.getId();
        
        if ( facilityId != null ) {
            // fetch all fields to show the defaults we will use on this run
            fRec = getFacility();
            companyID = fRec.Company__c;
            // pKey for the MRPSettingService 
	        cfID = companyID +'-' +facilityID; 
        }
    }
    
    public GenerateMRPbyFacilityExtV2( Id facilityId) {        
        this.facilityID = facilityId;
        
        if ( facilityId != null ) {
            // fetch all fields to show the defaults we will use on this run
            fRec = getFacility();
            companyID = fRec.Company__c;
            // pKey for the MRPSettingService 
	        cfID = companyID +'-' +facilityID; 
        }
    }
    
    Facility__c getFacility () {
        return [ SELECT id, name, Company__c, 
                            Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c,
                            MRP_Backward_Horizon_in_Days__c,
                            MRP_Demand_Time_Fence_in_Days__c,
                            MRP_Forward_Horizon_in_Days__c,
                            MRP_Planning_Time_Fence_in_Days__c,
                            Use_Order_Forecast_as_Demand_in_MRP__c,
                            Planning_Calendar__c,
                    		Planning_Calendar2__c,
                            Use_Purchase_Orders_as_Supply_in_MRP__c,
                            Use_Quantity_on_Hand_as_Supply_in_MRP__c,
                            Receiving_Calendar__c,
                    		Receiving_Calendar2__c,
                            Use_Sales_Orders_as_Demand_in_MRP__c,
                            Use_Work_Orders_as_Demand_in_MRP__c,
                            Use_Work_Orders_as_Supply_in_MRP__c,
                            Use_Transfer_Orders_as_Demand_in_MRP__c,
                            Use_Transfer_Orders_as_Supply_in_MRP__c
                       FROM Facility__c 
                      WHERE id = :facilityID
                      LIMIT 1 ];
    }
    
    public void generatePlan () {  
    	ApexPages.addMessage( generatePlanWorker() );   		
    } 
    
    private ApexPages.Message generatePlanWorker() { 
        // Checking for running mrp processes by company/facility 
        if (mrpSetting.mrp_running(cfId)) {
            return new ApexPages.Message(ApexPages.severity.FATAL, Label.MRP_is_currently_running );          
        }
        Savepoint sp = Database.setSavepoint( ) ;
        
        try {
            MRP_Run__c mrpRun = createMRPRun ();
            
            // send a request to the heroku backend to start the mrp generate process
            MRPService.startMRPGenerateFuture ( mrpRun.id  ) ;
            
            // block the mrp generate process on this company-facility
            mrpSemaphore();
        }
        catch (DmlException e) {
           Database.rollback(sp);
           return new  ApexPages.Message(ApexPages.severity.FATAL, e.getMessage());           
        }
        
        return new ApexPages.Message(ApexPages.Severity.INFO,Label.BatchEmail);          
    }
    
    public MRP_Run__c createMRPRun () {
        // Creating a new MRP Run
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
        mrpRun.Planning_Calendar2__c = fRec.Planning_Calendar2__c;
        mrpRun.Purchase_Orders_as_Supply__c = fRec.Use_Purchase_Orders_as_Supply_in_MRP__c;
        mrpRun.Quantity_on_Hand_as_Supply__c = fRec.Use_Quantity_on_Hand_as_Supply_in_MRP__c;
        mrpRun.Receiving_Calendar2__c = fRec.Receiving_Calendar2__c;
        mrpRun.Sales_Orders_as_Demand__c = fRec.Use_Sales_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Demand__c = fRec.Use_Work_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Supply__c = fRec.Use_Work_Orders_as_Supply_in_MRP__c;
        mrpRun.Transfer_Orders_as_Demand__c = fRec.Use_Transfer_Orders_as_Demand_in_MRP__c;
        mrpRun.Transfer_Orders_as_Supply__c = fRec.Use_Transfer_Orders_as_Supply_in_MRP__c;
        DML.insertAsUser(mrpRun);
        return mrpRun;
    }
    
    public void mrpSemaphore () {
        // block the mrp generate process on this company-facility
        mrpSetting.mrp_start(cfId);
    }
}