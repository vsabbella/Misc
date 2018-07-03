public with sharing class HierarchyPathBatch implements Database.Batchable<sObject>, Process.Runnable2, Database.Stateful {
    
    public List<Notify.Message> messages = new List<Notify.Message>();
    
    public void runBatch(Process_Job__c job) { 
        Database.executeBatch(new HierarchyPathBatch(),2000); 
    }
    
    public List<Hierarchy__c> start(Database.BatchableContext BC) { 
        //String query = 'select id,Type__c from Hierarchy__c WHERE Type__c != null AND Current_bool__c = true order by Type__c ';
        //return Database.query(query);
        
        String whereClause = 'Type__c != null AND Current_bool__c = true order by Type__c';//KNDY-8796
        SOQLUtil soql = new SOQLUtil('Hierarchy__c',true);
        soql.addFields(new Set<String>{'Id','Type__c'});
        soql.setWhereClause(whereClause);
        return Database.query(soql.getQuery());
    }
    
    public void execute(Database.BatchableContext info,List<Hierarchy__c> scope) {
        
        // deal with types one at a time, make a map and collect lists by the type
        map<string,list<Hierarchy__c>> hMap = new map<string,list<Hierarchy__c>>();        
        for ( Hierarchy__c h : scope) {
            if ( ! hMap.containsKey( h.type__c) ) 
                hMap.put(h.type__c,new List<Hierarchy__c>());
            hMap.get(h.Type__c).add(h);
        }
        
        // iterate over each type
        for ( string typ : hMap.keySet() ) { 
            scope = hMap.get(typ);  // focus on the list of a single type
            
            HierarchyController hcon = new HierarchyController( new Apexpages.standardController( scope[0] ));
            hcon.setHierarchyPath();
            
            // we need to update only those records which are in scope so we dont blow past the 10,000 dml limit
            // build the short list to update
            list<Hierarchy__c> toUpdate = new list<Hierarchy__c>();
            for ( Hierarchy__c hh : scope ) { 
                if ( hcon.allRecords.containsKey(hh.Id) )
                    toUpdate.add(hcon.allRecords.get(hh.Id));
                else {
                    //messages.add( new Notify.Message('Hierarchy record missing ', String.valueof(hh) ));
                    system.debug(LoggingLevel.INFO, 'missing from allRecords '+hh);
                }
            }
            DML.updateAsUser(toUpdate); // less than or equal 2000 rows
        }
    }
    
    public void finish(Database.BatchableContext info) { 
        MasterControlProgram.finishedBatch(this); 
        Notify.sendEmailBatchFinish( null, messages, info);
    }
    
}