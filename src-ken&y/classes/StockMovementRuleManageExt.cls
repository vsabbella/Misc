public with sharing class StockMovementRuleManageExt {
    
    public Stock_Movement_Rule__c smr { get; set;}
    public List<Stock_Movement_Rule__c> smrList { get; set; } { smrList = new List<Stock_Movement_Rule__c>(); }
    ApexPages.StandardController con;
    public class StockMovementRuleManageExtException extends Exception{}
    
    public StockMovementRuleManageExt(ApexPages.StandardController controller) {
        con = controller;
        
        if( controller.getRecord().id != null ){
            smr = (Stock_Movement_Rule__c) controller.getRecord();
            
            if (ApexPages.currentPage().getParameters().get('clone') == '1')
            	smr.Id = null;
            
            list<Id> locList;
            if( smr.Location_List__c != null ){
                try{
                    locList = (list<Id>)JSON.deserialize(String.valueOf(smr.get('Location_List__c')), list<Id>.Class);
                }
                catch(Exception e){
                    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, 'Invalid location specified on stock movement rule :'+smr.get('name') ));
                    locList = null;
                }
            }
            
            if( locList != null && locList.size() > 0){
                smr.Location__c = locList[0];
            }
            smrList.add(smr.clone(false,true));
            
            if( locList != null && locList.size() > 1 ) {
                
                for( Integer i = 1; i < locList.size() ; i++){
                    Stock_Movement_Rule__c smrClone = (Stock_Movement_Rule__c)smr.clone(false, true);
                    smrClone.Location__c = locList[i];
                    smrList.add( smrClone );
                }
            }
        }
        else{
            smr = new Stock_Movement_Rule__c();
            smrList.add(smr.clone(false,true));
        }
        
    }
    
    public void syncClones(){
        
        Id idVal = (Id)ApexPages.currentPage().getParameters().get('changedId');
        String fieldPath = (String)ApexPages.currentPage().getParameters().get('fieldPath');
        
        String companyField = KSE.nameSpaceUU + 'Company__c';
        String facilityField = KSE.nameSpaceUU + 'Facility__c';
        
        if( fieldPath == companyField || fieldPath == facilityField ){
            
            copyToClones( idVal , fieldPath );
        }
        
    }
    
    public pageReference copyToClones( Id idVal , String fieldPath ){
        
        for( Stock_Movement_Rule__c smrClone : smrList ){
            
            smrClone.put( fieldPath, idVal );
        }
        smr.put( fieldPath, idVal );
        
        return null;
    }
    
    public void addNewLocation(){
        
        Stock_Movement_Rule__c smrClone = (Stock_Movement_Rule__c)smrList[0].clone(false, true);
        smrClone.Location__c = null;
        smrList.add( smrClone );
    }
    
    public PageReference save(){
        
        set<Id> locationSet = new set<Id>();
        list<Id> locationList = new list<Id>();
        
        try{
            for( Stock_Movement_Rule__c smrLocations : smrList ){
                
                if(!locationSet.contains(smrLocations.Location__c) && smrLocations.Location__c != null ){
                    
                    locationSet.add( smrLocations.Location__c );
                    locationList.add( smrLocations.Location__c );
                }
                else if(locationSet.contains(smrLocations.Location__c)){
                    throw new StockMovementRuleManageExtException('Location cannot be specified more than once!');
                }
            }
            
            //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
			
			SOQLUtil soql = new SOQLUtil('Location__c', true); //enforceFLS=true, running in user mode
			soql.addFields(new set<string>{
				'id','Facility__c','Facility__r.Company__c'
			});
			soql.setWhereClause('Id IN :locationSet');
			
			map<Id,Location__c> locationsMap = new map<Id,Location__c>((List<Location__c>)Database.query(soql.getQuery()));
            
            for( Stock_Movement_Rule__c smrLocations : smrList ){
                
                if( smrLocations.Location__c != null && locationSet.contains(smrLocations.Location__c) ){
                    
                    if(!locationsMap.containsKey(smrLocations.Location__c)){
                        smrLocations.Location__c.addError('Location does not exist!');
                        return null;
                    }
                    
                    if( locationsMap.get(smrLocations.Location__c).Facility__c != smr.Facility__c || locationsMap.get(smrLocations.Location__c).Facility__r.Company__c != smr.Company__c  ){
                        smrLocations.Location__c.addError('Location must belong the company and facility specified!');
                        return null;
                    }
                }
            }
            
            
            if( locationList.size() == 0 ){
                throw new StockMovementRuleManageExtException('Please specify at least one location.');
            }
            
            smr.Location_List__c = JSON.serialize( locationList );
            smr.Location__c = locationList[0]; // saving the first preferred location into the location field. maybe used for reporting purposes.
            DML.checkUpsertAsUser(smr); upsert smr;
        }
        catch(DMLException e){
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, e.getdmlMessage(0) ));
        }
        catch( Exception e ){
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
        
        return ApexPages.hasMessages() ? null : new PageReference('/'+smr.id);
    }
    
}