/**
 * Created by ryansieve on 4/12/17.
 */

public with sharing class UOM {
    private static map<Id, UOM__c> mUOMs = new map<Id, UOM__c>();
    public static map<Id, UOM__c> retrieveUOMs(set<Id> uomIds){
        set<Id> localIds = uomIds;
        map<Id, UOM__c> mUOMResponse = new map<Id, UOM__c>();
        if(!mUOMs.keySet().containsAll(uomIds)){
            localIds.removeAll(mUOMs.keySet());
            fetchUOMs(localIds);
        }
        for(Id uomId : uomIds){
            mUOMResponse.put(uomId, mUOMs.get(uomId));
        }
        return mUOMResponse;
    }

    private static void fetchUOMs(set<Id> uomIds){
        SOQLUtil soql = new SOQLUtil('UOM__c');
        soql.addAllFields();
        soql.setWhereClause('Id IN :uomIds');
        mUOMs.putAll((list<UOM__c>)Database.query(soql.getQuery()));
    }

    public class RetrieveUOMs implements Action.Target{
        public Action.Response execute(Object obj){
            Action.Response resp = new Action.Response();
            try{
                SOQLUtil soql = new SOQLUtil('UOM__c');
                soql.addAllFields();
                List<UOM__c> uoms = (List<UOM__c>)soql.returnQueryResult();
                resp.result = new Action.Result();
                resp.result.resultObject = JSON.serialize(uoms);
                resp.success = true;
            }catch(Exception ex){
                system.debug('EXCEPTION: ' + ex.getMessage() + ' ' +  ex.getStackTraceString());
                resp.success = false;
            }
            system.debug(JSON.serialize(resp));
            return resp;
        }
    }
}