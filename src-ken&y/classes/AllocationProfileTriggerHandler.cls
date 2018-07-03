public with sharing class AllocationProfileTriggerHandler {
    private static void checkForAllocatedSkids(List<Allocation_Profile__c> allocProfiles) {
        Map<Id, Allocation_Profile__c> idsToCheck = new Map<Id, Allocation_Profile__c>();
        for (Allocation_Profile__c allocProfile:allocProfiles) {
            if (allocProfile.Item__c != null) idsToCheck.put(allocProfile.Item__c, allocProfile);
            else if (allocProfile.Company__c != null) idsToCheck.put(allocProfile.Company__c, allocProfile);
        }

        if (idsToCheck.size() > 0) {
            String idList = '(\'' + String.join(new List<Id>(idsToCheck.keySet()),'\',\'') + '\')';
            SOQLUtil skidQuery = new SOQLUtil('SKID__c');
            skidQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c', 'Item__c' });
            skidQuery.setWhereClause('(Item__c IN ' + idList + ' OR Company__c IN ' + idList + ') AND Type__c = \'' + SkidService3.SKID_TYPE_ALLOCATED + '\'');
            
            for (SKID__c skid:Database.query(skidQuery.getQuery())) {
                throw new CustomException(idsToCheck.get(idsToCheck.containsKey(skid.Item__c) ? skid.Item__c : skid.Company__c).Name + ': Unable to add, modify or delete an allocation profile that has associated allocated skids');
            }
        }
    }

    private static void setAutoPlanPick(Map<Id, Allocation_Profile__c> allocProfiles) {
        Set<Id> itemIds = new Set<Id>();
        for (Allocation_Profile__c allocProfile:allocProfiles.values()) {
            if (allocProfile.Company__c == null && allocProfile.Item__c != null) itemIds.add(allocProfile.Item__c);
        }

        Map<Id, Item__c> items = new Map<Id, Item__c>();
        if (itemIds.size() > 0) {
            SOQLUtil itemQuery = new SOQLUtil('Item__c');
            itemQuery.addFields(new Set<String>{ 'Id', 'Name', 'Company__c' });
            itemQuery.setWhereClause('Id IN :itemIds');
            items = new Map<Id, Item__c>((List<Item__c>)Database.query(itemQuery.getQuery()));
        }

        Map<String, sObjectField> allocProfileFields = SchemaUtil.getInstance().getFieldsMap('Allocation_Profile__c');
        Set<Id> companyIds = new Set<Id>();
        Map<Id, Company__c> companiesToUpdate = new Map<Id, Company__c>();
        for (Allocation_Profile__c allocProfile:allocProfiles.values()) {
            Id companyId = allocProfile.Company__c;
            if (companyId == null && allocProfile.Item__c != null) companyId = items.get(allocProfile.Item__c).Company__c;

            if (companyId == null || (!Trigger.isDelete && companiesToUpdate.containsKey(companyId)) || (Trigger.isDelete && companyIds.contains(companyId))) continue;

            for (String fld:allocProfileFields.keySet()) {
                if (fld.endsWith('__c') && allocProfileFields.get(fld).getDescribe().getType() == Schema.DisplayType.Boolean && (Boolean)allocProfile.get(fld) == false) {
                    if (!Trigger.isDelete) {
                        companiesToUpdate.put(companyId, new Company__c(Id = companyId, Auto_Plan_Pick__c = false));
                        companyIds.remove(companyId);
                    } else {
                        companyIds.add(companyId);
                    }
                    break;
                }
            }

            if (Trigger.isUpdate && !companiesToUpdate.containsKey(companyId)) companyIds.add(companyId);
        }

        companiesToUpdate.putAll(CompanyService.setAutoPlanPick(companyIds, allocProfiles.keySet()));

        if (companiesToUpdate.size() > 0) {
            CompanyService.allowAutoPlanPickUpdate = true;
            DML.updateAsUser(companiesToUpdate.values());
            CompanyService.allowAutoPlanPickUpdate = false;
        }
    }

    public static void beforeInsert() { checkForAllocatedSkids((List<Allocation_Profile__c>)Trigger.new); }
    public static void beforeUpdate() {
        for (Allocation_Profile__c allocProfile:(List<Allocation_Profile__c>)Trigger.old) {
            if (allocProfile.Company__c == null && allocProfile.Item__c == null) continue;

            String errMsg = 'Cannot change an allocation profile\'s company or item';
            Allocation_Profile__c newAllocProfile = (Allocation_Profile__c)Trigger.newMap.get(allocProfile.Id);
            if (allocProfile.Company__c != newAllocProfile.Company__c) newAllocProfile.Company__c.addError(errMsg);
            if (allocProfile.Item__c != newAllocProfile.Item__c) newAllocProfile.Item__c.addError(errMsg);
        }

        checkForAllocatedSkids((List<Allocation_Profile__c>)Trigger.new); 
    }
    public static void beforeDelete() { checkForAllocatedSkids((List<Allocation_Profile__c>)Trigger.old); }

    public static void afterInsert() { setAutoPlanPick((Map<Id, Allocation_Profile__c>)Trigger.newMap); }
    public static void afterUpdate() { setAutoPlanPick((Map<Id, Allocation_Profile__c>)Trigger.newMap); }
    public static void afterDelete() { setAutoPlanPick((Map<Id, Allocation_Profile__c>)Trigger.oldMap); }
    public static void afterUndelete() {
        checkForAllocatedSkids((List<Allocation_Profile__c>)Trigger.new);
        setAutoPlanPick((Map<Id, Allocation_Profile__c>)Trigger.newMap);
    }
}