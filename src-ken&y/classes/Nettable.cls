public with sharing class Nettable {
    /** 
     * @description given a list of items, produce net/non net counts in a map
     */ 
    public static Map < Id, Nettable.NETcount > getNettable( List<Item__c> items) {
        
        set<id> idset = new set<id>();
        for ( Item__c it : items ) {            idset.add(it.id);       }

        Map < Id, NETcount > theMap = new Map<Id,NETcount>(); 
    
       

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'ID','Item__c','Location__r.Nettable__c','Quantity__c','Type__c'
        });
        soql.setWhereClause('Item__c in :idset and Type__c in (\'Location\',\'Allocated\')');
        soql.setOrderByClause('Location__r.Facility__r.Name, Location__r.Name ASC');
        for( SKID__c sk : Database.query(soql.getQuery())){
            
            // group the nettable by Item
            if ( ! theMap.containsKey( sk.Item__c ) ) {
                theMap.put( sk.Item__c, new NETcount() );
            }
            if (sk.Type__c == 'Allocated') {
                theMap.get(sk.Item__c).nettable -= sk.Quantity__c != null ? sk.Quantity__c : 0;
            }
            else {
                if ( sk.Location__r.Nettable__c ) { 
                    theMap.get(sk.Item__c).nettable += sk.Quantity__c != null ? sk.Quantity__c : 0;
                } else {
                    theMap.get(sk.Item__c).nonnettable += sk.Quantity__c != null ? sk.Quantity__c : 0;
                }
            }
        }     
        return theMap;
    }
    
    /** 
     * @description given a list of items and a facility ID, produce net/non net counts in a map
     */ 
    public static Map < Id, Nettable.NETcount > getNettableByFacility( List<Item__c> items, ID facilityID) {
        
        set<id> idset = new set<id>();
        for ( Item__c it : items ) {            idset.add(it.id);       }

        Map < Id, NETcount > theMap = new Map<Id,NETcount>(); 
    
      

        /*
        //KNDY-10473: Adding CRUD/FLS checks with SOQLUtil
        */
        SOQLUtil soql = new SOQLUtil('SKID__c', true); //enforceFLS=true, running in user mode
        soql.addFields(new set<string>{
            'ID','Item__c','Location__r.Nettable__c','Quantity__c','Type__c'
        });
        soql.setWhereClause('Item__c in :idset and Location__r.Facility__c =: facilityID and Type__c in (\'Location\',\'Allocated\')');
        soql.setOrderByClause('Location__r.Facility__r.Name, Location__r.Name ASC');
        for( SKID__c sk : Database.query(soql.getQuery())){
            
            // group the nettable by Item
            if ( ! theMap.containsKey( sk.Item__c ) ) {
                theMap.put( sk.Item__c, new NETcount() );
            }
            if (sk.Type__c == 'Allocated') {
                theMap.get(sk.Item__c).nettable -= sk.Quantity__c != null ? sk.Quantity__c : 0;
            }
            else {
                if ( sk.Location__r.Nettable__c ) { 
                    theMap.get(sk.Item__c).nettable += sk.Quantity__c != null ? sk.Quantity__c : 0;
                } else {
                    theMap.get(sk.Item__c).nonnettable += sk.Quantity__c != null ? sk.Quantity__c : 0;
                }
            }
        }     
        return theMap;
    }

    public with sharing class NETcount {
        public NETcount() { nettable = 0; nonnettable = 0; }
        public Double nettable {get;set;}
        public Double nonnettable {get;set;}  
    }
    
}