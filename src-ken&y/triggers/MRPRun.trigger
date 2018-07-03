/**
 * Trigger on MRP Run object
 *  @author Sunil
 * 
 */
trigger MRPRun on MRP_Run__c ( after update ) {
    
    if(DML.checkTriggerDispatch(MRP_Run__c.getSobjectType())){return;}
    
    // MRP run batch job should not trigger the emailer
    if ( Trigger.isUpdate && System.isBatch() == false ) {
        //This will send out an email to the whoever started the MRP Run
        //This will be executed only if user is running the MRP Run V2 (GenerateMRPV2/GenerateMRPByFacilityV2) pages
        MRPService.sendEmailAfterJobCompletion ( Trigger.newMap ) ;
    }
}