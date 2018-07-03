public with sharing class GenerateMRP {
    
    public class ItemLevel  implements Process.Runnable {
        public ItemLevel() {}
        public void runBatch( id CompanyId ) {
            ClearItemLevels Obj=new ClearItemLevels();
            obj.companyId=CompanyId;
            Id jobId=Database.executebatch(obj,2000);
        }  
    }
    
    public class Planning  implements Process.Runnable {
        public Planning() {}
        
        public void runBatch( id CompanyId ) {
            
            ID PcalID, RcalID;
            
            MRPSettingsService MRPService = new MRPSettingsService();
//  PTM-153 combine Facility and Company ID to allow simultaneous Facility MRPs to run            
            String cfID = CompanyId; 
            if (MRPService.mrp_running(cfID)) {
                throw new GenerateMRPException('Planning already running');
            }
            

/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
            */
SOQLUtil soql = new SOQLUtil('Company__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'ID','Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c','MRP_Backward_Horizon_in_Days__c','MRP_Demand_Time_Fence_in_Days__c','MRP_Forward_Horizon_in_Days__c',
	'MRP_Planning_Time_Fence_in_Days__c','Use_Order_Forecast_as_Demand_in_MRP__c','Planning_Calendar__c','Use_Purchase_Orders_as_Supply_in_MRP__c',
	'Use_Quantity_on_Hand_as_Supply_in_MRP__c','Receiving_Calendar__c','Use_Sales_Orders_as_Demand_in_MRP__c','Use_Work_Orders_as_Demand_in_MRP__c',
	'Use_Work_Orders_as_Supply_in_MRP__c'
});
soql.setWhereClause('ID =: CompanyId');
List<Company__c> cList = Database.query(soql.getQuery());
            
            MRP_Run__c mrpRun = new MRP_Run__c();
            mrpRun.Company__c = companyID;
            mrpRun.Completion_Status__c = 'Running';
            mrpRun.Facility__c = null;
            mrpRun.Failure_Message__c  = null;
            mrpRun.Level_Zero_QOH_as_Supply__c = cList[0].Use_Only_Level_Zero_QOH_as_Supply_in_MRP__c;
            mrpRun.MRP_Backward_Horizon_in_Days__c = cList[0].MRP_Backward_Horizon_in_Days__c;
            mrpRun.MRP_Demand_Time_Fence_in_Days__c = cList[0].MRP_Demand_Time_Fence_in_Days__c;
            mrpRun.MRP_Forward_Horizon_in_Days__c = cList[0].MRP_Forward_Horizon_in_Days__c;
            mrpRun.MRP_Planning_Time_Fence_in_Days__c = cList[0].MRP_Planning_Time_Fence_in_Days__c;
            mrpRun.Order_Forecast_as_Demand__c = cList[0].Use_Order_Forecast_as_Demand_in_MRP__c;
            mrpRun.Planning_Calendar__c = cList[0].Planning_Calendar__c;
            mrpRun.Purchase_Orders_as_Supply__c = cList[0].Use_Purchase_Orders_as_Supply_in_MRP__c;
            mrpRun.Quantity_on_Hand_as_Supply__c = cList[0].Use_Quantity_on_Hand_as_Supply_in_MRP__c;
            mrpRun.Receiving_Calendar__c = cList[0].Receiving_Calendar__c;
            mrpRun.Sales_Orders_as_Demand__c = cList[0].Use_Sales_Orders_as_Demand_in_MRP__c;
            mrpRun.Work_Orders_as_Demand__c = cList[0].Use_Work_Orders_as_Demand_in_MRP__c;
            mrpRun.Work_Orders_as_Supply__c = cList[0].Use_Work_Orders_as_Supply_in_MRP__c;
            try {
                DML.insertAsUser(mrpRun);
            }
            catch (DmlException e) {
                throw new GenerateMRPException(e);
            }

            // default calendars to the default calendar
			//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			soql = new SOQLUtil('BusinessHours', true); //enforceFLS=true, running in user mode
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
        }
    }
    
    public class GenerateMRPException extends Exception {} 
}