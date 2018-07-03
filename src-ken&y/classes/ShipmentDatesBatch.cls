/*
*	@description	This batch re-assigns the estimated shipment dates on shipments that have an 
*					expired estimated shipment date and are not shipped yet.(KNDY-4117) 
*/
public with sharing class ShipmentDatesBatch implements Database.batchable<sObject>, Process.Runnable{
	
	public String scopeQuery;
    public set<Id> operatingCompanyIds = new set<Id>();
    Date dateToday;

    public List<Notify.Message> messages = new List<Notify.Message>();
    
    public ShipmentDatesBatch(set<Id> operatingCompIds){
        operatingCompanyIds = operatingCompIds;
    }
      
    public Database.QueryLocator start(Database.BatchableContext BC){   
        dateToday = system.today();
        
        // Get all the shipments that have an estimated shipment date in the past
        // and are not shipped yet.
        scopeQuery= 'SELECT Id '+ 
                    '  FROM Shipment__c '+
                    ' WHERE Has_Exceptions__c = false '+
                    '   AND Company__c IN :operatingCompanyIds '+
                    '   AND ( Shipment_Date_Estimated__c <= :dateToday OR Shipment_Date_Estimated__c = null ) '+ 
                    '   AND ( Status__c !=  \'Confirmed\' OR Status__c !=  \'Delivered\' ) ';
                    
        return Database.getQueryLocator(scopeQuery);
    }
    
    public void execute(Database.BatchableContext info, List<Shipment__c> scope){
    	Set<Id> shipmentIds = new Set<Id>();
    	
    	for(Shipment__c shipment : scope){
    		shipmentIds.add(shipment.Id);
    	}
    	
    	if(shipmentIds.size() > 0){
    		// Save the shipments so that the trigger re-assigns the estimated dates on the shipments.
    		List<Shipment__c> updateShipments = new List<Shipment__c>();
    		
    		for(Id shipmentId : shipmentIds){
    			Shipment__c newShipment = new Shipment__c();
    			newShipment.Id = shipmentId;
        		updateShipments.add(newShipment);
        		
    		}
    		ShipmentService.setShipmentDates(shipmentIds);
    	}
    }
        
    public void finish(Database.BatchableContext info){
        BatchToChatter.processBatchInformation(info.getJobId(), this, messages);
        Notify.sendEmailBatchFinish( null, messages, info);        
        MasterControlProgram.finishedBatch( this );
    }
    
    // newInstance(); needs a no-arg consturctor     
  	public ShipmentDatesBatch() {
  	
  	}    
 	
 	public void runBatch( Id companyId ) {
		ShipmentDatesBatch batchInstance = new ShipmentDatesBatch(new Set<Id>{ companyId });
        Id jobId=Database.executebatch(batchInstance, 200);
 	} 
}