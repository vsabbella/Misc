public with sharing class ConfigureOTCExt {
    
    public SettingProxy otc {get; set;}
    
    public ConfigureOTCExt (ApexPages.StandardController con) {        init();    }
    
    void init() {
        Id companyId = ApexPages.currentPage().getParameters().get('id');
        String configName = AllowanceRuleService.getOTCConfigKeyForCompanyId (companyId);
        OTC__c tmp = OTC__c.getInstance(configName);        
        if (tmp != null) {
            otc = new SettingProxy(tmp);
        } else {
            otc = new SettingProxy(new Otc__c(Name=configName));
        }
    }
    
    public void onSave(){ 
        try {
            if (otc.Id != null) {
                DML.updateAsSystem(otc.getOTCSetting()); //intended to allow save for non admin user
                Id companyId = ApexPages.currentPage().getParameters().get('id');
                // Note: Using a future method for now, in case we hit limits we can move to something else.
                TransitRouteService.updateAllTransitRoutesForCompany(companyId);
            } else {
                otc.insertSetting();
            }
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Configuration_updated ));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, Label.Updating_relevant_Transit_Routes_in_a_background_process ));
            init();
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.FATAL, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
    
    public class SettingProxy {  
        public Id Id {get;set;}
        public String Name {get;set;}
        public boolean Parent_Level_Freight_Allowances_Only {get; set; }
        //public Decimal Fuel_Allowance_Preference_None  {get; set;}
        public Decimal Fuel_Allowance_Preference_Weekly  {get; set;}
        public Decimal Fuel_Allowance_Preference_Monthly  {get; set;}
        public Decimal Fuel_Allowance_Preference_Quarterly {get; set;}
        //public Decimal Distance_Rate_Preference_None {get; set; }
        public Decimal Distance_Rate_Preference_Weekly {get; set; }
        public Decimal Distance_Rate_Preference_Monthly {get; set; }
        public Decimal Distance_Rate_Preference_Quarterly  {get; set; }
        public Integer Max_Lines_for_Sync_order_release{get; set;}
        
        public boolean Customer_Credit_Hold_Check_At_Allocate {get; set;}
        public SettingProxy(OTC__c record) {
            this.Id = record.Id;
            this.Name = record.Name;
            this.Parent_Level_Freight_Allowances_Only = record.Parent_Level_Freight_Allowances_Only__c;
            //this.Fuel_Allowance_Preference_None = record.Fuel_Allowance_Preference_None__c;
            this.Fuel_Allowance_Preference_Weekly = record.Fuel_Allowance_Preference_Weekly__c;
            this.Fuel_Allowance_Preference_Monthly = record.Fuel_Allowance_Preference_Monthly__c;
            this.Fuel_Allowance_Preference_Quarterly = record.Fuel_Allowance_Preference_Quarterly__c;
            //this.Distance_Rate_Preference_None = record.Distance_Rate_Preference_None__c;
            this.Distance_Rate_Preference_Weekly = record.Distance_Rate_Preference_Weekly__c;
            this.Distance_Rate_Preference_Monthly = record.Distance_Rate_Preference_Monthly__c;
            this.Distance_Rate_Preference_Quarterly = record.Distance_Rate_Preference_Quarterly__c;
            
            this.Customer_Credit_Hold_Check_At_Allocate = record.Customer_Credit_Hold_Check_At_Allocate__c;
            
            if(record.Max_Lines_for_Sync_order_release__c != Null || record.Max_Lines_for_Sync_order_release__c != 0){
				
				this.Max_Lines_for_Sync_order_release = Integer.valueOf(KSE.addQuantityToField(record.Max_Lines_for_Sync_order_release__c, 0));
			}
        }
        
        public SettingProxy() {}
        
        public otc__c getOTCSetting() {
        	
            Otc__c OTCSetting = new otc__c(
					                Id = this.Id,
					                Name = this.Name,
					                Parent_Level_Freight_Allowances_Only__c = this.Parent_Level_Freight_Allowances_Only,
					                //Fuel_Allowance_Preference_None__c = this.Fuel_Allowance_Preference_None,
					                Fuel_Allowance_Preference_Weekly__c = this.Fuel_Allowance_Preference_Weekly,
					                Fuel_Allowance_Preference_Monthly__c = this.Fuel_Allowance_Preference_Monthly,
					                Fuel_Allowance_Preference_Quarterly__c = this.Fuel_Allowance_Preference_Quarterly,
					                //Distance_Rate_Preference_None__c = this.Distance_Rate_Preference_None,
					                Distance_Rate_Preference_Weekly__c = this.Distance_Rate_Preference_Weekly,
					                Distance_Rate_Preference_Monthly__c = this.Distance_Rate_Preference_Monthly,
					                Distance_Rate_Preference_Quarterly__c = this.Distance_Rate_Preference_Quarterly,
					                
					                Customer_Credit_Hold_Check_At_Allocate__c = this.Customer_Credit_Hold_Check_At_Allocate
					                
					                //Max_Lines_for_Sync_order_release__c = Integer.valueOf(this.Minimum_Lines_for_Async_order_release)
					            );
			
			if(this.Max_Lines_for_Sync_order_release != Null || this.Max_Lines_for_Sync_order_release != 0){
				
				OTCSetting.Max_Lines_for_Sync_order_release__c = Integer.valueOf(KSE.addQuantityToField(this.Max_Lines_for_Sync_order_release, 0));
			}
					            
			return OTCSetting;
        }
        
        public void insertSetting() {
            otc__c sdp = this.getOTCSetting();
            DML.insertAsSystem(sdp); //intended to allow insert for non admin user
            this.Id = sdp.Id;
        }
        
    }
    
}