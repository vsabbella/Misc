public with sharing class LocationListExtension {
    
    public class LocationListExtensionException extends Exception{}
    public list<Stock_Movement_Rule__c> smrList {get;set;}{ smrList = new list<Stock_Movement_Rule__c>();}
    
    public LocationListExtension(ApexPages.StandardController con) {
        
        try{
            if( con.getRecord().id != null ){
                Stock_Movement_Rule__c smr = (Stock_Movement_Rule__c) con.getRecord();
                
                list<Id> locList;
                if( smr.Location_List__c != null ){
                    try{
                        locList = (list<Id>)JSON.deserialize(String.valueOf(smr.get('Location_List__c')), list<Id>.Class);
                    }
                    catch(Exception e){
                        ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, 'Invalid location specified on stock movement rule :'+smr.get('name') ));
                        return;
                    }
                }
                else if( smr.Location_List__c == null || locList.size() == 0 ){
                    throw new LocationListExtensionException('No Locations have been specified for this rule!');
                }
                
                if( locList.size() > 0 ){
                    
                    for( Integer i = 0; i< locList.size() ; i++ ){
                        Stock_Movement_Rule__c locRule = smr.clone(false,true);
                        locRule.Location__c = locList[i];
                        locRule.Sequence__c = i+1;
                        smrList.add( locRule );
                    }
                }
            }
        }
        catch( Exception e ){
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.Error, MessageUtil.toFriendlyErrorMessage(e.getMessage())));
            system.debug(LoggingLevel.Error, 'EXCEPTION: ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}