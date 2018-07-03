public with sharing class LotUpdateStatusBatch implements Database.batchable<sObject>,Database.stateful, Process.Runnable {
  
    public string query;
    public Id companyId;
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    public void runBatch( id CompanyId ) {      // Process.Runnable implementation 
        LotUpdateStatusBatch obj=new LotUpdateStatusBatch();
        obj.companyId = CompanyId;
        Id jobId=Database.executebatch(obj, 2000);
    }
    
    public LotUpdateStatusBatch(){

        query='select ID, Expiration_Date__c, Item__r.Class__c, Lot_Hold__c, Shelf_Life_Status__c '+
              'from Lot__c '+
              'where Company__c =: CompanyId and '+
              'Expiration_Date__c != null '+
              'and Item__r.Class__c != null '+
              'and Lot_Hold__c = false';      
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){         
        return Database.getQueryLocator(query);
    }
    
     public void execute(Database.BatchableContext info, List<Lot__c> scope){
     
         Date todaysdate;
         Set<ID> classSet = new Set<ID>();
         List<Lot__c> lotList = new List<Lot__c>();
         
         todaysdate = System.today();
         
         for (Lot__c lotObj : scope) {
             classSet.add(lotObj.Item__r.Class__c);
         }
        
        Map<ID, Class__c> classMap = new Map<ID, Class__c> ([select ID,
                                                             Status_1_Name__c, Status_1_Offset_Days__c,
                                                             Status_2_Name__c, Status_2_Offset_Days__c,
                                                             Status_3_Name__c, Status_3_Offset_Days__c
                                                             from Class__c
                                                             where Status_1_Offset_Days__c > 0 and
                                                             Status_2_Offset_Days__c != 0 and
                                                             Status_3_Offset_Days__c != 0 and
                                                             ID in: classSet]);
                                                             
        for (Lot__c lotObj : scope) {
            if (classMap.containsKey(lotObj.Item__r.Class__c)) {
                if (lotObj.Expiration_Date__c - (long)classMap.get(lotObj.Item__r.Class__c).Status_3_Offset_Days__c <= todaysdate) {
                    if (lotObj.Shelf_Life_Status__c != classMap.get(lotObj.Item__r.Class__c).Status_3_Name__c) {
                        lotObj.Shelf_Life_Status__c = classMap.get(lotObj.Item__r.Class__c).Status_3_Name__c;
                        lotObj.Lot_Hold__c = true;
                        lotList.add(lotObj);
                    }
                }
                else if (lotObj.Expiration_Date__c - (long)classMap.get(lotObj.Item__r.Class__c).Status_2_Offset_Days__c <= todaysdate) {
                         if (lotObj.Shelf_Life_Status__c != classMap.get(lotObj.Item__r.Class__c).Status_2_Name__c) {
                             lotObj.Shelf_Life_Status__c = classMap.get(lotObj.Item__r.Class__c).Status_2_Name__c;
                             lotList.add(lotObj);
                         }
                     }
                     else if (lotObj.Expiration_Date__c - (long)classMap.get(lotObj.Item__r.Class__c).Status_1_Offset_Days__c <= todaysdate) {
                              if (lotObj.Shelf_Life_Status__c != classMap.get(lotObj.Item__r.Class__c).Status_1_Name__c) {
                                  lotObj.Shelf_Life_Status__c = classMap.get(lotObj.Item__r.Class__c).Status_1_Name__c;                          
                                  lotList.add(lotObj);
                              }
                         }
                         else if (lotObj.Expiration_Date__c - (long)classMap.get(lotObj.Item__r.Class__c).Status_1_Offset_Days__c > todaysdate) {
                                  if (lotObj.Shelf_Life_Status__c != null) {
                                      lotObj.Shelf_Life_Status__c = null;                          
                                      lotList.add(lotObj);
                              }
                         }
            }             
        }
        
        update(lotList);
        
    }
    
    public void finish(Database.BatchableContext info){
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this ); 

    }
}