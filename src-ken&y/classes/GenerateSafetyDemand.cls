/**
 * @description build MRP temp demand for items which are below safety stock, 
 * This class creates all the demands due to (Below safety and lot sizing) 
 * or negative quantity on hand. It is initiated from the ScheduleCreateMRPTemps class.
 */
//public class GenerateSafetyDemand {}

public with sharing class GenerateSafetyDemand implements Database.batchable<sObject>,Database.stateful {
    
    //iterate through the items which doesn't exist as assembly 
    Date todaysDate;
    public String query;
    public Id companyId;
    public ID facilityID;
    public ID mrpRunID, PcalID, RcalID;
    List<MRP_Run__c> mrpRun = new List<MRP_Run__c>();
    public String errMsg;
    
    public GenerateSafetyDemand( Id mrpRID, ID PclID, ID RclID ){
        this.mrpRunID = mrpRID;
        this.PcalID = PclID;
        this.RcalID = RclID;
        
        errMsg = '';
        
       // Get current business day     
        todaysDate=KSE.calculateStartDate(Date.today(), 0, PcalID);
        
/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
SOQLUtil soql = new SOQLUtil('MRP_Run__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'ID','Name','Company__c','Facility__c','Level_Zero_QOH_as_Supply__c'
});
soql.setWhereClause('ID =: mrpRunID');
mrpRun = Database.query(soql.getQuery());


        this.companyID = mrpRun[0].Company__c;
        this.facilityID = mrpRun[0].Facility__c;
        
        query='select Id, Company__c, Safety_Stock__c, Use_Lot_Sizing__c from Item__c ' +
                'where Active__c = true and ' + 
                'Non_Inventory__c <> true and ' + 
                'Company__c=:companyId ';
        if (mrpRun[0].Level_Zero_QOH_as_Supply__c == true) query = query + 'and Level__c = 0 ';
        
        if ( Test.isRunningTest( ) ) query +=' limit 200';
        
    }
  
    public Database.QueryLocator start(Database.BatchableContext BC){      
        system.assert( this.companyId != null, 'GenerateSafetyDemand expected company ID set');        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext info, List<Item__c> itemList){ 
      
        list<MRP__c> insertList=new list<MRP__c>();
        Map < Id, Nettable.NETcount > netMap = new Map < Id, Nettable.NETcount >();
        Set <ID> itemSet = new Set <ID>();
        Map<ID, Facility_Item__c> facilityItemMap = new Map<ID, Facility_Item__c>();
        Boolean UseLotSizing;
        Double SafetyStock;
        
        try {
           
            if (facilityID == null) { // by company
                netMap = Nettable.getNettable( itemList );
            }
            else { // by facility
                netMap = Nettable.getNettableByFacility( itemList, facilityID );
            
                // get facility item info
                for (Item__c itemObj : itemList) itemSet.add(itemObj.ID);


/*
//KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
                */
SOQLUtil soql = new SOQLUtil('Facility_Item__c', true); //enforceFLS=true, running in user mode
soql.addFields(new set<string>{
	'ID','Item__c','Safety_Stock__c','Use_Lot_Sizing__c'
});
soql.setWhereClause('Item__c in: itemSet and Active__c = true and Facility__c =: facilityID');
                for (Facility_Item__c fi : Database.query(soql.getQuery())){



                    facilityItemMap.put(fi.Item__c, fi);
                }
            }
        
            for ( Item__c itemObject : itemList ) {                                              
            
                Nettable.NETcount tmp = netMap.get(itemObject.id);
                Double quantityNettable = 0;
            
                if ( tmp != null ) {
                    quantityNettable = tmp.nettable;
                } 
                else {
                    // debug( LoggingLevel.INFO , 'for item ' +itemObject.id + ' the nettable is null');
                }
            
// Quantity on Hand             
                if (quantityNettable > 0.0) {
                    MRP__c MRPTempObject = new MRP__c();
                    MRPTempObject.Item__c = itemObject.Id;
                    MRPTempObject.Demand__c = 'Quantity on Hand';
                    MRPTempObject.Required_Date__c = todaysDate;
                    MRPTempObject.Is_Demand__c = false;
                    MRPTempObject.Start_Date__c = null;
                    MRPTempObject.Company__c = this.companyID; 
                    MRPTempObject.Facility__c = facilityID;
// KNDY-6125 lookup to MRP_Run                  
                    MRPTempObject.MRP_Run__c = mrpRunID;
                    MRPTempObject.Planned__c = false;
                    MRPTempObject.Quantity__c = quantityNettable;
                    MRPTempObject.Modified_Quantity__c = quantityNettable;
                
                    insertList.add(MRPTempObject);
                }
            
                MRP__c MRPTempObject = new MRP__c();
                MRPTempObject.Item__c = itemObject.Id;
                MRPTempObject.Required_Date__c = todaysDate;
                MRPTempObject.Is_Demand__c = true;
                MRPTempObject.Start_Date__c = null;
                MRPTempObject.Company__c = this.companyID;
                MRPTempObject.Facility__c = facilityID;
// KNDY-6125 lookup to MRP_Run              
                MRPTempObject.MRP_Run__c = mrpRunID;
                MRPTempObject.Planned__c = false;
            
// Safety Stock Check
                // default to Company/Item settings
                UseLotSizing = itemObject.Use_Lot_Sizing__c;
                if (itemObject.Safety_Stock__c > 0.0) SafetyStock = itemObject.Safety_Stock__c;
                else SafetyStock = 0;
            
                if (facilityID != null) { // by facility
                    if (facilityItemMap.containsKey(itemObject.ID)) {
                        Facility_Item__c fi = facilityItemMap.get(itemObject.ID);
                        UseLotSizing = fi.Use_Lot_Sizing__c;
                        if (fi.Safety_Stock__c > 0.0) SafetyStock = fi.Safety_Stock__c;
                        else SafetyStock = 0;
                        // PTM-373 added MRP lookup to Facility_Item__c
                        MRPTempObject.Facility_Item__c = fi.ID;
                        
                    }
                }
        
//  KNDY-486 Always consider Safety Stock
                if (UseLotSizing && SafetyStock > 0.0) {
                    MRPTempObject.Demand__c = 'Below Safety Stock';
                    MRPTempObject.Quantity__c = SafetyStock;
                    MRPTempObject.Modified_Quantity__c = SafetyStock;                
                    // .debug( LoggingLevel.INFO , 'adding  ' + MRPTempObject ); 
                
                    insertList.add(MRPTempObject);                                                                      
                }
// Negative Quantity on Hand             
                else {
                    if (quantityNettable < 0.0) {
                        MRPTempObject.Demand__c='Negative QOH';
                        MRPTempObject.Quantity__c = -quantityNettable;
                        MRPTempObject.Modified_Quantity__c = -quantityNettable;
                     
                        insertList.add(MRPTempObject);
                    }
                }
            }
        }
        catch (Exception e) {
            errMsg = errMsg +e.getMessage()+','+e.getStackTraceString();
            throw e;
        }
              
        DML.insertAsUser(insertList);  //KNDY-3586
    }
    
    public void finish(Database.BatchableContext info) {
        
        String msg;

        if (errmsg.length() > 0) {
            //show MRP completed
            MRPSettingsService MRPService = new MRPSettingsService();
            String cfID = companyID;
            if (facilityID != null) cfID = companyID +'-' +facilityID;
            MRPService.mrp_complete(cfID);
            
            msg = 'MRPSafteyDemand for run: ' +mrpRun[0].Name +' Failed with error: ' +errMsg;
            KSE.sendEmailBatchCompletion(msg);
            // PTM-377 MRP_Run status
            mrpRun[0].Completion_Status__c = 'Failure';
            mrpRun[0].Failure_Message__c = errMsg;
            DML.updateAsUser(mrpRun);
        }
        else if ( ! Test.isRunningTest() ) {  // don't chain these if called from a test method   
                // PTM-157 with many skids in the system, we must lower this from default 2000 items at a time
                // 10 is a safer number but could still result in a DML limit fail (> 10,000 MRP records inserted in one batch)
                // PTM-765 user defined batch size
                integer defaultBatchSize = 10;
                MRP_Batch_Sizes__c mrpbs = MRP_Batch_Sizes__c.getInstance('GenerateMRPTempData');
                if (mrpbs != null) defaultBatchSize = integer.valueOf(mrpbs.Batch_Size__c);
                
                GenerateMRPTempData obj = new GenerateMRPTempData(this.mrpRunID, this.PcalID, this.RcalID); 
                Id jobid = Database.executeBatch( obj, defaultBatchSize);
        }
    }
}