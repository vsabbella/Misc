public with sharing class LocationTriggerHandler {
    private static void setFacility(List<Location__c> locations, Boolean isBefore) {
        Relate.setLookupUsingField(locations, isBefore, 'Facility__c', 'Facility__c', 'Facility_Identifier__c', 'Primary_Key__c');
    }

    private static void checkMixedBins(Map<Id, Location__c> locations, Map<Id, Location__c> oldLocations) {
        Set<Id> locIds = new Set<Id>();
        for (Location__c loc:locations.values()) {
            if (loc.Bin_Tracked__c == true && loc.Mixed_Bins_Allowed__c == false && KSE.isFieldChanging('Mixed_Bins_Allowed__c', loc, oldLocations)) {
                locIds.add(loc.Id);
            }
        }

        if (locIds.size() > 0) {
            SOQLUtil skidQuery = new SOQLUtil('SKID__c', false, true);
            skidQuery.addFields(new Set<String>{ 'Bin__c binId', 'COUNT_DISTINCT(Item__c) itemCt' });
            skidQuery.setWhereClause('Location__c IN :locIds ' +
                                     'AND Type__c = \'' + SkidService3.SKID_TYPE_LOCATION + '\' ' +
                                     'GROUP BY Bin__c');

            Set<Id> binIds = new Set<Id>();
            for (AggregateResult ar:Database.query(skidQuery.getQuery())) {
                if ((Integer)ar.get('itemCt') > 1) binIds.add((Id)ar.get('binId'));
            }

            if (binIds.size() > 0) {
                SOQLUtil binQuery = new SOQLUtil('Bin__c');
                binQuery.addFields(new Set<String>{ 'Id', 'Name', 'Location__c' });
                binQuery.setWhereClause('Id IN :binIds');

                Map<Id, List<String>> binsWithMultipleItems = new Map<Id, List<String>>();
                for (Bin__c bin:Database.query(binQuery.getQuery())) {
                    if (binsWithMultipleItems.containsKey(bin.Location__c) == false) binsWithMultipleItems.put(bin.Location__c, new List<String>{ bin.Name });
                    else binsWithMultipleItems.get(bin.Location__c).add(bin.Name);
                }

                for (Id locId:binsWithMultipleItems.keySet()) {
                    Location__c loc = locations.get(locId);

                    List<String> binNames = binsWithMultipleItems.get(locId);
                    binNames.sort();

                    loc.Mixed_Bins_Allowed__c.addError('You can\'t disable mixed bins on location ' + loc.Name + ' because the following bins have multiple items in them: ' + String.join(binNames, ', '));
                }
            }
        }
    }

    private static void validateBinTracked(List<Location__c> locs, Map<Id, Location__c> oldLocs) {
        Set<Id> locsForSkids = new Set<Id>();
        Set<Id> locsForBins = new Set<Id>();
        List<Location__c> locsToCheck = new List<Location__c>();
        for (Location__c loc:locs) {
            if (KSE.isFieldChanging('Bin_Tracked__c', loc, oldLocs) == true) {
                if (loc.Bin_Tracked__c == true) locsForSkids.add(loc.Id);
                else locsForBins.add(loc.Id);   // Should we just check for skids and delete bins instead?
                locsToCheck.add(loc);
            }
        }
        if (locsToCheck.size() == 0) return;

        Set<Id> locsWithSkids = new Set<Id>();
        if (locsForSkids.size() > 0) {
            Set<String> skidTypes = new Set<String>{ SkidService3.SKID_TYPE_LOCATION, SkidService3.SKID_TYPE_ALLOCATED, SkidService3.SKID_TYPE_PLANNED };
            SOQLUtil skidQuery = new SOQLUtil('SKID__c', false, true);
            skidQuery.addFields(new Set<String>{ 'Location__c locId' });
            skidQuery.setWhereClause('Location__c IN :locsForSkids AND Type__c IN :skidTypes GROUP BY Location__c');
            for (AggregateResult ar:Database.query(skidQuery.getQuery())) locsWithSkids.add((Id)ar.get('locId'));
        }

        Set<Id> locsWithBins = new Set<Id>();
        if (locsForBins.size() > 0) {
            SOQLUtil binQuery = new SOQLUtil('Bin__c', true, true);
            binQuery.addFields(new Set<String>{ 'Location__c locId' });
            binQuery.setWhereClause('Location__c IN :locsForBins GROUP BY Location__c');
            for (AggregateResult ar:Database.query(binQuery.getQuery())) locsWithBins.add((Id)ar.get('locId'));
        }

        for (Location__c loc:locsToCheck) {
            if (loc.Bin_Tracked__c == true && locsWithSkids.contains(loc.Id) == true) loc.Bin_Tracked__c.addError(loc.Name + ': You can\'t enable bin tracking because this location has SKIDs associated with it.');
            else if (loc.Bin_Tracked__c == false && locsWithBins.contains(loc.Id) == true) loc.Bin_Tracked__c.addError(loc.Name + ': You can\'t disable bin tracking because this location has bins.');
        }
    }

    public static void beforeInsert() { setFacility(Trigger.new, true); }
    public static void beforeUpdate() { 
        setFacility(Trigger.new, true);
        checkMixedBins((Map<Id, Location__c>)Trigger.newMap, (Map<Id, Location__c>)Trigger.oldMap);
        validateBinTracked(Trigger.new, (Map<Id, Location__c>)Trigger.oldMap);
    }
    public static void beforeDelete() { KSE.blockRecordDeletion(); }
    public static void afterInsert() { }
    public static void afterUpdate() { }
    public static void afterDelete() { }
    public static void afterUndelete() { }
}