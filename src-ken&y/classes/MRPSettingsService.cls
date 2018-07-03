public with sharing class MRPSettingsService {

    public MRP_Settings__c mrpsettings = new MRP_Settings__c();
    Company__c c = new Company__c();    
    
    void getmrpsettings(String cID) {

        mrpsettings = MRP_Settings__c.getInstance(cID);
        if (mrpsettings == null) {
            mrpsettings = new MRP_Settings__c();
            mrpsettings.Name = cID;
            mrpsettings.Company_Name__c = cID;            
            mrpsettings.End_Date_Time__c = null;
            mrpsettings.Erase_Complete_Date_Time__c = null;
            mrpsettings.Previous_End_Date_Time__c = null;
            mrpsettings.Previous_Start_Date_Time__c = null;            
            mrpsettings.Running__c = false;
            mrpsettings.Start_Date_Time__c = system.now();
            mrpsettings.Temp_Complete_Date_Time__c = null;
            
            DML.insertAsSystem(mrpsettings);
        }
    }
    
    public boolean mrp_running(String cID) {

        getmrpsettings(cID);
        return (mrpsettings.Running__c == true);        
    } 
    
    public void mrp_start(String cID) {
    
        getmrpsettings(cID);
        
        mrpsettings.Previous_End_Date_Time__c = mrpsettings.End_Date_Time__c;
        mrpsettings.Previous_Start_Date_Time__c = mrpsettings.Start_Date_Time__c;
            
        mrpsettings.End_Date_Time__c = null;
        mrpsettings.Erase_Complete_Date_Time__c = null;
        mrpsettings.Running__c = true;
        mrpsettings.Start_Date_Time__c = system.now();
        mrpsettings.Temp_Complete_Date_Time__c = null;

        DML.updateAsSystem(mrpsettings);
    }
    
    public void mrp_erased(String cID) {
    
        getmrpsettings(cID);
        mrpsettings.Erase_Complete_Date_Time__c = system.now();

        DML.updateAsSystem(mrpsettings);
    }
    
    public void mrp_temped(String cID) {
    
        getmrpsettings(cID);
        mrpsettings.Temp_Complete_Date_Time__c = system.now();

        DML.updateAsSystem(mrpsettings);
    }  
    
    public void mrp_complete(String cID) {
    
        getmrpsettings(cID);
        mrpsettings.End_Date_Time__c = system.now();
        mrpsettings.Running__c = false;

        DML.updateAsSystem(mrpsettings);
    }
    
    public DateTime getmrpsettingstemp(String cID) {

        mrpsettings = MRP_Settings__c.getInstance(cID);
        if (mrpsettings == null) {
            return null;
        }
        return mrpsettings.Temp_Complete_Date_Time__c;
    }
    
}