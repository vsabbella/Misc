/**
 * GenerateMRPExtV2 : Generate the MRP for the company
 * This is accessible on the Company. 
 * 
 * Design: For generating the MRP, MRP Run is created in Salesforce
 * MRP Run id thus created will be sent to the heroku app to generate MRP records
 * MRPSettingsService will be used to block requests per company
 * 
 * Note that there is no leveling in salesforce. It happens in the heroku backend app
 * 
 */ 
public with sharing class GenerateMRPExtV2 {
    MRPSettingsService settings = new MRPSettingsService () ;
    ApexPages.StandardController con;
    Company__c cRec ; 
    
    // Enable or disable the Generate MRP button based on the MRP Settings [custom settings]
    public Boolean isButtonDisabled { get{
        
        if ( GatewayExt.isUserAuthorized() == false ) {
            ApexPages.addMessage( new ApexPages.Message ( ApexPages.Severity.FATAL , 'Please authorize for Kenandy Gateway. Goto All Tabs > Getting Around > Manage Defaults > Authorize External App > Authorize' ) ) ;
            return true;
        }
        
        // TODO Change to status Complete 
        return settings.mrp_running(cRec.Id) ;
    } set;} 
    
    public GenerateMRPExtV2 ( ApexPages.StandardController con ) { 
        this.con = con ;  
        cRec = (Company__c)con.getRecord();
    }
    
    public GenerateMRPExtV2 ( Id companyId  ) {
        try {
            SOQLUtil util = new SOQLUtil ( 'Company__c', true);
            util.addFields ( new Set<String> {
               'Planning_Calendar2__c','Receiving_Calendar2__c', 'Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c', 'MRP_Backward_Horizon_in_Days__c',
               'MRP_Demand_Time_Fence_in_Days__c', 'MRP_Forward_Horizon_in_Days__c', 'MRP_Planning_Time_Fence_in_Days__c','Use_Order_Forecast_as_Demand_in_MRP__c',
               'Use_Purchase_Orders_as_Supply_in_MRP__c', 'Use_Quantity_on_Hand_as_Supply_in_MRP__c', 'Use_Sales_Orders_as_Demand_in_MRP__c',
               'Use_Work_Orders_as_Demand_in_MRP__c', 'Use_Work_Orders_as_Supply_in_MRP__c','Use_Transfer_Orders_as_Demand_in_MRP__c',
               'Use_Transfer_Orders_as_Supply_in_MRP__c'
            });
            util.setWhereClause('Id = :companyId');
            cRec = Database.query ( util.getQuery() );
        } catch ( Exception e ) {
            ApexPages.addMessage( new ApexPages.Message ( ApexPages.Severity.FATAL , MessageUtil.toFriendlyErrorMessage(e.getMessage()) ) ) ;
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
    }
    
    // Initiates the mrp plan generate process
    public void generatePlan () {
        if (settings.mrp_running(cRec.Id )) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, Label.MRP_is_currently_running )) ;
            return ;          
        }
        
        // Checking for running mrp processes by company
        Savepoint sp = Database.setSavepoint() ; 
        
        
        try {
            MRP_Run__c mrpRun = createMRPRun ();
            
            // send a request to the heroku backend to start the mrp generate process
            MRPService.startMRPGenerateFuture ( mrpRun.id  ) ;
            
            mrpSemaphore ();
            
            ApexPages.addMessage( new ApexPages.Message ( ApexPages.Severity.INFO , Label.BatchEmail) ) ;
            
            // TODO post to chatter, email blah blah 
        }
        catch ( Exception e ) {
            Database.rollback(sp) ;
            ApexPages.addMessage( new ApexPages.Message ( ApexPages.Severity.FATAL , MessageUtil.toFriendlyErrorMessage(e.getMessage()) ) ) ;
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
    
    public MRP_Run__c createMRPRun () {
        // Create a MRP Run record
        MRP_Run__c mrpRun = new MRP_Run__c();
        mrpRun.Company__c = cRec.Id;
        mrpRun.Completion_Status__c = MRPService.STATUS_RUNNING ;
        mrpRun.Facility__c = null; // TODO support for facility
        mrpRun.Failure_Message__c  = null;
        mrpRun.Planning_Calendar2__c = cRec.Planning_Calendar2__c;
        mrpRun.Receiving_Calendar2__c = cRec.Receiving_Calendar2__c;
        mrpRun.Level_Zero_QOH_as_Supply__c = cRec.Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c;
        mrpRun.MRP_Backward_Horizon_in_Days__c = cRec.MRP_Backward_Horizon_in_Days__c;
        mrpRun.MRP_Demand_Time_Fence_in_Days__c = cRec.MRP_Demand_Time_Fence_in_Days__c;
        mrpRun.MRP_Forward_Horizon_in_Days__c = cRec.MRP_Forward_Horizon_in_Days__c;
        mrpRun.MRP_Planning_Time_Fence_in_Days__c = cRec.MRP_Planning_Time_Fence_in_Days__c;
        mrpRun.Order_Forecast_as_Demand__c = cRec.Use_Order_Forecast_as_Demand_in_MRP__c;
        mrpRun.Purchase_Orders_as_Supply__c = cRec.Use_Purchase_Orders_as_Supply_in_MRP__c;
        mrpRun.Quantity_on_Hand_as_Supply__c = cRec.Use_Quantity_on_Hand_as_Supply_in_MRP__c;
        mrpRun.Sales_Orders_as_Demand__c = cRec.Use_Sales_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Demand__c = cRec.Use_Work_Orders_as_Demand_in_MRP__c;
        mrpRun.Work_Orders_as_Supply__c = cRec.Use_Work_Orders_as_Supply_in_MRP__c;
        mrpRun.Transfer_Orders_as_Demand__c = cRec.Use_Transfer_Orders_as_Demand_in_MRP__c;
        mrpRun.Transfer_Orders_as_Supply__c = cRec.Use_Transfer_Orders_as_Supply_in_MRP__c;
        DML.insertAsUser(mrpRun);
        return mrpRun;
    }
    
    public void mrpSemaphore () {
        // block the mrp generate process on this company
        settings.mrp_start(cRec.Id);
    }
}